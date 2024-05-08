access(all)
contract StarlyRoyalties{ 
	access(all)
	struct Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let cut: UFix64
		
		init(address: Address, cut: UFix64){ 
			self.address = address
			self.cut = cut
		}
	}
	
	access(all)
	var starlyRoyalty: Royalty
	
	access(contract)
	let collectionRoyalties:{ String: Royalty}
	
	access(contract)
	let minterRoyalties:{ String:{ String: Royalty}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let EditorStoragePath: StoragePath
	
	access(all)
	let EditorProxyStoragePath: StoragePath
	
	access(all)
	let EditorProxyPublicPath: PublicPath
	
	access(all)
	fun getRoyalties(collectionID: String, starlyID: String): [Royalty]{ 
		let royalties = [self.starlyRoyalty]
		if let collectionRoyalty = self.collectionRoyalties[collectionID]{ 
			royalties.append(collectionRoyalty)
		}
		if let minterRoyaltiesForCollection = self.minterRoyalties[collectionID]{ 
			if let minterRoyalty = minterRoyaltiesForCollection[starlyID]{ 
				royalties.append(minterRoyalty)
			}
		}
		return royalties
	}
	
	access(all)
	fun getStarlyRoyalty(): Royalty{ 
		return self.starlyRoyalty
	}
	
	access(all)
	fun getCollectionRoyalty(collectionID: String): Royalty?{ 
		return self.collectionRoyalties[collectionID]
	}
	
	access(all)
	fun getMinterRoyalty(collectionID: String, starlyID: String): Royalty?{ 
		if let minterRoyaltiesForCollection = self.minterRoyalties[collectionID]{ 
			return minterRoyaltiesForCollection[starlyID]
		}
		return nil
	}
	
	access(all)
	resource interface IEditor{ 
		access(all)
		fun setStarlyRoyalty(address: Address, cut: UFix64)
		
		access(all)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64)
		
		access(all)
		fun deleteCollectionRoyalty(collectionID: String)
		
		access(all)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64)
		
		access(all)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String)
	}
	
	access(all)
	resource Editor: IEditor{ 
		access(all)
		fun setStarlyRoyalty(address: Address, cut: UFix64){ 
			StarlyRoyalties.starlyRoyalty = Royalty(address: address, cut: cut)
		}
		
		access(all)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64){ 
			StarlyRoyalties.collectionRoyalties.insert(key: collectionID, Royalty(address: address, cut: cut))
		}
		
		access(all)
		fun deleteCollectionRoyalty(collectionID: String){ 
			StarlyRoyalties.collectionRoyalties.remove(key: collectionID)
		}
		
		access(all)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64){ 
			if !StarlyRoyalties.minterRoyalties.containsKey(collectionID){ 
				StarlyRoyalties.minterRoyalties.insert(key: collectionID,{ starlyID: Royalty(address: address, cut: cut)})
			} else{ 
				(StarlyRoyalties.minterRoyalties[collectionID]!).insert(key: starlyID, Royalty(address: address, cut: cut))
			}
		}
		
		access(all)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String){ 
			StarlyRoyalties.minterRoyalties[collectionID]?.remove(key: starlyID)
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
		fun setStarlyRoyalty(address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setStarlyRoyalty(address: address, cut: cut)
		}
		
		access(all)
		fun setCollectionRoyalty(collectionID: String, address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setCollectionRoyalty(collectionID: collectionID, address: address, cut: cut)
		}
		
		access(all)
		fun deleteCollectionRoyalty(collectionID: String){ 
			((self.editorCapability!).borrow()!).deleteCollectionRoyalty(collectionID: collectionID)
		}
		
		access(all)
		fun setMinterRoyalty(collectionID: String, starlyID: String, address: Address, cut: UFix64){ 
			((self.editorCapability!).borrow()!).setMinterRoyalty(collectionID: collectionID, starlyID: starlyID, address: address, cut: cut)
		}
		
		access(all)
		fun deleteMinterRoyalty(collectionID: String, starlyID: String){ 
			((self.editorCapability!).borrow()!).deleteMinterRoyalty(collectionID: collectionID, starlyID: starlyID)
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
		self.starlyRoyalty = Royalty(address: 0x12c122ca9266c278, cut: 0.05)
		self.collectionRoyalties ={} 
		self.minterRoyalties ={} 
		self.AdminStoragePath = /storage/starlyRoyaltiesAdmin
		self.EditorStoragePath = /storage/starlyRoyaltiesEditor
		self.EditorProxyPublicPath = /public/starlyRoyaltiesEditorProxy
		self.EditorProxyStoragePath = /storage/starlyRoyaltiesEditorProxy
		let admin <- create Admin()
		let editor <- admin.createNewEditor()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-editor, to: self.EditorStoragePath)
	}
}
