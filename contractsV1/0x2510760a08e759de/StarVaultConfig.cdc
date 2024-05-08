access(all)
contract StarVaultConfig{ 
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let VaultNFTCollectionStoragePath: StoragePath
	
	access(all)
	let VaultAdminStoragePath: StoragePath
	
	access(all)
	let VaultTokenCollectionPublicPath: PublicPath
	
	access(all)
	let VaultTokenCollectionStoragePath: StoragePath
	
	access(all)
	let PoolPublicPath: PublicPath
	
	access(all)
	let PoolStoragePath: StoragePath
	
	access(all)
	let LPStakingCollectionStoragePath: StoragePath
	
	access(all)
	let LPStakingCollectionPublicPath: PublicPath
	
	access(all)
	let LPStakingAdminStoragePath: StoragePath
	
	access(all)
	let FactoryAdminStoragePath: StoragePath
	
	access(all)
	let ConfigAdminStoragePath: StoragePath
	
	access(all)
	var feeTo: Address?
	
	access(all)
	var feeRatio: UFix64
	
	access(all)
	struct VaultFees{ 
		access(all)
		var mintFee: UFix64
		
		access(all)
		var randomRedeemFee: UFix64
		
		access(all)
		var targetRedeemFee: UFix64
		
		access(all)
		var randomSwapFee: UFix64
		
		access(all)
		var targetSwapFee: UFix64
		
		init(
			mintFee: UFix64,
			randomRedeemFee: UFix64,
			targetRedeemFee: UFix64,
			randomSwapFee: UFix64,
			targetSwapFee: UFix64
		){ 
			self.mintFee = mintFee
			self.randomRedeemFee = randomRedeemFee
			self.targetRedeemFee = targetRedeemFee
			self.randomSwapFee = randomSwapFee
			self.targetSwapFee = targetSwapFee
		}
	}
	
	access(all)
	var globalVaultFees: VaultFees
	
	access(self)
	let vaultFees:{ Int: VaultFees}
	
	access(all)
	event UpdateGlobalFees(
		mintFee: UFix64,
		randomRedeemFee: UFix64,
		targetRedeemFee: UFix64,
		randomSwapFee: UFix64,
		targetSwapFee: UFix64
	)
	
	access(all)
	event UpdateVaultFees(
		vaultId: Int,
		mintFee: UFix64,
		randomRedeemFee: UFix64,
		targetRedeemFee: UFix64,
		randomSwapFee: UFix64,
		targetSwapFee: UFix64
	)
	
	access(all)
	event DisableVaultFees(vaultId: Int)
	
	access(all)
	event FeeToAddressChanged(oldFeeTo: Address?, newFeeTo: Address?)
	
	access(all)
	event FeeRatioChanged(oldFeeRatio: UFix64, newFeeRatio: UFix64)
	
	access(all)
	fun SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: String): String{ 
		return vaultTypeIdentifier.slice(from: 0, upTo: vaultTypeIdentifier.length - 6)
	}
	
	access(all)
	fun sliceTokenTypeIdentifierFromCollectionType(collectionTypeIdentifier: String): String{ 
		return collectionTypeIdentifier.slice(from: 0, upTo: collectionTypeIdentifier.length - 11)
	}
	
	access(all)
	fun getVaultFees(vaultId: Int): VaultFees{ 
		if self.vaultFees.containsKey(vaultId){ 
			return self.vaultFees[vaultId]!
		} else{ 
			return self.globalVaultFees
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setFactoryFees(
			mintFee: UFix64,
			randomRedeemFee: UFix64,
			targetRedeemFee: UFix64,
			randomSwapFee: UFix64,
			targetSwapFee: UFix64
		){ 
			StarVaultConfig.globalVaultFees = VaultFees(
					mintFee: mintFee,
					randomRedeemFee: randomRedeemFee,
					targetRedeemFee: targetRedeemFee,
					randomSwapFee: randomSwapFee,
					targetSwapFee: targetSwapFee
				)
			emit UpdateGlobalFees(
				mintFee: mintFee,
				randomRedeemFee: randomRedeemFee,
				targetRedeemFee: targetRedeemFee,
				randomSwapFee: randomSwapFee,
				targetSwapFee: targetSwapFee
			)
		}
		
		access(all)
		fun setVaultFees(
			vaultId: Int,
			mintFee: UFix64,
			randomRedeemFee: UFix64,
			targetRedeemFee: UFix64,
			randomSwapFee: UFix64,
			targetSwapFee: UFix64
		){ 
			let fees =
				VaultFees(
					mintFee: mintFee,
					randomRedeemFee: randomRedeemFee,
					targetRedeemFee: targetRedeemFee,
					randomSwapFee: randomSwapFee,
					targetSwapFee: targetSwapFee
				)
			StarVaultConfig.vaultFees.insert(key: vaultId, fees)
			emit UpdateVaultFees(
				vaultId: vaultId,
				mintFee: mintFee,
				randomRedeemFee: randomRedeemFee,
				targetRedeemFee: targetRedeemFee,
				randomSwapFee: randomSwapFee,
				targetSwapFee: targetSwapFee
			)
		}
		
		access(all)
		fun disableVaultFees(vaultId: Int){ 
			pre{ 
				StarVaultConfig.vaultFees.containsKey(vaultId):
					"vault fee not set"
			}
			StarVaultConfig.vaultFees.remove(key: vaultId)
			emit DisableVaultFees(vaultId: vaultId)
		}
		
		access(all)
		fun setFeeTo(feeToAddr: Address){ 
			emit FeeToAddressChanged(oldFeeTo: StarVaultConfig.feeTo, newFeeTo: feeToAddr)
			StarVaultConfig.feeTo = feeToAddr
		}
		
		access(all)
		fun setFeeRatio(feeRatio: UFix64){ 
			pre{ 
				feeRatio <= 1.0:
					"setFeeRatio: feeRatio overflow"
			}
			emit FeeRatioChanged(oldFeeRatio: StarVaultConfig.feeRatio, newFeeRatio: feeRatio)
			StarVaultConfig.feeRatio = feeRatio
		}
	}
	
	init(){ 
		self.VaultPublicPath = /public/star_vault
		self.VaultStoragePath = /storage/star_vault
		self.VaultNFTCollectionStoragePath = /storage/star_vault_nft_collection
		self.VaultAdminStoragePath = /storage/star_vault_admin
		self.VaultTokenCollectionPublicPath = /public/star_vault_token_collection
		self.VaultTokenCollectionStoragePath = /storage/star_vault_token_collection
		self.PoolPublicPath = /public/star_vault_reward_pool
		self.PoolStoragePath = /storage/star_vault_reward_pool
		self.LPStakingCollectionStoragePath = /storage/star_vault_lpstaking_collection
		self.LPStakingCollectionPublicPath = /public/star_vault_lpstaking_collection
		self.LPStakingAdminStoragePath = /storage/star_vault_lpstaking_admin
		self.FactoryAdminStoragePath = /storage/star_vault_factory_admin
		self.ConfigAdminStoragePath = /storage/star_vault_config_admin
		self.globalVaultFees = VaultFees(
				mintFee: 0.0,
				randomRedeemFee: 0.0,
				targetRedeemFee: 0.0,
				randomSwapFee: 0.0,
				targetSwapFee: 0.0
			)
		self.vaultFees ={} 
		self.feeTo = nil
		self.feeRatio = 0.0
		destroy <-self.account.storage.load<@AnyResource>(from: self.ConfigAdminStoragePath)
		self.account.storage.save(<-create Admin(), to: self.ConfigAdminStoragePath)
	}
}
