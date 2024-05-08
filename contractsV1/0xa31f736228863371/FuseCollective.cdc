import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FuseCollective: NonFungibleToken{ 
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
	// FuseCollective Events
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
	
	access(all)
	var maxSupply: UInt64
	
	// -----------------------------------------------------------------------
	// FuseCollective Fields
	// -----------------------------------------------------------------------
	access(all)
	var name: String
	
	access(self)
	var collectionMetadata:{ String: String}
	
	access(self)
	let idToEditionMetadata:{ UInt64: EditionMetadata}
	
	access(all)
	struct EditionMetadata{ 
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			if FuseCollective.idToEditionMetadata[self.id] != nil{ 
				return (FuseCollective.idToEditionMetadata[self.id]!).metadata
			} else{ 
				return{} 
			}
		}
		
		init(id: UInt64){ 
			self.id = id
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface FuseCollectiveCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFuseCollective(id: UInt64): &FuseCollective.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FuseCollective reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, FuseCollectiveCollectionPublic{ 
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
			let token <- token as! @FuseCollective.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowFuseCollective(id: UInt64): &FuseCollective.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &FuseCollective.NFT
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
	}
	
	// -----------------------------------------------------------------------
	// Admin Functions
	// -----------------------------------------------------------------------
	access(account)
	fun setEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
		self.idToEditionMetadata[editionNumber] = EditionMetadata(metadata: metadata)
	}
	
	access(account)
	fun setCollectionMetadata(metadata:{ String: String}){ 
		self.collectionMetadata = metadata
	}
	
	access(account)
	fun mint(nftID: UInt64): @{NonFungibleToken.NFT}{ 
		post{ 
			self.totalSupply <= self.maxSupply:
				"Total supply going over max supply with invalid mint."
		}
		self.totalSupply = self.totalSupply + 1
		return <-create NFT(id: nftID)
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
		if self.idToEditionMetadata[edition] != nil{ 
			return (self.idToEditionMetadata[edition]!).metadata
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
		self.name = "Fuse Collective"
		self.totalSupply = 0
		self.maxSupply = 1000
		self.collectionMetadata ={} 
		self.idToEditionMetadata ={} 
		self.CollectionStoragePath = /storage/FuseCollectiveCollection
		self.CollectionPublicPath = /public/FuseCollectiveCollection
		emit ContractInitialized()
	}
}
