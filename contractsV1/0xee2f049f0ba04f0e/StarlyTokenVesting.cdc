import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract StarlyTokenVesting: NonFungibleToken{ 
	access(all)
	event TokensVested(id: UInt64, beneficiary: Address, amount: UFix64)
	
	access(all)
	event TokensReleased(id: UInt64, beneficiary: Address, amount: UFix64, remainingAmount: UFix64)
	
	access(all)
	event VestingBurned(id: UInt64, beneficiary: Address, amount: UFix64)
	
	access(all)
	event TokensBurned(id: UInt64, amount: UFix64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event VestingInitialized(beneficiary: Address)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalVested: UFix64
	
	access(all)
	var totalReleased: UFix64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let BurnerStoragePath: StoragePath
	
	access(all)
	resource interface VestingPublic{ 
		access(all)
		fun getBeneficiary(): Address
		
		access(all)
		fun getInitialVestedAmount(): UFix64
		
		access(all)
		fun getVestedAmount(): UFix64
		
		access(all)
		fun getVestingSchedule(): &{StarlyTokenVesting.IVestingSchedule}
		
		access(all)
		fun getReleasableAmount(): UFix64
	}
	
	access(all)
	enum VestingType: UInt8{ 
		access(all)
		case linear
		
		access(all)
		case period
	}
	
	access(all)
	resource interface IVestingSchedule{ 
		access(all)
		fun getReleasePercent(): UFix64
		
		access(all)
		fun getStartTimestamp(): UFix64
		
		access(all)
		fun getEndTimestamp(): UFix64
		
		access(all)
		fun getNextUnlock():{ UFix64: UFix64}
		
		access(all)
		fun getVestingType(): VestingType
		
		access(all)
		fun toString(): String
	}
	
	access(all)
	resource LinearVestingSchedule: IVestingSchedule{ 
		access(all)
		let startTimestamp: UFix64
		
		access(all)
		let endTimestamp: UFix64
		
		init(startTimestamp: UFix64, endTimestamp: UFix64){ 
			pre{ 
				endTimestamp > startTimestamp:
					"endTimestamp cannot be less than startTimestamp"
			}
			self.startTimestamp = startTimestamp
			self.endTimestamp = endTimestamp
		}
		
		access(all)
		fun getReleasePercent(): UFix64{ 
			let timestamp = getCurrentBlock().timestamp
			if timestamp >= self.endTimestamp{ 
				return 1.0
			} else if timestamp < self.startTimestamp{ 
				return 0.0
			} else{ 
				let duration = self.endTimestamp - self.startTimestamp
				let progress = timestamp - self.startTimestamp
				return progress / duration
			}
		}
		
		access(all)
		fun getStartTimestamp(): UFix64{ 
			return self.startTimestamp
		}
		
		access(all)
		fun getEndTimestamp(): UFix64{ 
			return self.endTimestamp
		}
		
		access(all)
		fun getVestingType(): VestingType{ 
			return VestingType.linear
		}
		
		access(all)
		fun getNextUnlock():{ UFix64: UFix64}{ 
			return{ getCurrentBlock().timestamp: self.getReleasePercent()}
		}
		
		access(all)
		fun toString(): String{ 
			return "LinearVestingSchedule(startTimestamp: ".concat(self.startTimestamp.toString()).concat(", endTimestamp: ").concat(self.endTimestamp.toString()).concat(", releasePercent: ").concat(self.getReleasePercent().toString()).concat(")")
		}
	}
	
	access(all)
	resource PeriodVestingSchedule: IVestingSchedule{ 
		access(all)
		let startTimestamp: UFix64
		
		access(all)
		let endTimestamp: UFix64
		
		access(self)
		let schedule:{ UFix64: UFix64}
		
		init(schedule:{ UFix64: UFix64}){ 
			self.schedule = schedule
			let keys = self.schedule.keys
			var startTimestamp = 0.0
			var endTimestamp = 0.0
			for key in keys{ 
				if self.schedule[key]! == 0.0{ 
					startTimestamp = key
				}
				if self.schedule[key]! == 1.0{ 
					endTimestamp = key
				}
			}
			self.startTimestamp = startTimestamp
			self.endTimestamp = endTimestamp
		}
		
		access(all)
		fun getReleasePercent(): UFix64{ 
			let timestamp = getCurrentBlock().timestamp
			let keys = self.schedule.keys
			var closestTimestamp = 0.0
			var releasePercent = 0.0
			for key in keys{ 
				if timestamp >= key && key >= closestTimestamp{ 
					releasePercent = self.schedule[key]!
					closestTimestamp = key
				}
			}
			return releasePercent
		}
		
		access(all)
		fun getStartTimestamp(): UFix64{ 
			return self.startTimestamp
		}
		
		access(all)
		fun getEndTimestamp(): UFix64{ 
			return self.endTimestamp
		}
		
		access(all)
		fun getVestingType(): VestingType{ 
			return VestingType.period
		}
		
		access(all)
		fun getNextUnlock():{ UFix64: UFix64}{ 
			let timestamp = getCurrentBlock().timestamp
			let keys = self.schedule.keys
			var closestTimestamp = self.endTimestamp
			var releasePercent = 1.0
			for key in keys{ 
				if timestamp <= key && key <= closestTimestamp{ 
					releasePercent = self.schedule[key]!
					closestTimestamp = key
				}
			}
			return{ closestTimestamp: releasePercent}
		}
		
		access(all)
		fun toString(): String{ 
			return "PeriodVestingSchedule(releasePercent: ".concat(self.getReleasePercent().toString()).concat(")")
		}
	}
	
	access(all)
	struct VestingMetadataView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let beneficiary: Address
		
		access(all)
		let initialVestedAmount: UFix64
		
		access(all)
		let remainingVestedAmount: UFix64
		
		access(all)
		let vestingType: VestingType
		
		access(all)
		let startTimestamp: UFix64
		
		access(all)
		let endTimestamp: UFix64
		
		access(all)
		let nextUnlock:{ UFix64: UFix64}
		
		access(all)
		let releasePercent: UFix64
		
		access(all)
		let releasableAmount: UFix64
		
		init(id: UInt64, beneficiary: Address, initialVestedAmount: UFix64, remainingVestedAmount: UFix64, vestingType: VestingType, startTimestamp: UFix64, endTimestamp: UFix64, nextUnlock:{ UFix64: UFix64}, releasePercent: UFix64, releasableAmount: UFix64){ 
			self.id = id
			self.beneficiary = beneficiary
			self.initialVestedAmount = initialVestedAmount
			self.remainingVestedAmount = remainingVestedAmount
			self.vestingType = vestingType
			self.startTimestamp = startTimestamp
			self.endTimestamp = endTimestamp
			self.nextUnlock = nextUnlock
			self.releasePercent = releasePercent
			self.releasableAmount = releasableAmount
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, VestingPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let beneficiary: Address
		
		access(all)
		let initialVestedAmount: UFix64
		
		access(contract)
		let vestedVault: @StarlyToken.Vault
		
		access(contract)
		let vestingSchedule: @{StarlyTokenVesting.IVestingSchedule}
		
		init(id: UInt64, beneficiary: Address, vestedVault: @StarlyToken.Vault, vestingSchedule: @{StarlyTokenVesting.IVestingSchedule}){ 
			self.id = id
			self.beneficiary = beneficiary
			self.initialVestedAmount = vestedVault.balance
			self.vestedVault <- vestedVault
			self.vestingSchedule <- vestingSchedule
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<VestingMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "StarlyTokenVesting #".concat(self.id.toString()), description: "id: ".concat(self.id.toString()).concat(", beneficiary: ").concat(self.beneficiary.toString()).concat(", vestedAmount: ").concat(self.vestedVault.balance.toString()).concat(", vestingSchedule: ").concat(self.vestingSchedule.toString()), thumbnail: MetadataViews.HTTPFile(url: ""))
				case Type<VestingMetadataView>():
					return VestingMetadataView(id: self.id, beneficiary: self.getBeneficiary(), initialVestedAmount: self.getInitialVestedAmount(), remainingVestedAmount: self.vestedVault.balance, vestingType: self.vestingSchedule.getVestingType(), startTimestamp: self.vestingSchedule.getStartTimestamp(), endTimestamp: self.vestingSchedule.getEndTimestamp(), nextUnlock: self.vestingSchedule.getNextUnlock(), releasePercent: self.vestingSchedule.getReleasePercent(), releasableAmount: self.getReleasableAmount())
			}
			return nil
		}
		
		access(all)
		fun getBeneficiary(): Address{ 
			return self.beneficiary
		}
		
		access(all)
		fun getInitialVestedAmount(): UFix64{ 
			return self.initialVestedAmount
		}
		
		access(all)
		fun getVestedAmount(): UFix64{ 
			return self.vestedVault.balance
		}
		
		access(all)
		fun getVestingSchedule(): &{StarlyTokenVesting.IVestingSchedule}{ 
			return &self.vestingSchedule as &{StarlyTokenVesting.IVestingSchedule}
		}
		
		access(all)
		fun getReleasableAmount(): UFix64{ 
			let initialAmount = self.initialVestedAmount
			let currentAmount = self.vestedVault.balance
			let alreadyReleasedAmount = initialAmount - currentAmount
			let releasePercent = self.vestingSchedule.getReleasePercent()
			let releasableAmount = initialAmount * releasePercent - alreadyReleasedAmount
			return releasableAmount
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// We put vesting creation logic into minter, its job is to have checks, emit events, update counters
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintLinear(beneficiary: Address, vestedVault: @StarlyToken.Vault, startTimestamp: UFix64, endTimestamp: UFix64): @StarlyTokenVesting.NFT{ 
			let vestingSchedule <- create LinearVestingSchedule(startTimestamp: startTimestamp, endTimestamp: endTimestamp)
			return <-self.mintInternal(beneficiary: beneficiary, vestedVault: <-vestedVault, vestingSchedule: <-vestingSchedule)
		}
		
		access(all)
		fun mintPeriod(beneficiary: Address, vestedVault: @StarlyToken.Vault, schedule:{ UFix64: UFix64}): @StarlyTokenVesting.NFT{ 
			let vestingSchedule <- create PeriodVestingSchedule(schedule: schedule)
			return <-self.mintInternal(beneficiary: beneficiary, vestedVault: <-vestedVault, vestingSchedule: <-vestingSchedule)
		}
		
		access(self)
		fun mintInternal(beneficiary: Address, vestedVault: @StarlyToken.Vault, vestingSchedule: @{StarlyTokenVesting.IVestingSchedule}): @StarlyTokenVesting.NFT{ 
			pre{ 
				vestedVault.balance > 0.0:
					"vestedVault balance cannot be zero"
			}
			let vesting <- create NFT(id: StarlyTokenVesting.totalSupply, beneficiary: beneficiary, vestedVault: <-vestedVault, vestingSchedule: <-vestingSchedule)
			let vestedAmount = vesting.vestedVault.balance
			StarlyTokenVesting.totalSupply = StarlyTokenVesting.totalSupply + 1 as UInt64
			StarlyTokenVesting.totalVested = StarlyTokenVesting.totalVested + vestedAmount
			emit TokensVested(id: vesting.id, beneficiary: beneficiary, amount: vestedAmount)
			return <-vesting
		}
	}
	
	// We put releasing logic into burner, its job is to have checks, emit events, update counters
	access(all)
	resource NFTBurner{ 
		// if admin owns the vesting NFT we can burn it to release tokens
		access(all)
		fun burn(vesting: @StarlyTokenVesting.NFT){ 
			let vestedAmount = vesting.vestedVault.balance
			let returnVaultRef = StarlyTokenVesting.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)!
			returnVaultRef.deposit(from: <-vesting.vestedVault.withdraw(amount: vestedAmount))
			StarlyTokenVesting.totalVested = StarlyTokenVesting.totalVested - vestedAmount
			emit VestingBurned(id: vesting.id, beneficiary: vesting.beneficiary, amount: vestedAmount)
			destroy vesting
		}
		
		// user can only release tokens
		access(all)
		fun release(vestingRef: &StarlyTokenVesting.NFT){ 
			let receiverRef = getAccount(vestingRef.beneficiary).capabilities.get<&{FungibleToken.Receiver}>(StarlyToken.TokenPublicReceiverPath).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow StarlyToken receiver reference to the beneficiary's vault!")
			let releaseAmount = vestingRef.getReleasableAmount()
			receiverRef.deposit(from: <-vestingRef.vestedVault.withdraw(amount: releaseAmount))
			StarlyTokenVesting.totalVested = StarlyTokenVesting.totalVested - releaseAmount
			StarlyTokenVesting.totalReleased = StarlyTokenVesting.totalReleased + releaseAmount
			emit TokensReleased(id: vestingRef.id, beneficiary: vestingRef.beneficiary, amount: releaseAmount, remainingAmount: vestingRef.vestedVault.balance)
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowVestingPublic(id: UInt64): &StarlyTokenVesting.NFT
		
		access(all)
		fun getIDs(): [UInt64]
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(all)
		fun borrowVestingPrivate(id: UInt64): &StarlyTokenVesting.NFT
		
		access(all)
		fun release(id: UInt64)
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, CollectionPrivate, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let vesting <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: vesting.id, from: self.owner?.address)
			return <-vesting
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @StarlyTokenVesting.NFT
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let vesting = nft as! &StarlyTokenVesting.NFT
			return vesting as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowVestingPublic(id: UInt64): &StarlyTokenVesting.NFT{ 
			let vestingRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let intermediateRef = vestingRef as! &StarlyTokenVesting.NFT
			return intermediateRef as &StarlyTokenVesting.NFT
		}
		
		access(all)
		fun release(id: UInt64){ 
			let burner = StarlyTokenVesting.account.storage.borrow<&NFTBurner>(from: StarlyTokenVesting.BurnerStoragePath)!
			let vestingRef = self.borrowVestingPrivate(id: id)
			return burner.release(vestingRef: vestingRef)
		}
		
		access(all)
		fun borrowVestingPrivate(id: UInt64): &StarlyTokenVesting.NFT{ 
			let vestingRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return vestingRef as! &StarlyTokenVesting.NFT
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createEmptyCollectionAndNotify(beneficiary: Address): @{NonFungibleToken.Collection}{ 
		emit VestingInitialized(beneficiary: beneficiary)
		return <-self.createEmptyCollection(nftType: Type<@Collection>())
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			return <-create NFTMinter()
		}
		
		access(all)
		fun createNFTBurner(): @NFTBurner{ 
			return <-create NFTBurner()
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.totalVested = 0.0
		self.totalReleased = 0.0
		self.CollectionStoragePath = /storage/starlyTokenVestingCollection
		self.CollectionPublicPath = /public/starlyTokenVestingCollection
		self.AdminStoragePath = /storage/starlyTokenVestingAdmin
		self.MinterStoragePath = /storage/starlyTokenVestingMinter
		self.BurnerStoragePath = /storage/starlyTokenVestingBurner
		let admin <- create Admin()
		let minter <- admin.createNFTMinter()
		let burner <- admin.createNFTBurner()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		self.account.storage.save(<-burner, to: self.BurnerStoragePath)
		// we will use account's default Starly token vault
		if self.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath) == nil{ 
			self.account.storage.save(<-StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()), to: StarlyToken.TokenStoragePath)
			var capability_1 = self.account.capabilities.storage.issue<&StarlyToken.Vault>(StarlyToken.TokenStoragePath)
			self.account.capabilities.publish(capability_1, at: StarlyToken.TokenPublicReceiverPath)
			var capability_2 = self.account.capabilities.storage.issue<&StarlyToken.Vault>(StarlyToken.TokenStoragePath)
			self.account.capabilities.publish(capability_2, at: StarlyToken.TokenPublicBalancePath)
		}
		emit ContractInitialized()
	}
}
