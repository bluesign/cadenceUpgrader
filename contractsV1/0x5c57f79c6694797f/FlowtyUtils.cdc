import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import LostAndFound from "../0x473d6a2c37eab5be/LostAndFound.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

access(all)
contract FlowtyUtils{ 
	access(contract)
	var Attributes:{ String: AnyStruct}
	
	access(all)
	let FlowtyUtilsStoragePath: StoragePath
	
	access(all)
	resource FlowtyUtilsAdmin{ 
		// addSupportedTokenType
		// add a supported token type that can be used in Flowty loans
		access(all)
		fun addSupportedTokenType(type: Type){ 
			var supportedTokens = FlowtyUtils.Attributes["supportedTokens"]
			if supportedTokens == nil{ 
				supportedTokens = [Type<@FUSD.Vault>()] as! [Type]
			}
			let tokens = supportedTokens! as! [Type]
			if !FlowtyUtils.isTokenSupported(type: type){ 
				tokens.append(type)
			}
			FlowtyUtils.Attributes["supportedTokens"] = tokens
		}
		
		access(all)
		fun removeSupportedToken(type: Type){ 
			var supportedTokens = FlowtyUtils.Attributes["supportedTokens"]
			if supportedTokens == nil{ 
				supportedTokens = [Type<@FUSD.Vault>()] as! [Type]
			}
			let tokens = supportedTokens! as! [Type]
			var index: Int? = nil
			for idx, t in tokens{ 
				if t == type{ 
					index = idx
				}
			}
			if let idx = index{ 
				tokens.remove(at: idx)
			}
			FlowtyUtils.Attributes["supportedTokens"] = tokens
		}
		
		access(all)
		fun setBalancePath(key: String, path: PublicPath): Bool{ 
			if FlowtyUtils.Attributes["balancePaths"] == nil{ 
				FlowtyUtils.Attributes["balancePaths"] = BalancePaths()
			}
			return (FlowtyUtils.Attributes["balancePaths"]! as! BalancePaths).set(
				key: key,
				path: path
			)
		}
		
		access(all)
		fun setRoyaltyOverride(key: String, value: Bool){ 
			if FlowtyUtils.Attributes["royaltyOverrides"] == nil{ 
				FlowtyUtils.Attributes["royaltyOverrides"] ={}  as{ String: Bool}
			}
			var overrides = FlowtyUtils.Attributes["royaltyOverrides"]! as!{ String: Bool}
			(overrides!).insert(key: key, value)
			FlowtyUtils.Attributes["royaltyOverrides"] = overrides!
		}
	}
	
	access(all)
	fun getRoyaltyOverrides():{ String: Bool}?{ 
		return FlowtyUtils.Attributes["royaltyOverrides"]! as?{ String: Bool}
	}
	
	access(all)
	fun getRoyaltyOverride(_ t: Type): Bool{ 
		var overrides = FlowtyUtils.Attributes["royaltyOverrides"]
		if overrides == nil{ 
			return false
		}
		let converted = overrides! as!{ String: Bool}
		return converted[t.identifier] != nil ? converted[t.identifier]! : false
	}
	
	access(all)
	fun isSupported(_ nft: &{NonFungibleToken.NFT}): Bool{ 
		let collections =
			NFTCatalog.getCollectionsForType(nftTypeIdentifier: nft.getType().identifier)
		if collections == nil{ 
			return false
		}
		for v in (collections!).values{ 
			if v{ 
				return true
			}
		}
		return false
	}
	
	access(all)
	fun getRoyaltyRate(_ nft: &{NonFungibleToken.NFT}): UFix64{ 
		// check for overrides first
		if FlowtyUtils.getRoyaltyOverride(nft.getType()){ 
			return 0.0
		}
		let royalties =
			nft.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?
		if royalties == nil{ 
			return 0.0
		}
		
		// count the royalty rate now, then we'll pick them all up after the fact when a loan is settled?
		var total = 0.0
		for r in (royalties!).getRoyalties(){ 
			total = total + r.cut
		}
		return total
	}
	
	access(all)
	fun distributeRoyalties(
		v: @{FungibleToken.Vault},
		cuts: [
			MetadataViews.Royalty
		],
		path: PublicPath
	){ 
		let balance = v.balance
		if balance == 0.0{ 
			destroy v
			return
		}
		var total = 0.0
		for c in cuts{ 
			total = total + c.cut
		}
		for i, r in cuts{ 
			let amount = balance * (r.cut / total)
			let royaltyReceiverCap = getAccount(r.receiver.address).capabilities.get<&{FungibleToken.Receiver}>(path)
			if v.balance < amount || i == cuts.length - 1{ 
				FlowtyUtils.trySendFungibleTokenVault(vault: <-v, receiver: royaltyReceiverCap!)
				return
			}
			let cut <- v.withdraw(amount: amount)
			FlowtyUtils.trySendFungibleTokenVault(vault: <-cut, receiver: royaltyReceiverCap!)
		}
		
		// this line shouldn't ever be reached but it's best to be safe
		destroy v
	}
	
	access(all)
	fun getSupportedTokens(): AnyStruct{ 
		return self.Attributes["supportedTokens"]!
	}
	
	// getAllowedTokens
	// return an array of types that are able to be used as the payment type
	// for loans
	access(all)
	fun getAllowedTokens(): [Type]{ 
		var supportedTokens = self.Attributes["supportedTokens"]
		return supportedTokens != nil ? supportedTokens! as! [Type] : [Type<@FUSD.Vault>()]
	}
	
	// isTokenSupported
	// check if the given type is able to be used as payment
	access(all)
	fun isTokenSupported(type: Type): Bool{ 
		for t in FlowtyUtils.getAllowedTokens(){ 
			if t == type{ 
				return true
			}
		}
		return false
	}
	
	access(account)
	fun depositToLostAndFound(
		redeemer: Address,
		item: @AnyResource,
		memo: String?,
		display: MetadataViews.Display?
	){ 
		let depositor =
			FlowtyUtils.account.storage.borrow<&LostAndFound.Depositor>(
				from: LostAndFound.DepositorStoragePath
			)
		if depositor == nil{ 
			let depositEstimate <- LostAndFound.estimateDeposit(redeemer: redeemer, item: <-item, memo: memo, display: display)
			let flowtyFlowVault = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			assert(flowtyFlowVault != nil, message: "FlowToken vault is not set up")
			let storagePaymentVault <- (flowtyFlowVault!).withdraw(amount: depositEstimate.storageFee * 1.05)
			let item <- depositEstimate.withdraw()
			destroy depositEstimate
			let flowtyFlowReceiver = self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
			LostAndFound.deposit(redeemer: redeemer, item: <-item, memo: memo, display: display, storagePayment: &storagePaymentVault as &{FungibleToken.Vault}, flowTokenRepayment: flowtyFlowReceiver)
			(flowtyFlowReceiver.borrow()!).deposit(from: <-storagePaymentVault)
			return
		}
		(depositor!).deposit(redeemer: redeemer, item: <-item, memo: memo, display: display)
	}
	
	access(account)
	fun trySendFungibleTokenVault(
		vault: @{FungibleToken.Vault},
		receiver: Capability<&{FungibleToken.Receiver}>
	){ 
		if !receiver.check(){ 
			self.depositToLostAndFound(redeemer: receiver.address, item: <-vault, memo: nil, display: nil)
		} else{ 
			(receiver.borrow()!).deposit(from: <-vault)
		}
	}
	
	access(account)
	fun trySendNFT(
		nft: @{NonFungibleToken.NFT},
		receiver: Capability<&{NonFungibleToken.CollectionPublic}>
	){ 
		if !receiver.check(){ 
			self.depositToLostAndFound(redeemer: receiver.address, item: <-nft, memo: nil, display: nil)
		} else{ 
			(receiver.borrow()!).deposit(token: <-nft)
		}
	}
	
	access(all)
	struct BalancePaths{ 
		access(self)
		var paths:{ String: PublicPath}
		
		access(account)
		fun get(key: String): PublicPath?{ 
			return self.paths[key]
		}
		
		access(account)
		fun set(key: String, path: PublicPath): Bool{ 
			let pathOverwritten = self.paths[key] != nil
			self.paths[key] = path
			return pathOverwritten
		}
		
		init(){ 
			self.paths ={} 
		}
	}
	
	access(all)
	fun balancePaths(): BalancePaths{ 
		if self.Attributes["balancePaths"] == nil{ 
			self.Attributes["balancePaths"] = BalancePaths()
		}
		return self.Attributes["balancePaths"]! as! BalancePaths
	}
	
	access(all)
	fun getTokenBalance(address: Address, vaultType: Type): UFix64{ 
		// get the account for the address we want the balance for
		let user = getAccount(address)
		
		// get the balance path for the user for the given fungible token
		let balancePath = self.balancePaths().get(key: vaultType.identifier)
		assert(
			balancePath != nil,
			message: "No balance path configured for ".concat(vaultType.identifier)
		)
		
		// get the FungibleToken.Balance capability located at the path
		let vaultCap = user.capabilities.get<&{FungibleToken.Balance}>(balancePath!)
		
		// check the capability exists
		if !vaultCap.check(){ 
			return 0.0
		}
		
		// borrow the reference
		let vaultRef = vaultCap.borrow()
		
		// get the balance of the account
		return vaultRef?.balance ?? 0.0
	}
	
	init(){ 
		self.Attributes ={} 
		self.FlowtyUtilsStoragePath = /storage/FlowtyUtils
		let utilsAdmin <- create FlowtyUtilsAdmin()
		self.account.storage.save(<-utilsAdmin, to: self.FlowtyUtilsStoragePath)
	}
}
