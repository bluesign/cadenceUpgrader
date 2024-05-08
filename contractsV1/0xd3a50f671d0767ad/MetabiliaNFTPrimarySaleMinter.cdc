import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import MetabiliaNFT from "../0x28766db62a58d796/MetabiliaNFT.cdc"

access(all)
contract MetabiliaNFTPrimarySaleMinter{ 
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(self)
		let setMinter: @MetabiliaNFT.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @MetabiliaNFT.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @MetabiliaNFT.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
