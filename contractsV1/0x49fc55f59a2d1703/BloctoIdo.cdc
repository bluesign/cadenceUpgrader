import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import TeleportedTetherToken from "../0xcfdd90d4a00f7b5b/TeleportedTetherToken.cdc"

import BloctoToken from "../0x0f9df91c9121c460/BloctoToken.cdc"

access(all)
contract BloctoIdo{ 
	access(all)
	let BloctoIdoAdminStoragePath: StoragePath
	
	access(all)
	let BloctoIdoAdminPublicPath: PublicPath
	
	access(all)
	let BloctoIdoUserStoragePath: StoragePath
	
	access(all)
	let BloctoIdoUserPublicPath: PublicPath
	
	access(all)
	event AddKycInfo(name: String, addr: Address)
	
	access(all)
	event AddKycInfoError(name: String, addr: Address, reason: String)
	
	access(all)
	event SelectPool(name: String, addr: Address, poolType: String)
	
	access(all)
	event Deposit(name: String, addr: Address, amount: UFix64)
	
	access(all)
	event UpdateQuota(name: String, addr: Address, amount: UFix64)
	
	access(all)
	event UpdateQuotaError(name: String, addr: Address, reason: String)
	
	access(all)
	event Distribute(name: String, addr: Address, amount: UFix64)
	
	access(all)
	event DistributingError(name: String, addr: Address, reason: String)
	
	access(contract)
	var fee: @BloctoToken.Vault
	
	access(contract)
	var vault: @TeleportedTetherToken.Vault
	
	access(contract)
	var activities:{ String: Activity}
	
	access(contract)
	var activitiesOrder: [String]
	
	access(contract)
	var idToAddress:{ UInt64: Address}
	
	access(all)
	var userId: UInt64
	
	access(all)
	struct TokenInfo{ 
		access(all)
		var contractName: String
		
		access(all)
		var address: Address
		
		access(all)
		var storagePath: StoragePath
		
		access(all)
		var receiverPath: PublicPath
		
		access(all)
		var balancePath: PublicPath
		
		init(){ 
			self.contractName = ""
			self.address = 0x0
			self.storagePath = /storage/defaultTokenPath
			self.receiverPath = /public/defaultTokenPath
			self.balancePath = /public/defaultTokenPath
		}
	}
	
	access(all)
	struct PoolConfig{ 
		access(all)
		var amount: UFix64
		
		access(all)
		var minimumStake: UFix64
		
		access(all)
		var upperBound: UFix64
		
		access(all)
		var selectFee: UFix64
		
		access(all)
		var exchangeRate: UFix64
		
		init(){ 
			self.amount = 0.0
			self.minimumStake = 0.0
			self.upperBound = 0.0
			self.selectFee = 0.0
			self.exchangeRate = 0.0
		}
	}
	
	access(all)
	struct ActivityConfig{ 
		access(all)
		var tokenInfo: BloctoIdo.TokenInfo
		
		access(all)
		var schedule:{ String: [UFix64]}
		
		access(all)
		var poolConfig:{ String: BloctoIdo.PoolConfig}
		
		access(all)
		var snapshotTimes: UInt64
		
		init(
			_ tokenInfo: BloctoIdo.TokenInfo,
			_ schedule:{ 
				String: [
					UFix64
				]
			},
			_ poolConfig:{ 
				String: BloctoIdo.PoolConfig
			},
			_ snapshotTimes: UInt64
		){ 
			self.tokenInfo = tokenInfo
			self.schedule = schedule
			self.poolConfig = poolConfig
			self.snapshotTimes = snapshotTimes
		}
	}
	
	access(all)
	struct Activity{ 
		// activity config
		access(all)
		var tokenInfo: TokenInfo
		
		// TODO use enum
		// Key => KYC | SELECT_POOL | DEPOSIT | DISTRIBUTE
		// Value => [startTimestamp, endTimestamp]
		access(all)
		var schedule:{ String: [UFix64]}
		
		access(all)
		var poolConfig:{ String: PoolConfig}
		
		// user data
		access(all)
		var kycList: [Address]
		
		access(all)
		var userInfos:{ Address: UserInfo}
		
		access(all)
		var totalValidStake:{ String: UFix64}
		
		access(all)
		var snapshotTimes: UInt64
		
		init(){ 
			self.tokenInfo = TokenInfo()
			self.schedule ={} 
			self.poolConfig ={} 
			self.kycList = []
			self.userInfos ={} 
			self.totalValidStake ={} 
			self.snapshotTimes = 0
		}
		
		access(contract)
		fun addUserInfo(address: Address, userInfo: UserInfo){ 
			self.userInfos.insert(key: address, userInfo)
		}
		
		access(contract)
		fun updateUserInfo(address: Address, userInfo: UserInfo){ 
			self.userInfos[address] = userInfo
		}
		
		access(contract)
		fun updateTotalValidStake(poolType: String, totalValidStake: UFix64){ 
			self.totalValidStake[poolType] = totalValidStake
		}
		
		access(contract)
		fun addKycList(address: Address){ 
			self.kycList.append(address)
		}
	}
	
	access(all)
	struct StakeInfo{ 
		access(all)
		var stakeAmount: UFix64
		
		access(all)
		var lockAmount: UFix64
		
		init(){ 
			self.stakeAmount = 0.0
			self.lockAmount = 0.0
		}
	}
	
	access(all)
	struct UserInfo{ 
		// TODO use enum
		// LIMITED | UNLIMITED
		access(all)
		var poolType: String
		
		access(all)
		var stakeInfos: [StakeInfo]
		
		access(all)
		var quota: UFix64
		
		access(all)
		var deposited: UFix64
		
		access(all)
		var distributed: Bool
		
		init(){ 
			self.poolType = ""
			self.stakeInfos = []
			self.quota = 0.0
			self.deposited = 0.0
			self.distributed = false
		}
	}
	
	access(all)
	resource interface UserPublic{ 
		access(all)
		let id: UInt64
	}
	
	access(all)
	resource User: UserPublic{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		fun selectPool(name: String, poolType: String, vault: @BloctoToken.Vault){ 
			let activity = BloctoIdo.activities[name] ?? panic("ido does not exist")
			let interval = activity.schedule["SELECT_POOL"] ?? panic("stage does not exist")
			let current = getCurrentBlock().timestamp
			if current < interval[0] || current > interval[1]{ 
				panic("stage closed")
			}
			let address = BloctoIdo.idToAddress[self.id] ?? panic("invalid id")
			let userInfo = activity.userInfos[address] ?? panic("user info does not exist")
			if userInfo.poolType != ""{ 
				panic("you have already selected a pool")
			}
			let poolConfig = activity.poolConfig[poolType] ?? panic("unsupported pool type")
			if vault.balance < poolConfig.selectFee{ 
				panic("fee is not enough")
			}
			
			// calculate stake amount
			let validStake = BloctoIdo.calculateValidStake(poolType: poolType, stakeInfos: userInfo.stakeInfos, upperBound: poolConfig.upperBound)
			var oriTotalValidStake = 0.0
			if activity.totalValidStake[poolType] != nil{ 
				oriTotalValidStake = activity.totalValidStake[poolType]!
			}
			userInfo.poolType = poolType
			activity.updateUserInfo(address: address, userInfo: userInfo)
			activity.updateTotalValidStake(poolType: poolType, totalValidStake: oriTotalValidStake + validStake)
			BloctoIdo.activities[name] = activity
			emit SelectPool(name: name, addr: address, poolType: poolType)
			BloctoIdo.fee.deposit(from: <-vault)
		}
		
		access(all)
		fun deposit(name: String, vault: @TeleportedTetherToken.Vault){ 
			let activity = BloctoIdo.activities[name] ?? panic("ido does not exist")
			let interval = activity.schedule["DEPOSIT"] ?? panic("stage does not exist")
			let current = getCurrentBlock().timestamp
			if current < interval[0] || current > interval[1]{ 
				panic("stage closed")
			}
			let addressOpt = self.owner
			if addressOpt == nil{ 
				panic("resource owner is nil")
			}
			let address = (addressOpt!).address
			let expectedAddress = BloctoIdo.idToAddress[self.id] ?? panic("can't get expected address")
			if address != expectedAddress{ 
				panic("unexpected address")
			}
			let userInfo = activity.userInfos[address] ?? panic("user info does not exist")
			if userInfo.deposited + vault.balance > userInfo.quota{ 
				panic("insufficient quota")
			}
			userInfo.deposited = userInfo.deposited + vault.balance
			activity.updateUserInfo(address: address, userInfo: userInfo)
			BloctoIdo.activities[name] = activity
			emit Deposit(name: name, addr: address, amount: vault.balance)
			BloctoIdo.vault.deposit(from: <-vault)
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun upsertActivity(_ name: String, _ activity: Activity){ 
			if BloctoIdo.activities[name] == nil{ 
				BloctoIdo.activitiesOrder.append(name)
			}
			BloctoIdo.activities[name] = activity
		}
		
		access(all)
		fun removeActivity(_ name: String){ 
			var idx = 0
			while idx < BloctoIdo.activitiesOrder.length{ 
				let activityName = BloctoIdo.activitiesOrder[idx]
				if activityName == name{ 
					BloctoIdo.activitiesOrder.remove(at: idx)
					break
				}
				idx = idx + 1
			}
			BloctoIdo.activities.remove(key: name)
		}
		
		access(all)
		fun addKycList(_ name: String, _ addrList: [Address]){ 
			if !BloctoIdo.activities.containsKey(name){ 
				panic("activity doesn't exist")
			}
			for addr in addrList{ 
				// check ido user
				let idoUserPublicRefOpt = getAccount(addr).capabilities.get<&{BloctoIdo.UserPublic}>(BloctoIdo.BloctoIdoUserPublicPath).borrow<&{BloctoIdo.UserPublic}>()
				if idoUserPublicRefOpt == nil{ 
					emit AddKycInfoError(name: name, addr: addr, reason: "failed to get ido user public")
					continue
				}
				let idoUserPublicRef = idoUserPublicRefOpt!
				
				// continue if already existed
				if (BloctoIdo.activities[name]!).userInfos.containsKey(addr){ 
					continue
				}
				let userInfo = BloctoIdo.UserInfo()
				(BloctoIdo.activities[name]!).addUserInfo(address: addr, userInfo: userInfo)
				(BloctoIdo.activities[name]!).addKycList(address: addr)
				self.setIdToAddress(id: idoUserPublicRef.id, address: addr)
				emit AddKycInfo(name: name, addr: addr)
			}
		}
		
		access(all)
		fun addStakeInfo(
			name: String,
			addrList: [
				Address
			],
			stakeAmountList: [
				UFix64
			],
			lockAmountList: [
				UFix64
			]
		){ 
			if !BloctoIdo.activities.containsKey(name){ 
				panic("activity doesn't exist")
			}
			if addrList.length != stakeAmountList.length{ 
				panic("addrList.length != stakeAmountList.length")
			}
			if addrList.length != lockAmountList.length{ 
				panic("addrList.length != lockAmountList.length")
			}
			var idx = -1
			while true{ 
				idx = idx + 1
				if idx >= addrList.length{ 
					break
				}
				let addr = addrList[idx]
				if (BloctoIdo.activities[name]!).userInfos.containsKey(addr) == nil{ 
					continue
				}
				let poolType = ((BloctoIdo.activities[name]!).userInfos[addr]!).poolType
				if poolType == ""{ 
					let stakeInfo = BloctoIdo.StakeInfo()
					stakeInfo.stakeAmount = stakeAmountList[idx]
					stakeInfo.lockAmount = lockAmountList[idx]
					((BloctoIdo.activities[name]!).userInfos[addr]!).stakeInfos.append(stakeInfo)
				} else{ 
					let upperBound = ((BloctoIdo.activities[name]!).poolConfig[poolType]!).upperBound
					let preValidStake = BloctoIdo.calculateValidStake(poolType: poolType, stakeInfos: ((BloctoIdo.activities[name]!).userInfos[addr]!).stakeInfos, upperBound: upperBound)
					let stakeInfo = BloctoIdo.StakeInfo()
					stakeInfo.stakeAmount = stakeAmountList[idx]
					stakeInfo.lockAmount = lockAmountList[idx]
					((BloctoIdo.activities[name]!).userInfos[addr]!).stakeInfos.append(stakeInfo)
					let postValidStake = BloctoIdo.calculateValidStake(poolType: poolType, stakeInfos: ((BloctoIdo.activities[name]!).userInfos[addr]!).stakeInfos, upperBound: upperBound)
					if (BloctoIdo.activities[name]!).totalValidStake[poolType] != nil{ 
						(BloctoIdo.activities[name]!).updateTotalValidStake(poolType: poolType, totalValidStake: (BloctoIdo.activities[name]!).totalValidStake[poolType]! - preValidStake + postValidStake)
					}
				}
			}
		}
		
		access(all)
		fun updateStakeInfo(name: String, addr: Address, stakeInfos: [StakeInfo]){ 
			if !BloctoIdo.activities.containsKey(name){ 
				panic("activity doesn't exist")
			}
			if (BloctoIdo.activities[name]!).userInfos.containsKey(addr) == nil{ 
				panic("user doesn't exist")
			}
			let userInfo = (BloctoIdo.activities[name]!).userInfos[addr]!
			if userInfo.poolType != ""{ 
				let upperBound = ((BloctoIdo.activities[name]!).poolConfig[userInfo.poolType]!).upperBound
				let userPreValidStake = BloctoIdo.calculateValidStake(poolType: userInfo.poolType, stakeInfos: userInfo.stakeInfos, upperBound: upperBound)
				let userPostValidStake = BloctoIdo.calculateValidStake(poolType: userInfo.poolType, stakeInfos: stakeInfos, upperBound: upperBound)
				var totalValidStake = 0.0
				if (BloctoIdo.activities[name]!).totalValidStake[userInfo.poolType] != nil{ 
					totalValidStake = (BloctoIdo.activities[name]!).totalValidStake[userInfo.poolType]!
					if totalValidStake >= userPreValidStake{ 
						totalValidStake = totalValidStake - userPreValidStake
					}
				}
				(BloctoIdo.activities[name]!).updateTotalValidStake(poolType: userInfo.poolType, totalValidStake: totalValidStake + userPostValidStake)
			}
			userInfo.stakeInfos = stakeInfos
			(BloctoIdo.activities[name]!).addUserInfo(address: addr, userInfo: userInfo)
		}
		
		access(all)
		fun updateQuota(name: String, addrList: [Address], quotaList: [UFix64]){ 
			if !BloctoIdo.activities.containsKey(name){ 
				panic("activity doesn't exist")
			}
			if addrList.length != quotaList.length{ 
				panic("addrList.length != quotaList.length")
			}
			var idx = -1
			while true{ 
				idx = idx + 1
				if idx >= addrList.length{ 
					break
				}
				let addr = addrList[idx]
				if !(BloctoIdo.activities[name]!).userInfos.containsKey(addr){ 
					emit UpdateQuotaError(name: name, addr: addr, reason: "doesn't exist user")
					continue
				}
				let userInfo = (BloctoIdo.activities[name]!).userInfos[addr]!
				userInfo.quota = quotaList[idx]
				(BloctoIdo.activities[name]!).addUserInfo(address: addr, userInfo: userInfo)
				emit UpdateQuota(name: name, addr: addr, amount: quotaList[idx])
			}
		}
		
		access(all)
		fun setIdToAddress(id: UInt64, address: Address){ 
			BloctoIdo.idToAddress[id] = address
		}
		
		access(all)
		fun distribute(_ name: String, start: UInt64, num: UInt64){ 
			let activity = BloctoIdo.activities[name] ?? panic("ido does not exist")
			let interval = activity.schedule["DISTRIBUTE"] ?? panic("stage does not exist")
			let current = getCurrentBlock().timestamp
			if current < interval[0] || current > interval[1]{ 
				panic("stage closed")
			}
			var curr = start
			let end = start + num
			while curr < end{ 
				let address = activity.kycList[curr]
				let userInfo = activity.userInfos[address] ?? panic("failed to get user info")
				if userInfo.distributed{ 
					curr = curr + 1
					continue
				}
				if userInfo.poolType != "" && userInfo.deposited != 0.0{ 
					let poolConfig = activity.poolConfig[userInfo.poolType] ?? panic("invalid pool type")
					let vaultRef = BloctoIdo.account.storage.borrow<&{FungibleToken.Vault}>(from: activity.tokenInfo.storagePath) ?? panic("failed to get vault")
					let receiverRefOpt = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(activity.tokenInfo.receiverPath).borrow<&{FungibleToken.Receiver}>()
					if receiverRefOpt == nil{ 
						emit DistributingError(name: name, addr: address, reason: "failed to borrow receiver")
						curr = curr + 1
						continue
					}
					let receiverRef = receiverRefOpt!
					let amount = userInfo.deposited / poolConfig.exchangeRate
					receiverRef.deposit(from: <-vaultRef.withdraw(amount: amount))
					BloctoIdo.activities[name] = activity
					emit Distribute(name: name, addr: address, amount: amount)
				}
				userInfo.distributed = true
				activity.updateUserInfo(address: address, userInfo: userInfo)
				curr = curr + 1
			}
			BloctoIdo.activities[name] = activity
		}
		
		access(all)
		fun withdrawFromFee(amount: UFix64): @BloctoToken.Vault{ 
			return <-(BloctoIdo.fee.withdraw(amount: amount) as! @BloctoToken.Vault)
		}
		
		access(all)
		fun withdrawFromVault(amount: UFix64): @TeleportedTetherToken.Vault{ 
			return <-(BloctoIdo.vault.withdraw(amount: amount) as! @TeleportedTetherToken.Vault)
		}
	}
	
	access(all)
	fun getActivity(_ name: String): Activity?{ 
		return BloctoIdo.activities[name]
	}
	
	access(all)
	fun getActivityConfig(_ name: String): ActivityConfig?{ 
		let activityOpt = BloctoIdo.activities[name]
		if activityOpt == nil{ 
			return nil
		}
		let activity = activityOpt!
		return ActivityConfig(
			activity.tokenInfo,
			activity.schedule,
			activity.poolConfig,
			activity.snapshotTimes
		)
	}
	
	access(all)
	fun getAddressById(id: UInt64): Address?{ 
		return BloctoIdo.idToAddress[id]
	}
	
	access(all)
	fun getActivityNames(): [String]{ 
		return BloctoIdo.activitiesOrder
	}
	
	access(all)
	fun createNewUser(): @User{ 
		let newUser <- create User(id: BloctoIdo.userId)
		BloctoIdo.userId = BloctoIdo.userId + 1
		return <-newUser
	}
	
	access(all)
	fun calculateValidStake(poolType: String, stakeInfos: [StakeInfo], upperBound: UFix64): UFix64{ 
		var lastEpochStakeAmount = 0.0
		var validStake = 0.0
		var weights = 1.0
		switch poolType{ 
			case "LIMITED":
				for stakeInfo in stakeInfos{ 
					var stakeAmount = stakeInfo.stakeAmount
					if stakeAmount < lastEpochStakeAmount{ 
						return 0.0
					}
					if upperBound != 0.0 && stakeAmount > upperBound{ 
						stakeAmount = upperBound
					}
					if stakeAmount > lastEpochStakeAmount{ 
						validStake = validStake * (weights - 1.0) / weights
						validStake = validStake + stakeAmount / weights
					}
					lastEpochStakeAmount = stakeAmount
					weights = weights + 1.0
				}
			case "UNLIMITED":
				for stakeInfo in stakeInfos{ 
					var stakeAmount = 0.0
					if stakeInfo.stakeAmount > stakeInfo.lockAmount{ 
						stakeAmount = stakeInfo.stakeAmount - stakeInfo.lockAmount
					}
					if stakeAmount < lastEpochStakeAmount{ 
						return 0.0
					}
					if stakeAmount > lastEpochStakeAmount{ 
						validStake = validStake * (weights - 1.0) / weights
						validStake = validStake + stakeAmount / weights
					}
					lastEpochStakeAmount = stakeAmount
					weights = weights + 1.0
				}
		}
		return validStake
	}
	
	access(all)
	fun getFeeBalance(): UFix64{ 
		return BloctoIdo.fee.balance
	}
	
	access(all)
	fun getVaultBalance(): UFix64{ 
		return BloctoIdo.vault.balance
	}
	
	init(){ 
		self.BloctoIdoAdminStoragePath = /storage/BloctoIdoAdmin
		self.BloctoIdoAdminPublicPath = /public/BloctoIdoAdmin
		self.BloctoIdoUserStoragePath = /storage/BloctoIdoUser
		self.BloctoIdoUserPublicPath = /public/BloctoIdoUser
		self.fee <- BloctoToken.createEmptyVault(vaultType: Type<@BloctoToken.Vault>())
			as!
			@BloctoToken.Vault
		self.vault <- TeleportedTetherToken.createEmptyVault(
				vaultType: Type<@TeleportedTetherToken.Vault>()
			)
			as!
			@TeleportedTetherToken.Vault
		self.userId = 1
		self.activities ={} 
		self.activitiesOrder = []
		self.idToAddress ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.BloctoIdoAdminStoragePath)
	}
}
