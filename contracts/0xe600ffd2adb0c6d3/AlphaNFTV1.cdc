import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract AlphaNFTV1 : NonFungibleToken {
    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event NFTDestroyed(id: UInt64)
    pub event NFTMinted(nftId: UInt64, templateId: UInt64, mintNumber: UInt64)
    pub event TemplateCreated(templateId: UInt64, maxSupply: UInt64)

    // Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    
    pub var nextTemplateId: UInt64

    pub var totalSupply: UInt64

    access(account) var templates: {UInt64: Template}

    access(self) var nfts: {UInt64: NFTData}

    pub struct Template {
        pub let templateId: UInt64
        pub var maxSupply: UInt64
        pub var issuedSupply: UInt64
        access(contract) var immutableData: {String: AnyStruct}

        init(maxSupply: UInt64, immutableData: {String: AnyStruct}) {
            pre {
                maxSupply > 0 : "MaxSupply must be greater than zero"
            }
            
            self.templateId = AlphaNFTV1.nextTemplateId
            self.maxSupply = maxSupply
            self.immutableData = immutableData
            self.issuedSupply = 0
        }
        pub fun getImmutableData(): {String:AnyStruct} {
            return self.immutableData
        }
        access(account) fun incrementIssuedSupply(): UInt64 {
            pre {
                self.issuedSupply < self.maxSupply: "Template reached max supply"
            }   
            self.issuedSupply = self.issuedSupply + 1
            return self.issuedSupply
        }

    }

    pub struct NFTData {
        pub let templateId: UInt64
        pub let mintNumber: UInt64

        init(templateId: UInt64, mintNumber: UInt64) {
            self.templateId = templateId
            self.mintNumber = mintNumber
        }
    }
    // The resource that represents the AlphaNFTV1 NFTs
    // 
    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64

        init(templateId: UInt64, mintNumber: UInt64) {
            AlphaNFTV1.totalSupply = AlphaNFTV1.totalSupply + 1

            self.id = AlphaNFTV1.totalSupply
            AlphaNFTV1.nfts[self.id] = NFTData(templateId: templateId, mintNumber: mintNumber)

            emit NFTMinted(nftId: self.id, templateId: templateId, mintNumber: mintNumber)
        }
        destroy(){
            emit NFTDestroyed(id: self.id)
        }
    }
    pub resource interface AlphaNFTV1CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAlphaNFTV1(id: UInt64): &AlphaNFTV1.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow AlphaNFTV1 reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection is a resource that every user who owns NFTs 
    // will store in their account to manage their NFTS
    //
    pub resource Collection: AlphaNFTV1CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

       	// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @AlphaNFTV1.NFT
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
        
        pub fun borrowAlphaNFTV1(id: UInt64): &AlphaNFTV1.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &AlphaNFTV1.NFT
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
    access(account) fun createTemplate(maxSupply: UInt64, immutableData: {String: AnyStruct}) {
        let newTemplate = Template(maxSupply: maxSupply, immutableData: immutableData)
        AlphaNFTV1.templates[AlphaNFTV1.nextTemplateId] = newTemplate
        emit TemplateCreated(templateId: AlphaNFTV1.nextTemplateId, maxSupply: maxSupply)
        AlphaNFTV1.nextTemplateId = AlphaNFTV1.nextTemplateId + 1
    }
    //method to mint NFT, only access by the verified user
    access(account) fun mintNFT(templateInfo: {String: UInt64}, account: Address) {
        pre {
            account != nil: "invalid receipt Address"
            AlphaNFTV1.templates[templateInfo["id"]!] != nil: "Template Id must be valid"
        }
        let receiptAccount = getAccount(account)
        let recipientCollection = receiptAccount
            .getCapability(AlphaNFTV1.CollectionPublicPath)
            .borrow<&{AlphaNFTV1.AlphaNFTV1CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")
        let mintNumberFromSupply = AlphaNFTV1.templates[templateInfo["id"]!]!.incrementIssuedSupply()
        let mintNumber = templateInfo["serial"] ?? mintNumberFromSupply
        var newNFT: @NFT <- create NFT(templateId: templateInfo["id"]!, mintNumber: mintNumber)
        recipientCollection.deposit(token: <-newNFT)
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create AlphaNFTV1.Collection()
    }
    
    //public function to get all templates
    pub fun getTemplates(): {UInt64: Template} {
        return AlphaNFTV1.templates
    }

    //public function to get the latest template id
    pub fun getLatestTemplateId() : UInt64 {
        return AlphaNFTV1.nextTemplateId - 1
    }

    //public function to get template by id
    pub fun getTemplateById(templateId: UInt64): Template {
        pre {
            AlphaNFTV1.templates[templateId] != nil: "Template id does not exist"
        }
        return AlphaNFTV1.templates[templateId]!
    } 
    //public function to get nft-data by id
    pub fun getNFTData(nftId: UInt64): NFTData {
        pre {
            AlphaNFTV1.nfts[nftId] != nil:"nft id does not exist"
        }
        return AlphaNFTV1.nfts[nftId]!
    }
    
    init(){
        self.nextTemplateId = 1
        self.totalSupply = 0
        self.templates = {}
        self.nfts = {}
        self.CollectionStoragePath = /storage/AlphaNFTV1Collection
        self.CollectionPublicPath = /public/AlphaNFTV1Collection
    }
}
 