import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowStorageFees from "../0xe467b9dd11fa00df/FlowStorageFees.cdc"

access(all)
contract FlowTokenManager{ 
	access(all)
	fun TopUpFlowTokens(account: &Account, flowTokenProvider: &{FungibleToken.Provider}){ 
		if account.storage.used > account.storage.capacity{ 
			var extraStorageRequiredBytes = account.storage.used - account.storage.capacity
			var extraStorageRequiredMb = FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(extraStorageRequiredBytes)
			var flowRequired = FlowStorageFees.storageCapacityToFlow(extraStorageRequiredMb)
			let vault: @{FungibleToken.Vault} <- flowTokenProvider.withdraw(amount: flowRequired)
			((account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!).borrow()!).deposit(from: <-vault)
		}
	}
}
