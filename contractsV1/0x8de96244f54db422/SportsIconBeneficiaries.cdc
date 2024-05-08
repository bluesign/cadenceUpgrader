import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract SportsIconBeneficiaries{ 
	access(all)
	event BeneficiaryPaid(ids: [UInt64], amount: UFix64, to: Address)
	
	access(all)
	event BeneficiaryPaymentFailed(ids: [UInt64], amount: UFix64, to: Address)
	
	// Maps setID to beneficiary object
	// Allows for simple retrieval within the account of what cuts should be taken
	access(account)
	let mintBeneficiaries:{ UInt64: Beneficiaries}
	
	access(account)
	let marketBeneficiaries:{ UInt64: Beneficiaries}
	
	access(all)
	struct Beneficiary{ 
		// Cuts are in decimal form, .10 = 10%
		access(self)
		let cut: UFix64
		
		// Wallet that receives funds
		access(self)
		let fusdWallet: Capability<&FUSD.Vault>
		
		access(self)
		let flowWallet: Capability<&FlowToken.Vault>
		
		init(
			cut: UFix64,
			fusdWallet: Capability<&FUSD.Vault>,
			flowWallet: Capability<&FlowToken.Vault>
		){ 
			self.cut = cut
			self.fusdWallet = fusdWallet
			self.flowWallet = flowWallet
		}
		
		access(all)
		fun getCut(): UFix64{ 
			return self.cut
		}
		
		access(all)
		fun getFUSDWallet(): Capability<&{FungibleToken.Receiver}>{ 
			return self.fusdWallet
		}
		
		access(all)
		fun getFLOWWallet(): Capability<&{FungibleToken.Receiver}>{ 
			return self.flowWallet
		}
	}
	
	access(all)
	struct Beneficiaries{ 
		access(self)
		let beneficiaries: [Beneficiary]
		
		init(beneficiaries: [Beneficiary]){ 
			self.beneficiaries = beneficiaries
		}
		
		access(all)
		fun payOut(
			paymentReceiver: Capability<&{FungibleToken.Receiver}>?,
			payment: @{FungibleToken.Vault},
			tokenIDs: [
				UInt64
			]
		){ 
			let total = UFix64(payment.balance)
			let isPaymentFUSD = payment.isInstance(Type<@FUSD.Vault>())
			let isPaymentFlow = payment.isInstance(Type<@FlowToken.Vault>())
			if !isPaymentFUSD && !isPaymentFlow{ 
				panic("Received unsupported FT type for payment.")
			}
			for beneficiary in self.beneficiaries{ 
				var vaultCap: Capability<&{FungibleToken.Receiver}>? = nil
				if isPaymentFUSD{ 
					vaultCap = beneficiary.getFUSDWallet()
				} else{ 
					vaultCap = beneficiary.getFLOWWallet()
				}
				let vaultRef = (vaultCap!).borrow()!
				//let vaultRef = beneficiary.getFUSDWallet().borrow()
				if vaultRef != nil{ 
					let amount = total * beneficiary.getCut()
					let tempWallet <- payment.withdraw(amount: amount)
					(vaultRef!).deposit(from: <-tempWallet)
					emit BeneficiaryPaid(ids: tokenIDs, amount: amount, to: (vaultCap!).address)
				}
			}
			if payment.balance > 0.0{ 
				let amount = payment.balance
				let tempWallet <- payment.withdraw(amount: amount)
				let receiverVault = (paymentReceiver!).borrow()
				if receiverVault != nil{ 
					(					 // If we were able to retrieve the proper receiver of this sale, send it to them.
					 receiverVault!).deposit(from: <-tempWallet)
					emit BeneficiaryPaid(ids: tokenIDs, amount: amount, to: (paymentReceiver!).address)
				} else{ 
					// If we failed to retrieve the proper receiver of the sale, send it to the
					// SportsIcon admin account
					if isPaymentFUSD{ 
						let adminReceiver = SportsIconBeneficiaries.getAdminFUSDVault().borrow()!
						adminReceiver.deposit(from: <-tempWallet)
					} else{ 
						let adminReceiver = SportsIconBeneficiaries.getAdminFLOWVault().borrow()!
						adminReceiver.deposit(from: <-tempWallet)
					}
					emit BeneficiaryPaymentFailed(ids: tokenIDs, amount: amount, to: (paymentReceiver!).address)
				}
			}
			destroy payment
		}
		
		access(all)
		fun getBeneficiaries(): [Beneficiary]{ 
			return self.beneficiaries
		}
	}
	
	access(all)
	fun getAdminFUSDVault(): Capability<&FUSD.Vault>{ 
		return self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
	}
	
	access(all)
	fun getAdminFLOWVault(): Capability<&FlowToken.Vault>{ 
		return self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!
	}
	
	access(account)
	fun setMintBeneficiaries(setID: UInt64, beneficiaries: Beneficiaries){ 
		self.mintBeneficiaries[setID] = beneficiaries
	}
	
	access(account)
	fun setMarketBeneficiaries(setID: UInt64, beneficiaries: Beneficiaries){ 
		self.marketBeneficiaries[setID] = beneficiaries
	}
	
	init(){ 
		self.mintBeneficiaries ={} 
		self.marketBeneficiaries ={} 
	}
}
