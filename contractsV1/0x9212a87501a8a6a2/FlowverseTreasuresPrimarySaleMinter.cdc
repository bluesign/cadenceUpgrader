import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowverseTreasures from "./FlowverseTreasures.cdc"

import FlowversePrimarySale from "./FlowversePrimarySale.cdc"

access(all)
contract FlowverseTreasuresPrimarySaleMinter{ 
	access(all)
	resource Minter: FlowversePrimarySale.IMinter{ 
		access(self)
		let setMinter: @FlowverseTreasures.SetMinter
		
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(entityID: entityID, minterAddress: minterAddress)
		}
		
		init(setMinter: @FlowverseTreasures.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @FlowverseTreasures.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
	
	access(all)
	fun getPrivatePath(setID: UInt64): PrivatePath{ 
		let pathIdentifier = "FlowverseTreasuresPrimarySaleMinter"
		return PrivatePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
	
	access(all)
	fun getStoragePath(setID: UInt64): StoragePath{ 
		let pathIdentifier = "FlowverseTreasuresPrimarySaleMinter"
		return StoragePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
}
