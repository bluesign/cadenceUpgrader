import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract LCubeNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	//Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, ipfsHash: String, name: String, description: String, nftType: String, nftTypeDescription: String, contentType: String, power: UFix64, rarity: UFix64)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let ipfsHash: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let nftType: String
		
		access(all)
		let nftTypeDescription: String
		
		access(all)
		let contentType: String
		
		access(all)
		let power: UFix64
		
		access(all)
		let rarity: UFix64
		
		init(creator: Address, ipfsHash: String, name: String, description: String, nftType: String, nftTypeDescription: String, contentType: String, power: UFix64, rarity: UFix64){ 
			self.id = LCubeNFT.totalSupply
			self.creator = creator
			self.ipfsHash = ipfsHash
			self.name = name
			self.description = description
			self.nftType = nftType
			self.nftTypeDescription = nftTypeDescription
			self.contentType = contentType
			self.power = power
			self.rarity = rarity
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.id, description: self.ipfsHash, thumbnail: self.name, description: self.description, nftType: self.nftType, nftTypeDescription: self.nftTypeDescription, contentType: self.contentType, power: self.power, rarity: self.rarity)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their LCube Collection as
	// to allow others to deposit LCube into their Collection. It also allows for reading
	// the details of LCube in the Collection.
	access(all)
	resource interface LCubeCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LCube reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LCubeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
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
			let token <- token as! @LCubeNFT.NFT
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			destroy oldToken
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowLCubeNFT(id: UInt64): &LCubeNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &LCubeNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let refItem = nft as! &LCubeNFT.NFT
			return refItem as &{ViewResolver.Resolver}
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
	resource NFTMinter{ 
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(creator: Capability<&{NonFungibleToken.Receiver}>, recipient: &{NonFungibleToken.CollectionPublic}, ipfsHash: String, name: String, description: String, nftType: String, nftTypeDescription: String, contentType: String, power: UFix64, rarity: UFix64): &{NonFungibleToken.NFT}{ 
			// create a new NFT
			var token <- create NFT(creator: creator.address, ipfsHash: ipfsHash, name: name, description: description, nftType: nftType, nftTypeDescription: nftTypeDescription, contentType: contentType, power: power, rarity: rarity)
			LCubeNFT.totalSupply = LCubeNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, creator: creator.address, ipfsHash: ipfsHash, name: name, description: description, nftType: nftType, nftTypeDescription: nftTypeDescription, contentType: contentType, power: power, rarity: rarity)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	fun minter(): Capability<&NFTMinter>{ 
		return self.account.capabilities.get<&NFTMinter>(self.MinterPublicPath)!
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		// Set the named paths
		self.CollectionStoragePath = /storage/LCubeNFTCollection
		self.CollectionPublicPath = /public/LCubeNFTCollection
		self.MinterPublicPath = /public/LCubeNFTMinter
		self.MinterStoragePath = /storage/LCubeNFTMinter
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&LCubeNFT.Collection>(LCubeNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LCubeNFT.CollectionPublicPath)
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
