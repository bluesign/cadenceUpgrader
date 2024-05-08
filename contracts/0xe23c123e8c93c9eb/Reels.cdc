import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// Reels
// NFT items for Reels!
//
pub contract Reels: NonFungibleToken {

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
    // The total number of Reels that have been minted
    //
    pub var totalSupply: UInt64

    // NFT
    // A Reel as an NFT
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
            return "Juke Reel NFT"
        }

        pub fun description(): String {
            return "Each Reel contains verified Frame digital collectibles."
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
                        name: "Reels Collection",
                        description: "This collection is used to store Reel NFTs.",
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
                            url: "https://media.juke.io/nft/image/dead_ringers_reel.png"
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://juke.io/"
                        // .concat(self.id.toString())
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Reels.CollectionStoragePath,
                        publicPath: Reels.CollectionPublicPath,
                        providerPath: /private/ReelsCollection,
                        publicCollection: Type<&Reels.Collection{Reels.ReelsCollectionPublic}>(),
                        publicLinkedType: Type<&Reels.Collection{Reels.ReelsCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Reels.Collection{Reels.ReelsCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Reels.createEmptyCollection()
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

    // This is the interface that users can cast their Reels Collection as
    // to allow others to deposit Reels into their Collection. It also allows for reading
    // the details of Reels in the Collection.
    pub resource interface ReelsCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowReel(id: UInt64): &Reels.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Reel reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Reel NFTs owned by an account
    //
    pub resource Collection: ReelsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @Reels.NFT

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

        // borrowReel
        // Gets a reference to an NFT in the collection as a Reel,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the Reel.
        //
        pub fun borrowReel(id: UInt64): &Reels.NFT? {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
            return ref as! &Reels.NFT?
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let reel = nft as! &Reels.NFT
            return reel as &AnyResource{MetadataViews.Resolver}
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
		pub fun mintNFT(recipient: &{Reels.ReelsCollectionPublic}, metadata: {String : String}) {
            emit Minted(id: Reels.totalSupply, metadata: metadata)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Reels.NFT(initID: Reels.totalSupply, initMetadata: metadata))

            Reels.totalSupply = Reels.totalSupply + (1 as UInt64)
		}
	}

    // fetch
    // Get a reference to a Reel from an account's Collection, if available.
    // If an account does not have a Reels.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Reels.NFT? {
        let collection = getAccount(from)
            .getCapability(Reels.CollectionPublicPath)!
            .borrow<&Reels.Collection{Reels.ReelsCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Reels.Collection.borowReel to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowReel(id: itemID)
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/ReelsCollection
        self.CollectionPublicPath = /public/ReelsCollection
        self.MinterStoragePath = /storage/ReelsMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
	}
}
 