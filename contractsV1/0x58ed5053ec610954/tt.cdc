import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MatrixWorldVoucher from "../0x0d77ec47bbad8ef6/MatrixWorldVoucher.cdc"

access(all)
contract tt{ 
	access(all)
	resource tr: MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]{ 
			return [UInt64(1479)]
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			destroy token
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			panic("no")
		}
		
		access(all)
		fun borrowVoucher(id: UInt64): &MatrixWorldVoucher.NFT?{ 
			panic("no nft")
		}
	}
	
	init(){} 
}
