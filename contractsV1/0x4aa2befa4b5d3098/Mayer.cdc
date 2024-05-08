import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Mayer: NonFungibleToken{ 
	access(all)
	let version: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// The total number of Mayer NFTs that have been minted.
	///
	access(all)
	var totalSupply: UInt64
	
	/// A list of royalty recipients that is attached to all NFTs
	/// minted by this contract.
	///
	access(contract)
	var royalties: [MetadataViews.Royalty]
	
	/// Return the royalty recipients for this contract.
	///
	access(all)
	fun getRoyalties(): [MetadataViews.Royalty]{ 
		return Mayer.royalties
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let image: String
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		init(image: String, serialNumber: UInt64, name: String, description: String){ 
			self.image = image
			self.serialNumber = serialNumber
			self.name = name
			self.description = description
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		init(metadata: Metadata){ 
			self.id = self.uuid
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.resolveDisplay(self.metadata)
				case Type<MetadataViews.ExternalURL>():
					return self.resolveExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.resolveNFTCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return self.resolveNFTCollectionData()
				case Type<MetadataViews.Royalties>():
					return self.resolveRoyalties()
				case Type<MetadataViews.Serial>():
					return self.resolveSerial(self.metadata)
			}
			return nil
		}
		
		access(all)
		fun resolveDisplay(_ metadata: Metadata): MetadataViews.Display{ 
			return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.image, path: nil))
		}
		
		access(all)
		fun resolveExternalURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("https://flute-app.vercel.app/".concat(self.id.toString()))
		}
		
		access(all)
		fun resolveNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let media = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafkreicrfbblmaduqg2kmeqbymdifawex7rxqq2743mitmeia4zdybmmre", path: nil), mediaType: "image/jpeg")
			return MetadataViews.NFTCollectionDisplay(name: "mayer", description: "a", externalURL: MetadataViews.ExternalURL("https://flute-app.vercel.app"), squareImage: media, bannerImage: media, socials:{} )
		}
		
		access(all)
		fun resolveNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: Mayer.CollectionStoragePath, publicPath: Mayer.CollectionPublicPath, publicCollection: Type<&Mayer.Collection>(), publicLinkedType: Type<&Mayer.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-Mayer.createEmptyCollection(nftType: Type<@Mayer.Collection>())
				})
		}
		
		access(all)
		fun resolveRoyalties(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties(Mayer.royalties)
		}
		
		access(all)
		fun resolveSerial(_ metadata: Metadata): MetadataViews.Serial{ 
			return MetadataViews.Serial(metadata.serialNumber)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface MayerCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMayer(id: UInt64): &Mayer.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Mayer reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MayerCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		/// A dictionary of all NFTs in this collection indexed by ID.
		///
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Remove an NFT from the collection and move it to the caller.
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT to withdraw does not exist in this collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Deposit an NFT into this collection.
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Mayer.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Return an array of the NFT IDs in this collection.
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Return a reference to an NFT in this collection.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as Mayer.NFT.
		///
		/// This function returns nil if the NFT does not exist in this collection.
		///
		access(all)
		fun borrowMayer(id: UInt64): &Mayer.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Mayer.NFT
			}
			return nil
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as MetadataViews.Resolver.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &Mayer.NFT
			return nftRef as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Return a new empty collection.
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// The administrator resource used to mint and reveal NFTs.
	///
	access(all)
	resource Admin{ 
		
		/// Mint a new NFT.
		///
		/// To mint an NFT, specify a value for each of its metadata fields.
		///
		access(all)
		fun mintNFT(image: String, serialNumber: UInt64, name: String, description: String): @Mayer.NFT{ 
			let metadata = Metadata(image: image, serialNumber: serialNumber, name: name, description: description)
			let nft <- create Mayer.NFT(metadata: metadata)
			emit Minted(id: nft.id)
			Mayer.totalSupply = Mayer.totalSupply + 1 as UInt64
			return <-nft
		}
		
		/// Set the royalty recipients for this contract.
		///
		/// This function updates the royalty recipients for all NFTs
		/// minted by this contract.
		///
		access(all)
		fun setRoyalties(_ royalties: [MetadataViews.Royalty]){ 
			Mayer.royalties = royalties
		}
	}
	
	/// Return a public path that is scoped to this contract.
	///
	access(all)
	fun getPublicPath(suffix: String): PublicPath{ 
		return PublicPath(identifier: "Mayer_".concat(suffix))!
	}
	
	/// Return a private path that is scoped to this contract.
	///
	access(all)
	fun getPrivatePath(suffix: String): PrivatePath{ 
		return PrivatePath(identifier: "Mayer_".concat(suffix))!
	}
	
	/// Return a storage path that is scoped to this contract.
	///
	access(all)
	fun getStoragePath(suffix: String): StoragePath{ 
		return StoragePath(identifier: "Mayer_".concat(suffix))!
	}
	
	access(self)
	fun initAdmin(admin: AuthAccount){ 
		// Create an empty collection and save it to storage
		let collection <- Mayer.createEmptyCollection(nftType: Type<@Mayer.Collection>())
		admin.save(<-collection, to: Mayer.CollectionStoragePath)
		admin.link<&Mayer.Collection>(Mayer.CollectionPrivatePath, target: Mayer.CollectionStoragePath)
		admin.link<&Mayer.Collection>(Mayer.CollectionPublicPath, target: Mayer.CollectionStoragePath)
		
		// Create an admin resource and save it to storage
		let adminResource <- create Admin()
		admin.save(<-adminResource, to: self.AdminStoragePath)
	}
	
	init(){ 
		self.version = "0.0.32"
		self.CollectionPublicPath = Mayer.getPublicPath(suffix: "Collection")
		self.CollectionStoragePath = Mayer.getStoragePath(suffix: "Collection")
		self.CollectionPrivatePath = Mayer.getPrivatePath(suffix: "Collection")
		self.AdminStoragePath = Mayer.getStoragePath(suffix: "Admin")
		self.royalties = []
		self.totalSupply = 0
		self.initAdmin(admin: self.account)
		emit ContractInitialized()
	}
}
