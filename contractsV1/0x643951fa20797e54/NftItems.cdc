// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract NftItems: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, description: String, thumbnail: String, metadataobjs:{ UInt64:{ String: String}}, properties:{ UInt64:{ String: String}}, cid: String, path: String?)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let description: String
		
		access(self)
		var metadataobjs:{ UInt64:{ String: String}}
		
		access(all)
		fun getMetadata():{ UInt64:{ String: String}}{ 
			return self.metadataobjs
		}
		
		access(self)
		var properties:{ UInt64:{ String: String}}
		
		access(all)
		fun getProperties():{ UInt64:{ String: String}}{ 
			return self.properties
		}
		
		access(all)
		let cid: String
		
		access(all)
		let path: String?
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.IPFSFile>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.cid, path: self.path)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: NftItems.CollectionStoragePath, publicPath: NftItems.CollectionPublicPath, publicCollection: Type<&NftItems.Collection>(), publicLinkedType: Type<&NftItems.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-NftItems.createEmptyCollection(nftType: Type<@NftItems.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, initMetadataObjs:{ UInt64:{ String: String}}, initProperties:{ UInt64:{ String: String}}, cid: String, path: String?){ 
			self.id = id
			self.name = name
			self.thumbnail = thumbnail
			self.description = description
			self.metadataobjs = initMetadataObjs
			self.properties = initProperties
			self.cid = cid
			self.path = path
		}
	}
	
	access(all)
	resource interface NftItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNftItems(id: UInt64): &NftItems.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NftItems reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NftItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @NftItems.NFT
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
		fun borrowNftItems(id: UInt64): &NftItems.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NftItems.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let NftItems = nft as! &NftItems.NFT
			return NftItems as &{ViewResolver.Resolver}
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, metadataobjs:{ UInt64:{ String: String}}, properties:{ UInt64:{ String: String}}, cid: String, path: String?){ 
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create NftItems.NFT(id: NftItems.totalSupply, name: name, description: description, thumbnail: thumbnail, initMetadataObjs: metadataobjs, initProperties: properties, cid: cid, path: path))
			emit Minted(id: NftItems.totalSupply, name: name, description: description, thumbnail: thumbnail, metadataobjs: metadataobjs, properties: properties, cid: cid, path: path)
			NftItems.totalSupply = NftItems.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/nftItemsCollectionV9
		self.CollectionPublicPath = /public/nftItemsCollectionV9
		self.MinterStoragePath = /storage/nftItemsMinterV9
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&NftItems.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
