// MAINNET

/*
    FlowversePrimarySaleV2.cdc

    The contract handles the primary sale of NFTs, enabling purchasing and minting NFTs on-the-fly.

    Author: Brian Min brian@flowverse.co
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import Crypto

pub contract FlowversePrimarySaleV2 {
    pub let AdminStoragePath: StoragePath

    // Incremented ID used to create entities
    pub var nextPrimarySaleID: UInt64

    access(contract) var primarySales: @{UInt64: PrimarySale}
    access(contract) var primarySaleIDs: {String: UInt64}

    pub event PurchaseComplete(primarySaleID: UInt64, orders: [Order], nftIDs: [UInt64], purchaserAddress: Address, pool: String, price: UFix64, salePaymentVaultType: String)
    pub event ContractInitialized()

    pub resource interface IMinter {
        pub fun mint(entityID: UInt64, minterAddress: Address): @NonFungibleToken.NFT
    }

    // Data struct signed by admin account - allows accounts to purchase from a primary sale for a period of time.
    pub struct AdminSignedPayload {
        pub let primarySaleID: UInt64
        pub let purchaserAddress: Address
        pub let expiration: UInt64 // unix timestamp

        init(primarySaleID: UInt64, purchaserAddress: Address, expiration: UInt64){
            self.primarySaleID = primarySaleID
            self.purchaserAddress = purchaserAddress
            self.expiration = expiration
        }

        pub fun toString(): String {
            return self.primarySaleID.toString().concat("-")
                .concat(self.purchaserAddress.toString()).concat("-")
                .concat(self.expiration.toString())
        }
    }

    pub struct PriceData {
        pub let price: {String: UFix64}
        pub let pool: String
        pub(set) var eligibleAddresses: [Address]?
        pub var maxMintsPerUser: UInt64?

        init(price: {String: UFix64}, pool: String, eligibleAddresses: [Address]?, maxMintsPerUser: UInt64?){
            self.price = price
            self.pool = pool
            self.eligibleAddresses = eligibleAddresses
            self.maxMintsPerUser = maxMintsPerUser
        }
    }

    pub struct PurchaseData {
        pub let primarySaleID: UInt64
        pub let purchaserAddress: Address
        pub let purchaserCollectionRef: &{NonFungibleToken.Receiver}
        pub let orders: [Order]
        pub let pool: String

        init(primarySaleID: UInt64, purchaserAddress: Address, purchaserCollectionRef: &{NonFungibleToken.Receiver}, orders: [Order], pool: String){
            self.primarySaleID = primarySaleID
            self.purchaserAddress = purchaserAddress
            self.purchaserCollectionRef = purchaserCollectionRef
            self.orders = orders
            self.pool = pool
        }
    }
    
    pub struct PurchaseDataSequential {
        pub let primarySaleID: UInt64
        pub let purchaserAddress: Address
        pub let purchaserCollectionRef: &{NonFungibleToken.Receiver}
        pub let quantity: UInt64
        pub let pool: String

        init(primarySaleID: UInt64, purchaserAddress: Address, purchaserCollectionRef: &{NonFungibleToken.Receiver}, quantity: UInt64, pool: String){
            self.primarySaleID = primarySaleID
            self.purchaserAddress = purchaserAddress
            self.purchaserCollectionRef = purchaserCollectionRef
            self.quantity = quantity
            self.pool = pool
        }
    }

    pub struct Order {
        pub let entityID: UInt64
        pub let quantity: UInt64

        init(entityID: UInt64, quantity: UInt64){
            self.entityID = entityID
            self.quantity = quantity
        }
    }

    pub enum PrimarySaleStatus: UInt8 {
        pub case PAUSED
        pub case OPEN
        pub case CLOSED
    }

    pub resource interface PrimarySalePublic {
        pub fun getSupply(pool: String?): UInt64
        pub fun getPrices(): {String: PriceData}
        pub fun getStatus(): String
        pub fun purchaseHeroesBox(
            payment: @FungibleToken.Vault,
            data: PurchaseDataSequential,
            adminSignedPayload: AdminSignedPayload, 
            signature: String
        )
        pub fun purchaseSequentialNFTs(
            payment: @FungibleToken.Vault,
            data: PurchaseDataSequential,
            adminSignedPayload: AdminSignedPayload, 
            signature: String
        )
        pub fun getNumMintedByUser(userAddress: Address, pool: String): UInt64
        pub fun getNumMintedPerUser(): {String: {Address: UInt64}}
        pub fun getAllAvailableEntities(pool: String): {UInt64: UInt64}
        pub fun getLaunchDate(): String
        pub fun getEndDate(): String
        pub fun getPaymentReceivers(): {String: Address} 
        pub fun getContractName(): String
        pub fun getContractAddress(): Address
        pub fun getID(): UInt64
    }

    pub resource PrimarySale: PrimarySalePublic {
        access(self) var primarySaleID: UInt64
        access(self) var contractName: String
        access(self) var contractAddress: Address
        access(self) var status: PrimarySaleStatus
        access(self) var prices: {String: PriceData}
        access(self) var pooledEntities: {String: {UInt64: UInt64}}
        access(self) var numMintedPerUser: {String: {Address: UInt64}}
        access(self) var launchDate: String
        access(self) var endDate: String

        access(self) let minterCap: Capability<&{IMinter}>
        access(self) var paymentReceiverCaps: {String: Capability<&{FungibleToken.Receiver}>}

        init(
            contractName: String,
            contractAddress: Address,
            prices: {String: PriceData},
            minterCap: Capability<&{IMinter}>,
            paymentReceiverCaps: {String: Capability<&AnyResource{FungibleToken.Receiver}>},
            launchDate: String, 
            endDate: String
        ) {
            self.contractName = contractName
            self.contractAddress = contractAddress
            self.status = PrimarySaleStatus.PAUSED // primary sale is paused initially
            self.pooledEntities = {}
            self.prices = prices

            self.minterCap = minterCap
            self.paymentReceiverCaps = paymentReceiverCaps
            
            self.launchDate = launchDate
            self.endDate = endDate

            self.primarySaleID = FlowversePrimarySaleV2.nextPrimarySaleID
            let key = contractName.concat(contractAddress.toString())
            FlowversePrimarySaleV2.primarySaleIDs[key] = self.primarySaleID
            
            self.numMintedPerUser = {}
            for pool in prices.keys {
                self.numMintedPerUser.insert(key: pool, {})
            }
        }

        pub fun getStatus(): String {
            if (self.status == PrimarySaleStatus.PAUSED) {
                return "PAUSED"
            } else if (self.status == PrimarySaleStatus.OPEN) {
                return "OPEN"
            } else if (self.status == PrimarySaleStatus.CLOSED) {
                return "CLOSED"
            } else {
                return ""
            }
        }

        pub fun setPrice(priceData: PriceData) {
            self.prices[priceData.pool] = priceData
            if !self.numMintedPerUser.containsKey(priceData.pool) {
                self.numMintedPerUser.insert(key: priceData.pool, {})
            }
        }
        
        pub fun removePool(pool: String) {
            self.prices.remove(key: pool)
            self.numMintedPerUser.remove(key: pool)
            self.pooledEntities.remove(key: pool)
        }

        pub fun getPrices(): {String: PriceData} {
            return self.prices
        }
        
        pub fun addEligibleAddressesToPool(pool: String, eligibleAddresses: [Address]) {
            assert(self.prices.containsKey(pool), message: "Pool does not exist")
            let price = self.prices[pool]!
            if price.eligibleAddresses == nil {
                price.eligibleAddresses = eligibleAddresses
            } else {
                let updatedEligibleAddresses = price.eligibleAddresses!
                updatedEligibleAddresses.appendAll(eligibleAddresses)
                price.eligibleAddresses = updatedEligibleAddresses
            }
            self.prices[pool] = price
        }

        pub fun clearEligibleAddressesForPool(pool: String) {
            assert(self.prices.containsKey(pool), message: "Pool does not exist")
            let price = self.prices[pool]!
            price.eligibleAddresses = nil
            self.prices[pool] = price
        }

        pub fun getSupply(pool: String?): UInt64 {
            var supply = UInt64(0)
            for poolKey in self.pooledEntities.keys {
                if pool == nil || pool == poolKey {
                    let pooledDict = self.pooledEntities[poolKey]!
                    for entityID in pooledDict.keys {
                        supply = supply + pooledDict[entityID]!
                    }
                }
            }
            return supply
        }

        pub fun getLaunchDate(): String {
            return self.launchDate
        }

        pub fun getEndDate(): String {
            return self.endDate
        }

        pub fun getPaymentReceivers(): {String: Address}  {
            let paymentReceivers: {String: Address} = {}
            for salePaymentVaultType in self.paymentReceiverCaps.keys {
                let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
                if receiver.owner != nil {
                    paymentReceivers[salePaymentVaultType] = receiver.owner!.address
                }
            }
            return paymentReceivers
        }

        pub fun getPaymentReceiverAddress(salePaymentVaultType: String): Address? {
            assert(self.paymentReceiverCaps.containsKey(salePaymentVaultType), message: "payment receiver does not exist for vault type: ".concat(salePaymentVaultType))
            let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
            if receiver.owner != nil {
                return receiver.owner!.address
            }
            return nil
        }
        
        pub fun getNumMintedPerUser(): {String: {Address: UInt64}} {
            return self.numMintedPerUser
        }

        pub fun getNumMintedByUser(userAddress: Address, pool: String): UInt64 {
            assert(self.numMintedPerUser.containsKey(pool), message: "invalid pool")
            let numMintedDict = self.numMintedPerUser[pool]!
            return numMintedDict[userAddress] ?? 0
        }
        
        pub fun getContractName(): String {
            return self.contractName
        }
        
        pub fun getContractAddress(): Address {
            return self.contractAddress
        }

        pub fun getID(): UInt64 {
            return self.primarySaleID
        }

        pub fun addEntity(entityID: UInt64, pool: String, quantity: UInt64) {
            if !self.pooledEntities.containsKey(pool) {
                self.pooledEntities.insert(key: pool, {})
            }
            self.pooledEntities[pool]!.insert(key: entityID, quantity)
        }

        pub fun removeEntity(entityID: UInt64, pool: String) {
            if self.pooledEntities.containsKey(pool) {
                self.pooledEntities[pool]!.remove(key: entityID)
            }
        }

        pub fun addEntities(entityIDs: [UInt64], pool: String) {
            for id in entityIDs {
                self.addEntity(entityID: id, pool: pool, quantity: 1)
            }
        }

        pub fun pause() {
            self.status = PrimarySaleStatus.PAUSED
        }

        pub fun open() {
            pre {
                self.status != PrimarySaleStatus.OPEN : "Primary sale is already open"
                self.status != PrimarySaleStatus.CLOSED : "Cannot re-open primary sale that is closed"
            }

            self.status = PrimarySaleStatus.OPEN
        }

        pub fun close() {
            self.status = PrimarySaleStatus.CLOSED
        }
        
        access(self) fun verifyAdminSignedPayload(signedPayloadData: AdminSignedPayload, signature: String): Bool {
            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey
            
            let publicKey = PublicKey(
                publicKey: accountKey.publicKey,
                signatureAlgorithm: accountKey.signatureAlgorithm
            )

            return publicKey.verify(
                signature: signature.decodeHex(),
                signedData: signedPayloadData.toString().utf8,
                domainSeparationTag: "FLOW-V0.0-user",
                hashAlgorithm: HashAlgorithm.SHA3_256
            )
        }

        pub fun purchaseHeroesBox(
            payment: @FungibleToken.Vault,
            data: PurchaseDataSequential,
            adminSignedPayload: AdminSignedPayload,
            signature: String
        ) {
            pre {
                self.primarySaleID == data.primarySaleID: "primarySaleID mismatch"
                self.status == PrimarySaleStatus.OPEN: "primary sale is not open"
                data.quantity > 0: "must purchase at least one NFT"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp): "expired signature"
                self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature): "failed to validate signature for the primary sale purchase"
                self.contractName == "HeroesOfTheFlow": "only supports heroes of the flow contract"
            }

            let pool = data.pool
            let supply = self.getSupply(pool: pool)
            let totalQuantity = data.quantity * 3
            assert(totalQuantity <= supply, message: "insufficient supply")

            let orders: [Order] = []
            var quantityNeeded = totalQuantity
            var availableEntities = self.getAllAvailableEntities(pool: pool)
            for entityID in availableEntities.keys {
                if quantityNeeded > 0 {
                    var quantityToAdd: UInt64 = availableEntities[entityID]!
                    if quantityToAdd > quantityNeeded {
                        quantityToAdd = quantityNeeded
                    }
                    orders.append(Order(entityID: entityID, quantity: quantityToAdd))
                    quantityNeeded = quantityNeeded - quantityToAdd
                } else {
                    break
                }
            }

            let purchaseData = PurchaseData(
                primarySaleID: data.primarySaleID,
                purchaserAddress: data.purchaserAddress,
                purchaserCollectionRef: data.purchaserCollectionRef,
                orders: orders,
                pool: data.pool
            )
            
            self.purchase(payment: <-payment, data: purchaseData)
        }

        pub fun purchaseSequentialNFTs(
            payment: @FungibleToken.Vault,
            data: PurchaseDataSequential,
            adminSignedPayload: AdminSignedPayload,
            signature: String
        ) {
            pre {
                self.primarySaleID == data.primarySaleID: "primarySaleID mismatch"
                self.status == PrimarySaleStatus.OPEN: "primary sale is not open"
                data.quantity > 0: "must purchase at least one NFT"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp): "expired signature"
                self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature): "failed to validate signature for the primary sale purchase"
                self.contractName != "HeroesOfTheFlow": "HeroesOfTheFlow does not support sequential purchase"
            }

            let pool = data.pool
            let supply = self.getSupply(pool: pool)
            assert(data.quantity <= supply, message: "insufficient supply")

            let orders: [Order] = []
            var quantityNeeded = data.quantity
            var availableEntities = self.getAllAvailableEntities(pool: pool)
            for entityID in availableEntities.keys {
                if quantityNeeded > 0 {
                    var quantityToAdd: UInt64 = availableEntities[entityID]!
                    if quantityToAdd > quantityNeeded {
                        quantityToAdd = quantityNeeded
                    }
                    orders.append(Order(entityID: entityID, quantity: quantityToAdd))
                    quantityNeeded = quantityNeeded - quantityToAdd
                } else {
                    break
                }
            }

            let purchaseData = PurchaseData(
                primarySaleID: data.primarySaleID,
                purchaserAddress: data.purchaserAddress,
                purchaserCollectionRef: data.purchaserCollectionRef,
                orders: orders,
                pool: data.pool
            )
            
            self.purchase(payment: <-payment, data: purchaseData)
        }

        access(self) fun purchase(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
        ) {
            pre {
                self.primarySaleID == data.primarySaleID: "primarySaleID mismatch"
                self.status == PrimarySaleStatus.OPEN: "primary sale is not open"
                data.orders.length > 0: "must purchase at least one NFT"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                self.pooledEntities.containsKey(data.pool):"Pool does not exist")
            }
            
            let priceData = self.prices[data.pool] ?? panic("Invalid pool")

            if priceData.eligibleAddresses != nil {
                // check if purchaser is in eligible address list
                if !priceData.eligibleAddresses!.contains(data.purchaserAddress) {
                     panic("Address is ineligible for purchase")
                }
            }

            // Check if payment type is supported
            let salePaymentVaultType: String = payment.getType().identifier
            let price: UFix64 = priceData.price[salePaymentVaultType] ?? panic("payment type not supported")
            

            // Gets the number of NFTs minted by this user
            let numMintedByUser = self.getNumMintedByUser(userAddress: data.purchaserAddress, pool: data.pool)

            // Check payment amount is correct
            var totalQuantity: UInt64 = 0
            for order in data.orders {
                totalQuantity = totalQuantity + order.quantity
            }

            // Heroes Of The Flow is sold in a box of 3 NFTs
            if self.contractName == "HeroesOfTheFlow" {
                totalQuantity = totalQuantity / 3
            }
            
            assert(payment.balance == price * UFix64(totalQuantity), message: "payment vault does not contain requested price")

            // Check maxMintsPerUser limit
            if priceData.maxMintsPerUser != nil {
                assert(totalQuantity + UInt64(numMintedByUser) <= priceData.maxMintsPerUser!, message: "maximum number of mints exceeded")
            }

            // Deposit payment to payment receiver based on vault type
            assert(self.paymentReceiverCaps.containsKey(salePaymentVaultType), message: "payment receiver capability does not exist for vault type: ".concat(salePaymentVaultType))
            let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
            receiver.deposit(from: <- payment)

            let minter = self.minterCap.borrow()!
            var i: Int = 0
            let purchasedNFTIds: [UInt64] = []
            while i < data.orders.length {
                let entityID = data.orders[i].entityID
                let quantity = data.orders[i].quantity
                let pooledDict = self.pooledEntities[data.pool]!
                assert(pooledDict.containsKey(entityID) && pooledDict[entityID]! >= quantity, message: "NFT is not available for purchase, entityID: ".concat(entityID.toString()))
                if pooledDict[entityID]! > quantity {
                    self.pooledEntities[data.pool]!.insert(key: entityID, pooledDict[entityID]! - quantity)
                } else {
                    self.pooledEntities[data.pool]!.remove(key: entityID)
                }

                var n: UInt64 = 0
                while n < quantity {
                    let nft <- minter.mint(entityID: entityID, minterAddress: data.purchaserAddress)
                    purchasedNFTIds.append(nft.id)
                    data.purchaserCollectionRef.deposit(token: <-nft)
                    n = n + 1
                }
                i = i + 1
            }
            emit PurchaseComplete(primarySaleID: self.primarySaleID, orders: data.orders, nftIDs: purchasedNFTIds, purchaserAddress: data.purchaserAddress, pool: data.pool, price: price, salePaymentVaultType: salePaymentVaultType)
            // Increments the number of NFTs minted by the user
            self.numMintedPerUser[data.pool]!.insert(key: data.purchaserAddress, numMintedByUser + totalQuantity)
        }
        
        pub fun getAllAvailableEntities(pool: String): {UInt64: UInt64} {
            var availableEntities: {UInt64: UInt64} = {}
            assert(self.pooledEntities.containsKey(pool), message: "Pool does not exist")
            let pooledDict = self.pooledEntities[pool]!
            for entityID in pooledDict.keys {
                availableEntities[entityID] = pooledDict[entityID]!
            }
            return availableEntities
        }

        pub fun getPooledEntities(): {String: {UInt64: UInt64}} {
            return self.pooledEntities
        }

        pub fun updateLaunchDate(date: String) {
            self.launchDate = date
        }

        pub fun updateEndDate(date: String) {
            self.endDate = date
        }

        pub fun updatePaymentReceiver(salePaymentVaultType: String, paymentReceiverCap: Capability<&{FungibleToken.Receiver}>) {
            pre {
                paymentReceiverCap.borrow() != nil: "Could not borrow payment receiver capability"
            }
            self.paymentReceiverCaps[salePaymentVaultType] = paymentReceiverCap
        }
    }

    // Admin is a special authorization resource that 
    // allows the owner to create primary sales
    //
    pub resource Admin {
        pub fun createPrimarySale(
            contractName: String,
            contractAddress: Address,
            prices: {String: PriceData},
            minterCap: Capability<&{IMinter}>,
            paymentReceiverCaps: {String: Capability<&{FungibleToken.Receiver}>},
            launchDate: String,
            endDate: String
        ) {
            pre {
                minterCap.borrow() != nil: "Could not borrow minter capability"
            }

            let key = contractName.concat(contractAddress.toString())
            assert(!FlowversePrimarySaleV2.primarySaleIDs.containsKey(key), message: "Primary sale with contractName, contractAddress already exists")

            var primarySale <- create PrimarySale(
                contractName: contractName,
                contractAddress: contractAddress,
                prices: prices,
                minterCap: minterCap,
                paymentReceiverCaps: paymentReceiverCaps,
                launchDate: launchDate,
                endDate: endDate
            )

            let primarySaleID = FlowversePrimarySaleV2.nextPrimarySaleID

            FlowversePrimarySaleV2.nextPrimarySaleID = FlowversePrimarySaleV2.nextPrimarySaleID + UInt64(1)

            FlowversePrimarySaleV2.primarySales[primarySaleID] <-! primarySale
        }

        pub fun getPrimarySale(primarySaleID: UInt64): &PrimarySale? {
            if FlowversePrimarySaleV2.primarySales.containsKey(primarySaleID) {
                return (&FlowversePrimarySaleV2.primarySales[primarySaleID] as &PrimarySale?)!
            }
            return nil
        }

        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }

    pub struct PrimarySaleData {
        pub let primarySaleID: UInt64
        pub let contractName: String
        pub let contractAddress: Address
        pub let supply: UInt64
        pub let prices: {String: FlowversePrimarySaleV2.PriceData}
        pub let status: String
        pub let pooledEntities: {String: {UInt64: UInt64}}
        pub let launchDate: String
        pub let endDate: String
        pub let numMintedPerUser: {String: {Address: UInt64}}
        pub let paymentReceivers: {String: Address} 

        init(
            primarySaleID: UInt64,
            contractName: String,
            contractAddress: Address,
            supply: UInt64,
            prices: {String: FlowversePrimarySaleV2.PriceData},
            status: String,
            pooledEntities: {String: {UInt64: UInt64}},
            launchDate: String,
            endDate: String,
            numMintedPerUser: {String: {Address: UInt64}},
            paymentReceivers: {String: Address} ,
        ) {
            self.primarySaleID = primarySaleID
            self.contractName = contractName
            self.contractAddress = contractAddress
            self.supply = supply
            self.prices = prices
            self.status = status
            self.pooledEntities = pooledEntities
            self.launchDate = launchDate
            self.endDate = endDate
            self.numMintedPerUser = numMintedPerUser
            self.paymentReceivers = paymentReceivers
        }
    }

    pub fun getPrimarySaleData(primarySaleID: UInt64): PrimarySaleData {
        pre {
            FlowversePrimarySaleV2.primarySales.containsKey(primarySaleID): "Primary sale does not exist"
        }
        let primarySale = (&FlowversePrimarySaleV2.primarySales[primarySaleID] as &PrimarySale?)!
        return PrimarySaleData(
            primarySaleID: primarySale.getID(),
            contractName: primarySale.getContractName(),
            contractAddress: primarySale.getContractAddress(),
            supply: primarySale.getSupply(pool: nil),
            prices: primarySale.getPrices(),
            status: primarySale.getStatus(),
            pooledEntities: primarySale.getPooledEntities(),
            launchDate: primarySale.getLaunchDate(),
            endDate: primarySale.getEndDate(),
            numMintedPerUser: primarySale.getNumMintedPerUser(),
            paymentReceivers: primarySale.getPaymentReceivers()
        )
    }
    
    pub fun getPrice(primarySaleID: UInt64, pool: String, salePaymentVaultType: String): UFix64 {
        pre {
            FlowversePrimarySaleV2.primarySales.containsKey(primarySaleID): "Primary sale does not exist"
        }
        let primarySale = (&FlowversePrimarySaleV2.primarySales[primarySaleID] as &PrimarySale?)!
        let prices = primarySale.getPrices()
        assert(prices.containsKey(pool), message: "pool does not exist")
        assert(prices[pool]!.price.containsKey(salePaymentVaultType), message: "salePaymentVaultType not supported")
        return prices[pool]!.price[salePaymentVaultType]!
    }

    pub fun purchaseHeroesBox(
        payment: @FungibleToken.Vault,
        data: PurchaseDataSequential,
        adminSignedPayload: AdminSignedPayload,
        signature: String
    ) {
        pre {
            FlowversePrimarySaleV2.primarySales.containsKey(data.primarySaleID): "Primary sale does not exist"
        }
        let primarySale = (&FlowversePrimarySaleV2.primarySales[data.primarySaleID] as &PrimarySale?)!
        primarySale.purchaseHeroesBox(payment: <-payment, data: data, adminSignedPayload: adminSignedPayload, signature: signature)
    }

    pub fun purchaseSequentialNFTs(
        payment: @FungibleToken.Vault,
        data: PurchaseDataSequential,
        adminSignedPayload: AdminSignedPayload,
        signature: String
    ) {
        pre {
            FlowversePrimarySaleV2.primarySales.containsKey(data.primarySaleID): "Primary sale does not exist"
        }
        let primarySale = (&FlowversePrimarySaleV2.primarySales[data.primarySaleID] as &PrimarySale?)!
        primarySale.purchaseSequentialNFTs(payment: <-payment, data: data, adminSignedPayload: adminSignedPayload, signature: signature)
    }

    pub fun getID(contractName: String, contractAddress: Address): UInt64 {
        let key = contractName.concat(contractAddress.toString())
        assert(FlowversePrimarySaleV2.primarySaleIDs.containsKey(key), message: "primary sale does not exist")
        return FlowversePrimarySaleV2.primarySaleIDs[key]!
    }

    init() {
        self.AdminStoragePath = /storage/FlowversePrimarySaleV2AdminStoragePath

        self.primarySales <- {}
        self.primarySaleIDs = {}

        self.nextPrimarySaleID = 1
        
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
