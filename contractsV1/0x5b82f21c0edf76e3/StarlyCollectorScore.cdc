access(all)
contract StarlyCollectorScore{ 
	access(all)
	struct Config{ 
		access(all)
		let editions: [[UInt32; 2]]
		
		access(all)
		let rest: UInt32
		
		access(all)
		let last: UInt32
		
		init(editions: [[UInt32; 2]], rest: UInt32, last: UInt32){ 
			self.editions = editions
			self.rest = rest
			self.last = last
		}
	}
	
	// configs by collection id (or 'default'), then by rarity
	access(contract)
	let configs:{ String:{ String: Config}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(all)
	fun getCollectorScore(
		collectionID: String,
		rarity: String,
		edition: UInt32,
		editions: UInt32,
		priceCoefficient: UFix64
	): UFix64?{ 
		let collectionConfig =
			self.configs[collectionID] ?? self.configs["default"] ?? panic("No score config found")
		let rarityConfig = collectionConfig[rarity] ?? panic("No rarity config")
		var editionScore: UInt32 = 0
		if edition == editions && edition != 1{ 
			editionScore = rarityConfig.last
		} else{ 
			for e in rarityConfig.editions{ 
				if edition <= e[0]{ 
					editionScore = e[1]
					break
				}
			}
		}
		if editionScore == 0{ 
			editionScore = rarityConfig.rest
		}
		return UFix64(editionScore) * priceCoefficient
	}
	
	access(all)
	resource interface IEditor{ 
		access(all)
		fun addCollectionConfig(collectionID: String, config:{ String: Config})
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(all)
		fun addCollectionConfig(collectionID: String, config:{ String: Config}){ 
			StarlyCollectorScore.configs[collectionID] = config
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
		fun addCollectionConfig(collectionID: String, config:{ String: Config}){ 
			((self.editorCapability!).borrow()!).addCollectionConfig(collectionID: collectionID, config: config)
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
		self.AdminStoragePath = /storage/starlyCollectorScoreAdmin
		self.EditorStoragePath = /storage/starlyCollectorScoreEditor
		self.EditorProxyPublicPath = /public/starlyCollectorScoreEditorProxy
		self.EditorProxyStoragePath = /storage/starlyCollectorScoreEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
		self.configs ={} 
	}
}
