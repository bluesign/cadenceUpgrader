// SPDX-License-Identifier: MIT
// This contracts contains Metadata structs for Artwork metadata
access(all)
contract ArtworkMetadata{ 
	access(all)
	struct Creator{ 
		access(all)
		let name: String
		
		access(all)
		let bio: String
		
		// Creator Flow Address
		access(all)
		let address: Address
		
		// Link to Everbloom profile
		access(all)
		let externalLink: String?
		
		init(name: String, bio: String, address: Address, externalLink: String?){ 
			self.name = name
			self.bio = bio
			self.address = address
			self.externalLink = externalLink
		}
	}
	
	access(all)
	struct Attribute{ 
		access(all)
		let traitType: String
		
		access(all)
		let value: String
		
		init(traitType: String, value: String){ 
			self.traitType = traitType
			self.value = value
		}
	}
	
	access(all)
	struct Content{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// Link to the image
		access(all)
		let image: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let animation: String?
		
		// Link to Everbloom Post
		access(all)
		let externalLink: String?
		
		init(
			name: String,
			description: String,
			image: String,
			thumbnail: String,
			animation: String?,
			externalLink: String?
		){ 
			self.name = name
			self.description = description
			self.image = image
			self.thumbnail = thumbnail
			self.animation = animation
			self.externalLink = externalLink
		}
	}
}
