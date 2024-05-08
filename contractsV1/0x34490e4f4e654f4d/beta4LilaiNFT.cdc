import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract beta4LilaiNFT: NonFungibleToken, ViewResolver{ 
	/// Total supply of beta4LilaiNFTs in existence
	access(all)
	var totalSupply: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an NFT is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// The event that is emitted when the Lilaiputia field of an NFT is updated
	access(all)
	event LilaiputiaUpdated(id: UInt64, updater: Address?, newLilaiputiaData: String)
	
	// Event when an nft is minted
	access(all)
	event NFTMinted(id: UInt64)
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// The core resource that represents a Non Fungible Token.
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		/// Metadata fields
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(self)
		var lilaiputia: String // Mutable field for Lilaiputia data
		
		
		init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}, lilaiputia: String){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
			self.lilaiputia = lilaiputia
		}
		
		/// Function to update the Lilaiputia field
		access(all)
		fun updateLilaiputia(newLilaiputiaData: String){ 
			self.lilaiputia = newLilaiputiaData
			emit LilaiputiaUpdated(id: self.id, updater: self.owner?.address, newLilaiputiaData: newLilaiputiaData)
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		/// Function that resolves a metadata view for this token.
		///
		/// @param view: The Type of the desired view.
		/// @return A structure representing the requested view.
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "Lilaiputian NFTs", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("http://www.lilaiputia.com/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: beta4LilaiNFT.CollectionStoragePath, publicPath: beta4LilaiNFT.CollectionPublicPath, publicCollection: Type<&beta4LilaiNFT.Collection>(), publicLinkedType: Type<&beta4LilaiNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-beta4LilaiNFT.createEmptyCollection(nftType: Type<@beta4LilaiNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A collection of unique NFTs for the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/lilaipuita")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime", "foo"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
					let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
					traitsView.addTrait(fooTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface beta4LilaiNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowbeta4LilaiNFT(id: UInt64): &beta4LilaiNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow beta4LilaiNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: beta4LilaiNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @beta4LilaiNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowbeta4LilaiNFT(id: UInt64): &beta4LilaiNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &beta4LilaiNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let beta4LilaiNFT = nft as! &beta4LilaiNFT.NFT
			return beta4LilaiNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Public function to mint a new NFT
	access(all)
	fun mintNFT(recipientAddress: Address, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], lilaiputiaData: String){ 
		let recipientAccount = getAccount(recipientAddress)
		let recipientCollection = recipientAccount.capabilities.get<&Collection>(self.CollectionPublicPath).borrow<&Collection>() ?? panic("Could not borrow a reference to the recipient's collection")
		let metadata:{ String: AnyStruct} ={ "name": name, "description": description, "thumbnail": thumbnail, "ipfsLink": thumbnail, // Include IPFS link																																	  
																																	  "mintedBlock": getCurrentBlock().height, "mintedTime": getCurrentBlock().timestamp, "minter": recipientAddress																																																													// Add other fields as needed
																																																													}
		var newNFT <- create NFT(id: beta4LilaiNFT.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata, lilaiputia: lilaiputiaData)
		recipientCollection.deposit(token: <-newNFT)
		beta4LilaiNFT.totalSupply = beta4LilaiNFT.totalSupply + UInt64(1)
		emit beta4LilaiNFT.NFTMinted(id: beta4LilaiNFT.totalSupply)
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: beta4LilaiNFT.CollectionStoragePath, publicPath: beta4LilaiNFT.CollectionPublicPath, publicCollection: Type<&beta4LilaiNFT.Collection>(), publicLinkedType: Type<&beta4LilaiNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-beta4LilaiNFT.createEmptyCollection(nftType: Type<@beta4LilaiNFT.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A diverse collection of NFTs within the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("hhttps://twitter.com/lilaiputia")})
		}
		return nil
	}
	
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	init(){ 
		self.totalSupply = 0
		// Set the paths
		self.CollectionStoragePath = /storage/beta4LilaiNFTCollection
		self.CollectionPublicPath = /public/beta4LilaiNFTCollection
		// Create and store the collection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		// Link the collection to the public path
		var capability_1 = self.account.capabilities.storage.issue<&beta4LilaiNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
