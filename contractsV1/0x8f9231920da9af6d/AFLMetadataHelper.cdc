access(all)
contract AFLMetadataHelper{ 
	access(contract)
	let metadataByTemplateId:{ UInt64:{ String: String}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	fun getMetadataForTemplate(id: UInt64):{ String: String}{ 
		if self.metadataByTemplateId[id] == nil{ 
			return{} 
		}
		return self.metadataByTemplateId[id]!
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateMetadataForTemplate(id: UInt64, metadata:{ String: String}){ 
			if AFLMetadataHelper.metadataByTemplateId[id] == nil{ 
				AFLMetadataHelper.metadataByTemplateId[id] ={} 
			}
			AFLMetadataHelper.metadataByTemplateId[id] = metadata
		}
		
		access(all)
		fun addMetadataToTemplate(id: UInt64, key: String, value: String){ 
			if AFLMetadataHelper.metadataByTemplateId[id] == nil{ 
				AFLMetadataHelper.metadataByTemplateId[id] ={} 
			}
			let templateRef =
				&AFLMetadataHelper.metadataByTemplateId[id]! as auth(Mutate) &{String: String}
			templateRef[key] = value
		}
		
		access(all)
		fun removeMetadataFromTemplate(id: UInt64, key: String){ 
			let templateRef =
				&AFLMetadataHelper.metadataByTemplateId[id]! as auth(Mutate) &{String: String}
			templateRef[key] = nil
		}
		
		access(all)
		fun removeAllExtendedMetadataFromTemplate(id: UInt64){ 
			AFLMetadataHelper.metadataByTemplateId[id] ={} 
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/AFLMetadataHelperAdmin
		self.metadataByTemplateId ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
