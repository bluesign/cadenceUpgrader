/**
> Author: FIXeS World <https://fixes.world/>

# FRC20Storefront

TODO: Add description

*/
// Third-party imports
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
// Fixes imports
import Fixes from "./Fixes.cdc"
import FRC20FTShared from "./FRC20FTShared.cdc"
import FRC20Indexer from "./FRC20Indexer.cdc"
import FRC20AccountsPool from "./FRC20AccountsPool.cdc"

access(all) contract FRC20Storefront {

    /* --- Events --- */

    access(all) event StorefrontInitialized(uuid: UInt64)

    access(all) event ListingAvailable(
        storefrontAddress: Address,
        storefrontId: UInt64,
        listingResourceID: UInt64,
        inscriptionId: UInt64,
        type: UInt8,
        tick: String,
        amount: UFix64,
        totalPrice: UFix64,
        customID: String?,
        commissionReceivers: [Address]?,
    )

    access(all) event ListingPartiallyDeal(
        storefrontAddress: Address,
        storefrontId: UInt64,
        listingResourceID: UInt64,
        inscriptionId: UInt64,
        type: UInt8,
        tick: String,
        totalAmount: UFix64,
        transactedAmount: UFix64,
        transactedPrice: UFix64,
        customID: String?,
        commissionAmount: UFix64,
        commissionReceiver: Address?,
    )
    access(all) event ListingCompleted(
        storefrontAddress: Address,
        storefrontId: UInt64,
        listingResourceID: UInt64,
        inscriptionId: UInt64,
        type: UInt8,
        tick: String,
        amount: UFix64,
        totalPrice: UFix64,
        customID: String?,
        commissionAmount: UFix64,
        commissionReceiver: Address?,
    )
    access(all) event ListingCancelled(
        storefrontAddress: Address,
        storefrontId: UInt64,
        listingResourceID: UInt64,
        inscriptionId: UInt64,
        type: UInt8,
        tick: String,
        amount: UFix64,
        price: UFix64,
        customID: String?,
    )
    access(all) event ListingRemoved(
        storefrontAddress: Address,
        storefrontId: UInt64,
        listingResourceID: UInt64,
        inscriptionId: UInt64,
        customID: String?,
        withStatus: UInt8,
    )

    /// UnpaidReceiver
    /// A entitled receiver has not been paid during the sale of the NFT.
    ///
    access(all) event UnpaidReceiver(receiver: Address, entitledSaleCut: UFix64)


    /* --- Variable, Enums and Structs --- */
    access(all)
    let StorefrontStoragePath: StoragePath
    access(all)
    let StorefrontPublicPath: PublicPath

    /* --- Interfaces & Resources --- */

    access(all) enum ListingStatus: UInt8 {
        access(all) case Available
        access(all) case Completed
        access(all) case Cancelled
    }

    access(all) enum ListingType: UInt8 {
        access(all) case FixedPriceBuyNow
        access(all) case FixedPriceSellNow
    }

    /// ListingDetails
    /// A struct containing a Listing's data.
    ///
    access(all) struct ListingDetails {
        // constants data values
        access(all)
        let storefrontId: UInt64
        access(all)
        let inscriptionId: UInt64
        access(all)
        let type: ListingType
        access(all)
        let tick: String
        access(all)
        let amount: UFix64
        /// Sale cuts
        access(all)
        let saleCuts: [FRC20FTShared.SaleCut]
        // Calculated values
        access(all)
        let totalPrice: UFix64
        access(all)
        let priceValuePerMint: UFix64
        /// Created time of the listing
        access(all)
        let createdAt: UInt64
        // variables
        /// Whether this listing has been purchased or not.
        access(all)
        var status: ListingStatus
        /// Allow different dapp teams to provide custom strings as the distinguished string
        /// that would help them to filter events related to their customID.
        access(all)
        var customID: String?
        access(all)
        var transactedAmount: UFix64

        /// Initializer
        ///
        init (
            storefrontId: UInt64,
            inscriptionId: UInt64,
            type: ListingType,
            tick: String,
            amount: UFix64,
            totalPrice: UFix64,
            saleCuts: [FRC20FTShared.SaleCut],
            customID: String?
        ) {
            pre {
                // Validate the length of the sale cut
                saleCuts.length > 0: "Listing must have at least one payment cut recipient"
                totalPrice > 0.0: "Listing must have non-zero price"
                amount > 0.0: "Listing must have non-zero amount"
            }
            let tokenMeta = FRC20Indexer.getIndexer().getTokenMeta(tick: tick)
                ?? panic("Unable to fetch the token meta")

            self.createdAt = UInt64(getCurrentBlock().timestamp)
            self.storefrontId = storefrontId
            self.inscriptionId = inscriptionId
            self.type = type
            self.tick = tick
            self.amount = amount
            self.totalPrice = totalPrice
            self.transactedAmount = 0.0

            self.saleCuts = saleCuts
            self.customID = customID
            self.status = ListingStatus.Available

            // Calculate the total price from the cuts
            var totalRatio = 0.0
            // Perform initial check on capabilities, and calculate sale price from cut amounts.
            for cut in self.saleCuts {
                // Make sure we can borrow the receiver.
                // We will check this again when the token is sold.
                if cut.type == FRC20FTShared.SaleCutType.SellMaker {
                    cut.receiver?.borrow()
                        ?? panic("Cannot borrow receiver")
                }
                // Add the cut amount to the total price
                totalRatio = totalRatio + cut.ratio
            }
            // total ratio should be 1.0
            assert(totalRatio == 1.0, message: "Total ratio should be 1.0")

            // Store the calculated price value per mint
            self.priceValuePerMint = self.totalPrice * tokenMeta.limit / amount
        }

        /// Get the price per token
        ///
        access(all) view
        fun pricePerToken(): UFix64 {
            return self.totalPrice / self.amount
        }

        /// Get the price rank
        access(all) view
        fun priceRank(): UInt64 {
            return UInt64(100000.0 / self.amount * self.totalPrice)
        }

        /// Return if the listing is completed.
        ///
        access(all) view
        fun isCompleted(): Bool {
            return self.status == ListingStatus.Completed
        }

        /// Return if the listing is cancelled.
        ///
        access(all) view
        fun isCancelled(): Bool {
            return self.status == ListingStatus.Cancelled
        }

        /// Return if the listing is fully transacted.
        ///
        access(all) view
        fun isFullyTransacted(): Bool {
            return self.transactedAmount == self.amount
        }

        access(all) view
        fun getPriceByTransactedAmount(_ transactedAmount: UFix64): UFix64 {
            pre {
                transactedAmount <= self.amount: "Transacted amount should not exceed the total amount"
            }
            return self.totalPrice.saturatingMultiply(transactedAmount / self.amount)
        }

        /// Irreversibly set this listing as completed.
        ///
        access(contract)
        fun setToCompleted() {
            pre {
                self.status == ListingStatus.Available: "Listing must be available"
                self.isFullyTransacted(): "Listing must be fully transacted"
            }
            self.status = ListingStatus.Completed
        }

        /// Irreversibly set this listing as cancelled.
        ///
        access(contract)
        fun setToCancelled() {
            pre {
                self.status == ListingStatus.Available: "Listing must be available"
            }
            self.status = ListingStatus.Cancelled
        }

        /// Set the customID
        ///
        access(contract)
        fun setCustomID(customID: String?){
            self.customID = customID
        }

        /// Update the transacted amount
        ///
        access(contract)
        fun transact(amount: UFix64) {
            pre {
                self.transactedAmount.saturatingAdd(amount) <= self.amount: "Transacted amount should not exceed the total amount"
            }
            self.transactedAmount = self.transactedAmount.saturatingAdd(amount)
        }
    }

    /// ListingPublic
    /// An interface providing a useful public interface to a Listing.
    ///
    access(all) resource interface ListingPublic {
        /** ---- Public Methods ---- */

        /// Get the address of the owner of the NFT that is being sold.
        access(all) view
        fun getOwnerAddress(): Address

        /// The listing frc20 token name
        access(all) view
        fun getTickName(): String

        /// Borrow the listing token Meta for the selling FRC20 token
        access(all) view
        fun getTickMeta(): FRC20Indexer.FRC20Meta

        /// Fetches the details of the listing.
        access(all) view
        fun getDetails(): ListingDetails

        /// Fetches the status
        access(all) view
        fun getStatus(): ListingStatus

        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If it returns `nil` then commission is up to grab by anyone.
        access(all) view
        fun getAllowedCommissionReceivers(): [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]?

        /// Purchase the listing, buying the token.
        /// This pays the beneficiaries and returns the token to the buyer.
        ///
        access(all)
        fun takeBuyNow(
            ins: &Fixes.Inscription,
            commissionRecipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?,
        )

        /// Purchase the listing, selling the token.
        /// This pays the beneficiaries and returns the token to the buyer.
        access(all)
        fun takeSellNow(
            ins: &Fixes.Inscription,
            commissionRecipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?,
        )

        /** ---- Internal Methods ---- */

        /// borrow the inscription reference
        access(contract)
        fun borrowInspection(): &Fixes.Inscription
    }


    /// Listing
    /// A resource that allows an NFT to be sold for an amount of a given FungibleToken,
    /// and for the proceeds of that sale to be split between several recipients.
    ///
    access(all) resource Listing: ListingPublic {
        /// The simple (non-Capability, non-complex) details of the sale
        access(self)
        let details: ListingDetails
        /// An optional list of marketplaces capabilities that are approved
        /// to receive the marketplace commission.
        access(contract)
        let commissionRecipientCaps: [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]?
        /// The frozen change for this listing.
        access(contract)
        var frozenChange: @FRC20FTShared.Change?

        /// initializer
        ///
        init (
            storefrontId: UInt64,
            listIns: &Fixes.Inscription,
            commissionRecipientCaps: [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]?,
            customID: String?
        ) {
            // Store the commission recipients capability
            self.commissionRecipientCaps = commissionRecipientCaps

            // Analyze the listing inscription and build the details
            let indexer = FRC20Indexer.getIndexer()
            // find the op first
            let meta = indexer.parseMetadata(&listIns.getData() as &Fixes.InscriptionData)
            let op = meta["op"]?.toLower() ?? panic("The token operation is not found")

            var order: @FRC20FTShared.ValidFrozenOrder? <- nil
            var listType: ListingType = ListingType.FixedPriceBuyNow
            switch op {
            case "list-buynow":
                order <-! indexer.buildBuyNowListing(ins: listIns)
                assert(
                    order?.tick == order?.change?.tick && order?.amount == order?.change?.getBalance(),
                    message: "Tick and amount in the inscription and the change should be the same"
                )
                listType = ListingType.FixedPriceBuyNow
                break
            case "list-sellnow":
                order <-! indexer.buildSellNowListing(ins: listIns)
                listType = ListingType.FixedPriceSellNow
                break
            default:
                panic("Unsupported listing operation")
            }

            // Store the change
            self.frozenChange <- order?.extract() ?? panic("Unable to extract the change")
            // Store the list information
            self.details = ListingDetails(
                storefrontId: storefrontId,
                inscriptionId: listIns.getId(),
                type: listType,
                tick: order?.tick ?? panic("Unable to fetch the tick"),
                amount: order?.amount ?? panic("Unable to fetch the amount"),
                totalPrice: order?.totalPrice ?? panic("Unable to fetch the total price"),
                saleCuts: order?.cuts ?? panic("Unable to fetch the cuts"),
                customID: customID
            )
            // Destroy stored order
            destroy order
        }

        /// @deprecated after Cadence 1.0
        destroy() {
            pre {
                self.details.status == ListingStatus.Completed || self.details.status == ListingStatus.Cancelled:
                    "Listing must be purchased or cancelled"
                self.frozenChange == nil: "Frozen change must be nil"
            }
            destroy self.frozenChange
        }

        // ListingPublic interface implementation

        /// getOwnerAddress
        /// Fetches the address of the owner of the NFT that is being sold.
        ///
        access(all) view
        fun getOwnerAddress(): Address {
            return self.owner?.address ?? panic("Get owner address failed")
        }

        /// The listing frc20 token name
        ///
        access(all) view
        fun getTickName(): String {
            return self.details.tick
        }

        /// borrow the Token Meta for the selling FRC20 token
        ///
        access(all) view
        fun getTickMeta(): FRC20Indexer.FRC20Meta {
            let indexer = FRC20Indexer.getIndexer()
            return indexer.getTokenMeta(tick: self.details.tick)
                ?? panic("Unable to fetch the token meta")
        }

        /// Fetches the status
        ///
        access(all) view
        fun getStatus(): ListingStatus {
            return self.details.status
        }

        /// Get the details of listing.
        ///
        access(all) view
        fun getDetails(): ListingDetails {
            return self.details
        }

        /// getAllowedCommissionReceivers
        /// Fetches the allowed marketplaces capabilities or commission receivers.
        /// If it returns `nil` then commission is up to grab by anyone.
        access(all) view
        fun getAllowedCommissionReceivers(): [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]? {
            return self.commissionRecipientCaps
        }

        /// purchase
        /// Purchase the listing, buying the token.
        /// This pays the beneficiaries and returns the token to the buyer.
        ///
        access(all)
        fun takeBuyNow(
            ins: &Fixes.Inscription,
            commissionRecipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?,
        ) {
            pre {
                self.details.type == ListingType.FixedPriceBuyNow: "Listing must be a buy now listing"
                self.details.status == ListingStatus.Available: "Listing must be available"
                self.owner != nil : "Resource doesn't have the assigned owner"
            }

            // just check if the inscription is valid, the further check will be done in applyListedOrder
            assert(
                FRC20Storefront.isListFRC20Inscription(ins: ins),
                message: "Given inscription is not a valid FRC20 listing inscription"
            )

            // Some singleton resources
            let frc20Indexer = FRC20Indexer.getIndexer()

            // give the change to the buyer
            var frc20TokenChange: @FRC20FTShared.Change? <- nil
            frc20TokenChange <-> self.frozenChange
            assert(
                frc20TokenChange != nil && frc20TokenChange?.isBackedByVault() == false,
                message: "Frozen change should be backed by a non-vault change"
            )

            let currentAmount = frc20TokenChange?.getBalance() ?? panic("Unable to fetch the current amount")
            let maxAmount = self.details.amount - self.details.transactedAmount

            let sellerIns = self.borrowInspection()
            let seller = sellerIns.owner?.address ?? panic("Unable to fetch the seller address")
            let buyer = ins.owner?.address ?? panic("Unable to fetch the buyer address")
            let storefrontAddress = self.owner?.address ?? panic("Unable to fetch the storefront address")
            assert(
                seller != buyer && seller == storefrontAddress,
                message: "Seller should be the storefront address and buyer should not be the storefront address"
            )

            // The change to use
            let extractedFlowChange <- frc20Indexer.extractFlowVaultChangeFromInscription(
                ins,
                amount: ins.getInscriptionValue() - ins.getMinCost()
            )
            assert(
                extractedFlowChange.from == buyer
                && extractedFlowChange.tick == ""
                && extractedFlowChange.getVaultType() == Type<@FlowToken.Vault>(),
                message: "Extracted change should be backed by the inscription owner"
            )

            // apply the change and both inscriptions in frc20 indexer
            var restChange <- frc20Indexer.applyBuyNowOrder(
                makerIns: sellerIns,
                takerIns: ins,
                maxAmount: maxAmount,
                change: <- (frc20TokenChange ?? panic("Unable to extract the change")),
            )
            let transactedAmt = currentAmount.saturatingSubtract(restChange.getBalance())
            // update the transacted amount
            self.details.transact(amount: transactedAmt)

            assert(
                self.details.amount - self.details.transactedAmount == restChange.getBalance(),
                message: "Un-transacted amount should be equal to the change balance"
            )

            // re-store the change
            self.frozenChange <-! restChange

            // transacted price should be paid to the sale cuts
            let transactedPrice = self.details.getPriceByTransactedAmount(transactedAmt)
            assert(
                extractedFlowChange.getBalance() >= transactedPrice,
                message: "Insufficient payment value"
            )

            // The payment vault for the sale.
            let flowVault <- extractedFlowChange.withdrawAsVault(amount: transactedPrice)

            // Pay the sale cuts to the recipients.
            let commissionAmount = self._payToSaleCuts(
                payment: <- (flowVault as! @FlowToken.Vault),
                commissionRecipient: commissionRecipient,
                paymentRecipient: nil,
            )

            // Pay the residual change to the buyer.
            if extractedFlowChange.getBalance() > 0.0 {
                // If there is residual change, pay to the buyer
                let residualVault <- extractedFlowChange.extractAsVault()
                destroy extractedFlowChange
                let buyerVault = FRC20Indexer.borrowFlowTokenReceiver(buyer)
                    ?? panic("Unable to fetch the buyer vault")
                buyerVault.deposit(from: <- residualVault)
            } else {
                destroy extractedFlowChange
            }

            // handle the transaction deal
            self._onTransactionDeal(
                storefrontAddress: storefrontAddress,
                seller: seller,
                buyer: buyer,
                transactedAmt: transactedAmt,
                transactedPrice: transactedPrice,
                commissionAmount: commissionAmount,
                commissionRecipientAddress: commissionRecipient?.address
            )
        }

        /// Purchase the listing, selling the token.
        /// This pays the beneficiaries and returns the token to the buyer.
        access(all)
        fun takeSellNow(
            ins: &Fixes.Inscription,
            commissionRecipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?,
        ) {
            pre {
                self.details.type == ListingType.FixedPriceSellNow: "Listing must be a buy now listing"
                self.details.status == ListingStatus.Available: "Listing must be available"
                self.owner != nil : "Resource doesn't have the assigned owner"
            }

            // just check if the inscription is valid, the further check will be done in applyListedOrder
            assert(
                FRC20Storefront.isListFRC20Inscription(ins: ins),
                message: "Given inscription is not a valid FRC20 listing inscription"
            )

            // The indexer for all the FRC20 tokens.
            let frc20Indexer = FRC20Indexer.getIndexer()

            // give the change to the buyer
            var flowTokenChange: @FRC20FTShared.Change? <- nil
            flowTokenChange <-> self.frozenChange

            assert(
                flowTokenChange != nil && flowTokenChange?.isBackedByFlowTokenVault() == true,
                message: "Frozen change should be backed by a vault change"
            )

            let maxAmount = self.details.amount - self.details.transactedAmount

            let buyerIns = self.borrowInspection()
            let buyer = buyerIns.owner?.address ?? panic("Unable to fetch the buyer address")
            let seller = ins.owner?.address ?? panic("Unable to fetch the seller address")
            let storefrontAddress = self.owner?.address ?? panic("Unable to fetch the storefront address")
            assert(
                seller != buyer && buyer == storefrontAddress,
                message: "Buyer should be the storefront address and seller should not be the storefront address"
            )

            let detailRef = &self.details as &ListingDetails
            var payment: @FlowToken.Vault? <- nil
            var transactedAmt: UFix64? = nil
            let restChange <- frc20Indexer.applySellNowOrder(
                makerIns: buyerIns,
                takerIns: ins,
                maxAmount: maxAmount,
                change: <- (flowTokenChange ?? panic("Unable to get the flow token change")),
                fun (_ realTransactedAmt: UFix64, flowToPay: @FlowToken.Vault): Bool {
                    pre {
                        realTransactedAmt > 0.0 : "Transacted amount should be greater than zero"
                        flowToPay.balance > 0.0 : "Payment amount should be greater than zero"
                    }
                    // update the transacted amount
                    detailRef.transact(amount: realTransactedAmt)
                    // cache the transacted amount
                    transactedAmt = realTransactedAmt
                    // cache the payment vault to the caller
                    payment <-! flowToPay
                    // return true if the listing is fully transacted
                    return detailRef.isFullyTransacted()
                }
            )

            // re-store the change
            self.frozenChange <-! restChange

            let transactedPrice = payment?.balance ?? panic("Unable to fetch the payment balance")
            // The payment vault for the sale is from the taker's address
            let paymentRecipient = FRC20Indexer.borrowFlowTokenReceiver(seller)
                ?? panic("Unable to fetch the payment recipient")

            // Pay the sale cuts to the recipients.
            let commissionAmount = self._payToSaleCuts(
                payment: <- (payment ?? panic("Payment is nil")),
                commissionRecipient: commissionRecipient,
                paymentRecipient: paymentRecipient,
            )

            // handle the transaction deal
            self._onTransactionDeal(
                storefrontAddress: storefrontAddress,
                seller: seller,
                buyer: buyer,
                transactedAmt: transactedAmt!,
                transactedPrice: transactedPrice,
                commissionAmount: commissionAmount,
                commissionRecipientAddress: commissionRecipient?.address
            )
        }

        /// Invoked when the listing is partially or fully transacted.
        ///
        access(self)
        fun _onTransactionDeal(
            storefrontAddress: Address,
            seller: Address,
            buyer: Address,
            transactedAmt: UFix64,
            transactedPrice: UFix64,
            commissionAmount: UFix64,
            commissionRecipientAddress: Address?,
        ) {
            // Some singleton resources
            let frc20Indexer = FRC20Indexer.getIndexer()
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let tickName = self.details.tick

            // ------- start -- Invoke Hooks --------------
            // Invoke transaction hooks to do things like:
            // -- Record the transction record
            // -- Record trading Volume
            // for market hook
            let marketAddress = acctsPool.getFRC20MarketAddress(tick: tickName) ?? panic("Unable to fetch the marketplace address")
            if let marketTransactionHook = FRC20FTShared.borrowTransactionHook(marketAddress) {
                marketTransactionHook.onDeal(
                    storefront: storefrontAddress,
                    listingId: self.details.storefrontId,
                    seller: seller,
                    buyer: buyer,
                    tick: tickName,
                    dealAmount: transactedAmt,
                    dealPrice: transactedPrice,
                    totalAmountInListing: self.details.amount,
                )
            }
            // for seller hook
            if let sellerTransactionHook = FRC20FTShared.borrowTransactionHook(seller) {
                sellerTransactionHook.onDeal(
                    storefront: storefrontAddress,
                    listingId: self.details.storefrontId,
                    seller: seller,
                    buyer: buyer,
                    tick: tickName,
                    dealAmount: transactedAmt,
                    dealPrice: transactedPrice,
                    totalAmountInListing: self.details.amount,
                )
            }
            // for buyer hook
            if let buyerTransactionHook = FRC20FTShared.borrowTransactionHook(buyer) {
                buyerTransactionHook.onDeal(
                    storefront: storefrontAddress,
                    listingId: self.details.storefrontId,
                    seller: seller,
                    buyer: buyer,
                    tick: tickName,
                    dealAmount: transactedAmt,
                    dealPrice: transactedPrice,
                    totalAmountInListing: self.details.amount,
                )
            }
            // ------- end ---------------------------------

            // emit ListingPartiallyDeal event
            emit ListingPartiallyDeal(
                storefrontAddress: storefrontAddress,
                storefrontId: self.details.storefrontId,
                listingResourceID: self.uuid,
                inscriptionId: self.details.inscriptionId,
                type: self.details.type.rawValue,
                tick: tickName,
                totalAmount: self.details.amount,
                transactedAmount: transactedAmt,
                transactedPrice: transactedPrice,
                customID: self.details.customID,
                commissionAmount: commissionAmount,
                commissionReceiver: commissionAmount != 0.0 ? commissionRecipientAddress : nil,
            )

            // if the listing is fully transacted, then set it to completed
            if self.details.isFullyTransacted() {
                // Make sure the listing cannot be completed again.
                self.details.setToCompleted()

                // set the frozen change to nil
                var nilChange: @FRC20FTShared.Change? <- nil
                nilChange <-> self.frozenChange
                if nilChange?.getBalance() != 0.0 {
                    frc20Indexer.returnChange(
                        change: <- (nilChange ?? panic("Unable to extract the change"))
                    )
                } else {
                    destroy nilChange
                }

                // emit ListingCompleted event
                emit ListingCompleted(
                    storefrontAddress: storefrontAddress,
                    storefrontId: self.details.storefrontId,
                    listingResourceID: self.uuid,
                    inscriptionId: self.details.inscriptionId,
                    type: self.details.type.rawValue,
                    tick: self.details.tick,
                    amount: self.details.amount,
                    totalPrice: self.details.totalPrice,
                    customID: self.details.customID,
                    commissionAmount: commissionAmount,
                    commissionReceiver: commissionAmount != 0.0 ? commissionRecipientAddress : nil,
                )
            }
        }

        /** ---- Account or contract methods ---- */

        access(contract)
        fun cancel() {
            pre {
                self.details.status == ListingStatus.Available: "Listing must be available"
                self.owner != nil : "Resource doesn't have the assigned owner"
            }

            self.details.setToCancelled()

            // The indexer for all the FRC20 tokens.
            let frc20Indexer = FRC20Indexer.getIndexer()

            var changeToReturn: @FRC20FTShared.Change? <- nil
            changeToReturn <-> self.frozenChange

            assert(
                changeToReturn != nil,
                message: "Frozen change should not be nil"
            )

            // apply the change and rollback inscriptions in frc20 indexer
            frc20Indexer.cancelListing(
                listedIns: self.borrowInspection(),
                change: <- (changeToReturn ?? panic("Unable to extract the change"))
            )

            emit ListingCancelled(
                storefrontAddress: self.owner?.address ?? panic("Unable to fetch the storefront address"),
                storefrontId: self.details.storefrontId,
                listingResourceID: self.uuid,
                inscriptionId: self.details.inscriptionId,
                type: self.details.type.rawValue,
                tick: self.details.tick,
                amount: self.details.amount,
                price: self.details.totalPrice,
                customID: self.details.customID,
            )
        }

        /// borrow the inscription reference
        ///
        access(contract)
        fun borrowInspection(): &Fixes.Inscription {
            return self._borrowStorefront().borrowInspection(self.details.inscriptionId)
        }

        /* ---- Internal methods ---- */

        /// Pay the sale cuts to the recipients.
        /// Returns the amount of commission paid.
        ///
        access(self)
        fun _payToSaleCuts(
            payment: @FlowToken.Vault,
            commissionRecipient: Capability<&FlowToken.Vault{FungibleToken.Receiver}>?,
            paymentRecipient: &{FungibleToken.Receiver}?,
        ): UFix64 {
            // Some singleton resources
            let frc20Indexer = FRC20Indexer.getIndexer()
            let acctsPool = FRC20AccountsPool.borrowAccountsPool()
            let globalSharedStore = FRC20FTShared.borrowGlobalStoreRef()

            // some constants
            let stakingFRC20Tick = (globalSharedStore.getByEnum(FRC20FTShared.ConfigType.PlatofrmMarketplaceStakingToken) as! String?) ?? "flows"
            let listingTick = self.details.tick
            let listingTokenMeta = frc20Indexer.getTokenMeta(tick: listingTick)
                ?? panic("Unable to fetch the token meta")
            // All the commission receivers that are eligible to receive the commission.
            let eligibleCommissionReceivers = self.commissionRecipientCaps

            let marketAddress = acctsPool.getFRC20MarketAddress(tick: listingTick) ?? panic("Unable to fetch the marketplace address")
            let marketSharedStore = FRC20FTShared.borrowStoreRef(marketAddress)

            // Token treasuries
            let tokenTreasury = frc20Indexer.borrowTokenTreasuryReceiver(tick: listingTick)
            let platformTreasury = frc20Indexer.borowPlatformTreasuryReceiver()

            let payToPlatformStakingPool = fun (_ payment: @FungibleToken.Vault) {
                if let flowVault = acctsPool.borrowFRC20StakingFlowTokenReceiver(tick: stakingFRC20Tick) {
                    flowVault.deposit(from: <- payment)
                } else {
                    // if the staking pool doesn't exist, pay to token treasury
                    tokenTreasury.deposit(from: <- payment)
                }
            }

            // The function to pay to marketplace staking pool
            let payToMarketplaceShared = fun (_ payment: @FungibleToken.Vault) {
                if let flowVault = acctsPool.borrowMarketSharedFlowTokenReceiver() {
                    flowVault.deposit(from: <- payment)
                } else {
                    // if the campaign pool doesn't exist, pay to token treasury
                    tokenTreasury.deposit(from: <- payment)
                }
            }

            // The function to pay to marketplace campaign pool
            let payToMarketplaceSpecific = fun (_ payment: @FungibleToken.Vault) {
                if let flowVault = acctsPool.borrowFRC20MarketFlowTokenReceiver(tick: listingTick) {
                    flowVault.deposit(from: <- payment)
                } else {
                    // if the campaign pool doesn't exist, pay to token treasury
                    tokenTreasury.deposit(from: <- payment)
                }
            }

            let payToDeployer = fun (_ payment: @FungibleToken.Vault) {
                if let flowVault = FRC20Indexer.borrowFlowTokenReceiver(listingTokenMeta.deployer) {
                    flowVault.deposit(from: <- payment)
                } else {
                    // if the deployer pool doesn't exist, pay to token treasury
                    tokenTreasury.deposit(from: <- payment)
                }
            }

            // The function to pay the commission
            let payCommissionFunc = fun (payment: @FungibleToken.Vault) {
                // If commission recipient is nil, Throw panic.
                if let commissionReceiver = commissionRecipient {
                    if eligibleCommissionReceivers != nil {
                        var isCommissionRecipientHasValidType = false
                        var isCommissionRecipientAuthorised = false
                        for cap in eligibleCommissionReceivers! {
                            // Check 1: Should have the same type
                            if cap.getType() == commissionReceiver.getType() {
                                isCommissionRecipientHasValidType = true
                                // Check 2: Should have the valid market address that holds approved capability.
                                if cap.address == commissionReceiver.address && cap.check() {
                                    isCommissionRecipientAuthorised = true
                                    break
                                }
                            }
                        }
                        assert(isCommissionRecipientHasValidType, message: "Given recipient does not has valid type")
                        assert(isCommissionRecipientAuthorised,   message: "Given recipient is not authorised to receive the commission")
                    }
                    let recipient = commissionReceiver.borrow() ?? panic("Unable to borrow the recipient capability")
                    recipient.deposit(from: <- payment)
                } else {
                    // If commission recipient is nil, pay to the marketplace shared pool
                    payToMarketplaceShared(<- payment)
                }
            }

            // Rather than aborting the transaction if any receiver is absent when we try to pay it,
            // we send the cut to the token or platform treasury, and emit an event to let the
            // receiver know that they have unclaimed funds.
            var residualReceiver: &{FungibleToken.Receiver}? = nil

            // The commission amount
            var commissionAmount = 0.0
            let totalPaymentAmount = payment.balance
            // Pay each beneficiary their amount of the payment.
            for cut in self.details.saleCuts {
                let paymentAmt = cut.ratio * totalPaymentAmount
                switch cut.type {
                case FRC20FTShared.SaleCutType.TokenTreasury:
                    tokenTreasury.deposit(from: <- payment.withdraw(amount: paymentAmt))
                    // If the residual receiver is not set, set it to the token treasury.
                    if residualReceiver == nil {
                        residualReceiver = tokenTreasury
                    }
                    break
                case FRC20FTShared.SaleCutType.PlatformTreasury:
                    platformTreasury.deposit(from: <- payment.withdraw(amount: paymentAmt))
                    // If the residual receiver is not set, set it to the token treasury.
                    if residualReceiver == nil {
                        residualReceiver = platformTreasury
                    }
                    break
                case FRC20FTShared.SaleCutType.PlatformStakers:
                    payToPlatformStakingPool(<- payment.withdraw(amount: paymentAmt))
                    break
                case FRC20FTShared.SaleCutType.SellMaker:
                    let receiverCap = cut.receiver ?? panic("Receiver capability should not be nil")
                    if let receiver = receiverCap.borrow() {
                        receiver.deposit(from: <- payment.withdraw(amount: paymentAmt))
                    } else {
                        emit UnpaidReceiver(receiver: receiverCap.address, entitledSaleCut: paymentAmt)
                    }
                    break
                case FRC20FTShared.SaleCutType.BuyTaker:
                    let receiver = paymentRecipient ?? panic("Payment recipient should not be nil")
                    receiver.deposit(from: <- payment.withdraw(amount: paymentAmt))
                case FRC20FTShared.SaleCutType.Commission:
                    commissionAmount = paymentAmt
                    payCommissionFunc(<- payment.withdraw(amount: paymentAmt))
                    break
                case FRC20FTShared.SaleCutType.MarketplacePortion:
                    let partialPayment <- payment.withdraw(amount: paymentAmt)
                    // If the commission recipient is not set, pay to the marketplace shared pool
                    // Otherwise, pay to the commission recipient
                    if commissionRecipient != nil {
                        commissionAmount = paymentAmt
                        payCommissionFunc(<- partialPayment)
                    } else if let store = marketSharedStore {
                        // Load config from market shared store
                        let sharedRatio = store.getByEnum(FRC20FTShared.ConfigType.MarketFeeSharedRatio) as! UFix64? ?? 1.0
                        let specificRatio = store.getByEnum(FRC20FTShared.ConfigType.MarketFeeTokenSpecificRatio) as! UFix64? ?? 0.0
                        let deployerRatio = store.getByEnum(FRC20FTShared.ConfigType.MarketFeeDeployerRatio) as! UFix64? ?? 0.0
                        // calculate the total weight
                        let totalWeight = sharedRatio + specificRatio + deployerRatio
                        let mktPaymentBalance = partialPayment.balance
                        // the amount to pay to the shared pool
                        let payToShared = sharedRatio / totalWeight * mktPaymentBalance
                        if payToShared > 0.0 {
                            payToMarketplaceShared(<- partialPayment.withdraw(amount: payToShared))
                        }
                        // the amount to pay to the specific pool
                        let payToSpecific = specificRatio / totalWeight * mktPaymentBalance
                        if payToSpecific > 0.0 {
                            payToMarketplaceSpecific(<- partialPayment.withdraw(amount: payToSpecific))
                        }
                        // rest amount can be paid to the deployer pool
                        if partialPayment.balance > 0.0 {
                            payToDeployer(<- partialPayment)
                        }
                    } else {
                        // If the market shared store is not set, pay to the token treasury
                        tokenTreasury.deposit(from: <- partialPayment)
                    }
                    break
                default:
                    panic("Unsupported cut type")
                }
            }

            assert(residualReceiver != nil, message: "No valid payment receivers")

            // At this point, if all receivers were active and available, then the payment Vault will have
            // zero tokens left, and this will functionally be a no-op that consumes the empty vault
            residualReceiver!.deposit(from: <- payment)

            // Return the commission amount
            return commissionAmount
        }

        /// Borrow the storefront resource.
        ///
        access(self)
        fun _borrowStorefront(): &Storefront{StorefrontPublic} {
            return FRC20Storefront.borrowStorefront(address: self.owner!.address)
                ?? panic("Storefront not found")
        }
    }



    /// StorefrontManager
    /// An interface for adding and removing Listings within a Storefront,
    /// intended for use by the Storefront's owner
    ///
    access(all) resource interface StorefrontManager {
        /// createListing
        /// Allows the Storefront owner to create and insert Listings.
        ///
        access(all)
        fun createListing(
            ins: @Fixes.Inscription,
            marginVault: @FlowToken.Vault?,
            commissionRecipientCaps: [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]?,
            customID: String?
        ): UInt64

        /// Allows the Storefront owner to remove any sale listing, accepted or not.
        ///
        access(all)
        fun removeListing(listingResourceID: UInt64): @Fixes.Inscription
    }

    /// StorefrontPublic
    /// An interface to allow listing and borrowing Listings, and purchasing items via Listings
    /// in a Storefront.
    ///
    access(all) resource interface StorefrontPublic {
        /** ---- Public Methods ---- */
        /// get all listingIDs
        access(all)
        fun getListingIDs(): [UInt64]
        // Borrow the listing reference
        access(all)
        fun borrowListing(_ listingResourceID: UInt64): &Listing{ListingPublic}?
        // Cleanup methods
        access(all)
        fun tryCleanupFinishedListing(_ listingResourceID: UInt64)
        /** ---- Contract Methods ---- */
        /// borrow the inscription reference
        access(contract)
        fun borrowInspection(_ id: UInt64): &Fixes.Inscription
   }

    /// Storefront
    /// A resource that allows its owner to manage a list of Listings, and anyone to interact with them
    /// in order to query their details and purchase the NFTs that they represent.
    ///
    access(all) resource Storefront : StorefrontManager, StorefrontPublic {
        /// The dictionary of stored inscriptions.
        access(contract)
        var inscriptions: @{UInt64: Fixes.Inscription}
        /// The dictionary of Listing uuids to Listing resources.
        access(contract)
        var listings: @{UInt64: Listing}
        /// Dictionary to keep track of listing ids for listing.
        /// tick -> [listing resource ID]
        access(contract)
        var listedTicks: {String: [UInt64]}

        /// @deprecated after Cadence 1.0
        destroy() {
            destroy self.inscriptions
            destroy self.listings
        }

        /// constructor
        ///
        init () {
            self.listings <- {}
            self.inscriptions <- {}
            self.listedTicks = {}

            // Let event consumers know that this storefront exists
            emit StorefrontInitialized(uuid: self.uuid)
        }

        /** ---- Public Methods ---- */

        /// getListingIDs
        /// Returns an array of the Listing resource IDs that are in the collection
        ///
        access(all)
        fun getListingIDs(): [UInt64] {
            return self.listings.keys
        }

        /// borrowSaleItem
        /// Returns a read-only view of the SaleItem for the given listingID if it is contained by this collection.
        ///
        access(all)
        fun borrowListing(_ listingResourceID: UInt64): &Listing{ListingPublic}? {
             if self.listings[listingResourceID] != nil {
                return &self.listings[listingResourceID] as &Listing{ListingPublic}?
            } else {
                return nil
            }
        }

        /** ---- Private Methods ---- */

        /// insert
        /// Create and publish a Listing for an NFT.
        ///
        access(all)
        fun createListing(
            ins: @Fixes.Inscription,
            marginVault: @FlowToken.Vault?,
            commissionRecipientCaps: [Capability<&FlowToken.Vault{FungibleToken.Receiver}>]?,
            customID: String?
         ): UInt64 {
            pre {
                self.owner != nil : "Resource doesn't have the assigned owner"
            }

            var insRef = &ins as &Fixes.Inscription
            assert(
                FRC20Storefront.isListFRC20Inscription(ins: insRef),
                message: "Given inscription is not a valid FRC20 listing inscription"
            )

            let storefrontId = self.uuid

            // store the inscription to local
            let inscriptionId = insRef.getId()
            let nothing <- self.inscriptions[inscriptionId] <- ins
            destroy nothing

            // borrow again to get the reference
            insRef = self.borrowInspection(inscriptionId)

            // save the margin vault if it is not nil
            if marginVault != nil {
                insRef.deposit(<- marginVault!)
            } else {
                destroy marginVault
            }

            // Instead of letting an arbitrary value be set for the UUID of a given NFT, the contract
            // should fetch it itself
            let listing <- create Listing(
                storefrontId: storefrontId,
                listIns: insRef,
                commissionRecipientCaps: commissionRecipientCaps,
                customID: customID
            )

            let listingResourceID = listing.uuid
            let details = listing.getDetails()
            // Add the new listing to the dictionary.
            let oldListing <- self.listings[listingResourceID] <- listing
            // Note that oldListing will always be nil, but we have to handle it.

            destroy oldListing

            // Scraping addresses from the capabilities to emit in the event.
            var allowedCommissionReceivers : [Address]? = nil
            if let allowedReceivers = commissionRecipientCaps {
                // Small hack here to make `allowedCommissionReceivers` variable compatible to
                // array properties.
                allowedCommissionReceivers = []
                for receiver in allowedReceivers {
                    allowedCommissionReceivers!.append(receiver.address)
                }
            }

            emit ListingAvailable(
                storefrontAddress: self.owner?.address ?? panic("Storefront owner is not set"),
                storefrontId: storefrontId,
                listingResourceID: listingResourceID,
                inscriptionId: details.inscriptionId,
                type: details.type.rawValue,
                tick: details.tick,
                amount: details.amount,
                totalPrice: details.totalPrice,
                customID: customID,
                commissionReceivers: allowedCommissionReceivers
            )

            return listingResourceID
        }

        /// Remove a Listing that has not yet been purchased from the collection and destroy it.
        /// It can only be executed by the StorefrontManager resource owner.
        ///
        access(all)
        fun removeListing(listingResourceID: UInt64): @Fixes.Inscription {
            let listingRef = self.borrowListingPrivate(listingResourceID)

            let currentStatus: FRC20Storefront.ListingStatus = listingRef.getStatus()
            // If the listing is already completed, then we don't need to do anything.
            if currentStatus == ListingStatus.Available {
                listingRef.cancel()
            } else if currentStatus == ListingStatus.Cancelled {
                // If the listing is already cancelled, then we don't need to do anything.
            } else if currentStatus == ListingStatus.Completed {
                // If the listing is already completed, then we don't need to do anything.
            }

            // ensure the change in listing is nil
            assert(
                listingRef.frozenChange == nil,
                message: "Listing change should be nil"
            )

            let listing <- self.listings.remove(key: listingResourceID)
                ?? panic("missing Listing")
            let details = listing.getDetails()

            emit ListingRemoved(
                storefrontAddress: self.owner?.address ?? panic("Storefront owner is not set"),
                storefrontId: self.uuid,
                listingResourceID: listingResourceID,
                inscriptionId: details.inscriptionId,
                customID: details.customID,
                withStatus: currentStatus.rawValue
            )

            destroy listing

            // return the inscription
            return <- self.inscriptions.remove(key: details.inscriptionId)!
        }

        /// Allows anyone to remove already completed listings.
        ///
        access(all)
        fun tryCleanupFinishedListing(_ listingResourceID: UInt64) {
            let listingRef = self.borrowListing(listingResourceID)
                ?? panic("Could not find listing with given id")
            let details = listingRef.getDetails()

            // If the listing is not completed or cancelled, then we don't need to do anything.
            if !details.isCompleted() && !details.isCancelled() {
                return
            }

            let listing <- self.listings.remove(key: listingResourceID)!

            emit ListingRemoved(
                storefrontAddress: self.owner?.address ?? panic("Storefront owner is not set"),
                storefrontId: self.uuid,
                listingResourceID: listingResourceID,
                inscriptionId: details.inscriptionId,
                customID: details.customID,
                withStatus: details.status.rawValue
            )
            // destroy listing
            destroy listing

            // destory the inscription
            let ins <- self.inscriptions.remove(key: details.inscriptionId)
            destroy ins
        }

        /** ---- Internal Method ---- */

        /// borrow the inscription reference
        ///
        access(contract)
        fun borrowInspection(_ id: UInt64): &Fixes.Inscription {
            return &self.inscriptions[id] as &Fixes.Inscription? ?? panic("Inscription not found")
        }

        /// borrow the listing reference
        ///
        access(contract)
        fun borrowListingPrivate(_ id: UInt64): &Listing {
            return &self.listings[id] as &Listing? ?? panic("Listing not found")
        }
    }

    /* --- Public Resource Interfaces --- */

    /// Check if the given inscription is a valid FRC20 listing inscription.
    ///
    access(all)
    fun isListFRC20Inscription(ins: &Fixes.Inscription): Bool {
        let indexer = FRC20Indexer.getIndexer()
        if !indexer.isValidFRC20Inscription(ins: ins) {
            return false
        }
        let meta = indexer.parseMetadata(&ins.getData() as &Fixes.InscriptionData)
        let op = meta["op"]?.toLower()
        if op == nil || op!.slice(from: 0, upTo: 5) != "list-" {
            return false
        }
        return true
    }

    /// createStorefront
    /// Make creating a Storefront publicly accessible.
    ///
    access(all)
    fun createStorefront(): @Storefront {
        return <-create Storefront()
    }

    /// Borrow a Storefront from an account.
    ///
    access(all)
    fun borrowStorefront(address: Address): &Storefront{StorefrontPublic}? {
        return getAccount(address)
            .getCapability<&Storefront{StorefrontPublic}>(self.StorefrontPublicPath)
            .borrow()
    }

    init() {
        let identifier = "FRC20Storefront_".concat(self.account.address.toString())
        self.StorefrontStoragePath = StoragePath(identifier: identifier)!
        self.StorefrontPublicPath = PublicPath(identifier: identifier)!
    }
}
