import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

import ContractVersion from "../0xb223b2bfe4b8ffb5/ContractVersion.cdc"

import MotoGPRegistry from "./MotoGPRegistry.cdc"

// Contract to hold Metadata for MotoGPCards. Metadata is accessed using the Card's cardID (not the Card's id)
//
access(all)
contract MotoGPCardMetadata: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.4"
	}
	
	//////////////////////////////////
	// MotoGPCard MetadataViews implementation
	//////////////////////////////////
	access(all)
	struct Rider{ 
		access(all)
		let name: String
		
		access(all)
		let bike: String
		
		access(all)
		let team: String
		
		access(all)
		let number: String
		
		init(name: String, bike: String, team: String, number: String){ 
			self.name = name
			self.bike = bike
			self.team = team
			self.number = number
		}
	}
	
	access(all)
	struct Riders{ 
		access(all)
		let riders: [Rider]
		
		init(riders: [Rider]){ 
			self.riders = riders
		}
	}
	
	// The getRider method is the equivalent of the MetadataViews.get{ViewName} methods 
	// to get the custom Riders view by supplying a card reference as argument
	// 
	access(all)
	fun getRiders(_ viewResolver: &{ViewResolver.Resolver}): Riders?{ 
		if let view = viewResolver.resolveView(Type<Riders>()){ 
			if let v = view as? Riders{ 
				return v
			}
		}
		return nil
	}
	
	access(contract)
	fun resolveDisplayView(cardID: UInt64): MetadataViews.Display{ 
		let metadata = self.metadatas[cardID]!
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
		return MetadataViews.ExternalURL("https://motogp-ignition.com/nft/card/".concat(id.toString()))
	}
	
	access(contract)
	fun resolveNFTCollectionDisplayView(): MetadataViews.NFTCollectionDisplay{ 
		let socials:{ String: MetadataViews.ExternalURL} ={} 
		socials.insert(key: "twitter", MetadataViews.ExternalURL("https://twitter.com/MotoGPIgnition"))
		let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.motogp-ignition.com/MGPI-card-Square.jpg"), mediaType: "image/jpeg")
		let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.motogp-ignition.com/MGPI-card-Banner.jpg"), mediaType: "image/jpeg")
		return MetadataViews.NFTCollectionDisplay(name: "MotoGPCard", description: "MotoGP Ignition is an NFT collection for MotoGP enthusiasts", externalURL: MetadataViews.ExternalURL("https://motogp-ignition.com"), squareImage: squareMedia, bannerImage: bannerMedia, socials: socials)
	}
	
	access(contract)
	fun resolveMediasView(cardID: UInt64): MetadataViews.Medias{ 
		let metadata = self.metadatas[cardID]!
		var imageUrl: String = metadata.imageUrl
		var videoUrl: String = metadata.data["videoUrl"]!
		var thumbnailVideoUrl: String = metadata.data["thumbnailVideoUrl"]!
		let medias: [MetadataViews.Media] = []
		medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: imageUrl), mediaType: "image/png"))
		medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: videoUrl), mediaType: "video/mp4"))
		medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: thumbnailVideoUrl), mediaType: "video/mp4"))
		return MetadataViews.Medias(medias)
	}
	
	access(contract)
	fun resolveTraitsView(cardID: UInt64): MetadataViews.Traits{ 
		let metadata = self.metadatas[cardID]!
		let traits = MetadataViews.Traits([])
		for key in metadata.data.keys{ 
			if key != "id" && key != "name" && key != "description" && key != "imageUrl" && key != "videoUrl" && key != "thumbnailVideoUrl"{ 
				let trait = MetadataViews.Trait(name: key, value: metadata.data[key], displayType: nil, rarity: nil)
				traits.addTrait(trait)
			}
		}
		return traits
	}
	
	access(contract)
	fun resolveRidersView(cardID: UInt64): Riders{ 
		let riders: [Rider] = []
		let metadata = self.metadatas[cardID]!
		var riderIndex = 1
		for key in metadata.data.keys{ 
			let riderKey = "rider_".concat(riderIndex.toString())
			let riderName = metadata.data[riderKey]
			if riderName == nil{ 
				break
			} else{ 
				let riderBike = metadata.data[riderKey.concat("_bike")] ?? ""
				let riderTeam = metadata.data[riderKey.concat("_team")] ?? ""
				let riderNumber = metadata.data[riderKey.concat("_number")] ?? ""
				riders.append(Rider(name: riderName!, bike: riderBike, team: riderTeam, number: riderNumber))
				riderIndex = riderIndex + 1
			}
		}
		return Riders(riders: riders)
	}
	
	access(all)
	fun resolveView(view: Type, id: UInt64, cardID: UInt64, serial: UInt64, publicCollectionType: Type, publicLinkedType: Type, providerLinkedType: Type, createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}): AnyStruct?{ 
		switch view{ 
			case Type<MotoGPCardMetadata.Riders>():
				return self.resolveRidersView(cardID: cardID)
			case Type<MetadataViews.Traits>():
				return self.resolveTraitsView(cardID: cardID)
			case Type<MetadataViews.Display>():
				return self.resolveDisplayView(cardID: cardID)
			case Type<MetadataViews.Royalties>():
				return self.resolveRoyaltiesView()
			case Type<MetadataViews.ExternalURL>():
				return self.resolveExternalURLView(id: id)
			case Type<MetadataViews.Medias>():
				return self.resolveMediasView(cardID: cardID)
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.resolveNFTCollectionDisplayView()
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: StoragePath(identifier: "motogpCardCollection")!, publicPath: PublicPath(identifier: "motogpCardCollection")!, publicCollection: publicCollectionType, publicLinkedType: publicLinkedType, createEmptyCollectionFunction: createEmptyCollectionFunction)
		}
		return nil
	}
	
	/////////////////////////////////////////////////////////////////////////////////
	// MotoGPCard Legacy Metadata Implementation (kept for compatibility purposes)
	////////////////////////////////////////////////////////////////////////////////
	access(all)
	struct Metadata{ 
		access(all)
		let cardID: UInt64
		
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
		
		init(_cardID: UInt64, _name: String, _description: String, _imageUrl: String, _data:{ String: String}){ 
			pre{ 
				!_data.containsKey("name"):
					"data dictionary contains 'name' key"
				!_data.containsKey("description"):
					"data dictionary contains 'description' key"
				!_data.containsKey("imageUrl"):
					"data dictionary contains 'imageUrl' key"
			}
			self.cardID = _cardID
			self.name = _name
			self.description = _description
			self.imageUrl = _imageUrl
			self.data = _data
		}
	}
	
	//Dictionary to hold all metadata with cardID as key
	//
	access(self)
	let metadatas:{ UInt64: MotoGPCardMetadata.Metadata}
	
	// Get all metadatas
	//
	access(all)
	fun getMetadatas():{ UInt64: MotoGPCardMetadata.Metadata}{ 
		return self.metadatas
	}
	
	access(all)
	fun getMetadatasCount(): UInt64{ 
		return UInt64(self.metadatas.length)
	}
	
	//Get metadata for a specific cardID
	//
	access(all)
	fun getMetadataForCardID(cardID: UInt64): MotoGPCardMetadata.Metadata?{ 
		return self.metadatas[cardID]
	}
	
	//Access to set metadata is controlled using an Admin reference as argument
	//
	access(all)
	fun setMetadata(adminRef: &MotoGPAdmin.Admin, cardID: UInt64, name: String, description: String, imageUrl: String, data:{ String: String}){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		let metadata = Metadata(_cardID: cardID, _name: name, _description: description, _imageUrl: imageUrl, _data: data)
		self.metadatas[cardID] = metadata
	}
	
	//Remove metadata by cardID
	//
	access(all)
	fun removeMetadata(adminRef: &MotoGPAdmin.Admin, cardID: UInt64){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		self.metadatas.remove(key: cardID)
	}
	
	init(){ 
		self.metadatas ={} 
	}
}
