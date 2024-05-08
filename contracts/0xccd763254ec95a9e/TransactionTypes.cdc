pub contract TransactionTypes {
    /*
    pub fun createListing(
        nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
        paymentReceiver: Capability<&{FungibleToken.Receiver}>,
        nftType: Type,
        nftID: UInt64,
        salePaymentVaultType: Type,
        price: UFix64,
        customID: String?,
        expiry: UInt64,
        buyer: Address?
    ): UInt64
    */
    pub struct StorefrontListingRequest {
        pub let nftProviderAddress: Address
        pub let nftProviderPath: PrivatePath
        pub let nftStoragePath: StoragePath
        pub let nftTypeIdentifier: String
        pub let nftID: UInt64
        pub let price: UFix64
        pub let customID: String?
        pub let expiry: UInt64
        pub let buyerAddress: Address?
        pub let catalogCollection: Bool

        init(
            nftProviderAddress: Address,
            nftProviderPath: PrivatePath,
            nftStoragePath: StoragePath,
            nftTypeIdentifier: String,
            nftID: UInt64,
            price: UFix64,
            customID: String?,
            expiry: UInt64,
            buyerAddress: Address?,
            catalogCollection: Bool
        ) {
            self.nftProviderAddress = nftProviderAddress
            self.nftProviderPath = nftProviderPath
            self.nftTypeIdentifier = nftTypeIdentifier
            self.nftID = nftID
            self.price = price
            self.customID = customID
            self.expiry = expiry
            self.buyerAddress = buyerAddress
            self.catalogCollection = catalogCollection
            self.nftStoragePath = nftStoragePath
        }
    }
}