import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import SpaceTradeAssetCatalog from "./SpaceTradeAssetCatalog.cdc"

access(all)
contract SpaceTradeFeeManager{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let SpaceTradeManagerStoragePath: StoragePath
	
	access(all)
	let SpaceTradeManagerPrivatePath: PrivatePath
	
	access(all)
	var fee: Fee?
	
	// We can have multiple receivers that has their each cut percentage specified
	access(all)
	struct FeeCut{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cutPercentage: UFix64
		
		init(receiver: Capability<&{FungibleToken.Receiver}>, cutPercentage: UFix64){ 
			self.receiver = receiver
			self.cutPercentage = cutPercentage
		}
	}
	
	access(all)
	struct Fee{ 
		access(all)
		let tokenName: String
		
		access(all)
		let vaultType: Type
		
		access(all)
		let tokenAmount: UFix64
		
		access(all)
		let feeCuts: [FeeCut]
		
		init(tokenName: String, vaultType: Type, tokenAmount: UFix64, feeCuts: [FeeCut]){ 
			pre{ 
				SpaceTradeAssetCatalog.isSupportedFT(tokenName):
					"Unsupported fungible token specified for fees"
			}
			self.tokenName = tokenName
			self.vaultType = vaultType
			self.tokenAmount = tokenAmount
			self.feeCuts = feeCuts
		}
		
		access(all)
		fun deposit(payment: @{FungibleToken.Vault}){ 
			pre{ 
				payment.isInstance(self.vaultType):
					"Unable to transfer fee with unknown token type"
			}
			let availableReceivers: [&{FungibleToken.Receiver}] = []
			let initialBalance = payment.balance
			for feeCut in self.feeCuts{ 
				// Rather than aborting the transaction if any receiver is absent when we try to pay it to available receivers with their specified cuts
				if let receiver = feeCut.receiver.borrow(){ 
					let cut <- payment.withdraw(amount: initialBalance * feeCut.cutPercentage)
					receiver.deposit(from: <-cut)
					availableReceivers.append(receiver)
				}
			}
			if payment.balance > 0.0{ 
				// Equally distribute to available receivers
				let restBalance = payment.balance
				for availableReceiver in availableReceivers{ 
					let cut <- payment.withdraw(amount: restBalance * (1.0 / UFix64(availableReceivers.length)))
					availableReceiver.deposit(from: <-cut)
				}
			}
			
			// noop normally, but ensure that we have deposited everything!
			availableReceivers[0].deposit(from: <-payment)
		}
	}
	
	access(all)
	resource Manager{ 
		access(all)
		fun updateFee(_ fee: SpaceTradeFeeManager.Fee?){ 
			SpaceTradeFeeManager.fee = fee
		}
	}
	
	init(){ 
		self.SpaceTradeManagerStoragePath = /storage/SpaceTradeFreeManager
		self.SpaceTradeManagerPrivatePath = /private/SpaceTradeFreeManager
		
		// Create a manager and store it to contract account
		self.account.storage.save(<-create Manager(), to: self.SpaceTradeManagerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Manager>(self.SpaceTradeManagerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.SpaceTradeManagerPrivatePath)
		
		// Fee details, nil means that this contract is free to use, manager can use SpaceTradeFreeManager to override this
		self.fee = nil
		emit ContractInitialized()
	}
}
