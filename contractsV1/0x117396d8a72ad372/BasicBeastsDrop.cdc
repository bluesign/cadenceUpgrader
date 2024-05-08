import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract BasicBeastsDrop{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var currentDrop: UInt32
	
	access(self)
	var drops:{ UInt32: [Drop]}
	
	access(all)
	struct Drop{ 
		access(all)
		let order: UInt32
		
		access(all)
		let drop: UInt32
		
		access(all)
		let amount: UFix64
		
		access(all)
		let totalPurchase: UFix64
		
		access(all)
		let vaultAddress: Address
		
		access(all)
		let type: String
		
		access(all)
		let address: Address
		
		init(
			order: UInt32,
			amount: UFix64,
			totalPurchase: UFix64,
			vaultAddress: Address,
			type: String,
			address: Address
		){ 
			self.order = order
			self.drop = BasicBeastsDrop.currentDrop
			self.amount = amount
			self.totalPurchase = totalPurchase
			self.vaultAddress = vaultAddress
			self.type = type
			self.address = address
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun startNewDrop(){ 
			BasicBeastsDrop.currentDrop = BasicBeastsDrop.currentDrop + 1
		}
	}
	
	access(all)
	fun participate(
		amount: UFix64,
		vaultAddress: Address,
		type: String,
		vault: @{FungibleToken.Vault},
		address: Address
	){ 
		var quantity = 0
		var amountForPack: UFix64 = 0.0
		switch type{ 
			case "Starter":
				quantity = Int(amount / 10.0)
				amountForPack = 10.0
			case "Cursed Black":
				quantity = Int(amount / 300.0)
				amountForPack = 300.0
			case "Shiny Gold":
				quantity = Int(amount / 999.0)
				amountForPack = 999.0
		}
		if BasicBeastsDrop.drops[BasicBeastsDrop.currentDrop] == nil{ 
			BasicBeastsDrop.drops[BasicBeastsDrop.currentDrop] = []
		}
		var i = 0
		while quantity > i{ 
			(BasicBeastsDrop.drops[BasicBeastsDrop.currentDrop]!).append(Drop(order: UInt32((BasicBeastsDrop.drops[BasicBeastsDrop.currentDrop]!).length + 1), amount: amountForPack, totalPurchase: amount, vaultAddress: vaultAddress, type: type, address: address))
			i = i + 1
		}
		(
			(
				getAccount(vaultAddress).capabilities.get<&{FungibleToken.Receiver}>(
					/public/fusdReceiver
				)!
			).borrow()!
		).deposit(from: <-vault)
	}
	
	access(all)
	fun getDrops(): [UInt32]{ 
		return BasicBeastsDrop.drops.keys
	}
	
	access(all)
	fun getDropData(drop: UInt32): [Drop]?{ 
		return BasicBeastsDrop.drops[drop]
	}
	
	init(){ 
		self.AdminStoragePath = /storage/basicBeastsDropAdmin
		self.currentDrop = 12
		self.drops ={} 
		
		// Create a Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
