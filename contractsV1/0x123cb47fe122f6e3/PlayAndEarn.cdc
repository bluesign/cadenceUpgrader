import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyToken from "./MoxyToken.cdc"

access(all)
contract PlayAndEarn{ 
	access(all)
	event PlayAndEarnEventCreated(eventCode: String, feeCost: UFix64)
	
	access(all)
	event PlayAndEarnEventParticipantAdded(
		eventCode: String,
		addressAdded: Address,
		feePaid: UFix64
	)
	
	access(all)
	event PlayAndEarnEventPaymentToAddress(eventCode: String, receiver: Address, amount: UFix64)
	
	access(all)
	event PlayAndEarnEventTokensDeposited(eventCode: String, amount: UFix64)
	
	access(all)
	resource PlayAndEarnEcosystem: PlayAndEarnEcosystemInfoInterface{ 
		access(contract)
		var events: @{String: PlayAndEarnEvent}
		
		access(all)
		fun getMOXYBalanceFor(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getMOXYBalance()!
		}
		
		access(all)
		fun getFeeAmountFor(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getFeeAmount()!
		}
		
		access(all)
		fun getParticipantsFor(eventCode: String): [Address]{ 
			return self.events[eventCode]?.getParticipants()!
		}
		
		access(all)
		fun getPaymentsFor(eventCode: String):{ Address: UFix64}{ 
			return self.events[eventCode]?.getPayments()!
		}
		
		access(all)
		fun getCreatedAt(eventCode: String): UFix64{ 
			return self.events[eventCode]?.getCreatedAt()!
		}
		
		access(all)
		fun getAllEvents(): [String]{ 
			return self.events.keys
		}
		
		access(all)
		fun addParticipantTo(eventCode: String, address: Address, feeVault: @{FungibleToken.Vault}){ 
			self.events[eventCode]?.addParticipant(address: address, feeVault: <-feeVault.withdraw(amount: feeVault.balance))
			destroy feeVault
		}
		
		access(all)
		fun depositTo(eventCode: String, vault: @{FungibleToken.Vault}){ 
			self.events[eventCode]?.deposit(vault: <-vault.withdraw(amount: vault.balance))
			destroy vault
		}
		
		access(all)
		fun payToAddressFor(eventCode: String, address: Address, amount: UFix64){ 
			self.events[eventCode]?.payToAddress(address: address, amount: amount)
		}
		
		access(all)
		fun addEvent(code: String, feeAmount: UFix64){ 
			if self.events[code] != nil{ 
				panic("Event already exists")
			}
			self.events[code] <-! create PlayAndEarnEvent(code: code, fee: feeAmount)
			emit PlayAndEarnEventCreated(eventCode: code, feeCost: feeAmount)
		}
		
		init(){ 
			self.events <-{} 
		}
	}
	
	access(all)
	resource PlayAndEarnEvent{ 
		access(all)
		var code: String
		
		access(all)
		var fee: UFix64
		
		access(all)
		var vault: @{FungibleToken.Vault}
		
		access(contract)
		var participants:{ Address: UFix64}
		
		access(contract)
		var payments:{ Address: UFix64}
		
		access(all)
		var createdAt: UFix64
		
		access(all)
		fun getFeeAmount(): UFix64{ 
			return self.fee
		}
		
		access(all)
		fun getMOXYBalance(): UFix64{ 
			return self.vault.balance
		}
		
		access(all)
		fun getParticipants(): [Address]{ 
			return self.participants.keys
		}
		
		access(all)
		fun getPayments():{ Address: UFix64}{ 
			return self.payments
		}
		
		access(all)
		fun getCreatedAt(): UFix64{ 
			return self.createdAt
		}
		
		access(all)
		fun hasParticipant(address: Address): Bool{ 
			return self.participants[address] != nil
		}
		
		access(all)
		fun addParticipant(address: Address, feeVault: @{FungibleToken.Vault}){ 
			let feePaid = feeVault.balance
			self.participants[address] = feePaid
			self.vault.deposit(from: <-feeVault)
			emit PlayAndEarnEventParticipantAdded(
				eventCode: self.code,
				addressAdded: address,
				feePaid: feePaid
			)
		}
		
		access(all)
		fun deposit(vault: @{FungibleToken.Vault}){ 
			let amount = vault.balance
			self.vault.deposit(from: <-vault)
			emit PlayAndEarnEventTokensDeposited(eventCode: self.code, amount: amount)
		}
		
		access(all)
		fun payToAddress(address: Address, amount: UFix64){ 
			// Get the amount from the event vault
			let vault <- self.vault.withdraw(amount: amount)
			
			// Get the recipient's public account object
			let recipient = getAccount(address)
			
			// Get a reference to the recipient's Receiver
			let receiverRef =
				recipient.capabilities.get<&{FungibleToken.Receiver}>(
					MoxyToken.moxyTokenReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic("Could not borrow receiver reference to the recipient's Vault")
			
			// Deposit the withdrawn tokens in the recipient's receiver
			receiverRef.deposit(from: <-vault)
			
			// Register address as payment recipient
			if self.payments[address] == nil{ 
				self.payments[address] = amount
			} else{ 
				self.payments[address] = self.payments[address]! + amount
			}
			emit PlayAndEarnEventPaymentToAddress(
				eventCode: self.code,
				receiver: address,
				amount: amount
			)
		}
		
		init(code: String, fee: UFix64){ 
			self.code = code
			self.fee = fee
			self.vault <- MoxyToken.createEmptyVault(vaultType: Type<@MoxyToken.Vault>())
			self.participants ={} 
			self.payments ={} 
			self.createdAt = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	fun getPlayAndEarnEcosystemPublicCapability(): &PlayAndEarnEcosystem{ 
		return self.account.capabilities.get<&PlayAndEarn.PlayAndEarnEcosystem>(
			PlayAndEarn.playAndEarnEcosystemPublic
		).borrow<&PlayAndEarn.PlayAndEarnEcosystem>()!
	}
	
	access(all)
	resource interface PlayAndEarnEcosystemInfoInterface{ 
		access(all)
		fun getMOXYBalanceFor(eventCode: String): UFix64
		
		access(all)
		fun getFeeAmountFor(eventCode: String): UFix64
		
		access(all)
		fun getParticipantsFor(eventCode: String): [Address]
		
		access(all)
		fun getPaymentsFor(eventCode: String):{ Address: UFix64}
		
		access(all)
		fun getCreatedAt(eventCode: String): UFix64
		
		access(all)
		fun getAllEvents(): [String]
		
		access(all)
		fun depositTo(eventCode: String, vault: @{FungibleToken.Vault})
	}
	
	access(all)
	let playAndEarnEcosystemStorage: StoragePath
	
	access(all)
	let playAndEarnEcosystemPrivate: PrivatePath
	
	access(all)
	let playAndEarnEcosystemPublic: PublicPath
	
	init(){ 
		self.playAndEarnEcosystemStorage = /storage/playAndEarnEcosystem
		self.playAndEarnEcosystemPrivate = /private/playAndEarnEcosystem
		self.playAndEarnEcosystemPublic = /public/playAndEarnEcosystem
		let playAndEarnEcosystem <- create PlayAndEarnEcosystem()
		self.account.storage.save(<-playAndEarnEcosystem, to: self.playAndEarnEcosystemStorage)
		var capability_1 =
			self.account.capabilities.storage.issue<&PlayAndEarnEcosystem>(
				self.playAndEarnEcosystemStorage
			)
		self.account.capabilities.publish(capability_1, at: self.playAndEarnEcosystemPrivate)
		var capability_2 =
			self.account.capabilities.storage.issue<&PlayAndEarnEcosystem>(
				self.playAndEarnEcosystemStorage
			)
		self.account.capabilities.publish(capability_2, at: self.playAndEarnEcosystemPublic)
	}
}
