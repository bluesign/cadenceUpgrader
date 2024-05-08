import Crypto

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FanTopToken from "./FanTopToken.cdc"

access(all)
contract FanTopMarket{ 
	access(all)
	event CapacityExtended(by: Address, capacity: Int)
	
	access(all)
	event SellOrderAdded(
		agent: Address,
		from: Address,
		orderId: String,
		refId: String,
		nftId: UInt64,
		version: UInt32,
		metadata:{ 
			String: String
		}
	)
	
	access(all)
	event SellOrderUpdated(
		agent: Address,
		from: Address,
		orderId: String,
		refId: String,
		nftId: UInt64,
		version: UInt32,
		metadata:{ 
			String: String
		}
	)
	
	access(all)
	event SellOrderCancelled(
		agent: Address?,
		from: Address,
		orderId: String,
		refId: String,
		nftId: UInt64,
		version: UInt32,
		metadata:{ 
			String: String
		}
	)
	
	access(all)
	event SellOrderFulfilled(
		agent: Address,
		orderId: String,
		refId: String,
		nftId: UInt64,
		from: Address,
		to: Address,
		metadata:{ 
			String: String
		}
	)
	
	access(all)
	struct SellOrder{ 
		access(all)
		let orderId: String
		
		access(contract)
		let capability: Capability<&FanTopToken.Collection>
		
		access(all)
		let refId: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let version: UInt32
		
		access(contract)
		let metadata:{ String: String}
		
		access(self)
		init(
			orderId: String,
			capability: Capability<&FanTopToken.Collection>,
			refId: String,
			nftId: UInt64,
			version: UInt32,
			metadata:{ 
				String: String
			}
		){ 
			self.orderId = orderId
			self.capability = capability
			self.refId = refId
			self.nftId = nftId
			self.version = version
			self.metadata = metadata
		}
		
		access(contract)
		fun withdraw(): @FanTopToken.NFT{ 
			let token <-
				(self.capability.borrow()!).withdraw(withdrawID: self.nftId) as! @FanTopToken.NFT
			return <-token
		}
		
		access(all)
		fun borrowFanTopToken(): &FanTopToken.NFT{ 
			return (self.capability.borrow()!).borrowFanTopToken(id: self.nftId)
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun check(): Bool{ 
			if let collection = self.capability.borrow(){ 
				if !collection.getIDs().contains(self.nftId){ 
					return false
				}
				let token = collection.borrowFanTopToken(id: self.nftId)
				return token.refId == self.refId
			}
			return false
		}
		
		access(all)
		fun getOwner(): &Account{ 
			return getAccount(self.capability.address)
		}
	}
	
	access(all)
	struct SellOrderList{ 
		access(self)
		let orders:{ String: SellOrder}
		
		access(self)
		let refIds:{ String: String}
		
		access(self)
		let nftIds:{ UInt64: String}
		
		access(account)
		init(){ 
			self.orders ={} 
			self.nftIds ={} 
			self.refIds ={} 
		}
		
		access(contract)
		view fun contains(_ orderId: String): Bool{ 
			return self.orders.containsKey(orderId)
		}
		
		access(contract)
		view fun containsRefId(_ refId: String): Bool{ 
			return self.refIds.containsKey(refId)
		}
		
		access(contract)
		view fun containsNFTId(_ nftId: UInt64): Bool{ 
			return self.nftIds.containsKey(nftId)
		}
		
		access(contract)
		fun get(_ orderId: String): SellOrder?{ 
			return self.orders[orderId]
		}
		
		access(contract)
		fun getOrderIds(): [String]{ 
			return self.orders.keys
		}
		
		access(contract)
		fun insert(key orderId: String, _ order: SellOrder){ 
			pre{ 
				!self.orders.containsKey(orderId):
					"Cannot add a SellOrder that already exists"
				!self.refIds.containsKey(order.refId):
					"Cannot add a SellOrder with duplicate refId"
				!self.nftIds.containsKey(order.nftId):
					"Cannot add a SellOrder with duplicate nftId"
			}
			self.orders.insert(key: orderId, order)
			self.refIds.insert(key: order.refId, orderId)
			self.nftIds.insert(key: order.nftId, orderId)
		}
		
		access(contract)
		fun remove(key orderId: String): SellOrder{ 
			pre{ 
				self.orders.containsKey(orderId):
					"Orders that are not included cannot be removed"
			}
			let order = self.orders.remove(key: orderId)!
			self.refIds.remove(key: order.refId)
			self.nftIds.remove(key: order.nftId)
			return order
		}
		
		access(contract)
		fun count(): Int{ 
			return self.orders.length
		}
	}
	
	access(self)
	let sellOrderLists: [SellOrderList]
	
	access(self)
	view fun getSellOrderIndex(_ orderId: String): Int{ 
		var index = 0
		while index < self.sellOrderLists.length{ 
			if self.sellOrderLists[index].contains(orderId){ 
				return index
			}
			index = index + 1
		}
		return -1
	}
	
	access(self)
	fun getSellOrderMinimumIndex(): Int{ 
		var minIndex = 0
		var index = 0
		while index < self.sellOrderLists.length{ 
			if self.sellOrderLists[index].count() < self.sellOrderLists[minIndex].count(){ 
				minIndex = index
			}
			index = index + 1
		}
		return minIndex
	}
	
	access(account)
	fun extendCapacity(by: Address, capacity: Int){ 
		pre{ 
			capacity > self.sellOrderLists.length:
				"Capacity cannot be reduced"
		}
		let size = capacity - self.sellOrderLists.length
		var count = 0
		while count < size{ 
			self.sellOrderLists.append(SellOrderList())
			count = count + 1
		}
		emit CapacityExtended(by: by, capacity: capacity)
	}
	
	access(account)
	fun sell(
		agent: Address,
		capability: Capability<&FanTopToken.Collection>,
		orderId: String,
		refId: String,
		nftId: UInt64,
		version: UInt32,
		metadata:{ 
			String: String
		}
	){ 
		pre{ 
			!self.containsOrder(orderId):
				"Cannot add a SellOrder that already exists"
			!self.containsRefId(refId):
				"Cannot add a SellOrder with duplicate refId"
			!self.containsNFTId(nftId):
				"Cannot add a SellOrder with duplicate nftId"
		}
		let order =
			SellOrder(
				orderId: orderId,
				capability: capability,
				refId: refId,
				nftId: nftId,
				version: version,
				metadata: metadata
			)
		if !order.check(){ 
			panic("Invalid orders cannot be added")
		}
		let index = self.getSellOrderMinimumIndex()
		self.sellOrderLists[index].insert(key: orderId, order)
		emit SellOrderAdded(
			agent: agent,
			from: capability.address,
			orderId: orderId,
			refId: refId,
			nftId: nftId,
			version: version,
			metadata: metadata
		)
	}
	
	access(account)
	fun update(agent: Address, orderId: String, version: UInt32, metadata:{ String: String}){ 
		pre{ 
			self.containsOrder(orderId):
				"Cannot update non-existent order"
		}
		var index = self.getSellOrderIndex(orderId)
		let removed = self.sellOrderLists[index].remove(key: orderId)
		if !removed.check(){ 
			panic("Invalid order cannot be updated")
		}
		if version <= removed.version{ 
			panic("Order cannot be updated without upgrading the version")
		}
		let order =
			SellOrder(
				orderId: orderId,
				capability: removed.capability,
				refId: removed.refId,
				nftId: removed.nftId,
				version: version,
				metadata: metadata
			)
		index = self.getSellOrderMinimumIndex()
		self.sellOrderLists[index].insert(key: orderId, order)
		emit SellOrderUpdated(
			agent: agent,
			from: order.capability.address,
			orderId: orderId,
			refId: order.refId,
			nftId: order.nftId,
			version: version,
			metadata: metadata
		)
	}
	
	access(account)
	fun fulfill(
		agent: Address,
		orderId: String,
		version: UInt32,
		recipient: &{FanTopToken.CollectionPublic}
	){ 
		pre{ 
			self.containsOrder(orderId):
				"Cannot fulfill non-existent order"
			recipient.owner != nil:
				"Purchased tokens cannot be placed in collections where the owner cannot be identified"
		}
		let index = self.getSellOrderIndex(orderId)
		let order = self.sellOrderLists[index].remove(key: orderId)
		if !order.check(){ 
			panic("Invalid order cannot be purchased")
		}
		if order.version != version{ 
			panic("Orders with mismatched versions cannot be purchased")
		}
		let token <- order.withdraw()
		recipient.deposit(token: <-token)
		emit SellOrderFulfilled(
			agent: agent,
			orderId: orderId,
			refId: order.refId,
			nftId: order.nftId,
			from: order.capability.address,
			to: (recipient.owner!).address,
			metadata: order.metadata
		)
	}
	
	access(account)
	fun cancel(agent: Address?, orderId: String){ 
		pre{ 
			self.containsOrder(orderId):
				"Orders that do not exist cannot be canceled"
		}
		let index = self.getSellOrderIndex(orderId)
		let removed = self.sellOrderLists[index].remove(key: orderId)!
		emit SellOrderCancelled(
			agent: agent,
			from: removed.capability.address,
			orderId: orderId,
			refId: removed.refId,
			nftId: removed.nftId,
			version: removed.version,
			metadata: removed.metadata
		)
	}
	
	// Public
	access(all)
	fun getCapacity(): Int{ 
		return self.sellOrderLists.length
	}
	
	access(all)
	fun getCountOfOrders(index: Int): Int{ 
		return self.sellOrderLists[index].count()
	}
	
	access(all)
	fun getTotalCountOfOrders(): Int{ 
		var count = 0
		for container in self.sellOrderLists{ 
			count = count + container.count()
		}
		return count
	}
	
	access(all)
	view fun containsOrder(_ orderId: String): Bool{ 
		return self.getSellOrderIndex(orderId) >= 0
	}
	
	access(all)
	view fun containsRefId(_ refId: String): Bool{ 
		var index = 0
		while index < self.sellOrderLists.length{ 
			if self.sellOrderLists[index].containsRefId(refId){ 
				return true
			}
			index = index + 1
		}
		return false
	}
	
	access(all)
	view fun containsNFTId(_ nftId: UInt64): Bool{ 
		var index = 0
		while index < self.sellOrderLists.length{ 
			if self.sellOrderLists[index].containsNFTId(nftId){ 
				return true
			}
			index = index + 1
		}
		return false
	}
	
	access(all)
	fun getSellOrderIds(): [String]{ 
		let ids: [String] = []
		for orderMap in self.sellOrderLists{ 
			ids.appendAll(orderMap.getOrderIds())
		}
		return ids
	}
	
	access(all)
	fun getSellOrder(_ orderId: String): SellOrder?{ 
		let index = self.getSellOrderIndex(orderId)
		if index == -1{ 
			return nil
		}
		return self.sellOrderLists[index].get(orderId)
	}
	
	init(){ 
		self.sellOrderLists = [SellOrderList()]
	}
}
