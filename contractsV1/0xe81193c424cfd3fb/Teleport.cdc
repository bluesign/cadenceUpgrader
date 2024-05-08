import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Clock from "./Clock.cdc"

import Wearables from "./Wearables.cdc"

import FindUtils from "../0x097bafa4e0b48eef/FindUtils.cdc"

import FindRelatedAccounts from "../0x097bafa4e0b48eef/FindRelatedAccounts.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TokenForwarding from "./../../standardsV1/TokenForwarding.cdc"

import DapperStorageRent from "../0xa08e88e23f332538/DapperStorageRent.cdc"

import GenesisBoxRegistry from "./GenesisBoxRegistry.cdc"

access(all)
contract Teleport{ 
	
	//mapping of remoteId so DoodleId to data
	access(contract)
	let registryRemote:{ UInt64: Data}
	
	//mapping of dooplicator id to doodleId
	access(contract)
	let registryTeleporter:{ UInt64: UInt64}
	
	//was misspelled in an earlier version, needs to be here...
	access(all)
	event Refueled()
	
	access(all)
	event Refuelled(
		address: Address,
		amount: UFix64,
		missingStorage: UInt64,
		storageUsed: UInt64,
		storageCapacity: UInt64
	)
	
	access(all)
	event Teleported(data: Data)
	
	access(all)
	event Opened(data: GenesisBoxRegistry.Data)
	
	access(all)
	struct Data{ 
		
		//the receiver address on flow
		access(all)
		let receiver: Address
		
		//the doodleId of the asset beeing teleported
		access(all)
		let remoteId: UInt64
		
		//the id of the teleporter token
		access(all)
		let teleporterId: UInt64
		
		//the remote address on ETH
		access(all)
		let remoteAddress: String
		
		//context like ethTx or other info to add to event
		access(all)
		let context:{ String: String}
		
		//the wearable template ids that will be minted and sent
		access(all)
		let wearableTemplateIds: [UInt64]
		
		init(
			receiver: Address,
			remoteId: UInt64,
			remoteAddress: String,
			templateId: UInt64,
			wearableTemplateIds: [
				UInt64
			],
			context:{ 
				String: String
			},
			teleporterId: UInt64
		){ 
			self.receiver = receiver
			self.remoteId = remoteId
			self.remoteAddress = remoteAddress
			self.context = context
			self.wearableTemplateIds = wearableTemplateIds
			self.teleporterId = teleporterId
		}
	}
	
	//store the proxy for the admin
	access(all)
	let TeleportProxyPublicPath: PublicPath
	
	access(all)
	let TeleportProxyStoragePath: StoragePath
	
	access(all)
	let TeleportServerStoragePath: StoragePath
	
	access(all)
	let TeleportServerPrivatePath: PrivatePath
	
	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	access(all)
	resource Server{} 
	
	/// ===================================================================================
	// Teleport things
	/// ===================================================================================
	//Teleport client to use for capability receiver pattern
	access(all)
	fun createTeleportProxyClient(): @TeleportProxy{ 
		return <-create TeleportProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface TeleportProxyClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&Server>)
	}
	
	//admin proxy with capability receiver
	access(all)
	resource TeleportProxy: TeleportProxyClient{ 
		access(self)
		var capability: Capability<&Server>?
		
		access(all)
		fun addCapability(_ cap: Capability<&Server>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(all)
		fun teleport(_ data: Data){ 
			pre{ 
				self.capability != nil:
					"Cannot create Teleport, capability is not set"
			}
			let status = Teleport.isAllowed(remoteId: data.remoteId, teleporterId: data.teleporterId)
			if !status.allowed{ 
				panic(status.message)
			}
			let trust = Teleport.isTrusted(flow: data.receiver, ethereum: data.remoteAddress)
			if !trust.allowed{ 
				panic(trust.message)
			}
			let account = getAccount(data.receiver)
			let wearable = account.capabilities.get<&Wearables.Collection>(Wearables.CollectionPublicPath).borrow() ?? panic("cannot borrow werable cap")
			let context = data.context
			for id in data.wearableTemplateIds{ 
				Wearables.mintNFT(recipient: wearable, template: id, context: context)
			}
			Teleport.registryRemote[data.remoteId] = data
			Teleport.registryTeleporter[data.teleporterId] = data.remoteId
			emit Teleported(data: data)
			if let receiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow(){ 
				let isDapper = receiver.isInstance(Type<@TokenForwarding.Forwarder>())
				if !isDapper{ 
					return
				}
			}
			
			//try to refill first and then fill up if we need to?
			DapperStorageRent.tryRefill(data.receiver)
			let buffer = 1000 as UInt64
			let recipient = getAccount(data.receiver)
			var used: UInt64 = recipient.storage.used
			var capacity: UInt64 = recipient.storage.capacity
			var missingStorage = 0 as UInt64
			if used > capacity{ 
				missingStorage = used - capacity + buffer
			} else{ 
				let remainingStorage = capacity - used
				if remainingStorage < buffer{ 
					missingStorage = buffer - remainingStorage
				}
			}
			if missingStorage > 0{ 
				let amount = 0.1 //we just give a fixed amount right now
				
				emit Refuelled(address: data.receiver, amount: amount, missingStorage: missingStorage, storageUsed: used, storageCapacity: capacity)
				let vaultRef = Teleport.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("cannot get flow token vault")
				let newVault <- DapperStorageRent.fundedRefillV2(address: data.receiver, tokens: <-vaultRef.withdraw(amount: amount))
				vaultRef.deposit(from: <-newVault)
			}
		}
		
		access(all)
		fun openBox(_ data: GenesisBoxRegistry.Data){ 
			pre{ 
				self.capability != nil:
					"Cannot create Teleport, capability is not set"
			}
			let record = GenesisBoxRegistry.getGenesisBoxStatus(data.genesisBoxId)
			if record != nil{ 
				panic("Genesis Box ID : ".concat(data.genesisBoxId.toString()).concat(" has already been opened by ").concat((record!).receiver.toString()))
			}
			let trust = Teleport.isTrusted(flow: data.receiver, ethereum: data.remoteAddress)
			if !trust.allowed{ 
				panic(trust.message)
			}
			let account = getAccount(data.receiver)
			let wearable = account.capabilities.get<&Wearables.Collection>(Wearables.CollectionPublicPath).borrow() ?? panic("cannot borrow werable cap")
			let context = data.context
			for id in data.wearableTemplateIds{ 
				Wearables.mintNFT(recipient: wearable, template: id, context: context)
			}
			GenesisBoxRegistry.setData(data)
			emit Opened(data: data)
			if let receiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow(){ 
				let isDapper = receiver.isInstance(Type<@TokenForwarding.Forwarder>())
				if !isDapper{ 
					return
				}
			}
			
			//try to refill first and then fill up if we need to?
			DapperStorageRent.tryRefill(data.receiver)
			let buffer = 1000 as UInt64
			let recipient = getAccount(data.receiver)
			var used: UInt64 = recipient.storage.used
			var capacity: UInt64 = recipient.storage.capacity
			var missingStorage = 0 as UInt64
			if used > capacity{ 
				missingStorage = used - capacity + buffer
			} else{ 
				let remainingStorage = capacity - used
				if remainingStorage < buffer{ 
					missingStorage = buffer - remainingStorage
				}
			}
			if missingStorage > 0{ 
				let amount = 0.1 //we just give a fixed amount right now
				
				emit Refuelled(address: data.receiver, amount: amount, missingStorage: missingStorage, storageUsed: used, storageCapacity: capacity)
				let vaultRef = Teleport.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("cannot get flow token vault")
				let newVault <- DapperStorageRent.fundedRefillV2(address: data.receiver, tokens: <-vaultRef.withdraw(amount: amount))
				vaultRef.deposit(from: <-newVault)
			}
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	access(all)
	fun getRemoteStatus(_ id: UInt64): Data?{ 
		return self.registryRemote[id]
	}
	
	access(all)
	fun getTeleporterStatus(_ id: UInt64): Data?{ 
		if let remoteId = self.registryTeleporter[id]{ 
			return self.getRemoteStatus(remoteId)
		}
		return nil
	}
	
	access(all)
	fun getGenesisBoxStatus(_ id: UInt64): GenesisBoxRegistry.Data?{ 
		return GenesisBoxRegistry.getGenesisBoxStatus(id)
	}
	
	access(all)
	fun isValid(remoteId: UInt64, teleporterId: UInt64): Bool{ 
		if let checkRemoteId = self.registryTeleporter[teleporterId]{ 
			return remoteId == checkRemoteId
		}
		return false
	}
	
	access(all)
	struct AllowedStatus{ 
		access(all)
		let allowed: Bool
		
		access(all)
		let message: String
		
		init(remoteId: UInt64, teleporterId: UInt64){ 
			var remoteMessage = ""
			var teleporterMessage = ""
			let ids =
				"DoodleID : ".concat(remoteId.toString()).concat(" DooplicatorID : ").concat(
					teleporterId.toString()
				)
			if let remote = Teleport.getRemoteStatus(remoteId){ 
				remoteMessage = FindUtils.joinMapToString(remote.context)
			}
			if let teleporter = Teleport.getTeleporterStatus(teleporterId){ 
				teleporterMessage = FindUtils.joinMapToString(teleporter.context)
			}
			if remoteMessage == "" && teleporterMessage == ""{ 
				self.message = ""
				self.allowed = true
			} else if remoteMessage == teleporterMessage{ 
				self.message = ids.concat(" was teleported as a combination. ").concat(remoteMessage)
				self.allowed = false
			} else{ 
				var message = ""
				var remoteTeleported = false
				message = message.concat("DoodleID : ").concat(remoteId.toString())
				if remoteMessage != ""{ 
					message = message.concat(" was teleported. Remote : ").concat(remoteMessage)
					remoteTeleported = true
				} else{ 
					message = message.concat(" was not teleported. ")
				}
				message = message.concat("DooplicatorID : ").concat(teleporterId.toString())
				if teleporterMessage != ""{ 
					message = message.concat(" was teleported. Teleporter : ").concat(teleporterMessage)
					if remoteTeleported{ 
						message = "Combination was teleported separately. ".concat(message)
					}
				} else{ 
					message = message.concat(" was not teleported. ")
				}
				self.message = message
				self.allowed = false
			}
		}
	}
	
	access(all)
	struct TrustStatus{ 
		access(all)
		let allowed: Bool
		
		access(all)
		let message: String
		
		init(flow: Address, ethereum: String){ 
			self.allowed = true
			self.message = ""
		
		// Disabled
		// let account=getAccount(flow)
		
		// if let related = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath).borrow() {
		// 	if !related.verify(network: "Ethereum", address:ethereum) {
		// 		self.allowed=false
		// 		self.message="receiver with address ".concat(flow.toString()).concat(" is not set up to teleport from ETH address ").concat(ethereum)
		// 	} else {
		// 		self.allowed=true
		// 		self.message=""
		// 	}
		// } else {
		// 	self.allowed=false
		// 	self.message="No related accounts registered for the account ".concat(flow.toString())
		// }
		}
	}
	
	access(all)
	fun isAllowed(remoteId: UInt64, teleporterId: UInt64): AllowedStatus{ 
		return AllowedStatus(remoteId: remoteId, teleporterId: teleporterId)
	}
	
	access(all)
	fun isTrusted(flow: Address, ethereum: String): TrustStatus{ 
		return TrustStatus(flow: flow, ethereum: ethereum)
	}
	
	access(all)
	fun isGenesisBoxAllowed(_ genesisBoxId: UInt64): GenesisBoxRegistry.AllowedStatus{ 
		return GenesisBoxRegistry.AllowedStatus(genesisBoxId)
	}
	
	init(){ 
		self.TeleportProxyPublicPath = /public/teleportProxy
		self.TeleportProxyStoragePath = /storage/teleportProxy
		self.registryRemote ={} 
		self.registryTeleporter ={} 
		
		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.TeleportServerPrivatePath = /private/teleportServer
		self.TeleportServerStoragePath = /storage/teleportServer
		self.account.storage.save(<-create Server(), to: self.TeleportServerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Server>(self.TeleportServerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.TeleportServerPrivatePath)
	}
}
