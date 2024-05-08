import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

import ContractVersion from "../0xb223b2bfe4b8ffb5/ContractVersion.cdc"

import MotoGPRegistry from 0xa49cc0ee46c54bfb

// Contract to hold Metadata for MotoGPPacks. Metadata is accessed using the Pack's packID (not the Pack's id)
//
access(all)
contract MotoGPPackMetadata: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.2"
	}
	
	//////////////////////////////////
	// MotoGPPack MetadataViews implementation
	//////////////////////////////////
	access(contract)
	fun resolveDisplayView(packID: UInt64): MetadataViews.Display{ 
		let metadata = self.metadatas[packID]!
		return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.HTTPFile(url: metadata.imageUrl))
	}
	
	access(contract)
	fun resolveRoyaltiesView(): MetadataViews.Royalties{ 
		var royaltyList: [MetadataViews.Royalty] = []
		let capability = getAccount(MotoGPRegistry.get(key: "motogp-royalty-receiver")! as! Address).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
		let royalty: MetadataViews.Royalty = MetadataViews.Royalty(receiver: capability!, cut: 0.075, description: "Creator royalty")
		royaltyList.append(royalty)
		return MetadataViews.Royalties(royaltyList)
	}
	
	access(contract)
	fun resolveExternalURLView(id: UInt64): MetadataViews.ExternalURL{ 
		return MetadataViews.ExternalURL("https://motogp-ignition.com/nft/pack/".concat(id.toString()))
	}
	
	access(contract)
	fun resolveNFTCollectionDisplayView(): MetadataViews.NFTCollectionDisplay{ 
		let socials:{ String: MetadataViews.ExternalURL} ={} 
		socials.insert(key: "twitter", MetadataViews.ExternalURL("https://twitter.com/MotoGPIgnition"))
		let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs-assets.animocabrands.com/MGPI-pack-Square.jpg"), mediaType: "image/jpeg")
		let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs-assets.animocabrands.com/MGPI-pack-Banner.jpg"), mediaType: "image/jpeg")
		return MetadataViews.NFTCollectionDisplay(name: "MotoGPPack", description: "MotoGP Ignition is an NFT collection for MotoGP enthusiasts", externalURL: MetadataViews.ExternalURL("https://motogp-ignition.com"), squareImage: squareMedia, bannerImage: bannerMedia, socials: socials)
	}
	
	access(contract)
	fun resolveMediasView(packID: UInt64): MetadataViews.Medias{ 
		let metadata = self.metadatas[packID]!
		let imageUrl = metadata.imageUrl
		let medias: [MetadataViews.Media] = []
		medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: imageUrl), mediaType: "image/jpeg"))
		return MetadataViews.Medias(medias)
	}
	
	access(contract)
	fun resolveTraitsView(packID: UInt64): MetadataViews.Traits{ 
		let metadata = self.metadatas[packID]!
		let traits = MetadataViews.Traits([])
		for key in metadata.data.keys{ 
			if key != "id" && key != "name" && key != "description" && key != "imageUrl" && key != "videoUrl" && key != "thumbnailVideoUrl"{ 
				let trait = MetadataViews.Trait(name: key, value: metadata.data[key], displayType: nil, rarity: nil)
				traits.addTrait(trait)
			}
		}
		return traits
	}
	
	access(all)
	fun resolveView(view: Type, id: UInt64, packID: UInt64, serial: UInt64, publicCollectionType: Type, publicLinkedType: Type, providerLinkedType: Type, createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.Traits>():
				return self.resolveTraitsView(packID: packID)
			case Type<MetadataViews.Display>():
				return self.resolveDisplayView(packID: packID)
			case Type<MetadataViews.Royalties>():
				return self.resolveRoyaltiesView()
			case Type<MetadataViews.ExternalURL>():
				return self.resolveExternalURLView(id: id)
			case Type<MetadataViews.Medias>():
				return self.resolveMediasView(packID: packID)
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.resolveNFTCollectionDisplayView()
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: StoragePath(identifier: "motogpPackCollection")!, publicPath: PublicPath(identifier: "motogpPackCollection")!, publicCollection: publicCollectionType, publicLinkedType: publicLinkedType, createEmptyCollectionFunction: createEmptyCollectionFunction)
		}
		return nil
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let packID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageUrl: String
		
		// data contains all 'other' metadata fields, e.g. videoUrl, team, etc
		//
		access(all)
		let data:{ String: String}
		
		init(_packID: UInt64, _name: String, _description: String, _imageUrl: String, _data:{ String: String}){ 
			pre{ 
				!_data.containsKey("name"):
					"data dictionary contains 'name' key"
				!_data.containsKey("description"):
					"data dictionary contains 'description' key"
				!_data.containsKey("imageUrl"):
					"data dictionary contains 'imageUrl' key"
			}
			self.packID = _packID
			self.name = _name
			self.description = _description
			self.imageUrl = _imageUrl
			self.data = _data
		}
	}
	
	//Dictionary to hold all metadata with packID as key
	//
	access(self)
	let metadatas:{ UInt64: MotoGPPackMetadata.Metadata}
	
	// Get all metadatas
	//
	access(all)
	fun getMetadatas():{ UInt64: MotoGPPackMetadata.Metadata}{ 
		return self.metadatas
	}
	
	access(all)
	fun getMetadatasCount(): UInt64{ 
		return UInt64(self.metadatas.length)
	}
	
	//Get metadata for a specific packID
	//
	access(all)
	fun getMetadataForPackID(packID: UInt64): MotoGPPackMetadata.Metadata?{ 
		return self.metadatas[packID]
	}
	
	//Access to set metadata is controlled using an Admin reference as argument
	//
	access(all)
	fun setMetadata(adminRef: &MotoGPAdmin.Admin, packID: UInt64, name: String, description: String, imageUrl: String, data:{ String: String}){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		let metadata = Metadata(_packID: packID, _name: name, _description: description, _imageUrl: imageUrl, _data: data)
		self.metadatas[packID] = metadata
	}
	
	//Remove metadata by packID
	//
	access(all)
	fun removeMetadata(adminRef: &MotoGPAdmin.Admin, packID: UInt64){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		self.metadatas.remove(key: packID)
	}
	
	init(){ 
		self.metadatas ={} 
	}
}
