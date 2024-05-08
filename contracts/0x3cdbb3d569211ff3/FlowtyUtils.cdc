import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NFTCatalog from "../0x49a7cda3a1eecc29/NFTCatalog.cdc"

import LostAndFound from "../0x473d6a2c37eab5be/LostAndFound.cdc"

import RoyaltiesOverride from "./RoyaltiesOverride.cdc"


pub contract FlowtyUtils {
	access(contract) var Attributes: {String: AnyStruct}

	pub let FlowtyUtilsStoragePath: StoragePath

	// Deprecated
	pub struct NFTIdentifier {}

	// Deprecated
	pub struct CollectionInfo {}

	pub struct TokenInfo {
		pub let tokenType: Type
		pub let storagePath: StoragePath
		pub let balancePath: PublicPath
		pub let receiverPath: PublicPath
		pub let providerPath: PrivatePath

		init(
			tokenType: Type, 
			storagePath: StoragePath, 
			balancePath: PublicPath, 
			receiverPath: PublicPath, 
			providerPath: PrivatePath
		) {
			self.tokenType = tokenType
			self.storagePath = storagePath
			self.balancePath = balancePath
			self.receiverPath = receiverPath
			self.providerPath = providerPath
		}
	}
	
	// Deprecated
	pub struct PaymentCut {}

	pub resource FlowtyUtilsAdmin {
		pub fun setBalancePath(key: String, path: PublicPath): Bool {
			if FlowtyUtils.Attributes["balancePaths"] == nil {
				FlowtyUtils.Attributes["balancePaths"] = BalancePaths()
			}

			return (FlowtyUtils.Attributes["balancePaths"]! as! BalancePaths).set(key: key, path: path)
		}

		// addSupportedTokenType
		// add a supported token type that can be used in Flowty loans
		pub fun addSupportedTokenType(tokenInfo: TokenInfo) {
			var supportedTokens = FlowtyUtils.Attributes["supportedTokens"]
			if supportedTokens == nil {
				supportedTokens = {} as {Type: TokenInfo}
			}

			let tokens = supportedTokens! as! {Type: TokenInfo}
			tokens[tokenInfo.tokenType] = tokenInfo
			FlowtyUtils.Attributes["supportedTokens"] = tokens

			self.setBalancePath(key: tokenInfo.tokenType.identifier, path: tokenInfo.balancePath)
		}

		pub fun removeSupportedTokenType(type: Type) {
			let tokens = (FlowtyUtils.Attributes["supportedTokens"] != nil ? FlowtyUtils.Attributes["supportedTokens"]! : {} as {Type: TokenInfo}) as! {Type: TokenInfo}
			tokens.remove(key: type)
			FlowtyUtils.Attributes["supportedTokens"] = tokens
		}
	}

	pub fun getTokenInfo(_ type: Type): TokenInfo? {
		let tokens = (FlowtyUtils.Attributes["supportedTokens"] != nil ? FlowtyUtils.Attributes["supportedTokens"]! : {} as {Type: TokenInfo}) as! {Type: TokenInfo}
		return tokens[type]
	}

	pub fun getSupportedTokens(): [Type] {
		let attribute = self.Attributes["supportedTokens"]
		if attribute == nil {
			return []
		}
		let supportedTokens = attribute! as! {Type: TokenInfo}
		return supportedTokens.keys
	}


	pub fun getAllBalances(address: Address): {String: UFix64} {
		let allowedTokens = FlowtyUtils.getSupportedTokens()
		let balances: {String: UFix64} = {}

		for index, allowedToken in allowedTokens {
			let vaultType = allowedTokens[index]
			let balance = FlowtyUtils.getTokenBalance(address: address, vaultType: vaultType)
			balances.insert(key: vaultType.identifier, balance)
		}
		return balances
	}

	access(self) fun getDepositor(): &LostAndFound.Depositor {
		return self.account.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
	}

	/*
		We cannot know the real value of each item being transacted with. Because of that, we will simply split 
		the royalty rate evenly amongst each MetadataViews.Royalties item, and then split that piece of the royalty
		evenly amongst each Royalty in that item.

		For example, let's say we have two MetadataRoyalties entries:
		1. A single cutInfo of 5%
		2. Two cutInfos of 1% and 5%

		And let's also say that the royaltyRate is 5%. In that scenario, half of the vault goes to each Royalties entry.
		All of the first half goes to cutInfo #1's destination. The second half should send 1/6 of its half to the first
		cutInfo, and 5/6 of the second half to the second cutInfo.

		So if we had a loan of 1000 tokens, 25 goes to cutInfo 1, ~4.16 goes to cutInfo2.1, and ~20.4 to cutInfo2.
	 */
	pub fun metadataRoyaltiesToRoyaltyCuts(tokenInfo: TokenInfo, mdRoyalties: [MetadataViews.Royalties]): [RoyaltyCut] {
		if mdRoyalties.length == 0 {
			return []
		}
		
		let royaltyCuts: {Address: RoyaltyCut} = {}

		// the cut for each Royalties object is split evenly, regardless of the hypothetical value
		// difference between each asset they came from.
		let cutPerRoyalties = 1.0 / UFix64(mdRoyalties.length)

		// for each royalties struct, calculate the sum totals to go to each benefiary
		// then roll them up in 
		for royalties in mdRoyalties {
			// we need to know the total % taken from this set of royalties so that we can
			// calculate the total proportion taken from each Royalty struct inside of it. 
			// Unfortunately there isn't another way to do this since the total cut amount 
			// isn't pre-populated by the Royalties standard
			var royaltiesTotal = 0.0
			for cutInfo in royalties.getRoyalties() {
				royaltiesTotal = royaltiesTotal + cutInfo.cut
			}

			for cutInfo in royalties.getRoyalties() {
				if royaltyCuts[cutInfo.receiver.address] == nil {
					let cap = getAccount(cutInfo.receiver.address).getCapability<&{FungibleToken.Receiver}>(tokenInfo.receiverPath)
					royaltyCuts[cutInfo.receiver.address] = RoyaltyCut(cap: cap, percentage: 0.0)
				}

				let denom = royaltiesTotal * cutPerRoyalties
				if denom == 0.0 {
					continue
				}

				royaltyCuts[cutInfo.receiver.address]!.add(p: cutInfo.cut / denom)
			}
		}

		return royaltyCuts.values
	}

	pub struct RoyaltyCut {
		pub let cap: Capability<&{FungibleToken.Receiver}>
		pub var percentage: UFix64

		init(cap: Capability<&{FungibleToken.Receiver}>, percentage: UFix64) {
			self.cap = cap
			self.percentage = percentage
		}

		pub fun add(p: UFix64) {
			self.percentage = self.percentage + p
		}
	}

	pub fun distributeRoyaltiesWithDepositor(royaltyCuts: [RoyaltyCut], depositor: &LostAndFound.Depositor, vault: @FungibleToken.Vault) {
		let depositor = FlowtyUtils.getDepositor()
		let startBalance = vault.balance
		for index, rs in royaltyCuts {
			if index == royaltyCuts.length - 1 {
				depositor.trySendResource(item: <-vault, cap: rs.cap, memo: "flowty royalty distribution", display: nil)  
				return 
			}

			depositor.trySendResource(item: <-vault.withdraw(amount: startBalance * rs.percentage), cap: rs.cap, memo: "flowty royalty distribution", display: nil)
		}
		destroy vault
	}

	// getAllowedTokens
	// return an array of types that are able to be used as the payment type
	// for loans
	pub fun getAllowedTokens(): [Type] {
		let tokens = (FlowtyUtils.Attributes["supportedTokens"] != nil ? FlowtyUtils.Attributes["supportedTokens"]! : {} as {Type: TokenInfo}) as! {Type: TokenInfo}
		return tokens.keys
	}

	// isTokenSupported
	// check if the given type is able to be used as payment
	pub fun isTokenSupported(type: Type): Bool {
		for t in FlowtyUtils.getAllowedTokens() {
			if t == type {
				return true
			}
		}

		return false
	}

	pub fun depositToLostAndFound(
		redeemer: Address,
		item: @AnyResource,
		memo: String?,
		display: MetadataViews.Display?,
		depositor: &LostAndFound.Depositor
	) {
		depositor.deposit(redeemer: redeemer, item: <-item, memo: memo, display: display)
	}

	pub fun trySendFungibleTokenVault(vault: @FungibleToken.Vault, receiver: Capability<&{FungibleToken.Receiver}>, depositor: &LostAndFound.Depositor){
		if !receiver.check() {
			depositor.deposit(redeemer: receiver.address, item: <-vault, memo: nil, display: nil)
		} else {
			receiver.borrow()!.deposit(from: <-vault)
		}
	}

	pub fun trySendNFT(nft: @NonFungibleToken.NFT, receiver: Capability<&{NonFungibleToken.CollectionPublic}>, depositor: &LostAndFound.Depositor) {
		if !receiver.check() {
			depositor.deposit(
				redeemer: receiver.address,
				item: <- nft,
				memo: nil,
				display: nil,
			)
		} else {
			receiver.borrow()!.deposit(token: <-nft)
		}
	}

	pub struct BalancePaths {
		access(self) var paths: {String: PublicPath}

		access(account) fun get(key: String): PublicPath? {
			return self.paths[key]
		}
		

		access(account) fun set(key: String, path: PublicPath): Bool {
			let pathOverwritten = self.paths[key] != nil

			self.paths[key] = path

			return pathOverwritten
		}

		init() {
			self.paths = {}
		}
	}

	pub fun getTokenBalance(address: Address, vaultType: Type): UFix64 {
		// get the account for the address we want the balance for
		let user = getAccount(address)

		// get the balance path for the user for the given fungible token
		let ti = FlowtyUtils.getTokenInfo(vaultType)
			?? panic("No configuration for ".concat(vaultType.identifier))
		let balancePath = ti.balancePath

		assert(balancePath != nil, message: "No balance path configured for ".concat(vaultType.identifier))
		
		// get the FungibleToken.Balance capability located at the path
		let vaultCap = user.getCapability<&{FungibleToken.Balance}>(balancePath)
		
		// check the capability exists
		if !vaultCap.check() {
			return 0.0
		}

		// borrow the reference
		let vaultRef = vaultCap.borrow()

		// get the balance of the account
		return vaultRef?.balance ?? 0.0
	}

	pub fun getRoyaltyRate(_ nft: &NonFungibleToken.NFT): UFix64 {
		// check for overrides first

		if RoyaltiesOverride.get(nft.getType()) {
			return 0.0
		}

		let royalties = nft.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?
		if royalties == nil {
			return 0.0
		}

		// count the royalty rate now, then we'll pick them all up after the fact when a loan is settled?
		var total = 0.0
		for r in royalties!.getRoyalties() {
			total = total + r.cut
		}

		return total
	}

	pub fun isSupported(_ nft: &NonFungibleToken.NFT): Bool {
		let collections = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nft.getType().identifier)
		if collections == nil {
			return false
		}

		for v in collections!.values {
			if v {
				return true
			}
		}

		return false
	}

	init() {
		self.Attributes = {}

		self.FlowtyUtilsStoragePath = /storage/FlowtyUtils

		let utilsAdmin <- create FlowtyUtilsAdmin()
		self.account.save(<-utilsAdmin, to: self.FlowtyUtilsStoragePath)

		if self.account.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath) == nil {
			let flowTokenReceiver = self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			let depositor <- LostAndFound.createDepositor(flowTokenReceiver, lowBalanceThreshold: 10.0)
			self.account.save(<-depositor, to: LostAndFound.DepositorStoragePath)
		}
	}
}
 