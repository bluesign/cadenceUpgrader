access(all)
contract TransactionTypes{ 
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
	
	access(all)
	struct StorefrontListingRequest{ 
		access(all)
		let nftProviderAddress: Address
		
		access(all)
		let nftProviderPath: PrivatePath
		
		access(all)
		let nftStoragePath: StoragePath
		
		access(all)
		let nftTypeIdentifier: String
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let price: UFix64
		
		access(all)
		let customID: String?
		
		access(all)
		let expiry: UInt64
		
		access(all)
		let buyerAddress: Address?
		
		access(all)
		let catalogCollection: Bool
		
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
		){ 
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
