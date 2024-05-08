import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract InterflowCustom: NonFungibleToken{ 
	
	/// Total supply of InterflowCustoms in existence
	access(all)
	var totalSupply: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	access(all)
	event NftRevealed(id: UInt64)
	
	/// The event that is emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an NFT is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// The core resource that represents a Non Fungible Token. 
	/// New instances will be created using the NFTMinter resource
	/// and stored in the Collection resource
	///
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
		var thumbnail: String
		
		access(all)
		let originalNftUuid: UInt64
		
		access(all)
		let originalNftImageLink: String
		
		access(all)
		let originalNftCollectionName: String
		
		access(all)
		let originalNftType: Type?
		
		access(all)
		let originalNftContractAddress: Address?
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, name: String, description: String, thumbnail: String, originalNftUuid: UInt64, originalNftImageLink: String, originalNftCollectionName: String, originalNftType: Type?, originalNftContractAddress: Address?, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.originalNftUuid = originalNftUuid
			self.originalNftImageLink = originalNftImageLink
			self.originalNftCollectionName = originalNftCollectionName
			self.originalNftType = originalNftType
			self.originalNftContractAddress = originalNftContractAddress
			self.royalties = royalties
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
		}
		
		access(contract)
		fun revealThumbnail(){ 
			self.thumbnail = "https://interflow-app.s3.amazonaws.com/".concat(self.id.toString()).concat(".png")
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
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://interflow.../".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: InterflowCustom.CollectionStoragePath, publicPath: InterflowCustom.CollectionPublicPath, publicCollection: Type<&InterflowCustom.Collection>(), publicLinkedType: Type<&InterflowCustom.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-InterflowCustom.createEmptyCollection(nftType: Type<@InterflowCustom.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://interflow-app.s3.amazonaws.com/bgImage.png"), mediaType: "image/png")
					let squareImg = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://interflow-app.s3.amazonaws.com/logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Interflow Custom", description: "First AI generated NFT Collection based in original NFTs images.", externalURL: MetadataViews.ExternalURL("https://interflow.../"), squareImage: squareImg, bannerImage: media, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/QzBqwSSc")})
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					return MetadataViews.Traits(traits)
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
	resource interface InterflowCustomCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowInterflowCustom(id: UInt64): &InterflowCustom.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow InterflowCustom reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: InterflowCustomCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Removes an NFT from the collection and moves it to the caller
		///
		/// @param withdrawID: The ID of the NFT that wants to be withdrawn
		/// @return The NFT resource that has been taken out of the collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Adds an NFT to the collections dictionary and adds the ID to the id array
		///
		/// @param token: The NFT resource to be included in the collection
		/// 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @InterflowCustom.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Helper method for getting the collection IDs
		///
		/// @return An array containing the IDs of the NFTs in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an NFT in the collection so that 
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Gets a reference to an NFT in the collection so that 
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///		
		access(all)
		fun borrowInterflowCustom(id: UInt64): &InterflowCustom.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &InterflowCustom.NFT
			}
			return nil
		}
		
		/// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
		/// interface so that the caller can retrieve the views that the NFT
		/// is implementing and resolve them
		///
		/// @param id: The ID of the wanted NFT
		/// @return The resource reference conforming to the Resolver interface
		/// 
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let InterflowCustom = nft as! &InterflowCustom.NFT
			return InterflowCustom as &{ViewResolver.Resolver}
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
	
	/// Allows anyone to create a new empty collection
	///
	/// @return The new Collection resource
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Resource that an admin or something similar would own to be
	/// able to mint new NFTs
	///
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, id: UInt64, name: String, description: String, originalNftUuid: UInt64, originalNftImageLink: String, originalNftCollectionName: String, originalNftType: Type?, originalNftContractAddress: Address?, royalties: [MetadataViews.Royalty]){ 
			let placeholderImage = "https://interflow-app.s3.amazonaws.com/placeholder.png"
			// create a new NFT
			var newNFT <- create NFT(id: id, name: name, description: description, thumbnail: placeholderImage, originalNftUuid: originalNftUuid, originalNftImageLink: originalNftImageLink, originalNftCollectionName: originalNftCollectionName, originalNftType: originalNftType, originalNftContractAddress: originalNftContractAddress, royalties: royalties)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			InterflowCustom.totalSupply = InterflowCustom.totalSupply + UInt64(1)
		}
		
		access(all)
		fun revealNft(nft: &NFT){ 
			nft.revealThumbnail()
			emit NftRevealed(id: nft.id)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/interflowCustomCollection
		self.CollectionPublicPath = /public/interflowCustomCollection
		self.MinterStoragePath = /storage/interflowCustomMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&InterflowCustom.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
