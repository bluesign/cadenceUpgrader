import AlphaNFTV1 from "./AlphaNFTV1.cdc"

import AlphaPackV1 from "./AlphaPackV1.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AlphaAdminV1{ 
	
	// Admin
	// the admin resource is defined so that only the admin account
	// can have this resource. It possesses the ability to open packs
	// given a user's Pack Collection and Card Collection reference.
	// It can also create a new pack type and mint Packs.
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createTemplate(maxSupply: UInt64, immutableData:{ String: AnyStruct}){ 
			AlphaNFTV1.createTemplate(maxSupply: maxSupply, immutableData: immutableData)
		}
		
		access(all)
		fun openPack(templateInfo:{ String: UInt64}, account: Address){ 
			AlphaNFTV1.mintNFT(templateInfo: templateInfo, account: account)
		}
		
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(all)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		init(){} 
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/AlphaAdminV1)
	}
}
