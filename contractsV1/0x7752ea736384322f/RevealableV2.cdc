// Description
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TheFabricantMetadataViewsV2 from "./TheFabricantMetadataViewsV2.cdc"

import CoCreatableV2 from "./CoCreatableV2.cdc"

access(all)
contract interface RevealableV2{ 
	
	// When an NFT is minted, its metadata is stored here
	access(contract)
	var nftMetadata:{ UInt64:{ RevealableMetadata}}
	
	access(all)
	fun getNftMetadatas():{ UInt64:{ RevealableMetadata}}
	
	// Mutable-Template based NFT Metadata.
	// Each time a revealable NFT is minted, a RevealableMetadata is created
	// and saved into the nftMetadata dictionary. This represents the
	// bare minimum a RevealableMetadata should implement
	access(all)
	struct interface RevealableMetadata{ 
		
		//NOTE: totalSupply value of attached NFT, therefore edition number. 
		// nfts are currently stored under their id in the collection, so
		// this should be used as the key for the nftMetadata dictionary as well
		// for consistency.
		access(all)
		let id: UInt64
		
		// NOTE: nftUuid is the uuid of the associated nft.
		access(all)
		let nftUuid: UInt64 // uuid of NFT
		
		
		// NOTE: Name of NFT. Will most likely be the last node in the collection value.
		// eg XXories Original.
		// Will be combined with the edition number on the application
		// Doesn't include the edition number.
		access(all)
		var name: String
		
		access(all)
		var description: String //Display
		
		
		// NOTE: Thumbnail, which is needed for the Display view, should be set using one of the
		// media properties
		//pub let thumbnail: String //Display
		access(all)
		let collection: String // Name of collection eg The Fabricant > Season 3 > Wholeland > XXories Originals
		
		
		// Stores the metadata associated with this particular creation
		// but is not part of a characteristic eg mainImage, video etc
		access(all)
		var metadata:{ String: AnyStruct}
		
		//These are the characteristics that the 
		access(all)
		var characteristics:{ String:{ CoCreatableV2.Characteristic}}
		
		// The numerical score of the rarity
		access(all)
		var rarity: UFix64?
		
		// Legendary, Epic, Rare, Uncommon, Common or any other string value
		access(all)
		var rarityDescription: String?
		
		// NOTE: Media is not implemented in the struct because MetadataViews.Medias
		// is not mutable, so can't be updated. In addition, each 
		// NFT collection might have a different number of image/video properties.
		// Instead, the NFT should implement a function that rolls up the props
		// into a MetadataViews.Medias struct
		//pub let media: MetadataViews.Medias //Media
		//URL to the collection page on the website
		access(all)
		let externalURL: MetadataViews.ExternalURL //ExternalURL
		
		
		access(all)
		let coCreatable: Bool
		
		access(all)
		let coCreator: Address
		
		// Nil if can't be revealed, otherwise set to true when revealed
		access(all)
		var isRevealed: Bool?
		
		// id and editionNumber might not be the same in the nft...
		access(all)
		let editionNumber: UInt64 //Edition
		
		
		access(all)
		let maxEditionNumber: UInt64?
		
		access(all)
		let royalties: MetadataViews.Royalties //Royalty
		
		
		access(all)
		let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
		
		access(contract)
		var revealableTraits:{ String: Bool}
		
		access(all)
		fun getRevealableTraits():{ String: Bool}
		
		// Called by the Admin to reveal the traits for this NFT.
		// Should contain a switch function that knows how to modify
		// the properties of this struct. Should check that the trait
		// being revealed is allowed to be modified.
		access(contract)
		fun revealTraits(traits: [{RevealableTrait}])
		
		access(contract)
		fun updateMetadata(key: String, value: AnyStruct)
		
		// Called by the nft owner to modify if a trait can be 
		// revealed or not - used to revoke admin access
		access(all)
		fun updateIsTraitRevealable(key: String, value: Bool)
		
		access(all)
		fun checkRevealableTrait(traitName: String): Bool?
	}
	
	access(all)
	struct interface RevealableTrait{ 
		access(all)
		let name: String
		
		access(all)
		let value: AnyStruct
	}
}
