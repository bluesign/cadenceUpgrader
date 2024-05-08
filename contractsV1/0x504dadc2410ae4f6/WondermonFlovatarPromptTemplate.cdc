access(all)
contract WondermonFlovatarPromptTemplate{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event PromptTemplateSet(flovatarId: UInt64)
	
	access(all)
	event PromptTemplateRemoved(flovatarId: UInt64)
	
	access(all)
	event DefaultPromptTemplateSet()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	let promptTemplates:{ UInt64: String}
	
	access(all)
	var defaultPrompt: String
	
	access(all)
	resource Admin{ 
		access(all)
		fun setTemplate(flovatarId: UInt64, template: String){ 
			WondermonFlovatarPromptTemplate.promptTemplates.insert(key: flovatarId, template)
			emit PromptTemplateSet(flovatarId: flovatarId)
		}
		
		access(all)
		fun removeTemplate(flovatarId: UInt64){ 
			WondermonFlovatarPromptTemplate.promptTemplates.remove(key: flovatarId)
			emit PromptTemplateRemoved(flovatarId: flovatarId)
		}
		
		access(all)
		fun setDefaultTemplate(_ template: String){ 
			WondermonFlovatarPromptTemplate.defaultPrompt = template
			emit DefaultPromptTemplateSet()
		}
	}
	
	access(all)
	fun getPromptTemplate(flovatarId: UInt64): String{ 
		return self.promptTemplates[flovatarId] ?? self.defaultPrompt
	}
	
	init(){ 
		self.promptTemplates ={} 
		self.defaultPrompt = ""
		self.AdminStoragePath = /storage/WondermonFlovatarPromptTemplateAdmin
		self.AdminPublicPath = /public/WondermonFlovatarPromptTemplateAdmin
		self.AdminPrivatePath = /private/WondermonFlovatarPromptTemplateAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
