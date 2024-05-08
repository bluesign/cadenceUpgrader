import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract SendTokenMessage{ 
	access(all)
	event Delivered(tokenType: Type, amount: UFix64, to: Address, message: String?)
	
	access(all)
	fun deliver(
		vault: @{FungibleToken.Vault},
		receiverPath: PublicPath,
		receiver: Address,
		message: String?
	){ 
		emit Delivered(
			tokenType: vault.getType(),
			amount: vault.balance,
			to: receiver,
			message: message
		)
		let receiverVault =
			getAccount(receiver).capabilities.get<&{FungibleToken.Receiver}>(receiverPath).borrow<
				&{FungibleToken.Receiver}
			>()
			?? panic("Receiver does not have a vault set up to accept this delivery.")
		receiverVault.deposit(from: <-vault)
	}
}
