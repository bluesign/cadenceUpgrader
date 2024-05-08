import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// NftReality Contract
access(all)
contract NftReality: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, itemUuid: String, unit: UInt64, totalUnits: UInt64, metadata: Metadata, additionalInfo:{ String: String})
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Number of nfts minted
	access(all)
	var totalSupply: UInt64
	
	// NFT metadata
	access(all)
	struct Metadata{ 
		access(all)
		let artwork: String
		
		access(all)
		let logotype: String
		
		access(all)
		let description: String
		
		access(all)
		let creator: String
		
		access(all)
		let company: String
		
		access(all)
		let role: String
		
		access(all)
		let creationDate: String
		
		init(artwork: String, logotype: String, description: String, creator: String, company: String, role: String, creationDate: String){ 
			self.artwork = artwork
			self.logotype = logotype
			self.description = description
			self.creator = creator
			self.company = company
			self.role = role
			self.creationDate = creationDate
		}
	}
	
	access(all)
	struct NftRealityMetadataView{ 
		access(all)
		let itemUuid: String
		
		access(all)
		let unit: UInt64
		
		access(all)
		let totalUnits: UInt64
		
		access(all)
		let artwork: String
		
		access(all)
		let logotype: String
		
		access(all)
		let description: String
		
		access(all)
		let creator: String
		
		access(all)
		let company: String
		
		access(all)
		let role: String
		
		access(all)
		let creationDate: String
		
		init(itemUuid: String, unit: UInt64, totalUnits: UInt64, artwork: String, logotype: String, description: String, creator: String, company: String, role: String, creationDate: String){ 
			self.itemUuid = itemUuid
			self.unit = unit
			self.totalUnits = totalUnits
			self.artwork = artwork
			self.logotype = logotype
			self.description = description
			self.creator = creator
			self.company = company
			self.role = role
			self.creationDate = creationDate
		}
	}
	
	// NftReality nft resource
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemUuid: String
		
		access(all)
		let unit: UInt64
		
		access(all)
		let totalUnits: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(self)
		let additionalInfo:{ String: String}
		
		init(ID: UInt64, itemUuid: String, unit: UInt64, totalUnits: UInt64, metadata: Metadata, additionalInfo:{ String: String}){ 
			self.id = ID
			self.itemUuid = itemUuid
			self.unit = unit
			self.totalUnits = totalUnits
			self.metadata = metadata
			self.additionalInfo = additionalInfo
		}
		
		access(all)
		fun name(): String{ 
			return self.metadata.company.concat(" - ").concat(self.metadata.role)
		}
		
		access(all)
		fun description(): String{ 
			return self.metadata.description
		}
		
		access(all)
		fun imageCID(): String{ 
			return self.metadata.artwork
		}
		
		access(all)
		fun getAdditionalInfo():{ String: String}{ 
			return self.additionalInfo
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<NftRealityMetadataView>(), Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<NftRealityMetadataView>():
					return NftRealityMetadataView(itemUuid: self.itemUuid, unit: self.unit, totalUnits: self.totalUnits, artwork: self.metadata.artwork, logotype: self.metadata.logotype, description: self.metadata.description, creator: self.metadata.creator, company: self.metadata.company, role: self.metadata.role, creationDate: self.metadata.creationDate)
				case Type<MetadataViews.Display>():
					var thumbnail:{ MetadataViews.File} = MetadataViews.HTTPFile(url: "")
					if self.getAdditionalInfo().containsKey("artworkThumbnail"){ 
						thumbnail = MetadataViews.IPFSFile(cid: self.getAdditionalInfo()["artworkThumbnail"]!, path: "artworkThumbnail")
					}
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: thumbnail)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// NftReality nfts collection public interface
	access(all)
	resource interface NftRealityCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNftReality(id: UInt64): &NftReality.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NftReality reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// NftReality nfts collection resource
	access(all)
	resource Collection: NftRealityCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NftReality.NFT
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
		fun borrowNftReality(id: UInt64): &NftReality.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NftReality.NFT
			} else{ 
				return nil
			}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin can use to mint new nfts
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(itemUuid: String, recipient: &{NonFungibleToken.CollectionPublic}, unit: UInt64, totalUnits: UInt64, metadata: Metadata, additionalInfo:{ String: String}){ 
			emit Minted(id: NftReality.totalSupply, itemUuid: itemUuid, unit: unit, totalUnits: totalUnits, metadata: metadata, additionalInfo: additionalInfo)
			recipient.deposit(token: <-create NftReality.NFT(ID: NftReality.totalSupply, itemUuid: itemUuid, unit: unit, totalUnits: totalUnits, metadata: metadata, additionalInfo: additionalInfo))
			NftReality.totalSupply = NftReality.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun batchMintNFT(itemUuid: String, recipient: &{NonFungibleToken.CollectionPublic}, totalUnits: UInt64, startingUnit: UInt64, quantity: UInt64, metadata: Metadata, additionalInfo:{ String: String}){ 
			var i: UInt64 = 0
			var unit: UInt64 = startingUnit - 1
			while i < quantity{ 
				i = i + UInt64(1)
				unit = unit + UInt64(1)
				self.mintNFT(itemUuid: itemUuid, recipient: recipient, unit: unit, totalUnits: totalUnits, metadata: metadata, additionalInfo: additionalInfo)
			}
		}
		
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/nftRealityCollection
		self.CollectionPublicPath = /public/nftRealityCollection
		self.MinterStoragePath = /storage/nftRealityMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
