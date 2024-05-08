/**
> Author: FIXeS World <https://fixes.world/>

# FRC20 Indexer

This the main contract of FRC20, it is used to deploy and manage the FRC20 tokens.

*/
// Third-party imports
import StringUtils from "../0xa340dc0a4ec828ab/StringUtils.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
// Fixes imports
import Fixes from "./Fixes.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"

access(all) contract FRC20Indexer {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()

    /// Event emitted when the admin calls the sponsorship method
    access(all) event PlatformTreasurySponsorship(amount: UFix64, to: Address, forTick: String)
    /// Event emitted when the Treasury Withdrawn invoked
    access(all) event TokenTreasuryWithdrawn(tick: String, amount: UFix64, byInsId: UInt64, reason: String)

    /// Event emitted when a FRC20 token is deployed
    access(all) event FRC20Deployed(tick: String, max: UFix64, limit: UFix64, deployer: Address)
    /// Event emitted when a FRC20 token is minted
    access(all) event FRC20Minted(tick: String, amount: UFix64, to: Address)
    /// Event emitted when the owner of an inscription is updated
    access(all) event FRC20Transfer(tick: String, from: Address, to: Address, amount: UFix64)
    /// Event emitted when a FRC20 token is burned
    access(all) event FRC20Burned(tick: String, amount: UFix64, from: Address, flowExtracted: UFix64)
    /// Event emitted when a FRC20 token is withdrawn as change
    access(all) event FRC20WithdrawnAsChange(tick: String, amount: UFix64, from: Address)
    /// Event emitted when a FRC20 token is deposited from change
    access(all) event FRC20DepositedFromChange(tick: String, amount: UFix64, to: Address, from: Address)
    /// Event emitted when a FRC20 token is set to be burnable
    access(all) event FRC20BurnableSet(tick: String, burnable: Bool)
    /// Event emitted when a FRC20 token is burned unsupplied tokens
    access(all) event FRC20UnsuppliedBurned(tick: String, amount: UFix64)

    /* --- Variable, Enums and Structs --- */
    access(all)
    let IndexerStoragePath: StoragePath
    access(all)
    let IndexerPublicPath: PublicPath

    /* --- Interfaces & Resources --- */

    /// The meta-info of a FRC20 token
    access(all) struct FRC20Meta {
        access(all) let tick: String
        access(all) let max: UFix64
        access(all) let limit: UFix64
        access(all) let deployAt: UFix64
        access(all) let deployer: Address
        access(all) var burnable: Bool
        access(all) var supplied: UFix64
        access(all) var burned: UFix64

        init(
            tick: String,
            max: UFix64,
            limit: UFix64,
            deployAt: UFix64,
            deployer: Address,
            supplied: UFix64,
            burned: UFix64,
            burnable: Bool
        ) {
            self.tick = tick
            self.max = max
            self.limit = limit
            self.deployAt = deployAt
            self.deployer = deployer
            self.supplied = supplied
            self.burned = burned
            self.burnable = burnable
        }

        access(all)
        fun updateSupplied(_ amt: UFix64) {
            self.supplied = amt
        }

        access(all)
        fun updateBurned(_ amt: UFix64) {
            self.burned = amt
        }

        access(all)
        fun setBurnable(_ burnable: Bool) {
            self.burnable = burnable
        }
    }

    access(all) resource interface IndexerPublic {
        /* --- read-only --- */
        /// Get all the tokens
        access(all) view
        fun getTokens(): [String]
        /// Get the meta-info of a token
        access(all) view
        fun getTokenMeta(tick: String): FRC20Meta?
        /// Get the token display info
        access(all) view
        fun getTokenDisplay(tick: String): FungibleTokenMetadataViews.FTDisplay?
        /// Check if an inscription is a valid FRC20 inscription
        access(all) view
        fun isValidFRC20Inscription(ins: &Fixes.Inscription{Fixes.InscriptionPublic}): Bool
        /// Get the balance of a FRC20 token
        access(all) view
        fun getBalance(tick: String, addr: Address): UFix64
        /// Get all balances of some address
        access(all) view
        fun getBalances(addr: Address): {String: UFix64}
        /// Get the holders of a FRC20 token
        access(all) view
        fun getHolders(tick: String): [Address]
        /// Get the amount of holders of a FRC20 token
        access(all) view
        fun getHoldersAmount(tick: String): UInt64
        /// Get the pool balance of a FRC20 token
        access(all) view
        fun getPoolBalance(tick: String): UFix64
        /// Get the benchmark value of a FRC20 token
        access(all) view
        fun getBenchmarkValue(tick: String): UFix64
        /// Get the pool balance of platform treasury
        access(all) view
        fun getPlatformTreasuryBalance(): UFix64
        /** ---- borrow public interface ---- */
        /// Borrow the token's treasury $FLOW receiver
        access(all)
        fun borrowTokenTreasuryReceiver(tick: String): &FlowToken.Vault{FungibleToken.Receiver}
        /// Borrow the platform treasury $FLOW receiver
        access(all)
        fun borowPlatformTreasuryReceiver(): &FlowToken.Vault{FungibleToken.Receiver}
        /* --- write --- */
        /// Deploy a new FRC20 token
        access(all)
        fun deploy(ins: &Fixes.Inscription)
        /// Mint a FRC20 token
        access(all)
        fun mint(ins: &Fixes.Inscription)
        /// Transfer a FRC20 token
        access(all)
        fun transfer(ins: &Fixes.Inscription)
        /// Burn a FRC20 token
        access(all)
        fun burn(ins: &Fixes.Inscription): @FlowToken.Vault
        /** ---- Account Methods for readonly ---- */
        /// Parse the metadata of a FRC20 inscription
        access(account) view
        fun parseMetadata(_ data: &Fixes.InscriptionData): {String: String}
        /** ---- Account Methods for listing ---- */
        /// Building a selling FRC20 Token order with the sale cut from a FRC20 inscription
        /// This method will not extract all value of the inscription
        access(account)
        fun buildBuyNowListing(ins: &Fixes.Inscription): @FRC20FTShared.ValidFrozenOrder
        /// Building a buying FRC20 Token order with the sale cut from a FRC20 inscription
        /// This method will not extract all value of the inscription
        access(account)
        fun buildSellNowListing(ins: &Fixes.Inscription): @FRC20FTShared.ValidFrozenOrder
        /// Extract a part of the inscription's value to a FRC20 token change
        access(account)
        fun extractFlowVaultChangeFromInscription(_ ins: &Fixes.Inscription, amount: UFix64): @FRC20FTShared.Change
        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applyBuyNowOrder(
            makerIns: &Fixes.Inscription,
            takerIns: &Fixes.Inscription,
            maxAmount: UFix64,
            change: @FRC20FTShared.Change
        ): @FRC20FTShared.Change
        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applySellNowOrder(
            makerIns: &Fixes.Inscription,
            takerIns: &Fixes.Inscription,
            maxAmount: UFix64,
            change: @FRC20FTShared.Change,
            _ distributeFlowTokenFunc: ((UFix64, @FlowToken.Vault): Bool)
        ): @FRC20FTShared.Change
        /// Cancel a listed order
        access(account)
        fun cancelListing(listedIns: &Fixes.Inscription, change: @FRC20FTShared.Change)
        /// Withdraw amount of a FRC20 token by a FRC20 inscription
        access(account)
        fun withdrawChange(ins: &Fixes.Inscription): @FRC20FTShared.Change
        /// Deposit a FRC20 token change to indexer
        access(account)
        fun depositChange(ins: &Fixes.Inscription, change: @FRC20FTShared.Change)
        /// Return the change of a FRC20 order back to the owner
        access(account)
        fun returnChange(change: @FRC20FTShared.Change)
        /** ---- Account Methods for command inscriptions ---- */
        /// Set a FRC20 token to be burnable
        access(account)
        fun setBurnable(ins: &Fixes.Inscription)
        // Burn unsupplied frc20 tokens
        access(account)
        fun burnUnsupplied(ins: &Fixes.Inscription)
        /// Burn unsupplied frc20 tokens
        access(account)
        fun withdrawFromTreasury(ins: &Fixes.Inscription): @FRC20FTShared.Change
        /// Allocate the tokens to some address
        access(account)
        fun allocate(ins: &Fixes.Inscription): @FlowToken.Vault
        /// Extract the ins and ensure this ins is owned by the deployer
        access(account)
        fun executeByDeployer(ins: &Fixes.Inscription): Bool
    }

    /// The resource that stores the inscriptions mapping
    ///
    access(all) resource InscriptionIndexer: IndexerPublic {
        /// The mapping of tokens
        access(self)
        let tokens: {String: FRC20Meta}
        /// The mapping of balances
        access(self)
        let balances: {String: {Address: UFix64}}
        /// The extracted balance pool of the indexer
        access(self)
        let pool: @{String: FlowToken.Vault}
        /// The treasury of the indexer
        access(self)
        let treasury: @FlowToken.Vault

        init() {
            self.tokens = {}
            self.balances = {}
            self.pool <- {}
            self.treasury <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.treasury
            destroy self.pool
        }

        /* ---- Public methds ---- */

        /// Get all the tokens
        ///
        access(all) view
        fun getTokens(): [String] {
            return self.tokens.keys
        }

        /// Get the meta-info of a token
        ///
        access(all) view
        fun getTokenMeta(tick: String): FRC20Meta? {
            return self.tokens[tick.toLower()]
        }

        /// Get the token display info
        ///
        access(all) view
        fun getTokenDisplay(tick: String): FungibleTokenMetadataViews.FTDisplay? {
            let ticker = tick.toLower()
            if self.tokens[ticker] == nil {
                return nil
            }
            let tickNameSize = 80 + (10 - ticker.length > 0 ? 10 - ticker.length : 0) * 12
            let svgStr = "data:image/svg+xml;utf8,"
                .concat("%3Csvg%20xmlns%3D%5C%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%5C%22%20viewBox%3D%5C%22-256%20-256%20512%20512%5C%22%20width%3D%5C%22512%5C%22%20height%3D%5C%22512%5C%22%3E")
                .concat("%3Cdefs%3E%3ClinearGradient%20gradientUnits%3D%5C%22userSpaceOnUse%5C%22%20x1%3D%5C%220%5C%22%20y1%3D%5C%22-240%5C%22%20x2%3D%5C%220%5C%22%20y2%3D%5C%22240%5C%22%20id%3D%5C%22gradient-0%5C%22%20gradientTransform%3D%5C%22matrix(0.908427%2C%20-0.41805%2C%200.320369%2C%200.696163%2C%20-69.267567%2C%20-90.441103)%5C%22%3E%3Cstop%20offset%3D%5C%220%5C%22%20style%3D%5C%22stop-color%3A%20rgb(244%2C%20246%2C%20246)%3B%5C%22%3E%3C%2Fstop%3E%3Cstop%20offset%3D%5C%221%5C%22%20style%3D%5C%22stop-color%3A%20rgb(35%2C%20133%2C%2091)%3B%5C%22%3E%3C%2Fstop%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E")
                .concat("%3Cellipse%20style%3D%5C%22fill%3A%20rgb(149%2C%20225%2C%20192)%3B%20stroke-width%3A%201rem%3B%20paint-order%3A%20fill%3B%20stroke%3A%20url(%23gradient-0)%3B%5C%22%20ry%3D%5C%22240%5C%22%20rx%3D%5C%22240%5C%22%3E%3C%2Fellipse%3E")
                .concat("%3Ctext%20style%3D%5C%22dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(80%2C%20213%2C%20155)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20text-anchor%3A%20middle%3B%5C%22%20fill-opacity%3D%5C%220.2%5C%22%20y%3D%5C%22-12%5C%22%20font-size%3D%5C%22420%5C%22%3E%F0%9D%94%89%3C%2Ftext%3E")
                .concat("%3Ctext%20style%3D%5C%22dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(244%2C%20246%2C%20246)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20text-anchor%3A%20middle%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%5C%22%20y%3D%5C%2212%5C%22%20font-size%3D%5C%22").concat(tickNameSize.toString()).concat("%5C%22%3E")
                .concat(ticker).concat("%3C%2Ftext%3E%3C%2Fsvg%3E")
            let medias = MetadataViews.Medias([MetadataViews.Media(
                file: MetadataViews.HTTPFile(url: svgStr),
                mediaType: "image/svg+xml"
            )])
            return FungibleTokenMetadataViews.FTDisplay(
                name: "FIXeS FRC20 - ".concat(ticker),
                symbol: ticker,
                description: "This is a FRC20 Fungible Token created by [FIXeS](https://fixes.world/).",
                externalURL: MetadataViews.ExternalURL("https://fixes.world/"),
                logos: medias,
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/flowOnFlow")
                }
            )
        }

        /// Get the balance of a FRC20 token
        ///
        access(all) view
        fun getBalance(tick: String, addr: Address): UFix64 {
            let balancesRef = self._borrowBalancesRef(tick: tick)
            return balancesRef[addr] ?? 0.0
        }

        /// Get all balances of some address
        ///
        access(all) view
        fun getBalances(addr: Address): {String: UFix64} {
            let ret: {String: UFix64} = {}
            for tick in self.tokens.keys {
                let balancesRef = self._borrowBalancesRef(tick: tick)
                let balance = balancesRef[addr] ?? 0.0
                if balance > 0.0 {
                    ret[tick] = balance
                }
            }
            return ret
        }

        /// Get the holders of a FRC20 token
        access(all) view
        fun getHolders(tick: String): [Address] {
            let balancesRef = self._borrowBalancesRef(tick: tick)
            return balancesRef.keys
        }

        /// Get the amount of holders of a FRC20 token
        access(all) view
        fun getHoldersAmount(tick: String): UInt64 {
            return UInt64(self.getHolders(tick: tick.toLower()).length)
        }

        /// Get the pool balance of a FRC20 token
        ///
        access(all) view
        fun getPoolBalance(tick: String): UFix64 {
            let pool = self._borrowTokenTreasury(tick: tick)
            return pool.balance
        }

        /// Get the benchmark value of a FRC20 token
        access(all) view
        fun getBenchmarkValue(tick: String): UFix64 {
            let pool = self._borrowTokenTreasury(tick: tick)
            let meta = self.borrowTokenMeta(tick: tick)
            let totalExisting = meta.supplied.saturatingSubtract(meta.burned)
            if totalExisting > 0.0 {
                return pool.balance / totalExisting
            } else {
                return 0.0
            }
        }

        /// Get the pool balance of global
        ///
        access(all) view
        fun getPlatformTreasuryBalance(): UFix64 {
            return self.treasury.balance
        }

        /// Check if an inscription is a valid FRC20 inscription
        ///
        access(all) view
        fun isValidFRC20Inscription(ins: &Fixes.Inscription{Fixes.InscriptionPublic}): Bool {
            let p = ins.getMetaProtocol()
            return ins.getMimeType() == "text/plain" &&
                (p == "FRC20" || p == "frc20" || p == "frc-20" || p == "FRC-20")
        }

        /** ---- borrow public interface ---- */

        /// Borrow the token's treasury $FLOW receiver
        ///
        access(all)
        fun borrowTokenTreasuryReceiver(tick: String): &FlowToken.Vault{FungibleToken.Receiver} {
            let pool = self._borrowTokenTreasury(tick: tick)
            // Force cast to FungibleToken.Receiver, don't care about the warning, just for avoiding some mistakes
            return pool as &FlowToken.Vault{FungibleToken.Receiver}
        }

        /// Borrow the platform treasury $FLOW receiver
        ///
        access(all)
        fun borowPlatformTreasuryReceiver(): &FlowToken.Vault{FungibleToken.Receiver} {
            let pool = self._borrowPlatformTreasury()
            // Force cast to FungibleToken.Receiver, don't care about the warning, just for avoiding some mistakes
            return pool as &FlowToken.Vault{FungibleToken.Receiver}
        }

        // ---- Admin Methods ----

        /// Extract some $FLOW from global pool to sponsor the tick deployer
        ///
        access(all)
        fun sponsorship(
            amount: UFix64,
            to: Capability<&{FungibleToken.Receiver}>,
            forTick: String,
        ) {
            pre {
                amount > 0.0: "The amount should be greater than 0.0"
                to.check() != nil: "The receiver should be a valid capability"
            }

            let recipient = to.address
            let meta = self.borrowTokenMeta(tick: forTick)
            // The receiver should be the deployer of the token
            assert(
                recipient == meta.deployer,
                message: "The receiver should be the deployer of the token"
            )

            let platformPool = self._borrowPlatformTreasury()
            // check the balance
            assert(
                platformPool.balance >= amount,
                message: "The platform treasury does not have enough balance"
            )

            let flowReceiver = to.borrow()
                ?? panic("The receiver should be a valid capability")
            let supportedTypes = flowReceiver.getSupportedVaultTypes()
            assert(
                supportedTypes[Type<@FlowToken.Vault>()] == true,
                message: "The receiver should support the $FLOW vault"
            )

            let flowExtracted <- platformPool.withdraw(amount: amount)
            let sponsorAmt = flowExtracted.balance
            flowReceiver.deposit(from: <- (flowExtracted as! @FlowToken.Vault))

            emit PlatformTreasurySponsorship(
                amount: sponsorAmt,
                to: recipient,
                forTick: forTick
            )
        }

        /** ------ Functionality ------  */

        /// Deploy a new FRC20 token
        ///
        access(all)
        fun deploy(ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "deploy" && meta["tick"] != nil && meta["max"] != nil && meta["lim"] != nil,
                message: "The inscription is not a valid FRC20 inscription for deployment"
            )

            let tick = meta["tick"]!.toLower()
            assert(
                tick.length >= 3 && tick.length <= 10,
                message: "The token tick should be between 3 and 10 characters"
            )
            assert(
                self.tokens[tick] == nil && self.balances[tick] == nil && self.pool[tick] == nil,
                message: "The token has already been deployed"
            )
            let max = UFix64.fromString(meta["max"]!) ?? panic("The max supply is not a valid UFix64")
            let limit = UFix64.fromString(meta["lim"]!) ?? panic("The limit is not a valid UFix64")
            let deployer = ins.owner!.address
            let burnable = meta["burnable"] == "true" || meta["burnable"] == "1" // default to false
            self.tokens[tick] = FRC20Meta(
                tick: tick,
                max: max,
                limit: limit,
                deployAt: getCurrentBlock().timestamp,
                deployer: deployer,
                supplied: 0.0,
                burned: 0.0,
                burnable: burnable
            )
            self.balances[tick] = {} // init the balance mapping
            self.pool[tick] <-! FlowToken.createEmptyVault() as! @FlowToken.Vault // init the pool

            // emit event
            emit FRC20Deployed(
                tick: tick,
                max: max,
                limit: limit,
                deployer: deployer
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Mint a FRC20 token
        ///
        access(all)
        fun mint(ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "mint" && meta["tick"] != nil && meta["amt"] != nil,
                message: "The inscription is not a valid FRC20 inscription for minting"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            assert(
                tokenMeta.supplied < tokenMeta.max,
                message: "The token has reached the max supply"
            )
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            assert(
                amt > 0.0 && amt <= tokenMeta.limit,
                message: "The amount should be greater than 0.0 and less than the limit"
            )
            let fromAddr = ins.owner!.address

            // get the balance mapping
            let balancesRef = self._borrowBalancesRef(tick: tick)

            // check the limit
            var amtToAdd = amt
            if tokenMeta.supplied + amt > tokenMeta.max {
                amtToAdd = tokenMeta.max.saturatingSubtract(tokenMeta.supplied)
            }
            assert(
                amtToAdd > 0.0,
                message: "The amount should be greater than 0.0"
            )
            // update the balance
            if let oldBalance = balancesRef[fromAddr] {
                balancesRef[fromAddr] = oldBalance.saturatingAdd(amtToAdd)
            } else {
                balancesRef[fromAddr] = amtToAdd
            }
            tokenMeta.updateSupplied(tokenMeta.supplied + amtToAdd)

            // emit event
            emit FRC20Minted(
                tick: tick,
                amount: amtToAdd,
                to: fromAddr
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Transfer a FRC20 token
        ///
        access(all)
        fun transfer(ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "transfer" && meta["tick"] != nil && meta["amt"] != nil && meta["to"] != nil,
                message: "The inscription is not a valid FRC20 inscription for transfer"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let to = Address.fromString(meta["to"]!) ?? panic("The receiver is not a valid address")
            let fromAddr = ins.owner!.address

            // call the internal transfer method
            self._transferToken(tick: tick, fromAddr: fromAddr, to: to, amt: amt)

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Burn a FRC20 token
        ///
        access(all)
        fun burn(ins: &Fixes.Inscription): @FlowToken.Vault {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "burn" && meta["tick"] != nil && meta["amt"] != nil,
                message: "The inscription is not a valid FRC20 inscription for burning"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            assert(
                tokenMeta.burnable,
                message: "The token is not burnable"
            )
            assert(
                tokenMeta.supplied > tokenMeta.burned,
                message: "The token has been burned out"
            )
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let fromAddr = ins.owner!.address

            // get the balance mapping
            let balancesRef = self._borrowBalancesRef(tick: tick)

            // check the amount for from address
            let fromBalance = balancesRef[fromAddr] ?? panic("The from address does not have a balance")
            assert(
                fromBalance >= amt && amt > 0.0,
                message: "The from address does not have enough balance"
            )

            let oldBurned = tokenMeta.burned
            balancesRef[fromAddr] = fromBalance.saturatingSubtract(amt)
            self._burnTokenInternal(tick: tick, amountToBurn: amt)

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)

            // extract flow from pool
            let flowPool = self._borrowTokenTreasury(tick: tick)
            let restAmt = tokenMeta.supplied.saturatingSubtract(oldBurned)
            if restAmt > 0.0 {
                let flowTokenToExtract = flowPool.balance * amt / restAmt
                let flowExtracted <- flowPool.withdraw(amount: flowTokenToExtract)
                // emit event
                emit FRC20Burned(
                    tick: tick,
                    amount: amt,
                    from: fromAddr,
                    flowExtracted: flowExtracted.balance
                )
                return <- (flowExtracted as! @FlowToken.Vault)
            } else {
                return <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
            }
        }

        // ---- Account Methods ----

        /// Parse the metadata of a FRC20 inscription
        ///
        access(account) view
        fun parseMetadata(_ data: &Fixes.InscriptionData): {String: String} {
            let ret: {String: String} = {}
            if data.encoding != nil && data.encoding != "utf8" {
                panic("The inscription is not encoded in utf8")
            }
            // parse the body
            if let body = String.fromUTF8(data.metadata) {
                // split the pairs
                let pairs = StringUtils.split(body, ",")
                for pair in pairs {
                    // split the key and value
                    let kv = StringUtils.split(pair, "=")
                    if kv.length == 2 {
                        ret[kv[0]] = kv[1]
                    }
                }
            } else {
                panic("The inscription is not encoded in utf8")
            }
            return ret
        }

        // ---- Account Methods for command inscriptions ----

        /// Set a FRC20 token to be burnable
        ///
        access(account)
        fun setBurnable(ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
                // The command inscriptions should be only executed by the indexer
                self._isOwnedByIndexer(ins): "The inscription is not owned by the indexer"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "burnable" && meta["tick"] != nil && meta["v"] != nil,
                message: "The inscription is not a valid FRC20 inscription for setting burnable"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let isTrue = meta["v"]! == "true" || meta["v"]! == "1"
            tokenMeta.setBurnable(isTrue)

            // emit event
            emit FRC20BurnableSet(
                tick: tick,
                burnable: isTrue
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Burn unsupplied frc20 tokens
        ///
        access(account)
        fun burnUnsupplied(ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
                // The command inscriptions should be only executed by the indexer
                self._isOwnedByIndexer(ins): "The inscription is not owned by the indexer"
            }
            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "burnUnsup" && meta["tick"] != nil && meta["perc"] != nil,
                message: "The inscription is not a valid FRC20 inscription for burning unsupplied tokens"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            // check the burnable
            assert(
                tokenMeta.burnable,
                message: "The token is not burnable"
            )
            // check the supplied, should be less than the max
            assert(
                tokenMeta.supplied < tokenMeta.max,
                message: "The token has reached the max supply"
            )

            let perc = UFix64.fromString(meta["perc"]!) ?? panic("The percentage is not a valid UFix64")
            // check the percentage
            assert(
                perc > 0.0 && perc <= 1.0,
                message: "The percentage should be greater than 0.0 and less than or equal to 1.0"
            )

            // update the burned amount
            let totalUnsupplied = tokenMeta.max.saturatingSubtract(tokenMeta.supplied)
            let amtToBurn = totalUnsupplied * perc
            // update the meta-info: supplied and burned
            tokenMeta.updateSupplied(tokenMeta.supplied.saturatingAdd(amtToBurn))
            self._burnTokenInternal(tick: tick, amountToBurn: amtToBurn)

            // emit event
            emit FRC20UnsuppliedBurned(
                tick: tick,
                amount: amtToBurn
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Burn unsupplied frc20 tokens
        ///
        access(account)
        fun withdrawFromTreasury(ins: &Fixes.Inscription): @FRC20FTShared.Change {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
                // The command inscriptions should be only executed by the indexer
                self._isOwnedByIndexer(ins): "The inscription is not owned by the indexer"
            }
            post {
                result.isBackedByFlowTokenVault(): "The result should be backed by a FlowToken.Vault"
                result.getBalance() > 0.0: "The result should have a positive balance"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "withdrawFromTreasury" && meta["tick"] != nil && meta["amt"] != nil && meta["usage"] != nil,
                message: "The inscription is not a valid FRC20 inscription for withdrawing from treasury"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amtToWithdraw = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let usage = meta["usage"]!
            assert(
                usage == "lottery" || usage == "staking",
                message: "The usage should be 'lottery'"
            )

            let treasury = self._borrowTokenTreasury(tick: tick)
            assert(
                treasury.balance >= amtToWithdraw,
                message: "The treasury does not have enough balance"
            )

            let ret <- FRC20FTShared.wrapFungibleVaultChange(
                ftVault: <- treasury.withdraw(amount: amtToWithdraw),
                from: FRC20Indexer.getAddress()
            )

            assert(
                ret.getBalance() == amtToWithdraw,
                message: "The result should have the same balance as the amount to withdraw"
            )

            // emit event
            emit TokenTreasuryWithdrawn(
                tick: tick,
                amount: amtToWithdraw,
                byInsId: ins.getId(),
                reason: usage
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)

            return <- ret
        }

        /// Allocate the tokens to some address
        ///
        access(account)
        fun allocate(ins: &Fixes.Inscription): @FlowToken.Vault {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "alloc" && meta["tick"] != nil && meta["amt"] != nil && meta["to"] != nil,
                message: "The inscription is not a valid FRC20 inscription for allocating"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let to = Address.fromString(meta["to"]!) ?? panic("The receiver is not a valid address")
            let fromAddr = FRC20Indexer.getAddress()

            // call the internal transfer method
            self._transferToken(tick: tick, fromAddr: fromAddr, to: to, amt: amt)

            return <- ins.extract()
        }

        /// Extract the ins and ensure this ins is owned by the deployer
        ///
        access(account)
        fun executeByDeployer(ins: &Fixes.Inscription): Bool {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            // only check the tick property
            assert(
                meta["tick"] != nil,
                message: "The inscription is not a valid FRC20 inscription for deployer execution"
            )

            // only the deployer can execute the inscription
            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)

            assert(
                ins.owner!.address == tokenMeta.deployer,
                message: "The inscription is not owned by the deployer"
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)

            return true
        }

        /** ---- Account Methods without Inscription extrasction ---- */

        /// Building a selling FRC20 Token order with the sale cut from a FRC20 inscription
        ///
        access(account)
        fun buildBuyNowListing(ins: &Fixes.Inscription): @FRC20FTShared.ValidFrozenOrder {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "list-buynow" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FRC20 inscription for listing"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            assert(
                amt > 0.0,
                message: "The amount should be greater than 0.0"
            )

            // the price here means the total price
            let totalPrice = UFix64.fromString(meta["price"]!) ?? panic("The price is not a valid UFix64")

            let benchmarkValue = self.getBenchmarkValue(tick: tick)
            let benchmarkPrice = benchmarkValue * amt
            assert(
                totalPrice >= benchmarkPrice,
                message: "The price should be greater than or equal to the benchmark value: ".concat(benchmarkValue.toString())
            )
            // from address
            let fromAddr = ins.owner!.address

            // create the valid frozen order
            let order <- FRC20FTShared.createValidFrozenOrder(
                tick: tick,
                amount: amt,
                totalPrice: totalPrice,
                cuts: self._buildFRC20SaleCuts(sellerAddress: fromAddr),
                // withdraw the token to change
                change: <- self._withdrawToTokenChange(tick: tick, fromAddr: fromAddr, amt: amt),
            )
            assert(
                order.change != nil && order.change?.isBackedByVault() == false,
                message: "The 'BuyNow' listing change should not be backed by a vault"
            )
            assert(
                order.change?.getBalance() == amt,
                message: "The change amount should be same as the amount"
            )
            return <- order
        }

        /// Building a buying FRC20 Token order with the sale cut from a FRC20 inscription
        ///
        access(account)
        fun buildSellNowListing(ins: &Fixes.Inscription): @FRC20FTShared.ValidFrozenOrder {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "list-sellnow" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FRC20 inscription for listing"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            assert(
                amt > 0.0,
                message: "The amount should be greater than 0.0"
            )

            // the price here means the total price
            let totalPrice = UFix64.fromString(meta["price"]!) ?? panic("The price is not a valid UFix64")

            let benchmarkValue = self.getBenchmarkValue(tick: tick)
            let benchmarkPrice = benchmarkValue * amt
            assert(
                totalPrice >= benchmarkValue,
                message: "The price should be greater than or equal to the benchmark value: ".concat(benchmarkValue.toString())
            )

            // create the valid frozen order
            let order <- FRC20FTShared.createValidFrozenOrder(
                tick: tick,
                amount: amt,
                totalPrice: totalPrice,
                cuts: self._buildFRC20SaleCuts(sellerAddress: nil),
                change: <- self.extractFlowVaultChangeFromInscription(ins, amount: totalPrice),
            )
            assert(
                order.change != nil && order.change?.isBackedByFlowTokenVault() == true,
                message: "The 'SellNow' listing change should be backed by a vault"
            )
            assert(
                order.change?.getBalance() == totalPrice,
                message: "The 'SellNow' listing change amount should be same as the amount"
            )
            return <- order
        }

        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applyBuyNowOrder(
            makerIns: &Fixes.Inscription,
            takerIns: &Fixes.Inscription,
            maxAmount: UFix64,
            change: @FRC20FTShared.Change
        ): @FRC20FTShared.Change {
            pre {
                makerIns.isExtractable(): "The MAKER inscription is not extractable"
                takerIns.isExtractable(): "The TAKER inscription is not extractable"
                self.isValidFRC20Inscription(ins: makerIns): "The MAKER inscription is not a valid FRC20 inscription"
                self.isValidFRC20Inscription(ins: takerIns): "The TAKER inscription is not a valid FRC20 inscription"
                change.isBackedByVault() == false: "The change should not be backed by a vault"
                maxAmount > 0.0: "No Enough amount to transact"
                maxAmount <= change.getBalance(): "The max amount should be less than or equal to the change balance"
            }

            let makerMeta = self.parseMetadata(&makerIns.getData() as &Fixes.InscriptionData)
            let takerMeta = self.parseMetadata(&takerIns.getData() as &Fixes.InscriptionData)

            assert(
                makerMeta["op"] == "list-buynow" && makerMeta["tick"] != nil && makerMeta["amt"] != nil && makerMeta["price"] != nil,
                message: "The MAKER inscription is not a valid FRC20 inscription for listing"
            )
            assert(
                takerMeta["op"] == "list-take-buynow" && takerMeta["tick"] != nil && takerMeta["amt"] != nil,
                message: "The TAKER inscription is not a valid FRC20 inscription for taking listing"
            )

            let tick = self._parseTickerName(takerMeta)
            assert(
                makerMeta["tick"]!.toLower() == tick && change.tick == tick,
                message: "The MAKER and TAKER should be the same token"
            )
            let takerAmt = UFix64.fromString(takerMeta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let makerAmt = UFix64.fromString(makerMeta["amt"]!) ?? panic("The amount is not a valid UFix64")

            // the max amount should be less than or equal to the maker amount
            assert(
                maxAmount <= makerAmt,
                message: "The max takeable amount should be less than or equal to the maker amount"
            )
            // set the transact amount, max
            let transactAmount = takerAmt > maxAmount ? maxAmount : takerAmt
            assert(
                transactAmount > 0.0 && transactAmount <= change.getBalance(),
                message: "The transact amount should be greater than 0.0 and less than or equal to the change balance"
            )

            let makerAddr = makerIns.owner!.address
            let takerAddr = takerIns.owner!.address
            assert(
                makerAddr != takerAddr,
                message: "The MAKER and TAKER should be different address"
            )
            assert(
                makerAddr == change.from,
                message: "The MAKER should be the same address as the change from address"
            )

            // withdraw the token from the maker by given amount
            let tokenToTransfer <- change.withdrawAsChange(amount: transactAmount)

            // deposit the token change to the taker
            self._depositFromTokenChange(change: <- tokenToTransfer, to: takerAddr)

            // extract taker's inscription
            self._extractInscription(tick: tick, ins: takerIns)
            // check rest balance in the change, if empty, extract the maker's inscription
            if change.isEmpty() {
                self._extractInscription(tick: tick, ins: makerIns)
            }
            return <- change
        }

        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applySellNowOrder(
            makerIns: &Fixes.Inscription,
            takerIns: &Fixes.Inscription,
            maxAmount: UFix64,
            change: @FRC20FTShared.Change,
            _ distributeFlowTokenFunc: ((UFix64, @FlowToken.Vault): Bool)
        ): @FRC20FTShared.Change {
            pre {
                makerIns.isExtractable(): "The MAKER inscription is not extractable"
                takerIns.isExtractable(): "The TAKER inscription is not extractable"
                self.isValidFRC20Inscription(ins: makerIns): "The MAKER inscription is not a valid FRC20 inscription"
                self.isValidFRC20Inscription(ins: takerIns): "The TAKER inscription is not a valid FRC20 inscription"
                maxAmount > 0.0: "No Enough amount to transact"
                change.isBackedByFlowTokenVault() == true: "The change should be backed by a flow vault"
            }

            let makerMeta = self.parseMetadata(&makerIns.getData() as &Fixes.InscriptionData)
            let takerMeta = self.parseMetadata(&takerIns.getData() as &Fixes.InscriptionData)

            assert(
                makerMeta["op"] == "list-sellnow" && makerMeta["tick"] != nil && makerMeta["amt"] != nil && makerMeta["price"] != nil,
                message: "The MAKER inscription is not a valid FRC20 inscription for listing"
            )
            assert(
                takerMeta["op"] == "list-take-sellnow" && takerMeta["tick"] != nil && takerMeta["amt"] != nil,
                message: "The TAKER inscription is not a valid FRC20 inscription for taking listing"
            )

            let tick = self._parseTickerName(takerMeta)
            assert(
                makerMeta["tick"]!.toLower() == tick,
                message: "The MAKER and TAKER should be the same token"
            )
            let takerAmt = UFix64.fromString(takerMeta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let makerAmt = UFix64.fromString(makerMeta["amt"]!) ?? panic("The amount is not a valid UFix64")

            // the max amount should be less than or equal to the maker amount
            assert(
                maxAmount <= makerAmt,
                message: "The MAKER and TAKER should be the same amount"
            )
            // set the transact amount, max
            let transactAmount = takerAmt > maxAmount ? maxAmount : takerAmt

            let makerAddr = makerIns.owner!.address
            let takerAddr = takerIns.owner!.address
            assert(
                makerAddr != takerAddr,
                message: "The MAKER and TAKER should be different address"
            )
            assert(
                makerAddr == change.from,
                message: "The MAKER should be the same address as the change from address"
            )

            // the price here means the total price
            let totalPrice = UFix64.fromString(makerMeta["price"]!) ?? panic("The price is not a valid UFix64")
            let partialPrice = transactAmount / makerAmt * totalPrice

            // transfer token from taker to maker
            self._transferToken(tick: tick, fromAddr: takerAddr, to: makerAddr, amt: transactAmount)

            // withdraw the token from the maker by given amount
            let tokenToTransfer <- change.withdrawAsVault(amount: partialPrice)
            let isCompleted = distributeFlowTokenFunc(transactAmount, <- (tokenToTransfer as! @FlowToken.Vault))

            // extract inscription
            self._extractInscription(tick: tick, ins: takerIns)
            // check rest balance in the change, if empty, extract the maker's inscription
            if change.isEmpty() || isCompleted {
                self._extractInscription(tick: tick, ins: makerIns)
            }
            return <- change
        }

        /// Cancel a listed order
        access(account)
        fun cancelListing(listedIns: &Fixes.Inscription, change: @FRC20FTShared.Change) {
            pre {
                listedIns.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: listedIns): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&listedIns.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"]?.slice(from: 0, upTo: 5) == "list-" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FRC20 inscription for listing"
            )
            let fromAddr = listedIns.owner!.address
            assert(
                fromAddr == change.from,
                message: "The listed owner should be the same as the change from address"
            )

            // deposit the token change return to change's from address
            let flowReceiver = FRC20Indexer.borrowFlowTokenReceiver(fromAddr)
                ?? panic("The flow receiver no found")
            let supportedTypes = flowReceiver.getSupportedVaultTypes()
            assert(
                supportedTypes[Type<@FlowToken.Vault>()] == true,
                message: "The receiver should support the $FLOW vault"
            )
            // extract inscription and return flow in the inscription to the owner
            flowReceiver.deposit(from: <- listedIns.extract())

            // call the return change method
            self.returnChange(change: <- change)
        }

        /// Withdraw amount of a FRC20 token by a FRC20 inscription
        ///
        access(account)
        fun withdrawChange(ins: &Fixes.Inscription): @FRC20FTShared.Change {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "withdraw" && meta["tick"] != nil && meta["amt"] != nil && meta["usage"] != nil,
                message: "The inscription is not a valid FRC20 inscription for transfer"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let usage = meta["usage"]!
            assert(
                usage == "staking" || usage == "donate" || usage == "lottery",
                message: "The usage should be 'staking' or 'donate' or 'lottery'"
            )
            let fromAddr = ins.owner!.address

            let retChange <- self._withdrawToTokenChange(
                tick: tick,
                fromAddr: fromAddr,
                amt: amt
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)

            return <- retChange
        }

        /// Deposit a FRC20 token change to indexer
        ///
        access(account)
        fun depositChange(ins: &Fixes.Inscription, change: @FRC20FTShared.Change) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
                change.isBackedByVault() == false: "The change should not be backed by a vault"
            }

            let meta = self.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
            assert(
                meta["op"] == "deposit" && meta["tick"] != nil,
                message: "The inscription is not a valid FRC20 inscription for transfer"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            assert(
                tokenMeta.tick == change.tick,
                message: "The token should be the same as the change"
            )
            let fromAddr = ins.owner!.address

            self._depositFromTokenChange(change: <- change, to: fromAddr)

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Return the change of a FRC20 order back to the owner
        ///
        access(account)
        fun returnChange(change: @FRC20FTShared.Change) {
            // if the change is empty, destroy it and return
            if change.getBalance() == 0.0 {
                destroy change
                return
            }
            let fromAddr = change.from

            if change.isBackedByFlowTokenVault() {
                let flowVault <- change.extractAsVault()
                assert(
                    flowVault.getType() == Type<@FlowToken.Vault>(),
                    message: "The change should be a flow token vault"
                )
                // deposit the token change return to change's from address
                let flowReceiver = FRC20Indexer.borrowFlowTokenReceiver(fromAddr)
                    ?? panic("The flow receiver no found")
                let supportedTypes = flowReceiver.getSupportedVaultTypes()
                assert(
                    supportedTypes[Type<@FlowToken.Vault>()] == true,
                    message: "The receiver should support the $FLOW vault"
                )
                flowReceiver.deposit(from: <- (flowVault as! @FlowToken.Vault))
                destroy change
            } else if !change.isBackedByVault() {
                self._depositFromTokenChange(change: <- change, to: fromAddr)
            } else {
                panic("The change should not be backed by a vault that not a flow token vault")
            }
        }

        /// Extract a part of the inscription's value to a FRC20 token change
        ///
        access(account)
        fun extractFlowVaultChangeFromInscription(_ ins: &Fixes.Inscription, amount: UFix64): @FRC20FTShared.Change {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFRC20Inscription(ins: ins): "The inscription is not a valid FRC20 inscription"
            }
            post {
                ins.isExtractable() && ins.isValueValid(): "The inscription should be extractable and the value should be valid after partial extraction"
            }
            // extract payment from the buyer's inscription, the payment should be a FLOW token
            // the payment should be equal to the total price and the payer should be the buyer
            // in the partialExtract method, the inscription will be extracted if the payment is enough
            // and the inscription will be still extractable.
            let vault <- ins.partialExtract(amount)
            assert(
                vault.balance == amount,
                message: "The amount should be equal to the balance of the vault"
            )
            // return the change
            return <- FRC20FTShared.wrapFungibleVaultChange(
                ftVault: <- vault,
                from: ins.owner!.address, // Pay $FLOW to the buyer and get the FRC20 token
            )
        }

        /** ----- Private methods ----- */

        /// Build the sale cuts for a FRC20 order
        /// - Parameters:
        ///   - sellerAddress: The seller address, if it is nil, then it is a buy order
        ///
        access(self)
        fun _buildFRC20SaleCuts(sellerAddress: Address?): [FRC20FTShared.SaleCut] {
            let ret: [FRC20FTShared.SaleCut] = []

            // use the shared store to get the sale fee
            let sharedStore = FRC20FTShared.borrowGlobalStoreRef()
            // Default sales fee, 2% of the total price
            let salesFee = (sharedStore.getByEnum(FRC20FTShared.ConfigType.PlatformSalesFee) as! UFix64?) ?? 0.02
            assert(
                salesFee > 0.0 && salesFee <= 1.0,
                message: "The sales fee should be greater than 0.0 and less than or equal to 1.0"
            )

            // Default 40% of sales fee to the token treasury pool
            let treasuryPoolCut = (sharedStore.getByEnum(FRC20FTShared.ConfigType.PlatformSalesCutTreasuryPoolRatio) as! UFix64?) ?? 0.4
            // Default 25% of sales fee to the platform pool
            let platformTreasuryCut = (sharedStore.getByEnum(FRC20FTShared.ConfigType.PlatformSalesCutPlatformPoolRatio) as! UFix64?) ?? 0.25
            // Default 25% of sales fee to the stakers pool
            let platformStakersCut = (sharedStore.getByEnum(FRC20FTShared.ConfigType.PlatformSalesCutPlatformStakersRatio) as! UFix64?) ?? 0.25
            // Default 10% of sales fee to the marketplace portion cut
            let marketplacePortionCut = (sharedStore.getByEnum(FRC20FTShared.ConfigType.PlatformSalesCutMarketRatio) as! UFix64?) ?? 0.1

            // sum of all the cuts should be 1.0
            let totalCutsRatio = treasuryPoolCut + platformTreasuryCut + platformStakersCut + marketplacePortionCut
            assert(
                totalCutsRatio == 1.0,
                message: "The sum of all the cuts should be 1.0"
            )

            // add to the sale cuts
            // The first cut is the token treasury cut to ensure residualReceiver will be this
            ret.append(FRC20FTShared.SaleCut(
                type: FRC20FTShared.SaleCutType.TokenTreasury,
                amount: salesFee * treasuryPoolCut,
                receiver: nil
            ))
            ret.append(FRC20FTShared.SaleCut(
                type: FRC20FTShared.SaleCutType.PlatformTreasury,
                amount: salesFee * platformTreasuryCut,
                receiver: nil
            ))
            ret.append(FRC20FTShared.SaleCut(
                type: FRC20FTShared.SaleCutType.PlatformStakers,
                amount: salesFee * platformStakersCut,
                receiver: nil
            ))
            ret.append(FRC20FTShared.SaleCut(
                type: FRC20FTShared.SaleCutType.MarketplacePortion,
                amount: salesFee * marketplacePortionCut,
                receiver: nil
            ))

            // add the seller or buyer cut
            if sellerAddress != nil {
                // borrow the receiver reference
                let flowTokenReceiver = getAccount(sellerAddress!)
                    .getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                assert(
                    flowTokenReceiver.check(),
                    message: "Could not borrow receiver reference to the seller's Vault"
                )
                ret.append(FRC20FTShared.SaleCut(
                    type: FRC20FTShared.SaleCutType.SellMaker,
                    amount: (1.0 - salesFee),
                    // recevier is the FlowToken Vault of the seller
                    receiver: flowTokenReceiver
                ))
            } else {
                ret.append(FRC20FTShared.SaleCut(
                    type: FRC20FTShared.SaleCutType.BuyTaker,
                    amount: (1.0 - salesFee),
                    receiver: nil
                ))
            }

            // check cuts amount, should be same as the total price
            var totalRatio: UFix64 = 0.0
            for cut in ret {
                totalRatio = totalRatio.saturatingAdd(cut.ratio)
            }
            assert(
                totalRatio == 1.0,
                message: "The sum of all the cuts should be 1.0"
            )
            // return the sale cuts
            return ret
        }

        /// Internal Transfer a FRC20 token
        ///
        access(self)
        fun _transferToken(
            tick: String,
            fromAddr: Address,
            to: Address,
            amt: UFix64
        ) {
            let change <- self._withdrawToTokenChange(tick: tick, fromAddr: fromAddr, amt: amt)
            self._depositFromTokenChange(change: <- change, to: to)

            // emit event
            emit FRC20Transfer(
                tick: tick,
                from: fromAddr,
                to: to,
                amount: amt
            )
        }

        /// Internal Build a FRC20 token change
        ///
        access(self)
        fun _withdrawToTokenChange(
            tick: String,
            fromAddr: Address,
            amt: UFix64
        ): @FRC20FTShared.Change {
            post {
                result.isBackedByVault() == false: "The change should not be backed by a vault"
                result.getBalance() == amt: "The change balance should be same as the amount"
                self.getBalance(tick: tick, addr: fromAddr) == before(self.getBalance(tick: tick, addr: fromAddr)) - amt
                    : "The from address balance should be decreased by the amount"
            }
            // borrow the balance mapping
            let balancesRef = self._borrowBalancesRef(tick: tick)

            // check the amount for from address
            let fromBalance = balancesRef[fromAddr] ?? panic("The from address does not have a balance")
            assert(
                fromBalance >= amt && amt > 0.0,
                message: "The from address does not have enough balance"
            )

            balancesRef[fromAddr] = fromBalance.saturatingSubtract(amt)

            // emit event
            emit FRC20WithdrawnAsChange(
                tick: tick,
                amount: amt,
                from: fromAddr
            )

            // create the frc20 token change
            return <- FRC20FTShared.createChange(
                tick: tick,
                from: fromAddr,
                balance: amt,
                ftVault: nil
            )
        }

        /// Internal Deposit a FRC20 token change
        ///
        access(self)
        fun _depositFromTokenChange(
            change: @FRC20FTShared.Change,
            to: Address
        ) {
            pre {
                change.isBackedByVault() == false: "The change should not be backed by a vault"
            }
            let tick = change.tick
            let amt = change.extract()
            // borrow the balance mapping
            let balancesRef = self._borrowBalancesRef(tick: tick)

            // update the balance
            if let oldBalance = balancesRef[to] {
                balancesRef[to] = oldBalance.saturatingAdd(amt)
            } else {
                balancesRef[to] = amt
            }

            // emit event
            emit FRC20DepositedFromChange(
                tick: tick,
                amount: amt,
                to: to,
                from: change.from
            )

            // destroy the empty change
            destroy change
        }

        /// Internal Burn a FRC20 token
        ///
        access(self)
        fun _burnTokenInternal(tick: String, amountToBurn: UFix64) {
            let meta = self.borrowTokenMeta(tick: tick)
            let oldBurned = meta.burned
            meta.updateBurned(oldBurned.saturatingAdd(amountToBurn))
        }

        /// Extract the $FLOW from inscription
        ///
        access(self)
        fun _extractInscription(tick: String, ins: &Fixes.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.pool[tick] != nil: "The token has not been deployed"
            }

            // extract the tokens
            let token <- ins.extract()
            // 5% of the extracted tokens will be sent to the treasury
            let amtToTreasury = token.balance * 0.05
            // withdraw the tokens to the treasury
            let tokenToTreasuryVault <- token.withdraw(amount: amtToTreasury)

            // deposit the tokens to pool and treasury
            let pool = self._borrowTokenTreasury(tick: tick)
            let treasury = self._borrowPlatformTreasury()

            pool.deposit(from: <- token)
            treasury.deposit(from: <- tokenToTreasuryVault)
        }

        /// Check if an inscription is owned by the indexer
        ///
        access(self) view
        fun _isOwnedByIndexer(_ ins: &Fixes.Inscription): Bool {
            return ins.owner?.address == FRC20Indexer.getAddress()
        }

        /// Parse the ticker name from the meta-info of a FRC20 inscription
        ///
        access(self)
        fun _parseTickerName(_ meta: {String: String}): String {
            let tick = meta["tick"]?.toLower() ?? panic("The token tick is not found")
            assert(
                self.tokens[tick] != nil && self.balances[tick] != nil && self.pool[tick] != nil,
                message: "The token has not been deployed"
            )
            return tick
        }

        /// Borrow the meta-info of a token
        ///
        access(self)
        fun borrowTokenMeta(tick: String): &FRC20Meta {
            let meta = &self.tokens[tick.toLower()] as &FRC20Meta?
            return meta ?? panic("The token meta is not found")
        }

        /// Borrow the balance mapping of a token
        ///
        access(self)
        fun _borrowBalancesRef(tick: String): &{Address: UFix64} {
            let balancesRef = &self.balances[tick.toLower()] as &{Address: UFix64}?
            return balancesRef ?? panic("The token balance is not found")
        }

        /// Borrow the token's treasury $FLOW receiver
        ///
        access(self)
        fun _borrowTokenTreasury(tick: String): &FlowToken.Vault {
            let pool = &self.pool[tick.toLower()] as &FlowToken.Vault?
            return pool ?? panic("The token pool is not found")
        }

        /// Borrow the platform treasury $FLOW receiver
        ///
        access(self)
        fun _borrowPlatformTreasury(): &FlowToken.Vault {
            return &self.treasury as &FlowToken.Vault
        }
    }

    /* --- Public Methods --- */

    /// Get the address of the indexer
    ///
    access(all)
    fun getAddress(): Address {
        return self.account.address
    }

    /// Get the inscription indexer
    ///
    access(all)
    fun getIndexer(): &InscriptionIndexer{IndexerPublic} {
        let addr = self.account.address
        let cap = getAccount(addr)
            .getCapability<&InscriptionIndexer{IndexerPublic}>(self.IndexerPublicPath)
            .borrow()
        return cap ?? panic("Could not borrow InscriptionIndexer")
    }

    /// Helper method to get FlowToken receiver
    ///
    access(all)
    fun borrowFlowTokenReceiver(
        _ addr: Address
    ): &{FungibleToken.Receiver}? {
        let cap = getAccount(addr)
            .getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        return cap.borrow()
    }

    init() {
        let identifier = "FRC20Indexer_".concat(self.account.address.toString())
        self.IndexerStoragePath = StoragePath(identifier: identifier)!
        self.IndexerPublicPath = PublicPath(identifier: identifier)!
        // create the indexer
        self.account.save(<- create InscriptionIndexer(), to: self.IndexerStoragePath)
        self.account.link<&InscriptionIndexer{IndexerPublic}>(self.IndexerPublicPath, target: self.IndexerStoragePath)
    }
}
