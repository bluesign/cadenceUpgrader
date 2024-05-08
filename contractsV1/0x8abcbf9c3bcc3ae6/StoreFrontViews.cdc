import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// TOKEN RUNNERS: Contract responsable for Default view
access(all)
contract StoreFrontViews{ 
	
	// Display is a basic view that includes the name, description,
	// thumbnail for an object and metadata as flexible field. Most objects should implement this view.
	//
	access(all)
	struct StoreFrontDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let metadata:{ String: String}
		
		init(
			name: String,
			description: String,
			thumbnail:{ MetadataViews.File},
			metadata:{ 
				String: String
			}
		){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
	}
}
