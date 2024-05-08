import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract NFTStoreFree {
   
    pub event NFTStorefrontInitialized()

    pub event StorefrontInitialized(storefrontResourceID: UInt64)
   
    pub event StorefrontDestroyed(storefrontResourceID: UInt64)

    pub event ListingAvailable(
        storefrontAddress: Address,
        listingResourceID: UInt64,
        nftType: Type,
        nftID: UInt64,
        ftVaultType: Type,
        price: UFix64
    )

    pub event ListingCompleted(
        listingResourceID: UInt64, 
        storefrontResourceID: UInt64, 
        purchased: Bool,
        nftType: Type,
        nftID: UInt64
    )

    pub let StorefrontStoragePath: StoragePath

    pub let StorefrontPublicPath: PublicPath

    pub struct SaleCut {
    
        pub let receiver: Capability<&{FungibleToken.Receiver}>

        pub let amount: UFix64

        init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }
    }

    pub struct ListingDetails {
       
        pub var storefrontID: UInt64
        // Whether this listing has been purchased or not.
        pub var purchased: Bool
        // The Type of the NonFungibleToken.NFT that is being listed.
        pub let nftType: Type
        // The ID of the NFT within that type.
        pub let nftID: UInt64
        // The Type of the FungibleToken that payments must be made in.
        pub let salePaymentVaultType: Type
        // The amount that must be paid in the specified FungibleToken.
        pub let salePrice: UFix64
        // This specifies the division of payment between recipients.
        pub let saleCuts: [SaleCut]

        access(contract) fun setToPurchased() {
            self.purchased = true
        }

        // initializer
        init (
            nftType: Type,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut],
            storefrontID: UInt64
        ) {
            self.storefrontID = storefrontID
            self.purchased = false
            self.nftType = nftType
            self.nftID = nftID
            self.salePaymentVaultType = salePaymentVaultType
            // Store the cuts
            assert(saleCuts.length > 0, message: "Listing must have at least one payment cut recipient")
            self.saleCuts = saleCuts

            // Calculate the total price from the cuts
            var salePrice = 0.0
            // Perform initial check on capabilities, and calculate sale price from cut amounts.
            for cut in self.saleCuts {
                // Make sure we can borrow the receiver.
                cut.receiver.borrow()
                    ?? panic("Cannot borrow receiver")
                // Add the cut amount to the total price
                salePrice = salePrice + cut.amount
            }

            // Store the calculated sale price
            self.salePrice = salePrice
        }
    }

    // ListingPublic
    pub resource interface ListingPublic {
        // borrowNFT
        pub fun borrowNFT(): &NonFungibleToken.NFT

        // purchase
        pub fun purchase(payment: @FungibleToken.Vault): @NonFungibleToken.NFT

        // getDetails
        pub fun getDetails(): ListingDetails

    }

    pub resource Listing: ListingPublic {
        // The simple (non-Capability, non-complex) details of the sale
        access(self) let details: ListingDetails

        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        access(contract) let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

        // borrowNFT
        pub fun borrowNFT(): &NonFungibleToken.NFT {
            let ref = self.nftProviderCapability.borrow()!.borrowNFT(id: self.getDetails().nftID)
            //- CANNOT DO THIS IN PRECONDITION: "member of restricted type is not accessible: isInstance"
            //  result.isInstance(self.getDetails().nftType): "token has wrong type"
            assert(ref.isInstance(self.getDetails().nftType), message: "token has wrong type")
            assert(ref.id == self.getDetails().nftID, message: "token has wrong ID")
            return (ref as &NonFungibleToken.NFT?)!
        }

        pub fun getDetails(): ListingDetails {
            return self.details
        }
        
        // purchase
        // Purchase the listing, buying the token.
        // This pays the beneficiaries and returns the token to the buyer.
        //
        pub fun purchase(payment: @FungibleToken.Vault): @NonFungibleToken.NFT {
            pre {
                self.details.purchased == false: "listing has already been purchased"
                payment.isInstance(self.details.salePaymentVaultType): "payment vault is not requested fungible token"
                payment.balance == self.details.salePrice: "payment vault does not contain requested price"
            }

            // Make sure the listing cannot be purchased again.
            self.details.setToPurchased()

            // Fetch the token to return to the purchaser.
            let nft <-self.nftProviderCapability.borrow()!.withdraw(withdrawID: self.details.nftID)
        
            assert(nft.isInstance(self.details.nftType), message: "withdrawn NFT is not of specified type")
            assert(nft.id == self.details.nftID, message: "withdrawn NFT does not have specified ID")

            var residualReceiver: &{FungibleToken.Receiver}? = nil

            // Pay each beneficiary their amount of the payment.
            for cut in self.details.saleCuts {
                if let receiver = cut.receiver.borrow() {
                   let paymentCut <- payment.withdraw(amount: cut.amount)
                    receiver.deposit(from: <-paymentCut)
                    if (residualReceiver == nil) {
                        residualReceiver = receiver
                    }
                }
            }

            assert(residualReceiver != nil, message: "No valid payment receivers")

            residualReceiver!.deposit(from: <-payment)

            emit ListingCompleted(
                listingResourceID: self.uuid,
                storefrontResourceID: self.details.storefrontID,
                purchased: self.details.purchased,
                nftType: self.details.nftType,
                nftID: self.details.nftID
            )

            return <-nft
        }

        // destructor
        destroy () {
            // If we change this destructor, revisit those functions.
            if !self.details.purchased {
                emit ListingCompleted(
                    listingResourceID: self.uuid,
                    storefrontResourceID: self.details.storefrontID,
                    purchased: self.details.purchased,
                    nftType: self.details.nftType,
                    nftID: self.details.nftID
                )
            }
        }

        // initializer
        init (
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut],
            storefrontID: UInt64
        ) {
            // Store the sale information
            self.details = ListingDetails(
                nftType: nftType,
                nftID: nftID,
                salePaymentVaultType: salePaymentVaultType,
                saleCuts: saleCuts,
                storefrontID: storefrontID
            )

            // Store the NFT provider
            self.nftProviderCapability = nftProviderCapability

            // Check that the provider contains the NFT.
            let provider = self.nftProviderCapability.borrow()
            assert(provider != nil, message: "cannot borrow nftProviderCapability")

            // This will precondition assert if the token is not available.
            let nft = provider!.borrowNFT(id: self.details.nftID)
            assert(nft.isInstance(self.details.nftType), message: "token is not of specified type")
            assert(nft.id == self.details.nftID, message: "token does not have specified ID")
        }
    }

    pub resource interface StorefrontManager {
        // createListing
        pub fun createListing(
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut]
        ): UInt64
        // removeListing
        pub fun removeListing(listingResourceID: UInt64)
    }

    pub resource interface StorefrontPublic {
        pub fun getListingIDs(): [UInt64]
        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}?
        pub fun cleanup(listingResourceID: UInt64)
   }

    pub resource Storefront : StorefrontManager, StorefrontPublic {
        // The dictionary of Listing uuids to Listing resources.
        access(self) var listings: @{UInt64: Listing}

        // insert
        // Create and publish a Listing for an NFT.
        //
         pub fun createListing(
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut]
         ): UInt64 {
            let listing <- create Listing(
                nftProviderCapability: nftProviderCapability,
                nftType: nftType,
                nftID: nftID,
                salePaymentVaultType: salePaymentVaultType,
                saleCuts: saleCuts,
                storefrontID: self.uuid
            )

            let listingResourceID = listing.uuid
            let listingPrice = listing.getDetails().salePrice

            // Add the new listing to the dictionary.
            let oldListing <- self.listings[listingResourceID] <- listing
            // Note that oldListing will always be nil, but we have to handle it.

            destroy oldListing

            emit ListingAvailable(
                storefrontAddress: self.owner?.address!,
                listingResourceID: listingResourceID,
                nftType: nftType,
                nftID: nftID,
                ftVaultType: salePaymentVaultType,
                price: listingPrice
            )

            return listingResourceID
        }
        
        pub fun removeListing(listingResourceID: UInt64) {
            let listing <- self.listings.remove(key: listingResourceID)
                ?? panic("missing Listing")
    
            // This will emit a ListingCompleted event.
            destroy listing
        }

        pub fun getListingIDs(): [UInt64] {
            return self.listings.keys
        }

        pub fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}? {
            if self.listings[listingResourceID] != nil {
                return (&self.listings[listingResourceID] as &Listing{ListingPublic}?)
            } else {
                return nil
            }
        }

        pub fun cleanup(listingResourceID: UInt64) {
            pre {
                self.listings[listingResourceID] != nil: "could not find listing with given id"
            }

            let listing <- self.listings.remove(key: listingResourceID)!
            assert(listing.getDetails().purchased == true, message: "listing is not purchased, only admin can remove")
            destroy listing
        }

        // destructor
        //
        destroy () {
            destroy self.listings

            // Let event consumers know that this storefront will no longer exist
            emit StorefrontDestroyed(storefrontResourceID: self.uuid)
        }

        // constructor
        init () {
            self.listings <- {}

            // Let event consumers know that this storefront exists
            emit StorefrontInitialized(storefrontResourceID: self.uuid)
        }
    }

    pub fun createStorefront(): @Storefront {
        return <-create Storefront()
    }

    init () {
        self.StorefrontStoragePath = /storage/NFTStoreFree
        self.StorefrontPublicPath = /public/NFTStoreFree

        emit NFTStorefrontInitialized()
    }
}