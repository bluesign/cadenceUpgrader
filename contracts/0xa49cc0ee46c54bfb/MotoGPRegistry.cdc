import ContractVersion from 0xa49cc0ee46c54bfb 

pub contract MotoGPRegistry: ContractVersion {
    
    pub fun getVersion():String {
        return "1.0.0"
    }
    
    pub resource Admin {}

    access(contract) let map: {String : AnyStruct}
 
    pub fun set(adminRef: &Admin, key: String, value: AnyStruct) {
        self.map[key] = value
    }
 
    pub fun get(key: String): AnyStruct? {
        return self.map[key] ?? nil
    }
 
    pub let AdminStoragePath: StoragePath 
 
    init(){
        self.map = {} 
        self.AdminStoragePath = /storage/registryAdmin
        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}