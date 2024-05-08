import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import DugoutDawgzNFT from "./DugoutDawgzNFT.cdc"

access(all)
contract DugoutDawgzNFTPrimarySaleMinter{ 
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(self)
		let setMinter: @DugoutDawgzNFT.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @DugoutDawgzNFT.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @DugoutDawgzNFT.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
