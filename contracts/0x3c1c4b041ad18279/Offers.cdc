import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import LostAndFound from "../0x473d6a2c37eab5be/LostAndFound.cdc"
import ScopedFTProviders from "./ScopedFTProviders.cdc"

import NFTStorefrontV2 from "../0x3cdbb3d569211ff3/NFTStorefrontV2.cdc"
import Filter from "./Filter.cdc"
import FlowtyUtils from "../0x3cdbb3d569211ff3/FlowtyUtils.cdc"
import FlowtyListingCallback from "../0x3cdbb3d569211ff3/FlowtyListingCallback.cdc"
import DNAHandler from "../0x3cdbb3d569211ff3/DNAHandler.cdc"

pub contract Offers {
	pub let OffersStoragePath: StoragePath
	pub let OffersPublicPath: PublicPath

	pub let AdminStoragePath: StoragePath
	pub let AdminPublicPath: PublicPath

	// Events
	pub event StorefrontInitialized(storefrontResourceID: UInt64)
	pub event OfferCancelled(storefrontAddress: Address?, offerResourceID: UInt64)
	pub event OfferCompleted(storefrontAddress: Address?, offerResourceID: UInt64)
	pub event OfferCreated(
		storefrontAddress: Address,
		offerResourceID: UInt64,
		offeredAmount: UFix64,
		paymentTokenType: String,
		numAcceptable: Int,
		expiry: UInt64,
		taker: Address?,
		payer: Address
	)

	pub event OfferAccepted(
		storefrontAddress: Address,
		offerResourceID: UInt64,
		offeredAmount: UFix64,
		paymentTokenType: String,
		numAcceptable: Int,
		remaining: Int,
		taker: Address,
		nftID: UInt64,
		nftType: String
	)

	pub event FilterTypeAdded(type: Type)
	pub event FilterTypeRemoved(type: Type)

	pub event MissingReceiver(receiver: Address, amount: UFix64)

	pub resource interface StorefrontPublic {
		pub fun borrowOffer(offerResourceID: UInt64): &Offer{OfferPublic}?
		pub fun acceptOffer(offerResourceID: UInt64, nft: @NonFungibleToken.NFT, receiver: Capability<&{FungibleToken.Receiver}>)
		pub fun getIDs(): [UInt64]
		pub fun cleanupOffer(_ id: UInt64)
		access(contract) fun adminRemoveListing(offerResourceID: UInt64)
	}

	pub resource Storefront: StorefrontPublic {
		access(self) let offers: @{UInt64: Offer}

		pub fun createOffer(
			offeredAmount: UFix64,
			paymentTokenType: Type,
			filterGroup: Filter.FilterGroup,
			expiry: UInt64,
			numAcceptable: Int,
			taker: Address?,
			paymentProvider: Capability<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>,
			nftReceiver: Capability<&{NonFungibleToken.CollectionPublic}>
		) {
			pre {
				paymentProvider.check(): "payment provider is invalid"
				nftReceiver.check(): "nftReceiver is invalid"
				Offers.validateFilterGroup(filterGroup): "invalid filter provided"
				filterGroup.filters.length == 1: "filter group must be a length of one filter"
			}

			// wrap out FT provider to keep it safe!
			// the provider should expire after when the offer expires, and it should only be
			// permitted to withdraw (offeredAmount * numAcceptable) tokens
			let allowance = ScopedFTProviders.AllowanceFilter(offeredAmount * UFix64(numAcceptable))
			let scopedProvider <- ScopedFTProviders.createScopedFTProvider(provider: paymentProvider, filters: [allowance], expiration: UFix64(expiry))

			let paymentTokenType = scopedProvider.getProviderType()

			let commission = NFTStorefrontV2.getFee(p: offeredAmount, t: paymentTokenType)

			let offer <- create Offer(
				offeredAmount: offeredAmount,
				paymentTokenType: paymentTokenType,
				commission: commission,
				filterGroup: filterGroup,
				expiry: expiry,
				numAcceptable: numAcceptable,
				taker: taker,
				paymentProvider: <-scopedProvider,
				nftReceiver: nftReceiver
			)

			emit OfferCreated(
				storefrontAddress: self.owner!.address,
				offerResourceID: offer.uuid,
				offeredAmount: offeredAmount,
				paymentTokenType: paymentTokenType.identifier,
				numAcceptable: numAcceptable,
				expiry: expiry,
				taker: taker,
				payer: paymentProvider.address
			)

			if let callback = Offers.borrowCallbackContainer() {
				callback.handle(stage: FlowtyListingCallback.Stage.Created, listing: &offer as &{FlowtyListingCallback.Listing}, nft: nil)
			}

			self.offers[offer.uuid] <-! offer
		}

		pub fun acceptOffer(offerResourceID: UInt64, nft: @NonFungibleToken.NFT, receiver: Capability<&{FungibleToken.Receiver}>) {
			let offer = (&self.offers[offerResourceID] as &Offer?) ?? panic("offer not found")

			let nftType = nft.getType()
			let nftID = nft.id

			emit OfferAccepted(
				storefrontAddress: self.owner!.address,
				offerResourceID: offer.uuid,
				offeredAmount: offer.details.offeredAmount,
				paymentTokenType: offer.details.paymentTokenType.identifier,
				numAcceptable: offer.details.numAcceptable,
				remaining: offer.details.remaining - 1,
				taker: receiver.address,
				nftID: nft.id,
				nftType: nftType.identifier
			)

			offer.acceptOffer(nft: <-nft, receiver: receiver)
			if offer.details.remaining < 1 {
				emit OfferCompleted(storefrontAddress: self.owner!.address, offerResourceID: offer.uuid)
				let o <- self.offers.remove(key: offerResourceID)!

				if let callback = Offers.borrowCallbackContainer() {
					callback.handle(stage: FlowtyListingCallback.Stage.Completed, listing: &o as &{FlowtyListingCallback.Listing}, nft: nil)
					callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &o as &{FlowtyListingCallback.Listing}, nft: nil)
				}

				destroy o
			}

			// clean up any listings that belong to this NFT on the NFTStorefront as well
			let cap = getAccount(receiver.address).getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)
			if cap.check() {
				let s = cap.borrow()!
				var existingListingIDs = s.getExistingListingIDs(
					nftType: nftType,
					nftID: nftID
				)
				for listingID in existingListingIDs {
					s.cleanupInvalidListing(listingResourceID: listingID)
				}
			}
		}

		pub fun cancelOffer(offerResourceID: UInt64) {
			let offer <- self.offers.remove(key: offerResourceID) ?? panic("no offer with that resource ID")
			emit OfferCancelled(storefrontAddress: self.owner?.address, offerResourceID: offer.uuid)

			if let callback = Offers.borrowCallbackContainer() {
				callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &offer as &{FlowtyListingCallback.Listing}, nft: nil)
			}

			destroy offer
		}

		pub fun cleanupOffer(_ id: UInt64) {
			pre {
				self.offers.containsKey(id): "offer does not exist"
			}

		 	let offer <- self.offers.remove(key: id) ?? panic("offer not found")
			assert(!offer.isValid(), message: "cannot cleanup offers that are still valid")
			emit OfferCancelled(storefrontAddress: self.owner!.address, offerResourceID: offer.uuid)
			destroy offer
		}

		pub fun borrowOffer(offerResourceID: UInt64): &Offer{OfferPublic}? {
			return &self.offers[offerResourceID] as &Offer{OfferPublic}?
		}

		pub fun getIDs(): [UInt64] {
			return self.offers.keys
		}

		access(contract) fun adminRemoveListing(offerResourceID: UInt64) {
			pre {
				self.offers[offerResourceID] != nil: "could not find listing with given id"
			}
			let offer <- self.offers.remove(key: offerResourceID)
					?? panic("missing offer")
			emit OfferCancelled(storefrontAddress: self.owner!.address, offerResourceID: offer.uuid)
			let offerDetails = offer.getDetails()
			destroy offer
		}

		init() {
			self.offers <- {}
			emit StorefrontInitialized(storefrontResourceID: self.uuid)
		}

		destroy() {
			for id in self.getIDs() {
				self.cancelOffer(offerResourceID: id)
			}

			destroy self.offers
		}
	}

	pub struct OfferCut {}

	pub struct Details {
		pub let offerResourceID: UInt64
		pub let offeredAmount: UFix64
		pub let paymentTokenType: Type
		pub let filterGroup: Filter.FilterGroup
		pub let expiry: UInt64

		// Only provide for private offers
		pub let taker: Address?

		// how many times can this offer be accepted
		pub let numAcceptable: Int
		pub var remaining: Int

		// generated by offer creation
		pub let commission: UFix64

		init(
			offerResourceID: UInt64,
			offeredAmount: UFix64,
			paymentTokenType: Type,
			commission: UFix64,
			filterGroup: Filter.FilterGroup,
			expiry: UInt64,
			numAcceptable: Int,
			taker: Address?
		) {
			pre {
				numAcceptable > 0: "must be acceptable at least once"
			}

			self.offerResourceID = offerResourceID
			self.offeredAmount = offeredAmount
			self.paymentTokenType = paymentTokenType
			self.filterGroup = filterGroup
			self.expiry = expiry
			self.commission = commission
			self.taker = taker
			self.numAcceptable = numAcceptable

			self.remaining = numAcceptable
		}

		access(contract) fun decrementRemaining() {
			pre {
				self.remaining > 0: "cannot decrement below 0"
			}

			self.remaining = self.remaining - 1
		}
	}

	pub resource interface OfferPublic {
		access(contract) fun acceptOffer(nft: @NonFungibleToken.NFT, receiver: Capability<&{FungibleToken.Receiver}>)
		pub fun getDetails(): Details
		pub fun isValid(): Bool
		pub fun isMatch(_ nft: &NonFungibleToken.NFT): Bool
	}

	pub resource Offer: OfferPublic, FlowtyListingCallback.Listing {
		access(contract) let details: Details
		access(contract) let provider: @ScopedFTProviders.ScopedFTProvider
		access(contract) let receiver: Capability<&{NonFungibleToken.CollectionPublic}>
		
		access(contract) fun acceptOffer(nft: @NonFungibleToken.NFT, receiver: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.details.filterGroup.match(nft: &nft as &NonFungibleToken.NFT): "nft does not pass filter check"
				self.details.taker == nil || receiver.address == self.details.taker: "this offer is meant for a private taker"
				self.isValid(): "offer is not valid"
			}

			let fees = NFTStorefrontV2.getPaymentCuts(r: receiver, n: &nft as &NonFungibleToken.NFT, p: self.details.offeredAmount, tokenType: self.details.paymentTokenType)
			let mpFee = NFTStorefrontV2.getFee(p: self.details.offeredAmount, t: self.details.paymentTokenType)

			let payment <- self.provider.withdraw(amount: self.details.offeredAmount)
			assert(payment.getType() == self.details.paymentTokenType, message: "mismatched payment token type")
			assert(payment.balance == self.details.offeredAmount, message: "mismatched payment amount")

			let depositor = Offers.account.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
			let mpPayment <- payment.withdraw(amount: mpFee)
			let mpReceiver = NFTStorefrontV2.getCommissionReceiver(t: self.details.paymentTokenType)
			mpReceiver.borrow()!.deposit(from: <-mpPayment)

			for f in fees {
				let paymentCut <- payment.withdraw(amount: f.amount)
				FlowtyUtils.trySendFungibleTokenVault(vault: <-paymentCut, receiver: f.receiver, depositor: depositor)
			}

			if payment.balance > 0.0 {
				// send whatever is left to the maker who is the last receiver
				FlowtyUtils.trySendFungibleTokenVault(vault: <-payment, receiver: fees[fees.length-1].receiver, depositor: depositor)
			} else {
				destroy payment
			}

			if let callback = Offers.borrowCallbackContainer() {
				callback.handle(stage: FlowtyListingCallback.Stage.Filled, listing: &self as &{FlowtyListingCallback.Listing}, nft: &nft as &NonFungibleToken.NFT)
			}

			self.details.decrementRemaining()
			self.receiver.borrow()!.deposit(token: <- nft)
		}

		pub fun isMatch(_ nft: &NonFungibleToken.NFT): Bool {
			return self.details.filterGroup.match(nft: nft)
		}

		pub fun getDetails(): Details {
			return self.details
		}

		pub fun isValid(): Bool {
			if !self.provider.check() {
				return false
			}

			if !self.provider.canWithdraw(self.details.offeredAmount) {
				return false
			}

			if self.details.remaining < 1 {
				return false
			}

			if UInt64(getCurrentBlock().timestamp) > self.details.expiry {
				return false
			}

			return true
		}

		init(
			offeredAmount: UFix64,
			paymentTokenType: Type,
			commission: UFix64,
			filterGroup: Filter.FilterGroup,
			expiry: UInt64,
			numAcceptable: Int,
			taker: Address?,
			paymentProvider: @ScopedFTProviders.ScopedFTProvider,
			nftReceiver: Capability<&{NonFungibleToken.CollectionPublic}>
		) {
			self.details = Details(
				offerResourceID: self.uuid,
				offeredAmount: offeredAmount,
				paymentTokenType: paymentTokenType,
				commission: commission,
				filterGroup: filterGroup,
				expiry: expiry,
				numAcceptable: numAcceptable,
				taker: taker
			)

			self.provider <- paymentProvider
			self.receiver = nftReceiver
		}

		destroy () {
			destroy self.provider	
		}
	}

	pub resource interface AdminPublic {
		pub fun isValidFilter(_ t: Type): Bool
		pub fun getFilters(): {Type: Bool}
	}

	pub resource interface AdminCleaner {
		pub fun removeOffer(storefrontAddress: Address, offerResourceID: UInt64)
	}

	pub resource Admin: AdminPublic, AdminCleaner {
		pub let permittedFilters: {Type: Bool}

		init() {
			self.permittedFilters = {}
		}

		pub fun addPermittedFilter(_ t: Type) {
			pre {
				t.isSubtype(of: Type<{Filter.NFTFilter}>())
			}

			self.permittedFilters[t] = true

			emit FilterTypeAdded(type: t)
		}

		pub fun removeFilter(_ t: Type) {
			if let removedType = self.permittedFilters.remove(key: t) {
				emit FilterTypeRemoved(type: t)
			}
		}

		pub fun isValidFilter(_ t: Type): Bool {
			return self.permittedFilters[t] != nil && self.permittedFilters[t]!
		}

		pub fun getFilters(): {Type: Bool} {
			return self.permittedFilters
		}

		pub fun removeOffer(storefrontAddress: Address, offerResourceID: UInt64) {
			let acct = getAccount(storefrontAddress)
			let storefront = acct.getCapability<&Storefront{StorefrontPublic}>(Offers.OffersPublicPath)
			storefront.borrow()!.adminRemoveListing(offerResourceID: offerResourceID)
		}
	}

	pub fun getValidFilters(): {Type: Bool} {
		return Offers.borrowPublicAdmin().getFilters()
	}

	pub fun createStorefront(): @Storefront {
		return <- create Storefront()
	}

	pub fun borrowPublicAdmin(): &Admin{AdminPublic} {
		return self.account.borrow<&Admin{AdminPublic}>(from: Offers.AdminStoragePath)!
	}

	pub fun validateFilterGroup(_ fg: Filter.FilterGroup): Bool {
		let a = Offers.borrowPublicAdmin()
		for f in fg.filters {
			if !a.isValidFilter(f.getType()) {
				return false
			}
		}
		return true
	}

	access(contract) fun borrowCallbackContainer(): &FlowtyListingCallback.Container? {
		return self.account.borrow<&FlowtyListingCallback.Container>(from: FlowtyListingCallback.ContainerStoragePath)
	}

	init() {
		self.OffersStoragePath = StoragePath(identifier: "Offers".concat(self.account.address.toString()))!
		self.OffersPublicPath = PublicPath(identifier: "Offers".concat(self.account.address.toString()))!

		self.AdminPublicPath = /public/offersAdmin
		self.AdminStoragePath = /storage/offersAdmin

		self.account.save(<- create Admin(), to: self.AdminStoragePath)


		if self.account.borrow<&AnyResource>(from: FlowtyListingCallback.ContainerStoragePath) == nil {
			let dnaHandler <- DNAHandler.createHandler()
			let listingHandler <- FlowtyListingCallback.createContainer(defaultHandler: <-dnaHandler)
			self.account.save(<-listingHandler, to: FlowtyListingCallback.ContainerStoragePath)
		}
	}
}
 