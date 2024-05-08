import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// Frames
// NFT items for Frames!
//
pub contract Frames: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, metadata: {String : String})

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of Frames that have been minted
    //
    pub var totalSupply: UInt64

    // NFT
    // A Frame as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // The token's ID
        pub let id: UInt64
        // The token's type, e.g. 3 == Hat
        pub let metadata: {String : String}

        // initializer
        //
        init(initID: UInt64, initMetadata: {String : String}) {
            self.id = initID
            self.metadata = initMetadata
        }

        pub fun name(): String {
            return "Juke Frame NFT"
        }

        pub fun description(): String {
            return "A verified Frame digital collectible."
        }


        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/621f4dcf0da11e4f2d3b64c3/6372a0fe2d013229476dd8dc_Juke-HZ-Black-p-500.png"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Frames Collection",
                        description: "This collection is used to store Frame NFTs.",
                        externalURL: MetadataViews.ExternalURL("https://juke.io"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/JukeFrames")
                        }
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([
                    MetadataViews.Royalty(
                        receiver: getAccount(0x17599e9dfd41a150).getCapability<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath()),
                        cut: 0.05000000,
                        description: ""
                    )
                ])
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description(),
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata["imageUrl"]!
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://juke.io/"
                        // .concat(self.id.toString())
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Frames.CollectionStoragePath,
                        publicPath: Frames.CollectionPublicPath,
                        providerPath: /private/FramesCollection,
                        publicCollection: Type<&Frames.Collection{Frames.FramesCollectionPublic}>(),
                        publicLinkedType: Type<&Frames.Collection{Frames.FramesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Frames.Collection{Frames.FramesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Frames.createEmptyCollection()
                        })
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

    // This is the interface that users can cast their Frames Collection as
    // to allow others to deposit Frames into their Collection. It also allows for reading
    // the details of Frames in the Collection.
    pub resource interface FramesCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFrame(id: UInt64): &Frames.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Frame reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Frame NFTs owned by an account
    //
    pub resource Collection: FramesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Frames.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowFrame
        // Gets a reference to an NFT in the collection as a Frame,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the Frame.
        //
        pub fun borrowFrame(id: UInt64): &Frames.NFT? {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return ref as! &Frames.NFT?
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let frame = nft as! &Frames.NFT
            return frame as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
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
		pub fun mintNFT(recipient: &{Frames.FramesCollectionPublic}, metadata: {String : String}) {
            emit Minted(id: Frames.totalSupply, metadata: metadata)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Frames.NFT(initID: Frames.totalSupply, initMetadata: metadata))

            Frames.totalSupply = Frames.totalSupply + (1 as UInt64)
		}
	}

    // fetch
    // Get a reference to a Frame from an account's Collection, if available.
    // If an account does not have a Frames.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Frames.NFT? {
        let collection = getAccount(from)
            .getCapability(Frames.CollectionPublicPath)!
            .borrow<&Frames.Collection{Frames.FramesCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Frames.Collection.borowFrame to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowFrame(id: itemID)
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/FramesCollection
        self.CollectionPublicPath = /public/FramesCollection
        self.MinterStoragePath = /storage/FramesMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
	}
}
 