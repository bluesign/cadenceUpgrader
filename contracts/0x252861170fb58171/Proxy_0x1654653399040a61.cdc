import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import DynamicImport from "./DynamicImport.cdc"

pub contract Proxy_0x1654653399040a61 {
    
    pub resource ContractObject : DynamicImport.ImportInterface {

        pub fun dynamicImport(name: String): auth &AnyStruct?{  
            if name=="FlowToken"{
                return &FlowToken as auth &AnyStruct
            }
            return nil 
        }
        
    }
    
    init(){
        self.account.save(<-create ContractObject(), to: /storage/A0x1654653399040a61)
    }

}   



