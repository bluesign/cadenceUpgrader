import Vevent from "./Vevent.cdc"

import Wearables from "../0xe81193c424cfd3fb/Wearables.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract VeventVerifiers{ 
	access(all)
	struct DoodlesSock: Vevent.Verifier{ 
		access(all)
		fun verify(user: Address): Bool{ 
			if let collection = getAccount(user).capabilities.get<&Wearables.Collection>(Wearables.CollectionPublicPath).borrow<&Wearables.Collection>(){ 
				for id in collection.getIDs(){ 
					let resolver = collection.borrowViewResolver(id: id)!
					let view = resolver.resolveView(Type<Wearables.Metadata>())! as! Wearables.Metadata
					let template = Wearables.templates[view.templateId]!
					let name = template.name
					if name == "crew socks"{ 
						return true
					}
				}
			}
			return false
		}
	}
}
