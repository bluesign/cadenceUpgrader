import ChainzNFT from "./ChainzNFT.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract ChainzPack: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextPackTypeId: UInt64
	
	access(self)
	let packTypes:{ UInt64: PackType}
	
	access(all)
	struct PackType{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let price: UFix64
		
		access(all)
		var amountMinted: UInt64
		
		access(all)
		let reserved: UInt64
		
		access(all)
		var takenFromReserved: UInt64
		
		access(all)
		let maxSupply: UInt64
		
		access(all)
		var isSaleActive: Bool
		
		access(all)
		let extra:{ String: String}
		
		access(all)
		fun minted(){ 
			self.amountMinted = self.amountMinted + 1
		}
		
		access(all)
		fun usedReserve(){ 
			self.takenFromReserved = self.takenFromReserved + 1
		}
		
		access(all)
		fun toggleActive(){ 
			self.isSaleActive = !self.isSaleActive
		}
		
		init(_name: String, _price: UFix64, _maxSupply: UInt64, _reserved: UInt64, _extra:{ String: String}){ 
			self.id = ChainzPack.nextPackTypeId
			self.name = _name
			self.price = _price
			self.amountMinted = 0
			self.maxSupply = _maxSupply
			self.reserved = _reserved
			self.takenFromReserved = 0
			self.isSaleActive = false
			self.extra = _extra
		}
	}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The Pack's id
		access(all)
		let id: UInt64
		
		access(all)
		let sequence: UInt64
		
		access(all)
		let packTypeId: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_packTypeId: UInt64){ 
			self.id = self.uuid
			ChainzPack.totalSupply = ChainzPack.totalSupply + 1
			self.sequence = ChainzPack.totalSupply
			self.packTypeId = _packTypeId
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
		fun borrowPack(id: UInt64): &ChainzPack.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// IPackCollectionAdminAccessible
	// Exposes the openPack which allows an admin to
	// open a pack in this collection.
	//
	access(all)
	resource interface AdminAccessible{ 
		access(account)
		fun openPack(id: UInt64, cardCollectionRef: &ChainzNFT.Collection, names: [String], descriptions: [String], thumbnails: [String], metadatas: [{String: String}])
	}
	
	// Collection
	// a collection of Pack resources so that users can
	// own Packs in a collection and trade them back and forth.
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, AdminAccessible{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ChainzPack.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Pack")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// openPack
		// This method removes a Pack from this Collection and then
		// deposits newly minted Cards into the Collection reference by
		// calling depositBatch on the reference. 
		//
		// The Pack is also destroyed in the process so it will no longer
		// exist
		//
		access(account)
		fun openPack(id: UInt64, cardCollectionRef: &ChainzNFT.Collection, names: [String], descriptions: [String], thumbnails: [String], metadatas: [{String: String}]){ 
			let pack <- self.withdraw(withdrawID: id)
			var i: Int = 0
			// Mints new Cards into this empty Collection
			while i < names.length{ 
				let newCard: @ChainzNFT.NFT <- ChainzNFT.createNFT(name: names[i], description: descriptions[i], thumbnail: thumbnails[i], metadata: metadatas[i])
				cardCollectionRef.deposit(token: <-newCard)
				i = i + 1
			}
			destroy pack
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
		fun borrowPack(id: UInt64): &ChainzPack.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &ChainzPack.NFT?
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(account)
	fun createPackType(name: String, price: UFix64, maxSupply: UInt64, reserved: UInt64, extra:{ String: String}){ 
		self.packTypes[self.nextPackTypeId] = PackType(_name: name, _price: price, _maxSupply: maxSupply, _reserved: reserved, _extra: extra)
		self.nextPackTypeId = self.nextPackTypeId + 1
	}
	
	access(account)
	fun toggleActive(packTypeId: UInt64){ 
		let packType = &self.packTypes[packTypeId] as &PackType? ?? panic("This Pack Type does not exist.")
		packType.toggleActive()
	}
	
	access(all)
	fun getPackType(packTypeId: UInt64): PackType?{ 
		return self.packTypes[packTypeId]
	}
	
	access(all)
	fun mintPack(packCollectionRef: &ChainzPack.Collection, packTypeId: UInt64, payment: @DapperUtilityCoin.Vault){ 
		let packType = &self.packTypes[packTypeId] as &PackType? ?? panic("This Pack Type does not exist.")
		assert(payment.balance == packType.price, message: "The correct payment amount was not passed in.")
		assert(packType.amountMinted < packType.maxSupply - packType.reserved, message: "This Pack Type is sold out.")
		assert(packType.isSaleActive, message: "The drop is not currently active.")
		packCollectionRef.deposit(token: <-create NFT(_packTypeId: packTypeId))
		packType.minted()
		
		// WHERE DOES THE PAYMENT GO?
		let treasury = getAccount(0xd1120ae332f528f0).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("This is not a Dapper Wallet account.")
		treasury.deposit(from: <-payment)
	}
	
	access(account)
	fun reserveMint(packCollectionRef: &ChainzPack.Collection, packTypeId: UInt64){ 
		let packType = &self.packTypes[packTypeId] as &PackType? ?? panic("This Pack Type does not exist.")
		assert(packType.amountMinted < packType.maxSupply, message: "This Pack Type is sold out.")
		assert(packType.takenFromReserved < packType.reserved, message: "You have used up all of the reserves.")
		packCollectionRef.deposit(token: <-create NFT(_packTypeId: packTypeId))
		packType.minted()
		packType.usedReserve()
	}
	
	init(){ 
		self.totalSupply = 0
		self.nextPackTypeId = 0
		self.packTypes ={} 
		self.CollectionStoragePath = /storage/ChainzPackCollection
		self.CollectionPublicPath = /public/ChainzPackCollection
		emit ContractInitialized()
	}
}
