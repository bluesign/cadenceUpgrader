access(all)
contract StarlyMetadataViews{ 
	access(all)
	struct Creator{ 
		access(all)
		let id: String
		
		access(all)
		let name: String
		
		access(all)
		let username: String
		
		access(all)
		let address: Address?
		
		access(all)
		let url: String
		
		init(id: String, name: String, username: String, address: Address?, url: String){ 
			self.id = id
			self.name = name
			self.username = username
			self.address = address
			self.url = url
		}
	}
	
	access(all)
	struct Collection{ 
		access(all)
		let id: String
		
		access(all)
		let creator: Creator
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let priceCoefficient: UFix64
		
		access(all)
		let url: String
		
		init(
			id: String,
			creator: Creator,
			title: String,
			description: String,
			priceCoefficient: UFix64,
			url: String
		){ 
			self.id = id
			self.creator = creator
			self.title = title
			self.description = description
			self.priceCoefficient = priceCoefficient
			self.url = url
		}
	}
	
	access(all)
	struct Card{ 
		access(all)
		let id: UInt32
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let editions: UInt32
		
		access(all)
		let rarity: String
		
		access(all)
		let mediaType: String
		
		access(all)
		let mediaSizes: [MediaSize]
		
		access(all)
		let url: String
		
		access(all)
		let previewUrl: String
		
		init(
			id: UInt32,
			title: String,
			description: String,
			editions: UInt32,
			rarity: String,
			mediaType: String,
			mediaSizes: [
				MediaSize
			],
			url: String,
			previewUrl: String
		){ 
			self.id = id
			self.title = title
			self.description = description
			self.editions = editions
			self.rarity = rarity
			self.mediaType = mediaType
			self.mediaSizes = mediaSizes
			self.url = url
			self.previewUrl = previewUrl
		}
	}
	
	access(all)
	struct MediaSize{ 
		access(all)
		let width: UInt16
		
		access(all)
		let height: UInt16
		
		access(all)
		let url: String
		
		access(all)
		let screenshot: String?
		
		init(width: UInt16, height: UInt16, url: String, screenshot: String?){ 
			self.width = width
			self.height = height
			self.url = url
			self.screenshot = screenshot
		}
	}
	
	access(all)
	struct CardEdition{ 
		access(all)
		let collection: Collection
		
		access(all)
		let card: Card
		
		access(all)
		let edition: UInt32
		
		access(all)
		let score: UFix64?
		
		access(all)
		let url: String
		
		access(all)
		let previewUrl: String
		
		init(
			collection: Collection,
			card: Card,
			edition: UInt32,
			score: UFix64?,
			url: String,
			previewUrl: String
		){ 
			self.collection = collection
			self.card = card
			self.edition = edition
			self.score = score
			self.url = url
			self.previewUrl = previewUrl
		}
	}
}
