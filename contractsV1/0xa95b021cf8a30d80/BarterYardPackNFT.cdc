import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract BarterYardPackNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Mint(id: UInt64, packPartId: Int, edition: UInt16)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(contract)
	let packParts:{ Int: PackPart}
	
	access(all)
	struct interface SupplyManager{ 
		access(all)
		let maxSupply: UInt16
		
		access(all)
		var totalSupply: UInt16
		
		access(all)
		fun increment(): UInt16{ 
			pre{ 
				self.totalSupply < self.maxSupply:
					"[SupplyManager](increment): can't increment totalSupply as maxSupply has been reached"
			}
		}
	}
	
	/// PackPart represents a part of our future werewolf pack.
	/// eg: Alpha, Beta, Omega...
	access(all)
	struct PackPart: SupplyManager{ 
		access(all)
		let id: Int
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let ipfsThumbnailCid: String
		
		access(all)
		let ipfsThumbnailPath: String?
		
		access(all)
		let maxSupply: UInt16
		
		access(all)
		var totalSupply: UInt16
		
		access(all)
		fun increment(): UInt16{ 
			self.totalSupply = self.totalSupply + 1
			return self.totalSupply
		}
		
		access(all)
		init(id: Int, name: String, description: String, ipfsThumbnailCid: String, ipfsThumbnailPath: String?, maxSupply: UInt16, totalSupply: UInt16){ 
			self.id = id
			self.name = name
			self.description = description
			self.ipfsThumbnailCid = ipfsThumbnailCid
			self.ipfsThumbnailPath = ipfsThumbnailPath
			self.maxSupply = maxSupply
			self.totalSupply = totalSupply
		}
	}
	
	access(all)
	struct PackMetadataDisplay{ 
		access(all)
		let packPartId: Int
		
		access(all)
		let edition: UInt16
		
		init(packPartId: Int, edition: UInt16){ 
			self.packPartId = packPartId
			self.edition = edition
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packPartId: Int
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let ipfsThumbnailCid: String
		
		access(all)
		let ipfsThumbnailPath: String?
		
		access(all)
		let edition: UInt16
		
		init(id: UInt64, packPartId: Int, name: String, description: String, ipfsThumbnailCid: String, ipfsThumbnailPath: String?, edition: UInt16){ 
			self.id = id
			self.packPartId = packPartId
			self.name = name
			self.description = description
			self.ipfsThumbnailCid = ipfsThumbnailCid
			self.ipfsThumbnailPath = ipfsThumbnailPath
			self.edition = edition
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<PackMetadataDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.ipfsThumbnailCid, path: self.ipfsThumbnailPath))
				case Type<PackMetadataDisplay>():
					return PackMetadataDisplay(packPartId: self.packPartId, edition: self.edition)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface BarterYardPackNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBarterYardPackNFT(id: UInt64): &BarterYardPackNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BarterYardPackNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: BarterYardPackNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BarterYardPackNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowBarterYardPackNFT(id: UInt64): &BarterYardPackNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &BarterYardPackNFT.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let BarterYardPackNFT = nft as! &BarterYardPackNFT.NFT
			return BarterYardPackNFT as! &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// mintNFT mints a new NFT with a new Id
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(packPartId: Int): @BarterYardPackNFT.NFT{ 
			let packPart = BarterYardPackNFT.packParts[packPartId] ?? panic("[Admin](mintNFT): can't mint nft because invalid packPartId was providen")
			let edition = packPart.increment()
			BarterYardPackNFT.packParts[packPartId] = packPart
			
			// create a new NFT
			var newNFT <- create NFT(id: BarterYardPackNFT.totalSupply, packPartId: packPartId, name: packPart.name, description: packPart.description, ipfsThumbnailCid: packPart.ipfsThumbnailCid, ipfsThumbnailPath: packPart.ipfsThumbnailPath, edition: edition)
			emit Mint(id: newNFT.id, packPartId: packPartId, edition: edition)
			BarterYardPackNFT.totalSupply = BarterYardPackNFT.totalSupply + 1
			return <-newNFT
		}
		
		// Create a new pack part
		access(all)
		fun createNewPack(name: String, description: String, ipfsThumbnailCid: String, ipfsThumbnailPath: String?, maxSupply: UInt16){ 
			let newPackId = BarterYardPackNFT.packParts.length
			let packPart = PackPart(id: newPackId, name: name, description: description, ipfsThumbnailCid: ipfsThumbnailCid, ipfsThumbnailPath: ipfsThumbnailPath, maxSupply: maxSupply, totalSupply: 0)
			BarterYardPackNFT.packParts.insert(key: newPackId, packPart)
		}
	}
	
	access(all)
	fun getPackPartsIds(): [Int]{ 
		return self.packParts.keys
	}
	
	access(all)
	fun getPackPartById(packPartId: Int): BarterYardPackNFT.PackPart?{ 
		return self.packParts[packPartId]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.packParts ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/BarterYardPackNFTCollection
		self.CollectionPublicPath = /public/BarterYardPackNFTCollection
		self.CollectionPrivatePath = /private/BarterYardPackNFTCollection
		self.AdminStoragePath = /storage/BarterYardPackNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&BarterYardPackNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&BarterYardPackNFT.Collection>(BarterYardPackNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: BarterYardPackNFT.CollectionPrivatePath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
