import SchmoesPreLaunchToken from "./SchmoesPreLaunchToken.cdc"

access(all)
contract SchmoesPreLaunchTokenAdmin{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(all)
		fun setIsSaleActive(_ isSaleActive: Bool){ 
			SchmoesPreLaunchToken.setIsSaleActive(isSaleActive)
		}
		
		access(all)
		fun setImageUrl(_ imageUrl: String){ 
			SchmoesPreLaunchToken.setImageUrl(imageUrl)
		}
	}
	
	access(all)
	init(){ 
		self.AdminStoragePath = /storage/schmoesPreLaunchTokenAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
