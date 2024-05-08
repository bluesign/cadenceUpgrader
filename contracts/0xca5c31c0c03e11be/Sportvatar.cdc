import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import SportvatarTemplate from "./SportvatarTemplate.cdc"
import SportvatarPack from "./SportvatarPack.cdc"
import Sportbit from "./Sportbit.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FlovatarComponentTemplate from "../0x921ea449dffec68a/FlovatarComponentTemplate.cdc"
import FlovatarComponent from "../0x921ea449dffec68a/FlovatarComponent.cdc"

/*

 The contract that defines the Sportvatar NFT and a Collection to manage them


This contract contains also the Admin resource that can be used to manage and generate the Sportvatar Templates.

 */

pub contract Sportvatar: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    // These will be used in the Marketplace to pay out
    // royalties to the creator and to the marketplace
    access(account) var royaltyCut: UFix64
    access(account) var marketplaceCut: UFix64

    // Here we keep track of all the Sportvatar unique combinations and names
    // that people will generate to make sure that there are no duplicates
    pub var totalSupply: UInt64
    access(contract) let mintedCombinations: {String: Bool}
    access(contract) let mintedNames: {String: Bool}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, mint: UInt64, series: UInt64, address: Address)
    pub event Updated(id: UInt64)
    pub event Destroyed(id: UInt64)
    pub event NameSet(id: UInt64, name: String)
    pub event PositionChanged(id: UInt64, position: String)
    pub event StoryAdded(id: UInt64, story: String)


    pub struct Royalties{
        pub let royalty: [Royalty]
        init(royalty: [Royalty]) {
            self.royalty=royalty
        }
    }

    pub enum RoyaltyType: UInt8{
        pub case fixed
        pub case percentage
    }

    pub struct Royalty{
        pub let wallet:Capability<&{FungibleToken.Receiver}>
        pub let cut: UFix64

        //can be percentage
        pub let type: RoyaltyType

        init(wallet:Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType ){
            if(! wallet.check()){
                panic("Capability not valid!")
            }
            self.wallet = wallet
            self.cut = cut
            self.type = type
        }
    }

    //Randomize code gently provided by @bluesign
    pub struct RandomInt{
        priv var value : UInt64?
        priv let maxValue: UInt64
        priv let minValue: UInt64
        priv let field: String
        priv let uuid: UInt64

        pub init(uuid: UInt64, field: String, minValue: UInt64, maxValue: UInt64){
                self.uuid = uuid
                self.field = field
                self.minValue = minValue
                self.maxValue = maxValue
                self.value = nil
        }

        pub fun getValue() : UInt64{
                if let value = self.value {
                    return value
                }
                let h: [UInt8] = HashAlgorithm.SHA3_256.hash(self.uuid.toBigEndianBytes())
                let f: [UInt8] = HashAlgorithm.SHA3_256.hash(self.field.utf8)

                var id =  getBlock(at: getCurrentBlock().height)!.id
                var random:UInt64 = 0
                var i = 0
                while i<8{
                    random = random + (UInt64(id[i]) ^ UInt64(h[i]) ^ UInt64(f[i]))
                    random = random << 8
                    i=i+1
                }
                self.value = self.minValue + random % (self.maxValue - self.minValue)
                return self.minValue + random % (self.maxValue - self.minValue)
        }
    }



    // The public interface can show metadata and the content for the Sportvatar.
    // In addition to it, it provides methods to access the additional optional
    // components (accessory, hat, eyeglasses, background) for everyone.
    pub resource interface Public {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let combination: String
        pub let rarity: String
        pub let creatorAddress: Address
        pub let createdAt: UFix64
        pub let createdAtBlock: UInt64
        access(contract) let royalties: Royalties

        // these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
        access(contract) var name: String
        pub let description: String
        pub let schema: String?

        pub fun getName(): String
        pub fun getSvg(): String
        pub fun getRoyalties(): Royalties
        pub fun getBio(): {String: String}
        pub fun getMetadata(): {String: String}
        pub fun getStats(): {String: UInt32}
        pub fun getLayers(): {UInt32: UInt64?}
        pub fun getAccessories(): [UInt64]
        pub fun getSeries(): SportvatarTemplate.SeriesData?
        pub fun getFlovatarBackground(): UInt64?
    }

    //The private interface can update the Accessory, Hat, Eyeglasses and Background
    //for the Sportvatar and is accessible only to the owner of the NFT
    pub resource interface Private {
        pub fun setName(name: String): String
        pub fun addStory(text: String): String
        pub fun setPosition(latitude: Fix64, longitude: Fix64): String
        pub fun setSportbit(layer: UInt32, sportbit: @Sportbit.NFT): @Sportbit.NFT?
        pub fun removeAccessory(layer: UInt32): @Sportbit.NFT?
        pub fun setFlovatarBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT?
        pub fun removeFlovatarBackground(): @FlovatarComponent.NFT?
    }

    //The NFT resource that implements both Private and Public interfaces
    pub resource NFT: NonFungibleToken.INFT, Public, Private, MetadataViews.Resolver {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let combination: String
        pub let rarity: String
        pub let creatorAddress: Address
        pub let createdAt: UFix64
        pub let createdAtBlock: UInt64
        access(contract) let royalties: Royalties

        access(contract) var name: String
        pub let description: String
        pub let schema: String?
        access(self) let bio: {String: String}
        access(self) let metadata: {String: String}
        access(self) let stats: {String: UInt32}
        access(self) let layers: {UInt32: UInt64?}
        access(self) let accessories: @{UInt32: Sportbit.NFT}
        access(contract) var background: @FlovatarComponent.NFT?

        init(series: UInt64,
            layers: {UInt32: UInt64?},
            metadata: {String: String},
            stats: {String: UInt32},
            creatorAddress: Address,
            royalties: Royalties,
            rarity: String
            ) {
            Sportvatar.totalSupply = Sportvatar.totalSupply + UInt64(1)
            SportvatarTemplate.increaseTotalMintedCollectibles(series: series)
            let coreLayers: {UInt32: UInt64} = Sportvatar.getCoreLayers(series: series, layers: layers)

            self.id = Sportvatar.totalSupply
            self.mint = SportvatarTemplate.getTotalMintedCollectibles(series: series)!
            self.series = series
            self.combination = Sportvatar.getCombinationString(series: series, layers: coreLayers)
            self.creatorAddress = creatorAddress
            self.createdAt = getCurrentBlock().timestamp
            self.createdAtBlock = getCurrentBlock().height
            self.royalties = royalties

            self.schema = nil
            self.name = ""
            self.description = ""
            self.bio = {}
            self.metadata = metadata
            self.stats = stats
            self.layers = layers
            self.accessories <- {}
            self.rarity = rarity
            self.background <- nil
        }

        destroy() {
            destroy self.accessories
            destroy self.background
            emit Destroyed(id: self.id)
        }

        pub fun getID(): UInt64 {
            return self.id
        }

        pub fun getMetadata(): {String: String} {
            return self.metadata
        }

        pub fun getStats(): {String: UInt32} {
            return (self.createdAtBlock < getCurrentBlock().height) ? self.stats : {}
        }

        pub fun getRoyalties(): Royalties {
            return self.royalties
        }

        pub fun getBio(): {String: String} {
            return self.bio
        }

        pub fun getName(): String {
            return self.name
        }

        pub fun getSeries(): SportvatarTemplate.SeriesData? {
            return SportvatarTemplate.getSeries(id: self.series)
        }

        // This will allow to change the Name of the Sportvatar only once.
        // It checks for the current name is empty, otherwise it will throw an error.
        pub fun setName(name: String): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized
                //and that bad words are not accepted?
                name.length > 2 : "The name is too short"
                name.length < 32 : "The name is too long"
                self.name == "" : "The name has already been set"
                //vault.balance == 100.0 : "The amount of $DUST is not correct"
                //vault.isInstance(Type<@SportvatarDustToken.Vault>()) : "Vault not of the right Token Type"
            }

            // Makes sure that the name is available and not taken already
            if(Sportvatar.checkNameAvailable(name: name) == false){
                panic("This name has already been taken")
            }

            //destroy vault
            //self.name = name

            // Adds the name to the array to remember it
            //Sportvatar.addMintedName(name: name)
            //emit NameSet(id: self.id, name: name)

            return self.name
        }

        // This will allow to add a text Story to the Sportvatar Bio.
        // The String will be concatenated each time.
        // There is a limit of 300 characters per story but there is no limit in the full concatenated story length
        pub fun addStory(text: String): String {
            pre {
                // TODO: Make sure that the text of the name is sanitized
                //and that bad words are not accepted?
                text.length > 0 : "The text is too short"
                text.length <= 300 : "The text is too long"
                //vault.balance == 50.0 : "The amount of $DUST is not correct"
                //vault.isInstance(Type<@SportvatarDustToken.Vault>()) : "Vault not of the right Token Type"
            }

            //destroy vault
            //let currentStory: String = self.bio["story"] ?? ""
            //let story: String = currentStory.concat(" ").concat(text)
            //self.bio.insert(key: "story", story)

            //emit StoryAdded(id: self.id, story: story)

            //return story
            return ""
        }


        // This will allow to set the GPS location of a Sportvatar
        // It can be run multiple times and each time it will override the previous state
        pub fun setPosition(latitude: Fix64, longitude: Fix64): String {
            pre {
                latitude >= -90.0 : "The latitude is out of range"
                latitude <= 90.0 : "The latitude is out of range"
                longitude >= -180.0 : "The longitude is out of range"
                longitude <= 180.0 : "The longitude is out of range"
                //vault.balance == 10.0 : "The amount of $DUST is not correct"
                //vault.isInstance(Type<@SportvatarDustToken.Vault>()) : "Vault not of the right Token Type"
            }

            //destroy vault
            //let position: String = latitude.toString().concat(",").concat(longitude.toString())
            //self.bio.insert(key: "position", position)

            //emit PositionChanged(id: self.id, position: position)

            //return position
            return ""
        }

        pub fun getLayers(): {UInt32: UInt64?} {
            return self.layers
        }


        pub fun getAccessories(): [UInt64] {
            let accessoriesIds: [UInt64] = []
            for k in self.accessories.keys {
                let accessoryId = self.accessories[k]?.id
                if(accessoryId != nil){
                    accessoriesIds.append(accessoryId!)
                }
            }
            return accessoriesIds
        }
        // This will allow to change the Accessory of the Sportvatar any time.
        // It checks for the right category and series before executing.
        pub fun setSportbit(layer: UInt32, sportbit: @Sportbit.NFT): @Sportbit.NFT? {
            pre {
                sportbit.getSeries() == self.series : "The accessory belongs to a different series"
            }

            if(SportvatarTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series)){
                emit Updated(id: self.id)

                self.layers[layer] = sportbit.templateId

                let oldAccessory <- self.accessories[layer] <- sportbit
                return <- oldAccessory
            }

            panic("The Layer is out of range or it's not an accessory")
        }

        // This will allow to remove the Accessory of the Sportvatar any time.
        pub fun removeAccessory(layer: UInt32): @Sportbit.NFT? {
            if(SportvatarTemplate.isCollectibleLayerAccessory(layer: layer, series: self.series)){
                emit Updated(id: self.id)
                self.layers[layer] = nil
                let accessory <- self.accessories[layer] <- nil
                return <-accessory
            }

            panic("The Layer is out of range or it's not an accessory")
        }


        pub fun getFlovatarBackground(): UInt64? {
            return self.background?.templateId
        }

        // This will allow to change the Background of the Flobot any time.
        // It checks for the right category and series before executing.
        pub fun setFlovatarBackground(component: @FlovatarComponent.NFT): @FlovatarComponent.NFT? {
            pre {
                component.getCategory() == "background" : "The component needs to be a background"
            }

            emit Updated(id: self.id)

            let compNFT <- self.background <- component
            return <-compNFT
        }

        // This will allow to remove the Background of the Flobot any time.
        pub fun removeFlovatarBackground(): @FlovatarComponent.NFT? {
            emit Updated(id: self.id)
            let compNFT <- self.background <- nil
            return <-compNFT
        }


        // This function will return the full SVG of the Sportvatar. It will take the
        // optional Background and the other Sportbit components from their
        // original Template resources, while all the other unmutable components are
        // taken from the Metadata directly.
        pub fun getSvg(): String {
            let series = SportvatarTemplate.getSeries(id: self.series)

            let layersArr: [String] = []

            for k in series!.layers.keys {
                layersArr.append("")
            }

            var svg: String = series!.svgPrefix

            if let background = self.getFlovatarBackground() {
                if let template = FlovatarComponentTemplate.getComponentTemplate(id: background) {
                    svg = svg.concat(template.svg!)
                }
            }

            for k in self.layers.keys {
                if(self.layers[k] != nil){
                    let layer = self.layers[k]!
                    if(layer != nil){
                        let tempSvg = SportvatarTemplate.getTemplateSvg(id: layer!)
                        //svg = svg.concat(tempSvg!)
                        layersArr[(k-UInt32(1))] = tempSvg!
                    }
                }
            }

            for tempLayer in layersArr {
                svg = svg.concat(tempLayer)
            }

            svg = svg.concat(series!.svgSuffix)

            return svg

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
                return MetadataViews.ExternalURL("https://sportvatar.com/collectible/".concat(self.id.toString()))
            }

            if type == Type<MetadataViews.Royalties>() {
                let royalties : [MetadataViews.Royalty] = []
                var count: Int = 0
                for royalty in self.royalties.royalty {
                    royalties.append(MetadataViews.Royalty(recepient: royalty.wallet, cut: royalty.cut, description: "Sportvatar Royalty ".concat(count.toString())))
                    count = count + Int(1)
                }
                return MetadataViews.Royalties(cutInfos: royalties)
            }

            if type == Type<MetadataViews.Serial>() {
                return MetadataViews.Serial(self.id)
            }

            if type ==  Type<MetadataViews.Editions>() {
                let series = self.getSeries()
                var maxMintable: UInt64 = series!.maxMintable
                if(maxMintable == UInt64(0)){
                    maxMintable = UInt64(999999)
                }
                let editionInfo = MetadataViews.Edition(name: "Sportvatar Series ".concat(self.series.toString()), number: self.mint, max: maxMintable)
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
                    name: "Sportvatar Collectible",
                    description: "Sportvatar is the next generation of composable and customizable Digital Collectibles",
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
                    name: self.name == "" ? "Sportvatar #".concat(self.id.toString()) : self.name,
                    description: self.description,
                    thumbnail: MetadataViews.HTTPFile(
                        url: "https://images.sportvatar.com/sportvatar/svg/".concat(self.id.toString()).concat(".svg")
                    )
                )
            }

            if type == Type<MetadataViews.Traits>() {
                let traits: [MetadataViews.Trait] = []

                let series = self.getSeries()

                for k in self.layers.keys {
                    if(self.layers[k] != nil){
                        let layer = series!.layers[k]!
                        if(self.layers[k] != nil){
                            let layerSelf = self.layers[k]!
                            if(layer != nil){
                                let template = SportvatarTemplate.getTemplate(id: layerSelf!)
                                let trait = MetadataViews.Trait(name: layer!.name, value: template!.name, displayType:"String", rarity: MetadataViews.Rarity(score:nil, max:nil, description: template!.rarity))
                                traits.append(trait)
                            }
                        }
                    }
                }

                return MetadataViews.Traits(traits)
            }

            if type == Type<MetadataViews.NFTCollectionData>() {
                return MetadataViews.NFTCollectionData(
                storagePath: Sportvatar.CollectionStoragePath,
                publicPath: Sportvatar.CollectionPublicPath,
                providerPath: /private/SportvatarCollection,
                publicCollection: Type<&Sportvatar.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportvatar.CollectionPublic}>(),
                publicLinkedType: Type<&Sportvatar.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportvatar.CollectionPublic}>(),
                providerLinkedType: Type<&Sportvatar.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Sportvatar.CollectionPublic}>(),
                createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Sportvatar.createEmptyCollection()}
                )
            }


            return nil
        }
    }


    // Standard NFT collectionPublic interface that can also borrowSportvatar as the correct type
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSportvatar(id: UInt64): &Sportvatar.NFT{Sportvatar.Public, MetadataViews.Resolver}? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Sportvatar Dust Collectible reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Main Collection to manage all the Sportvatar NFT
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
            let token <- token as! @Sportvatar.NFT

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

        // borrowSportvatar returns a borrowed reference to a Sportvatar
        // so that the caller can read data and call methods from it.
        pub fun borrowSportvatar(id: UInt64): &Sportvatar.NFT{Sportvatar.Public, MetadataViews.Resolver}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let collectibleNFT = ref as! &Sportvatar.NFT
                return collectibleNFT as &Sportvatar.NFT{Sportvatar.Public, MetadataViews.Resolver}
            } else {
                return nil
            }
        }

        // borrowSportvatarPrivate returns a borrowed reference to a Sportvatar using the Private interface
        // so that the caller can read data and call methods from it, like setting the optional components.
        pub fun borrowSportvatarPrivate(id: UInt64): &{Sportvatar.Private}? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Sportvatar.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            pre {
                self.ownedNFTs[id] != nil : "NFT does not exist"
            }
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let collectibleNFT = nft as! &Sportvatar.NFT
            return collectibleNFT as &AnyResource{MetadataViews.Resolver}
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // This struct is used to send a data representation of the Sportvatar Dust Collectibles
    // when retrieved using the contract helper methods outside the collection.
    pub struct SportvatarData {
        pub let id: UInt64
        pub let mint: UInt64
        pub let series: UInt64
        pub let name: String
        pub let rarity: String
        pub let svg: String?
        pub let combination: String
        pub let creatorAddress: Address
        pub let layers: {UInt32: UInt64?}
        pub let bio: {String: String}
        pub let metadata: {String: String}
        pub let stats: {String: UInt32}
        init(
            id: UInt64,
            mint: UInt64,
            series: UInt64,
            name: String,
            rarity: String,
            svg: String?,
            combination: String,
            creatorAddress: Address,
            layers: {UInt32: UInt64?},
            bio: {String: String},
            metadata: {String: String},
            stats: {String: UInt32}
            ) {
            self.id = id
            self.mint = mint
            self.series = series
            self.name = name
            self.rarity = rarity
            self.svg = svg
            self.combination = combination
            self.creatorAddress = creatorAddress
            self.layers = layers
            self.bio = bio
            self.metadata = metadata
            self.stats = stats
        }
    }


    // This function will look for a specific Sportvatar on a user account and return a SportvatarData if found
    pub fun getSportvatar(address: Address, sportvatarId: UInt64) : SportvatarData? {

        let account = getAccount(address)

        if let collectibleCollection = account.getCapability(self.CollectionPublicPath).borrow<&Sportvatar.Collection{Sportvatar.CollectionPublic}>()  {
            if let collectible = collectibleCollection.borrowSportvatar(id: sportvatarId) {
                return SportvatarData(
                    id: sportvatarId,
                    mint: collectible!.mint,
                    series: collectible!.series,
                    name: collectible!.getName(),
                    rarity: collectible!.rarity,
                    svg: collectible!.getSvg(),
                    combination: collectible!.combination,
                    creatorAddress: collectible!.creatorAddress,
                    layers: collectible!.getLayers(),
                    bio: collectible!.getBio(),
                    metadata: collectible!.getMetadata(),
                    stats: collectible!.getStats()
                )
            }
        }
        return nil
    }

    // This function will return all Sportvatars on a user account and return an array of SportvatarData
    pub fun getSportvatars(address: Address) : [SportvatarData] {

        var sportvatarData: [SportvatarData] = []
        let account = getAccount(address)

        if let collectibleCollection = account.getCapability(self.CollectionPublicPath).borrow<&Sportvatar.Collection{Sportvatar.CollectionPublic}>()  {
            for id in collectibleCollection.getIDs() {
                if let collectible = collectibleCollection.borrowSportvatar(id: id) {
                    sportvatarData.append(SportvatarData(
                        id: id,
                        mint: collectible!.mint,
                        series: collectible!.series,
                        name: collectible!.getName(),
                        rarity: collectible!.rarity,
                        svg: nil,
                        combination: collectible!.combination,
                        creatorAddress: collectible!.creatorAddress,
                        layers: collectible!.getLayers(),
                        bio: collectible!.getBio(),
                        metadata: collectible!.getMetadata(),
                        stats: collectible!.getStats()
                    ))
                }
            }
        }
        return sportvatarData
    }


    // This returns all the previously minted combinations, so that duplicates won't be allowed
    pub fun getMintedCombinations() : [String] {
        return Sportvatar.mintedCombinations.keys
    }
    // This returns all the previously minted names, so that duplicates won't be allowed
    pub fun getMintedNames() : [String] {
        return Sportvatar.mintedNames.keys
    }

    // This function will add a minted combination to the array
    access(account) fun addMintedCombination(combination: String) {
        Sportvatar.mintedCombinations.insert(key: combination, true)
    }
    // This function will add a new name to the array
    access(account) fun addMintedName(name: String) {
        Sportvatar.mintedNames.insert(key: name, true)
    }

    pub fun getCoreLayers(series: UInt64, layers: {UInt32: UInt64?}): {UInt32: UInt64}{
        let coreLayers: {UInt32: UInt64} = {}
        for k in layers.keys {
            if(!SportvatarTemplate.isCollectibleLayerAccessory(layer: k, series: series)){
                let templateId = layers[k]!
                let template = SportvatarTemplate.getTemplate(id: templateId!)!
                if(template.series != series){
                    panic("Template belonging to the wrong Dust Collectible Series")
                }
                if(template.layer != k){
                    panic("Template belonging to the wrong Layer")
                }
                coreLayers[k] = templateId!
            }
        }

        return coreLayers
    }

    // This helper function will generate a string from a list of components,
    // to be used as a sort of barcode to keep the inventory of the minted
    // Sportvatars and to avoid duplicates
    pub fun getCombinationString(
        series: UInt64,
        layers: {UInt32: UInt64}
    ) : String {

        var combination: String = "S".concat(series.toString())
        var i: UInt32 = UInt32(2)
        while(i <  UInt32(9)){
            let layer = layers[i]!
            combination = combination.concat("-L").concat(i.toString()).concat("_").concat(layer.toString())
            i = i + UInt32(1)
        }

        return combination
    }

    // This function will get a list of component IDs and will check if the
    // generated string is unique or if someone already used it before.
    pub fun checkCombinationAvailable(
        series: UInt64,
        layers: {UInt32: UInt64}
    ) : Bool {
        let combinationString = Sportvatar.getCombinationString(
            series: series,
            layers: layers
        )
        return ! Sportvatar.mintedCombinations.containsKey(combinationString)
    }

    // This will check if a specific Name has already been taken
    // and assigned to some Sportvatar
    pub fun checkNameAvailable(name: String) : Bool {
        return name.length > 2 && name.length < 20 && ! Sportvatar.mintedNames.containsKey(name)
    }


    // This is a public function that anyone can call to generate a new Sportvatar
    // A list of components resources needs to be passed to executed.
    // It will check first for uniqueness of the combination + name and will then
    // generate the Sportvatar and burn all the passed components.
    // The Flame NFT will entitle to use any common basic component (body, hair, etc.)
    // In order to use special rare components a boost of the same rarity will be needed
    // for each component used
    pub fun createSportvatar(
        sportflame: @Sportbit.NFT,
        series: UInt64,
        layers: [UInt32],
        templateIds: [UInt64?],
        sportbits: @[Sportbit.NFT?],
        address: Address,
    ) : @Sportvatar.NFT {

        let seriesData = SportvatarTemplate.getSeries(id: series)
        if(seriesData == nil){
            panic("Dust Collectible Series not found!")
        }
        if(seriesData!.layers.length != layers.length){
            panic("The amount of layers is not matching!")
        }
        if(templateIds.length != layers.length){
            panic("The amount of layers and templates is not matching!")
        }
        let mintedCollectibles = SportvatarTemplate.getTotalMintedCollectibles(series: series)
        if(mintedCollectibles != nil){
            if(seriesData!.maxMintable > UInt64(0) && mintedCollectibles! >= seriesData!.maxMintable){
                panic("Reached the maximum mint number for this Series!")
            }
        }

        let templates: [SportvatarTemplate.TemplateData] = []
        let coreLayers: {UInt32: UInt64} = {}
        let fullLayers: {UInt32: UInt64?} = {}
        let flameRarity: String = sportflame.getRarity()
        let metadata: {String: String} = {}
        let stats: {String: UInt32} = {}



        if(sportflame.getLayer() != UInt32(0)) {
            panic("The Sport Flame belongs to the wrong category")
        }
        if(sportflame.getSeries() != series) {
            panic("The Sport Flame doesn't belong to the correct series")
        }


        var i: UInt32 = UInt32(0)
        while(i <  UInt32(layers.length)){
            let layerId: UInt32 = layers[i]!
            let templateId: UInt64? = templateIds[i] ?? nil
            if(!SportvatarTemplate.isCollectibleLayerAccessory(layer: layerId, series: series)){
                if(templateId == nil){
                    panic("Core Layer missing ".concat(layerId.toString()).concat(" - ").concat(i.toString()).concat("/").concat(layers.length.toString()))
                }
                let template = SportvatarTemplate.getTemplate(id: templateId!)!
                if(template.series != series){
                    panic("Template belonging to the wrong Series")
                }
                if(template.layer != layerId){
                    panic("Template belonging to the wrong Layer")
                }

                if(template.name == "clothing"){
                    metadata["sport"] = template.sport
                }

                let templateRarity: String = template.rarity
                var checkRarity: Bool = false

                if(flameRarity == "common"){
                    if(templateRarity  != "common"){
                        checkRarity = true
                    }
                } else if(flameRarity == "rare"){
                    if(templateRarity  == "epic" ||  templateRarity  == "legendary"){
                        checkRarity = true
                    }
                } else if(flameRarity == "epic"){
                    if(templateRarity  == "legendary"){
                        checkRarity = true
                    }
                }
                if(checkRarity){
                    panic("Sport Flame does not belong to the correct Rarity")
                }

                let totalMintedComponents: UInt64 = SportvatarTemplate.getTotalMintedComponents(id: template.id)!
                // Makes sure that the original minting limit set for each Template has not been reached
                if(template.maxMintableComponents > UInt64(0) && totalMintedComponents >= template.maxMintableComponents) {
                    panic("Reached maximum mintable count for this trait")
                }

                coreLayers[layerId] = template.id
                fullLayers[layerId] = template.id
                templates.append(template)

                SportvatarTemplate.increaseTotalMintedComponents(id: template.id)
                SportvatarTemplate.setLastComponentMintedAt(id: template.id, value: getCurrentBlock().timestamp)
            } else {
                fullLayers[layerId] = nil
            }

            i = i + UInt32(1)
        }



        // Generates the combination string to check for uniqueness.
        // This is like a barcode that defines exactly which components were used
        // to create the Sportvatar
        let combinationString = Sportvatar.getCombinationString(
            series: series,
            layers: coreLayers
            )

        // Makes sure that the combination is available and not taken already
        if(Sportvatar.mintedCombinations.containsKey(combinationString) == true) {
            panic("This combination has already been taken")
        }


        //Generate random stats based on the rarity level
        var minValue:UInt64 = 5
        var maxValue:UInt64 = 20
        if(flameRarity == "rare"){
            minValue = 20
            maxValue = 30
        } else if(flameRarity == "epic"){
            minValue = 30
            maxValue = 40
        } else if(flameRarity == "legendary"){
            minValue = 40
            maxValue = 51
        }

        var tempRand:Int64 = 0
        var tempOverall:UInt64 = RandomInt(uuid: unsafeRandom(), field: "overall", minValue: minValue, maxValue: maxValue).getValue()
        var tempMax:Int64 = 0
        var tempMin:Int64 = 5
        var pointsLeft:Int64 = Int64(tempOverall)


        //stats["overall"] = UInt32(tempOverall)


        tempMax = pointsLeft - Int64(4)
        tempMax = tempMax > Int64(10) ? Int64(10) : tempMax
        tempMin = pointsLeft - Int64(40)
        tempMin = tempMin < Int64(1) ? Int64(1) : tempMin
        tempRand = tempMin == tempMax ? tempMin : Int64(RandomInt(uuid: unsafeRandom(), field: "mental strength", minValue: UInt64(tempMin), maxValue: UInt64(tempMax) + UInt64(1)).getValue())
        stats["mental strength"] = UInt32(tempRand)
        pointsLeft = pointsLeft - tempRand

        tempMax = pointsLeft - Int64(3)
        tempMax = tempMax > Int64(10) ? Int64(10) : tempMax
        tempMin = pointsLeft - Int64(30)
        tempMin = tempMin < Int64(1) ? Int64(1) : tempMin
        tempRand = tempMin == tempMax ? tempMin : Int64(RandomInt(uuid: unsafeRandom(), field: "speed", minValue: UInt64(tempMin), maxValue: UInt64(tempMax) + UInt64(1)).getValue())
        stats["speed"] = UInt32(tempRand)
        pointsLeft = pointsLeft - tempRand

        tempMax = pointsLeft - Int64(2)
        tempMax = tempMax > Int64(10) ? Int64(10) : tempMax
        tempMin = pointsLeft - Int64(20)
        tempMin = tempMin < Int64(1) ? Int64(1) : tempMin
        tempRand = tempMin == tempMax ? tempMin : Int64(RandomInt(uuid: unsafeRandom(), field: "power", minValue: UInt64(tempMin), maxValue: UInt64(tempMax) + UInt64(1)).getValue())
        stats["power"] = UInt32(tempRand)
        pointsLeft = pointsLeft - tempRand

        tempMax = pointsLeft - Int64(1)
        tempMax = tempMax > Int64(10) ? Int64(10) : tempMax
        tempMin = pointsLeft - Int64(10)
        tempMin = tempMin < Int64(1) ? Int64(1) : tempMin
        tempRand = tempMin == tempMax ? tempMin : Int64(RandomInt(uuid: unsafeRandom(), field: "technique", minValue: UInt64(tempMin), maxValue: UInt64(tempMax) + UInt64(1)).getValue())
        stats["technique"] = UInt32(tempRand)
        pointsLeft = pointsLeft - tempRand
        stats["endurance"] = UInt32(pointsLeft)

        if(pointsLeft < Int64(1)){
            panic("Error distributing stat points to Sportvatar")
        }



        let royalties: [Royalty] = []

        royalties.append(Royalty(
            wallet: self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
            cut: Sportvatar.getMarketplaceCut(),
            type: RoyaltyType.percentage
        ))

        // Mint the new Sportvatar NFT by passing the metadata to it
        var newNFT <- create NFT(series: series, layers: fullLayers, metadata: metadata, stats: stats, creatorAddress: address, royalties: Royalties(royalty: royalties), rarity: flameRarity)

        // Adds the combination to the arrays to remember it
        Sportvatar.addMintedCombination(combination: combinationString)


        // Emits the Created event to notify about its existence
        emit Created(id: newNFT.id, mint: newNFT.mint, series: newNFT.series, address: address)


        i = UInt32(0)
        let sportbitLayers: {UInt32: UInt64} = {}
        while(i <  UInt32(sportbits.length)){
            let sportbitTemp <- sportbits[i] <- nil
            if(sportbitTemp != nil) {
                let tempLayer:UInt32 = sportbitTemp?.getLayer()!
                if(sportbitLayers[tempLayer] == nil){
                    sportbitLayers[tempLayer] = sportbitTemp?.getTemplate()?.id
                    let temp <- newNFT.setSportbit(layer: tempLayer, sportbit: <-sportbitTemp!)
                    if(temp != nil){
                        panic("Sportbit already set and preventing to be destroyed")
                    }
                    destroy temp
                } else {
                    destroy sportbitTemp
                    panic("Sending multiple Sportbits for the same Layer")
                }
            } else {
                destroy sportbitTemp
            }
        }

        destroy sportbits
        destroy sportflame

        return <- newNFT
    }



    // These functions will return the current Royalty cuts for
    // both the Creator and the Marketplace.
    pub fun getRoyaltyCut(): UFix64{
        return self.royaltyCut
    }
    pub fun getMarketplaceCut(): UFix64{
        return self.marketplaceCut
    }
    // Only Admins will be able to call the set functions to
    // manage Royalties and Marketplace cuts.
    access(account) fun setRoyaltyCut(value: UFix64){
        self.royaltyCut = value
    }
    access(account) fun setMarketplaceCut(value: UFix64){
        self.marketplaceCut = value
    }




    // This is the main Admin resource that will allow the owner
    // to generate new Templates, Components and Packs
    pub resource Admin {

        //This will create a new SportvatarTemplate that
        // contains all the SVG and basic informations to represent
        // a specific part of the Sportvatar (body, hair, eyes, mouth, etc.)
        // More info in the SportvatarTemplate.cdc file
        pub fun createSeries(
                        name: String,
                        description: String,
                        svgPrefix: String,
                        svgSuffix: String,
                        layers: {UInt32: SportvatarTemplate.Layer},
                        colors: {UInt32: String},
                        metadata: {String: String},
                        maxMintable: UInt64
                    ) : @SportvatarTemplate.Series {
            return <- SportvatarTemplate.createSeries(
                name: name,
                description: description,
                svgPrefix: svgPrefix,
                svgSuffix: svgSuffix,
                layers: layers,
                colors: colors,
                metadata: metadata,
                maxMintable: maxMintable
            )
        }
        //This will create a new SportvatarTemplate that
        // contains all the SVG and basic informations to represent
        // a specific part of the Sportvatar (body, hair, eyes, mouth, etc.)
        // More info in the SportvatarTemplate.cdc file
        pub fun createTemplate(
                        name: String,
                        description: String,
                        series: UInt64,
                        layer: UInt32,
                        metadata: {String: String},
                        rarity: String,
                        sport: String,
                        svg: String,
                        maxMintableComponents: UInt64
                    ) : @SportvatarTemplate.Template {
            return <- SportvatarTemplate.createTemplate(
                name: name,
                description: description,
                series: series,
                layer: layer,
                metadata: metadata,
                rarity: rarity,
                sport: sport,
                svg: svg,
                maxMintableComponents: maxMintableComponents
            )
        }


        //This will mint a new Component based from a selected Template
        pub fun createSportbit(templateId: UInt64) : @Sportbit.NFT {
            return <- Sportbit.createSportbit(templateId: templateId)
        }
        //This will mint Components in batch and return a Collection instead of the single NFT
        pub fun batchCreateSportbits(templateId: UInt64, quantity: UInt64) : @Sportbit.Collection {
            return <- Sportbit.batchCreateSportbits(templateId: templateId, quantity: quantity)
        }


        // This function will generate a new Pack containing a set of components.
        // A random string is passed to manage permissions for the
        // purchase of it (more info on SportvatarPack.cdc).
        // Finally the sale price is set as well.
        pub fun createPack(
            components: @[Sportbit.NFT],
            randomString: String,
            price: UFix64,
            flameCount: UInt32,
            series: UInt32,
            name: String
        ) : @SportvatarPack.Pack {

            return <- SportvatarPack.createPack(
                components: <-components,
                randomString: randomString,
                price: price,
                flameCount: flameCount,
                series: series,
                name: name
            )
        }


        // With this function you can generate a new Admin resource
        // and pass it to another user if needed
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

        // Helper functions to update the Royalty cut
        pub fun setRoyaltyCut(value: UFix64) {
            Sportvatar.setRoyaltyCut(value: value)
        }

        // Helper functions to update the Marketplace cut
        pub fun setMarketplaceCut(value: UFix64) {
            Sportvatar.setMarketplaceCut(value: value)
        }
    }





	init() {
        self.CollectionPublicPath = /public/SportvatarCollection
        self.CollectionStoragePath = /storage/SportvatarCollection
        self.AdminStoragePath = /storage/SportvatarAdmin

        // Initialize the total supply
        self.totalSupply = UInt64(0)
        self.mintedCombinations = {}
        self.mintedNames = {}

        // Set the default Royalty and Marketplace cuts
        self.royaltyCut = 0.01
        self.marketplaceCut = 0.05

        self.account.save<@NonFungibleToken.Collection>(<- Sportvatar.createEmptyCollection(), to: Sportvatar.CollectionStoragePath)
        self.account.link<&Sportvatar.Collection{Sportvatar.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Sportvatar.CollectionPublicPath, target: Sportvatar.CollectionStoragePath)

        // Put the Admin resource in storage
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
