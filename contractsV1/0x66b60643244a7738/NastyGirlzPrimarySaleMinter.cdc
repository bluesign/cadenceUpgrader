// Mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NGPrimarySale from "./NGPrimarySale.cdc"

import NastyGirlz from "./NastyGirlz.cdc"

access(all)
contract NastyGirlzPrimarySaleMinter{ 
	access(all)
	resource Minter: NGPrimarySale.IMinter{ 
		access(self)
		let setMinter: @NastyGirlz.SetMinter
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @NastyGirlz.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(all)
	fun createMinter(setMinter: @NastyGirlz.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
