import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

pub contract TopShotEscrowV3 {

    // -----------------------------------------------------------------------
    // TopShotEscrowV3 contract Events
    // -----------------------------------------------------------------------

    pub event ContractInitialized()
    pub event Escrowed(id: UInt64, owner: Address, NFTIds: [UInt64], duration: UFix64, startTime: UFix64)
    pub event Redeemed(id: UInt64, owner: Address, NFTIds: [UInt64], partial: Bool, time: UFix64)
    pub event EscrowCancelled(id: UInt64, owner: Address, NFTIds: [UInt64], partial: Bool, time: UFix64)
    pub event EscrowWithdraw(id: UInt64, from: Address?)
    pub event EscrowUpdated(id: UInt64, owner: Address, NFTIds: [UInt64])

    // -----------------------------------------------------------------------
    // TopShotEscrowV3 contract-level fields.
    // These contain actual values that are stored in the smart contract.
    // -----------------------------------------------------------------------

    // The total amount of EscrowItems that have been created
    pub var totalEscrows: UInt64

    // Escrow Storage Path
    pub let escrowStoragePath: StoragePath

    /// Escrow Public Path
    pub let escrowPublicPath: PublicPath

    // -----------------------------------------------------------------------
    // TopShotEscrowV3 contract-level Composite Type definitions
    // -----------------------------------------------------------------------
    // These are just *definitions* for Types that this contract
    // and other accounts can use. These definitions do not contain
    // actual stored values, but an instance (or object) of one of these Types
    // can be created by this contract that contains stored values.
    // -----------------------------------------------------------------------

    // This struct contains the status of the escrow
    // and is exposed so websites can use escrow information
    pub struct EscrowDetails {
        pub let owner: Address
        pub let escrowID: UInt64
        pub let NFTIds: [UInt64]?
        pub let starTime: UFix64
        pub let duration : UFix64
        pub let isRedeemable : Bool
        
        init(_owner: Address,
            _escrowID: UInt64, 
            _NFTIds: [UInt64]?,
            _startTime: UFix64,
            _duration: UFix64, 
            _isRedeemable: Bool
        ) {
            self.owner = _owner
            self.escrowID = _escrowID
            self.NFTIds = _NFTIds
            self.starTime = _startTime
            self.duration = _duration
            self.isRedeemable = _isRedeemable
        }
    }

    // An interface that exposes public fields and functions
    // of the EscrowItem resource
    pub resource interface EscrowItemPublic {
        pub let escrowID: UInt64
        pub var redeemed: Bool
        pub fun hasBeenRedeemed(): Bool
        pub fun isRedeemable(): Bool
        pub fun getEscrowDetails(): EscrowDetails
        pub fun redeem(NFTIds: [UInt64])
        pub fun addNFTs(NFTCollection: @TopShot.Collection)
    }

    // EscrowItem contains a NFT Collection (single or several NFTs) for a single escrow
    // Fields and functions are defined as private by default
    // to access escrow details, one can call getEscrowDetails()
    pub resource EscrowItem: EscrowItemPublic {

        // The id of this individual escrow
        pub let escrowID: UInt64
        access(self) var NFTCollection: [UInt64]?
        pub let startTime:  UFix64
        access(self) var duration: UFix64
        pub var redeemed: Bool
        access(self) let receiverCap : Capability<&{TopShot.MomentCollectionPublic}>
        access(self) var lock: Bool

        init(
            _NFTCollection: @TopShot.Collection,
            _duration: UFix64,
            _receiverCap : Capability<&{TopShot.MomentCollectionPublic}> 
        ) {
            TopShotEscrowV3.totalEscrows = TopShotEscrowV3.totalEscrows + 1
            self.escrowID =  TopShotEscrowV3.totalEscrows
            self.NFTCollection = _NFTCollection.getIDs()
            assert(self.NFTCollection != nil, message: "NFT Collection is empty")
            self.startTime = getCurrentBlock().timestamp
            self.duration = _duration
            assert(_receiverCap.borrow() != nil, message: "Cannot borrow receiver")
            self.receiverCap = _receiverCap
            self.redeemed = false
            self.lock = false

            let adminTopShotReceiverRef = TopShotEscrowV3.account.getCapability(/public/MomentCollection).borrow<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>()
            ?? panic("Cannot borrow collection")
            
            for tokenId in self.NFTCollection! {
                    let token <- _NFTCollection.withdraw(withdrawID: tokenId)
                    adminTopShotReceiverRef.deposit(token: <-token)
            }

            assert(_NFTCollection.getIDs().length == 0, message: "can't destroy resources")
            destroy _NFTCollection
        }

        pub fun isRedeemable(): Bool {
            return getCurrentBlock().timestamp > self.startTime + self.duration
        }

        pub fun hasBeenRedeemed(): Bool {
            return self.redeemed
        }
        

        pub fun redeem(NFTIds: [UInt64]) {

            pre {
                !self.lock: "Reentrant call"
                self.isRedeemable() : "Not redeemable yet"
                !self.hasBeenRedeemed() : "Has already been redeemed"
            }
            post {
                !self.lock: "Lock not released"
            }
            self.lock = true

            let collectionRef = self.receiverCap.borrow() 
                                ?? panic("Cannot borrow receiver")

            let providerTopShotProviderRef: &TopShot.Collection? = TopShotEscrowV3.account.borrow<&TopShot.Collection>(from: /storage/MomentCollection) 
                    ?? panic("Cannot borrow collection")

            if (NFTIds.length == 0 || NFTIds.length == self.NFTCollection?.length){
                // Iterate through the keys in the collection and deposit each one
                for tokenId in self.NFTCollection! {
                    let token <- providerTopShotProviderRef?.withdraw(withdrawID: tokenId)!
                    collectionRef.deposit(token: <-token)
                }

                self.redeemed = true;

                emit Redeemed(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!, partial: false, time: getCurrentBlock().timestamp)
            } else {
                for NFTId in NFTIds {
                    let token <- providerTopShotProviderRef?.withdraw(withdrawID: NFTId)!
                    collectionRef.deposit(token: <-token)
                    let index = self.NFTCollection?.firstIndex(of: NFTId) ?? panic("NFT ID not found")
                    let removedId = self.NFTCollection?.remove(at: index !) ?? panic("NFT ID not found")
                    assert(removedId == NFTId, message: "NFT ID mismatch")
                }

                if (self.NFTCollection?.length == 0){
                    self.redeemed = true;
                }

                emit Redeemed(id: self.escrowID, owner: self.receiverCap.address, NFTIds: NFTIds, partial: !self.redeemed, time: getCurrentBlock().timestamp)
            }

            self.lock = false
        }

        pub fun getEscrowDetails(): EscrowDetails{
            return EscrowDetails(
                    _owner: self.receiverCap.address,
                    _escrowID: self.escrowID,
                    _NFTIds: self.NFTCollection,
                    _startTime: self.startTime,
                    _duration: self.duration,
                    _isRedeemable: self.isRedeemable()
                    )   
        }

        pub fun setEscrowDuration(_ newDuration: UFix64) {
            post {
                newDuration < self.duration : "Can only decrease duration"
            }
            self.duration = newDuration
        }

        pub fun cancelEscrow(NFTIds: [UInt64]) {
            pre {
                !self.hasBeenRedeemed() : "Has already been redeemed"
            }
            let collectionRef = self.receiverCap.borrow() 
                                ?? panic("Cannot borrow receiver")

            let providerTopShotProviderRef: &TopShot.Collection? = TopShotEscrowV3.account.borrow<&TopShot.Collection>(from: /storage/MomentCollection) 
                    ?? panic("Cannot borrow collection")

            if (NFTIds.length == 0 || NFTIds.length == self.NFTCollection?.length){
                self.redeemed = true;

                for tokenId in self.NFTCollection! {
                    let token <- providerTopShotProviderRef?.withdraw(withdrawID: tokenId)!
                    collectionRef.deposit(token: <-token)
                }

                emit EscrowCancelled(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!, partial: false, time: getCurrentBlock().timestamp)
            } else {
                for NFTId in NFTIds {
                    let token <- providerTopShotProviderRef?.withdraw(withdrawID: NFTId)!
                    collectionRef.deposit(token: <-token)
                    let index = self.NFTCollection?.firstIndex(of: NFTId) ?? panic("NFT ID not found")
                    let removedId = self.NFTCollection?.remove(at: index !) ?? panic("NFT ID not found")
                    assert(removedId == NFTId, message: "NFT ID mismatch")
                }

                if (self.NFTCollection?.length == 0){
                    self.redeemed = true;
                }

                emit EscrowCancelled(id: self.escrowID, owner: self.receiverCap.address, NFTIds: NFTIds, partial: !self.redeemed, time: getCurrentBlock().timestamp)
            }
        }

        pub fun addNFTs(NFTCollection: @TopShot.Collection) {
            pre {
                !self.hasBeenRedeemed() : "Has already been redeemed"
            }
            let NFTIds = NFTCollection.getIDs()
            let adminTopShotReceiverRef = TopShotEscrowV3.account.getCapability(/public/MomentCollection).borrow<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic}>()
            ?? panic("Cannot borrow collection")
            
            for NFTId in NFTIds {
                    let token <- NFTCollection.withdraw(withdrawID: NFTId)
                    adminTopShotReceiverRef.deposit(token: <-token)
            }

            assert(NFTCollection.getIDs().length == 0, message: "can't destroy resources")
            destroy NFTCollection

            self.NFTCollection!.appendAll(NFTIds)
            emit EscrowUpdated(id: self.escrowID, owner: self.receiverCap.address, NFTIds: self.NFTCollection!)
        }

        destroy() { 
            assert(self.redeemed, message: "Escrow not redeemed")
        }
    }

    // An interface to interact publicly with the Escrow Collection
    pub resource interface EscrowCollectionPublic {
        pub fun createEscrow(
                NFTCollection: @TopShot.Collection,
                duration: UFix64,
                receiverCap : Capability<&{TopShot.MomentCollectionPublic}>)

        pub fun borrowEscrow(escrowID: UInt64): &EscrowItem{EscrowItemPublic}?
        pub fun getEscrowIDs() : [UInt64]
    }

    // EscrowCollection contains a dictionary of EscrowItems 
    // and provides methods for manipulating the EscrowItems
    pub resource EscrowCollection: EscrowCollectionPublic {

        // Escrow Items
        access(self) var escrowItems: @{UInt64: EscrowItem}

        // withdraw
        // Removes an escrow from the collection and moves it to the caller
        pub fun withdraw(escrowID: UInt64): @TopShotEscrowV3.EscrowItem {
            let escrow <- self.escrowItems.remove(key: escrowID) ?? panic("missing NFT")

            emit EscrowWithdraw(id: escrow.escrowID, from: self.owner?.address)

            return <-escrow
        }


        init() {
            self.escrowItems <- {}
        }

        pub fun getEscrowIDs() : [UInt64] {
            return self.escrowItems.keys
        }

        pub fun createEscrow(
                NFTCollection: @TopShot.Collection,
                duration: UFix64,
                receiverCap : Capability<&{TopShot.MomentCollectionPublic}>) {

            let TopShotIds = NFTCollection.getIDs()

            assert(receiverCap.check(), message : "Non Valid Receiver Capability")

            // create a new escrow item resource container
            let item <- create EscrowItem(
                _NFTCollection: <- NFTCollection,
                _duration: duration,
                _receiverCap: receiverCap)

            let escrowID = item.escrowID
            let startTime = item.startTime
            // update the escrow items dictionary with the new resources
            let oldItem <- self.escrowItems[escrowID] <- item
            destroy oldItem

            let owner = receiverCap.address

            emit Escrowed(id: escrowID, owner: owner, NFTIds: TopShotIds, duration: duration, startTime: startTime)
        }

        pub fun borrowEscrow(escrowID: UInt64): &EscrowItem{EscrowItemPublic}? {
            // Get the escrow item resources
            if let escrowRef = (&self.escrowItems[escrowID] as &EscrowItem{EscrowItemPublic}?) {
                return escrowRef
            }
            return nil
        }

        pub fun createEscrowRef(escrowID: UInt64): &EscrowItem {
            // Get the escrow item resources
            let escrowRef = (&self.escrowItems[escrowID] as &EscrowItem?)!
            return escrowRef
        }

        destroy() {
            assert(self.escrowItems.length == 0, message: "Escrow items still exist")
            destroy self.escrowItems
        }
    }

    // -----------------------------------------------------------------------
    // TopShotEscrowV3 contract-level function definitions
    // -----------------------------------------------------------------------

    // createEscrowCollection returns a new EscrowCollection resource to the caller
    pub fun createEscrowCollection(): @EscrowCollection {
        let escrowCollection <- create EscrowCollection()

        return <- escrowCollection
    }

    // createEscrow
    pub fun createEscrow(
                _ NFTCollection: @TopShot.Collection,
                _ duration: UFix64,
                _ receiverCap : Capability<&{TopShot.MomentCollectionPublic}>) {
        let escrowCollectionRef = self.account.borrow<&TopShotEscrowV3.EscrowCollection>(from: self.escrowStoragePath) ??
                                                                    panic("Couldn't borrow escrow collection")
        escrowCollectionRef.createEscrow(NFTCollection: <- NFTCollection, duration: duration, receiverCap: receiverCap)
    }

    // redeem tokens
    pub fun redeem(_ escrowID: UInt64, _ NFTIds: [UInt64]) {
        let escrowCollectionRef = self.account.borrow<&TopShotEscrowV3.EscrowCollection>(from: self.escrowStoragePath) ??
                                                                    panic("Couldn't borrow escrow collection")
        let escrowRef = escrowCollectionRef.borrowEscrow(escrowID: escrowID)!
        escrowRef.redeem(NFTIds: NFTIds)
        if (escrowRef.redeemed){
            destroy <- escrowCollectionRef.withdraw(escrowID: escrowID)
        }
    }

    // batch redeem tokens
    pub fun batchRedeem(_ escrowIDs: [UInt64]) {

        for escrowID in escrowIDs {
            let escrowCollectionRef = self.account.borrow<&TopShotEscrowV3.EscrowCollection>(from: self.escrowStoragePath) ??
                                                                        panic("Couldn't borrow escrow collection")
            let escrowRef = escrowCollectionRef.borrowEscrow(escrowID: escrowID)!
            escrowRef.redeem(NFTIds: [])
            if (escrowRef.redeemed){
            destroy <- escrowCollectionRef.withdraw(escrowID: escrowID)
            }
        }
    }

    // -----------------------------------------------------------------------
    // TopShotEscrowV3 initialization function
    // -----------------------------------------------------------------------
    //

    init() {
        self.totalEscrows = 0
        self.escrowStoragePath= /storage/TopShotEscrowV3
        self.escrowPublicPath= /public/TopShotEscrowV3

        // Setup collection onto Deployer's account
        let escrowCollection <- self.createEscrowCollection()
        self.account.save(<- escrowCollection, to: self.escrowStoragePath)
        self.account.link<&TopShotEscrowV3.EscrowCollection{TopShotEscrowV3.EscrowCollectionPublic}>(self.escrowPublicPath, target: self.escrowStoragePath)
    }   
}
 