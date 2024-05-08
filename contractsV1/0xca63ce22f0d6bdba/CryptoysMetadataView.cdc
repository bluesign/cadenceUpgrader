access(all)
contract CryptoysMetadataView{ 
	access(all)
	struct Cryptoy{ 
		access(all)
		let name: String?
		
		access(all)
		let description: String?
		
		access(all)
		let image: String?
		
		access(all)
		let coreImage: String?
		
		access(all)
		let video: String?
		
		access(all)
		let platformId: String?
		
		access(all)
		let category: String?
		
		access(all)
		let type: String?
		
		access(all)
		let skin: String?
		
		access(all)
		let tier: String?
		
		access(all)
		let rarity: String?
		
		access(all)
		let edition: String?
		
		access(all)
		let series: String?
		
		access(all)
		let legionId: String?
		
		access(all)
		let creator: String?
		
		access(all)
		let packaging: String?
		
		access(all)
		let termsUrl: String?
		
		init(
			name: String?,
			description: String?,
			image: String?,
			coreImage: String?,
			video: String?,
			platformId: String?,
			category: String?,
			type: String?,
			skin: String?,
			tier: String?,
			rarity: String?,
			edition: String?,
			series: String?,
			legionId: String?,
			creator: String?,
			packaging: String?,
			termsUrl: String?
		){ 
			self.name = name
			self.description = description
			self.image = image
			self.coreImage = coreImage
			self.video = video
			self.platformId = platformId
			self.category = category
			self.type = type
			self.skin = skin
			self.tier = tier
			self.rarity = rarity
			self.edition = edition
			self.series = series
			self.legionId = legionId
			self.creator = creator
			self.packaging = packaging
			self.termsUrl = termsUrl
		}
	}
}
