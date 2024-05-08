import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TopShotLocking from "../0x0b2a3299cc857e29/TopShotLocking.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import Pinnacle from "../0xedf9df96c92f4595/Pinnacle.cdc"

access(all)
contract NFTLocking{ 
	access(all)
	fun isLocked(nftRef: &{NonFungibleToken.NFT}): Bool{ 
		let type = nftRef.getType()
		if type == Type<@TopShot.NFT>(){ 
			return TopShotLocking.isLocked(nftRef: nftRef)
		}
		if type == Type<@Pinnacle.NFT>(){ 
			let pinnacleNFTRef: &Pinnacle.NFT? = nftRef as? &Pinnacle.NFT
			if pinnacleNFTRef == nil{ 
				return false
			}
			return (pinnacleNFTRef!).isLocked()
		}
		return false
	}
	
	init(){} 
}
