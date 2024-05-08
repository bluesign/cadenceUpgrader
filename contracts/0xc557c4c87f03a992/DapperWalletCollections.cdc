pub contract DapperWalletCollections {
    pub let StoragePath: StoragePath

    pub event TypeChanged(identifier: String, added: Bool)

    access(self) let types: {Type: Bool}

    pub resource Admin {
        pub fun addType(_ t: Type) {
            DapperWalletCollections.types.insert(key: t, true)
            emit TypeChanged(identifier: t.identifier, added: true)
        }

        pub fun removeType( _ t: Type) {
            DapperWalletCollections.types.remove(key: t)
            emit TypeChanged(identifier: t.identifier, added: false)
        }
    }

    init () {
        self.types = {}

        self.StoragePath = /storage/dapperWalletCollections
    }
}