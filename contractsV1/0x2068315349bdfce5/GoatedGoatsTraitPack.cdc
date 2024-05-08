/*
	A NFT contract for the Goated Goats trait packs.
	
	Key Callouts: 
	* Unlimited supply of packs
	* Contains an id which represents which drop this pack was from == packID
	* Main id for a pack is auto-increment
	* Redeemable by public function that accepts in a TraitPacksVoucher
	  * Takes in pack, burns it, and emits a new event.
	* Have an on/off switch for redeeming packs in case back-end is facing problems and needs to be temporarily turned off
	* Collection-level metadata
	* Edition-level metadata
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GoatedGoatsTraitPack: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// GoatedGoatsTraitPack Events
	// -----------------------------------------------------------------------
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// GoatedGoatsTraitPack Fields
	// -----------------------------------------------------------------------
	access(all)
	var name: String
	
	access(self)
	var collectionMetadata:{ String: String}
	
	access(self)
	let idToTraitPackMetadata:{ UInt64: TraitPackMetadata}
	
	access(all)
	struct TraitPackMetadata{ 
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		let packEditionID: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: "No thumbnail cid set", path: "No thumbnail pat set")
					if self.getMetadata().containsKey("thumbnailCID"){ 
						ipfsImage = MetadataViews.IPFSFile(cid: self.getMetadata()["thumbnailCID"]!, path: self.getMetadata()["thumbnailPath"])
					}
					return MetadataViews.Display(name: self.getMetadata()["name"] ?? "Goated Goat Trait Pack ".concat(self.id.toString()), description: self.getMetadata()["description"] ?? "No description set", thumbnail: ipfsImage)
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			if GoatedGoatsTraitPack.idToTraitPackMetadata[self.id] != nil{ 
				return (GoatedGoatsTraitPack.idToTraitPackMetadata[self.id]!).metadata
			} else{ 
				return{} 
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packID: UInt64, packEditionID: UInt64){ 
			self.id = id
			self.packID = packID
			self.packEditionID = packEditionID
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface TraitPackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTraitPack(id: UInt64): &GoatedGoatsTraitPack.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GoatedGoatsTraitPack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: TraitPackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GoatedGoatsTraitPack.NFT
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
		fun borrowTraitPack(id: UInt64): &GoatedGoatsTraitPack.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &GoatedGoatsTraitPack.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let traitPack = nft as! &GoatedGoatsTraitPack.NFT
			return traitPack as &{ViewResolver.Resolver}
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
	
	// -----------------------------------------------------------------------
	// Admin Functions
	// -----------------------------------------------------------------------
	access(account)
	fun setEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
		self.idToTraitPackMetadata[editionNumber] = TraitPackMetadata(metadata: metadata)
	}
	
	access(account)
	fun setCollectionMetadata(metadata:{ String: String}){ 
		self.collectionMetadata = metadata
	}
	
	access(account)
	fun mint(nftID: UInt64, packID: UInt64, packEditionID: UInt64): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.totalSupply + 1
		return <-create NFT(id: nftID, packID: packID, packEditionID: packEditionID)
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	fun getTotalSupply(): UInt64{ 
		return self.totalSupply
	}
	
	access(all)
	fun getName(): String{ 
		return self.name
	}
	
	access(all)
	fun getCollectionMetadata():{ String: String}{ 
		return self.collectionMetadata
	}
	
	access(all)
	fun getEditionMetadata(_ edition: UInt64):{ String: String}{ 
		if self.idToTraitPackMetadata[edition] != nil{ 
			return (self.idToTraitPackMetadata[edition]!).metadata
		} else{ 
			return{} 
		}
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.name = "Goated Goats Trait Pack"
		self.totalSupply = 0
		self.collectionMetadata ={} 
		self.idToTraitPackMetadata ={} 
		self.CollectionStoragePath = /storage/GoatTraitPackCollection
		self.CollectionPublicPath = /public/GoatTraitPackCollection
		emit ContractInitialized()
	}
}
