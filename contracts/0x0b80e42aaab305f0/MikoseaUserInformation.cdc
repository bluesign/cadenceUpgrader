pub contract MikoseaUserInformation {
    pub let storagePath: StoragePath
    pub let publicPath: PublicPath
    pub let adminPath: StoragePath

    access(contract) let userData: {Address:UserInfo}
    pub struct UserInfo {
        pub var metadata: {String:String}

        init(metadata:  {String:String}) {
            self.metadata = metadata
        }

        pub fun byKey(key: String): String? {
            return self.metadata[key]
        }

        pub fun setKeyValue(key: String, value: String) {
            self.metadata[key] = value
        }

        pub fun update(metadata: {String:String}) {
            self.metadata = metadata
        }
    }

    pub resource Admin {
        init() {
        }

        pub fun upsert(address: Address, metadata: {String:String}) {
            MikoseaUserInformation.userData[address] = UserInfo(metadata: metadata)
        }

        pub fun upsertKeyValue(address: Address, key: String, value: String) {
            if let user = MikoseaUserInformation.userData[address] {
                user.setKeyValue(key: key, value: value)
                self.upsert(address: address, metadata: user.metadata)
            } else {
                self.upsert(address: address, metadata: {key: value})
            }
        }
    }

    pub fun findByAddress(address: Address): UserInfo? {
        return MikoseaUserInformation.userData[address]
    }

    init() {
        // Initialize contract paths
        self.storagePath = /storage/MikoseaUserInformation
        self.publicPath = /public/MikoseaUserInformation
        self.adminPath = /storage/MikoseaUserInformationAdmin

        self.userData={}
        let admin <- create Admin()
        self.account.save(<- admin, to: self.adminPath)
    }
}