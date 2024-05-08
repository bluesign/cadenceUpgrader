import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract DigiBuddies: NonFungibleToken {

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event DigiBuddiesMinted(id: UInt64, name: String, description: String, image: String, traits: {String: String})

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath

    pub var totalSupply: UInt64

    pub struct DigiBuddiesMetadata {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let image: String
        pub let traits: {String: String}

        init(id: UInt64 ,name: String, description: String, image: String, traits: {String: String}) {
            self.id = id
            self.name=name
            self.description = description
            self.image = image
            self.traits = traits
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub var image: String
        pub let traits: {String: String}

        init(id: UInt64 ,name: String, description: String, image: String, traits: {String: String}) {
            self.id = id
            self.name=name
            self.description = description
            self.image = image
            self.traits = traits
        }

        pub fun revealThumbnail() {
            let urlBase = self.image.slice(from: 0, upTo: 47)
            let newImage = urlBase.concat(self.id.toString()).concat(".png")
            self.image = newImage
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTView>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<DigiBuddies.DigiBuddiesMetadata>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.image,
                            path: nil
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://digibuddies.xyz")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: DigiBuddies.CollectionStoragePath,
                        publicPath: DigiBuddies.CollectionPublicPath,
                        providerPath: DigiBuddies.CollectionPrivatePath,
                        publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic}>(),
                        publicLinkedType: Type<&Collection{DigiBuddies.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Collection{DigiBuddies.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <- DigiBuddies.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                           url: "https://digibuddies.xyz/logo.png"
                        ),
                        mediaType: "image"
                    )
                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://digibuddies.xyz/logo.png"
                        ),
                        mediaType: "image"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "DigiBuddies",
                        description: "DigiBuddies Collection",
                        externalURL: MetadataViews.ExternalURL("https://digibuddies.xyz"),
                        squareImage: squareMedia,
                        bannerImage: bannerMedia,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/@digibuddiesxyz"),
                            "instagram": MetadataViews.ExternalURL("https://instagram.com/@digibuddies.xyz")
                        }
                    )
                case Type<DigiBuddies.DigiBuddiesMetadata>():
                    return DigiBuddies.DigiBuddiesMetadata(
                        id: self.id,
                        name: self.name,
                        description: self.description,
                        image: self.image,
                        traits: self.traits
                    )
                case Type<MetadataViews.NFTView>(): 
                let viewResolver = &self as &{MetadataViews.Resolver}
                return MetadataViews.NFTView(
                    id : self.id,
                    uuid: self.uuid,
                    display: MetadataViews.getDisplay(viewResolver),
                    externalURL : MetadataViews.getExternalURL(viewResolver),
                    collectionData : MetadataViews.getNFTCollectionData(viewResolver),
                    collectionDisplay : MetadataViews.getNFTCollectionDisplay(viewResolver),
                    royalties : MetadataViews.getRoyalties(viewResolver),
                    traits : MetadataViews.getTraits(viewResolver)
                )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    for trait in self.traits.keys {
                        traits.append(MetadataViews.Trait(
                            trait: trait,
                            value: self.traits[trait]!,
                            displayType: nil,
                            rarity: nil
                        ))
                    }
                    return MetadataViews.Traits(traits: traits)
            }
            return nil
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDigiBuddies(id: UInt64): &DigiBuddies.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow DigiBuddies reference: The ID of the returned reference is incorrect"
            }
        }        
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @DigiBuddies.NFT

            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let mainNFT = nft as! &DigiBuddies.NFT
            return mainNFT
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowDigiBuddies(id: UInt64): &DigiBuddies.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DigiBuddies.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }

        pub fun deleteAllNFTs() {
            let ids = self.getIDs()

            for id in ids {
                let nftToBurn <- self.withdraw(withdrawID: id)
                destroy nftToBurn
            }
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

	pub resource Admin {
		pub fun mintNFT(
		recipient: &{NonFungibleToken.CollectionPublic},
		name: String,
        description: String,
        image: String,
        traits: {String: String}
        ) {
            emit DigiBuddiesMinted(id: DigiBuddies.totalSupply, name: name, description: description, image: image, traits: traits)

            DigiBuddies.totalSupply = DigiBuddies.totalSupply + (1 as UInt64)
            
			recipient.deposit(token: <- create DigiBuddies.NFT(
			    initID: DigiBuddies.totalSupply,
                name: name,
                description: description,
			    image:image,
                traits: traits
                )
            )
		}
	}

    pub fun reset() {
        self.totalSupply = 0
    }

    init() {
        self.CollectionStoragePath = /storage/DigiBuddiesCollection
        self.CollectionPublicPath = /public/DigiBuddiesCollection
        self.CollectionPrivatePath = /private/DigiBuddiesCollection
        self.AdminStoragePath = /storage/DigiBuddiesMinter

        self.totalSupply = 0

        let minter <- create Admin()
        self.account.save(<-minter, to: self.AdminStoragePath)

        let collection <- DigiBuddies.createEmptyCollection()
        self.account.save(<-collection, to: DigiBuddies.CollectionStoragePath)
        self.account.link<&DigiBuddies.Collection{NonFungibleToken.CollectionPublic, DigiBuddies.CollectionPublic}>(DigiBuddies.CollectionPublicPath, target: DigiBuddies.CollectionStoragePath)

        emit ContractInitialized()
    }
}