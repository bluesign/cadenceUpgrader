import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TFCPayouts{ 
	
	// Events
	access(all)
	event PayoutCompleted(to: Address, amount: UFix64, token: String)
	
	access(all)
	event ContractInitialized()
	
	// Named Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	resource Administrator{ 
		access(all)
		fun payout(
			to: Address,
			from: @{FungibleToken.Vault},
			paymentVaultType: Type,
			receiverPath: PublicPath
		){ 
			let amount = from.balance
			let receiver =
				getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(receiverPath).borrow<
					&{FungibleToken.Receiver}
				>()
				?? panic("Could not borrow receiver reference to the recipient's Vault")
			receiver.deposit(from: <-from)
			emit PayoutCompleted(to: to, amount: amount, token: paymentVaultType.identifier)
		}
	}
	
	init(){ 
		// Set our named paths
		self.AdminStoragePath = /storage/TFCPayoutsAdmin
		self.AdminPrivatePath = /private/TFCPayoutsPrivate
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
