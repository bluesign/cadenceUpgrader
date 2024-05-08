import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowversePass from "./FlowversePass.cdc"

import FlowversePrimarySale from "./FlowversePrimarySale.cdc"

access(all)
contract FlowversePassPrimarySaleMinter{ 
	access(all)
	resource Minter: FlowversePrimarySale.IMinter{ 
		access(self)
		let setMinter: @FlowversePass.SetMinter
		
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(entityID: entityID, minterAddress: minterAddress)
		}
		
		init(setMinter: @FlowversePass.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @FlowversePass.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
	
	access(all)
	fun getPrivatePath(setID: UInt64): PrivatePath{ 
		let pathIdentifier = "FlowversePassPrimarySaleMinter"
		return PrivatePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
	
	access(all)
	fun getStoragePath(setID: UInt64): StoragePath{ 
		let pathIdentifier = "FlowversePassPrimarySaleMinter"
		return StoragePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
}
