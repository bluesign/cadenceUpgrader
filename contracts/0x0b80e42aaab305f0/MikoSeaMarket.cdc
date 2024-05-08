import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract MikoSeaMarket {
    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------
    pub event NFTMikoSeaMarketInitialized()
    pub event MikoSeaMarketInitialized(marketResourceID: UInt64)
    pub event MikoSeaMarketDestroyed(marketResourceID: UInt64)
    pub event OrderCreated(orderId: UInt64, holderAddress: Address, nftType: Type, nftID: UInt64, price: UFix64)
    pub event OrderCompleted(orderId: UInt64, purchased: Bool, holderAddress: Address, buyerAddress: Address?, nftID: UInt64, nftType: Type, price: UFix64)

    //------------------------------------------------------------
    // Path
    //------------------------------------------------------------
    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath
    pub let MarketStoragePath: StoragePath
    pub let MarketPublicPath: PublicPath

    //------------------------------------------------------------
    // MikoSeaMarket vairables
    //------------------------------------------------------------
    priv let adminCap: Capability<&{AdminPublicCollection}>
    pub var mikoseaCap: Capability<&AnyResource{FungibleToken.Receiver}>
    pub var tokenPublicPath: PublicPath
    // maping transactionId - orderId
    pub let refIds: {String: UInt64}
    // maping nftID - orderId
    pub let nftIds: {UInt64: UInt64}

    //------------------------------------------------------------
    // OrderDetail Struct
    //------------------------------------------------------------
    pub resource OrderDetail {
        pub var purchased: Bool

        // MIKOSEANFT.NFT or MIKOSEANFTV2.NFT
        pub let nftType: Type
        pub let nftID: UInt64

        pub let holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

        // status:
        //   created
        //   validated
        //   done
        //   reject
        pub var status: String

        // unit yen
        pub let salePrice: UFix64

        // transactionOrderId
        pub var refId: String?

        pub var receiverCap: Capability<&{NonFungibleToken.Receiver}>?

        pub let royalties: MetadataViews.Royalties

        // unix time
        pub var expireAt: UFix64?
        // unix time
        pub let createdAt: UFix64
        // unix time
        pub var purchasedAt: UFix64?
        // unix time
        pub var cancelAt: UFix64?

        pub let metadata: {String:String}

        init (
            nftType: Type,
            nftID: UInt64,
            holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            salePrice:UFix64,
            royalties: MetadataViews.Royalties,
            metadata: {String:String}
        ) {
            self.holderCap = holderCap
            self.nftType = nftType
            self.nftID = nftID
            self.salePrice = salePrice
            self.royalties = royalties
            self.metadata = metadata

            self.refId = nil
            self.receiverCap = nil
            self.status = "created"
            self.purchased = false
            self.createdAt = getCurrentBlock().timestamp
            self.purchasedAt = nil
            self.cancelAt = nil
            self.expireAt = nil

            self.checkAfterCreate()
        }

        pub fun getId(): UInt64 {
            return self.uuid
        }

        priv fun checkAfterCreate() {
            let collection = self.holderCap.borrow() ?? panic("COULD_NOT_BORROW_HOLDER")
            self.borrowNFT()
        }

        access(contract) fun withdraw(): @NonFungibleToken.NFT {
            let ref = self.holderCap.borrow() ?? panic("SOMETHING_WENT_WRONG")
            return <- ref.withdraw(withdrawID: self.nftID)
        }

        access(contract) fun setToPurchased() {
            self.purchased = true
            self.purchasedAt = getCurrentBlock().timestamp
            self.status = "done"
        }

        // when GMO payment success
        access(contract) fun onPaymentSuccess(refId: String, receiverCap: Capability<&{NonFungibleToken.Receiver}>) {
            self.status = "validated"
            self.refId = refId
            self.receiverCap = receiverCap
        }

        priv fun checkBeforePurchase(_ receiverAddress: Address) {
            let nft = self.borrowNFT()
            assert(self.purchased == false, message: "ORDER_IS_PURCHASED")
            assert(self.status == "validated", message: "STATUS_IS_INVALID")
            assert(self.receiverCap != nil && self.receiverCap!.address == receiverAddress, message: "NOT_RECIPIENT".concat(", receive ").concat(self.receiverCap!.address.toString()).concat(", receive ").concat(receiverAddress.toString()))
        }

        pub fun borrowNFT(): &NonFungibleToken.NFT {
            let ref = self.holderCap.borrow() ?? panic("ACCOUNT_NOT_SETUP")
            let nft = ref.borrowNFT(id: self.nftID)
            assert(nft.isInstance(self.nftType), message: "NFT_TYPE_ERROR")
            assert(nft.id == self.nftID, message: "NFT_ID_ERROR")
            return nft
        }

        // pub fun borrowNFTSafe(): &NonFungibleToken.NFT? {
        //     if let ref = self.holderCap.borrow() {
        //         if let nft = ref.borrowNFTSafe(id: self.nftID) {
        //             if (nft.isInstance(self.nftType)) {
        //                 return nft
        //             }
        //         }
        //     }
        //     return nil
        // }

        pub fun purchase(_ receiverAddress: Address) {
            self.checkBeforePurchase(receiverAddress)
            log(self.receiverCap)
            log(receiverAddress)
            let receiverRef = self.receiverCap!.borrow() ?? panic("ACCOUNT_NOT_SETUP")
            receiverRef.deposit(token: <- self.withdraw())
            self.setToPurchased()
            emit OrderCompleted(
                orderId: self.uuid,
                purchased: self.purchased,
                holderAddress: self.holderCap.address,
                buyerAddress: self.receiverCap?.address,
                nftID: self.nftID,
                nftType: self.nftType,
                price: self.salePrice
            )
        }

        // destructor
        destroy () {
            MikoSeaMarket.nftIds.remove(key: self.nftID)
            if self.refId != nil {
                MikoSeaMarket.refIds.remove(key: self.refId!)
            }
            if !self.purchased {
                emit OrderCompleted(
                    orderId: self.uuid,
                    purchased: self.purchased,
                    holderAddress: self.holderCap.address,
                    buyerAddress: self.receiverCap?.address,
                    nftID: self.nftID,
                    nftType: self.nftType,
                    price: self.salePrice
                )
            }
        }
    }

    //------------------------------------------------------------
    // StorefrontPublic
    //------------------------------------------------------------
    pub resource interface StorefrontPublic {
        pub fun getIds(): [UInt64]
        pub fun getOrders(): [&OrderDetail]
        pub fun borrowOrder(_ orderId: UInt64): &OrderDetail?
    }
    //------------------------------------------------------------
    // Storefront
    //------------------------------------------------------------
    pub resource Storefront: StorefrontPublic {
        pub let orderIds: [UInt64]

        init() {
            self.orderIds = []
        }

        // get listing ids
        pub fun getIds(): [UInt64] {
            return self.orderIds
        }

        pub fun getOrders(): [&OrderDetail] {
            let res: [&OrderDetail] = []
            for orderId in self.getIds() {
                if let order = MikoSeaMarket.getAdminRef().borrowOrder(orderId) {
                    res.append(order)
                }
            }
            return res
        }

        pub fun borrowOrder(_ orderId: UInt64): &OrderDetail? {
            if !self.getIds().contains(orderId) {
                return nil
            }
            return MikoSeaMarket.getAdminRef().borrowOrder(orderId)
        }

        pub fun createOrder(
            nftType: Type,
            nftID: UInt64,
            holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            salePrice: UFix64,
            royalties: MetadataViews.Royalties,
            metadata: {String:String}
        ): UInt64 {
            let orderId = MikoSeaMarket.getAdminRef().createOrder(nftType: nftType, nftID: nftID, holderCap: holderCap, salePrice: salePrice, royalties: royalties, metadata: metadata)
            self.orderIds.append(orderId)
            return orderId
        }

        pub fun removeOrder(_ orderId: UInt64) {
            if let order = self.borrowOrder(orderId) {
                MikoSeaMarket.getAdminRef().removeOrder(orderId)
            }
            if let orderIdIndex = self.orderIds.firstIndex(of: orderId) {
                self.orderIds.remove(at: orderIdIndex)
            }
        }
    }


    //------------------------------------------------------------
    // Admin public
    //------------------------------------------------------------
    pub resource interface AdminPublicCollection {
        pub fun createOrder(
            nftType: Type,
            nftID: UInt64,
            holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            salePrice: UFix64,
            royalties: MetadataViews.Royalties,
            metadata: {String:String}
        ): UInt64
        pub fun removeOrder(_ orderId: UInt64)
        pub fun getIDs(): [UInt64]
        pub fun borrowOrder(_ orderId: UInt64): &OrderDetail?
    }

    //------------------------------------------------------------
    // Admin
    //------------------------------------------------------------
    pub resource Admin: AdminPublicCollection {
        access(self) var orders: @{UInt64: OrderDetail}

        init() {
            self.orders <- {}
        }

        pub fun borrowOrder(_ orderId: UInt64): &OrderDetail? {
            return &self.orders[orderId] as &OrderDetail?
        }

        pub fun getIDs(): [UInt64] {
            return self.orders.keys
        }

        pub fun createOrder(
            nftType: Type,
            nftID: UInt64,
            holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            salePrice:UFix64,
            royalties: MetadataViews.Royalties,
            metadata: {String:String}
        ): UInt64 {
            let order <- create OrderDetail(
                nftType: nftType,
                nftID: nftID,
                holderCap: holderCap,
                salePrice: salePrice,
                royalties: royalties,
                metadata: metadata
            )

            let orderId = order.uuid

            let oldOrder <- self.orders[orderId] <- order
            destroy oldOrder

            MikoSeaMarket.nftIds.insert(key: nftID, orderId)

            emit OrderCreated(orderId: orderId, holderAddress: holderCap.address, nftType: nftType, nftID: nftID, price: salePrice)

            return orderId
        }

        pub fun cleanup(orderId: UInt64, holderCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>) {
            let order <- self.orders.remove(key: orderId) ?? panic("NOT_FOUND_ORDER")
            assert(order.purchased == true, message: "ORDER_IS_PURCHASED")
            let nft = holderCap.borrow()?.borrowNFT(id: order.nftID)
            assert(nft.isInstance(order.nftType), message: "NFT_TYPE_ERROR")
            assert(nft!.id == order.nftID, message: "NFT_ID_ERROR")
            destroy order
        }

        pub fun cleanAll() {
            for orderId in self.orders.keys {
                let order <- self.orders.remove(key: orderId) ?? panic("NOT_FOUND_ORDER")
                destroy order
            }
        }

        pub fun removeOrder(_ orderId: UInt64) {
            let order <- self.orders.remove(key: orderId)
                ?? panic("NOT_FOUND_ORDER")
            destroy order
        }

        // when GMO payment success
        pub fun onPaymentSuccess(orderId: UInt64, refId: String, receiverCap: Capability<&{NonFungibleToken.Receiver}>) {
            let order = self.borrowOrder(orderId)!
            order.onPaymentSuccess(refId: refId, receiverCap: receiverCap)
            MikoSeaMarket.refIds[refId] = order.uuid
        }

        // admin transfer nft to user
        pub fun purchaseForUser(_ orderId: UInt64, receiverAddress: Address) {
            let order = self.borrowOrder(orderId)
            order!.purchase(receiverAddress)
        }

        destroy () {
            destroy self.orders
            emit MikoSeaMarketDestroyed(marketResourceID: self.uuid)
        }
    }

    //------------------------------------------------------------
    // Contract fun
    //------------------------------------------------------------

    //------------------------------------------------------------
    // Create Empty Collection
    //------------------------------------------------------------
    pub fun createStorefront(): @Storefront {
        return <-create Storefront()
    }

    priv fun getAdminRef(): &{AdminPublicCollection}{
        return self.adminCap.borrow() ?? panic("NOT_FOUND_ADMIN")
    }

    pub fun getIDs(): [UInt64] {
        return self.getAdminRef().getIDs()
    }

    pub fun borrowOrder(_ orderId: UInt64): &OrderDetail? {
        return self.getAdminRef().borrowOrder(orderId)
    }

    pub fun getAdminAddress(): Address {
        return self.adminCap.address
    }

    // pub fun purchase(orderId: UInt64, receiverCap: Capability<&{NonFungibleToken.Receiver}>) {
    //     return self.getAdminRef().purchase(orderId: orderId, receiverCap: receiverCap)
    // }

    //------------------------------------------------------------
    // Initializer
    //------------------------------------------------------------
    init () {
        self.AdminStoragePath = /storage/MarketAdmin
        self.AdminPublicPath = /public/MarketAdmin
        self.MarketStoragePath =  /storage/MikoSeaMarket
        self.MarketPublicPath =  /public/MikoSeaMarket
        self.refIds = {}
        self.nftIds = {}


        // default token path
        self.tokenPublicPath = /public/flowTokenReceiver
        self.mikoseaCap = self.account.getCapability<&{FungibleToken.Receiver}>(self.tokenPublicPath)

        self.account.save(<- create Admin(), to: self.AdminStoragePath)
        self.account.link<&{AdminPublicCollection}>(self.AdminPublicPath, target: self.AdminStoragePath)
        self.adminCap = self.account.getCapability<&{AdminPublicCollection}>(self.AdminPublicPath)

        emit NFTMikoSeaMarketInitialized()
    }
}
