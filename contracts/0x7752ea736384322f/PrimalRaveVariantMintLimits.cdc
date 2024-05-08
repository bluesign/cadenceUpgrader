pub contract PrimalRaveVariantMintLimits {

    // -----------------------------------------------------------------------
    // Paths
    // -----------------------------------------------------------------------

    pub let PrimalRaveVariantMintLimitsAdminStoragePath: StoragePath

    // -----------------------------------------------------------------------
    // Contract Events
    // -----------------------------------------------------------------------

    pub event AdminSetVariantMintLimit(
        variantId: UInt64,
        variantMintLimit: UInt64
    )

    pub event AdminResourceCreated(
        uuid: UInt64,
        adminAddress: Address
    )

    pub event AddressVariantMintsIncremented(
        address: Address,
        variantId: UInt64,
        oldValue: UInt64?,
        newValue: UInt64
    )

    // -----------------------------------------------------------------------
    // Contract State
    // -----------------------------------------------------------------------

    // The maximum number of mints an address can mint for a given variant
    // If maxMints is nil, unlimited mints allowed for variant
    // {variantId: maxMints}
    access(contract) var variantMintLimits: {UInt64: UInt64}

    // The number of mints an address has minted for a given variant
    // {userAddress: {variantId: mints}}
    access(contract) var addressVariantMints: {Address: {UInt64: UInt64}}

    // The total number of variants
    access(contract) var numberOfVariants: UInt64

    // -----------------------------------------------------------------------
    // Admin Resource
    // -----------------------------------------------------------------------

    pub resource Admin {
        pub fun setVariantMintLimits(variantMintLimitsDict: {UInt64: UInt64}) {

            let keys = variantMintLimitsDict.keys
            let values = variantMintLimitsDict.values

            while keys.length > 0 {
                let key = keys.removeFirst()
                let value = values.removeFirst()
                PrimalRaveVariantMintLimits.variantMintLimits[key] = value

                emit AdminSetVariantMintLimit(
                    variantId: key,
                    variantMintLimit: value
                )
            }
        }

        pub fun setVariantMintsForAddress(address: Address, variantId: UInt64, numberOfMints: UInt64) {
            if let variantMintsByAddress: {UInt64: UInt64} = PrimalRaveVariantMintLimits.addressVariantMints[address] {
                variantMintsByAddress[variantId] = numberOfMints
                PrimalRaveVariantMintLimits.addressVariantMints[address] = variantMintsByAddress
            } else {
                // If variantMintsByAddress is nil, then address hasn't minted any variants yet, create a new entry
                PrimalRaveVariantMintLimits.addressVariantMints[address] = {variantId: numberOfMints}
                return
            }
        }

        pub fun setNumberOfVariants(numberOfVariants: UInt64) {
            PrimalRaveVariantMintLimits.numberOfVariants = numberOfVariants
        }  

        init(adminAddress: Address) {

            emit AdminResourceCreated(
                uuid: self.uuid,
                adminAddress: adminAddress
            )
        }
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    // Checks if an address can mint a variant
    pub fun checkAddressCanMintVariant(address: Address, variantId: UInt64): Bool {
        pre {
            variantId <= self.numberOfVariants: "Variant ID must be less than or equal to the number of variants"
        }
        let variantMintLimit: UInt64? = self.variantMintLimits[variantId]
        if variantMintLimit == nil {
            return true
        }

        let variantMintsByAddress: {UInt64: UInt64}? = self.addressVariantMints[address]
        if variantMintsByAddress == nil {
            return true
        }

        if let variantMintsByAddress: {UInt64: UInt64} = variantMintsByAddress {
            let mints = variantMintsByAddress[variantId]
            if mints == nil {
                return true
            }
            return mints! < variantMintLimit!
        }

        return false
    }

    // Increments the number of mints an address has minted for a given variant
    pub fun incrementVariantMintsForAddress(address: Address, variantId: UInt64) {
        if let variantMintsByAddress: {UInt64: UInt64} = self.addressVariantMints[address] {
            // Get the number of mints for the variant
            let mints = variantMintsByAddress[variantId]
            // If the address hasn't minted the variant yet, create a new entry
            if mints == nil {
                variantMintsByAddress[variantId] = 1
                self.addressVariantMints[address] = variantMintsByAddress
            } else {
                // Increment the number of mints for the variant
                let newMintsValue = mints! + 1
                variantMintsByAddress[variantId] = newMintsValue
                self.addressVariantMints[address] = variantMintsByAddress
            }
        } else {
            // If variantMintsByAddress is nil, then address hasn't minted any variants yet, create a new entry
            self.addressVariantMints[address] = {variantId: 1}
            return
        }
    }

    // -----------------------------------------------------------------------
    // Public Utility Functions
    // -----------------------------------------------------------------------

    pub fun getVariantMintLimits(): {UInt64: UInt64} {
        return self.variantMintLimits
    }

    pub fun getAllVariantMints(): {Address: {UInt64: UInt64}} {
        return self.addressVariantMints
    }

    pub fun getAllVariantMintsForAddress(address: Address): {UInt64: UInt64}? {
        return self.addressVariantMints[address]
    }

    pub fun getVariantMintsForAddress(address: Address, variantId: UInt64): {UInt64: UInt64}? {
        if let variantMintsByAddress: {UInt64: UInt64} = self.addressVariantMints[address] {
            let mints = variantMintsByAddress[variantId]
            if mints == nil {
                return nil
            }
            return {variantId: mints!}
        }
        return nil
    }

    // returns {variantId: {mints | limit: value}}
    pub fun getVariantMintsAndLimitsForAddress(address: Address): {UInt64: {String: UInt64?}} {
        
        var i: UInt64 = 0
        let ret: {UInt64: {String: UInt64?}} = {}
        while i < self.numberOfVariants {
            i = i + 1
            // Set the mint limit for the variant
            let variantMintLimits = self.variantMintLimits
            let limit = variantMintLimits[i]
            ret[i] = {
                "limit": limit
            }

            // Get variant mints dictionary
            let variantMintsForAddress = self.getAllVariantMintsForAddress(address: address)

            // If the address hasn't minted any variants yet, mints is 0 for this variant
            if variantMintsForAddress == nil {
                ret[i] = {
                    "mints": 0,
                    "limit": limit
                }
                continue
            }

            // Get the number of mints for this variant
            let variantMints = variantMintsForAddress![i]

            if variantMints == nil {
                ret[i] = {
                    "mints": 0,
                    "limit": limit
                }
                continue
            } else {
                ret[i] = {
                    "mints": variantMints,
                    "limit": limit
                }
            }
        }
        return ret
    }

    // -----------------------------------------------------------------------
    // Contract Init
    // -----------------------------------------------------------------------

    init() {
        
        self.PrimalRaveVariantMintLimitsAdminStoragePath = /storage/PrimalRaveVariantMintLimitsAdminStoragePath

        self.variantMintLimits = {}
        self.addressVariantMints = {}
        self.numberOfVariants = 8

        self.account.save(<- create Admin(adminAddress: self.account.address), to: self.PrimalRaveVariantMintLimitsAdminStoragePath)
    }
}