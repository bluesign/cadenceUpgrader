import MessageCard from "../0xf38fadaba79009cc/MessageCard.cdc"

access(all)
contract EmaShowcase{ 
	access(all)
	struct Ema{ 
		access(all)
		let id: UInt64
		
		access(all)
		let owner: Address
		
		init(id: UInt64, owner: Address){ 
			self.id = id
			self.owner = owner
		}
	}
	
	access(account)
	var emas: [Ema]
	
	access(account)
	var exists:{ UInt64: Bool}
	
	access(account)
	var max: Int
	
	access(account)
	var paused: Bool
	
	access(account)
	var allowedTemplateIds:{ UInt64: Bool}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateMax(max: Int){ 
			EmaShowcase.max = max
			while EmaShowcase.emas.length > EmaShowcase.max{ 
				let lastEma = EmaShowcase.emas.removeLast()
				EmaShowcase.exists.remove(key: lastEma.id)
			}
		}
		
		access(all)
		fun updatePaused(paused: Bool){ 
			EmaShowcase.paused = paused
		}
		
		access(all)
		fun addAllowedTemplateId(templateId: UInt64){ 
			EmaShowcase.allowedTemplateIds[templateId] = true
		}
		
		access(all)
		fun removeAllowedTemplateId(templateId: UInt64){ 
			EmaShowcase.allowedTemplateIds.remove(key: templateId)
		}
		
		access(all)
		fun clearEmas(){ 
			EmaShowcase.emas = []
			EmaShowcase.exists ={} 
		}
	}
	
	access(all)
	fun addEma(id: UInt64, collectionCapability: Capability<&MessageCard.Collection>){ 
		pre{ 
			!EmaShowcase.paused:
				"Paused"
			!EmaShowcase.exists.containsKey(id):
				"Already Existing"
			collectionCapability.borrow()?.borrowMessageCard(id: id) != nil:
				"Not Found"
			EmaShowcase.allowedTemplateIds.containsKey(((collectionCapability.borrow()!).borrowMessageCard(id: id)!).templateId):
				"Not Allowed Template"
		}
		EmaShowcase.emas.insert(at: 0, Ema(id: id, owner: collectionCapability.address))
		EmaShowcase.exists[id] = true
		if EmaShowcase.emas.length > EmaShowcase.max{ 
			let lastEma = EmaShowcase.emas.removeLast()
			EmaShowcase.exists.remove(key: lastEma.id)
		}
	}
	
	access(all)
	fun getEmas(from: Int, upTo: Int): [Ema]{ 
		if from >= EmaShowcase.emas.length{ 
			return []
		}
		if upTo >= EmaShowcase.emas.length{ 
			return EmaShowcase.emas.slice(from: from, upTo: EmaShowcase.emas.length - 1)
		}
		return EmaShowcase.emas.slice(from: from, upTo: upTo)
	}
	
	init(){ 
		self.emas = []
		self.exists ={} 
		self.max = 1000
		self.paused = false
		self.allowedTemplateIds ={} 
		self.account.storage.save(<-create Admin(), to: /storage/EmaShowcaseAdmin)
	}
}
