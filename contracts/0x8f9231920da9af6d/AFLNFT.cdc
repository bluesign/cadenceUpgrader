import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import AFLBadges from "./AFLBadges.cdc"
import AFLMetadataHelper from "./AFLMetadataHelper.cdc"
import AFLBurnRegistry from "./AFLBurnRegistry.cdc"

pub contract AFLNFT : NonFungibleToken {
    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event NFTDestroyed(id: UInt64)
    pub event NFTMinted(nftId: UInt64, templateId: UInt64, mintNumber: UInt64)
    pub event TemplateCreated(templateId: UInt64, maxSupply: UInt64)
    pub event NFTBurnt(nftId: UInt64, templateId: UInt64, mintNumber: UInt64)

    // Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    
    // Latest template-id
    pub var lastIssuedTemplateId: UInt64

    // Total supply of all NFTs that are minted using this contract
    pub var totalSupply: UInt64
    // A dictionary that stores all Templates against it's template-id.
    access(account) var allTemplates: {UInt64: Template}
    // A dictionary that stores all NFTs against it's nft-id.
    access(self) var allNFTs: {UInt64: NFTData}

    // A structure that contain all the data and methods related to Template
    pub struct Template {
        pub let templateId: UInt64
        pub var maxSupply: UInt64
        pub var issuedSupply: UInt64
        access(contract) var immutableData: {String: AnyStruct}

        init(maxSupply: UInt64, immutableData: {String: AnyStruct}) {
            pre {
                maxSupply > 0 : "MaxSupply must be greater than zero"
                immutableData != nil: "ImmutableData must not be nil"
                immutableData.length != 0: "New template data cannot be empty"
            }
            
            self.templateId = AFLNFT.lastIssuedTemplateId
            self.maxSupply = maxSupply
            self.immutableData = immutableData
            self.issuedSupply = 0
        }
        pub fun getImmutableData(): {String:AnyStruct} {
            return self.immutableData
        }

        access(account) fun updateImmutableData(_ data: {String: AnyStruct}) {
            for key in data.keys {
                self.immutableData[key] = data[key]!
            }
        }

        // a method to increment issued supply for template
        access(account) fun incrementIssuedSupply(): UInt64 {
            pre {
                self.issuedSupply < self.maxSupply: "Template reached max supply"
            }   
            self.issuedSupply = self.issuedSupply + 1
            return self.issuedSupply
        }
        access(account) fun decrementIssuedSupply(): UInt64 {
            self.issuedSupply = self.issuedSupply - 1
            return self.issuedSupply
        }
        access(account) fun addBadges() {
            self.immutableData["badges"] = AFLBadges.getBadgesForTemplate(id: self.templateId)
        }
        access(account) fun addMetadata() {
            for key in AFLMetadataHelper.getMetadataForTemplate(id: self.templateId).keys {
                self.immutableData[key] = AFLMetadataHelper.getMetadataForTemplate(id: self.templateId)[key]!
            }
        }
    }
    // A structure that link template and mint-no of NFT
    pub struct NFTData {
        pub let templateId: UInt64
        pub let mintNumber: UInt64

        init(templateId: UInt64, mintNumber: UInt64) {
            self.templateId = templateId
            self.mintNumber = mintNumber
        }
    }
    // The resource that represents the AFLNFT NFTs
    // 
    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64

        init(templateId: UInt64, mintNumber: UInt64) {
            AFLNFT.totalSupply = AFLNFT.totalSupply + 1

            self.id = AFLNFT.totalSupply
            AFLNFT.allNFTs[self.id] = NFTData(templateId: templateId, mintNumber: mintNumber)

            emit NFTMinted(nftId: self.id, templateId: templateId, mintNumber: mintNumber)
        }
        destroy(){
            let nftData = &AFLNFT.allNFTs[self.id]! as &NFTData
            let templateId = nftData.templateId
            let mintNumber = nftData.mintNumber
            let templateRef = &AFLNFT.allTemplates[templateId]! as &Template
            // templateRef.decrementIssuedSupply()
            // AFLNFT.totalSupply = AFLNFT.totalSupply - 1
            // AFLNFT.allNFTs[self.id] = nil
            emit NFTDestroyed(id: self.id)
            emit NFTBurnt(nftId: self.id, templateId: templateId, mintNumber: mintNumber)
            AFLBurnRegistry.burn(templateId: templateId)
        }
    }
    pub resource interface AFLNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAFLNFT(id: UInt64): &AFLNFT.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow AFLNFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection is a resource that every user who owns NFTs 
    // will store in their account to manage their NFTS
    //
    pub resource Collection: AFLNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            assert(withdrawID != 87707, message: "Transfer of this NFT is not allowed!") // 87707 is the id of 2021 AFL Genesis Ball
            let data = AFLNFT.getNFTData(nftId: withdrawID)
            // assert(data.templateId != 0, message: "Transfer of this NFT is not allowed!") // yet to implement template transfer guard
            let token  <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Cannot withdraw: moment does not exist in the collection")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @AFLNFT.NFT
            let id = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            if self.owner?.address != nil {
                emit Deposit(id: id, to: self.owner?.address)
            }
            destroy oldToken
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        
        pub fun borrowAFLNFT(id: UInt64): &AFLNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &AFLNFT.NFT
            }
            else{
                return nil
            }
        }

        init() {
            self.ownedNFTs <- {}
        }
        
        destroy () {
            destroy self.ownedNFTs
        }
    }
    //method to create new Template, only access by the verified user
    access(account) fun createTemplate(maxSupply: UInt64, immutableData: {String: AnyStruct}): UInt64 {
        let newTemplate = Template(maxSupply: maxSupply, immutableData: immutableData)
        AFLNFT.allTemplates[AFLNFT.lastIssuedTemplateId] = newTemplate
        emit TemplateCreated(templateId: AFLNFT.lastIssuedTemplateId, maxSupply: maxSupply)
        AFLNFT.lastIssuedTemplateId = AFLNFT.lastIssuedTemplateId + 1
        return AFLNFT.lastIssuedTemplateId - 1
    }

    //method to mint NFT, only access by the verified user
    access(account) fun mintNFT(templateInfo: {String: UInt64}, account: Address) {
        pre {
            account != nil: "invalid receipt Address"
            AFLNFT.allTemplates[templateInfo["id"]!] != nil: "Template Id must be valid"
        }
        let receiptAccount = getAccount(account)
        let recipientCollection = receiptAccount
            .getCapability(AFLNFT.CollectionPublicPath)
            .borrow<&{AFLNFT.AFLNFTCollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        let mintNumberFromSupply = AFLNFT.allTemplates[templateInfo["id"]!]!.incrementIssuedSupply()
        let mintNumber = templateInfo["serial"] ?? mintNumberFromSupply
        var newNFT: @NFT <- create NFT(templateId: templateInfo["id"]!, mintNumber: mintNumber)
        recipientCollection.deposit(token: <-newNFT)
    }

    access(account) fun mintAndReturnNFT(templateInfo: {String: UInt64}): @NonFungibleToken.NFT {
        pre {
            AFLNFT.allTemplates[templateInfo["id"]!] != nil: "Template Id must be valid"
        }
        let mintNumberFromSupply = AFLNFT.allTemplates[templateInfo["id"]!]!.incrementIssuedSupply()
        let mintNumber = templateInfo["serial"] ?? mintNumberFromSupply
        var newNFT: @NFT <- create NFT(templateId: templateInfo["id"]!, mintNumber: mintNumber)
        return <-newNFT
    }

    //method to create empty Collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create AFLNFT.Collection()
    }
    
    //method to get all templates
    pub fun getAllTemplates(): {UInt64: Template} { 
        return AFLNFT.allTemplates
    }

    //method to get the latest template id
    pub fun getLatestTemplateId() : UInt64 {
        return AFLNFT.lastIssuedTemplateId - 1
    }

    //method to get template by id
    pub fun getTemplateById(templateId: UInt64): Template {
        pre {
            AFLNFT.allTemplates[templateId] != nil: "Template id does not exist"
        }
        let template = AFLNFT.allTemplates[templateId]! 
        template.addBadges()
        template.addMetadata()
        return template
    } 
    //method to get nft-data by id
    pub fun getNFTData(nftId: UInt64): NFTData {
        pre {
            AFLNFT.allNFTs[nftId] != nil:"nft id does not exist"
        }
        return AFLNFT.allNFTs[nftId]!
    }
    
    init(){
        self.lastIssuedTemplateId = 1
        self.totalSupply = 0
        self.allTemplates = {}
        self.allNFTs = {}
        self.CollectionStoragePath = /storage/AFLNFTCollection
        self.CollectionPublicPath = /public/AFLNFTCollection
    }
}
 