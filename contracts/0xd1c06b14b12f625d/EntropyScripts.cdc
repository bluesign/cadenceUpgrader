pub contract EntropyScripts {

	// EntropyScripts Contract Events
    pub event ContractInitialized()

	// Paths
	pub let AdminStoragePath: StoragePath


	// -----------------------------------------------------------------------
    // EntropyScripts contract-level fields.
    // -----------------------------------------------------------------------
	access(self) var scripts: @{UInt64: Script}
    access(self) var scriptPaths: {String: StoragePath}
	
	// The ID that is used to create Scripts
    // Every time a a new resource is created, an ID is assigned 
    // to the new Resource's ID and then is incremented by 1.
    pub var nextScriptID: UInt64



	pub resource Script {
        // The Script resource stores the signature art inside the Entropy account

        pub let name: String
        pub var signature: String
//        pub let path: String

        init (name: String, signature: String) {

            self.name = name
//            self.path = path
            self.signature = signature
        }

        access(contract) fun addToString(string: String) {
            self.signature = self.signature.concat(string)
        }

	}

	pub resource Admin { 

        // Create a new Script
        pub fun createScript(scriptName: String, scriptSignature: String) {
            // Create script resource
            var newScript <- create Script(name: scriptName, signature: scriptSignature)

            // Save the script path inside the contract's dictionary
            EntropyScripts.scriptPaths[scriptName] = StoragePath(identifier: "Entropy_".concat(scriptName))
            // Save resource with the script inside the Entropy account 
            // with a unique script name TO DO 
            EntropyScripts.account.save(<- newScript, to: EntropyScripts.scriptPaths[scriptName]!)
        }

        pub fun addToString(scriptName: String, string: String) {
    	    let script = EntropyScripts.account.borrow<&EntropyScripts.Script>(from: EntropyScripts.scriptPaths[scriptName]!)!

            script.addToString(string: string)
        }

		// create a new Administrator resource
		pub fun createAdmin(): @Admin {
			return <- create Admin()
		}
	}
    
    pub fun getScript(scriptName: String): String {
    	let script = EntropyScripts.account.borrow<&EntropyScripts.Script>(from: EntropyScripts.scriptPaths[scriptName]!)!

        return script.signature
    }



	init() {
		self.scripts <- {}
        self.scriptPaths = {}
		self.nextScriptID = 0
		self.AdminStoragePath = /storage/EntropyScriptsAdmin

		// Create a Administrator resource and save it to storage
		let administrator <- create Admin()
		self.account.save(<- administrator, to: self.AdminStoragePath)

		emit ContractInitialized()
	} 
}