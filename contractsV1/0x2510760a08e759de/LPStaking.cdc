import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import SwapConfig from "../0x5f4da03554851654/SwapConfig.cdc"

import SwapInterfaces from "../0x5f4da03554851654/SwapInterfaces.cdc"

import SwapFactory from "../0x5f4da03554851654/SwapFactory.cdc"

import StarVaultFactory from "./StarVaultFactory.cdc"

import StarVaultConfig from "./StarVaultConfig.cdc"

import StarVaultInterfaces from "./StarVaultInterfaces.cdc"

access(all)
contract LPStaking{ 
	access(all)
	var poolTemplate: Address
	
	access(self)
	let pools: [Address]
	
	access(self)
	let poolMap:{ Int: Address} // vaultId -> pool
	
	
	access(self)
	let pairMap:{ Address: Address} // pair -> pool
	
	
	access(all)
	var poolAccountPublicKey: String?
	
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	access(all)
	event NewPool(poolAddress: Address, numPools: Int)
	
	access(all)
	event PoolTemplateAddressChanged(oldTemplate: Address, newTemplate: Address)
	
	access(all)
	event PoolAccountPublicKeyChanged(oldPublicKey: String?, newPublicKey: String?)
	
	access(all)
	fun createPool(vaultAddress: Address, accountCreationFee: @{FungibleToken.Vault}): Address{ 
		assert(
			accountCreationFee.balance >= 0.001,
			message: "LPStaking: insufficient account creation fee"
		)
		let vaultRef =
			getAccount(vaultAddress).capabilities.get<&{StarVaultInterfaces.VaultPublic}>(
				StarVaultConfig.VaultPublicPath
			).borrow()
			?? panic("Vault Reference was not created correctly")
		let vaultId = vaultRef.vaultId()
		assert(
			StarVaultFactory.vault(vaultId: vaultId) == vaultAddress,
			message: "LPStaking: invalid vaultAddress",
			self.getPoolAddress(vaultId: vaultId) == nil,
			message: "LPStaking: pool already exists"
		)
		let token0Key =
			StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: Type<@FlowToken.Vault>().identifier
			)
		let token1Key =
			StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: vaultRef.getVaultTokenType().identifier
			)
		let pairAddr =
			SwapFactory.getPairAddress(token0Key: token0Key, token1Key: token1Key)
			?? panic(
				"createPool: nonexistent pair ".concat(token0Key).concat(" <-> ").concat(token1Key)
					.concat(", create pair first")
			)
		assert(!self.pairMap.containsKey(pairAddr), message: "LPStaking: pairAddr already exists")
		(
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow<&{FungibleToken.Receiver}>()!
		).deposit(from: <-accountCreationFee)
		let poolAccount = AuthAccount(payer: self.account)
		if self.poolAccountPublicKey != nil{ 
			poolAccount.keys.add(publicKey: PublicKey(publicKey: (self.poolAccountPublicKey!).decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256), hashAlgorithm: HashAlgorithm.SHA3_256, weight: 1000.0)
		}
		let poolAddress = poolAccount.address
		let poolTemplateContract = getAccount(self.poolTemplate).contracts.get(name: "RewardPool")!
		poolAccount.contracts.add(
			name: "RewardPool",
			code: poolTemplateContract.code,
			pid: self.pools.length,
			stakeToken: pairAddr
		)
		self.poolMap.insert(key: vaultId, poolAddress)
		self.pairMap.insert(key: pairAddr, poolAddress)
		self.pools.append(poolAddress)
		emit NewPool(poolAddress: poolAddress, numPools: self.pools.length)
		return poolAddress
	}
	
	access(all)
	fun distributeFees(vaultId: Int, vault: @{FungibleToken.Vault}){ 
		pre{ 
			self.poolMap.containsKey(vaultId):
				"distributeFees: pool not exists"
		}
		let pool = self.poolMap[vaultId]!
		let poolRef =
			getAccount(pool).capabilities.get<&{StarVaultInterfaces.PoolPublic}>(
				StarVaultConfig.PoolPublicPath
			).borrow()!
		poolRef.queueNewRewards(vault: <-vault)
	}
	
	access(all)
	resource LPStakingCollection: StarVaultInterfaces.LPStakingCollectionPublic{ 
		access(self)
		var tokenVaults: @{Address:{ FungibleToken.Vault}}
		
		init(){ 
			self.tokenVaults <-{} 
		}
		
		access(all)
		fun deposit(tokenAddress: Address, tokenVault: @{FungibleToken.Vault}){ 
			pre{ 
				LPStaking.pairMap.containsKey(tokenAddress):
					"LPStakingCollection: invalid pair address"
				tokenVault.balance > 0.0:
					"LPStakingCollection: deposit empty token vault"
			}
			let pairRef = getAccount(tokenAddress).capabilities.get<&{SwapInterfaces.PairPublic}>(SwapConfig.PairPublicPath).borrow()!
			assert(tokenVault.getType() == pairRef.getLpTokenVaultType(), message: "LPStakingCollection: input token vault type mismatch with token vault")
			if self.tokenVaults.containsKey(tokenAddress){ 
				let vaultRef = (&self.tokenVaults[tokenAddress] as &{FungibleToken.Vault}?)!
				vaultRef.deposit(from: <-tokenVault)
			} else{ 
				self.tokenVaults[tokenAddress] <-! tokenVault
			}
			self.updateReward(tokenAddress: tokenAddress)
		}
		
		access(all)
		fun withdraw(tokenAddress: Address, amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				LPStaking.pairMap.containsKey(tokenAddress):
					"LPStakingCollection: invalid pair address"
				self.tokenVaults.containsKey(tokenAddress):
					"LPStakingCollection: haven't provided liquidity to vault"
			}
			let vaultRef = (&self.tokenVaults[tokenAddress] as &{FungibleToken.Vault}?)!
			let withdrawVault <- vaultRef.withdraw(amount: amount)
			if vaultRef.balance == 0.0{ 
				let deletedVault <- self.tokenVaults[tokenAddress] <- nil
				destroy deletedVault
			}
			self.updateReward(tokenAddress: tokenAddress)
			return <-withdrawVault
		}
		
		access(all)
		fun getCollectionLength(): Int{ 
			return self.tokenVaults.keys.length
		}
		
		access(all)
		fun getTokenBalance(tokenAddress: Address): UFix64{ 
			if self.tokenVaults.containsKey(tokenAddress){ 
				let vaultRef = (&self.tokenVaults[tokenAddress] as &{FungibleToken.Vault}?)!
				return vaultRef.balance
			}
			return 0.0
		}
		
		access(all)
		fun getAllTokens(): [Address]{ 
			return self.tokenVaults.keys
		}
		
		access(self)
		fun updateReward(tokenAddress: Address){ 
			let pool = LPStaking.pairMap[tokenAddress]!
			let poolRef = getAccount(pool).capabilities.get<&{StarVaultInterfaces.PoolPublic}>(StarVaultConfig.PoolPublicPath).borrow()!
			poolRef.updateReward(account: (self.owner!).address)
		}
	}
	
	access(all)
	fun createEmptyLPStakingCollection(): @LPStakingCollection{ 
		return <-create LPStakingCollection()
	}
	
	access(all)
	fun getPoolAddress(vaultId: Int): Address?{ 
		if self.poolMap.containsKey(vaultId){ 
			return self.poolMap[vaultId]!
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun pool(pid: Int): Address{ 
		return self.pools[pid]
	}
	
	access(all)
	fun allPools(): [Address]{ 
		return self.pools
	}
	
	access(all)
	fun numPools(): Int{ 
		return self.pools.length
	}
	
	access(all)
	fun getRewards(account: Address, poolIds: [Int]){ 
		for pid in poolIds{ 
			let poolAddress = self.pools[pid]
			let poolRef = getAccount(poolAddress).capabilities.get<&{StarVaultInterfaces.PoolPublic}>(StarVaultConfig.PoolPublicPath).borrow()!
			poolRef.getReward(account: account)
		}
	}
	
	access(all)
	fun earned(account: Address, poolIds: [Int]): [UFix64]{ 
		let ret: [UFix64] = []
		for pid in poolIds{ 
			let poolAddress = self.pools[pid]
			let poolRef = getAccount(poolAddress).capabilities.get<&{StarVaultInterfaces.PoolPublic}>(StarVaultConfig.PoolPublicPath).borrow()!
			ret.append(poolRef.earned(account: account))
		}
		return ret
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setPoolContractTemplate(newAddr: Address){ 
			pre{ 
				getAccount(newAddr).contracts.get(name: "RewardPool") != nil:
					"invalid template"
			}
			emit PoolTemplateAddressChanged(
				oldTemplate: LPStaking.poolTemplate,
				newTemplate: newAddr
			)
			LPStaking.poolTemplate = newAddr
		}
		
		access(all)
		fun setPoolAccountPublicKey(publicKey: String?){ 
			pre{ 
				PublicKey(publicKey: (publicKey!).decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256) != nil:
					"invalid publicKey"
			}
			emit PoolAccountPublicKeyChanged(
				oldPublicKey: LPStaking.poolAccountPublicKey,
				newPublicKey: publicKey
			)
			LPStaking.poolAccountPublicKey = publicKey
		}
	}
	
	init(poolTemplate: Address, poolAccountPublicKey: String){ 
		pre{ 
			PublicKey(publicKey: (poolAccountPublicKey!).decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256) != nil:
				"invalid publicKey"
		}
		self.poolTemplate = poolTemplate
		self.pools = []
		self.poolAccountPublicKey = poolAccountPublicKey
		self.poolMap ={} 
		self.pairMap ={} 
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(
			from: StarVaultConfig.LPStakingAdminStoragePath
		)
		self.account.storage.save(<-create Admin(), to: StarVaultConfig.LPStakingAdminStoragePath)
	}
}
