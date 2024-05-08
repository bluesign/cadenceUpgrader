import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract interface StarVaultInterfaces{ 
	access(all)
	resource interface VaultPublic{ 
		access(all)
		fun vaultId(): Int
		
		access(all)
		fun base(): UFix64
		
		access(all)
		fun mint(nfts: @[{NonFungibleToken.NFT}], feeVault: @{FungibleToken.Vault}): @[AnyResource]
		
		access(all)
		fun redeem(
			amount: Int,
			vault: @{FungibleToken.Vault},
			specificIds: [
				UInt64
			],
			feeVault: @{FungibleToken.Vault}
		): @[
			AnyResource
		]
		
		access(all)
		fun swap(
			nfts: @[{
				NonFungibleToken.NFT}
			],
			specificIds: [
				UInt64
			],
			feeVault: @{FungibleToken.Vault}
		): @[
			AnyResource
		]
		
		access(all)
		fun getVaultTokenType(): Type
		
		access(all)
		fun allHoldings(): [UInt64]
		
		access(all)
		fun totalHoldings(): Int
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}
		
		access(all)
		fun vaultName(): String
		
		access(all)
		fun collectionKey(): String
		
		access(all)
		fun totalSupply(): UFix64
	}
	
	access(all)
	resource interface VaultAdmin{ 
		access(all)
		fun setVaultFeatures(
			enableMint: Bool,
			enableRandomRedeem: Bool,
			enableTargetRedeem: Bool,
			enableRandomSwap: Bool,
			enableTargetSwap: Bool
		)
		
		access(all)
		fun mint(amount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun setVaultName(vaultName: String)
	}
	
	access(all)
	resource interface VaultTokenCollectionPublic{ 
		access(all)
		fun deposit(vault: Address, tokenVault: @{FungibleToken.Vault})
		
		access(all)
		fun withdraw(vault: Address, amount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun getCollectionLength(): Int
		
		access(all)
		fun getTokenBalance(vault: Address): UFix64
		
		access(all)
		fun getAllTokens(): [Address]
		
		access(all)
		fun getSlicedTokens(from: UInt64, to: UInt64): [Address]
	}
	
	access(all)
	resource interface PoolPublic{ 
		access(all)
		fun pid(): Int
		
		access(all)
		fun stakeToken(): Address
		
		access(all)
		fun duration(): UFix64
		
		access(all)
		fun periodFinish(): UFix64
		
		access(all)
		fun rewardRate(): UFix64
		
		access(all)
		fun lastUpdateTime(): UFix64
		
		access(all)
		fun rewardPerTokenStored(): UFix64
		
		access(all)
		fun queuedRewards(): UFix64
		
		access(all)
		fun currentRewards(): UFix64
		
		access(all)
		fun historicalRewards(): UFix64
		
		access(all)
		fun totalSupply(): UFix64
		
		access(all)
		fun balanceOf(account: Address): UFix64
		
		access(all)
		fun updateReward(account: Address?)
		
		access(all)
		fun lastTimeRewardApplicable(): UFix64
		
		access(all)
		fun rewardPerToken(): UFix64
		
		access(all)
		fun earned(account: Address): UFix64
		
		access(all)
		fun getReward(account: Address)
		
		access(all)
		fun queueNewRewards(vault: @{FungibleToken.Vault})
	}
	
	access(all)
	resource interface LPStakingCollectionPublic{ 
		access(all)
		fun deposit(tokenAddress: Address, tokenVault: @{FungibleToken.Vault})
		
		access(all)
		fun getCollectionLength(): Int
		
		access(all)
		fun getTokenBalance(tokenAddress: Address): UFix64
		
		access(all)
		fun getAllTokens(): [Address]
	}
}
