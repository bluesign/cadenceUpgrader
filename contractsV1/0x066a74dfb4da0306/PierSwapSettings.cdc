import MultiFungibleToken from "../0xa378eeb799df8387/MultiFungibleToken.cdc"

import PierLPToken from "../0x609e10301860b683/PierLPToken.cdc"

/**

PierSwapSettings provides an Admin resource to control
some behaviors in PierPair and PierSwapFactory contracts.

@author Metapier Foundation Ltd.

 */

access(all)
contract PierSwapSettings{ 
	
	// Event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Event that is emitted when the trading fees have been updated
	access(all)
	event SwapFeesUpdated(poolTotalFee: UFix64, poolProtocolFee: UFix64)
	
	// Event that is emitted when the protocol fee recipient has been updated
	access(all)
	event ProtocolFeeRecipientUpdated(newAddress: Address)
	
	// DEPRECATED: Event that is emitted when the information for oracles is turned on/off
	access(all)
	event ObservationSwitchUpdated(enabled: Bool)
	
	// The fraction of the swap input to collect as the total trading fee
	access(all)
	var poolTotalFee: UFix64
	
	// The fraction of the swap input to collect as protocol fee (part of `poolTotalFee`)
	access(all)
	var poolProtocolFee: UFix64
	
	// The address to receive LP tokens as protocol fee
	access(all)
	var protocolFeeRecipient: Address
	
	// Admin resource provides functions for tuning fields
	// in this contract.
	access(all)
	resource Admin{ 
		
		// Updates `poolTotalFee` and `poolProtocolFee`
		// Always update both values to avoid bad configuration by mistakes
		access(all)
		fun setFees(newTotalFee: UFix64, newProtocolFee: UFix64){ 
			pre{ 
				newTotalFee <= 0.01:
					"Metapier PierSwapSettings: Total fee can't exceed 1%"
				newProtocolFee < newTotalFee:
					"Metapier PierSwapSettings: Protocol fee can't exceed total fee"
			}
			post{ 
				PierSwapSettings.getPoolTotalFeeCoefficient() % 1.0 == 0.0:
					"Metapier PierSwapSettings: Total fee doesn't support 4 or more decimals"
				newProtocolFee == 0.0 || PierSwapSettings.getPoolProtocolFeeCoefficient() % 1.0 == 0.0:
					"Metapier PierSwapSettings: Protocol fee should be zero or its coefficient should be an integer"
			}
			PierSwapSettings.poolTotalFee = newTotalFee
			PierSwapSettings.poolProtocolFee = newProtocolFee
			emit SwapFeesUpdated(poolTotalFee: newTotalFee, poolProtocolFee: newProtocolFee)
		}
		
		// Updates `protocolFeeRecipient`
		access(all)
		fun setProtocolFeeRecipient(newAddress: Address){ 
			pre{ 
				getAccount(newAddress).capabilities.get<&PierLPToken.Collection>(PierLPToken.CollectionPublicPath).check():
					"Metapier PierSwapSettings: Cannot find LP token collection in new protocol fee recipient"
			}
			PierSwapSettings.protocolFeeRecipient = newAddress
			emit ProtocolFeeRecipientUpdated(newAddress: newAddress)
		}
	}
	
	// Used in PierPair to calculate total fee
	access(all)
	view fun getPoolTotalFeeCoefficient(): UFix64{ 
		return self.poolTotalFee * 1_000.0
	}
	
	// Used in PierPair to calculate protocol fee
	access(all)
	view fun getPoolProtocolFeeCoefficient(): UFix64{ 
		return self.poolTotalFee / self.poolProtocolFee - 1.0
	}
	
	// Used in PierPair to deposit minted LP tokens as protocol fee
	access(all)
	fun depositProtocolFee(vault: @{MultiFungibleToken.Vault}){ 
		let feeCollectionRef =
			getAccount(self.protocolFeeRecipient).capabilities.get<&PierLPToken.Collection>(
				PierLPToken.CollectionPublicPath
			).borrow()
			?? panic("Metapier PierSwapSettings: Protocol fee receiver not found")
		feeCollectionRef.deposit(from: <-vault)
	}
	
	init(){ 
		self.poolTotalFee = 0.003 // The initial total fee is 0.3%
		
		self.poolProtocolFee = 0.0005 // The initial protocol fee is 0.05%
		
		self.protocolFeeRecipient = self.account.address // The default recipient is current account
		
		
		// create and store admin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: /storage/metapierSwapSettingsAdmin)
		
		// LP token collection setup
		self.account.storage.save(
			<-PierLPToken.createEmptyCollection(),
			to: PierLPToken.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&PierLPToken.Collection>(
				PierLPToken.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: PierLPToken.CollectionPublicPath)
		emit ContractInitialized()
	}
}
