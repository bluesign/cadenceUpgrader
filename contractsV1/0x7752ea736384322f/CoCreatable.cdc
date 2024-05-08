// A CoCreatable contract is one where the user combines characteristics
// to create an NFT. The contract should employ a set of dictionaries
// at the top that provide the set from which the user can select the 
// characteristics
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface CoCreatable{ 
	
	// The contract should have a dictionary of id to characteristic:
	// eg access(contract) var garmentDatas: {UInt64: Characteristic}
	// Dict not defined in the interface to provide flexibility to the contract
	
	// {concat of combined characteristics: nftId}
	// eg {materialDataId_garmentDataId_primaryColour_secondary_colour: 1}
	access(contract)
	var dataAllocations:{ String: UInt64}
	
	access(all)
	fun getDataAllocations():{ String: UInt64}
	
	access(all)
	resource interface CoCreatableNFT{ 
		access(all)
		fun getCharacteristics():{ String:{ Characteristic}}?
	}
	
	access(all)
	struct interface Characteristic{ 
		access(all)
		var id: UInt64
		
		// Used to inform the BE in case the struct changes
		access(all)
		var version: UFix64
		
		// This is the name that will be used for the Trait, so 
		// will be displayed on external MPs etc. Should be capitalised
		// and spaced eg "Shoe Shape Name"
		access(all)
		var traitName: String
		
		// eg characteristicType = garment
		access(all)
		var characteristicType: String
		
		access(all)
		var characteristicDescription: String
		
		// designerName, desc and address are nil if the Characteristic
		// doesnt have one eg a primaryColor
		access(all)
		var designerName: String?
		
		access(all)
		var designerDescription: String?
		
		access(all)
		var designerAddress: Address?
		
		// Value is the name of the selected characteristic
		// For example, for a garment, this might be "Adventurer Top"
		access(all)
		var value: AnyStruct
		
		access(all)
		var rarity: MetadataViews.Rarity?
		
		access(contract)
		fun updateCharacteristic(key: String, value: AnyStruct)
		
		//Helper function that converts the characteristics to traits
		access(all)
		fun convertToTraits(): [MetadataViews.Trait]
		
		// Helper function that can return the media associated with this characteristic.
		// Not all characteristics will have media. For example, this would return the png associated with a garment
		access(all)
		fun getMedia(): AnyStruct?
	}
}
