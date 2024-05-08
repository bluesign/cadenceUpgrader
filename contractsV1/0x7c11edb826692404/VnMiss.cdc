import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import VnMissCandidate from "./VnMissCandidate.cdc"

access(all)
contract VnMiss: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Minted(to: Address, level: UInt8, tokenId: UInt64, candidateID: UInt64, name: String, description: String, thumbnail: String)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var BaseURL: String?
	
	access(all)
	enum Level: UInt8{ 
		access(all)
		case Bronze
		
		access(all)
		case Silver
		
		access(all)
		case Diamond
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let candidateID: UInt64
		
		access(all)
		let level: UInt8
		
		access(all)
		let name: String
		
		access(all)
		let thumbnail: String
		
		init(id: UInt64, candidateID: UInt64, level: Level, name: String, thumbnail: String){ 
			self.id = id
			self.candidateID = candidateID
			self.level = level.rawValue
			self.name = name
			self.thumbnail = thumbnail
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let c = VnMissCandidate.getCandidate(id: self.candidateID)!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: c.name, description: c.description, thumbnail: MetadataViews.HTTPFile(url: (VnMiss.BaseURL ?? "").concat(self.thumbnail)))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface VnMissCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowVnMiss(id: UInt64): &VnMiss.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow VnMiss reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: VnMissCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let nft <- token as! @VnMiss.NFT
			emit Withdraw(id: nft.id, from: self.owner?.address)
			return <-nft
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @VnMiss.NFT
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
		fun borrowVnMiss(id: UInt64): &VnMiss.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &VnMiss.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &VnMiss.NFT
			return exampleNFT as &{ViewResolver.Resolver}
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, candidateID: UInt64, level: Level, name: String, thumbnail: String){ 
			
			// create a new NFT
			var newNFT <- create NFT(id: VnMiss.totalSupply + 1, candidateID: candidateID, level: level, name: name, thumbnail: thumbnail)
			let id = newNFT.id
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			VnMiss.totalSupply = VnMiss.totalSupply + UInt64(1)
			let c = VnMissCandidate.getCandidate(id: candidateID)!
			emit Minted(to: (recipient.owner!).address, level: level.rawValue, tokenId: id, candidateID: candidateID, name: name, description: c.description, thumbnail: (VnMiss.BaseURL ?? "").concat(thumbnail))
		}
		
		access(all)
		fun setBaseUrl(url: String){ 
			VnMiss.BaseURL = url
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.BaseURL = "https://hhhv-statics.avatarart.io/nfts/"
		
		// Set the named paths
		self.CollectionStoragePath = /storage/BNVnMissNFTCollection006
		self.CollectionPublicPath = /public/BNVnMissNFTCollection006
		self.MinterStoragePath = /storage/BNVnMissNFTMinter006
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&VnMiss.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
