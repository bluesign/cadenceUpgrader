/*
*
*  This is forked from the exampleNFT contract:
*  https://github.com/onflow/flow-nft/blob/master/contracts/ExampleNFT.cdc
*
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract CC0Roulette: NonFungibleToken, ViewResolver{ 
	
	/// Total supply of CC0Roulette NFTs in existence
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
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let royaltyAccount: Address
	
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
		let thumbnail: String
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
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
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(CC0Roulette.royaltyAccount).capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)!, cut: 0.03, description: "3% cut to contract account")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://chat.openai.com/g/g-ldzjWGPdV-cc0-roulette")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: CC0Roulette.CollectionStoragePath, publicPath: CC0Roulette.CollectionPublicPath, publicCollection: Type<&CC0Roulette.Collection>(), publicLinkedType: Type<&CC0Roulette.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-CC0Roulette.createEmptyCollection(nftType: Type<@CC0Roulette.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.dropbox.com/scl/fi/0exd1zmpx4b419q26j88i/roulette.png?rlkey=x4csng9lqr7ao5o5s9zxx0dvu&dl=0"), mediaType: "image/png")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.dropbox.com/scl/fi/i78x9jno2gycmz8lecfpa/green-banner.png?rlkey=zc2o2qlzu8o63s7elf03z1dkb&dl=0"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "CC0 Roulette", description: "A combination of many green backgrounded CC0 projects in a single collection. First free NFT mint to be done exclusively through ChatGPT.", externalURL: MetadataViews.ExternalURL("https://chat.openai.com/g/g-ldzjWGPdV-cc0-roulette"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/legitamit")})
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: nil)
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
	resource interface CC0RouletteCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCC0RouletteNFT(id: UInt64): &CC0Roulette.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CC0Roulette reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: CC0RouletteCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @CC0Roulette.NFT
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
		fun borrowCC0RouletteNFT(id: UInt64): &CC0Roulette.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CC0Roulette.NFT
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
			let cc0Roulette = nft as! &CC0Roulette.NFT
			return cc0Roulette as &{ViewResolver.Resolver}
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
		
		// Prevent an already minted user from minting again
		access(all)
		let mintedUsers:{ String: Bool}
		
		access(all)
		fun hasUserMinted(_ userID: String): Bool{ 
			return self.mintedUsers.containsKey(userID)
		}
		
		access(all)
		fun markUserMinted(_ userID: String){ 
			self.mintedUsers[userID] = true
		}
		
		/// Mints a new NFT with a new ID and deposit it in the
		/// recipients collection using their collection reference
		///
		/// @param recipient: A capability to the collection where the new NFT will be deposited
		/// @param name: The name for the NFT metadata
		/// @param description: The description for the NFT metadata
		/// @param thumbnail: The thumbnail for the NFT metadata
		///
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			assert(CC0Roulette.totalSupply <= 5000, message: "Max amount of NFTs allowed is 5,000")
			let currentBlock = getCurrentBlock()
			
			// create a new NFT
			var newNFT <- create NFT(id: CC0Roulette.totalSupply, name: name, description: description, thumbnail: thumbnail, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			CC0Roulette.totalSupply = CC0Roulette.totalSupply + UInt64(1)
		}
		
		init(){ 
			self.mintedUsers ={} 
		}
	}
	
	/// Function that resolves a metadata view for this contract.
	///
	/// @param view: The Type of the desired view.
	/// @return A structure representing the requested view.
	///
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: CC0Roulette.CollectionStoragePath, publicPath: CC0Roulette.CollectionPublicPath, publicCollection: Type<&CC0Roulette.Collection>(), publicLinkedType: Type<&CC0Roulette.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-CC0Roulette.createEmptyCollection(nftType: Type<@CC0Roulette.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "The Example Collection", description: "This collection is used as an example to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://chat.openai.com/g/g-ldzjWGPdV-cc0-roulette"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")})
		}
		return nil
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/CC0RouletteNFTCollection
		self.CollectionPublicPath = /public/CC0RouletteNFTCollection
		self.MinterStoragePath = /storage/CC0RouletteNFTMinter
		self.royaltyAccount = self.account.address
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
