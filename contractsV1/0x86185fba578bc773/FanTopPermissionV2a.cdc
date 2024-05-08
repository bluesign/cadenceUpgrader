import FanTopToken from "./FanTopToken.cdc"

import FanTopMarket from "./FanTopMarket.cdc"

import FanTopSerial from "./FanTopSerial.cdc"

import Signature from "./Signature.cdc"

access(all)
contract FanTopPermissionV2a{ 
	access(all)
	event PermissionAdded(target: Address, role: String)
	
	access(all)
	event PermissionRemoved(target: Address, role: String)
	
	access(all)
	let ownerStoragePath: StoragePath
	
	access(all)
	let receiverStoragePath: StoragePath
	
	access(all)
	let receiverPublicPath: PublicPath
	
	access(all)
	resource interface Role{ 
		access(all)
		let role: String
	}
	
	access(all)
	resource Owner: Role{ 
		access(all)
		let role: String
		
		access(all)
		fun addAdmin(receiver: &{Receiver}){ 
			FanTopPermissionV2a.addPermission((receiver.owner!).address, role: "admin")
			receiver.receive(<-create Admin())
		}
		
		access(all)
		fun addPermission(_ address: Address, role: String){ 
			FanTopPermissionV2a.addPermission(address, role: role)
		}
		
		access(all)
		fun removePermission(_ address: Address, role: String){ 
			FanTopPermissionV2a.removePermission(address, role: role)
		}
		
		access(self)
		init(){ 
			self.role = "owner"
		}
	}
	
	access(all)
	resource Admin: Role{ 
		access(all)
		let role: String
		
		access(all)
		fun addOperator(receiver: &{Receiver}){ 
			FanTopPermissionV2a.addPermission((receiver.owner!).address, role: "operator")
			receiver.receive(<-create Operator())
		}
		
		access(all)
		fun removeOperator(_ address: Address){ 
			FanTopPermissionV2a.removePermission(address, role: "operator")
		}
		
		access(all)
		fun addMinter(receiver: &{Receiver}){ 
			FanTopPermissionV2a.addPermission((receiver.owner!).address, role: "minter")
			receiver.receive(<-create Minter())
		}
		
		access(all)
		fun removeMinter(_ address: Address){ 
			FanTopPermissionV2a.removePermission(address, role: "minter")
		}
		
		access(all)
		fun addAgent(receiver: &{Receiver}){ 
			FanTopPermissionV2a.addPermission((receiver.owner!).address, role: "agent")
			receiver.receive(<-create Agent())
		}
		
		access(all)
		fun removeAgent(_ address: Address){ 
			FanTopPermissionV2a.removePermission(address, role: "agent")
		}
		
		access(all)
		fun extendMarketCapacity(_ capacity: Int){ 
			FanTopMarket.extendCapacity(by: (self.owner!).address, capacity: capacity)
		}
		
		access(self)
		init(){ 
			self.role = "admin"
		}
	}
	
	access(all)
	resource Operator: Role{ 
		access(all)
		let role: String
		
		access(all)
		fun createItem(itemId: String, version: UInt32, limit: UInt32, metadata:{ String: String}, active: Bool){ 
			FanTopToken.createItem(itemId: itemId, version: version, limit: limit, metadata: metadata, active: active)
		}
		
		access(all)
		fun updateMetadata(itemId: String, version: UInt32, metadata:{ String: String}){ 
			FanTopToken.updateMetadata(itemId: itemId, version: version, metadata: metadata)
		}
		
		access(all)
		fun updateLimit(itemId: String, limit: UInt32){ 
			FanTopToken.updateLimit(itemId: itemId, limit: limit)
		}
		
		access(all)
		fun updateActive(itemId: String, active: Bool){ 
			FanTopToken.updateActive(itemId: itemId, active: active)
		}
		
		access(all)
		fun truncateSerialBox(itemId: String, limit: Int){ 
			let boxRef = FanTopSerial.getBoxRef(itemId: itemId) ?? panic("Boxes that do not exist cannot be truncated")
			boxRef.truncate(limit: limit)
		}
		
		access(self)
		init(){ 
			self.role = "operator"
		}
	}
	
	access(all)
	resource Minter: Role{ 
		access(all)
		let role: String
		
		access(all)
		fun mintToken(refId: String, itemId: String, itemVersion: UInt32, metadata:{ String: String}): @FanTopToken.NFT{ 
			return <-FanTopToken.mintToken(refId: refId, itemId: itemId, itemVersion: itemVersion, metadata: metadata, minter: (self.owner!).address)
		}
		
		access(all)
		fun mintTokenWithSerialNumber(refId: String, itemId: String, itemVersion: UInt32, metadata:{ String: String}, serialNumber: UInt32): @FanTopToken.NFT{ 
			return <-FanTopToken.mintTokenWithSerialNumber(refId: refId, itemId: itemId, itemVersion: itemVersion, metadata: metadata, serialNumber: serialNumber, minter: (self.owner!).address)
		}
		
		access(all)
		fun truncateSerialBox(itemId: String, limit: Int){ 
			let boxRef = FanTopSerial.getBoxRef(itemId: itemId) ?? panic("Boxes that do not exist cannot be truncated")
			boxRef.truncate(limit: limit)
		}
		
		access(self)
		init(){ 
			self.role = "minter"
		}
	}
	
	access(all)
	resource Agent: Role{ 
		access(all)
		let role: String
		
		access(all)
		fun update(orderId: String, version: UInt32, metadata:{ String: String}){ 
			FanTopMarket.update(agent: (self.owner!).address, orderId: orderId, version: version, metadata: metadata)
		}
		
		access(all)
		fun fulfill(orderId: String, version: UInt32, recipient: &{FanTopToken.CollectionPublic}){ 
			FanTopMarket.fulfill(agent: (self.owner!).address, orderId: orderId, version: version, recipient: recipient)
		}
		
		access(all)
		fun cancel(orderId: String){ 
			FanTopMarket.cancel(agent: (self.owner!).address, orderId: orderId)
		}
		
		access(self)
		init(){ 
			self.role = "agent"
		}
	}
	
	access(all)
	struct User{ 
		access(all)
		fun sell(
			agent: Address,
			capability: Capability<&FanTopToken.Collection>,
			orderId: String,
			refId: String,
			nftId: UInt64,
			version: UInt32,
			metadata: [
				String
			],
			signature: [
				UInt8
			],
			keyIndex: Int
		){ 
			pre{ 
				keyIndex >= 0
				FanTopPermissionV2a.hasPermission(agent, role: "agent")
				metadata.length % 2 == 0:
					"Unpaired metadata cannot be used"
			}
			let account = getAccount(agent)
			var signedData =
				agent.toBytes().concat(capability.address.toBytes()).concat(orderId.utf8).concat(
					refId.utf8
				).concat(nftId.toBigEndianBytes()).concat(version.toBigEndianBytes())
			let flatMetadata:{ String: String} ={} 
			var i = 0
			while i < metadata.length{ 
				let key = metadata[i]
				let value = metadata[i + 1]
				signedData = signedData.concat(key.utf8).concat(value.utf8)
				flatMetadata[key] = value
				i = i + 2
			}
			signedData = signedData.concat(keyIndex.toString().utf8)
			assert(
				Signature.verify(
					signature: signature,
					signedData: signedData,
					account: account,
					keyIndex: keyIndex
				),
				message: "Unverified orders cannot be fulfilled"
			)
			FanTopMarket.sell(
				agent: agent,
				capability: capability,
				orderId: orderId,
				refId: refId,
				nftId: nftId,
				version: version,
				metadata: flatMetadata
			)
		}
		
		access(all)
		fun cancel(account: AuthAccount, orderId: String){ 
			pre{ 
				FanTopMarket.containsOrder(orderId):
					"Order is not exists"
				account.address == (FanTopMarket.getSellOrder(orderId)!).getOwner().address:
					"Cancel account is not match order account"
			}
			FanTopMarket.cancel(agent: nil, orderId: orderId)
		}
	}
	
	access(all)
	resource interface Receiver{ 
		access(all)
		fun receive(_ _resource: @{Role})
		
		access(all)
		view fun check(address: Address): Bool
	}
	
	access(all)
	resource Holder: Receiver{ 
		access(self)
		let address: Address
		
		access(self)
		let resources: @{String:{ Role}}
		
		access(all)
		view fun check(address: Address): Bool{ 
			return address == self.owner?.address && address == self.address
		}
		
		access(all)
		fun receive(_ _resource: @{Role}){ 
			assert(!self.resources.containsKey(_resource.role), message: "Resources for roles that already exist cannot be received")
			self.resources[_resource.role] <-! _resource
		}
		
		access(self)
		fun borrow(by: AuthAccount, role: String): &{Role}{ 
			pre{ 
				self.check(address: by.address):
					"Only borrowing by the owner is allowed"
				FanTopPermissionV2a.hasPermission(by.address, role: role):
					"Roles not on the list are not allowed"
			}
			return &self.resources[role] as &{Role}? ?? panic("Could not borrow role")
		}
		
		access(all)
		fun borrowAdmin(by: AuthAccount): &Admin{ 
			return self.borrow(by: by, role: "admin") as! &Admin
		}
		
		access(all)
		fun borrowOperator(by: AuthAccount): &Operator{ 
			return self.borrow(by: by, role: "operator") as! &Operator
		}
		
		access(all)
		fun borrowMinter(by: AuthAccount): &Minter{ 
			return self.borrow(by: by, role: "minter") as! &Minter
		}
		
		access(all)
		fun borrowAgent(by: AuthAccount): &Agent{ 
			return self.borrow(by: by, role: "agent") as! &Agent
		}
		
		access(all)
		fun revoke(_ role: String){ 
			pre{ 
				FanTopPermissionV2a.isRole(role):
					"Unknown role cannot be changed"
			}
			FanTopPermissionV2a.removePermission(self.address, role: role)
			destroy self.resources.remove(key: role)
		}
		
		access(contract)
		init(_ address: Address){ 
			self.address = address
			self.resources <-{} 
		}
	}
	
	access(all)
	fun createHolder(account: AuthAccount): @Holder{ 
		return <-create Holder(account.address)
	}
	
	access(self)
	let permissions:{ Address:{ String: Bool}}
	
	access(self)
	fun addPermission(_ address: Address, role: String){ 
		pre{ 
			FanTopPermissionV2a.isRole(role):
				"Unknown role cannot be changed"
			role != "owner":
				"Owner cannot be changed"
			!self.hasPermission(address, role: role):
				"Permission that already exists cannot be added"
		}
		let permission = self.permissions[address] ??{}  as{ String: Bool}
		permission[role] = true
		self.permissions[address] = permission
		emit PermissionAdded(target: address, role: role)
	}
	
	access(self)
	fun removePermission(_ address: Address, role: String){ 
		pre{ 
			FanTopPermissionV2a.isRole(role):
				"Unknown role cannot be changed"
			role != "owner":
				"Owner cannot be changed"
			self.hasPermission(address, role: role):
				"Permissions that do not exist cannot be deleted"
		}
		let permission:{ String: Bool} = self.permissions[address]!
		permission[role] = false
		self.permissions[address] = permission
		emit PermissionRemoved(target: address, role: role)
	}
	
	access(all)
	fun getAllPermissions():{ Address:{ String: Bool}}{ 
		return self.permissions
	}
	
	access(all)
	view fun hasPermission(_ address: Address, role: String): Bool{ 
		if let permission = self.permissions[address]{ 
			return permission[role] ?? false
		}
		return false
	}
	
	access(all)
	view fun isRole(_ role: String): Bool{ 
		switch role{ 
			case "owner":
				return true
			case "admin":
				return true
			case "operator":
				return true
			case "minter":
				return true
			case "agent":
				return true
			default:
				return false
		}
	}
	
	init(){ 
		self.ownerStoragePath = /storage/FanTopOwnerV2a
		self.receiverStoragePath = /storage/FanTopPermissionV2a
		self.receiverPublicPath = /public/FanTopPermissionV2a
		self.permissions ={ self.account.address:{ "owner": true}}
		self.account.storage.save<@Owner>(<-create Owner(), to: self.ownerStoragePath)
	}
}
