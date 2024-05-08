import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/// A contract to lock NFT for a given duration
/// Locked NFT are stored in a user owned collection
/// The collection owner can unlock the NFT after duration has been exceeded
///
access(all)
contract NFTLocker{ 
	
	/// Contract events
	///
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event NFTLocked(
		id: UInt64,
		to: Address?,
		lockedAt: UInt64,
		lockedUntil: UInt64,
		duration: UInt64,
		nftType: Type
	)
	
	access(all)
	event NFTUnlocked(id: UInt64, from: Address?, nftType: Type)
	
	/// Named Paths
	///
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// Contract variables
	///
	access(all)
	var totalLockedTokens: UInt64
	
	/// Metadata Dictionaries
	///
	access(self)
	let lockedTokens:{ Type:{ UInt64: LockedData}}
	
	/// Data describing characteristics of the locked NFT
	///
	access(all)
	struct LockedData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let owner: Address
		
		access(all)
		let lockedAt: UInt64
		
		access(all)
		let lockedUntil: UInt64
		
		access(all)
		let duration: UInt64
		
		access(all)
		let nftType: Type
		
		access(all)
		let extension:{ String: AnyStruct}
		
		init(id: UInt64, owner: Address, duration: UInt64, nftType: Type){ 
			if let lockedToken = (NFTLocker.lockedTokens[nftType]!)[id]{ 
				self.id = id
				self.owner = lockedToken.owner
				self.lockedAt = lockedToken.lockedAt
				self.lockedUntil = lockedToken.lockedUntil
				self.duration = lockedToken.duration
				self.nftType = lockedToken.nftType
				self.extension = lockedToken.extension
			} else{ 
				self.id = id
				self.owner = owner
				self.lockedAt = UInt64(getCurrentBlock().timestamp)
				self.lockedUntil = self.lockedAt + duration
				self.duration = duration
				self.nftType = nftType
				self.extension ={} 
			}
		}
	}
	
	access(all)
	fun getNFTLockerDetails(id: UInt64, nftType: Type): NFTLocker.LockedData?{ 
		return (NFTLocker.lockedTokens[nftType]!)[id]
	}
	
	/// Determine if NFT can be unlocked
	///
	access(all)
	view fun canUnlockToken(id: UInt64, nftType: Type): Bool{ 
		if let lockedToken = (NFTLocker.lockedTokens[nftType]!)[id]{ 
			if lockedToken.lockedUntil < UInt64(getCurrentBlock().timestamp){ 
				return true
			}
		}
		return false
	}
	
	/// A public collection interface that returns the ids
	/// of nft locked for a given type
	///
	access(all)
	resource interface LockedCollection{ 
		access(all)
		fun getIDs(nftType: Type): [UInt64]?
	}
	
	/// A public collection interface allowing locking and unlocking of NFT
	///
	access(all)
	resource interface LockProvider{ 
		access(all)
		fun lock(token: @{NonFungibleToken.NFT}, duration: UInt64)
		
		access(all)
		fun unlock(id: UInt64, nftType: Type): @{NonFungibleToken.NFT}
	}
	
	/// An NFT Collection
	///
	access(all)
	resource Collection: LockedCollection, LockProvider{ 
		access(all)
		var lockedNFTs: @{Type:{ UInt64:{ NonFungibleToken.NFT}}}
		
		/// Unlock an NFT of a given type
		///
		access(all)
		fun unlock(id: UInt64, nftType: Type): @{NonFungibleToken.NFT}{ 
			pre{ 
				NFTLocker.canUnlockToken(id: id, nftType: nftType) == true:
					"locked duration has not been met"
			}
			let token <- self.lockedNFTs[nftType]?.remove(key: id)!!
			if let lockedToken = NFTLocker.lockedTokens[nftType]{ 
				lockedToken.remove(key: id)
			}
			NFTLocker.totalLockedTokens = NFTLocker.totalLockedTokens - 1
			emit NFTUnlocked(id: token.id, from: self.owner?.address, nftType: nftType)
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Lock an NFT of a given type
		///
		access(all)
		fun lock(token: @{NonFungibleToken.NFT}, duration: UInt64){ 
			let id: UInt64 = token.id
			let nftType: Type = token.getType()
			if NFTLocker.lockedTokens[nftType] == nil{ 
				NFTLocker.lockedTokens[nftType] ={} 
			}
			if self.lockedNFTs[nftType] == nil{ 
				self.lockedNFTs[nftType] <-!{} 
			}
			let ref = &self.lockedNFTs[nftType] as &{UInt64:{ NonFungibleToken.NFT}}?
			let oldToken <- (ref!).insert(key: id, <-token)
			let nestedLockRef = &NFTLocker.lockedTokens[nftType] as &{UInt64: NFTLocker.LockedData}?
			let lockedData = NFTLocker.LockedData(id: id, owner: (self.owner!).address, duration: duration, nftType: nftType)
			(nestedLockRef!).insert(key: id, lockedData)
			NFTLocker.totalLockedTokens = NFTLocker.totalLockedTokens + 1
			emit NFTLocked(id: id, to: self.owner?.address, lockedAt: lockedData.lockedAt, lockedUntil: lockedData.lockedUntil, duration: lockedData.duration, nftType: nftType)
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun getIDs(nftType: Type): [UInt64]?{ 
			return self.lockedNFTs[nftType]?.keys
		}
		
		init(){ 
			self.lockedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/NFTLockerCollection
		self.CollectionPublicPath = /public/NFTLockerCollection
		self.totalLockedTokens = 0
		self.lockedTokens ={} 
	}
}
