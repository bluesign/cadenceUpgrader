// TiblesNFT.cdc
access(all)
contract interface TiblesNFT{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let PublicCollectionPath: PublicPath
	
	access(all)
	resource interface INFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mintNumber: UInt32
		
		access(all)
		fun metadata():{ String: AnyStruct}?
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun depositTible(tible: @{TiblesNFT.INFT})
		
		access(all)
		fun borrowTible(id: UInt64): &{TiblesNFT.INFT}
	}
}
