import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract ExampleNFT: NonFungibleToken, ViewResolver {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let serial: UInt64
        pub let extraMetadata: {String: AnyStruct}

        init(
            name: String,
            description: String,
            thumbnail: String,
            extraMetadata: {String: AnyStruct}
        ) {
            self.id = self.uuid
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.serial = ExampleNFT.totalSupply
            self.extraMetadata = extraMetadata

            ExampleNFT.totalSupply = ExampleNFT.totalSupply + 1
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.serial
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([
                        MetadataViews.Royalty(
                            receiver: ExampleNFT.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
                            cut: 0.05,
                            description: "Royalty for creating the NFTs."
                        )   
                    ])
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://academy.ecdao.org/en/quickstarts/1-non-fungible-token-svelte")
                case Type<MetadataViews.NFTCollectionData>():
                    return ExampleNFT.resolveView(view)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return ExampleNFT.resolveView(view)
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let excludedTraits: [String] = ["mintedTime", "foo"]
                    let traitsView: MetadataViews.Traits = MetadataViews.dictToTraits(dict: self.extraMetadata, excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait: MetadataViews.Trait = MetadataViews.Trait(name: "mintedTime", value: self.extraMetadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)

                    return traitsView
            }
            return nil
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token: @NFT <- token as! @ExampleNFT.NFT

            let id: UInt64 = token.uuid

            // add the new token to the dictionary which removes the old one
            self.ownedNFTs[id] <-! token

            emit Deposit(id: id, to: self.owner?.address)
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

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT: &NFT = nft as! &ExampleNFT.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        init () {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource Minter {
        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(
            recipient: &ExampleNFT.Collection{NonFungibleToken.CollectionPublic},
            name: String,
            description: String,
            thumbnail: String,
            extraMetadata: {String: AnyStruct}
        ) {
            let currentBlock: Block = getCurrentBlock()
            extraMetadata["mintedBlock"] = currentBlock.height
            extraMetadata["mintedTime"] = currentBlock.timestamp
            extraMetadata["minter"] = recipient.owner!.address

            // create a new NFT
            var newNFT: @NFT <- create NFT(
                name: name,
                description: description,
                thumbnail: thumbnail,
                extraMetadata: extraMetadata
            )

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <- newNFT)
        }
    }

    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.NFTCollectionData>()
        ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: ExampleNFT.CollectionStoragePath,
                    publicPath: ExampleNFT.CollectionPublicPath,
                    providerPath: /private/exampleNFTCollection,
                    publicCollection: Type<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                    publicLinkedType: Type<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-ExampleNFT.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "The Example Collection",
                    description: "This collection is used as an example to help you develop your next Flow NFT.",
                    externalURL: MetadataViews.ExternalURL("https://academy.ecdao.org/en/quickstarts/1-non-fungible-token"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/emerald_dao")
                    }
                )
        }
        return nil
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/EmeraldAcademyNonFungibleTokenCollection
        self.CollectionPublicPath = /public/EmeraldAcademyNonFungibleTokenCollection
        self.MinterStoragePath = /storage/EmeraldAcademyNonFungibleTokenMinter

        self.account.save(<- create Minter(), to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 