import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleTokenMinter from "../0x3b16cb9f5c036412/NonFungibleTokenMinter.cdc"

access(all)
contract MCityLand: NonFungibleToken, NonFungibleTokenMinter{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let mintedNfts:{ UInt64: Bool}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Minted(to: Address, id: UInt64, metadata:{ String: String})
	
	access(all)
	event Mint(id: UInt64, metadata:{ String: String})
	
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
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["metaURI"] ?? ""))
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTMCityLand(id: UInt64): &MCityLand.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MCityLand reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @MCityLand.NFT
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
		fun borrowNFTMCityLand(id: UInt64): &MCityLand.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MCityLand.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &MCityLand.NFT
			return (exampleNFT as &{ViewResolver.Resolver}?)!
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
	resource NFTMinter: NonFungibleTokenMinter.MinterProvider{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			pre{ 
				MCityLand.mintedNfts[id] == nil || MCityLand.mintedNfts[id] == false:
					"This id has been minted before"
			}
			// create a new NFT
			var newNFT <- create NFT(id: id, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MCityLand.mintedNfts[id] = true
			MCityLand.totalSupply = MCityLand.totalSupply + 1
			emit Minted(to: (recipient.owner!).address, id: id, metadata: metadata)
		}
		
		access(all)
		fun mint(id: UInt64, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
			pre{ 
				MCityLand.mintedNfts[id] == nil || MCityLand.mintedNfts[id] == false:
					"This id has been minted before"
			}
			MCityLand.totalSupply = MCityLand.totalSupply + 1
			let token <- create NFT(id: id, metadata: metadata)
			MCityLand.mintedNfts[id] = true
			emit Mint(id: token.id, metadata: metadata)
			return <-token
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.mintedNfts ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MCityLandStoragePath
		self.CollectionPublicPath = /public/MCityLandPublicPath
		self.MinterStoragePath = /storage/MCityLandMinterStoragePath
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&MCityLand.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
