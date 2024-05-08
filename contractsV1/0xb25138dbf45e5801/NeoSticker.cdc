import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NeoViews from "./NeoViews.cdc"

access(all)
contract NeoSticker: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event StickerTypeAdded(typeId: UInt64)
	
	access(all)
	event Minted(id: UInt64, typeId: UInt64, setId: UInt64, edition: UInt64, maxEdition: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(contract)
	let stickerTypes:{ UInt64: StickerType}
	
	access(all)
	struct StickerType{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let rarity: UInt64
		
		access(all)
		let location: UInt64
		
		access(all)
		let properties:{ String: String}
		
		init(name: String, description: String, thumbnailHash: String, rarity: UInt64, location: UInt64){ 
			self.name = name
			self.description = description
			self.thumbnailHash = thumbnailHash
			self.rarity = rarity
			self.location = location
			self.properties ={} 
		}
	}
	
	access(account)
	fun createStickerType(typeId: UInt64, metadata: StickerType){ 
		NeoSticker.stickerTypes[typeId] = metadata
		emit StickerTypeAdded(typeId: typeId)
	}
	
	access(all)
	fun getStickerType(_ typeId: UInt64): StickerType?{ 
		return NeoSticker.stickerTypes[typeId]
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let typeId: UInt64
		
		access(all)
		let setId: UInt64
		
		init(id: UInt64, typeId: UInt64, setId: UInt64, edition: UInt64, maxEdition: UInt64){ 
			self.id = id
			self.typeId = typeId
			self.setId = setId
			self.edition = edition
			self.maxEdition = maxEdition
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<NeoViews.StickerView>()]
		}
		
		access(all)
		fun getStickerType(): StickerType{ 
			return NeoSticker.getStickerType(self.typeId)!
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let type = self.getStickerType()
			switch view{ 
				case Type<NeoViews.StickerView>():
					return NeoViews.StickerView(id: self.id, name: type.name, description: type.description, thumbnailHash: type.thumbnailHash, rarity: type.rarity, location: type.location, edition: self.edition, maxEdition: self.maxEdition, typeId: self.typeId, setId: self.setId)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: type.name, description: type.description, thumbnail: MetadataViews.IPFSFile(cid: type.thumbnailHash, path: nil))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @NeoSticker.NFT
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let neoSticker = nft as! &NeoSticker.NFT
			return neoSticker as &{ViewResolver.Resolver}
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
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	access(account)
	fun mintNeoSticker(typeId: UInt64, setId: UInt64, edition: UInt64, maxEdition: UInt64): @NeoSticker.NFT{ 
		NeoSticker.totalSupply = NeoSticker.totalSupply + 1
		var newNFT <- create NFT(id: NeoSticker.totalSupply, typeId: typeId, setId: setId, edition: edition, maxEdition: maxEdition)
		emit Minted(id: newNFT.id, typeId: typeId, setId: setId, edition: edition, maxEdition: maxEdition)
		return <-newNFT
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/neoStickerCollection
		self.CollectionPublicPath = /public/neoStickerCollection
		self.stickerTypes ={} 
		emit ContractInitialized()
	}
}
