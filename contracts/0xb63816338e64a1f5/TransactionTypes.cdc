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
        pub let nftProviderPathIdentifier: String
        pub let paymentReceiverAddress: Address
        pub let paymentReceiverPathIdentifier: String
        pub let nftTypeIdentifier: String
        pub let nftID: UInt64
        pub let salePaymentVaultTypeIdentifier: String
        pub let price: UFix64
        pub let customID: String?
        pub let expiry: UInt64
        pub let buyerAddress: Address?

        init(
            nftProviderAddress: Address,
            nftProviderPathIdentifier: String,
            paymentReceiverAddress: Address,
            paymentReceiverPathIdentifier: String,
            nftTypeIdentifier: String,
            nftID: UInt64,
            salePaymentVaultTypeIdentifier: String,
            price: UFix64,
            customID: String?,
            expiry: UInt64,
            buyerAddress: Address?
        ) {
            self.nftProviderAddress = nftProviderAddress
            self.nftProviderPathIdentifier = nftProviderPathIdentifier
            self.paymentReceiverAddress = paymentReceiverAddress
            self.paymentReceiverPathIdentifier = paymentReceiverPathIdentifier
            self.nftTypeIdentifier = nftTypeIdentifier
            self.nftID = nftID
            self.salePaymentVaultTypeIdentifier = salePaymentVaultTypeIdentifier
            self.price = price
            self.customID = customID
            self.expiry = expiry
            self.buyerAddress = buyerAddress
        }
    }
}