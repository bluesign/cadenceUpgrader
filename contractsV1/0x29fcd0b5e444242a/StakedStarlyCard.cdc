import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyCard from "../0x5b82f21c0edf76e3/StarlyCard.cdc"

import StarlyCardStaking from "./StarlyCardStaking.cdc"

import StarlyIDParser from "../0x5b82f21c0edf76e3/StarlyIDParser.cdc"

import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract StakedStarlyCard: NonFungibleToken{ 
	access(all)
	event CardStaked(id: UInt64, starlyID: String, beneficiary: Address, stakeTimestamp: UFix64, remainingResourceAtStakeTimestamp: UFix64)
	
	access(all)
	event CardUnstaked(id: UInt64, starlyID: String, beneficiary: Address, stakeTimestamp: UFix64, unstakeTimestamp: UFix64, remainingResourceAtUnstakeTimestamp: UFix64)
	
	access(all)
	event StakeBurned(id: UInt64, starlyID: String)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	var stakingEnabled: Bool
	
	access(all)
	var unstakingEnabled: Bool
	
	access(all)
	var totalSupply: UInt64
	
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
	resource interface StakePublic{ 
		access(all)
		fun getStarlyID(): String
		
		access(all)
		fun getBeneficiary(): Address
		
		access(all)
		fun getStakeTimestamp(): UFix64
		
		access(all)
		fun getRemainingResourceAtStakeTimestamp(): UFix64
		
		access(all)
		fun getUnlockedResource(): UFix64
		
		access(all)
		fun borrowStarlyCard(): &StarlyCard.NFT
	}
	
	access(all)
	struct StakeMetadataView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let starlyID: String
		
		access(all)
		let stakeTimestamp: UFix64
		
		access(all)
		let remainingResource: UFix64
		
		access(all)
		let remainingResourceAtStakeTimestamp: UFix64
		
		init(id: UInt64, starlyID: String, stakeTimestamp: UFix64, remainingResource: UFix64, remainingResourceAtStakeTimestamp: UFix64){ 
			self.id = id
			self.starlyID = starlyID
			self.stakeTimestamp = stakeTimestamp
			self.remainingResource = remainingResource
			self.remainingResourceAtStakeTimestamp = remainingResourceAtStakeTimestamp
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, StakePublic{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let starlyCard: @StarlyCard.NFT
		
		access(all)
		let beneficiary: Address
		
		access(all)
		let stakeTimestamp: UFix64
		
		access(all)
		let remainingResourceAtStakeTimestamp: UFix64
		
		init(id: UInt64, starlyCard: @StarlyCard.NFT, beneficiary: Address, stakeTimestamp: UFix64, remainingResourceAtStakeTimestamp: UFix64){ 
			self.id = id
			self.starlyCard <- starlyCard
			self.beneficiary = beneficiary
			self.stakeTimestamp = stakeTimestamp
			self.remainingResourceAtStakeTimestamp = remainingResourceAtStakeTimestamp
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<StakeMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "StakedStarlyCard #".concat(self.id.toString()), description: "id: ".concat(self.id.toString()).concat(", stakeTimestamp: ").concat(UInt64(self.stakeTimestamp).toString()), thumbnail: MetadataViews.HTTPFile(url: ""))
				case Type<StakeMetadataView>():
					return StakeMetadataView(id: self.id, starlyID: self.starlyCard.starlyID, stakeTimestamp: self.stakeTimestamp, remainingResource: StarlyCardStaking.getRemainingResourceWithDefault(starlyID: self.starlyCard.starlyID), remainingResourceAtStakeTimestamp: self.remainingResourceAtStakeTimestamp)
			}
			return nil
		}
		
		access(all)
		fun getStarlyID(): String{ 
			return self.starlyCard.starlyID
		}
		
		access(all)
		fun getBeneficiary(): Address{ 
			return self.beneficiary
		}
		
		access(all)
		fun getStakeTimestamp(): UFix64{ 
			return self.stakeTimestamp
		}
		
		access(all)
		fun getRemainingResourceAtStakeTimestamp(): UFix64{ 
			return self.remainingResourceAtStakeTimestamp
		}
		
		access(all)
		fun getUnlockedResource(): UFix64{ 
			let starlyID = self.starlyCard.starlyID
			let stakeTimestamp = self.stakeTimestamp
			let remainingResourceAtStakeTimestamp = self.remainingResourceAtStakeTimestamp
			let stakedSeconds = getCurrentBlock().timestamp - stakeTimestamp
			let metadata = StarlyMetadata.getCardEdition(starlyID: starlyID) ?? panic("Missing metadata")
			let collectionID = metadata.collection.id
			let initialResource = metadata.score ?? 0.0
			let claimedResourceBeforeStaking = initialResource - remainingResourceAtStakeTimestamp
			let remainingResource = StarlyCardStaking.getRemainingResource(collectionID: collectionID, starlyID: starlyID) ?? initialResource
			if remainingResource <= 0.0{ 
				return 0.0
			}
			let claimedResource = remainingResourceAtStakeTimestamp - remainingResource
			let claimResourcePerSecond = initialResource / 0.31556952 // using scale factor of 10*9 to avoid precision errors
			
			let unlockedResource = stakedSeconds / 10000.0 * claimResourcePerSecond / 10000.0 - claimedResource
			return unlockedResource > remainingResource ? remainingResource : unlockedResource
		}
		
		access(all)
		fun borrowStarlyCard(): &StarlyCard.NFT{ 
			let ref = &self.starlyCard as &StarlyCard.NFT
			return ref as! &StarlyCard.NFT
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// We put stake creation logic into minter, its job is to have checks, emit events, update counters
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintStake(starlyCard: @StarlyCard.NFT, beneficiary: Address, stakeTimestamp: UFix64): @StakedStarlyCard.NFT{ 
			pre{ 
				StakedStarlyCard.stakingEnabled:
					"Staking is disabled"
			}
			let starlyID = starlyCard.starlyID
			let remainingResource = StarlyCardStaking.getRemainingResourceWithDefault(starlyID: starlyID)
			let stake <- create NFT(id: StakedStarlyCard.totalSupply, starlyCard: <-starlyCard, beneficiary: beneficiary, stakeTimestamp: stakeTimestamp, remainingResourceAtStakeTimestamp: remainingResource)
			StakedStarlyCard.totalSupply = StakedStarlyCard.totalSupply + 1 as UInt64
			emit CardStaked(id: stake.id, starlyID: starlyID, beneficiary: beneficiary, stakeTimestamp: stakeTimestamp, remainingResourceAtStakeTimestamp: remainingResource)
			return <-stake
		}
	}
	
	// We put stake unstaking logic into burner, its job is to have checks, emit events, update counters
	access(all)
	resource NFTBurner{ 
		access(all)
		fun burnStake(stake: @StakedStarlyCard.NFT){ 
			pre{ 
				StakedStarlyCard.unstakingEnabled:
					"Unstaking is disabled"
				stake.stakeTimestamp < getCurrentBlock().timestamp:
					"Cannot unstake stake with stakeTimestamp more or equal to current timestamp"
			}
			let id = stake.id
			let starlyID = stake.starlyCard.starlyID
			let beneficiary = stake.beneficiary
			let stakeTimestamp = stake.stakeTimestamp
			let timestamp = getCurrentBlock().timestamp
			let seconds = timestamp - stake.stakeTimestamp
			destroy stake
			let remainingResource = StarlyCardStaking.getRemainingResourceWithDefault(starlyID: starlyID)
			emit CardUnstaked(id: id, starlyID: starlyID, beneficiary: beneficiary, stakeTimestamp: stakeTimestamp, unstakeTimestamp: timestamp, remainingResourceAtUnstakeTimestamp: remainingResource)
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowStakePublic(id: UInt64): &StakedStarlyCard.NFT
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(all)
		fun borrowStakePrivate(id: UInt64): &StakedStarlyCard.NFT
		
		access(all)
		fun stake(starlyCard: @StarlyCard.NFT, beneficiary: Address)
		
		access(all)
		fun unstake(id: UInt64)
		
		access(all)
		fun claimAll(limit: Int)
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
			let stake <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: stake.id, from: self.owner?.address)
			return <-stake
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @StakedStarlyCard.NFT
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
			let stake = nft as! &StakedStarlyCard.NFT
			return stake as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowStakePublic(id: UInt64): &StakedStarlyCard.NFT{ 
			let stakeRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let intermediateRef = stakeRef as! &StakedStarlyCard.NFT
			return intermediateRef as &StakedStarlyCard.NFT
		}
		
		access(all)
		fun stake(starlyCard: @StarlyCard.NFT, beneficiary: Address){ 
			let minter = StakedStarlyCard.account.storage.borrow<&NFTMinter>(from: StakedStarlyCard.MinterStoragePath)!
			let stake <- minter.mintStake(starlyCard: <-starlyCard, beneficiary: beneficiary, stakeTimestamp: getCurrentBlock().timestamp)
			self.deposit(token: <-stake)
		}
		
		access(all)
		fun unstake(id: UInt64){ 
			let burner = StakedStarlyCard.account.storage.borrow<&NFTBurner>(from: StakedStarlyCard.BurnerStoragePath)!
			let stake <- self.withdraw(withdrawID: id) as! @StakedStarlyCard.NFT
			burner.burnStake(stake: <-stake)
		}
		
		access(all)
		fun borrowStakePrivate(id: UInt64): &StakedStarlyCard.NFT{ 
			let stakePassRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return stakePassRef as! &StakedStarlyCard.NFT
		}
		
		access(all)
		fun claimAll(limit: Int){ 
			var i = 0
			let stakeIDs = self.getIDs()
			for stakeID in stakeIDs{ 
				let stakeRef = self.borrowStakePrivate(id: stakeID)
				let starlyID = stakeRef.starlyCard.starlyID
				let parsedStarlyID = StarlyIDParser.parse(starlyID: starlyID)
				let collectionID = parsedStarlyID.collectionID
				let remainingResource = StarlyCardStaking.getRemainingResource(collectionID: collectionID, starlyID: starlyID)
				if i > limit{ 
					return
				}
				i = i + 1
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setStakingEnabled(_ enabled: Bool){ 
			StakedStarlyCard.stakingEnabled = enabled
		}
		
		access(all)
		fun setUnstakingEnabled(_ enabled: Bool){ 
			StakedStarlyCard.unstakingEnabled = enabled
		}
		
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
		self.stakingEnabled = true
		self.unstakingEnabled = true
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/stakedStarlyCardCollection
		self.CollectionPublicPath = /public/stakedStarlyCardCollection
		self.AdminStoragePath = /storage/stakedStarlyCardAdmin
		self.MinterStoragePath = /storage/stakedStarlyCardMinter
		self.BurnerStoragePath = /storage/stakedStarlyCardBurner
		let admin <- create Admin()
		let minter <- admin.createNFTMinter()
		let burner <- admin.createNFTBurner()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		self.account.storage.save(<-burner, to: self.BurnerStoragePath)
		emit ContractInitialized()
	}
}
