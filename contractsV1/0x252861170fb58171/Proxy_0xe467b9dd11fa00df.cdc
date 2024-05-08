import FlowServiceAccount from "../0xe467b9dd11fa00df/FlowServiceAccount.cdc"

import DynamicImport from "./DynamicImport.cdc"

access(all)
contract Proxy_0xe467b9dd11fa00df{ 
	access(all)
	resource ContractObject: DynamicImport.ImportInterface{ 
		access(all)
		fun dynamicImport(name: String): &AnyStruct?{ 
			if name == "FlowServiceAccount"{ 
				return &FlowServiceAccount as &AnyStruct
			}
			return nil
		}
	}
	
	init(){ 
		self.account.storage.save(<-create ContractObject(), to: /storage/A0xe467b9dd11fa00df)
	}
}
