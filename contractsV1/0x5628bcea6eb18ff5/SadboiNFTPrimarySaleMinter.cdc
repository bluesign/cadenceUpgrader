import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import SadboiNFT from "../0xd714ab2d9943c4a5/SadboiNFT.cdc"

access(all)
contract SadboiNFTPrimarySaleMinter{ 
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(self)
		let setMinter: @SadboiNFT.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @SadboiNFT.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @SadboiNFT.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
