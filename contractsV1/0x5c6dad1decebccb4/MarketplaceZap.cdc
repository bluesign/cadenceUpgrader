import FlowToken from "./../../standardsV1/FlowToken.cdc"

import SwapRouter from "../0x5f4da03554851654/SwapRouter.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StarVaultConfig from "./StarVaultConfig.cdc"

import StarVaultInterfaces from "./StarVaultInterfaces.cdc"

import StarVaultFactory from "./StarVaultFactory.cdc"

access(all)
contract MarketplaceZap{ 
	access(all)
	fun mintAndSell(
		vaultId: Int,
		nfts: @[{
			NonFungibleToken.NFT}
		],
		feeVault: @{FungibleToken.Vault}
	): @{FungibleToken.Vault}{ 
		let vaultAddress = StarVaultFactory.vault(vaultId: vaultId)
		let vaultRef =
			getAccount(vaultAddress).capabilities.get<&{StarVaultInterfaces.VaultPublic}>(
				StarVaultConfig.VaultPublicPath
			).borrow()!
		let ret <- vaultRef.mint(nfts: <-nfts, feeVault: <-feeVault)
		let lpVault <- ret.removeFirst() as! @{FungibleToken.Vault}
		let leftVault <- ret.removeFirst() as! @{FungibleToken.Vault}
		destroy ret
		let path =
			[
				StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(
					vaultTypeIdentifier: vaultRef.getVaultTokenType().identifier
				),
				StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(
					vaultTypeIdentifier: Type<@FlowToken.Vault>().identifier
				)
			]
		let swapped <-
			SwapRouter.swapExactTokensForTokens(
				exactVaultIn: <-lpVault,
				amountOutMin: 0.0,
				tokenKeyPath: path,
				deadline: getCurrentBlock().timestamp
			)
		if leftVault.balance > 0.0{ 
			swapped.deposit(from: <-leftVault)
		} else{ 
			destroy leftVault
		}
		return <-swapped
	}
	
	access(all)
	fun buyAndRedeem(
		vaultId: Int,
		amount: Int,
		vaultIn: @{FungibleToken.Vault},
		path: [
			String
		],
		specificIds: [
			UInt64
		]
	): @[
		AnyResource
	]{ 
		let vaultAddress = StarVaultFactory.vault(vaultId: vaultId)
		let vaultRef =
			getAccount(vaultAddress).capabilities.get<&{StarVaultInterfaces.VaultPublic}>(
				StarVaultConfig.VaultPublicPath
			).borrow()!
		let vfee = StarVaultConfig.getVaultFees(vaultId: vaultId)
		let totalFees =
			vfee.targetRedeemFee * UFix64(specificIds.length)
			+ vfee.randomRedeemFee * UFix64(amount - specificIds.length)
		let total = UFix64(amount) * vaultRef.base()
		let swapResVault <-
			SwapRouter.swapTokensForExactTokens(
				vaultInMax: <-vaultIn,
				exactAmountOut: total,
				tokenKeyPath: path,
				deadline: getCurrentBlock().timestamp
			)
		let vaultOut <- swapResVault.removeFirst()
		let vaultInLeft <- swapResVault.removeLast()
		destroy swapResVault
		return <-vaultRef.redeem(
			amount: amount,
			vault: <-vaultOut,
			specificIds: specificIds,
			feeVault: <-vaultInLeft
		)
	}
}
