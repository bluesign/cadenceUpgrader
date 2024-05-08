pub contract DapperWalletRestrictions {
//
    pub let StoragePath: StoragePath

    pub event TypeChanged(identifier: Type, newConfig: TypeConfig)
    pub event TypeRemoved(identifier: Type)

    pub fun GetConfigFlags(): {String: String} {
        return {
            "CAN_INIT": "Can initialize collection in Dapper Custodial Wallet",
            "CAN_WITHDRAW": "Can withdraw NFT out of Dapper Custodial space",
            "CAN_SELL": "Can sell collection in Dapper Custodial space",
            "CAN_TRADE": "Can trade collection with other Dapper Custodial Wallet",
            "CAN_TRADE_EXTERNAL": "Can trade collection with external wallets",
            "CAN_TRADE_DIFF_NFT": "Can trade collection with different NFT types"
        }
    }

    pub struct TypeConfig{
        pub let flags: {String: Bool}

        pub fun setFlag(_ flag: String, _ value: Bool) {
            if DapperWalletRestrictions.GetConfigFlags()[flag] == nil {
                panic("Invalid flag")
            }

            self.flags[flag] = value
        }

        pub fun getFlag(_ flag: String): Bool {
            return self.flags[flag] ?? false
        }

        init () {
            self.flags= {}
        }
    }

    access(self) let types: {Type: TypeConfig}

    access(self) let ext: {String: AnyStruct}

    pub resource Admin {
        pub fun addType(_ t: Type, conf: TypeConfig) {
            DapperWalletRestrictions.types.insert(key: t, conf)
            emit TypeChanged(identifier: t, newConfig: conf)
        }

        pub fun updateType(_ t: Type, conf: TypeConfig) {
            DapperWalletRestrictions.types[t] = conf
            emit TypeChanged(identifier: t, newConfig: conf)
        }

        pub fun removeType( _ t: Type) {
            DapperWalletRestrictions.types.remove(key: t)
            emit TypeRemoved(identifier: t)
        }
    }

    pub fun getTypes(): {Type:TypeConfig} {
        return self.types
    }

    pub fun getConfig(_ t: Type): TypeConfig? {
        return self.types[t]
    }

    init () {
        self.types = {}
        self.ext = {}

        self.StoragePath = /storage/dapperWalletCollections
        self.account.save(<- create Admin(), to: self.StoragePath)
    }
}
