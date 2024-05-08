import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import SNKRHUDNFT from "../0x80af1db15aa6535a/SNKRHUDNFT.cdc"

access(all)
contract SNKRHUDNFTPrimarySaleMinter{ 
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(self)
		let setMinter: @SNKRHUDNFT.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @SNKRHUDNFT.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @SNKRHUDNFT.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
