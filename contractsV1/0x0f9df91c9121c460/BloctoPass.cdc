// This is the implementation of BloctoPass, the Blocto Non-Fungible Token
// that is used in-conjunction with BLT, the Blocto Fungible Token
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import BloctoToken from "./BloctoToken.cdc"

import BloctoTokenStaking from "./BloctoTokenStaking.cdc"

import BloctoPassStamp from "./BloctoPassStamp.cdc"

access(all)
contract BloctoPass: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	// pre-defined lockup schedules
	// key: timestamp
	// value: percentage of BLT that must remain in the BloctoPass at this timestamp
	access(contract)
	var predefinedLockupSchedules: [{UFix64: UFix64}]
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event LockupScheduleDefined(id: Int, lockupSchedule:{ UFix64: UFix64})
	
	access(all)
	event LockupScheduleUpdated(id: Int, lockupSchedule:{ UFix64: UFix64})
	
	access(all)
	resource interface BloctoPassPrivate{ 
		access(all)
		fun stakeNewTokens(amount: UFix64)
		
		access(all)
		fun stakeUnstakedTokens(amount: UFix64)
		
		access(all)
		fun stakeRewardedTokens(amount: UFix64)
		
		access(all)
		fun requestUnstaking(amount: UFix64)
		
		access(all)
		fun unstakeAll()
		
		access(all)
		fun withdrawUnstakedTokens(amount: UFix64)
		
		access(all)
		fun withdrawRewardedTokens(amount: UFix64)
		
		access(all)
		fun withdrawAllUnlockedTokens(): @{FungibleToken.Vault}
		
		access(all)
		fun stampBloctoPass(from: @BloctoPassStamp.NFT)
	}
	
	access(all)
	resource interface BloctoPassPublic{ 
		access(all)
		fun getOriginalOwner(): Address?
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun getStamps(): [String]
		
		access(all)
		fun getVipTier(): UInt64
		
		access(all)
		fun getStakingInfo(): BloctoTokenStaking.StakerInfo
		
		access(all)
		view fun getLockupSchedule():{ UFix64: UFix64}
		
		access(all)
		view fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64
		
		access(all)
		view fun getLockupAmount(): UFix64
		
		access(all)
		view fun getIdleBalance(): UFix64
		
		access(all)
		view fun getTotalBalance(): UFix64
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, BloctoPassPrivate, BloctoPassPublic{ 
		// BLT holder vault
		access(self)
		let vault: @BloctoToken.Vault
		
		// BLT staker handle
		access(self)
		let staker: @BloctoTokenStaking.Staker
		
		// BloctoPass ID
		access(all)
		let id: UInt64
		
		// BloctoPass owner address
		// If the pass is transferred to another user, some perks will be disabled
		access(all)
		let originalOwner: Address?
		
		// BloctoPass metadata
		access(self)
		var metadata:{ String: String}
		
		// BloctoPass usage stamps, including voting records and special events
		access(self)
		var stamps: [String]
		
		// Total amount that's subject to lockup schedule
		access(all)
		let lockupAmount: UFix64
		
		// ID of predefined lockup schedule
		// If lockupScheduleId == nil, use custom lockup schedule instead
		access(all)
		let lockupScheduleId: Int?
		
		// Defines how much BloctoToken must remain in the BloctoPass on different dates
		// key: timestamp
		// value: percentage of BLT that must remain in the BloctoPass at this timestamp
		access(self)
		let lockupSchedule:{ UFix64: UFix64}?
		
		init(initID: UInt64, originalOwner: Address?, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupScheduleId: Int?, lockupSchedule:{ UFix64: UFix64}?){ 
			let stakingAdmin = BloctoPass.account.storage.borrow<&BloctoTokenStaking.Admin>(from: BloctoTokenStaking.StakingAdminStoragePath) ?? panic("Could not borrow admin reference")
			self.id = initID
			self.originalOwner = originalOwner
			self.metadata = metadata
			self.stamps = []
			self.vault <- vault as! @BloctoToken.Vault
			self.staker <- stakingAdmin.addStakerRecord(id: initID)
			
			// lockup calculations
			self.lockupAmount = self.vault.balance
			self.lockupScheduleId = lockupScheduleId
			self.lockupSchedule = lockupSchedule
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			post{ 
				self.getTotalBalance() >= self.getLockupAmount():
					"Cannot withdraw locked-up BLTs"
			}
			return <-self.vault.withdraw(amount: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			self.vault.deposit(from: <-from)
		}
		
		access(all)
		fun getOriginalOwner(): Address?{ 
			return self.originalOwner
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getStamps(): [String]{ 
			return self.stamps
		}
		
		access(all)
		fun getVipTier(): UInt64{ 
			// Disable VIP tier at launch
			
			// let stakedAmount = self.getStakingInfo().tokensStaked
			// if stakedAmount >= 1000.0 {
			//	 return 1
			// }
			
			// TODO: add more tiers
			return 0
		}
		
		access(all)
		view fun getLockupSchedule():{ UFix64: UFix64}{ 
			if self.lockupScheduleId == nil{ 
				return self.lockupSchedule ??{ 0.0: 0.0}
			}
			return BloctoPass.predefinedLockupSchedules[self.lockupScheduleId!]
		}
		
		access(all)
		fun getStakingInfo(): BloctoTokenStaking.StakerInfo{ 
			return BloctoTokenStaking.StakerInfo(stakerID: self.id)
		}
		
		access(all)
		view fun getLockupAmountAtTimestamp(timestamp: UFix64): UFix64{ 
			if self.lockupAmount == 0.0{ 
				return 0.0
			}
			let lockupSchedule = self.getLockupSchedule()
			let keys = lockupSchedule.keys
			var closestTimestamp = 0.0
			var lockupPercentage = 0.0
			for key in keys{ 
				if timestamp >= key && key >= closestTimestamp{ 
					lockupPercentage = lockupSchedule[key]!
					closestTimestamp = key
				}
			}
			return lockupPercentage * self.lockupAmount
		}
		
		access(all)
		view fun getLockupAmount(): UFix64{ 
			return self.getLockupAmountAtTimestamp(timestamp: getCurrentBlock().timestamp)
		}
		
		access(all)
		view fun getIdleBalance(): UFix64{ 
			return self.vault.balance
		}
		
		access(all)
		view fun getTotalBalance(): UFix64{ 
			return self.getIdleBalance() + BloctoTokenStaking.StakerInfo(stakerID: self.id).totalTokensInRecord()
		}
		
		// Private staking methods
		access(all)
		fun stakeNewTokens(amount: UFix64){ 
			self.staker.stakeNewTokens(<-self.vault.withdraw(amount: amount))
		}
		
		access(all)
		fun stakeUnstakedTokens(amount: UFix64){ 
			self.staker.stakeUnstakedTokens(amount: amount)
		}
		
		access(all)
		fun stakeRewardedTokens(amount: UFix64){ 
			self.staker.stakeRewardedTokens(amount: amount)
		}
		
		access(all)
		fun requestUnstaking(amount: UFix64){ 
			self.staker.requestUnstaking(amount: amount)
		}
		
		access(all)
		fun unstakeAll(){ 
			self.staker.unstakeAll()
		}
		
		access(all)
		fun withdrawUnstakedTokens(amount: UFix64){ 
			let vault <- self.staker.withdrawUnstakedTokens(amount: amount)
			self.vault.deposit(from: <-vault)
		}
		
		access(all)
		fun withdrawRewardedTokens(amount: UFix64){ 
			let vault <- self.staker.withdrawRewardedTokens(amount: amount)
			self.vault.deposit(from: <-vault)
		}
		
		access(all)
		fun withdrawAllUnlockedTokens(): @{FungibleToken.Vault}{ 
			let unlockedAmount = self.getTotalBalance() - self.getLockupAmount()
			let withdrawAmount = unlockedAmount < self.getIdleBalance() ? unlockedAmount : self.getIdleBalance()
			return <-self.vault.withdraw(amount: withdrawAmount)
		}
		
		access(all)
		fun stampBloctoPass(from: @BloctoPassStamp.NFT){ 
			self.stamps.append(from.getMessage())
			destroy from
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	// CollectionPublic is a custom interface that allows us to
	// access the public fields and methods for our BloctoPass Collection
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowBloctoPassPublic(id: UInt64): &BloctoPass.NFT
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(all)
		fun borrowBloctoPassPrivate(id: UInt64): &BloctoPass.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, CollectionPrivate{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		// withdrawal is disabled during lockup period
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
			let token <- token as! @BloctoPass.NFT
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
		
		// borrowBloctoPassPublic gets the public references to a BloctoPass NFT in the collection
		// and returns it to the caller as a reference to the NFT
		access(all)
		fun borrowBloctoPassPublic(id: UInt64): &BloctoPass.NFT{ 
			let bloctoPassRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let intermediateRef = bloctoPassRef as! &BloctoPass.NFT
			return intermediateRef as &BloctoPass.NFT
		}
		
		// borrowBloctoPassPrivate gets the private references to a BloctoPass NFT in the collection
		// and returns it to the caller as a reference to the NFT
		access(all)
		fun borrowBloctoPassPrivate(id: UInt64): &BloctoPass.NFT{ 
			let bloctoPassRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return bloctoPassRef as! &BloctoPass.NFT
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
	
	access(all)
	resource interface MinterPublic{ 
		access(all)
		fun mintBasicNFT(recipient: &{NonFungibleToken.CollectionPublic})
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter: MinterPublic{ 
		
		// adds a new predefined lockup schedule
		access(all)
		fun setupPredefinedLockupSchedule(lockupSchedule:{ UFix64: UFix64}){ 
			BloctoPass.predefinedLockupSchedules.append(lockupSchedule)
			emit LockupScheduleDefined(id: BloctoPass.predefinedLockupSchedules.length, lockupSchedule: lockupSchedule)
		}
		
		// updates a predefined lockup schedule
		// note that this function should be avoided 
		access(all)
		fun updatePredefinedLockupSchedule(id: Int, lockupSchedule:{ UFix64: UFix64}){ 
			BloctoPass.predefinedLockupSchedules[id] = lockupSchedule
			emit LockupScheduleUpdated(id: id, lockupSchedule: lockupSchedule)
		}
		
		// mintBasicNFT mints a new NFT without any special metadata or lockups
		access(all)
		fun mintBasicNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
			self.mintNFT(recipient: recipient, metadata:{} )
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			self.mintNFTWithCustomLockup(recipient: recipient, metadata: metadata, vault: <-BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>()), lockupSchedule:{ 0.0: 0.0})
		}
		
		access(all)
		fun mintNFTWithPredefinedLockup(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupScheduleId: Int?){ 
			
			// create a new NFT
			var newNFT <- create NFT(initID: BloctoPass.totalSupply, originalOwner: recipient.owner?.address, metadata: metadata, vault: <-vault, lockupScheduleId: lockupScheduleId, lockupSchedule: nil)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			BloctoPass.totalSupply = BloctoPass.totalSupply + UInt64(1)
		}
		
		access(all)
		fun mintNFTWithCustomLockup(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}, vault: @{FungibleToken.Vault}, lockupSchedule:{ UFix64: UFix64}){ 
			
			// create a new NFT
			var newNFT <- create NFT(initID: BloctoPass.totalSupply, originalOwner: recipient.owner?.address, metadata: metadata, vault: <-vault, lockupScheduleId: nil, lockupSchedule: lockupSchedule)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			BloctoPass.totalSupply = BloctoPass.totalSupply + UInt64(1)
		}
	}
	
	access(all)
	fun getPredefinedLockupSchedule(id: Int):{ UFix64: UFix64}{ 
		return self.predefinedLockupSchedules[id]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.predefinedLockupSchedules = []
		self.CollectionStoragePath = /storage/bloctoPassCollection
		self.CollectionPublicPath = /public/bloctoPassCollection
		self.MinterStoragePath = /storage/bloctoPassMinter
		self.MinterPublicPath = /public/bloctoPassMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, BloctoPass.CollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
