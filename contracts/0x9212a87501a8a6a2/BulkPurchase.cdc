/*
    BulkPurchase.cdc

    The contract enables the bulk purchasing of NFTs from multiple storefronts in a single transaction

    Author: Brian Min brian@flowverse.co
*/

import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import NFTCatalog from "../0x49a7cda3a1eecc29/NFTCatalog.cdc"
import NFTStorefront from "../0x4eb8a10cb9f87357/NFTStorefront.cdc"
import NFTStorefrontV2 from "../0x4eb8a10cb9f87357/NFTStorefrontV2.cdc"
import FlowtyStorefront from "../0x5425d4a12d3b88de/FlowtyStorefront.cdc"
import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"
import Market from "../0xc1e4f4f4c4257510/Market.cdc"
import TopShotMarketV3 from "../0xc1e4f4f4c4257510/TopShotMarketV3.cdc"
import FlovatarMarketplace from "../0x921ea449dffec68a/FlovatarMarketplace.cdc"

access(all) contract BulkPurchase {
    access(all) event BulkPurchaseCompleted(completedOrders: [CompletedPurchaseOrder])
    
    pub enum Storefront: UInt8 {
        pub case StorefrontV1
        pub case StorefrontV2
        pub case Flowty
        pub case TopShotV1
        pub case TopShotV3
        pub case Flovatar
    }

    access(all) fun getStorefrontFromIdentifier(_ identifier: String): Storefront {
        switch identifier {
            case "A.4eb8a10cb9f87357.NFTStorefront":
                return Storefront.StorefrontV1
            case "A.4eb8a10cb9f87357.NFTStorefrontV2":
                return Storefront.StorefrontV2
            case "A.c1e4f4f4c4257510.Market":
                return Storefront.TopShotV1
            case "A.c1e4f4f4c4257510.TopShotMarketV3":
                return Storefront.TopShotV3
            case "A.921ea449dffec68a.FlovatarMarketplace":
                return Storefront.Flovatar
        }
        panic("Invalid storefront identifier")
    }

    access(all) fun getStorefrontIdentifier(_ storefront: Storefront): String {
        switch storefront {
            case Storefront.StorefrontV1:
                return "A.4eb8a10cb9f87357.NFTStorefront"
            case Storefront.StorefrontV2:
                return "A.4eb8a10cb9f87357.NFTStorefrontV2"
            case Storefront.TopShotV1:
                return "A.c1e4f4f4c4257510.Market"
            case Storefront.TopShotV3:
                return "A.c1e4f4f4c4257510.TopShotMarketV3"
            case Storefront.Flovatar:
                return "A.921ea449dffec68a.FlovatarMarketplace"
        }
        return ""
    }

    access(all) struct PurchaseOrder {
        pub let listingID: UInt64
        pub let ownerAddress: Address
        pub let storefront: Storefront

        pub var salePrice: UFix64?
        pub var salePaymentVaultType: Type?
        pub var nftID: UInt64?
        pub var nftType: Type?
        pub var purchaserAddress: Address?
        pub var completed: Bool
        pub var failureReason: String?

        init(
          listingID: UInt64,
          ownerAddress: Address,
          storefront: Storefront
        ) {
            self.listingID = listingID
            self.ownerAddress = ownerAddress
            self.storefront = storefront
            self.salePrice = nil
            self.salePaymentVaultType = nil
            self.nftID = nil
            self.nftType = nil
            self.purchaserAddress = nil
            self.completed = false
            self.failureReason = nil
        }

        pub fun complete() {
            self.completed = true
        }

        pub fun fail(_ reason: String) {
            self.completed = false
            self.failureReason = reason
        }

        pub fun setSalePrice(_ salePrice: UFix64) {
            self.salePrice = salePrice
        }

        pub fun setSalePaymentVaultType(_ salePaymentVaultType: Type) {
            self.salePaymentVaultType = salePaymentVaultType
        }

        pub fun setNFTID(_ nftID: UInt64) {
            self.nftID = nftID
        }

        pub fun setNFTType(_ nftType: Type) {
            self.nftType = nftType
        }

        pub fun setPurchaserAddress(_ purchaserAddress: Address) {
            self.purchaserAddress = purchaserAddress
        }
    }
    
    access(all) struct CompletedPurchaseOrder {
        pub let listingID: UInt64
        pub let ownerAddress: String
        pub var storefront: String
        pub var salePrice: UFix64
        pub var salePaymentVaultType: String
        pub var nftID: UInt64
        pub var nftType: String
        pub var purchaserAddress: String
        pub var completed: Bool
        pub var failureReason: String?

        init (
            _ order: PurchaseOrder
        ) {
            self.listingID = order.listingID
            self.ownerAddress = order.ownerAddress.toString()
            self.storefront = BulkPurchase.getStorefrontIdentifier(order.storefront)
            self.salePrice = order.salePrice ?? 0.0
            self.salePaymentVaultType = order.salePaymentVaultType?.identifier ?? ""
            self.nftID = order.nftID ?? 0
            self.nftType = order.nftType?.identifier ?? ""
            self.purchaserAddress = order.purchaserAddress?.toString() ?? ""
            self.completed = order.completed
            self.failureReason = order.failureReason
        }
    }

    // Helper functions
    access(contract) fun getStorefrontV1Ref(address: Address): &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}? {
        return getAccount(address)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
            .borrow()
    }

    access(contract) fun getStorefrontV2Ref(address: Address): &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}? {
        return getAccount(address)
            .getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)
            .borrow()
    }

    access(contract) fun getTopshotV1MarketRef(address: Address): &Market.SaleCollection{Market.SalePublic}? {
        return getAccount(address)
            .getCapability<&Market.SaleCollection{Market.SalePublic}>(/public/topshotSaleCollection)
            .borrow()
    }

    access(contract) fun getTopshotV3MarketRef(address: Address): &TopShotMarketV3.SaleCollection{Market.SalePublic}? {
        return getAccount(address)
            .getCapability<&TopShotMarketV3.SaleCollection{Market.SalePublic}>(TopShotMarketV3.marketPublicPath)
            .borrow()
    }

    access(contract) fun getFlovatarMarketRef(address: Address): &FlovatarMarketplace.SaleCollection{FlovatarMarketplace.SalePublic}? {
        return getAccount(address)
            .getCapability<&FlovatarMarketplace.SaleCollection{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)!
            .borrow()
    }

    access(contract) fun processStorefrontV1Order (
        order: PurchaseOrder,
        paymentVaultRefs: {String: &FungibleToken.Vault},
        nftReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>},
        storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic},
        unsafeMode: Bool
    ): PurchaseOrder {
        let listing = storefront.borrowListing(listingResourceID: order.listingID)
        if listing == nil {
            if unsafeMode {
                order.fail("listing was not found")
                return order
            }
            panic("Storefront V1 listing was not found, listing id: ".concat(order.listingID.toString()))
        }
        let listingDetails = listing!.getDetails()
        if listingDetails.purchased {
            if unsafeMode {
                order.fail("listing was already purchased")
                return order
            }
            panic("Storefront V1 listing was already purchased, listing id: ".concat(order.listingID.toString()))
        }
        let paymentVaultRef = paymentVaultRefs[listingDetails.salePaymentVaultType.identifier]!
        assert(listingDetails.salePaymentVaultType == paymentVaultRef.getType(),
            message: "payment vault type does not match, listing id: ".concat(order.listingID.toString()))
        if listingDetails.salePrice > paymentVaultRef.balance {
            if unsafeMode {
                order.fail("insufficient balance")
                return order
            }
            panic("Insufficient balance to purchase Storefront V2 listing, listing id: ".concat(order.listingID.toString()))
        }

        let receiverCapability = nftReceiverCapabilities[listingDetails.nftType.identifier]
            ?? panic("failed to get nft receiver capability for Storefront V1, NFT type: ".concat(listingDetails.nftType.identifier))
        let receiver = receiverCapability.borrow()
            ?? panic("failed to borrow receiver for Storefront V1, NFT type: ".concat(listingDetails.nftType.identifier))

        let payment <- paymentVaultRef.withdraw(amount: listingDetails.salePrice)
        let nft <- listing!.purchase(payment: <-payment)
        receiver.deposit(token: <-nft)
        
        order.setSalePrice(listingDetails.salePrice)
        order.setSalePaymentVaultType(listingDetails.salePaymentVaultType)
        order.setNFTType(listingDetails.nftType)
        order.setNFTID(listingDetails.nftID)
        order.setPurchaserAddress(receiverCapability.address)
        order.complete()
        return order
    }
    
    access(contract) fun processStorefrontV2Order (
        order: PurchaseOrder,
        paymentVaultRefs: {String: &FungibleToken.Vault},
        nftReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>},
        storefront: &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic},
        commissionReceiverCapabilities: {String: Capability<&{FungibleToken.Receiver}>},
        unsafeMode: Bool
    ): PurchaseOrder {
        let listing = storefront.borrowListing(listingResourceID: order.listingID)
        if listing == nil {
            if unsafeMode {
                order.fail("listing was not found")
                return order
            }
            panic("Storefront V2 listing was not found, listing id: ".concat(order.listingID.toString()))
        }
        let listingDetails = listing!.getDetails()
        if listingDetails.purchased {
            if unsafeMode {
                order.fail("listing was already purchased")
                return order
            }
            panic("Storefront V2 listing was already purchased, listing id: ".concat(order.listingID.toString()))
        }
        let paymentVaultRef = paymentVaultRefs[listingDetails.salePaymentVaultType.identifier]!
        assert(listingDetails.salePaymentVaultType == paymentVaultRef.getType(),
            message: "payment vault type does not match, listing id: ".concat(order.listingID.toString()))
        if listingDetails.salePrice > paymentVaultRef.balance {
            if unsafeMode {
                order.fail("insufficient balance")
                return order
            }
            panic("Insufficient balance to purchase Storefront V2 listing, listing id: ".concat(order.listingID.toString()))
        }

        let receiverCapability = nftReceiverCapabilities[listingDetails.nftType.identifier]
            ?? panic("failed to get nft receiver capability for Storefront V2, NFT type: ".concat(listingDetails.nftType.identifier))
        let receiver = receiverCapability.borrow()
            ?? panic("failed to borrow receiver for Storefront V2, NFT type: ".concat(listingDetails.nftType.identifier))

        var commissionRecipient: Capability<&{FungibleToken.Receiver}>? = nil
        if (listingDetails.commissionAmount > 0.0) {
            commissionRecipient = commissionReceiverCapabilities[listingDetails.salePaymentVaultType.identifier]
            if let allowedCommissionReceivers = listing!.getAllowedCommissionReceivers() {
                var found = false
                for allowedReceiver in allowedCommissionReceivers {
                    // set commission receiver if specified and allowed
                    if commissionRecipient != nil &&
                        commissionRecipient!.address == allowedReceiver.address &&
                        commissionRecipient!.getType() == allowedReceiver.getType() {
                        found = true
                        break
                    }
                }
                if !found {
                    commissionRecipient = nil
                }
            }
        }

        let payment <- paymentVaultRef.withdraw(amount: listingDetails.salePrice)
        let nft <- listing!.purchase(
            payment: <-payment,
            commissionRecipient: commissionRecipient
        )
        receiver.deposit(token: <-nft)

        order.setSalePrice(listingDetails.salePrice)
        order.setSalePaymentVaultType(listingDetails.salePaymentVaultType)
        order.setNFTType(listingDetails.nftType)
        order.setNFTID(listingDetails.nftID)
        order.setPurchaserAddress(receiverCapability.address)
        order.complete()
        return order
    }

    access(contract) fun processTopshotOrder(
        order: PurchaseOrder,
        paymentVaultRefs: {String: &FungibleToken.Vault},
        nftReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>},
        topShotMarket: &{Market.SalePublic},
        unsafeMode: Bool
    ): PurchaseOrder {
        if !topShotMarket.getIDs().contains(order.listingID) {
            if unsafeMode {
                order.fail("listing was not found")
                return order
            }
            panic("TopShot listing was not found, listing id: ".concat(order.listingID.toString()))
        }
        let salePrice = topShotMarket.getPrice(tokenID: order.listingID)!
        let paymentVaultRef = paymentVaultRefs[Type<@DapperUtilityCoin.Vault>().identifier]!
        assert(paymentVaultRef.getType() == Type<@DapperUtilityCoin.Vault>(),
            message: "payment vault type does not match, listing id: ".concat(order.listingID.toString()))
        if (salePrice > paymentVaultRef.balance) {
            if unsafeMode {
                order.fail("insufficient balance")
                return order
            }
            panic("Insufficient balance to purchase TopShot listing, listing id: ".concat(order.listingID.toString()))
        }
        let receiverCapability = nftReceiverCapabilities[Type<@TopShot.NFT>().identifier] 
            ?? panic("failed to get nft receiver capability for topshot")
        let receiver = receiverCapability.borrow() 
            ?? panic("failed to borrow receiver for TopShot")

        let buyTokens <- paymentVaultRef.withdraw(amount: salePrice) as! @DapperUtilityCoin.Vault
        let purchasedItem <- topShotMarket!.purchase(tokenID: order.listingID, buyTokens: <-buyTokens)
        receiver.deposit(token: <-purchasedItem)

        order.setSalePrice(salePrice)
        order.setSalePaymentVaultType(Type<@DapperUtilityCoin.Vault>())
        order.setNFTType(Type<@TopShot.NFT>())
        order.setNFTID(order.listingID)
        order.setPurchaserAddress(receiverCapability.address)
        order.complete()
        return order
    }

     access(all) fun purchase(
        orders: [PurchaseOrder],
        paymentVaultRefs: {String: &FungibleToken.Vault},
        nftReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>},
        commissionReceiverCapabilities: {String: Capability<&{FungibleToken.Receiver}>},
        unsafeMode: Bool
    ) {
        pre {
            orders.length <= 30: "maximum 30 orders per transaction"
        }

        // storefront references
        let storefrontV1Refs: {Address: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}} = {}
        let storefrontV2Refs: {Address: &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}} = {}
        let topShotV1MarketRefs: {Address: &Market.SaleCollection{Market.SalePublic}} = {}
        let topShotV3MarketRefs: {Address: &TopShotMarketV3.SaleCollection{Market.SalePublic}} = {}
        let flovatarMarketRefs: {Address: &FlovatarMarketplace.SaleCollection{FlovatarMarketplace.SalePublic}} = {}

        let completedOrders: [CompletedPurchaseOrder] = []

        for order in orders {
            switch order.storefront {
            case Storefront.StorefrontV1:
                if !storefrontV1Refs.containsKey(order.ownerAddress) {
                    let storefrontV1Ref = self.getStorefrontV1Ref(address: order.ownerAddress)
                    storefrontV1Refs[order.ownerAddress] = storefrontV1Ref ?? panic("missing storefront v1 reference in owner account")
                }
                let storefront = storefrontV1Refs[order.ownerAddress]!
                let processedOrder = self.processStorefrontV1Order(
                    order: order,
                    paymentVaultRefs: paymentVaultRefs,
                    nftReceiverCapabilities: nftReceiverCapabilities,
                    storefront: storefront,
                    unsafeMode: unsafeMode
                )
                storefront.cleanup(listingResourceID: order.listingID)
                completedOrders.append(CompletedPurchaseOrder(processedOrder))
            case Storefront.StorefrontV2:
                if !storefrontV2Refs.containsKey(order.ownerAddress) {
                    let storefrontV2Ref = self.getStorefrontV2Ref(address: order.ownerAddress)
                    storefrontV2Refs[order.ownerAddress] = storefrontV2Ref ?? panic("missing storefront v2 reference in owner account")
                }
                let processedOrder = self.processStorefrontV2Order(
                    order: order,
                    paymentVaultRefs: paymentVaultRefs,
                    nftReceiverCapabilities: nftReceiverCapabilities,
                    storefront: storefrontV2Refs[order.ownerAddress]!,
                    commissionReceiverCapabilities: commissionReceiverCapabilities,
                    unsafeMode: unsafeMode
                )
                completedOrders.append(CompletedPurchaseOrder(processedOrder))
            case Storefront.Flowty:
                let flowtyStorefrontRef = FlowtyStorefront.getStorefrontRef(owner: order.ownerAddress)
                let listing = flowtyStorefrontRef.borrowListing(listingResourceID: order.listingID)
                if listing == nil {
                    if unsafeMode {
                        order.fail("listing was not found")
                        completedOrders.append(CompletedPurchaseOrder(order))
                        continue
                    }
                    panic("Flowty listing was not found, listing id: ".concat(order.listingID.toString()))
                }
                let listingDetails = listing!.getDetails()
                if listingDetails.purchased {
                    if unsafeMode {
                        order.fail("listing was already purchased")
                        completedOrders.append(CompletedPurchaseOrder(order))
                        continue
                    }
                    panic("Flowty listing was already purchased, listing id: ".concat(order.listingID.toString()))
                }
                // TODO: implement flowty purchase
                order.complete()
                completedOrders.append(CompletedPurchaseOrder(order))
            case Storefront.TopShotV1:
                if !topShotV1MarketRefs.containsKey(order.ownerAddress) {
                    let topShotV1MarketRef = self.getTopshotV1MarketRef(address: order.ownerAddress)
                    topShotV1MarketRefs[order.ownerAddress] = topShotV1MarketRef ?? panic("missing topshot v1 market reference in owner account")
                }
                let processedOrder = self.processTopshotOrder(
                    order: order,
                    paymentVaultRefs: paymentVaultRefs,
                    nftReceiverCapabilities: nftReceiverCapabilities,
                    topShotMarket: topShotV1MarketRefs[order.ownerAddress]!,
                    unsafeMode: unsafeMode
                )
                completedOrders.append(CompletedPurchaseOrder(processedOrder))
            case Storefront.TopShotV3:
                if !topShotV3MarketRefs.containsKey(order.ownerAddress) {
                    let topShotV3MarketRef = self.getTopshotV3MarketRef(address: order.ownerAddress)
                    topShotV3MarketRefs[order.ownerAddress] = topShotV3MarketRef ?? panic("missing topshot v3 market reference in owner account")
                }
                let processedOrder = self.processTopshotOrder(
                    order: order,
                    paymentVaultRefs: paymentVaultRefs,
                    nftReceiverCapabilities: nftReceiverCapabilities,
                    topShotMarket: topShotV3MarketRefs[order.ownerAddress]!,
                    unsafeMode: unsafeMode
                )
                completedOrders.append(CompletedPurchaseOrder(processedOrder))
            case Storefront.Flovatar:
                if !flovatarMarketRefs.containsKey(order.ownerAddress) {
                    let flovatarMarketRef = self.getFlovatarMarketRef(address: order.ownerAddress)
                    flovatarMarketRefs[order.ownerAddress] = flovatarMarketRef ?? panic("missing flovatar market reference in owner account")
                }
                // TODO: implement Flovatar purchase
                order.complete()
                completedOrders.append(CompletedPurchaseOrder(order))
            }
        }
        emit BulkPurchaseCompleted(completedOrders: completedOrders)
    }
}
