import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowtyRaffles from "../0x2fb4614ede95ab2b/FlowtyRaffles.cdc"

import FlowtyRaffleSource from "../0x2fb4614ede95ab2b/FlowtyRaffleSource.cdc"

access(all)
contract FlowtyWrapped: NonFungibleToken, ViewResolver{ 
	// Total supply of FlowtyWrapped NFTs
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionExternalUrl: String
	
	access(all)
	var nftExternalBaseUrl: String
	
	access(account)
	let editions:{ String:{ WrappedEdition}}
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	access(all)
	event CollectionCreated(uuid: UInt64)
	
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
	let CollectionProviderPath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	struct interface WrappedEdition{ 
		access(all)
		view fun getName(): String
		
		access(all)
		fun resolveView(_ t: Type, _ nft: &NFT): AnyStruct?
		
		access(all)
		fun getEditionSupply(): UInt64
		
		access(account)
		fun setStatus(_ s: String)
		
		access(account)
		fun mint(address: Address, data:{ String: AnyStruct}): @NFT
	}
	
	/// The core resource that represents a Non Fungible Token. 
	/// New instances will be created using the NFTMinter resource
	/// and stored in the Collection resource
	///
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let editionName: String
		
		access(all)
		let address: Address
		
		access(all)
		let data:{ String: AnyStruct}
		
		init(id: UInt64, serial: UInt64, editionName: String, address: Address, data:{ String: AnyStruct}){ 
			self.id = id
			self.serial = serial
			self.editionName = editionName
			self.address = address
			self.data = data
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
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
					let edition = FlowtyWrapped.getEditionRef(self.editionName)
					return edition.resolveView(view, &self as &NFT)
				case Type<MetadataViews.Medias>():
					let edition = FlowtyWrapped.getEditionRef(self.editionName)
					return edition.resolveView(view, &self as &NFT)
				case Type<MetadataViews.Editions>():
					let edition = FlowtyWrapped.getEditionRef(self.editionName)
					return edition.resolveView(view, &self as &NFT)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Royalties>():
					return nil
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(FlowtyWrapped.nftExternalBaseUrl.concat("/").concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return FlowtyWrapped.resolveView(view)
				case Type<MetadataViews.NFTCollectionDisplay>():
					return FlowtyWrapped.resolveView(view)
				case Type<MetadataViews.Traits>():
					let edition = FlowtyWrapped.getEditionRef(self.editionName)
					return edition.resolveView(view, &self as &NFT)
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
	resource interface FlowtyWrappedCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlowtyWrapped(id: UInt64): &FlowtyWrapped.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FlowtyWrapped reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: FlowtyWrappedCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			assert(false, message: "Flowty Wrapped is not transferrable.")
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
			let token <- token as! @FlowtyWrapped.NFT
			let nftOwnerAddress = token.address
			assert(nftOwnerAddress == self.owner?.address, message: "The NFT must be owned by the collection owner")
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
		fun borrowFlowtyWrapped(id: UInt64): &FlowtyWrapped.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlowtyWrapped.NFT
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
			return nft as! &FlowtyWrapped.NFT
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
		let c <- create Collection()
		emit CollectionCreated(uuid: c.uuid)
		return <-c
	}
	
	access(all)
	resource interface AdminPublic{} 
	
	/// Resource that an admin or something similar would own to be
	/// able to mint new NFTs
	///
	access(all)
	resource Admin: AdminPublic{ 
		/// Mints a new NFT with a new ID and deposit it in the
		/// recipients collection using their collection reference
		///
		/// @param recipient: A capability to the collection where the new NFT will be deposited
		///
		access(all)
		fun mintNFT(editionName: String, address: Address, data:{ String: AnyStruct}): @FlowtyWrapped.NFT{ 
			// we want IDs to start at 1, so we'll increment first
			FlowtyWrapped.totalSupply = FlowtyWrapped.totalSupply + 1
			let edition = FlowtyWrapped.getEditionRef(editionName)
			let nft <- edition.mint(address: address, data: data)
			return <-nft
		}
		
		access(all)
		fun getEdition(editionName: String): AnyStruct{ 
			let edition = FlowtyWrapped.getEditionRef(editionName)
			return edition
		}
		
		access(all)
		fun registerEdition(_ edition:{ WrappedEdition}){ 
			pre{ 
				FlowtyWrapped.editions[edition.getName()] == nil:
					"edition name already exists"
			}
			FlowtyWrapped.editions[edition.getName()] = edition
		}
		
		access(all)
		fun setCollectionExternalUrl(_ s: String){ 
			FlowtyWrapped.collectionExternalUrl = s
		}
		
		access(all)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
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
				return MetadataViews.NFTCollectionData(storagePath: FlowtyWrapped.CollectionStoragePath, publicPath: FlowtyWrapped.CollectionPublicPath, publicCollection: Type<&FlowtyWrapped.Collection>(), publicLinkedType: Type<&FlowtyWrapped.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlowtyWrapped.createEmptyCollection(nftType: Type<@FlowtyWrapped.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				return MetadataViews.NFTCollectionDisplay(name: "Flowty Wrapped", description: "A celebration and statistical review of an exciting year on Flowty and across the Flow blockchain ecosystem.", externalURL: MetadataViews.ExternalURL(FlowtyWrapped.collectionExternalUrl), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmdCiwwJ7z2gQecDr6hn4pJj91miWYnFC178o9p6JKftmi", path: nil), mediaType: "image/jpg"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmcLJhJh6yuLAoH6wWKMDS2zUv6myduXQc83zD5xv2V8tA", path: nil), mediaType: "image/jpg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")})
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
	
	access(account)
	fun getRaffleManager(): &FlowtyRaffles.Manager{ 
		return self.account.storage.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)!
	}
	
	access(contract)
	fun borrowAdmin(): &Admin{ 
		return self.account.storage.borrow<&Admin>(from: self.AdminStoragePath)!
	}
	
	access(account)
	fun mint(id: UInt64, serial: UInt64, editionName: String, address: Address, data:{ String: AnyStruct}): @NFT{ 
		return <-create NFT(id: id, serial: serial, editionName: editionName, address: address, data: data)
	}
	
	access(contract)
	fun getEditionRef(_ name: String): &{WrappedEdition}{ 
		pre{ 
			self.editions[name] != nil:
				"no edition found with given name"
		}
		return (&self.editions[name] as &{WrappedEdition}?)!
	}
	
	access(all)
	fun getEdition(_ name: String):{ WrappedEdition}{ 
		return self.editions[name] ?? panic("no edition found with given name")
	}
	
	access(all)
	fun getAccountAddress(): Address{ 
		return self.account.address
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		let identifier = "FlowtyWrapped_".concat(self.account.address.toString())
		
		// Set the named paths
		self.CollectionStoragePath = StoragePath(identifier: identifier)!
		self.CollectionPublicPath = PublicPath(identifier: identifier)!
		self.CollectionProviderPath = PrivatePath(identifier: identifier)!
		self.AdminStoragePath = StoragePath(identifier: identifier.concat("_Minter"))!
		self.AdminPublicPath = PublicPath(identifier: identifier.concat("_Minter"))!
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&FlowtyWrapped.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_2, at: self.AdminPublicPath)
		emit ContractInitialized()
		let manager <- FlowtyRaffles.createManager()
		self.account.storage.save(<-manager, to: FlowtyRaffles.ManagerStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&FlowtyRaffles.Manager>(FlowtyRaffles.ManagerStoragePath)
		self.account.capabilities.publish(capability_3, at: FlowtyRaffles.ManagerPublicPath)
		self.collectionExternalUrl = "https://flowty.io/collection/".concat(self.account.address.toString()).concat("/FlowtyWrapped")
		self.nftExternalBaseUrl = "https://flowty.io/asset/".concat(self.account.address.toString()).concat("/FlowtyWrapped")
		self.editions ={} 
	}
}
