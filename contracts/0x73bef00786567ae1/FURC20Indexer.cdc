// Third-party imports
import StringUtils from "../0xa340dc0a4ec828ab/StringUtils.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
// FlowUp imports
import FlowUp from "./FlowUp.cdc"
import FURC20FTShared from "./FURC20FTShared.cdc"

access(all) contract FURC20Indexer {
    /* --- Events --- */
    /// Event emitted when the contract is initialized
    access(all) event ContractInitialized()

    /// Event emitted when the admin calls the sponsorship method
    access(all) event PlatformTreasurySponsorship(amount: UFix64, to: Address, forTick: String)

    /// Event emitted when a FURC20 token is deployed
    access(all) event FURC20Deployed(tick: String, max: UFix64, limit: UFix64, deployer: Address)
    /// Event emitted when a FURC20 token is minted
    access(all) event FURC20Minted(tick: String, amount: UFix64, to: Address)
    /// Event emitted when the owner of an inscription is updated
    access(all) event FURC20Transfer(tick: String, from: Address, to: Address, amount: UFix64)
    /// Event emitted when a FURC20 token is burned
    access(all) event FURC20Burned(tick: String, amount: UFix64, from: Address, flowExtracted: UFix64)
    /// Event emitted when a FURC20 token is withdrawn as change
    access(all) event FURC20WithdrawnAsChange(tick: String, amount: UFix64, from: Address)
    /// Event emitted when a FURC20 token is deposited from change
    access(all) event FURC20DepositedFromChange(tick: String, amount: UFix64, to: Address, from: Address)
    /// Event emitted when a FURC20 token is set to be burnable
    access(all) event FURC20BurnableSet(tick: String, burnable: Bool)
    /// Event emitted when a FURC20 token is burned unsupplied tokens
    access(all) event FURC20UnsuppliedBurned(tick: String, amount: UFix64)

    /* --- Variable, Enums and Structs --- */
    access(all)
    let IndexerStoragePath: StoragePath
    access(all)
    let IndexerPublicPath: PublicPath

    /* --- Interfaces & Resources --- */

    /// The meta-info of a FURC20 token
    access(all) struct FURC20Meta {
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
        fun getTokenMeta(tick: String): FURC20Meta?
        /// Get the token display info
        access(all) view
        fun getTokenDisplay(tick: String): FungibleTokenMetadataViews.FTDisplay?
        /// Check if an inscription is a valid FURC20 inscription
        access(all) view
        fun isValidFURC20Inscription(ins: &FlowUp.Inscription): Bool
        /// Get the balance of a FURC20 token
        access(all) view
        fun getBalance(tick: String, addr: Address): UFix64
        /// Get all balances of some address
        access(all) view
        fun getBalances(addr: Address): {String: UFix64}
        /// Get the holders of a FURC20 token
        access(all) view
        fun getHolders(tick: String): [Address]
        /// Get the amount of holders of a FURC20 token
        access(all) view
        fun getHoldersAmount(tick: String): UInt64
        /// Get the pool balance of a FURC20 token
        access(all) view
        fun getPoolBalance(tick: String): UFix64
        /// Get the benchmark value of a FURC20 token
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
        /// Deploy a new FURC20 token
        access(all)
        fun deploy(ins: &FlowUp.Inscription)
        /// Mint a FURC20 token
        access(all)
        fun mint(ins: &FlowUp.Inscription, flowToCreator: @FlowToken.Vault)
        /// Transfer a FURC20 token
        access(all)
        fun transfer(ins: &FlowUp.Inscription)
        /// Burn a FURC20 token
        access(all)
        fun burn(ins: &FlowUp.Inscription): @FlowToken.Vault
        /** ---- Account Methods for readonly ---- */
        /// Parse the metadata of a FURC20 inscription
        access(account) view
        fun parseMetadata(_ data: &FlowUp.InscriptionData): {String: String}
        /** ---- Account Methods for listing ---- */
        /// Building a selling FURC20 Token order with the sale cut from a FURC20 inscription
        /// This method will not extract all value of the inscription
        access(account)
        fun buildBuyNowListing(ins: &FlowUp.Inscription): @FURC20FTShared.ValidFrozenOrder
        /// Building a buying FURC20 Token order with the sale cut from a FURC20 inscription
        /// This method will not extract all value of the inscription
        access(account)
        fun buildSellNowListing(ins: &FlowUp.Inscription): @FURC20FTShared.ValidFrozenOrder
        /// Extract a part of the inscription's value to a FURC20 token change
        access(account)
        fun extractFlowVaultChangeFromInscription(_ ins: &FlowUp.Inscription, amount: UFix64): @FURC20FTShared.Change
        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applyBuyNowOrder(
            makerIns: &FlowUp.Inscription,
            takerIns: &FlowUp.Inscription,
            maxAmount: UFix64,
            change: @FURC20FTShared.Change
        ): @FURC20FTShared.Change
        /// Apply a listed order, maker and taker should be the same token and the same amount
        access(account)
        fun applySellNowOrder(
            makerIns: &FlowUp.Inscription,
            takerIns: &FlowUp.Inscription,
            maxAmount: UFix64,
            change: @FURC20FTShared.Change,
            _ distributeFlowTokenFunc: ((UFix64, @FlowToken.Vault): Bool)
        ): @FURC20FTShared.Change
        /// Cancel a listed order
        access(account)
        fun cancelListing(listedIns: &FlowUp.Inscription, change: @FURC20FTShared.Change)
        /// Return the change of a FURC20 order back to the owner
        access(account)
        fun returnChange(change: @FURC20FTShared.Change)
        /** ---- Account Methods for command inscriptions ---- */
        /// Set a FURC20 token to be burnable
        access(account)
        fun setBurnable(ins: &FlowUp.Inscription)
        // Burn unsupplied FURC20 tokens
        access(account)
        fun burnUnsupplied(ins: &FlowUp.Inscription)
        /// Allocate the tokens to some address
        access(account)
        fun allocate(ins: &FlowUp.Inscription): @FlowToken.Vault
        /// Extract the ins and ensure this ins is owned by the deployer
        access(account)
        fun executeByDeployer(ins: &FlowUp.Inscription): Bool
    }

    /// The resource that stores the inscriptions mapping
    ///
    access(all) resource InscriptionIndexer: IndexerPublic {
        /// The mapping of tokens
        access(self)
        let tokens: {String: FURC20Meta}
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
        fun getTokenMeta(tick: String): FURC20Meta? {
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
                .concat("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"-256 -256 512 512\" width=\"512\" height=\"512\">")
                .concat("<defs><linearGradient gradientUnits=\"userSpaceOnUse\" x1=\"0\" y1=\"-240\" x2=\"0\" y2=\"240\" id=\"gradient-0\" gradientTransform=\"matrix(0.908427, -0.41805, 0.320369, 0.696163, -69.267567, -90.441103)\"><stop offset=\"0\" style=\"stop-color: rgb(244, 246, 246);\"></stop><stop offset=\"1\" style=\"stop-color: rgb(35, 133, 91);\"></stop></linearGradient></defs>")
                .concat("<ellipse style=\"fill: rgb(149, 225, 192); stroke-width: 1rem; paint-order: fill; stroke: url(#gradient-0);\" ry=\"240\" rx=\"240\"></ellipse>")
                .concat("<text style=\"dominant-baseline: middle; fill: rgb(80, 213, 155); font-family: system-ui, sans-serif; text-anchor: middle;\" fill-opacity=\"0.2\" y=\"-12\" font-size=\"420\">𝔉</text>")
                .concat("<text style=\"dominant-baseline: middle; fill: rgb(244, 246, 246); font-family: system-ui, sans-serif; text-anchor: middle; font-style: italic; font-weight: 700;\" y=\"12\" font-size=\"").concat(tickNameSize.toString()).concat("\">")
                .concat(ticker).concat("</text></svg>")
            let medias = MetadataViews.Medias([MetadataViews.Media(
                file: MetadataViews.HTTPFile(url: svgStr),
                mediaType: "image/svg+xml"
            )])
            return FungibleTokenMetadataViews.FTDisplay(
                name: "FlowUp FURC20 - ".concat(ticker),
                symbol: ticker,
                description: "This is a FURC20 Fungible Token created by [FlowUp](https://flowup.world/).",
                externalURL: MetadataViews.ExternalURL("https://flowup.world/"),
                logos: medias,
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/")
                }
            )
        }

        /// Get the balance of a FURC20 token
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

        /// Get the holders of a FURC20 token
        access(all) view
        fun getHolders(tick: String): [Address] {
            let balancesRef = self._borrowBalancesRef(tick: tick)
            return balancesRef.keys
        }

        /// Get the amount of holders of a FURC20 token
        access(all) view
        fun getHoldersAmount(tick: String): UInt64 {
            return UInt64(self.getHolders(tick: tick.toLower()).length)
        }

        /// Get the pool balance of a FURC20 token
        ///
        access(all) view
        fun getPoolBalance(tick: String): UFix64 {
            let pool = self._borrowTokenTreasury(tick: tick)
            return pool.balance
        }

        /// Get the benchmark value of a FURC20 token
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

        /// Check if an inscription is a valid FURC20 inscription
        ///
        access(all) view
        fun isValidFURC20Inscription(ins: &FlowUp.Inscription): Bool {
            let p = ins.getMetaProtocol()
            return ins.getMimeType() == "text/plain" &&
                (p == "FURC20" || p == "FURC20" || p == "FURC-20" || p == "FURC-20")
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
            to: Capability<&FlowToken.Vault{FungibleToken.Receiver}>,
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

        /// Deploy a new FURC20 token
        ///
        access(all)
        fun deploy(ins: &FlowUp.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "deploy" && meta["tick"] != nil && meta["max"] != nil && meta["lim"] != nil,
                message: "The inscription is not a valid FURC20 inscription for deployment"
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
            self.tokens[tick] = FURC20Meta(
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
            emit FURC20Deployed(
                tick: tick,
                max: max,
                limit: limit,
                deployer: deployer
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Mint a FURC20 token
        ///
        access(all)
        fun mint(ins: &FlowUp.Inscription, flowToCreator: @FlowToken.Vault) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }
            let flowToAmount = flowToCreator.balance
            assert(
                flowToAmount >= 50.0,
                message: "The amount should be greater than 50.0"
            )
            let recipient: Address = 0x73bef00786567ae1
            let recipientVaultRef = getAccount(recipient)
            .getCapability(/public/flowTokenReceiver)
            .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
            ?? panic("Could not get receiver reference")
            recipientVaultRef.deposit(from: <-flowToCreator)

            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "mint" && meta["tick"] != nil && meta["amt"] != nil,
                message: "The inscription is not a valid FURC20 inscription for minting"
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
            emit FURC20Minted(
                tick: tick,
                amount: amtToAdd,
                to: fromAddr
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)           
        }

        /// Transfer a FURC20 token
        ///
        access(all)
        fun transfer(ins: &FlowUp.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "transfer" && meta["tick"] != nil && meta["amt"] != nil && meta["to"] != nil,
                message: "The inscription is not a valid FURC20 inscription for transfer"
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

        /// Burn a FURC20 token
        ///
        access(all)
        fun burn(ins: &FlowUp.Inscription): @FlowToken.Vault {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }
            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "burn" && meta["tick"] != nil && meta["amt"] != nil,
                message: "The inscription is not a valid FURC20 inscription for burning"
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
                emit FURC20Burned(
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

        /// Parse the metadata of a FURC20 inscription
        ///
        access(account) view
        fun parseMetadata(_ data: &FlowUp.InscriptionData): {String: String} {
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

        /// Set a FURC20 token to be burnable
        ///
        access(account)
        fun setBurnable(ins: &FlowUp.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
                // The command inscriptions should be only executed by the indexer
                self._isOwnedByIndexer(ins): "The inscription is not owned by the indexer"
            }
            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "burnable" && meta["tick"] != nil && meta["v"] != nil,
                message: "The inscription is not a valid FURC20 inscription for setting burnable"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let isTrue = meta["v"]! == "true" || meta["v"]! == "1"
            tokenMeta.setBurnable(isTrue)

            // emit event
            emit FURC20BurnableSet(
                tick: tick,
                burnable: isTrue
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Burn unsupplied FURC20 tokens
        ///
        access(account)
        fun burnUnsupplied(ins: &FlowUp.Inscription) {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
                // The command inscriptions should be only executed by the indexer
                self._isOwnedByIndexer(ins): "The inscription is not owned by the indexer"
            }
            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "burnUnsup" && meta["tick"] != nil && meta["perc"] != nil,
                message: "The inscription is not a valid FURC20 inscription for burning unsupplied tokens"
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
            emit FURC20UnsuppliedBurned(
                tick: tick,
                amount: amtToBurn
            )

            // extract inscription
            self._extractInscription(tick: tick, ins: ins)
        }

        /// Allocate the tokens to some address
        ///
        access(account)
        fun allocate(ins: &FlowUp.Inscription): @FlowToken.Vault {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "alloc" && meta["tick"] != nil && meta["amt"] != nil && meta["to"] != nil,
                message: "The inscription is not a valid FURC20 inscription for allocating"
            )

            let tick = self._parseTickerName(meta)
            let tokenMeta = self.borrowTokenMeta(tick: tick)
            let amt = UFix64.fromString(meta["amt"]!) ?? panic("The amount is not a valid UFix64")
            let to = Address.fromString(meta["to"]!) ?? panic("The receiver is not a valid address")
            let fromAddr = FURC20Indexer.getAddress()

            // call the internal transfer method
            self._transferToken(tick: tick, fromAddr: fromAddr, to: to, amt: amt)

            return <- ins.extract()
        }

        /// Extract the ins and ensure this ins is owned by the deployer
        ///
        access(account)
        fun executeByDeployer(ins: &FlowUp.Inscription): Bool {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            // only check the tick property
            assert(
                meta["tick"] != nil,
                message: "The inscription is not a valid FURC20 inscription for deployer execution"
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

        /// Building a selling FURC20 Token order with the sale cut from a FURC20 inscription
        ///
        access(account)
        fun buildBuyNowListing(ins: &FlowUp.Inscription): @FURC20FTShared.ValidFrozenOrder {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "list-buynow" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FURC20 inscription for listing"
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
            let order <- FURC20FTShared.createValidFrozenOrder(
                tick: tick,
                amount: amt,
                totalPrice: totalPrice,
                cuts: self._buildFURC20SaleCuts(sellerAddress: fromAddr),
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

        /// Building a buying FURC20 Token order with the sale cut from a FURC20 inscription
        ///
        access(account)
        fun buildSellNowListing(ins: &FlowUp.Inscription): @FURC20FTShared.ValidFrozenOrder {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
            }

            let meta = self.parseMetadata(&ins.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"] == "list-sellnow" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FURC20 inscription for listing"
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
            let order <- FURC20FTShared.createValidFrozenOrder(
                tick: tick,
                amount: amt,
                totalPrice: totalPrice,
                cuts: self._buildFURC20SaleCuts(sellerAddress: nil),
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
            makerIns: &FlowUp.Inscription,
            takerIns: &FlowUp.Inscription,
            maxAmount: UFix64,
            change: @FURC20FTShared.Change
        ): @FURC20FTShared.Change {
            pre {
                makerIns.isExtractable(): "The MAKER inscription is not extractable"
                takerIns.isExtractable(): "The TAKER inscription is not extractable"
                self.isValidFURC20Inscription(ins: makerIns): "The MAKER inscription is not a valid FURC20 inscription"
                self.isValidFURC20Inscription(ins: takerIns): "The TAKER inscription is not a valid FURC20 inscription"
                change.isBackedByVault() == false: "The change should not be backed by a vault"
                maxAmount > 0.0: "No Enough amount to transact"
                maxAmount <= change.getBalance(): "The max amount should be less than or equal to the change balance"
            }

            let makerMeta = self.parseMetadata(&makerIns.getData() as &FlowUp.InscriptionData)
            let takerMeta = self.parseMetadata(&takerIns.getData() as &FlowUp.InscriptionData)

            assert(
                makerMeta["op"] == "list-buynow" && makerMeta["tick"] != nil && makerMeta["amt"] != nil && makerMeta["price"] != nil,
                message: "The MAKER inscription is not a valid FURC20 inscription for listing"
            )
            assert(
                takerMeta["op"] == "list-take-buynow" && takerMeta["tick"] != nil && takerMeta["amt"] != nil,
                message: "The TAKER inscription is not a valid FURC20 inscription for taking listing"
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
            makerIns: &FlowUp.Inscription,
            takerIns: &FlowUp.Inscription,
            maxAmount: UFix64,
            change: @FURC20FTShared.Change,
            _ distributeFlowTokenFunc: ((UFix64, @FlowToken.Vault): Bool)
        ): @FURC20FTShared.Change {
            pre {
                makerIns.isExtractable(): "The MAKER inscription is not extractable"
                takerIns.isExtractable(): "The TAKER inscription is not extractable"
                self.isValidFURC20Inscription(ins: makerIns): "The MAKER inscription is not a valid FURC20 inscription"
                self.isValidFURC20Inscription(ins: takerIns): "The TAKER inscription is not a valid FURC20 inscription"
                maxAmount > 0.0: "No Enough amount to transact"
                change.isBackedByFlowTokenVault() == true: "The change should be backed by a flow vault"
            }

            let makerMeta = self.parseMetadata(&makerIns.getData() as &FlowUp.InscriptionData)
            let takerMeta = self.parseMetadata(&takerIns.getData() as &FlowUp.InscriptionData)

            assert(
                makerMeta["op"] == "list-sellnow" && makerMeta["tick"] != nil && makerMeta["amt"] != nil && makerMeta["price"] != nil,
                message: "The MAKER inscription is not a valid FURC20 inscription for listing"
            )
            assert(
                takerMeta["op"] == "list-take-sellnow" && takerMeta["tick"] != nil && takerMeta["amt"] != nil,
                message: "The TAKER inscription is not a valid FURC20 inscription for taking listing"
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
        fun cancelListing(listedIns: &FlowUp.Inscription, change: @FURC20FTShared.Change) {
            pre {
                listedIns.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: listedIns): "The inscription is not a valid FURC20 inscription"
            }

            let meta = self.parseMetadata(&listedIns.getData() as &FlowUp.InscriptionData)
            assert(
                meta["op"]?.slice(from: 0, upTo: 5) == "list-" && meta["tick"] != nil && meta["amt"] != nil && meta["price"] != nil,
                message: "The inscription is not a valid FURC20 inscription for listing"
            )
            let fromAddr = listedIns.owner!.address
            assert(
                fromAddr == change.from,
                message: "The listed owner should be the same as the change from address"
            )

            // deposit the token change return to change's from address
            let flowReceiver = FURC20Indexer.borrowFlowTokenReceiver(fromAddr)
                ?? panic("The flow receiver no found")
            // extract inscription and return flow in the inscription to the owner
            flowReceiver.deposit(from: <- listedIns.extract())

            // call the return change method
            self.returnChange(change: <- change)
        }

        /// Return the change of a FURC20 order back to the owner
        ///
        access(account)
        fun returnChange(change: @FURC20FTShared.Change) {
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
                let flowReceiver = FURC20Indexer.borrowFlowTokenReceiver(fromAddr)
                    ?? panic("The flow receiver no found")
                flowReceiver.deposit(from: <- (flowVault as! @FlowToken.Vault))
                destroy change
            } else if !change.isBackedByVault() {
                self._depositFromTokenChange(change: <- change, to: fromAddr)
            } else {
                panic("The change should not be backed by a vault that not a flow token vault")
            }
        }

        /// Extract a part of the inscription's value to a FURC20 token change
        ///
        access(account)
        fun extractFlowVaultChangeFromInscription(_ ins: &FlowUp.Inscription, amount: UFix64): @FURC20FTShared.Change {
            pre {
                ins.isExtractable(): "The inscription is not extractable"
                self.isValidFURC20Inscription(ins: ins): "The inscription is not a valid FURC20 inscription"
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
            return <- FURC20FTShared.createChange(
                tick: "", // empty tick means this change is a FLOW token change
                from: ins.owner!.address, // Pay $FLOW to the buyer and get the FURC20 token
                balance: nil,
                ftVault: <- vault
            )
        }

        /** ----- Private methods ----- */

        /// Build the sale cuts for a FURC20 order
        /// - Parameters:
        ///   - sellerAddress: The seller address, if it is nil, then it is a buy order
        ///
        access(self)
        fun _buildFURC20SaleCuts(sellerAddress: Address?): [FURC20FTShared.SaleCut] {
            let ret: [FURC20FTShared.SaleCut] = []

            // use the shared store to get the sale fee
            let sharedStore = FURC20FTShared.borrowGlobalStoreRef()
            // Default sales fee, 2% of the total price
            let salesFee = (sharedStore.getByEnum(FURC20FTShared.ConfigType.PlatformSalesFee) as! UFix64?) ?? 0.02
            assert(
                salesFee > 0.0 && salesFee <= 1.0,
                message: "The sales fee should be greater than 0.0 and less than or equal to 1.0"
            )

            // Default 40% of sales fee to the token treasury pool
            let treasuryPoolCut = (sharedStore.getByEnum(FURC20FTShared.ConfigType.PlatformSalesCutTreasuryPoolRatio) as! UFix64?) ?? 0.4
            // Default 25% of sales fee to the platform pool
            let platformTreasuryCut = (sharedStore.getByEnum(FURC20FTShared.ConfigType.PlatformSalesCutPlatformPoolRatio) as! UFix64?) ?? 0.25
            // Default 25% of sales fee to the stakers pool
            let platformStakersCut = (sharedStore.getByEnum(FURC20FTShared.ConfigType.PlatformSalesCutPlatformStakersRatio) as! UFix64?) ?? 0.25
            // Default 10% of sales fee to the marketplace portion cut
            let marketplacePortionCut = (sharedStore.getByEnum(FURC20FTShared.ConfigType.PlatformSalesCutMarketRatio) as! UFix64?) ?? 0.1

            // sum of all the cuts should be 1.0
            let totalCutsRatio = treasuryPoolCut + platformTreasuryCut + platformStakersCut + marketplacePortionCut
            assert(
                totalCutsRatio == 1.0,
                message: "The sum of all the cuts should be 1.0"
            )

            // add to the sale cuts
            // The first cut is the token treasury cut to ensure residualReceiver will be this
            ret.append(FURC20FTShared.SaleCut(
                type: FURC20FTShared.SaleCutType.TokenTreasury,
                amount: salesFee * treasuryPoolCut,
                receiver: nil
            ))
            ret.append(FURC20FTShared.SaleCut(
                type: FURC20FTShared.SaleCutType.PlatformTreasury,
                amount: salesFee * platformTreasuryCut,
                receiver: nil
            ))
            ret.append(FURC20FTShared.SaleCut(
                type: FURC20FTShared.SaleCutType.PlatformStakers,
                amount: salesFee * platformStakersCut,
                receiver: nil
            ))
            ret.append(FURC20FTShared.SaleCut(
                type: FURC20FTShared.SaleCutType.MarketplacePortion,
                amount: salesFee * marketplacePortionCut,
                receiver: nil
            ))

            // add the seller or buyer cut
            if sellerAddress != nil {
                // borrow the receiver reference
                let flowTokenReceiver = getAccount(sellerAddress!)
                    .getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                assert(
                    flowTokenReceiver.check(),
                    message: "Could not borrow receiver reference to the seller's Vault"
                )
                ret.append(FURC20FTShared.SaleCut(
                    type: FURC20FTShared.SaleCutType.SellMaker,
                    amount: (1.0 - salesFee),
                    // recevier is the FlowToken Vault of the seller
                    receiver: flowTokenReceiver
                ))
            } else {
                ret.append(FURC20FTShared.SaleCut(
                    type: FURC20FTShared.SaleCutType.BuyTaker,
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

        /// Internal Transfer a FURC20 token
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
            emit FURC20Transfer(
                tick: tick,
                from: fromAddr,
                to: to,
                amount: amt
            )
        }

        /// Internal Build a FURC20 token change
        ///
        access(self)
        fun _withdrawToTokenChange(
            tick: String,
            fromAddr: Address,
            amt: UFix64
        ): @FURC20FTShared.Change {
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
            emit FURC20WithdrawnAsChange(
                tick: tick,
                amount: amt,
                from: fromAddr
            )

            // create the FURC20 token change
            return <- FURC20FTShared.createChange(
                tick: tick,
                from: fromAddr,
                balance: amt,
                ftVault: nil
            )
        }

        /// Internal Deposit a FURC20 token change
        ///
        access(self)
        fun _depositFromTokenChange(
            change: @FURC20FTShared.Change,
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
            emit FURC20DepositedFromChange(
                tick: tick,
                amount: amt,
                to: to,
                from: change.from
            )

            // destroy the empty change
            destroy change
        }

        /// Internal Burn a FURC20 token
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
        fun _extractInscription(tick: String, ins: &FlowUp.Inscription) {
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
        fun _isOwnedByIndexer(_ ins: &FlowUp.Inscription): Bool {
            return ins.owner?.address == FURC20Indexer.getAddress()
        }

        /// Parse the ticker name from the meta-info of a FURC20 inscription
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
        fun borrowTokenMeta(tick: String): &FURC20Meta {
            let meta = &self.tokens[tick.toLower()] as &FURC20Meta?
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
    ): &FlowToken.Vault{FungibleToken.Receiver}? {
        let cap = getAccount(addr)
            .getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        return cap.borrow()
    }

    init() {
        let identifier = "FURC20Indexer_".concat(self.account.address.toString())
        self.IndexerStoragePath = StoragePath(identifier: identifier)!
        self.IndexerPublicPath = PublicPath(identifier: identifier)!
        // create the indexer
        self.account.save(<- create InscriptionIndexer(), to: self.IndexerStoragePath)
        self.account.link<&InscriptionIndexer{IndexerPublic}>(self.IndexerPublicPath, target: self.IndexerStoragePath)
    }
}