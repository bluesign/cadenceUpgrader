import FlowToken from "./../../standardsV1/FlowToken.cdc"

import DynamicImport from "./DynamicImport.cdc"

access(all)
contract Proxy_0x1654653399040a61{ 
	access(all)
	resource ContractObject: DynamicImport.ImportInterface{ 
		access(all)
		fun dynamicImport(name: String): &AnyStruct?{ 
			if name == "FlowToken"{ 
				return &FlowToken as &AnyStruct
			}
			return nil
		}
	}
	
	init(){ 
		self.account.storage.save(<-create ContractObject(), to: /storage/A0x1654653399040a61)
	}
}
