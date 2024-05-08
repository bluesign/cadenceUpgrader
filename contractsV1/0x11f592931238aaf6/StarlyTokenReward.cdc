import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract StarlyTokenReward{ 
	access(all)
	event RewardPaid(rewardId: String, to: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(all)
		fun transfer(rewardId: String, to: Address, amount: UFix64){ 
			let rewardsVaultRef =
				StarlyTokenReward.account.storage.borrow<&StarlyToken.Vault>(
					from: StarlyToken.TokenStoragePath
				)!
			let receiverRef =
				getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(
					StarlyToken.TokenPublicReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic(
					"Could not borrow StarlyToken receiver reference to the recipient's vault!"
				)
			receiverRef.deposit(from: <-rewardsVaultRef.withdraw(amount: amount))
			emit RewardPaid(rewardId: rewardId, to: to)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/starlyTokenRewardAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// for payouts we will use account's default Starly token vault
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
