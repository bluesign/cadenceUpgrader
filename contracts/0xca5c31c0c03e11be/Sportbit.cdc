import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import SportvatarTemplate from "./SportvatarTemplate.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/*

 This contract defines the Sportvatar Dust Accessory NFT and the Collection to manage them.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

pub contract Sportbit: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Counter for all the Components ever minted
    pub var totalSupply: UInt64

    // Standard events that will be emitted
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, templateId: UInt64, mint: UInt64)
    pub event Destroyed(id: UInt64, templateId: UInt64)

    // The public interface provides all the basic informations about
    // the Component and also the Template ID associated with it.
    pub resource interface Public {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub fun getTemplate(): SportvatarTemplate.TemplateData
        pub fun getSvg(): String
        pub fun getSeries(): UInt64
        pub fun getRarity(): String
        pub fun getSport(): String
        pub fun getMetadata(): {String: String}
        pub fun getLayer(): UInt32
        pub fun getTotalMinted(): UInt64

        //these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        pub let name: String
        pub let description: String
        pub let schema: String?
    }


    // The NFT resource that implements the Public interface as well
    pub resource NFT: NonFungibleToken.INFT, Public, MetadataViews.Resolver {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let schema: String?

        // Initiates the NFT from a Template ID.
        init(templateId: UInt64) {

            Sportbit.totalSupply = Sportbit.totalSupply + UInt64(1)

            let template = SportvatarTemplate.getTemplate(id: templateId)!

            self.id = Sportbit.totalSupply
            self.templateId = templateId
            self.mint = SportvatarTemplate.getTotalMintedComponents(id: templateId)! + UInt64(1)
            self.name = template.name
            self.description = template.description
            self.schema = nil

            // Increments the counter and stores the timestamp
            SportvatarTemplate.setTotalMintedComponents(id: templateId, value: self.mint)
            SportvatarTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        // Returns the Template associated to the current Component
        pub fun getTemplate(): SportvatarTemplate.TemplateData {
            return SportvatarTemplate.getTemplate(id: self.templateId)!
        }

        // Gets the SVG from the parent Template
        pub fun getSvg(): String {
            return self.getTemplate().svg!
        }

        // Gets the series number from the parent Template
        pub fun getSeries(): UInt64 {
            return self.getTemplate().series
        }

        // Gets the rarity from the parent Template
        pub fun getRarity(): String {
            return self.getTemplate().rarity
        }

        pub fun getMetadata(): {String: String} {
            return self.getTemplate().metadata
        }

        pub fun getLayer(): UInt32 {
          return self.getTemplate().layer
        }

        pub fun getSport(): String {
          return self.getTemplate().sport
        }

        pub fun getTotalMinted(): UInt64 {
            return self.getTemplate().totalMintedComponents
        }

        // Emit a Destroyed event when it will be burned to create a Sportvatar
        // This will help to keep track of how many Components are still
        // available on the market.
        destroy() {
            emit Destroyed(id: self.id, templateId: self.templateId)
        }

        pub fun getViews() : [Type] {
            var views : [Type]=[]
            views.append(Type<MetadataViews.NFTCollectionData>())
            views.append(Type<MetadataViews.NFTCollectionDisplay>())
            views.append(Type<MetadataViews.Display>())
            views.append(Type<MetadataViews.Royalties>())
            views.append(Type<MetadataViews.Edition>())
            views.append(Type<MetadataViews.ExternalURL>())
            views.append(Type<MetadataViews.Serial>())
            views.append(Type<MetadataViews.Traits>())
            return views
        }

        pub fun resolveView(_ type: Type): AnyStruct? {

            if type == Type<MetadataViews.ExternalURL>() {
                return MetadataViews.ExternalURL("https://sportvatar.com")
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                royalties.append(MetadataViews.Royalty(receiver: Sportbit.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.05, description: "Sportvatar Royalty"))
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let componentTemplate: SportvatarTemplate.TemplateData = self.getTemplate()
                var maxMintable: UInt64 = componentTemplate.maxMintableComponents
                if(maxMintable == UInt64(0)){
                    maxMintable = UInt64(999999)
                }
                let editionInfo = MetadataViews.Edition(name: "Sportvatar Accessory", number: self.mint, max: maxMintable)
                let editionList: [MetadataViews.Edition] = [editionInfo]
                return MetadataViews.Editions(
                    editionList
                )
            }

            if type == Type<MetadataViews.NFTCollectionDisplay>() {
                let mediaSquare = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.sportvatar.com/logo.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                let mediaBanner = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://images.sportvatar.com/logo-horizontal.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Sportvatar Accessory",
                    description: "The Sportvatar Accessories allow you customize and make your beloved Sportvatar even more unique and exclusive.",
                    externalURL: MetadataViews.ExternalURL("https://sportvatar.com"),
                    squareImage: mediaSquare,
                    bannerImage: mediaBanner,
                    socials: {
                        "discord": MetadataViews.ExternalURL("https://discord.gg/sportvatar"),
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/sportvatar"),
                        "instagram": MetadataViews.ExternalURL("https://instagram.com/sportvatar_nft"),
                        "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@sportvatar")
                    }
                )
            }

            if type == Type<MetadataViews.Display>() {
                return MetadataViews.Display(
                    name: self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://sportvatar.com/api/image/template/".concat(self.templateId.toString())
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []

                let template = self.getTemplate()
                let trait = MetadataViews.Trait(name: "Name", value: template.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template.rarity))
                traits.append(trait)

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.Rarity>() {
                let template = self.getTemplate()
                return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
            }

            if type == Type<MetadataViews.NFTCollectionData>() {
                return MetadataViews.NFTCollectionData(
                storagePath: Sportbit.CollectionStoragePath,
                publicPath: Sportbit.CollectionPublicPath,
                providerPath: /private/SportbitCollection,
                publicCollection: Type<&Sportbit.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportbit.CollectionPublic}>(),
                publicLinkedType: Type<&Sportbit.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportbit.CollectionPublic}>(),
                providerLinkedType: Type<&Sportbit.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportbit.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Sportbit.createEmptyCollection()}
                )
            }

            return nil
        }
    }

    // Standard NFT collectionPublic interface that can also borrowAccessory as the correct type
    pub resource interface CollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowAccessory(id: UInt64): &Sportbit.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
        pub fun borrowSportvatar(id: UInt64): &Sportbit.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Component reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Components NFT
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Sportbit.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowAccessory returns a borrowed reference to a Sportbit
        // so that the caller can read data and call methods from it.
        pub fun borrowAccessory(id: UInt64): &Sportbit.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Sportbit.NFT
            } else {
                return nil
            }
        }
        pub fun borrowSportvatar(id: UInt64): &Sportbit.NFT? {
            return self.borrowAccessory(id: id)
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let componentNFT = nft as! &Sportbit.NFT
            return componentNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Components
    // when retrieved using the contract helper methods outside the collection.
    pub struct AccessoryData {
        pub let id: UInt64
        pub let templateId: UInt64
        pub let mint: UInt64
        pub let name: String
        pub let description: String
        pub let rarity: String
        pub let metadata: {String: String}
        pub let layer: UInt32
        pub let totalMinted: UInt64
        pub let sport: String

        init(id: UInt64, templateId: UInt64, mint: UInt64) {
            self.id = id
            self.templateId = templateId
            self.mint = mint
            let template = SportvatarTemplate.getTemplate(id: templateId)!
            self.name = template.name
            self.description = template.description
            self.rarity = template.rarity
            self.metadata = template.metadata
            self.layer = template.layer
            self.totalMinted = template.totalMintedComponents
            self.sport = template.sport
        }
    }




    // Get the SVG of a specific Sportbit from an account and the ID
    pub fun getSvgForSportbit(address: Address, id: UInt64) : String? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&Sportbit.Collection{Sportbit.CollectionPublic}>()  {
            return componentCollection.borrowAccessory(id: id)!.getSvg()
        }
        return nil
    }

    // Get a specific Component from an account and the ID as AccessoryData
    pub fun getSportbit(address: Address, componentId: UInt64) : AccessoryData? {
        let account = getAccount(address)
        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&Sportbit.Collection{Sportbit.CollectionPublic}>()  {
            if let component = componentCollection.borrowAccessory(id: componentId) {
                return AccessoryData(
                    id: componentId,
                    templateId: component!.templateId,
                    mint: component!.mint
                )
            }
        }
        return nil
    }

    // Get an array of all the components in a specific account as AccessoryData
    pub fun getSportbits(address: Address) : [AccessoryData] {

        var componentData: [AccessoryData] = []
        let account = getAccount(address)

        if let componentCollection = account.getCapability(self.CollectionPublicPath).borrow<&Sportbit.Collection{Sportbit.CollectionPublic}>()  {
            for id in componentCollection.getIDs() {
                var component = componentCollection.borrowAccessory(id: id)
                componentData.append(AccessoryData(
                    id: id,
                    templateId: component!.templateId,
                    mint: component!.mint
                    ))
            }
        }
        return componentData
    }

    access(account) fun createSportbit(templateId: UInt64) : @Sportbit.NFT {
        let template: SportvatarTemplate.TemplateData = SportvatarTemplate.getTemplate(id: templateId)!
        let totalMintedComponents: UInt64 = SportvatarTemplate.getTotalMintedComponents(id: templateId)!

        // Makes sure that the original minting limit set for each Template has not been reached
        if(template.maxMintableComponents > UInt64(0) && totalMintedComponents >= template.maxMintableComponents) {
            panic("Reached maximum mintable components for this template")
        }

        var newNFT <- create NFT(templateId: templateId)
        emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)

        return <- newNFT
    }


    // This method can only be called from another contract in the same account.
    // In Sportbit case it is called from the Sportvatar Admin that is used
    // to administer the components.
    // This function will batch create multiple Components and pass them back as a Collection
    access(account) fun batchCreateSportbits(templateId: UInt64, quantity: UInt64): @Collection {
        let newCollection <- create Collection()

        var i: UInt64 = 0
        while i < quantity {
            newCollection.deposit(token: <-self.createSportbit(templateId: templateId))
            i = i + UInt64(1)
        }

        return <-newCollection
    }

	init() {
        self.CollectionPublicPath = /public/SportbitCollection
        self.CollectionStoragePath = /storage/SportbitCollection

        // Initialize the total supply
        self.totalSupply = UInt64(0)

        self.account.save<@NonFungibleToken.Collection>(<- Sportbit.createEmptyCollection(), to: Sportbit.CollectionStoragePath)
        self.account.link<&Sportbit.Collection{Sportbit.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Sportbit.CollectionPublicPath, target: Sportbit.CollectionStoragePath)

        emit ContractInitialized()
	}
}

