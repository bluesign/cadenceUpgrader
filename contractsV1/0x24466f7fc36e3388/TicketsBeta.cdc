import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TicketsBeta{ 
	// Events
	access(all)
	event DispenserRequested(dispenser_id: UInt32, address: Address)
	
	access(all)
	event DispenserGranted(dispenser_id: UInt32, address: Address)
	
	access(all)
	event TicketRequested(dispenser_id: UInt32, user_id: UInt32, address: Address)
	
	access(all)
	event TicketUsed(
		dispenser_id: UInt32,
		user_id: UInt32,
		token_id: UInt64,
		address: Address,
		price: UFix64
	)
	
	access(all)
	event CrowdFunding(dispenser_id: UInt32, user_id: UInt32, address: Address, fund: UFix64)
	
	access(all)
	event Refund(dispenser_id: UInt32, user_id: UInt32, address: Address, amount: UFix64)
	
	// Paths
	access(all)
	let AdminPublicStoragePath: StoragePath
	
	access(all)
	let AdminPrivateStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	let CapabilityReceiverVaultPublicPath: PublicPath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	let DispenserVaultPublicPath: PublicPath
	
	access(all)
	let DispenserVaultPrivatePath: PrivatePath
	
	access(all)
	let TicketVaultPublicPath: PublicPath
	
	access(all)
	let TicketVaultPrivatePath: PrivatePath
	
	// Variants
	access(self)
	var totalDispenserVaultSupply: UInt32
	
	access(self)
	var totalTicketSupply: UInt64
	
	access(self)
	var totalTicketVaultSupply: UInt32
	
	access(self)
	var adminCapabilityHolder: Bool
	
	access(all)
	let FlowTokenVault: Capability<&FlowToken.Vault>
	
	access(all)
	let DispenserFlowTokenVault:{ UInt32: Capability<&FlowToken.Vault>}
	
	access(all)
	let UserFlowTokenVault:{ UInt32: Capability<&FlowToken.Vault>}
	
	// Objects
	access(self)
	let dispenserOwners:{ UInt32: DispenserStruct}
	
	access(self)
	let ticketInfo: [TicketStruct]
	
	access(self)
	let ticketRequesters:{ UInt32:{ UInt32: RequestStruct}}
	
	/*
	  ** [Struct]DispenserStruct
	  */
	
	access(all)
	struct DispenserStruct{ 
		access(contract)
		let dispenser_id: UInt32
		
		access(contract)
		let address: Address
		
		access(contract)
		let domain: String
		
		access(self)
		let description: String
		
		access(self)
		let paid: UFix64
		
		access(all)
		var grant: Bool
		
		init(
			dispenser_id: UInt32,
			address: Address,
			domain: String,
			description: String,
			paid: UFix64,
			grant: Bool
		){ 
			self.address = address
			self.dispenser_id = dispenser_id
			self.domain = domain
			self.description = description
			self.paid = paid
			self.grant = grant
		}
	}
	
	/*
	  ** [Struct]　TicketStruct
	  */
	
	access(all)
	struct TicketStruct{ 
		access(contract)
		let dispenser_id: UInt32
		
		access(self)
		let domain: String
		
		access(self)
		let type: UInt8
		
		access(self)
		let name: String
		
		access(self)
		let where_to_use: String
		
		access(self)
		let when_to_use: String
		
		access(self)
		let price: UFix64
		
		init(
			dispenser_id: UInt32,
			domain: String,
			type: UInt8,
			name: String,
			where_to_use: String,
			when_to_use: String,
			price: UFix64
		){ 
			self.dispenser_id = dispenser_id
			self.domain = domain
			self.type = type
			self.name = name
			self.where_to_use = where_to_use
			self.when_to_use = when_to_use
			self.price = price
		}
	}
	
	/*
	  ** [Struct] RequestStruct
	  */
	
	access(all)
	struct RequestStruct{ 
		access(all)
		let user_id: UInt32
		
		access(all)
		let address: Address
		
		access(all)
		var latest_token: UInt64?
		
		access(all)
		var time: UFix64 // Time
		
		
		access(all)
		var count: UInt8
		
		access(all)
		var paid: UFix64
		
		access(all)
		let crowdfunding: Bool
		
		init(time: UFix64, user_id: UInt32, address: Address, crowdfunding: Bool){ 
			self.user_id = user_id
			self.address = address
			self.latest_token = nil
			self.time = time
			self.count = 1
			self.paid = 0.0
			self.crowdfunding = crowdfunding
		}
	}
	
	/*
	  ** [Resource] Admin
	  */
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintDispenser(dispenser_id: UInt32, address: Address): @Dispenser{ 
			pre{ 
				TicketsBeta.dispenserOwners[dispenser_id] != nil:
					"Requested address is not in previously requested list."
				(TicketsBeta.dispenserOwners[dispenser_id]!).grant == false:
					"Requested address is already minted."
			}
			if let data = TicketsBeta.dispenserOwners[dispenser_id]{ 
				data.grant = true
				TicketsBeta.dispenserOwners[dispenser_id] = data
			}
			emit DispenserGranted(dispenser_id: dispenser_id, address: address)
			return <-create Dispenser()
		}
		
		init(){} 
	}
	
	/*
	  ** [Resource] AdminPublic
	  */
	
	access(all)
	resource AdminPublic{ 
		// [public access]
		access(all)
		fun getDispenserRequesters(): [DispenserStruct]{ 
			var dispenserArr: [DispenserStruct] = []
			for data in TicketsBeta.dispenserOwners.values{ 
				if data.grant == false{ 
					dispenserArr.append(data)
				}
			}
			return dispenserArr
		}
		
		// [public access]
		access(all)
		fun getAllDispensers(): [DispenserStruct]{ 
			var dispenserArr: [DispenserStruct] = []
			for data in TicketsBeta.dispenserOwners.values{ 
				dispenserArr.append(data)
			}
			return dispenserArr
		}
		
		init(){} 
		
		// [public access]
		access(all)
		fun getTicketRequesters(dispenser_id: UInt32):{ UInt32: RequestStruct}?{ 
			return TicketsBeta.ticketRequesters[dispenser_id]
		}
	}
	
	/*
	  ** [Interface] IDispenserPublic
	  */
	
	access(all)
	resource interface IProxyCapabilityReceiverPublic{ 
		access(all)
		fun deposit(cap: Capability<&Admin>)
	}
	
	/*
	  ** [Resource] CapabilityReceiverVault
	  */
	
	access(all)
	resource CapabilityReceiverVault: IProxyCapabilityReceiverPublic{ 
		
		// [private access]
		access(all)
		var proxyCapabilityReceiver: Capability<&Admin>?
		
		// [public access]
		access(all)
		fun deposit(cap: Capability<&Admin>){ 
			pre{ 
				TicketsBeta.adminCapabilityHolder == false:
					"Admin capability vault is already assigned."
			}
			if self.proxyCapabilityReceiver == nil{ 
				self.proxyCapabilityReceiver = cap
				TicketsBeta.adminCapabilityHolder = true
			}
		}
		
		init(){ 
			self.proxyCapabilityReceiver = nil
		}
	}
	
	/*
	  ** [create vault] createCapabilityReceiverVault
	  */
	
	access(all)
	fun createCapabilityReceiverVault(): @CapabilityReceiverVault{ 
		return <-create CapabilityReceiverVault()
	}
	
	/*
	  ** [Resource] Dispenser
	  */
	
	access(all)
	resource Dispenser{ 
		access(self)
		var last_token_id: UInt64
		
		access(all)
		fun getLatestMintedTokenId(): UInt64{ 
			return self.last_token_id
		}
		
		access(all)
		fun mintTicket(secret_code: String, dispenser_id: UInt32, user_id: UInt32): @Ticket{ 
			let token <- create Ticket(secret_code: secret_code, dispenser_id: dispenser_id)
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]{ 
					let ref = &(TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]! as &RequestStruct
					ref.latest_token = token.getId()
					self.last_token_id = token.getId()
				}
			}
			return <-token
		}
		
		access(all)
		fun addTicketInfo(
			dispenser_id: UInt32,
			type: UInt8,
			name: String,
			where_to_use: String,
			when_to_use: String,
			price: UFix64,
			flow_vault_receiver: Capability<&FlowToken.Vault>
		){ 
			let domain = (TicketsBeta.dispenserOwners[dispenser_id]!).domain
			let ticket =
				TicketStruct(
					dispenser_id: dispenser_id,
					domain: domain,
					type: type,
					name: name,
					where_to_use: where_to_use,
					when_to_use: when_to_use,
					price: price
				)
			TicketsBeta.ticketInfo.append(ticket)
			if TicketsBeta.DispenserFlowTokenVault[dispenser_id] == nil{ 
				TicketsBeta.DispenserFlowTokenVault[dispenser_id] = flow_vault_receiver
			}
		}
		
		access(all)
		fun updateTicketInfo(
			index: UInt32,
			dispenser_id: UInt32,
			type: UInt8,
			name: String,
			where_to_use: String,
			when_to_use: String,
			price: UFix64
		){ 
			let domain = (TicketsBeta.dispenserOwners[dispenser_id]!).domain
			let ticket =
				TicketStruct(
					dispenser_id: dispenser_id,
					domain: domain,
					type: type,
					name: name,
					where_to_use: where_to_use,
					when_to_use: when_to_use,
					price: price
				)
			let existTicket = TicketsBeta.ticketInfo.remove(at: index)
			if existTicket.dispenser_id == dispenser_id{ 
				TicketsBeta.ticketInfo.insert(at: index, ticket)
			} else{ 
				panic("Something is not going right.")
			}
		}
		
		init(){ 
			self.last_token_id = 0
		}
	}
	
	/*
	  ** [Interface] IDispenserPrivate
	  */
	
	access(all)
	resource interface IDispenserPrivate{ 
		access(all)
		var ownedDispenser: @Dispenser?
		
		access(all)
		var dispenser_id: UInt32
		
		access(all)
		fun addTicketInfo(
			type: UInt8,
			name: String,
			where_to_use: String,
			when_to_use: String,
			price: UFix64,
			flow_vault_receiver: Capability<&FlowToken.Vault>
		)
		
		access(all)
		fun updateTicketInfo(
			index: UInt32,
			type: UInt8,
			name: String,
			where_to_use: String,
			when_to_use: String,
			price: UFix64
		)
	}
	
	/*
	  ** [Interface] IDispenserPublic
	  */
	
	access(all)
	resource interface IDispenserPublic{ 
		access(all)
		fun deposit(minter: @Dispenser)
		
		access(all)
		fun hasDispenser(): Bool
		
		access(all)
		view fun getId(): UInt32
		
		access(all)
		fun getTicketRequesters():{ UInt32: RequestStruct}?
		
		access(all)
		fun getLatestMintedTokenId(): UInt64?
	}
	
	/*
	  ** [Resource] DispenserVault
	  */
	
	access(all)
	resource DispenserVault: IDispenserPrivate, IDispenserPublic{ 
		
		// [private access]
		access(all)
		var ownedDispenser: @Dispenser?
		
		// [private access]
		access(all)
		var dispenser_id: UInt32
		
		// [public access]
		access(all)
		fun deposit(minter: @Dispenser){ 
			if self.ownedDispenser == nil{ 
				self.ownedDispenser <-! minter
			} else{ 
				destroy minter
			}
		}
		
		// [public access]
		access(all)
		fun hasDispenser(): Bool{ 
			if self.ownedDispenser != nil{ 
				return true
			} else{ 
				return false
			}
		}
		
		// [public access]
		access(all)
		view fun getId(): UInt32{ 
			return self.dispenser_id
		}
		
		// [public access]
		access(all)
		fun getTicketRequesters():{ UInt32: RequestStruct}?{ 
			return TicketsBeta.ticketRequesters[self.dispenser_id]
		}
		
		// [public access]
		access(all)
		fun getLatestMintedTokenId(): UInt64?{ 
			return self.ownedDispenser?.getLatestMintedTokenId()
		}
		
		// [private access]
		access(all)
		fun addTicketInfo(type: UInt8, name: String, where_to_use: String, when_to_use: String, price: UFix64, flow_vault_receiver: Capability<&FlowToken.Vault>){ 
			self.ownedDispenser?.addTicketInfo(dispenser_id: self.dispenser_id, type: type, name: name, where_to_use: where_to_use, when_to_use: when_to_use, price: price, flow_vault_receiver: flow_vault_receiver)
		}
		
		// [private access]
		access(all)
		fun updateTicketInfo(index: UInt32, type: UInt8, name: String, where_to_use: String, when_to_use: String, price: UFix64){ 
			self.ownedDispenser?.updateTicketInfo(index: index, dispenser_id: self.dispenser_id, type: type, name: name, where_to_use: where_to_use, when_to_use: when_to_use, price: price)
		}
		
		// [private access]
		access(all)
		fun mintTicket(secret_code: String, user_id: UInt32): @Ticket?{ 
			return <-self.ownedDispenser?.mintTicket(secret_code: secret_code, dispenser_id: self.dispenser_id, user_id: user_id)
		}
		
		// [private access]
		access(all)
		fun refund(dispenser_id: UInt32, address: Address, user_id: UInt32, repayment: @FlowToken.Vault){ 
			pre{ 
				repayment.balance > 0.0:
					"refund is not set."
				TicketsBeta.UserFlowTokenVault[user_id] != nil:
					"The beneficiary has not yet set up the Vault."
				TicketsBeta.ticketRequesters.containsKey(dispenser_id):
					"Sender has not right to refund."
				(TicketsBeta.ticketRequesters[dispenser_id]!).containsKey(user_id):
					"Sender has not right to refund."
				((TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]!).paid >= repayment.balance:
					"refund is larger than paid amount."
			}
			let fund: UFix64 = repayment.balance
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]{ 
					let ref = &(TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]! as &RequestStruct
					ref.paid = data.paid - fund // refund
				
				}
			}
			((TicketsBeta.UserFlowTokenVault[user_id]!).borrow()!).deposit(from: <-repayment)
			emit Refund(dispenser_id: dispenser_id, user_id: user_id, address: address, amount: fund)
		}
		
		init(_ address: Address, _ domain: String, _ description: String, _ paid: UFix64){ 
			// TotalSupply
			self.dispenser_id = TicketsBeta.totalDispenserVaultSupply + 1
			TicketsBeta.totalDispenserVaultSupply = TicketsBeta.totalDispenserVaultSupply + 1
			
			// Event, Data
			emit DispenserRequested(dispenser_id: self.dispenser_id, address: address)
			self.ownedDispenser <- nil
			TicketsBeta.dispenserOwners[self.dispenser_id] = DispenserStruct(dispenser_id: self.dispenser_id, address: address, domain: domain, description: description, paid: paid, grant: false)
		}
	}
	
	/*
	  ** [create vault] createDispenserVault
	  */
	
	access(all)
	fun createDispenserVault(
		address: Address,
		domain: String,
		description: String,
		payment: @FlowToken.Vault
	): @DispenserVault{ 
		pre{ 
			payment.balance >= 0.3:
				"Payment is not sufficient"
		}
		let paid: UFix64 = payment.balance
		(TicketsBeta.FlowTokenVault.borrow()!).deposit(from: <-payment)
		return <-create DispenserVault(address, domain, description, paid)
	}
	
	/*
	  ** [Resource] Ticket
	  */
	
	access(all)
	resource Ticket{ 
		access(self)
		let token_id: UInt64
		
		access(self)
		let dispenser_id: UInt32
		
		access(self)
		let secret_code: String
		
		access(self)
		var readable_code: String
		
		access(self)
		var price: UFix64
		
		access(self)
		var used_time: UFix64?
		
		access(self)
		var created_time: UFix64
		
		access(all)
		view fun getId(): UInt64{ 
			return self.token_id
		}
		
		access(all)
		fun getCode(): String{ 
			return self.readable_code
		}
		
		access(all)
		fun getUsedTime(): UFix64?{ 
			return self.used_time
		}
		
		access(all)
		fun getCreatedTime(): UFix64{ 
			return self.created_time
		}
		
		access(all)
		fun useTicket(price: UFix64){ 
			pre{ 
				self.readable_code == "":
					"Something went wrong."
			}
			self.readable_code = self.secret_code
			self.price = price
			self.used_time = getCurrentBlock().timestamp
		}
		
		access(all)
		fun useCrowdfundingTicket(){ 
			pre{ 
				self.readable_code == "":
					"Something went wrong."
			}
			self.readable_code = self.secret_code
			self.used_time = getCurrentBlock().timestamp
		}
		
		init(secret_code: String, dispenser_id: UInt32){ 
			// TotalSupply
			self.token_id = TicketsBeta.totalTicketSupply + 1
			TicketsBeta.totalTicketSupply = TicketsBeta.totalTicketSupply + 1
			
			// Event, Data
			self.dispenser_id = dispenser_id
			self.secret_code = secret_code // チケット名称
			
			self.readable_code = "" // チケット枚数
			
			self.price = 0.0
			self.used_time = nil
			self.created_time = getCurrentBlock().timestamp
		}
	}
	
	/*
	  ** [Interface] ITicketPrivate
	  */
	
	access(all)
	resource interface ITicketPrivate{ 
		access(contract)
		var ownedTicket: @{UInt64: Ticket}
		
		access(all)
		fun requestTicket(dispenser_id: UInt32, address: Address)
		
		access(all)
		fun useTicket(
			dispenser_id: UInt32,
			token_id: UInt64,
			address: Address,
			payment: @FlowToken.Vault,
			fee: @FlowToken.Vault
		)
		
		access(all)
		fun prepareCrowdfund(dispenser_id: UInt32, address: Address)
		
		access(all)
		fun crowdfunding(
			dispenser_id: UInt32,
			address: Address,
			payment: @FlowToken.Vault,
			fee: @FlowToken.Vault
		)
	}
	
	/*
	  ** [Interface] ITicketPublic
	  */
	
	access(all)
	resource interface ITicketPublic{ 
		access(all)
		fun deposit(token: @Ticket)
		
		access(all)
		view fun getId(): UInt32
		
		access(all)
		fun getCode(dispenser_id: UInt32):{ UInt64: String}?
		
		access(all)
		fun getUsedTime(dispenser_id: UInt32):{ UInt64: UFix64??}?
		
		access(all)
		fun getCreatedTime(dispenser_id: UInt32):{ UInt64: UFix64?}?
	}
	
	/*
	  ** [Ticket Vault] TicketVault
	  */
	
	access(all)
	resource TicketVault: ITicketPrivate, ITicketPublic{ 
		access(self)
		var user_id: UInt32
		
		access(contract)
		var ownedTicket: @{UInt64: Ticket}
		
		access(contract)
		var contribution: [UInt32]
		
		// [public access]
		access(all)
		fun deposit(token: @Ticket){ 
			pre{ 
				self.ownedTicket[token.getId()] == nil:
					"You have same ticket."
			}
			self.ownedTicket[token.getId()] <-! token
		}
		
		// [public access]
		access(all)
		view fun getId(): UInt32{ 
			return self.user_id
		}
		
		// [public access]
		access(all)
		fun getCode(dispenser_id: UInt32):{ UInt64: String}?{ 
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					if data.latest_token == nil{ 
						return nil
					}
					let token_id = data.latest_token!
					return{ token_id: self.ownedTicket[token_id]?.getCode()!}
				}
			}
			return nil
		}
		
		// [public access]
		access(all)
		fun getUsedTime(dispenser_id: UInt32):{ UInt64: UFix64??}?{ 
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					if data.latest_token == nil{ 
						return nil
					}
					let token_id = data.latest_token!
					return{ token_id: self.ownedTicket[token_id]?.getUsedTime()}
				}
			}
			return nil
		}
		
		// [public access]
		access(all)
		fun getCreatedTime(dispenser_id: UInt32):{ UInt64: UFix64?}?{ 
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					if data.latest_token == nil{ 
						return nil
					}
					let token_id = data.latest_token!
					return{ token_id: self.ownedTicket[token_id]?.getCreatedTime()}
				}
			}
			return nil
		}
		
		// [private access]
		access(all)
		fun requestTicket(dispenser_id: UInt32, address: Address){ 
			let time = getCurrentBlock().timestamp
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					let ref = &(TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]! as &RequestStruct
					ref.count = data.count + 1
					ref.time = time
					ref.latest_token = nil
					emit TicketRequested(dispenser_id: dispenser_id, user_id: self.user_id, address: address)
				} else{ 
					let requestStruct = RequestStruct(time: time, user_id: self.user_id, address: address, crowdfunding: false)
					if let data = TicketsBeta.ticketRequesters[dispenser_id]{ 
						data[self.user_id] = requestStruct
						TicketsBeta.ticketRequesters[dispenser_id] = data
					}
				}
			} else{ 
				let requestStruct = RequestStruct(time: time, user_id: self.user_id, address: address, crowdfunding: false)
				TicketsBeta.ticketRequesters[dispenser_id] ={ self.user_id: requestStruct}
			}
		}
		
		// [private access]
		access(all)
		fun useTicket(dispenser_id: UInt32, token_id: UInt64, address: Address, payment: @FlowToken.Vault, fee: @FlowToken.Vault){ 
			pre{ 
				fee.balance > (fee.balance + payment.balance) * 0.024:
					"fee is less than 2.5%."
				TicketsBeta.DispenserFlowTokenVault[dispenser_id] != nil:
					"Receiver is not set."
				TicketsBeta.ticketRequesters.containsKey(dispenser_id):
					"Ticket is not requested."
				((TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]!).crowdfunding == false:
					"crowdfunding cannot use ticket with fee."
			}
			let price: UFix64 = payment.balance + fee.balance
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					let ref = &(TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]! as &RequestStruct
					ref.paid = data.paid + price
				}
			}
			self.ownedTicket[token_id]?.useTicket(price: price)
			(TicketsBeta.FlowTokenVault.borrow()!).deposit(from: <-fee)
			((TicketsBeta.DispenserFlowTokenVault[dispenser_id]!).borrow()!).deposit(from: <-payment)
			emit TicketUsed(dispenser_id: dispenser_id, user_id: self.user_id, token_id: token_id, address: address, price: price)
		}
		
		// [private access]
		access(all)
		fun prepareCrowdfund(dispenser_id: UInt32, address: Address){ 
			let time = getCurrentBlock().timestamp
			if !TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				let requestStruct = RequestStruct(time: time, user_id: self.user_id, address: address, crowdfunding: true)
				TicketsBeta.ticketRequesters[dispenser_id] ={ self.user_id: requestStruct}
			} else if let data = TicketsBeta.ticketRequesters[dispenser_id]{ 
				if !data.containsKey(self.user_id){ 
					let requestStruct = RequestStruct(time: time, user_id: self.user_id, address: address, crowdfunding: true)
					data[self.user_id] = requestStruct
					TicketsBeta.ticketRequesters[dispenser_id] = data
				}
			}
		}
		
		// [private access]
		access(all)
		fun crowdfunding(dispenser_id: UInt32, address: Address, payment: @FlowToken.Vault, fee: @FlowToken.Vault){ 
			pre{ 
				fee.balance > (fee.balance + payment.balance) * 0.024:
					"fee is less than 2.5%."
				TicketsBeta.DispenserFlowTokenVault[dispenser_id] != nil:
					"Receiver is not set."
				TicketsBeta.ticketRequesters.containsKey(dispenser_id):
					"crowdfunding registration info is not set."
				((TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]!).crowdfunding == true:
					"this ticket requester is not asking crowdfunding."
			}
			let fund: UFix64 = payment.balance + fee.balance
			if TicketsBeta.ticketRequesters.containsKey(dispenser_id){ 
				if let data = (TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]{ 
					let ref = &(TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]! as &RequestStruct
					ref.paid = data.paid + fund
				}
			}
			(TicketsBeta.FlowTokenVault.borrow()!).deposit(from: <-fee)
			((TicketsBeta.DispenserFlowTokenVault[dispenser_id]!).borrow()!).deposit(from: <-payment)
			emit CrowdFunding(dispenser_id: dispenser_id, user_id: self.user_id, address: address, fund: fund)
			self.contribution.append(dispenser_id)
		}
		
		access(all)
		fun setRefundVault(flow_vault_receiver: Capability<&FlowToken.Vault>){ 
			pre{ 
				TicketsBeta.UserFlowTokenVault[self.user_id] == nil:
					"You have already requested a refund once."
			}
			if TicketsBeta.UserFlowTokenVault[self.user_id] == nil{ 
				TicketsBeta.UserFlowTokenVault[self.user_id] = flow_vault_receiver
			}
		}
		
		// [private access]
		access(all)
		fun useCrowdfundingTicket(dispenser_id: UInt32, token_id: UInt64, address: Address){ 
			pre{ 
				TicketsBeta.DispenserFlowTokenVault[dispenser_id] != nil:
					"Receiver is not set."
				TicketsBeta.ticketRequesters.containsKey(dispenser_id):
					"Ticket is not requested."
				((TicketsBeta.ticketRequesters[dispenser_id]!)[self.user_id]!).crowdfunding == true:
					"this ticket is not for crowdfunding."
			}
			self.ownedTicket[token_id]?.useCrowdfundingTicket()
			emit TicketUsed(dispenser_id: dispenser_id, user_id: self.user_id, token_id: token_id, address: address, price: 0.0)
		}
		
		init(_ dispenser_id: UInt32, _ address: Address, _ crowdfunding: Bool){ 
			// TotalSupply
			self.user_id = TicketsBeta.totalTicketVaultSupply + 1
			TicketsBeta.totalTicketVaultSupply = TicketsBeta.totalTicketVaultSupply + 1
			
			// Event, Data
			self.ownedTicket <-{} 
			self.contribution = []
			let time = getCurrentBlock().timestamp
			let requestStruct = RequestStruct(time: time, user_id: self.user_id, address: address, crowdfunding: crowdfunding)
			if let data = TicketsBeta.ticketRequesters[dispenser_id]{ 
				data[self.user_id] = requestStruct
				TicketsBeta.ticketRequesters[dispenser_id] = data
			} else{ 
				TicketsBeta.ticketRequesters[dispenser_id] ={ self.user_id: requestStruct}
			}
			emit TicketRequested(dispenser_id: dispenser_id, user_id: self.user_id, address: address)
		}
	}
	
	/*
	  ** [create vault] createTicketVault
	  */
	
	access(all)
	fun createTicketVault(
		dispenser_id: UInt32,
		address: Address,
		crowdfunding: Bool
	): @TicketVault{ 
		return <-create TicketVault(dispenser_id, address, crowdfunding)
	}
	
	/*
	  ** [Public Function] getDispenserDomains
	  */
	
	access(all)
	fun getDispenserDomains(): [String]{ 
		var dispenserArr: [String] = []
		for data in TicketsBeta.dispenserOwners.values{ 
			dispenserArr.append(data.domain)
		}
		return dispenserArr
	}
	
	/*
	  ** [Public Function] getDispenserInfo
	  */
	
	access(all)
	fun getDispenserInfo(address: Address):{ UInt32: String}?{ 
		var dispenserArr: [DispenserStruct] = []
		for data in TicketsBeta.dispenserOwners.values{ 
			if data.address == address{ 
				return{ data.dispenser_id: data.domain}
			}
		}
		return nil
	}
	
	/*
	  ** [Public Function] getTickets
	  */
	
	access(all)
	fun getTickets(): [TicketStruct]{ 
		return TicketsBeta.ticketInfo
	}
	
	/*
	  ** [Public Function] getTicketRequestStatus
	  */
	
	access(all)
	fun getTicketRequestStatus(dispenser_id: UInt32, user_id: UInt32): RequestStruct?{ 
		return (TicketsBeta.ticketRequesters[dispenser_id]!)[user_id]
	}
	
	/*
	  ** [Public Function] isSetRefundVault
	  */
	
	access(all)
	fun isSetRefundVault(user_id: UInt32): Bool{ 
		return TicketsBeta.UserFlowTokenVault[user_id] != nil
	}
	
	/*
	  ** init
	  */
	
	init(){ 
		self.AdminPrivateStoragePath = /storage/TicketsBetaAdmin
		self.AdminPublicStoragePath = /storage/TicketsBetaAdminPublic
		self.AdminPublicPath = /public/TicketsBetaAdminPublic
		self.CapabilityReceiverVaultPublicPath = /public/TicketsBetaCapabilityReceiverVault
		self.DispenserVaultPublicPath = /public/TicketsBetaDispenserVault
		self.TicketVaultPublicPath = /public/TicketsBetaVault
		self.AdminPrivatePath = /private/TicketsBetaAdmin
		self.DispenserVaultPrivatePath = /private/TicketsBetaDispenserVault
		self.TicketVaultPrivatePath = /private/TicketsBetaVault
		self.totalDispenserVaultSupply = 0
		self.totalTicketSupply = 0
		self.totalTicketVaultSupply = 0
		self.adminCapabilityHolder = false
		self.dispenserOwners ={} 
		self.ticketRequesters ={} 
		self.ticketInfo = []
		self.FlowTokenVault = self.account.capabilities.get<&FlowToken.Vault>(
				/public/flowTokenReceiver
			)!
		self.DispenserFlowTokenVault ={} 
		self.UserFlowTokenVault ={} 
		
		// grant admin resource and link capability receiver
		self.account.storage.save<@TicketsBeta.Admin>(
			<-create Admin(),
			to: self.AdminPrivateStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&TicketsBeta.Admin>(
				self.AdminPrivateStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		self.account.storage.save<@TicketsBeta.AdminPublic>(
			<-create AdminPublic(),
			to: self.AdminPublicStoragePath
		)
		var capability_2 =
			self.account.capabilities.storage.issue<&TicketsBeta.AdminPublic>(
				self.AdminPublicStoragePath
			)
		self.account.capabilities.publish(capability_2, at: self.AdminPublicPath)
	}
}
