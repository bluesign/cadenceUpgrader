import AFLNFT from "./AFLNFT.cdc"

import AFLPack from "./AFLPack.cdc"

import AFLBurnExchange from "./AFLBurnExchange.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import PackRestrictions from "./PackRestrictions.cdc"

access(all)
contract AFLAdmin{ 
	
	// Admin
	// the admin resource is defined so that only the admin account
	// can have this resource. It possesses the ability to open packs
	// given a user's Pack Collection and Card Collection reference.
	// It can also create a new pack type and mint Packs.
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createTemplate(maxSupply: UInt64, immutableData:{ String: AnyStruct}): UInt64{ 
			return AFLNFT.createTemplate(maxSupply: maxSupply, immutableData: immutableData)
		}
		
		access(all)
		fun updateImmutableData(templateID: UInt64, immutableData:{ String: AnyStruct}){ 
			let templateRef = &AFLNFT.allTemplates[templateID] as &AFLNFT.Template?
			templateRef?.updateImmutableData(immutableData) ?? panic("Template does not exist")
		}
		
		access(all)
		fun addRestrictedPack(id: UInt64){ 
			PackRestrictions.addPackId(id: id)
		}
		
		access(all)
		fun removeRestrictedPack(id: UInt64){ 
			PackRestrictions.removePackId(id: id)
		}
		
		access(all)
		fun openPack(templateInfo:{ String: UInt64}, account: Address){ 
			AFLNFT.mintNFT(templateInfo: templateInfo, account: account)
		}
		
		access(all)
		fun mintNFT(templateInfo:{ String: UInt64}): @{NonFungibleToken.NFT}{ 
			return <-AFLNFT.mintAndReturnNFT(templateInfo: templateInfo)
		}
		
		access(all)
		fun addTokenForExchange(nftId: UInt64, token: @{NonFungibleToken.NFT}){ 
			AFLBurnExchange.addTokenForExchange(nftId: nftId, token: <-token)
		}
		
		access(all)
		fun withdrawTokenFromBurnExchange(nftId: UInt64): @{NonFungibleToken.NFT}{ 
			return <-AFLBurnExchange.withdrawToken(nftId: nftId)
		}
		
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(all)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		init(){} 
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/AFLAdmin)
	}
}
