import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyIDParser from "../0x5b82f21c0edf76e3/StarlyIDParser.cdc"

import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"

import StarlyMetadataViews from "../0x5b82f21c0edf76e3/StarlyMetadataViews.cdc"

import StakedStarlyCard from "./StakedStarlyCard.cdc"

import StarlyCardStaking from "./StarlyCardStaking.cdc"

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

import StarlyTokenStaking from "../0x76a9b420a331b9f0/StarlyTokenStaking.cdc"

access(all)
contract StarlyCardStakingClaims{ 
	access(all)
	event ClaimPaid(amount: UFix64, to: Address, paidStakeIDs: [UInt64])
	
	access(all)
	var claimingEnabled: Bool
	
	access(contract)
	var recentClaims: @{Address: RecentClaims}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource RecentClaims{ 
		access(self)
		let timestamps: [UFix64]
		
		access(self)
		let claimAmounts: [UFix64]
		
		access(all)
		var windowSizeSeconds: UFix64
		
		access(all)
		fun addClaim(
			timestamp: UFix64,
			starlyID: String,
			amountToClaim: UFix64,
			maxDailyClaimAmount: UFix64
		): UFix64{ 
			let thresholdTimestamp = timestamp - self.windowSizeSeconds
			var i = 0
			var alreadyClaimed = 0.0
			// remove old claims
			while i < self.timestamps.length{ 
				if self.timestamps[i] <= thresholdTimestamp{ 
					self.timestamps.remove(at: i)
					self.claimAmounts.remove(at: i)
				} else{ 
					alreadyClaimed = alreadyClaimed + self.claimAmounts[i]
					i = i + 1
				}
			}
			let availableAmount = maxDailyClaimAmount.saturatingSubtract(alreadyClaimed)
			if availableAmount <= 0.0{ 
				return 0.0
			}
			let claimAmount = amountToClaim < availableAmount ? amountToClaim : availableAmount
			self.timestamps.append(timestamp)
			self.claimAmounts.append(claimAmount)
			return claimAmount
		}
		
		access(all)
		fun getClaimedAmount(): UFix64{ 
			let thresholdTimestamp = getCurrentBlock().timestamp - self.windowSizeSeconds
			var i = 0
			var claimedAmount = 0.0
			while i < self.timestamps.length{ 
				if self.timestamps[i] > thresholdTimestamp{ 
					claimedAmount = claimedAmount + self.claimAmounts[i]
				}
				i = i + 1
			}
			return claimedAmount
		}
		
		init(){ 
			self.windowSizeSeconds = UFix64(24 * 60 * 60)
			self.timestamps = []
			self.claimAmounts = []
		}
	}
	
	access(all)
	fun claim(ids: [UInt64], address: Address){ 
		pre{ 
			StarlyCardStakingClaims.claimingEnabled:
				"Claiming is disabled"
		}
		let maxDailyClaimAmount = self.getDailyClaimAmountLimitByAddress(address: address)
		if !self.recentClaims.containsKey(address){ 
			self.recentClaims[address] <-! create RecentClaims()
		}
		let remainingResourceEditor =
			self.account.storage.borrow<&{StarlyCardStaking.IEditor}>(
				from: StarlyCardStaking.EditorProxyStoragePath
			)
			?? panic("Could not borrow a reference to StarlyCardStaking.EditorProxyStoragePath!")
		// get all staked cards
		let account = getAccount(address)
		let cardStakeCollectionRef =
			(
				account.capabilities.get<
					&{StakedStarlyCard.CollectionPublic, NonFungibleToken.CollectionPublic}
				>(StakedStarlyCard.CollectionPublicPath)!
			).borrow()
			?? panic("Could not borrow capability from public StarlyTokenStaking collection!")
		let userRecentClaims = (&self.recentClaims[address] as &RecentClaims?)!
		let currentTimestamp = getCurrentBlock().timestamp
		var payoutAmount = 0.0
		let paidStakeIDs: [UInt64] = []
		for id in ids{ 
			let nft = cardStakeCollectionRef.borrowStakePublic(id: id)
			let starlyID = nft.getStarlyID()
			let stakeTimestamp = nft.getStakeTimestamp()
			let metadata = StarlyMetadata.getCardEdition(starlyID: starlyID) ?? panic("Missing metadata")
			let collectionID = metadata.collection.id
			let initialResource = metadata.score ?? 0.0
			let remainingResource = StarlyCardStaking.getRemainingResource(collectionID: collectionID, starlyID: starlyID) ?? initialResource
			if remainingResource <= 0.0{ 
				continue
			}
			let amountToClaim = nft.getUnlockedResource()
			let claimAmount = userRecentClaims.addClaim(timestamp: currentTimestamp, starlyID: starlyID, amountToClaim: amountToClaim, maxDailyClaimAmount: maxDailyClaimAmount)
			if claimAmount <= 0.0{ 
				continue
			}
			let newRemainingResource = remainingResource - claimAmount
			remainingResourceEditor.setRemainingResource(collectionID: collectionID, starlyID: starlyID, remainingResource: newRemainingResource)
			payoutAmount = payoutAmount + claimAmount
			paidStakeIDs.append(id)
		}
		if payoutAmount > 0.0{ 
			let claimVaultRef = StarlyCardStakingClaims.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)!
			let receiverRef = account.capabilities.get<&{FungibleToken.Receiver}>(StarlyToken.TokenPublicReceiverPath).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow StarlyToken receiver reference to the beneficiary's vault!")
			receiverRef.deposit(from: <-claimVaultRef.withdraw(amount: payoutAmount))
			emit ClaimPaid(amount: payoutAmount, to: address, paidStakeIDs: paidStakeIDs)
		}
	}
	
	access(all)
	fun getClaimedAmountByAddress(address: Address): UFix64{ 
		if !self.recentClaims.containsKey(address){ 
			return 0.0
		} else{ 
			let userRecentClaims = (&self.recentClaims[address] as &RecentClaims?)!
			return userRecentClaims.getClaimedAmount()
		}
	}
	
	access(all)
	fun getRemainingDailyClaimAmountByAddress(address: Address): UFix64{ 
		return self.getDailyClaimAmountLimitByAddress(address: address).saturatingSubtract(
			self.getClaimedAmountByAddress(address: address)
		)
	}
	
	access(all)
	fun getDailyClaimAmountLimitByAddress(address: Address): UFix64{ 
		let stakeCollectionRef =
			(
				getAccount(address).capabilities.get<
					&{StarlyTokenStaking.CollectionPublic, NonFungibleToken.CollectionPublic}
				>(StarlyTokenStaking.CollectionPublicPath)!
			).borrow()
			?? panic("Could not borrow capability from public StarlyTokenStaking collection!")
		let stakedAmount = stakeCollectionRef.getStakedAmount()
		return self.getDailyClaimAmount(stakedAmount: stakedAmount)
	}
	
	access(all)
	fun getDailyClaimAmount(stakedAmount: UFix64): UFix64{ 
		return stakedAmount / 100.0
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setClaimingEnabled(_ enabled: Bool){ 
			StarlyCardStakingClaims.claimingEnabled = enabled
		}
	}
	
	init(){ 
		self.claimingEnabled = true
		self.recentClaims <-{} 
		self.AdminStoragePath = /storage/starlyCardStakingClaimsAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		if self.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
		== nil{ 
			self.account.storage.save(
				<-StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()),
				to: StarlyToken.TokenStoragePath
			)
			var capability_1 =
				self.account.capabilities.storage.issue<&StarlyToken.Vault>(
					StarlyToken.TokenStoragePath
				)
			self.account.capabilities.publish(capability_1, at: StarlyToken.TokenPublicReceiverPath)
			var capability_2 =
				self.account.capabilities.storage.issue<&StarlyToken.Vault>(
					StarlyToken.TokenStoragePath
				)
			self.account.capabilities.publish(capability_2, at: StarlyToken.TokenPublicBalancePath)
		}
	}
}
