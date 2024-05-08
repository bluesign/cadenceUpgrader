import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import LCubeTicketComponent from "./LCubeTicketComponent.cdc"
import LCubeExtension from "./LCubeExtension.cdc"

//Wow! You are viewing LimitlessCube Ticket contract.

pub contract LCubeTicket: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event EventCreated(eventID: UInt64, creator: Address, metadata: {String:String})
    pub event TicketCreated(creatorAddress: Address, eventID:UInt64, id: UInt64,  metadata: {String:String})
    pub event TicketUsed(id: UInt64, accountAddress: Address?, items: [UInt64])
    pub event Destroy(id: UInt64)

pub fun createTicketMinter(creator: Address, metadata: {String:String}): @TicketMinter {
    assert(metadata.containsKey("eventName"), message: "eventName property is required for LCubeTicket!")
    assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubeTicket!")

    var eventName = LCubeExtension.clearSpaceLetter(text: metadata["eventName"]!)

    assert(eventName.length>2, message: "eventName property is not empty or minimum 3 characters!")

    let storagePath= "Event_".concat(eventName)

    let candidate <- self.account.load<@LCubeEvent>(from: StoragePath(identifier: storagePath)!)

    if candidate!=nil {
        panic(eventName.concat(" Event already created before!"))
    }
    
    destroy candidate

    var newEvent <- create LCubeEvent(creatorAddress: creator, metadata: metadata)
    var eventID: UInt64 = newEvent.uuid
    emit EventCreated(eventID: eventID, creator: creator, metadata: metadata)    
    
    self.account.save(<-newEvent, to: StoragePath(identifier: storagePath)!)

    return <- create TicketMinter(eventID: eventID)
  }

  pub resource LCubeEvent {
    pub let creatorAddress: Address
    pub let metadata: {String:String}

    init(creatorAddress: Address, metadata: {String:String}) {
         self.creatorAddress = creatorAddress
         self.metadata = metadata
        }
  }  

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let creatorAddress: Address
        pub let eventID: UInt64        
        pub let startOfUse: UFix64
        pub let itemCount: UInt8
        pub let metadata: {String:String}
        access(self) let royalties: [MetadataViews.Royalty]
        init(
            creatorAddress: Address,
            eventID:UInt64,           
            startOfUse: UFix64,
            metadata: {String:String},
            royalties: [MetadataViews.Royalty],
            itemCount: UInt8
        ) {
            LCubeTicket.totalSupply = LCubeTicket.totalSupply + 1

            self.id = LCubeTicket.totalSupply 
            self.creatorAddress = creatorAddress
            self.eventID = eventID         
            self.startOfUse = startOfUse
            self.metadata = metadata
            self.royalties = royalties
            self.itemCount = itemCount
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"] ?? "",
                        description: self.metadata["description"] ?? "",
                        thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""),
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "LimitlessCube Ticket Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://limitlesscube.io/flow/ticket/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: LCubeTicket.CollectionStoragePath,
                        publicPath: LCubeTicket.CollectionPublicPath,
                        providerPath: /private/LCubeNFTCollection,
                        publicCollection: Type<&LCubeTicket.Collection{LCubeTicketCollectionPublic}>(),
                        publicLinkedType: Type<&LCubeTicket.Collection{LCubeTicket.LCubeTicketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&LCubeTicket.Collection{LCubeTicket.LCubeTicketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-LCubeTicket.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://limitlesscube.com/images/logo.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The LimitlessCube Ticket Collection",
                        description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.",
                        externalURL: MetadataViews.ExternalURL("https://limitlesscube.com/flow/MetadataViews"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["name", "description","thumbnail","image","nftType"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    return traitsView

            }
            return nil
        }

        pub fun getMetadata(): {String:String} {
            return self.metadata
        }

        pub fun getRoyalties(): [MetadataViews.Royalty] {
            return self.royalties
        }
    }

    pub resource interface LCubeTicketCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowLCubeTicket(id: UInt64): &LCubeTicket.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow LimitlessCube reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: LCubeTicketCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
         pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            let nft = (&self.ownedNFTs[withdrawID] as auth &NonFungibleToken.NFT?)!
            let ticketNFT = nft as! &LCubeTicket.NFT

            if (ticketNFT.startOfUse > getCurrentBlock().timestamp) {
                panic("Cannot withdraw: Ticket is locked")
            }

            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing Ticket")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @LCubeTicket.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }


        pub fun useTicket(id: UInt64, address: Address) {

            let recipient = getAccount(address)

            let recipientCap = recipient.getCapability<&{LCubeTicketComponent.LCubeTicketComponentCollectionPublic}>(LCubeTicketComponent.CollectionPublicPath)
            let auth = recipientCap.borrow()!      

            let ticket <- self.withdraw(withdrawID: id) as! @LCubeTicket.NFT

            let minter = LCubeTicket.getComponentMinter().borrow() ?? panic("Could not borrow receiver capability (maybe receiver not configured?)")

            let depositRef = recipient.getCapability(LCubeTicketComponent.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
    
            let beneficiaryCapability = recipient.getCapability<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
          
            if !beneficiaryCapability.check() { panic("Beneficiary capability is not valid!") }  

            var royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(
                  receiver: beneficiaryCapability,
                  cut: 0.05,
                  description: "LimitlessCubeTicket Royalty"
              )]

            let componentMetadata = ticket.getMetadata()

            componentMetadata.insert(key: "eventID", ticket.eventID.toString())
            componentMetadata.insert(key: "creatorAddress", address.toString())

            let components <- minter.batchCreateComponents(
                 eventID: ticket.eventID,
                 metadata: ticket.getMetadata(),
                 royalties:royalties,
                 quantity: ticket.itemCount
            )

            let keys = components.getIDs()
            for key in keys {
                depositRef.deposit(token: <-components.withdraw(withdrawID: key))
            }   

            destroy components

            emit TicketUsed(id: ticket.id,accountAddress: address, items: keys)
            destroy ticket
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{
            let ref = (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            return ref
        }
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ticketNFT = nft as! &LCubeTicket.NFT
            return ticketNFT
        }

        pub fun getMetadata(id: UInt64): {String:String} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ticketNFT = nft as! &LCubeTicket.NFT
            return ticketNFT.getMetadata()
        }

        pub fun borrowLCubeTicket(id: UInt64): &LCubeTicket.NFT? {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ticketNFT = nft as! &LCubeTicket.NFT
            return ticketNFT
        }

        pub fun getRoyalties(id: UInt64): [MetadataViews.Royalty] {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ticketNFT = nft as! &LCubeTicket.NFT
            return ticketNFT.getRoyalties()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @LCubeTicket.Collection {
        return <- create Collection()
    }

    pub fun getTickets(address: Address) : [UInt64]? {
        let account = getAccount(address)
        if let ticketCollection = account.getCapability(self.CollectionPublicPath).borrow<&{LCubeTicket.LCubeTicketCollectionPublic}>()  {
            return ticketCollection.getIDs();
        }
        return nil
    }

    pub fun minter(): Capability<&TicketMinter> {
        return self.account.getCapability<&TicketMinter>(self.MinterPublicPath)
    }

    priv fun getComponentMinter(): Capability<&LCubeTicketComponent.ComponentMinter> {
        return self.account.getCapability<&LCubeTicketComponent.ComponentMinter>(/public/LCubeTicketComponentMinter)
    }

   pub resource TicketMinter {
    
    access(self) let eventID: UInt64
    init(eventID: UInt64){
        self.eventID=eventID
    }

    priv fun createTicket(
            creatorAddress: Address,
            startOfUse: UFix64,
            metadata: {String:String},
            royalties: [MetadataViews.Royalty],
            itemCount: UInt8
        ) : @LCubeTicket.NFT {

        var newTicket <- create NFT( 
            creatorAddress: creatorAddress,
            eventID: self.eventID,          
            startOfUse: startOfUse,
            metadata:metadata,
            royalties: royalties,
            itemCount : itemCount
        )

        emit TicketCreated(creatorAddress: creatorAddress, eventID:self.eventID, id: newTicket.id, metadata: metadata)
        return <- newTicket
    }

    pub fun batchCreateTickets(creator: Capability<&{NonFungibleToken.Receiver}>, startOfUse: UFix64, metadata: {String:String}, royalties: [MetadataViews.Royalty], itemCount: UInt8, quantity: UInt8): @Collection {
         
         assert(metadata.containsKey("name"), message: "name property is required for LCubeTicket!")
         assert(metadata.containsKey("description"), message: "description property is required for LCubeTicket!")     
         assert(metadata.containsKey("image"), message: "image property is required for LCubeTicket!")

        let ticketCollection <- create Collection()

        var i: UInt8 = 0
        while i < quantity {
            ticketCollection.deposit(token: <-self.createTicket(creatorAddress: creator.address, startOfUse: startOfUse, metadata: metadata,royalties: royalties, itemCount: itemCount))
            i = i + 1
        }

       return <-ticketCollection
        }
   }


	init() {

        self.CollectionPublicPath=/public/LCubeTicketCollection
        self.CollectionStoragePath=/storage/LCubeTicketCollection

        self.MinterPublicPath = /public/LCubeTicketMinter
        self.MinterStoragePath = /storage/LCubeTicketMinter

        self.totalSupply = 0

        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&LCubeTicket.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, LCubeTicket.LCubeTicketCollectionPublic, MetadataViews.ResolverCollection}>(LCubeTicket.CollectionPublicPath, target: LCubeTicket.CollectionStoragePath)


        emit ContractInitialized()
	}
}