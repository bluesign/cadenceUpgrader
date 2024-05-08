import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Created by Emerald City DAO for Touchstone (https://touchstone.city/)
access(all)
contract TouchstonePurchases{ 
	access(all)
	let PurchasesStoragePath: StoragePath
	
	access(all)
	let PurchasesPublicPath: PublicPath
	
	access(all)
	struct Purchase{ 
		access(all)
		let metadataId: UInt64
		
		access(all)
		let display: MetadataViews.Display
		
		access(all)
		let contractAddress: Address
		
		access(all)
		let contractName: String
		
		init(
			_metadataId: UInt64,
			_display: MetadataViews.Display,
			_contractAddress: Address,
			_contractName: String
		){ 
			self.metadataId = _metadataId
			self.display = _display
			self.contractAddress = _contractAddress
			self.contractName = _contractName
		}
	}
	
	access(all)
	resource interface PurchasesPublic{ 
		access(all)
		fun getPurchases():{ UInt64: Purchase}
	}
	
	access(all)
	resource Purchases: PurchasesPublic{ 
		access(all)
		let list:{ UInt64: Purchase}
		
		access(all)
		fun addPurchase(uuid: UInt64, metadataId: UInt64, display: MetadataViews.Display, contractAddress: Address, contractName: String){ 
			self.list[uuid] = Purchase(_metadataId: metadataId, _display: display, _contractAddress: contractAddress, _contractName: contractName)
		}
		
		access(all)
		fun getPurchases():{ UInt64: Purchase}{ 
			return self.list
		}
		
		init(){ 
			self.list ={} 
		}
	}
	
	access(all)
	fun createPurchases(): @Purchases{ 
		return <-create Purchases()
	}
	
	init(){ 
		self.PurchasesStoragePath = /storage/TouchstonePurchases
		self.PurchasesPublicPath = /public/TouchstonePurchases
	}
}
