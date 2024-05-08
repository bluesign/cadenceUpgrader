import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all)
contract TopShotEscrowV2{ 
	
	// -----------------------------------------------------------------------
	// TopShotEscrowV2 contract Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Escrowed(
		id: UInt64,
		owner: Address,
		NFTIds: [
			UInt64
		],
		duration: UFix64,
		startTime: UFix64
	)
	
	access(all)
	event Redeemed(id: UInt64, owner: Address, NFTIds: [UInt64], partial: Bool, time: UFix64)
	
	access(all)
	event EscrowCancelled(id: UInt64, owner: Address, NFTIds: [UInt64], partial: Bool, time: UFix64)
	
	access(all)
	event EscrowWithdraw(id: UInt64, from: Address?)
	
	access(all)
	event EscrowUpdated(id: UInt64, owner: Address, NFTIds: [UInt64])
	
	// -----------------------------------------------------------------------
	// TopShotEscrowV2 contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The total amount of EscrowItems that have been created
	access(all)
	var totalEscrows: UInt64
	
	// Escrow Storage Path
	access(all)
	let escrowStoragePath: StoragePath
	
	/// Escrow Public Path
	access(all)
	let escrowPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// TopShotEscrowV2 contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// This struct contains the status of the escrow
	// and is exposed so websites can use escrow information
	access(all)
	struct EscrowDetails{ 
		access(all)
		let owner: Address
		
		access(all)
		let escrowID: UInt64
		
		access(all)
		let NFTIds: [UInt64]?
		
		access(all)
		let starTime: UFix64
		
		access(all)
		let duration: UFix64
		
		access(all)
		let isRedeemable: Bool
		
		init(
			_owner: Address,
			_escrowID: UInt64,
			_NFTIds: [
				UInt64
			]?,
			_startTime: UFix64,
			_duration: UFix64,
			_isRedeemable: Bool
		){ 
			self.owner = _owner
			self.escrowID = _escrowID
			self.NFTIds = _NFTIds
			self.starTime = _startTime
			self.duration = _duration
			self.isRedeemable = _isRedeemable
		}
	}
	
	// An interface that exposes public fields and functions
	// of the EscrowItem resource
	access(all)
	resource interface EscrowItemPublic{ 
		access(all)
		let escrowID: UInt64
		
		access(all)
		var redeemed: Bool
		
		access(all)
		view fun hasBeenRedeemed(): Bool
		
		access(all)
		view fun isRedeemable(): Bool
		
		access(all)
		fun getEscrowDetails(): EscrowDetails
		
		access(all)
		fun redeem(NFTIds: [UInt64])
		
		access(all)
		fun addNFTs(NFTCollection: @TopShot.Collection)
	}
	
	// EscrowItem contains a NFT Collection (single or several NFTs) for a single escrow
	// Fields and functions are defined as private by default
	// to access escrow details, one can call getEscrowDetails()
	access(all)
	resource EscrowItem: EscrowItemPublic{ 
		
		// The id of this individual escrow
		access(all)
		let escrowID: UInt64
		
		access(self)
		var NFTCollection: [UInt64]?
		
		access(all)
		let startTime: UFix64
		
		access(self)
		var duration: UFix64
		
		access(all)
		var redeemed: Bool
		
		access(self)
		let receiverCap: Capability<&{NonFungibleToken.Receiver}>
		
		access(self)
		var lock: Bool
		
		init(_NFTCollection: @TopShot.Collection, _duration: UFix64, _receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			TopShotEscrowV2.totalEscrows = TopShotEscrowV2.totalEscrows + 1
			self.escrowID = TopShotEscrowV2.totalEscrows
			self.NFTCollection = _NFTCollection.getIDs()
			assert(self.NFTCollection != nil, message: "NFT Collection is empty")
			self.startTime = getCurrentBlock().timestamp
			self.duration = _duration
			assert(_receiverCap.borrow() != nil, message: "Cannot borrow receiver")
			self.receiverCap = _receiverCap
			self.redeemed = false
			self.lock = false
			let adminTopShotReceiverRef = TopShotEscrowV2.account.capabilities.get<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>(/public/MomentCollection).borrow<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>() ?? panic("Cannot borrow collection")
			for tokenId in self.NFTCollection!{ 
				let token <- _NFTCollection.withdraw(withdrawID: tokenId)
				adminTopShotReceiverRef.deposit(token: <-token)
			}
			assert(_NFTCollection.getIDs().length == 0, message: "can't destroy resources")
			destroy _NFTCollection
		}
		
		access(all)
		view fun isRedeemable(): Bool{ 
			return getCurrentBlock().timestamp > self.startTime + self.duration
		}
		
		access(all)
		view fun hasBeenRedeemed(): Bool{ 
			return self.redeemed
		}
		
		access(all)
		fun redeem(NFTIds: [UInt64]){ 
			pre{ 
				!self.lock:
					"Reentrant call"
				self.isRedeemable():
					"Not redeemable yet"
				!self.hasBeenRedeemed():
					"Has already been redeemed"
			}
			post{ 
				!self.lock:
					"Lock not released"
			}
			self.lock = true
			let collectionRef = self.receiverCap.borrow() ?? panic("Cannot borrow receiver")
			let providerTopShotProviderRef: &TopShot.Collection? = TopShotEscrowV2.account.storage.borrow<&TopShot.Collection>(from: /storage/MomentCollection) ?? panic("Cannot borrow collection")
			if NFTIds.length == 0 || NFTIds.length == self.NFTCollection?.length{ 
				// Iterate through the keys in the collection and deposit each one
				for tokenId in self.NFTCollection!{ 
					let token <- providerTopShotProviderRef?.withdraw(withdrawID: tokenId)!
					collectionRef.deposit(token: <-token)
				}
				self.redeemed = true
				emit Redeemed(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!, partial: false, time: getCurrentBlock().timestamp)
			} else{ 
				for NFTId in NFTIds{ 
					let token <- providerTopShotProviderRef?.withdraw(withdrawID: NFTId)!
					collectionRef.deposit(token: <-token)
					let index = self.NFTCollection?.firstIndex(of: NFTId) ?? panic("NFT ID not found")
					let removedId = self.NFTCollection?.remove(at: index!) ?? panic("NFT ID not found")
					assert(removedId == NFTId, message: "NFT ID mismatch")
				}
				if self.NFTCollection?.length == 0{ 
					self.redeemed = true
				}
				emit Redeemed(id: self.escrowID, owner: self.receiverCap.address, NFTIds: NFTIds, partial: !self.redeemed, time: getCurrentBlock().timestamp)
			}
			self.lock = false
		}
		
		access(all)
		fun getEscrowDetails(): EscrowDetails{ 
			return EscrowDetails(_owner: self.receiverCap.address, _escrowID: self.escrowID, _NFTIds: self.NFTCollection, _startTime: self.startTime, _duration: self.duration, _isRedeemable: self.isRedeemable())
		}
		
		access(all)
		fun setEscrowDuration(_ newDuration: UFix64){ 
			post{ 
				newDuration < self.duration:
					"Can only decrease duration"
			}
			self.duration = newDuration
		}
		
		access(all)
		fun cancelEscrow(NFTIds: [UInt64]){ 
			pre{ 
				!self.hasBeenRedeemed():
					"Has already been redeemed"
			}
			let collectionRef = self.receiverCap.borrow() ?? panic("Cannot borrow receiver")
			let providerTopShotProviderRef: &TopShot.Collection? = TopShotEscrowV2.account.storage.borrow<&TopShot.Collection>(from: /storage/MomentCollection) ?? panic("Cannot borrow collection")
			if NFTIds.length == 0 || NFTIds.length == self.NFTCollection?.length{ 
				self.redeemed = true
				for tokenId in self.NFTCollection!{ 
					let token <- providerTopShotProviderRef?.withdraw(withdrawID: tokenId)!
					collectionRef.deposit(token: <-token)
				}
				emit EscrowCancelled(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!, partial: false, time: getCurrentBlock().timestamp)
			} else{ 
				for NFTId in NFTIds{ 
					let token <- providerTopShotProviderRef?.withdraw(withdrawID: NFTId)!
					collectionRef.deposit(token: <-token)
					let index = self.NFTCollection?.firstIndex(of: NFTId) ?? panic("NFT ID not found")
					let removedId = self.NFTCollection?.remove(at: index!) ?? panic("NFT ID not found")
					assert(removedId == NFTId, message: "NFT ID mismatch")
				}
				if self.NFTCollection?.length == 0{ 
					self.redeemed = true
				}
				emit EscrowCancelled(id: self.escrowID, owner: self.receiverCap.address, NFTIds: NFTIds, partial: !self.redeemed, time: getCurrentBlock().timestamp)
			}
		}
		
		access(all)
		fun addNFTs(NFTCollection: @TopShot.Collection){ 
			pre{ 
				!self.hasBeenRedeemed():
					"Has already been redeemed"
			}
			let NFTIds = NFTCollection.getIDs()
			let adminTopShotReceiverRef = TopShotEscrowV2.account.capabilities.get<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>(/public/MomentCollection).borrow<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>() ?? panic("Cannot borrow collection")
			for NFTId in NFTIds{ 
				let token <- NFTCollection.withdraw(withdrawID: NFTId)
				adminTopShotReceiverRef.deposit(token: <-token)
			}
			assert(NFTCollection.getIDs().length == 0, message: "can't destroy resources")
			destroy NFTCollection
			(self.NFTCollection!).appendAll(NFTIds)
			emit EscrowUpdated(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!)
		}
	}
	
	// An interface to interact publicly with the Escrow Collection
	access(all)
	resource interface EscrowCollectionPublic{ 
		access(all)
		fun createEscrow(
			NFTCollection: @TopShot.Collection,
			duration: UFix64,
			receiverCap: Capability<&{NonFungibleToken.Receiver}>
		)
		
		access(all)
		fun borrowEscrow(escrowID: UInt64): &EscrowItem?
		
		access(all)
		fun getEscrowIDs(): [UInt64]
	}
	
	// EscrowCollection contains a dictionary of EscrowItems 
	// and provides methods for manipulating the EscrowItems
	access(all)
	resource EscrowCollection: EscrowCollectionPublic{ 
		
		// Escrow Items
		access(self)
		var escrowItems: @{UInt64: EscrowItem}
		
		// withdraw
		// Removes an escrow from the collection and moves it to the caller
		access(all)
		fun withdraw(escrowID: UInt64): @TopShotEscrowV2.EscrowItem{ 
			let escrow <- self.escrowItems.remove(key: escrowID) ?? panic("missing NFT")
			emit EscrowWithdraw(id: escrow.escrowID, from: self.owner?.address)
			return <-escrow
		}
		
		init(){ 
			self.escrowItems <-{} 
		}
		
		access(all)
		fun getEscrowIDs(): [UInt64]{ 
			return self.escrowItems.keys
		}
		
		access(all)
		fun createEscrow(NFTCollection: @TopShot.Collection, duration: UFix64, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			let TopShotIds = NFTCollection.getIDs()
			assert(receiverCap.check(), message: "Non Valid Receiver Capability")
			
			// create a new escrow item resource container
			let item <- create EscrowItem(_NFTCollection: <-NFTCollection, _duration: duration, _receiverCap: receiverCap)
			let escrowID = item.escrowID
			let startTime = item.startTime
			// update the escrow items dictionary with the new resources
			let oldItem <- self.escrowItems[escrowID] <- item
			destroy oldItem
			let owner = receiverCap.address
			emit Escrowed(id: escrowID, owner: owner, NFTIds: TopShotIds, duration: duration, startTime: startTime)
		}
		
		access(all)
		fun borrowEscrow(escrowID: UInt64): &EscrowItem?{ 
			// Get the escrow item resources
			if let escrowRef = &self.escrowItems[escrowID] as &EscrowItem?{ 
				return escrowRef
			}
			return nil
		}
		
		access(all)
		fun createEscrowRef(escrowID: UInt64): &EscrowItem{ 
			// Get the escrow item resources
			let escrowRef = (&self.escrowItems[escrowID] as &EscrowItem?)!
			return escrowRef
		}
	}
	
	// -----------------------------------------------------------------------
	// TopShotEscrowV2 contract-level function definitions
	// -----------------------------------------------------------------------
	// createEscrowCollection returns a new EscrowCollection resource to the caller
	access(all)
	fun createEscrowCollection(): @EscrowCollection{ 
		let escrowCollection <- create EscrowCollection()
		return <-escrowCollection
	}
	
	// createEscrow
	access(all)
	fun createEscrow(
		_ NFTCollection: @TopShot.Collection,
		_ duration: UFix64,
		_ receiverCap: Capability<&{NonFungibleToken.Receiver}>
	){ 
		let escrowCollectionRef =
			self.account.storage.borrow<&TopShotEscrowV2.EscrowCollection>(
				from: self.escrowStoragePath
			)
			?? panic("Couldn't borrow escrow collection")
		escrowCollectionRef.createEscrow(
			NFTCollection: <-NFTCollection,
			duration: duration,
			receiverCap: receiverCap
		)
	}
	
	// redeem tokens
	access(all)
	fun redeem(_ escrowID: UInt64, _ NFTIds: [UInt64]){ 
		let escrowCollectionRef =
			self.account.storage.borrow<&TopShotEscrowV2.EscrowCollection>(
				from: self.escrowStoragePath
			)
			?? panic("Couldn't borrow escrow collection")
		let escrowRef = escrowCollectionRef.borrowEscrow(escrowID: escrowID)!
		escrowRef.redeem(NFTIds: NFTIds)
		if escrowRef.redeemed{ 
			destroy <-escrowCollectionRef.withdraw(escrowID: escrowID)
		}
	}
	
	// batch redeem tokens
	access(all)
	fun batchRedeem(_ escrowIDs: [UInt64]){ 
		for escrowID in escrowIDs{ 
			let escrowCollectionRef = self.account.storage.borrow<&TopShotEscrowV2.EscrowCollection>(from: self.escrowStoragePath) ?? panic("Couldn't borrow escrow collection")
			let escrowRef = escrowCollectionRef.borrowEscrow(escrowID: escrowID)!
			escrowRef.redeem(NFTIds: [])
			if escrowRef.redeemed{ 
				destroy <-escrowCollectionRef.withdraw(escrowID: escrowID)
			}
		}
	}
	
	// -----------------------------------------------------------------------
	// TopShotEscrowV2 initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.totalEscrows = 0
		self.escrowStoragePath = /storage/TopShotEscrowV2
		self.escrowPublicPath = /public/TopShotEscrowV2
		
		// Setup collection onto Deployer's account
		let escrowCollection <- self.createEscrowCollection()
		self.account.storage.save(<-escrowCollection, to: self.escrowStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&TopShotEscrowV2.EscrowCollection>(
				self.escrowStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.escrowPublicPath)
	}
}
