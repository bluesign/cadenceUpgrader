access(all)
contract ListingUtils{ 
	access(all)
	struct PurchaseModel{ 
		access(all)
		let listingResourceID: UInt64
		
		access(all)
		let storefrontAddress: Address
		
		access(all)
		let buyPrice: UFix64
		
		init(listingResourceID: UInt64, storefrontAddress: Address, buyPrice: UFix64){ 
			self.listingResourceID = listingResourceID
			self.storefrontAddress = storefrontAddress
			self.buyPrice = buyPrice
		}
	}
	
	access(all)
	struct ListingModel{ 
		access(all)
		let saleNFTID: UInt64
		
		access(all)
		let saleItemPrice: UFix64
		
		init(saleNFTID: UInt64, saleItemPrice: UFix64){ 
			self.saleNFTID = saleNFTID
			self.saleItemPrice = saleItemPrice
		}
	}
	
	access(all)
	struct SellItem{ 
		access(all)
		let listingId: UInt64
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let seller: Address
		
		init(listingId: UInt64, nftId: UInt64, seller: Address){ 
			self.listingId = listingId
			self.nftId = nftId
			self.seller = seller
		}
	}
}
