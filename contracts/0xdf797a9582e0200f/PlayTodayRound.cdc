import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract PlayTodayRound: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event CollectionCreated(address:Address?)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, creator: Address)
    pub event Destroy(id: UInt64)
    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of PlayTodayRound that have been minted
    //
    pub var totalSupply: UInt64

    // A Play Today Badge NFT as an NFT
    //  
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        pub let id: UInt64
        pub let game_id: UInt64
        pub let user_id: UInt64
        pub let creator: Address
        pub let hash: String
 

        access(self) let royalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}
        
        init(id: UInt64, game_id: UInt64, user_id:UInt64,   creator: Address, hash:String, royalties: [MetadataViews.Royalty], metadata: {String: AnyStruct}) {  
            self.id = id
            self.game_id = game_id
            self.user_id = user_id
            self.creator = creator
            self.hash = hash
            self.royalties = royalties
            self.metadata = metadata
        }

 
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                )
                // case Type<MetadataViews.Display>():
                //     return MetadataViews.Display(
                //         name: self.id,
                //         description: "",
                //         thumbnail: MetadataViews.HTTPFile(
                //             url: "https://ipfs.filebase.io/ipfs/".concat(self.uri)
                //         )
                //     )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://playtodaynft.com/badge/".concat(self.owner?.address?.toString()!).concat("/").concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: PlayTodayRound.CollectionStoragePath,
                        publicPath: PlayTodayRound.CollectionPublicPath,
                        providerPath: /private/PlayTodayRoundCollection,
                        publicCollection: Type<&PlayTodayRound.Collection{PlayTodayRound.PlayTodayRoundCollectionPublic}>(),
                        publicLinkedType: Type<&PlayTodayRound.Collection{PlayTodayRound.PlayTodayRoundCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&PlayTodayRound.Collection{PlayTodayRound.PlayTodayRoundCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-PlayTodayRound.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://s3.ap-southeast-2.amazonaws.com/files.playtoday.cc/PT_NFT_B.jpg"
                        ),
                        mediaType: "image/svg+xml"
                    )

                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://s3.ap-southeast-2.amazonaws.com/files.playtoday.cc/PT_NFT_B.jpg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Play Today Badge Collection",
                        description: "PlayToday.NFT is the world's first Web3 golf project developed with Players for the Players.",
                        externalURL: MetadataViews.ExternalURL("https://playtodaynft.com"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/PlayTodayRound"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/playtoday.nft/"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/6H3J85UU"),
                            "facebook": MetadataViews.ExternalURL("https://www.facebook.com/playtodaynft"),
                            "linkedin":MetadataViews.ExternalURL("https://www.linkedin.com/company/playtodaygolf")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits = ["mintedTime"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date",rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    
                    return traitsView
            }
      
            
            return nil
        }

        destroy() {
            emit Destroy(id: self.id)
        }
    }
    // This is the interface that users can cast their PlayTodayRound Collection as
    // to allow others to deposit PlayTodayRound into their Collection. It also allows for reading
    // the details of PlayTodayRound in the Collection.
    pub resource interface PlayTodayRoundCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPlayTodayRound(id: UInt64): &PlayTodayRound.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow PlayTodayRound reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of PlayTodayRound NFTs owned by an account
    //
    pub resource Collection: PlayTodayRoundCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @PlayTodayRound.NFT
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

        // borrowPlayTodayRound
        // Gets a reference to an NFT in the collection as a PlayTodayRound,
        // This is safe as there are no functions that can be called on the PlayTodayRound.
        //
        pub fun borrowPlayTodayRound(id: UInt64): &PlayTodayRound.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &PlayTodayRound.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let PlayTodayRound = nft as! &PlayTodayRound.NFT
            return PlayTodayRound as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
            emit CollectionCreated(address: self.owner?.address)
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
            game_id: UInt64,
            user_id: UInt64,
            creator: Address,
            hash: String,

            royalties: [MetadataViews.Royalty]
        ) {
            let metadata: {String: AnyStruct} = {}
            let currentBlock = getCurrentBlock()
            metadata["mintedBlock"] = currentBlock.height
            metadata["mintedTime"] = currentBlock.timestamp
            metadata["minter"] = recipient.owner!.address
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-create PlayTodayRound.NFT(
                id: PlayTodayRound.totalSupply, 
                game_id: game_id,
                user_id: user_id,
                creator: creator,
                hash: hash, 
                royalties: royalties,
                metadata: metadata
                ))

            emit Minted(
                id: PlayTodayRound.totalSupply, 
                creator: creator, 
       
            )
            PlayTodayRound.totalSupply = PlayTodayRound.totalSupply + (1 as UInt64)
        }
    }
    // fetch
    // Get a reference to a PlayTodayRound from an account's Collection, if available.
    // If an account does not have a PlayTodayRound.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &PlayTodayRound.NFT? {
        let collection = getAccount(from)
            .getCapability(PlayTodayRound.CollectionPublicPath)!
            .borrow<&PlayTodayRound.Collection{PlayTodayRound.PlayTodayRoundCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust PlayTodayRound.Collection.borowPlayTodayRound to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowPlayTodayRound(id: itemID)
    }

    // initializer
    //
    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/PlayTodayRoundCollection
        self.CollectionPublicPath = /public/PlayTodayRoundCollection
        self.MinterStoragePath = /storage/PlayTodayRoundMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)
        // self.account.link<&NFTMinter>(self.MinterPublicPath, target: self.MinterStoragePath)

        // create a public capability for the collection
        self.account.link<&PlayTodayRound.Collection{NonFungibleToken.CollectionPublic, PlayTodayRound.PlayTodayRoundCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
        self.account.link<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        
        emit ContractInitialized()
    }
}
 