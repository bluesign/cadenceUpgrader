import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import DriverzNFT from "./DriverzNFT.cdc"

access(all)
contract DriverzNFTPrimarySaleMinter{ 
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(self)
		let setMinter: @DriverzNFT.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @DriverzNFT.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @DriverzNFT.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
