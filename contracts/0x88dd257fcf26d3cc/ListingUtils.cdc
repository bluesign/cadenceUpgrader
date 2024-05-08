pub contract ListingUtils {

    pub struct PurchaseModel {
        pub let listingResourceID: UInt64
        pub let storefrontAddress: Address
        pub let buyPrice: UFix64

        init(
            listingResourceID: UInt64,
            storefrontAddress: Address,
            buyPrice: UFix64
        ) {
            self.listingResourceID = listingResourceID
            self.storefrontAddress = storefrontAddress
            self.buyPrice = buyPrice
        }
    }

    pub struct ListingModel {
        pub let saleNFTID: UInt64
        pub let saleItemPrice: UFix64

        init(
            saleNFTID: UInt64,
            saleItemPrice: UFix64
        ) {
            self.saleNFTID = saleNFTID
            self.saleItemPrice = saleItemPrice        
        }
    }

    pub struct SellItem {
        pub let listingId: UInt64
        pub let nftId: UInt64
        pub let seller: Address

        init(
            listingId: UInt64,
            nftId: UInt64,
            seller: Address
        ) {
            self.listingId = listingId
            self.nftId = nftId
            self.seller = seller
        }
    }

}