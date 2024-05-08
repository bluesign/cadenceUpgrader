import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// The Crash contract containing sub-types and their specification:
//
// - Events
// - The Crash NFT Resource
// - MetadataViews that it supports, and their content
// - The Collection Resource
// - Minter Resource
// - init() function
pub contract Crash: NonFungibleToken {

    // totalSupply
    // The total number of Crash that have been minted
    //
    pub var totalSupply: UInt64

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, component: CrashComponent)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub struct CrashComponent {
        pub var background: String
        pub var longHair: String
        pub var backAccessory: String
        pub var outfitBack: String
        pub var headgearBack: String
        pub var neck: String
        pub var outfitFront: String
        pub var head: String
        pub var cheekMarkings: String
        pub var forehead: String
        pub var implants: String
        pub var piercings: String
        pub var sideHeadMarkings: String
        pub var mouth: String
        pub var eyes: String
        pub var mohawks: String
        pub var hair: String
        pub var eyegear: String
        pub var headgearFront: String

        init(background: String, longHair: String, backAccessory: String, outfitBack: String, headgearBack: String, neck: String, outfitFront: String, 
            head: String, cheekMarkings: String, forehead: String, implants: String, piercings: String, sideHeadMarkings: String, mouth: String, eyes: String, 
            mohawks: String, hair: String, eyegear: String, headgearFront: String) {
            self.background = background
            self.longHair = longHair
            self.backAccessory = backAccessory
            self.outfitBack = outfitBack
            self.headgearBack = headgearBack
            self.neck = neck
            self.outfitFront = outfitFront
            self.head = head
            self.cheekMarkings = cheekMarkings
            self.forehead = forehead
            self.implants = implants
            self.piercings = piercings
            self.sideHeadMarkings = sideHeadMarkings
            self.mouth = mouth
            self.eyes = eyes
            self.mohawks = mohawks
            self.hair = hair
            self.eyegear = eyegear
            self.headgearFront = headgearFront
        }
    }

    // pub fun componentToString(_ component: CrashComponent): String {
    //     return component.background.toString()
    //     .concat("-")
    //     .concat(component.head.toString())
    //     .concat("-")
    //     .concat(component.torso.toString())
    //     .concat("-")
    //     .concat(component.legs.toString())
    // }
    
    // A Crash Item as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub fun name(): String {
            return "Crash"
                .concat(" #")
                .concat(self.id.toString())
        }
        
        pub fun description(): String {
            return "Crash "
                .concat(" with serial number ")
                .concat(self.id.toString())
        }


        pub fun thumbnail(): MetadataViews.HTTPFile {
          return MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/Qmb84UcaMr1MUwNbYBnXWHM3kEaDcYrKuPWwyRLVTNKELC/".concat(self.id.toString()).concat(".png"))
        }

        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}


        pub let component: Crash.CrashComponent

        init(
            id: UInt64,
            royalties: [MetadataViews.Royalty],
            metadata: {String: AnyStruct},
            component: Crash.CrashComponent,    
        ){
            self.id = id
            self.royalties = royalties
            self.metadata = metadata
            self.component = component
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description(),
                        thumbnail: self.thumbnail()
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Crash NFT Edition", number: self.id, max: nil)
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
                    return MetadataViews.ExternalURL("https://nftbridges.xyz/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Crash.CollectionStoragePath,
                        publicPath: Crash.CollectionPublicPath,
                        providerPath: /private/CrashCollection,
                        publicCollection: Type<&Crash.Collection{Crash.CrashCollectionPublic}>(),
                        publicLinkedType: Type<&Crash.Collection{Crash.CrashCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Crash.Collection{Crash.CrashCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Crash.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://nftbridges.xyz/wp-content/uploads/2023/02/NFT_1.png"
                        ),
                        mediaType: "image/png"
                    )

                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://nftbridges.xyz/wp-content/uploads/2023/02/NFT_1.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Crash Collection",
                        description: "This collection is used as an example for the NFT bridge",
                        externalURL: MetadataViews.ExternalURL("https://nftbridges.xyz/"),
                        squareImage: media,
                        bannerImage: bannerMedia,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime", "foo"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    return traitsView
            }
            return nil 
        }
    }

    // This is the interface that users can cast their Crash Collection as
    // to allow others to deposit Crash into their Collection. It also allows for reading
    // the details of Crash in the Collection.
    pub resource interface CrashCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowCrash(id: UInt64): &Crash.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Crash reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Crash NFTs owned by an account
    //
    pub resource Collection: CrashCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }

        // withdraw 
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit 
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Crash.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs 
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT 
        // gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowCrash
        // Gets a reference to an NFT in the collection as a Crash,
        // exposing all of its fields (including the typeID & rarityID).
        // This is safe as there are no functions that can be called on the Crash.
        //
        pub fun borrowCrash(id: UInt64): &Crash.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Crash.NFT
            } else {
                return nil
            }    
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let Crash = nft as! &Crash.NFT
            return Crash as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        //
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            component: Crash.CrashComponent,
            royalties: [MetadataViews.Royalty],
            id: UInt64
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address
            metadata["background"] = component.background
            metadata["longHair"] = component.longHair
            metadata["backAccessory"] = component.backAccessory
            metadata["outfitBack"] = component.outfitBack
            metadata["headgearBack"] = component.headgearBack
            metadata["neck"] = component.neck
            metadata["outfitFront"] = component.outfitFront
            metadata["head"] = component.head
            metadata["cheekMarkings"] = component.cheekMarkings
            metadata["forehead"] = component.forehead
            metadata["implants"] = component.implants
            metadata["piercings"] = component.piercings
            metadata["sideHeadMarkings"] = component.sideHeadMarkings
            metadata["mouth"] = component.mouth
            metadata["eyes"] = component.eyes
            metadata["mohawks"] = component.mohawks
            metadata["hair"] = component.hair
            metadata["eyegear"] = component.eyegear
            metadata["headgearFront"] = component.headgearFront

            // this piece of metadata will be used to show embedding rarity into a trait
            // metadata["foo"] = "bar"

            emit Minted(
                id: id,
                component: component,
            )

            Crash.totalSupply = Crash.totalSupply + UInt64(1)

            // create a new NFT
            var newNFT <- create Crash.NFT(
                id: id,
                royalties: royalties,
                metadata: metadata,
                component: component, 
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
        }
    }

    // fetch
    // Get a reference to a Crash from an account's Collection, if available.
    // If an account does not have a Crash.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Crash.NFT? {
        let collection = getAccount(from)
            .getCapability(Crash.CollectionPublicPath)!
            .borrow<&Crash.Collection{Crash.CrashCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Crash.Collection.borowCrash to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowCrash(id: itemID)
    }

    // initializer
    //
    init() {

        // Initialize the total supply
        self.totalSupply = 0

        // Set our named paths
        self.CollectionStoragePath = /storage/CrashCollection
        self.CollectionPublicPath = /public/CrashCollection
        self.MinterStoragePath = /storage/CrashMinter

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // Create a public capability for the collection
        self.account.link<&Crash.Collection{NonFungibleToken.CollectionPublic, Crash.CrashCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 