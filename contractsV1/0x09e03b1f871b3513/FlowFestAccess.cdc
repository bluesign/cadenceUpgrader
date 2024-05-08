/*
	Description: FlowFestAccess Contract
   
	This contract allows users to redeem their FlowFest NFTs to gain access to thefabricant.studio
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TheFabricantMysteryBox_FF1 from "../0xa0cbe021821c0965/TheFabricantMysteryBox_FF1.cdc"

access(all)
contract FlowFestAccess{ 
	
	// -----------------------------------------------------------------------
	// FlowFestAccess contract Events
	// -----------------------------------------------------------------------
	access(all)
	event AccountVerified(address: Address, id: UInt64)
	
	access(self)
	var accountsVerified:{ Address: UInt64}
	
	//redeem a flowfest nft by adding it into accountsVerified mapping if not already
	access(all)
	fun giveAccess(
		id: UInt64,
		collectionCap: Capability<&{TheFabricantMysteryBox_FF1.FabricantCollectionPublic}>
	){ 
		pre{ 
			FlowFestAccess.isAccountVerified(address: collectionCap.address) == false:
				"account already has access"
			!FlowFestAccess.accountsVerified.values.contains(id):
				"id is already used"
		}
		let collection = collectionCap.borrow()!
		// get the ids of the flowfest nfts that the collection contains
		let ids = collection.getIDs()
		// check that collection actually contains nft with that id
		if ids.contains(id){ 
			//verify account and store in dictionary
			FlowFestAccess.accountsVerified[collectionCap.address] = id
			emit AccountVerified(address: collectionCap.address, id: id)
		} else{ 
			panic("user does not have nft with this id")
		}
	}
	
	// get dictionary of accounts that are verified and the id
	// of the flowfest nft that it used
	access(all)
	fun getAccountsVerified():{ Address: UInt64}{ 
		return FlowFestAccess.accountsVerified
	}
	
	// check if account is already verified
	access(all)
	view fun isAccountVerified(address: Address): Bool{ 
		for key in FlowFestAccess.accountsVerified.keys{ 
			if key == address{ 
				return true
			}
		}
		return false
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.accountsVerified ={} 
	}
}
