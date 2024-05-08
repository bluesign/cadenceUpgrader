// A CoCreatableV2 contract is one where the user combines characteristics
// to create an NFT. The contract should employ a set of dictionaries
// at the top that provide the set from which the user can select the 
// characteristics

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract interface CoCreatableV2 {

    // The contract should have a dictionary of id to characteristic:
    // eg access(contract) var garmentDatas: {UInt64: Characteristic}
    // Dict not defined in the interface to provide flexibility to the contract

    // {concat of combined characteristics: nftId}
    // eg {materialDataId_garmentDataId_primaryColour_secondary_colour: 1}
    access(contract) var dataAllocations: {String: UInt64}
    access(contract) var idsToDataAllocations: {UInt64: String}

    pub fun getDataAllocations(): {String: UInt64}

    pub fun getAllIdsToDataAllocations(): {UInt64: String}
    pub fun getIdToDataAllocation(id: UInt64): String

    

    pub resource interface CoCreatableNFT {
        pub fun getCharacteristics(): {String: {Characteristic}}?
    }

    pub struct interface Characteristic {
        pub var id: UInt64

        // Used to inform the BE in case the struct changes
        pub var version: UFix64

        // This is the name that will be used for the Trait, so 
        // will be displayed on external MPs etc. Should be capitalised
        // and spaced eg "Shoe Shape Name"
        pub var traitName: String
        // eg characteristicType = garment
        pub var characteristicType: String
        pub var characteristicDescription: String

        // designerName, desc and address are nil if the Characteristic
        // doesnt have one eg a primaryColor
        pub var designerName: String?
        pub var designerDescription: String?
        pub var designerAddress: Address?
        // Value is the name of the selected characteristic
        // For example, for a garment, this might be "Adventurer Top" or a hex code
        pub var value: AnyStruct
        pub var rarity: MetadataViews.Rarity?

        // The media files associated with the Characteristic, not all will have this property. These will very rarely be included as part of a trait. 
        pub var media: MetadataViews.Medias?

        access(contract) fun updateCharacteristic(key: String, value: AnyStruct)

        //Helper function that converts the characteristics to traits
        pub fun convertToTraits(): [MetadataViews.Trait]
    }

}
 