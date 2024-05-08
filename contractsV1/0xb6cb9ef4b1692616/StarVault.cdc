import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import SwapRouter from "../0xa6850776a94e6551/SwapRouter.cdc"

import StarVaultConfig from "./StarVaultConfig.cdc"

import StarVaultInterfaces from "./StarVaultInterfaces.cdc"

import LPStaking from "./LPStaking.cdc"

access(all)
contract StarVault: FungibleToken{ 
	access(all)
	var totalSupply: UFix64
	
	access(all)
	let vaultId: Int
	
	access(all)
	let base: UFix64
	
	access(all)
	let collectionKey: String
	
	access(all)
	var enableMint: Bool
	
	access(all)
	var enableRandomRedeem: Bool
	
	access(all)
	var enableTargetRedeem: Bool
	
	access(all)
	var enableRandomSwap: Bool
	
	access(all)
	var enableTargetSwap: Bool
	
	access(self)
	var lock: Bool
	
	access(all)
	var vaultName: String
	
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	event NFTReceived(id: UInt64)
	
	access(all)
	event NFTWithdrawn(id: UInt64)
	
	access(all)
	event EnableMintUpdated(enableMint: Bool)
	
	access(all)
	event EnableRandomRedeemUpdated(enableRandomRedeem: Bool)
	
	access(all)
	event EnableTargetRedeemUpdated(enableTargetRedeem: Bool)
	
	access(all)
	event EnableRandomSwapUpdated(enableRandomSwap: Bool)
	
	access(all)
	event EnableTargetSwapUpdated(enableTargetSwap: Bool)
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @StarVault.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(self)
	fun mintToken(amount: UFix64): @StarVault.Vault{ 
		self.totalSupply = self.totalSupply + amount
		emit TokensMinted(amount: amount)
		return <-create Vault(balance: amount)
	}
	
	access(self)
	fun burnToken(from: @{FungibleToken.Vault}){ 
		let amount = from.balance
		destroy from
		emit TokensBurned(amount: amount)
	}
	
	access(self)
	fun distributeFees(fee: @{FungibleToken.Vault}){ 
		let amount = fee.balance
		if amount == 0.0{ 
			destroy fee
			return
		}
		var feeRatio = StarVaultConfig.feeRatio
		let feeTo = StarVaultConfig.feeTo
		if feeTo == nil{ 
			feeRatio = 0.0
		}
		LPStaking.distributeFees(vaultId: self.vaultId, vault: <-fee.withdraw(amount: amount * (1.0 - feeRatio)))
		if feeRatio > 0.0 && feeTo != nil{ 
			let flowVaultRef = getAccount(StarVaultConfig.feeTo!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
			flowVaultRef.deposit(from: <-fee)
		} else{ 
			destroy fee
		}
	}
	
	access(all)
	fun getFeeAmount(amountOut: UFix64): UFix64{ 
		let path = [StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: Type<@FlowToken.Vault>().identifier), StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: Type<@StarVault.Vault>().identifier)]
		let amounts: [UFix64] = SwapRouter.getAmountsIn(amountOut: amountOut, tokenKeyPath: path)
		return amounts[0]
	}
	
	access(all)
	fun mint(nfts: @[{NonFungibleToken.NFT}], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
		pre{ 
			self.enableMint:
				"StarVault: mint not enabled"
			self.lock == false:
				"StarVault: Reentrant"
			feeVault.isInstance(Type<@FlowToken.Vault>()):
				"StarVault: Invalid feeVault type"
		}
		post{ 
			self.lock == false:
				"StarVault: unlock"
		}
		self.lock = true
		let count = self.receiveNFTs(nfts: <-nfts)
		let totalFee = self.getVaultFees().mintFee * UFix64(count)
		let realFee = self.getFeeAmount(amountOut: totalFee)
		assert(feeVault.balance >= realFee, message: "insufficient flow fee")
		let ret: @[AnyResource] <- []
		ret.append(<-self.mintToken(amount: self.base * UFix64(count)))
		self.distributeFees(fee: <-feeVault.withdraw(amount: realFee))
		ret.append(<-feeVault)
		self.lock = false
		return <-ret
	}
	
	access(all)
	fun redeem(amount: Int, vault: @{FungibleToken.Vault}, specificIds: [UInt64], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
		pre{ 
			vault.isInstance(Type<@StarVault.Vault>()):
				"StarVault: incompatible vault type"
			amount == specificIds.length || self.enableRandomRedeem:
				"StarVault: Random redeem not enabled"
			specificIds.length == 0 || self.enableTargetRedeem:
				"StarVault: Target redeem not enabled"
			feeVault.isInstance(Type<@FlowToken.Vault>()):
				"StarVault: Invalid feeVault type"
			self.lock == false:
				"StarVault: Reentrant"
		}
		post{ 
			self.lock == false:
				"StarVault: unlock"
		}
		self.lock = true
		let vaultFees = self.getVaultFees()
		let totalFee = vaultFees.targetRedeemFee * UFix64(specificIds.length) + vaultFees.randomRedeemFee * UFix64(amount - specificIds.length)
		let realFee = self.getFeeAmount(amountOut: totalFee)
		assert(feeVault.balance >= realFee, message: "insufficient flow fee")
		let total = UFix64(amount) * self.base
		assert(total == vault.balance, message: "StarVault: insufficient LP balance to redeem")
		self.distributeFees(fee: <-feeVault.withdraw(amount: realFee))
		let nfts <- self.withdrawNFTs(count: amount, specificIds: specificIds)
		let ret: @[AnyResource] <- []
		var i = 0
		let count = nfts.length
		while i < count{ 
			ret.append(<-nfts.removeFirst())
			i = i + 1
		}
		destroy nfts
		self.burnToken(from: <-vault)
		ret.append(<-feeVault)
		self.lock = false
		return <-ret
	}
	
	access(all)
	fun swap(nfts: @[{NonFungibleToken.NFT}], specificIds: [UInt64], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
		pre{ 
			nfts.length == specificIds.length || self.enableRandomSwap:
				"StarVault: Random swap disabled"
			specificIds.length == 0 || self.enableTargetSwap:
				"StarVault: Target swap disabled"
			feeVault.isInstance(Type<@FlowToken.Vault>()):
				"StarVault: Invalid feeVault type"
			self.lock == false:
				"StarVault: Reentrant"
		}
		post{ 
			self.lock == false:
				"StarVault: unlock"
		}
		self.lock = true
		let cnt = nfts.length
		let vaultFees = self.getVaultFees()
		let totalFee = vaultFees.targetSwapFee * UFix64(specificIds.length) + vaultFees.randomSwapFee * UFix64(cnt - specificIds.length)
		let realFee = self.getFeeAmount(amountOut: totalFee)
		assert(feeVault.balance >= realFee, message: "insufficient flow fee")
		self.distributeFees(fee: <-feeVault.withdraw(amount: realFee))
		let withdrawedNFTs <- self.withdrawNFTs(count: nfts.length, specificIds: specificIds)
		let ret: @[AnyResource] <- []
		self.receiveNFTs(nfts: <-nfts)
		var i = 0
		let count = withdrawedNFTs.length
		while i < count{ 
			ret.append(<-withdrawedNFTs.removeFirst())
			i = i + 1
		}
		destroy withdrawedNFTs
		ret.append(<-feeVault)
		self.lock = false
		return <-ret
	}
	
	access(all)
	fun allHoldings(): [UInt64]{ 
		let collection = self.account.storage.borrow<&{NonFungibleToken.Collection}>(from: StarVaultConfig.VaultNFTCollectionStoragePath)!
		return collection.getIDs()
	}
	
	access(all)
	fun totalHoldings(): Int{ 
		let collection = self.account.storage.borrow<&{NonFungibleToken.Collection}>(from: StarVaultConfig.VaultNFTCollectionStoragePath)!
		return collection.getIDs().length
	}
	
	access(all)
	fun getVaultFees(): StarVaultConfig.VaultFees{ 
		return StarVaultConfig.getVaultFees(vaultId: self.vaultId)
	}
	
	access(self)
	fun receiveNFTs(nfts: @[{NonFungibleToken.NFT}]): Int{ 
		let collection = self.account.storage.borrow<&{NonFungibleToken.Collection}>(from: StarVaultConfig.VaultNFTCollectionStoragePath)!
		let count = nfts.length
		var i = 0
		while i < count{ 
			let token <- nfts.removeFirst()
			emit NFTReceived(id: token.id)
			collection.deposit(token: <-token)
			i = i + 1
		}
		destroy nfts
		return count
	}
	
	access(self)
	fun withdrawNFTs(count: Int, specificIds: [UInt64]): @[{NonFungibleToken.NFT}]{ 
		let collection = self.account.storage.borrow<&{NonFungibleToken.Collection}>(from: StarVaultConfig.VaultNFTCollectionStoragePath)!
		let specificLength = specificIds.length
		let ret: @[{NonFungibleToken.NFT}] <- []
		var i = 0
		var tokenId: UInt64 = 0
		while i < count{ 
			if i < specificLength{ 
				let token <- collection.withdraw(withdrawID: specificIds[i])
				tokenId = token.id
				ret.append(<-token)
			} else{ 
				let token <- self.getRandomNFTFromCollection()
				tokenId = token.id
				ret.append(<-token)
			}
			emit NFTWithdrawn(id: tokenId)
			i = i + 1
		}
		return <-ret
	}
	
	access(self)
	fun getRandomNFTFromCollection(): @{NonFungibleToken.NFT}{ 
		let collection = self.account.storage.borrow<&{NonFungibleToken.Collection}>(from: StarVaultConfig.VaultNFTCollectionStoragePath)!
		let ids = collection.getIDs()
		assert(ids.length > 0, message: "not enough NFTs")
		let id = revertibleRandom<UInt64>() % UInt64(ids.length)
		return <-collection.withdraw(withdrawID: ids[id])
	}
	
	access(self)
	fun setVaultFeatures(enableMint: Bool, enableRandomRedeem: Bool, enableTargetRedeem: Bool, enableRandomSwap: Bool, enableTargetSwap: Bool){ 
		self.enableMint = enableMint
		self.enableRandomRedeem = enableRandomRedeem
		self.enableTargetRedeem = enableTargetRedeem
		self.enableRandomSwap = enableRandomSwap
		self.enableTargetSwap = enableTargetSwap
		emit EnableMintUpdated(enableMint: enableMint)
		emit EnableRandomRedeemUpdated(enableRandomRedeem: enableRandomRedeem)
		emit EnableTargetRedeemUpdated(enableTargetRedeem: enableTargetRedeem)
		emit EnableRandomSwapUpdated(enableRandomSwap: enableRandomSwap)
		emit EnableTargetSwapUpdated(enableTargetSwap: enableTargetSwap)
	}
	
	access(self)
	fun setVaultName(vaultName: String){ 
		self.vaultName = vaultName
	}
	
	access(all)
	resource VaultPublic: StarVaultInterfaces.VaultPublic{ 
		access(all)
		fun vaultId(): Int{ 
			return StarVault.vaultId
		}
		
		access(all)
		fun base(): UFix64{ 
			return StarVault.base
		}
		
		access(all)
		fun mint(nfts: @[{NonFungibleToken.NFT}], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
			return <-StarVault.mint(nfts: <-nfts, feeVault: <-feeVault)
		}
		
		access(all)
		fun redeem(amount: Int, vault: @{FungibleToken.Vault}, specificIds: [UInt64], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
			return <-StarVault.redeem(amount: amount, vault: <-vault, specificIds: specificIds, feeVault: <-feeVault)
		}
		
		access(all)
		fun swap(nfts: @[{NonFungibleToken.NFT}], specificIds: [UInt64], feeVault: @{FungibleToken.Vault}): @[AnyResource]{ 
			return <-StarVault.swap(nfts: <-nfts, specificIds: specificIds, feeVault: <-feeVault)
		}
		
		access(all)
		fun getVaultTokenType(): Type{ 
			return Type<@StarVault.Vault>()
		}
		
		access(all)
		fun allHoldings(): [UInt64]{ 
			return StarVault.allHoldings()
		}
		
		access(all)
		fun totalHoldings(): Int{ 
			return StarVault.totalHoldings()
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-StarVault.createEmptyVault(vaultType: Type<@StarVault.Vault>())
		}
		
		access(all)
		fun vaultName(): String{ 
			return StarVault.vaultName
		}
		
		access(all)
		fun collectionKey(): String{ 
			return StarVault.collectionKey
		}
		
		access(all)
		fun totalSupply(): UFix64{ 
			return StarVault.totalSupply
		}
	}
	
	access(all)
	resource Admin: StarVaultInterfaces.VaultAdmin{ 
		access(all)
		fun setVaultFeatures(enableMint: Bool, enableRandomRedeem: Bool, enableTargetRedeem: Bool, enableRandomSwap: Bool, enableTargetSwap: Bool){ 
			StarVault.setVaultFeatures(enableMint: enableMint, enableRandomRedeem: enableRandomRedeem, enableTargetRedeem: enableTargetRedeem, enableRandomSwap: enableRandomSwap, enableTargetSwap: enableTargetSwap)
		}
		
		access(all)
		fun mint(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-StarVault.mintToken(amount: amount)
		}
		
		access(all)
		fun setVaultName(vaultName: String){ 
			StarVault.setVaultName(vaultName: vaultName)
		}
	}
	
	init(vaultId: Int, vaultName: String, collection: @{NonFungibleToken.Collection}){ 
		self.vaultId = vaultId
		self.totalSupply = 0.0
		self.lock = false
		self.base = 1.0
		self.vaultName = vaultName
		self.collectionKey = StarVaultConfig.sliceTokenTypeIdentifierFromCollectionType(collectionTypeIdentifier: collection.getType().identifier)
		self.enableMint = true
		self.enableRandomRedeem = true
		self.enableTargetRedeem = true
		self.enableRandomSwap = true
		self.enableTargetSwap = true
		let vaultStoragePath = StarVaultConfig.VaultStoragePath
		destroy <-self.account.storage.load<@AnyResource>(from: vaultStoragePath)
		self.account.storage.save(<-create VaultPublic(), to: vaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{StarVaultInterfaces.VaultPublic}>(vaultStoragePath)
		self.account.capabilities.publish(capability_1, at: StarVaultConfig.VaultPublicPath)
		self.account.storage.save(<-collection, to: StarVaultConfig.VaultNFTCollectionStoragePath)
		destroy <-self.account.storage.load<@AnyResource>(from: StarVaultConfig.VaultAdminStoragePath)
		self.account.storage.save(<-create Admin(), to: StarVaultConfig.VaultAdminStoragePath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
