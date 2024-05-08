
// Mainnet
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from 0x1d7e57aa55817448 

//Testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"

pub contract DriverzExclusive: NonFungibleToken {

	//Define Events
	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event ExclusiveMinted(id: UInt64, name: String, description: String, image: String, traits: {String:String})

	//Define Paths
	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
	pub let AdminStoragePath: StoragePath

	//Difine Total Supply
	pub var totalSupply: UInt64

	pub struct driverzExclusiveMetadata {
		pub let id: UInt64
		pub let name: String
		pub let description: String 
		pub let image: String
		pub let traits: {String:String}

		init(_id: UInt64, _name: String, _description: String, _image: String, _traits:{String:String}) {
			self.id = _id
			self.name = _name
			self.description = _description
			self.image = _image
			self.traits = _traits
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

		pub let id: UInt64
		pub let name: String
		pub let description: String
		pub var image: String
		pub let traits: {String: String}

		init( _id: UInt64, _name: String, _description: String, _image: String, _traits: {String:String}) {
			
			self.id = _id
			self.name = _name
			self.description = _description
			self.image = _image
			self.traits = _traits
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
				Type<DriverzExclusive.driverzExclusiveMetadata>(),
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
         			return MetadataViews.ExternalURL("https://driverz.world")

				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(
						storagePath: DriverzExclusive.CollectionStoragePath,
						publicPath: DriverzExclusive.CollectionPublicPath,
						providerPath: DriverzExclusive.CollectionPrivatePath,
						publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic}>(),
						publicLinkedType: Type<&Collection{DriverzExclusive.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
						providerLinkedType: Type<&Collection{DriverzExclusive.CollectionPublic, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, NonFungibleToken.Provider}>(),
						createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
								return <- DriverzExclusive.createEmptyCollection()
						})
					)

                case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(
						file: MetadataViews.HTTPFile(
							url: "https://driverzinc.io/DriverzNFT-logo.png"
						),
						mediaType: "image"
					)
					let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://driverzinc.io/DriverzNFT-logo.png"
                        ),
                        mediaType: "image"
                    )
					return MetadataViews.NFTCollectionDisplay(
						name: "Driverz Exclusive",
						description: "Driverz Exclusive Collection",
						externalURL: MetadataViews.ExternalURL("https://driverz.world"),
						squareImage: squareMedia,
						bannerImage: bannerMedia,
						socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/DriverzWorld/"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/driverz"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/driverzworld/")
						}
					)

				case Type<DriverzExclusive.driverzExclusiveMetadata>():
					return DriverzExclusive.driverzExclusiveMetadata(
						id: self.id,
						name: self.name,
						description: self.description,
						image: self.image,
						traits: self.traits
					)

                case Type<MetadataViews.NFTView>():
                    let viewResolver = &self as &{MetadataViews.Resolver}
                        return MetadataViews.NFTView(
                            id: self.id,
                            uuid: self.uuid,
                            display: MetadataViews.getDisplay(viewResolver),
                            externalURL: MetadataViews.getExternalURL(viewResolver),
                            collectionData: MetadataViews.getNFTCollectionData(viewResolver),
                            collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver),
                            royalties: MetadataViews.getRoyalties(viewResolver),
                            traits: MetadataViews.getTraits(viewResolver) 
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
        pub fun borrowDriverzExclusive(id: UInt64): &DriverzExclusive.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow DriverzExclusive reference: The ID of the returned reference is incorrect."
            }
        }
	}

	pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an 'UInt64' ID field
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
			let token <- token as! @DriverzExclusive.NFT

			let id: UInt64 = token.id

			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

        destroy oldToken
			
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let mainNFT = nft as! &DriverzExclusive.NFT
            return mainNFT
		}


		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

       pub fun borrowDriverzExclusive(id: UInt64): &DriverzExclusive.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DriverzExclusive.NFT
            } else {
                return nil
            }
        } 

		init () {
			self.ownedNFTs <- {}
		}

		destroy() {
			destroy self.ownedNFTs
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
            traits: {String:String}
            ) {
			    emit ExclusiveMinted(id: DriverzExclusive.totalSupply, name: name, description: description, image: image, traits: traits)
			    DriverzExclusive.totalSupply = DriverzExclusive.totalSupply + (1 as UInt64)

			recipient.deposit(token: <- create DriverzExclusive.NFT(
                initID: DriverzExclusive.totalSupply,
                name: name,
                description: description,
                image: image,
                traits: traits
                )
			)
		}	
	}

	init() {
		
		self.CollectionStoragePath = /storage/DriverzExclusiveCollection
		self.CollectionPublicPath = /public/DriverzExclusiveCollection
		self.CollectionPrivatePath = /private/DriverzExclusiveCollection
		self.AdminStoragePath = /storage/DriverzExclusiveMinter

		self.totalSupply = 0

		let minter <- create Admin()
		self.account.save(<-minter, to: self.AdminStoragePath)

		let collection <- DriverzExclusive.createEmptyCollection()
		self.account.save(<- collection, to: self.CollectionStoragePath)

		// create a public capability for the collection
		self.account.link<&DriverzExclusive.Collection{NonFungibleToken.CollectionPublic, DriverzExclusive.CollectionPublic}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		
		emit ContractInitialized()
	}
}
