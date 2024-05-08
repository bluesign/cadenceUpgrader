import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyCollectorScore from "./StarlyCollectorScore.cdc"

import StarlyMetadataViews from "./StarlyMetadataViews.cdc"

import StarlyIDParser from "./StarlyIDParser.cdc"

access(all)
contract StarlyMetadata{ 
	access(all)
	struct CollectionMetadata{ 
		access(all)
		let collection: StarlyMetadataViews.Collection
		
		access(all)
		let cards:{ UInt32: StarlyMetadataViews.Card}
		
		init(
			collection: StarlyMetadataViews.Collection,
			cards:{ 
				UInt32: StarlyMetadataViews.Card
			}
		){ 
			self.collection = collection
			self.cards = cards
		}
		
		access(all)
		fun insertCard(cardID: UInt32, card: StarlyMetadataViews.Card){ 
			self.cards.insert(key: cardID, card)
		}
		
		access(all)
		fun removeCard(cardID: UInt32){ 
			self.cards.remove(key: cardID)
		}
	}
	
	access(contract)
	var metadata:{ String: CollectionMetadata}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(all)
	fun getViews(): [Type]{ 
		return [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Edition>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.Traits>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<StarlyMetadataViews.CardEdition>()
		]
	}
	
	access(all)
	fun resolveView(starlyID: String, view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.Display>():
				return self.getDisplay(starlyID: starlyID)
			case Type<MetadataViews.Edition>():
				return self.getEdition(starlyID: starlyID)
			case Type<MetadataViews.Royalties>():
				return self.getRoyalties(starlyID: starlyID)
			case Type<MetadataViews.ExternalURL>():
				return self.getExternalURL(starlyID: starlyID)
			case Type<MetadataViews.Traits>():
				return self.getTraits(starlyID: starlyID)
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.getNFTCollectionDisplay()
			// case Type<MetadataViews.NFTCollectionData>(): implemented in StarlytCard
			case Type<StarlyMetadataViews.CardEdition>():
				return self.getCardEdition(starlyID: starlyID)
		}
		return nil
	}
	
	access(all)
	fun getDisplay(starlyID: String): MetadataViews.Display?{ 
		if let cardEdition = self.getCardEdition(starlyID: starlyID){ 
			let card = cardEdition.card
			let title = card.title
			let edition = cardEdition.edition.toString()
			let editions = card.editions.toString()
			let creatorName = cardEdition.collection.creator.name
			var thumbnail: String? = ""
			let mediaSize = cardEdition.card.mediaSizes[0]
			if mediaSize.screenshot != nil{ 
				thumbnail = mediaSize.screenshot
			} else{ 
				thumbnail = mediaSize.url
			}
			return MetadataViews.Display(name: title.concat(" #").concat(edition).concat("/").concat(editions).concat(" by ").concat(creatorName), description: cardEdition.card.description, thumbnail: MetadataViews.HTTPFile(url: thumbnail!))
		}
		return nil
	}
	
	access(all)
	fun getEdition(starlyID: String): MetadataViews.Edition?{ 
		if let cardEdition = self.getCardEdition(starlyID: starlyID){ 
			let card = cardEdition.card
			let edition = cardEdition.edition
			let editions = card.editions
			return MetadataViews.Edition(name: "Card", number: UInt64(edition), max: UInt64(editions))
		}
		return nil
	}
	
	access(all)
	fun getRoyalties(starlyID: String): MetadataViews.Royalties?{ 
		if let cardEdition = self.getCardEdition(starlyID: starlyID){ 
			let creator = cardEdition.collection.creator
			// TODO link and use getRoyaltyReceiverPublicPath
			let royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: getAccount(0x12c122ca9266c278).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Starly royalty (5%)"), MetadataViews.Royalty(receiver: getAccount(creator.address!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Creator royalty (%5) for ".concat(creator.username))]
			return MetadataViews.Royalties(royalties)
		}
		return nil
	}
	
	access(all)
	fun getExternalURL(starlyID: String): MetadataViews.ExternalURL?{ 
		if let cardEdition = self.getCardEdition(starlyID: starlyID){ 
			return MetadataViews.ExternalURL(cardEdition.url)
		}
		return nil
	}
	
	access(all)
	fun getTraits(starlyID: String): MetadataViews.Traits?{ 
		if let cardEdition = self.getCardEdition(starlyID: starlyID){ 
			let collection = cardEdition.collection
			let creator = collection.creator
			let card = cardEdition.card
			return MetadataViews.Traits([MetadataViews.Trait(name: "Name", value: card.title, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Description", value: card.description, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Rarity", value: card.rarity, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Collection (Name)", value: collection.title, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Collection (URL)", value: collection.url, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Creator (Name)", value: creator.name, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Creator (Username)", value: creator.username, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Creator (URL)", value: creator.url, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Collector Score", value: cardEdition.score ?? 0.0, displayType: "Numeric", rarity: nil), MetadataViews.Trait(name: "URL", value: cardEdition.url, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Preview URL", value: cardEdition.previewUrl, displayType: "String", rarity: nil)])
		}
		return nil
	}
	
	access(all)
	fun getNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
		return MetadataViews.NFTCollectionDisplay(
			name: "Starly",
			description: "Starly is a launchpad and marketplace for gamified NFT collections on Flow.",
			externalURL: MetadataViews.ExternalURL("https://starly.io"),
			squareImage: MetadataViews.Media(
				file: MetadataViews.HTTPFile(
					url: "https://storage.googleapis.com/starly-prod.appspot.com/assets/starly-square-logo.jpg"
				),
				mediaType: "image/jpeg"
			),
			bannerImage: MetadataViews.Media(
				file: MetadataViews.HTTPFile(
					url: "https://storage.googleapis.com/starly-prod.appspot.com/assets/starly-banner.jpg"
				),
				mediaType: "image/jpeg"
			),
			socials:{ 
				"twitter": MetadataViews.ExternalURL("https://twitter.com/StarlyNFT"),
				"discord": MetadataViews.ExternalURL("https://discord.gg/starly"),
				"medium": MetadataViews.ExternalURL("https://medium.com/@StarlyNFT")
			}
		)
	}
	
	access(all)
	fun getCardEdition(starlyID: String): StarlyMetadataViews.CardEdition?{ 
		let starlyID = StarlyIDParser.parse(starlyID: starlyID)
		let collectionMetadataOptional = self.metadata[starlyID.collectionID]
		if let collectionMetadata = collectionMetadataOptional{ 
			let cardOptional = collectionMetadata.cards[starlyID.cardID]
			if let card = cardOptional{ 
				return StarlyMetadataViews.CardEdition(collection: collectionMetadata.collection, card: card, edition: starlyID.edition, score: StarlyCollectorScore.getCollectorScore(collectionID: starlyID.collectionID, rarity: card.rarity, edition: starlyID.edition, editions: card.editions, priceCoefficient: collectionMetadata.collection.priceCoefficient), url: card.url.concat("/").concat(starlyID.edition.toString()), previewUrl: card.previewUrl.concat("/").concat(starlyID.edition.toString()))
			}
		}
		return nil
	}
	
	access(all)
	resource interface IEditor{ 
		access(all)
		fun putCollectionCard(collectionID: String, cardID: UInt32, card: StarlyMetadataViews.Card)
		
		access(all)
		fun putMetadata(collectionID: String, metadata: CollectionMetadata)
		
		access(all)
		fun deleteCollectionCard(collectionID: String, cardID: UInt32)
		
		access(all)
		fun deleteMetadata(collectionID: String)
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(all)
		fun putCollectionCard(collectionID: String, cardID: UInt32, card: StarlyMetadataViews.Card){ 
			StarlyMetadata.metadata[collectionID]?.insertCard(cardID: cardID, card: card)
		}
		
		access(all)
		fun putMetadata(collectionID: String, metadata: CollectionMetadata){ 
			StarlyMetadata.metadata.insert(key: collectionID, metadata)
		}
		
		access(all)
		fun deleteCollectionCard(collectionID: String, cardID: UInt32){ 
			StarlyMetadata.metadata[collectionID]?.removeCard(cardID: cardID)
		}
		
		access(all)
		fun deleteMetadata(collectionID: String){ 
			StarlyMetadata.metadata.remove(key: collectionID)
		}
	}
	
	access(all)
	resource interface EditorProxyPublic{ 
		access(all)
		fun setEditorCapability(cap: Capability<&Editor>)
	}
	
	access(all)
	resource EditorProxy: IEditor, EditorProxyPublic{ 
		access(self)
		var editorCapability: Capability<&Editor>?
		
		access(all)
		fun setEditorCapability(cap: Capability<&Editor>){ 
			self.editorCapability = cap
		}
		
		access(all)
		fun putCollectionCard(collectionID: String, cardID: UInt32, card: StarlyMetadataViews.Card){ 
			((self.editorCapability!).borrow()!).putCollectionCard(collectionID: collectionID, cardID: cardID, card: card)
		}
		
		access(all)
		fun putMetadata(collectionID: String, metadata: CollectionMetadata){ 
			((self.editorCapability!).borrow()!).putMetadata(collectionID: collectionID, metadata: metadata)
		}
		
		access(all)
		fun deleteCollectionCard(collectionID: String, cardID: UInt32){ 
			((self.editorCapability!).borrow()!).deleteCollectionCard(collectionID: collectionID, cardID: cardID)
		}
		
		access(all)
		fun deleteMetadata(collectionID: String){ 
			((self.editorCapability!).borrow()!).deleteMetadata(collectionID: collectionID)
		}
		
		init(){ 
			self.editorCapability = nil
		}
	}
	
	access(all)
	fun createEditorProxy(): @EditorProxy{ 
		return <-create EditorProxy()
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createNewEditor(): @Editor{ 
			return <-create Editor()
		}
	}
	
	init(){ 
		self.metadata ={} 
		self.AdminStoragePath = /storage/starlyMetadataAdmin
		self.EditorStoragePath = /storage/starlyMetadataEditor
		self.EditorProxyPublicPath = /public/starlyMetadataEditorProxy
		self.EditorProxyStoragePath = /storage/starlyMetadataEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
	}
}
