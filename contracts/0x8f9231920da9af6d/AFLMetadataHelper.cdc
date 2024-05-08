pub contract AFLMetadataHelper {

    access(contract) let metadataByTemplateId: {UInt64: {String: String}}

    pub let AdminStoragePath: StoragePath

    pub fun getMetadataForTemplate(id: UInt64): {String: String} {
        if (self.metadataByTemplateId[id] == nil) {
            return {}
        }
        return self.metadataByTemplateId[id]!
    }

    pub resource Admin {
        pub fun updateMetadataForTemplate(id: UInt64, metadata: {String: String}) {
            if (AFLMetadataHelper.metadataByTemplateId[id] == nil) {
                AFLMetadataHelper.metadataByTemplateId[id] = {}
            }
            AFLMetadataHelper.metadataByTemplateId[id] = metadata
        }

        pub fun addMetadataToTemplate(id: UInt64, key: String, value: String) {
            if (AFLMetadataHelper.metadataByTemplateId[id] == nil) {
                AFLMetadataHelper.metadataByTemplateId[id] = {}
            }
            let templateRef = &AFLMetadataHelper.metadataByTemplateId[id]! as &{String:String}
            templateRef[key] = value
        }

        pub fun removeMetadataFromTemplate(id: UInt64, key: String) {
            let templateRef = &AFLMetadataHelper.metadataByTemplateId[id]! as &{String:String}
            templateRef[key] = nil
        }

        pub fun removeAllExtendedMetadataFromTemplate(id: UInt64) {
            AFLMetadataHelper.metadataByTemplateId[id] = {}
        }
    }

    init() {
        self.AdminStoragePath = /storage/AFLMetadataHelperAdmin 
        self.metadataByTemplateId = {}
        let admin <- create Admin()
        self.account.save(<- admin, to: self.AdminStoragePath)
    }
}