/*
    OrdinalVendor.cdc

    Author: Brian Min brian@flowverse.co
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowversePass from "./FlowversePass.cdc"
import FlowverseSocks from "../0xce4c02539d1fabe8/FlowverseSocks.cdc"
import FlowverseShirt from "./FlowverseShirt.cdc"
import Crypto

access(all) contract OrdinalVendor {
    access(all) let AdminStoragePath: StoragePath
    
    access(contract) var vendor: @Vendor?

    // Mapping of domains to inscription numbers
    access(contract) var domains: {String: UInt64}

    // Inscription numbers for text and image type ordinals
    access(contract) var textIDs: [UInt64]
    access(contract) var imageIDs: [UInt64]

    // Restricted inscription numbers - flagged as inappropiate
    access(contract) var restrictedIDs: {UInt64: Bool}

    access(all) event ContractInitialized()

    access(all) event OrdinalPurchased(id: UInt64, type: String, purchaserAddress: Address, price: UFix64, salePaymentVaultType: String)
    access(all) event OrdinalPurchasedV2(id: UInt64, type: String, size: UInt64, purchaserAddress: Address, price: UFix64, salePaymentVaultType: String)
    access(all) event OrdinalRestricted(id: UInt64)

    access(all) resource interface IMinter {
        access(all) fun mint(creator: Address, type: String, data: String): @NonFungibleToken.NFT
    }

    access(all) struct PurchaseData {
        access(all) let type: String
        access(all) let inscriptionData: String
        access(all) let purchaserAddress: Address
        access(all) let purchaserCollectionRef: &{NonFungibleToken.Receiver}

        init(type: String, inscriptionData: String, purchaserAddress: Address, purchaserCollectionRef: &{NonFungibleToken.Receiver}){
            self.type = type
            self.inscriptionData = inscriptionData
            self.purchaserAddress = purchaserAddress
            self.purchaserCollectionRef = purchaserCollectionRef
        }
    }

    access(all) struct PriceData {
        access(all) let price: {String: UFix64}
        access(all) let type: String

        init(price: {String: UFix64}, type: String){
            self.price = price
            self.type = type
        }
    }

    access(all) struct AdminSignedPayload {
        access(all) let type: String
        access(all) let creator: Address
        access(all) let expiration: UInt64

        init(type: String, creator: Address, expiration: UInt64){
            self.type = type
            self.creator = creator
            self.expiration = expiration
        }

        access(all) fun toString(): String {
            return self.type.concat("-")
                .concat(self.creator.toString()).concat("-")
                .concat(self.expiration.toString())
        }
    }

    access(all) resource interface VendorPublic {
        access(all) fun purchaseDomain(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload, 
            signature: String
        )
        access(all) fun purchaseText(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload, 
            signature: String
        )
        access(all) fun purchaseImage(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload, 
            signature: String
        )
        access(all) fun getPrices(): {String: PriceData}
        access(all) fun getPaymentReceivers(): {String: Address}
    }

    access(all) resource Vendor: VendorPublic {
        access(self) let minterCap: Capability<&{IMinter}>
        access(self) var prices: {String: PriceData}
        access(self) var paymentReceiverCaps: {String: Capability<&{FungibleToken.Receiver}>}

        init(
            minterCap: Capability<&{IMinter}>,
            prices: {String: PriceData},
            paymentReceiverCaps: {String: Capability<&AnyResource{FungibleToken.Receiver}>}
        ) {
            self.minterCap = minterCap
            self.prices = prices
            self.paymentReceiverCaps = paymentReceiverCaps
        }

        access(all) fun setPrice(priceData: PriceData) {
            self.prices[priceData.type] = priceData
        }

        access(all) fun getPrices(): {String: PriceData} {
            return self.prices
        }

        access(all) fun setPaymentReceiver(salePaymentVaultType: String, paymentReceiverCap: Capability<&{FungibleToken.Receiver}>) {
            pre {
                paymentReceiverCap.borrow() != nil: "Could not borrow payment receiver capability"
            }
            self.paymentReceiverCaps[salePaymentVaultType] = paymentReceiverCap
        }

        access(all) fun getPaymentReceivers(): {String: Address}  {
            let paymentReceivers: {String: Address} = {}
            for salePaymentVaultType in self.paymentReceiverCaps.keys {
                let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
                if receiver.owner != nil {
                    paymentReceivers[salePaymentVaultType] = receiver.owner!.address
                }
            }
            return paymentReceivers
        }

        access(all) fun getPaymentReceiverAddress(salePaymentVaultType: String): Address? {
            assert(self.paymentReceiverCaps.containsKey(salePaymentVaultType), message: "payment receiver does not exist for vault type: ".concat(salePaymentVaultType))
            let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
            if receiver.owner != nil {
                return receiver.owner!.address
            }
            return nil
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

        access(self) fun validateDomain(domain: String, ownerAddress: Address) {
            var i = 0
            var index = -1
            while i < domain.length {
                if domain[i] == "." {
                    index = i
                    break
                }
                i = i + 1
            }
            assert(index != -1, message: "invalid domain")

            assert(OrdinalVendor.checkDomainAvailability(domain: domain), message: "domain already exists")

            let domainName = domain.slice(from: 0, upTo: index)
            let domainExtension = domain.slice(from: index + 1, upTo: domain.length)

            assert(
                domainExtension == "flow" || domainExtension == "flowverse" || domainExtension == "socks" || domainExtension == "shirt",
                message: "domain extension must be .flow, .flowverse, .socks, or .shirt"
            )
            assert(domainName.length <= 32, message: "domain name must be at most 32 characters long")

            let forbiddenChars = "!@#$%^&*()<>? ./\\`~+=,;:'\"[]{}|_"
            for c in forbiddenChars.utf8 {
                assert(!domainName.utf8.contains(c), message: "domain name contains forbidden characters")
            }

            // Check if domain name is lowercase
            assert(domainName == domainName.toLower(), message: "domain name must be lowercase")

             // Check if user owns a Flowverse Pass to be eligible for .flowverse domain
            if domainExtension == "flowverse" {
                let mysteryPassCollectionRef = getAccount(ownerAddress).getCapability(FlowversePass.CollectionPublicPath)
                    .borrow<&{FlowversePass.CollectionPublic}>()
                    ?? panic("FlowversePass Collection reference not found")
                assert(mysteryPassCollectionRef.getIDs().length > 0, message: "ineligible for .flowverse domain as user does not own a Flowverse Pass")
            }

            // Check if user owns a Flowverse Sock to be eligible for .socks domain
            if domainExtension == "socks" {
                let socksCollectionRef = getAccount(ownerAddress).getCapability(FlowverseSocks.CollectionPublicPath)
                    .borrow<&{FlowverseSocks.FlowverseSocksCollectionPublic}>()
                    ?? panic("FlowverseSocks Collection reference not found")
                assert(socksCollectionRef.getIDs().length > 0, message: "ineligible for .socks domain as user does not own a Flowverse Sock")
            }

            // Check if user owns a Flowverse Shirt to be eligible for .shirt domain
            if domainExtension == "shirt" {
                let shirtCollectionRef = getAccount(ownerAddress).getCapability(FlowverseShirt.CollectionPublicPath)
                    .borrow<&{FlowverseShirt.CollectionPublic}>()
                    ?? panic("FlowverseShirt Collection reference not found")
                assert(shirtCollectionRef.getIDs().length > 0, message: "ineligible for .shirt domain as user does not own a Flowverse Shirt")
            }
        }

        access(all) fun purchaseDomain(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload,
            signature: String
        ) {
            pre {
                data.type == "domain": "Invalid type (must be domain)"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp): "expired signature"
                self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature): "failed to validate signature for the purchase"
            }

            self.validateDomain(domain: data.inscriptionData, ownerAddress: data.purchaserAddress)
            self.handlePurchase(payment: <-payment, data: data)
        }

        access(all) fun purchaseText(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload,
            signature: String
        ) {
            pre {
                data.type == "text": "Invalid type (must be text)"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp): "expired signature"
                self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature): "failed to validate signature for the purchase"
                data.inscriptionData.length > 0: "text size must be greater than 0"
                data.inscriptionData.length <= 300000: "text must be less than or equal to 300KB"
            }

            self.handlePurchase(payment: <-payment, data: data)
        }

        access(all) fun purchaseImage(
            payment: @FungibleToken.Vault,
            data: PurchaseData,
            adminSignedPayload: AdminSignedPayload,
            signature: String
        ) {
            pre {
                data.type == "image" : "Invalid type (must be image)"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp): "expired signature"
                self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature): "failed to validate signature for the purchase"
                data.inscriptionData.length > 0: "image size must be greater than 0"
                data.inscriptionData.length <= 300000: "image size must be less than 300KB"
            }

            self.handlePurchase(payment: <-payment, data: data)
        }

        access(self) fun handlePurchase(
            payment: @FungibleToken.Vault,
            data: PurchaseData
        ) {
            pre {
                data.type == "image" || data.type == "text" || data.type == "domain" : "Invalid type (must be either image, text or domain)"
                self.minterCap.borrow() != nil: "cannot borrow minter"
                self.paymentReceiverCaps.containsKey(payment.getType().identifier): "payment receiver capability does not exist"
            }

            let salePaymentVaultType = payment.getType().identifier
            var size = UInt64(data.inscriptionData.length)
            if data.type == "domain" {
                size = OrdinalVendor.getDomainSize(domain: data.inscriptionData)
            }
            let price = OrdinalVendor.getPrice(size: size, type: data.type, salePaymentVaultType: salePaymentVaultType)
            assert(payment.balance == price, message: "payment vault does not contain requested price")

            let receiver = self.paymentReceiverCaps[salePaymentVaultType]!.borrow()!
            receiver.deposit(from: <- payment)

            let minter = self.minterCap.borrow()!
            let ordinal <- minter.mint(creator: data.purchaserAddress, type: data.type, data: data.inscriptionData)
            let inscriptionNumber = ordinal.id
            data.purchaserCollectionRef.deposit(token: <-ordinal)

            if data.type == "domain" {
                OrdinalVendor.domains[data.inscriptionData] = inscriptionNumber
            } else if data.type == "text" {
                OrdinalVendor.textIDs.append(inscriptionNumber)
            } else {
                OrdinalVendor.imageIDs.append(inscriptionNumber)
            }

            emit OrdinalPurchasedV2(id: inscriptionNumber, type: data.type, size: UInt64(data.inscriptionData.length), purchaserAddress: data.purchaserAddress, price: price, salePaymentVaultType: salePaymentVaultType)
        }

        access(all) fun updatePaymentReceiver(salePaymentVaultType: String, paymentReceiverCap: Capability<&{FungibleToken.Receiver}>) {
            pre {
                paymentReceiverCap.borrow() != nil: "Could not borrow payment receiver capability"
            }
            self.paymentReceiverCaps[salePaymentVaultType] = paymentReceiverCap
        }
    }

    access(all) resource Admin {
        access(all) fun initialise(
            minterCap: Capability<&{IMinter}>,
            prices: {String: PriceData},
            paymentReceiverCaps: {String: Capability<&AnyResource{FungibleToken.Receiver}>}
        ) {
            pre {
                minterCap.borrow() != nil: "Could not borrow minter capability"
            }
            
            let vendor <- create Vendor(
                minterCap: minterCap,
                prices: prices,
                paymentReceiverCaps: paymentReceiverCaps
            )
            OrdinalVendor.vendor <-! vendor
        }

        access(all) fun getVendor(): &Vendor? {
            if OrdinalVendor.vendor != nil {
                return (&OrdinalVendor.vendor as &Vendor?)!
            }
            return nil
        }

        access(all) fun addRestrictedID(id: UInt64) {
            pre {
                !OrdinalVendor.restrictedIDs.containsKey(id) : "ID already restricted"
            }
            OrdinalVendor.restrictedIDs.insert(key: id, true)
            emit OrdinalRestricted(id: id)
        }

        access(all) fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }

    access(all) fun purchaseOrdinal(
        payment: @FungibleToken.Vault,
        type: String,
        data: PurchaseData,
        adminSignedPayload: AdminSignedPayload, 
        signature: String
    ) {
        pre {
            OrdinalVendor.vendor != nil: "Vendor has not been initialised"
            type == "image" || type == "text" || type == "domain" : "Invalid type (must be either image, text or domain)"
        }
        let vendor = (&OrdinalVendor.vendor as &Vendor?)!
        if type == "domain" {
            vendor.purchaseDomain(payment: <-payment, data: data, adminSignedPayload: adminSignedPayload, signature: signature)
        } else if type == "text" {
            vendor.purchaseText(payment: <-payment, data: data, adminSignedPayload: adminSignedPayload, signature: signature)
        } else {
            vendor.purchaseImage(payment: <-payment, data: data, adminSignedPayload: adminSignedPayload, signature: signature)
        }
    }

    access(all) fun getPrice(size: UInt64, type: String, salePaymentVaultType: String): UFix64 {
        pre {
            size > 0: "size must be greater than 0"
            OrdinalVendor.vendor != nil: "Vendor has not been initialised"
        }
        let vendor = (&OrdinalVendor.vendor as &Vendor?)!
        let prices = vendor.getPrices()
        let priceData = prices[type] ?? panic("price does not exist")
        let price = priceData.price[salePaymentVaultType] ?? panic("payment type not supported")
        var multiplier = UFix64(1)
        if type == "image" {
            if size <= 10000 {
                multiplier = UFix64(1)
            } else if size <= 100000 {
                multiplier = UFix64(2)
            } else if size <= 200000 {
                multiplier = UFix64(3)
            } else {
                multiplier = UFix64(5)
            }
        } else if type == "domain" {
            if size == 1 {
                multiplier = UFix64(16)
            } else if size <= 2 {
                multiplier = UFix64(10)
            } else if size <= 3 {
                multiplier = UFix64(6)
            } else if size <= 4 {
                multiplier = UFix64(4)
            } else {
                multiplier = UFix64(1)
            }
        }
        return price * multiplier
    }

    access(all) fun getDomainSize(domain: String): UInt64 {
        var i = 0
        for c in domain {
            if c == "." {
                break
            }
            i = i + 1
        }
        assert(i > 0, message: "invalid domain")
        return UInt64(i)
    }

    access(all) fun checkDomainAvailability(domain: String): Bool {
        return OrdinalVendor.domains[domain] == nil
    }

    access(all) fun checkOrdinalRestricted(id: UInt64): Bool {
        return OrdinalVendor.restrictedIDs.containsKey(id)
    }
    
    pub struct OrdinalVendorInfo {
        pub let domains: {String: UInt64}
        pub let textIDs: [UInt64]
        pub let imageIDs: [UInt64]
        pub let restrictedIDs: {UInt64: Bool}
        pub let prices: {String: OrdinalVendor.PriceData}
        pub let paymentReceivers: {String: Address} 

        init(
            domains: {String: UInt64},
            textIDs: [UInt64],
            imageIDs: [UInt64],
            restrictedIDs: {UInt64: Bool},
            prices: {String: OrdinalVendor.PriceData},
            paymentReceivers: {String: Address} ,
        ) {
            self.domains = domains
            self.textIDs = textIDs
            self.imageIDs = imageIDs
            self.restrictedIDs = restrictedIDs
            self.prices = prices
            self.paymentReceivers = paymentReceivers
        }
    }

    pub fun getInfo(): OrdinalVendorInfo? {
        if OrdinalVendor.vendor != nil {
            let vendor = (&OrdinalVendor.vendor as &Vendor?)!
            return OrdinalVendorInfo(
                domains: OrdinalVendor.domains,
                textIDs: OrdinalVendor.textIDs,
                imageIDs: OrdinalVendor.imageIDs,
                restrictedIDs: OrdinalVendor.restrictedIDs,
                prices: vendor.getPrices(),
                paymentReceivers: vendor.getPaymentReceivers()
            )
        }
        return nil
    }

    init() {
        self.AdminStoragePath = /storage/OrdinalVendorAdminStoragePath

        self.vendor <- nil
        self.domains = {}
        self.textIDs = []
        self.imageIDs = []
        self.restrictedIDs = {}
        
        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
 