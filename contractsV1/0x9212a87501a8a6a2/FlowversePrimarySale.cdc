// MAINNET
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

import FlowversePass from "./FlowversePass.cdc"

import FlowverseSocks from "../0xce4c02539d1fabe8/FlowverseSocks.cdc"

import Crypto

access(all)
contract FlowversePrimarySale{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	// Incremented ID used to create entities
	access(all)
	var nextPrimarySaleID: UInt64
	
	access(contract)
	var primarySales: @{UInt64: PrimarySale}
	
	access(contract)
	var primarySaleIDs:{ String: UInt64}
	
	access(all)
	event PrimarySaleCreated(
		primarySaleID: UInt64,
		contractName: String,
		contractAddress: Address,
		setID: UInt64,
		prices:{ 
			String: PriceData
		},
		launchDate: String,
		endDate: String,
		pooled: Bool
	)
	
	access(all)
	event PrimarySaleStatusChanged(primarySaleID: UInt64, status: String)
	
	access(all)
	event PrimarySaleDateUpdated(primarySaleID: UInt64, date: String, isLaunch: Bool)
	
	access(all)
	event PriceSet(
		primarySaleID: UInt64,
		type: String,
		price: UFix64,
		eligibleAddresses: [
			Address
		]?,
		maxMintsPerUser: UInt64
	)
	
	access(all)
	event EntityAdded(primarySaleID: UInt64, entityID: UInt64, pool: String?, quantity: UInt64)
	
	access(all)
	event EntityRemoved(primarySaleID: UInt64, entityID: UInt64, pool: String?)
	
	// NFTPurchased is deprecated - please refer to PurchasedOrder event instead
	access(all)
	event NFTPurchased(
		primarySaleID: UInt64,
		entityID: UInt64,
		nftID: UInt64,
		purchaserAddress: Address,
		priceType: String,
		price: UFix64
	)
	
	access(all)
	event PurchasedOrder(
		primarySaleID: UInt64,
		entityID: UInt64,
		quantity: UInt64,
		nftIDs: [
			UInt64
		],
		purchaserAddress: Address,
		priceType: String,
		price: UFix64
	)
	
	access(all)
	event ClaimedTreasures(
		primarySaleID: UInt64,
		nftIDs: [
			UInt64
		],
		passIDs: [
			UInt64
		],
		sockIDs: [
			UInt64
		],
		claimerAddress: Address,
		pool: String
	)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	resource interface IMinter{ 
		access(all)
		fun mint(entityID: UInt64, minterAddress: Address): @{NonFungibleToken.NFT}
	}
	
	// Data struct signed by admin account - allows accounts to purchase from a primary sale for a period of time.
	access(all)
	struct AdminSignedPayload{ 
		access(all)
		let primarySaleID: UInt64
		
		access(all)
		let purchaserAddress: Address
		
		access(all)
		let expiration: UInt64 // unix timestamp
		
		
		init(primarySaleID: UInt64, purchaserAddress: Address, expiration: UInt64){ 
			self.primarySaleID = primarySaleID
			self.purchaserAddress = purchaserAddress
			self.expiration = expiration
		}
		
		access(all)
		view fun toString(): String{ 
			return self.primarySaleID.toString().concat("-").concat(
				self.purchaserAddress.toString()
			).concat("-").concat(self.expiration.toString())
		}
	}
	
	access(all)
	struct PriceData{ 
		access(all)
		let priceType: String
		
		access(all)
		let eligibleAddresses: [Address]?
		
		access(all)
		let price: UFix64
		
		access(all)
		var maxMintsPerUser: UInt64
		
		init(
			priceType: String,
			eligibleAddresses: [
				Address
			]?,
			price: UFix64,
			maxMintsPerUser: UInt64?
		){ 
			self.priceType = priceType
			self.eligibleAddresses = eligibleAddresses
			self.price = price
			self.maxMintsPerUser = maxMintsPerUser ?? 10
		}
	}
	
	access(all)
	struct Order{ 
		access(all)
		let entityID: UInt64
		
		access(all)
		let quantity: UInt64
		
		init(entityID: UInt64, quantity: UInt64){ 
			self.entityID = entityID
			self.quantity = quantity
		}
	}
	
	access(all)
	struct PurchaseData{ 
		access(all)
		let primarySaleID: UInt64
		
		access(all)
		let purchaserAddress: Address
		
		access(all)
		let purchaserCollectionRef: &{NonFungibleToken.Receiver}
		
		access(all)
		let orders: [Order]
		
		access(all)
		let priceType: String
		
		init(
			primarySaleID: UInt64,
			purchaserAddress: Address,
			purchaserCollectionRef: &{NonFungibleToken.Receiver},
			orders: [
				Order
			],
			priceType: String
		){ 
			self.primarySaleID = primarySaleID
			self.purchaserAddress = purchaserAddress
			self.purchaserCollectionRef = purchaserCollectionRef
			self.orders = orders
			self.priceType = priceType
		}
	}
	
	access(all)
	struct PurchaseDataRandom{ 
		access(all)
		let primarySaleID: UInt64
		
		access(all)
		let purchaserAddress: Address
		
		access(all)
		let purchaserCollectionRef: &{NonFungibleToken.Receiver}
		
		access(all)
		let quantity: UInt64
		
		access(all)
		let priceType: String
		
		init(
			primarySaleID: UInt64,
			purchaserAddress: Address,
			purchaserCollectionRef: &{NonFungibleToken.Receiver},
			quantity: UInt64,
			priceType: String
		){ 
			self.primarySaleID = primarySaleID
			self.purchaserAddress = purchaserAddress
			self.purchaserCollectionRef = purchaserCollectionRef
			self.quantity = quantity
			self.priceType = priceType
		}
	}
	
	access(all)
	enum PrimarySaleStatus: UInt8{ 
		access(all)
		case PAUSED
		
		access(all)
		case OPEN
		
		access(all)
		case CLOSED
	}
	
	access(all)
	resource interface PrimarySalePublic{ 
		access(all)
		fun getSupply(pool: String?): UInt64
		
		access(all)
		fun getPrices():{ String: PriceData}
		
		access(all)
		fun getStatus(): String
		
		access(all)
		fun purchaseRandomNFTs(
			payment: @{FungibleToken.Vault},
			data: PurchaseDataRandom,
			adminSignedPayload: AdminSignedPayload,
			signature: String
		)
		
		access(all)
		fun purchaseNFTs(
			payment: @{FungibleToken.Vault},
			data: PurchaseData,
			adminSignedPayload: AdminSignedPayload,
			signature: String
		)
		
		access(all)
		fun claimTreasures(
			primarySaleID: UInt64,
			pool: String?,
			claimerAddress: Address,
			claimerCollectionRef: &{NonFungibleToken.Receiver},
			adminSignedPayload: AdminSignedPayload,
			signature: String
		)
		
		access(all)
		fun getNumMintedByUser(userAddress: Address, priceType: String): UInt64
		
		access(all)
		fun getNumMintedPerUser():{ String:{ Address: UInt64}}
		
		access(all)
		fun getAllAvailableEntities(pool: String?):{ UInt64: UInt64}
		
		access(all)
		fun getAvailableEntities():{ UInt64: UInt64}
		
		access(all)
		fun getPooledEntities():{ String:{ UInt64: UInt64}}
		
		access(all)
		fun getLaunchDate(): String
		
		access(all)
		fun getEndDate(): String
		
		access(all)
		fun getPooled(): Bool
		
		access(all)
		fun getContractName(): String
		
		access(all)
		fun getContractAddress(): Address
		
		access(all)
		fun getID(): UInt64
		
		access(all)
		fun getSetID(): UInt64
	}
	
	access(all)
	resource PrimarySale: PrimarySalePublic{ 
		access(self)
		var primarySaleID: UInt64
		
		access(self)
		var contractName: String
		
		access(self)
		var contractAddress: Address
		
		access(self)
		var setID: UInt64
		
		access(self)
		var status: PrimarySaleStatus
		
		access(self)
		var prices:{ String: PriceData}
		
		access(self)
		var availableEntities:{ UInt64: UInt64}
		
		access(self)
		var pooledEntities:{ String:{ UInt64: UInt64}}
		
		access(self)
		var numMintedPerUser:{ String:{ Address: UInt64}}
		
		access(self)
		var launchDate: String
		
		access(self)
		var endDate: String
		
		access(self)
		var pooled: Bool
		
		access(self)
		let minterCap: Capability<&{IMinter}>
		
		access(self)
		var paymentReceiverCap: Capability<&{FungibleToken.Receiver}>
		
		init(contractName: String, contractAddress: Address, setID: UInt64, prices:{ String: PriceData}, minterCap: Capability<&{IMinter}>, paymentReceiverCap: Capability<&{FungibleToken.Receiver}>, launchDate: String, endDate: String, pooled: Bool){ 
			self.contractName = contractName
			self.contractAddress = contractAddress
			self.setID = setID
			self.status = PrimarySaleStatus.PAUSED // primary sale is paused initially
			
			self.availableEntities ={} 
			self.pooledEntities ={} 
			self.prices = prices
			self.minterCap = minterCap
			self.paymentReceiverCap = paymentReceiverCap
			self.launchDate = launchDate
			self.endDate = endDate
			self.pooled = pooled
			self.primarySaleID = FlowversePrimarySale.nextPrimarySaleID
			let key = contractName.concat(contractAddress.toString().concat(setID.toString()))
			FlowversePrimarySale.primarySaleIDs[key] = self.primarySaleID
			self.numMintedPerUser ={} 
			for priceType in prices.keys{ 
				self.numMintedPerUser.insert(key: priceType,{} )
			}
			emit PrimarySaleCreated(primarySaleID: self.primarySaleID, contractName: contractName, contractAddress: contractAddress, setID: setID, prices: prices, launchDate: launchDate, endDate: endDate, pooled: pooled)
		}
		
		access(all)
		fun getStatus(): String{ 
			if self.status == PrimarySaleStatus.PAUSED{ 
				return "PAUSED"
			} else if self.status == PrimarySaleStatus.OPEN{ 
				return "OPEN"
			} else if self.status == PrimarySaleStatus.CLOSED{ 
				return "CLOSED"
			} else{ 
				return ""
			}
		}
		
		access(all)
		fun setPrice(priceData: PriceData){ 
			self.prices[priceData.priceType] = priceData
			if !self.numMintedPerUser.containsKey(priceData.priceType){ 
				self.numMintedPerUser.insert(key: priceData.priceType,{} )
			}
			emit PriceSet(primarySaleID: self.primarySaleID, type: priceData.priceType, price: priceData.price, eligibleAddresses: priceData.eligibleAddresses, maxMintsPerUser: priceData.maxMintsPerUser)
		}
		
		access(all)
		fun getPrices():{ String: PriceData}{ 
			return self.prices
		}
		
		access(all)
		fun getSupply(pool: String?): UInt64{ 
			var supply = UInt64(0)
			if self.pooled{ 
				for poolKey in self.pooledEntities.keys{ 
					if pool == nil || pool == poolKey{ 
						let pooledDict = self.pooledEntities[poolKey]!
						for entityID in pooledDict.keys{ 
							supply = supply + pooledDict[entityID]!
						}
					}
				}
			} else{ 
				for entityID in self.availableEntities.keys{ 
					supply = supply + self.availableEntities[entityID]!
				}
			}
			return supply
		}
		
		access(all)
		fun getLaunchDate(): String{ 
			return self.launchDate
		}
		
		access(all)
		fun getEndDate(): String{ 
			return self.endDate
		}
		
		access(all)
		fun getPaymentReceiverAddress(): Address?{ 
			let receiver = self.paymentReceiverCap.borrow()!
			if receiver.owner != nil{ 
				return (receiver.owner!).address
			}
			return nil
		}
		
		access(all)
		fun getPooled(): Bool{ 
			return self.pooled
		}
		
		access(all)
		fun getNumMintedPerUser():{ String:{ Address: UInt64}}{ 
			return self.numMintedPerUser
		}
		
		access(all)
		fun getNumMintedByUser(userAddress: Address, priceType: String): UInt64{ 
			assert(self.numMintedPerUser.containsKey(priceType), message: "invalid priceType")
			let numMintedDict = self.numMintedPerUser[priceType]!
			return numMintedDict[userAddress] ?? 0
		}
		
		access(all)
		fun getContractName(): String{ 
			return self.contractName
		}
		
		access(all)
		fun getContractAddress(): Address{ 
			return self.contractAddress
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.primarySaleID
		}
		
		access(all)
		fun getSetID(): UInt64{ 
			return self.setID
		}
		
		access(all)
		fun addEntity(entityID: UInt64, pool: String?, quantity: UInt64){ 
			if self.pooled{ 
				assert(pool != nil, message: "must specify pool")
				let poolStr = pool!
				if !self.pooledEntities.containsKey(poolStr){ 
					self.pooledEntities.insert(key: poolStr,{} )
				}
				(self.pooledEntities[poolStr]!).insert(key: entityID, quantity)
				emit EntityAdded(primarySaleID: self.primarySaleID, entityID: entityID, pool: poolStr, quantity: quantity)
			} else{ 
				self.availableEntities[entityID] = quantity
				emit EntityAdded(primarySaleID: self.primarySaleID, entityID: entityID, pool: nil, quantity: quantity)
			}
		}
		
		access(all)
		fun removeEntity(entityID: UInt64, pool: String?){ 
			if self.pooled{ 
				assert(pool != nil, message: "must specify pool")
				let poolStr = pool!
				if self.pooledEntities.containsKey(poolStr){ 
					let entity = (self.pooledEntities[poolStr]!).remove(key: entityID)
					if entity != nil{ 
						emit EntityRemoved(primarySaleID: self.primarySaleID, entityID: entityID, pool: poolStr)
					}
				}
			} else{ 
				let entity = self.availableEntities.remove(key: entityID)
				if entity != nil{ 
					emit EntityRemoved(primarySaleID: self.primarySaleID, entityID: entityID, pool: nil)
				}
			}
		}
		
		access(all)
		fun addEntities(entityIDs: [UInt64], pool: String?){ 
			for id in entityIDs{ 
				self.addEntity(entityID: id, pool: pool, quantity: 1)
			}
		}
		
		access(all)
		fun pause(){ 
			self.status = PrimarySaleStatus.PAUSED
			emit PrimarySaleStatusChanged(primarySaleID: self.primarySaleID, status: self.getStatus())
		}
		
		access(all)
		fun open(){ 
			pre{ 
				self.status != PrimarySaleStatus.OPEN:
					"Primary sale is already open"
				self.status != PrimarySaleStatus.CLOSED:
					"Cannot re-open primary sale that is closed"
			}
			self.status = PrimarySaleStatus.OPEN
			emit PrimarySaleStatusChanged(primarySaleID: self.primarySaleID, status: self.getStatus())
		}
		
		access(all)
		fun close(){ 
			self.status = PrimarySaleStatus.CLOSED
			emit PrimarySaleStatusChanged(primarySaleID: self.primarySaleID, status: self.getStatus())
		}
		
		access(self)
		view fun verifyAdminSignedPayload(signedPayloadData: AdminSignedPayload, signature: String): Bool{ 
			let keyList = Crypto.KeyList()
			let accountKey = ((self.owner!).keys.get(keyIndex: 0)!).publicKey
			let publicKey = PublicKey(publicKey: accountKey.publicKey, signatureAlgorithm: accountKey.signatureAlgorithm)
			return publicKey.verify(signature: signature.decodeHex(), signedData: signedPayloadData.toString().utf8, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
		}
		
		access(all)
		fun purchaseRandomNFTs(payment: @{FungibleToken.Vault}, data: PurchaseDataRandom, adminSignedPayload: AdminSignedPayload, signature: String){ 
			pre{ 
				self.primarySaleID == data.primarySaleID:
					"primarySaleID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				data.quantity > 0:
					"must purchase at least one NFT"
				self.minterCap.borrow() != nil:
					"cannot borrow minter"
				adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp):
					"expired signature"
				self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature):
					"failed to validate signature for the primary sale purchase"
				self.contractName != "FlowverseTreasures":
					"cannot purchase a Flowverse Treasures NFT"
			}
			var pool: String? = nil
			if self.pooled{ 
				pool = data.priceType
			}
			let supply = self.getSupply(pool: pool)
			assert(data.quantity <= supply, message: "insufficient supply")
			let orders: [Order] = []
			var quantityNeeded = data.quantity
			var availableEntities = self.getAllAvailableEntities(pool: pool)!
			for entityID in availableEntities.keys{ 
				if quantityNeeded > 0{ 
					var quantityToAdd: UInt64 = availableEntities[entityID]!
					if quantityToAdd > quantityNeeded{ 
						quantityToAdd = quantityNeeded
					}
					orders.append(Order(entityID: entityID, quantity: quantityToAdd))
					quantityNeeded = quantityNeeded - quantityToAdd
				} else{ 
					break
				}
			}
			let purchaseData = PurchaseData(primarySaleID: data.primarySaleID, purchaserAddress: data.purchaserAddress, purchaserCollectionRef: data.purchaserCollectionRef, orders: orders, priceType: data.priceType)
			self.purchase(payment: <-payment, data: purchaseData)
		}
		
		access(all)
		fun purchaseNFTs(payment: @{FungibleToken.Vault}, data: PurchaseData, adminSignedPayload: AdminSignedPayload, signature: String){ 
			pre{ 
				self.primarySaleID == data.primarySaleID:
					"primarySaleID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				data.orders.length > 0:
					"must purchase at least one NFT"
				self.minterCap.borrow() != nil:
					"cannot borrow minter"
				adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp):
					"expired signature"
				self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature):
					"failed to validate signature for the primary sale purchase"
				self.contractName != "FlowverseTreasures":
					"cannot purchase a Flowverse Treasures NFT"
			}
			self.purchase(payment: <-payment, data: data)
		}
		
		access(all)
		fun claimTreasures(primarySaleID: UInt64, pool: String?, claimerAddress: Address, claimerCollectionRef: &{NonFungibleToken.Receiver}, adminSignedPayload: AdminSignedPayload, signature: String){ 
			pre{ 
				self.primarySaleID == primarySaleID:
					"primarySaleID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				self.minterCap.borrow() != nil:
					"cannot borrow minter"
				adminSignedPayload.expiration >= UInt64(getCurrentBlock().timestamp):
					"expired signature"
				self.verifyAdminSignedPayload(signedPayloadData: adminSignedPayload, signature: signature):
					"failed to validate signature for the primary sale purchase"
				self.contractName == "FlowverseTreasures":
					"primary sale must be for a Flowverse Treasure"
			}
			// Get available entity IDs
			let availableEntityIDs = (self.getAllAvailableEntities(pool: pool)!).keys
			assert(availableEntityIDs.length > 0, message: "No available entities")
			
			// Check if claimer is eligible for treasure based on whether they own a Flowverse Pass
			let mysteryPassCollectionRef = getAccount(claimerAddress).capabilities.get<&{FlowversePass.CollectionPublic}>(FlowversePass.CollectionPublicPath).borrow<&{FlowversePass.CollectionPublic}>() ?? panic("FlowversePass Collection reference not found")
			var passIDs = mysteryPassCollectionRef.getIDs()
			let numPassesOwned = passIDs.length
			assert(numPassesOwned > 0, message: "ineligible for treasure claim as user does not own a Flowverse Pass")
			
			// If pool is sockholder, check if claimer owns a Flowverse Sock
			var sockIDs: [UInt64] = []
			var numSocksOwned = 0
			if pool == "sockholders"{ 
				let socksCollectionRef = getAccount(claimerAddress).capabilities.get<&{FlowverseSocks.FlowverseSocksCollectionPublic}>(FlowverseSocks.CollectionPublicPath).borrow<&{FlowverseSocks.FlowverseSocksCollectionPublic}>() ?? panic("FlowverseSocks Collection reference not found")
				sockIDs = socksCollectionRef.getIDs()
				numSocksOwned = sockIDs.length
				passIDs = []
				assert(numSocksOwned > 0, message: "ineligible for treasure claim in sockholder pool as user does not own a Flowverse Sock")
			}
			let priceType = pool ?? "public"
			
			// Gets the number of treasure NFTs minted by this user in the current pool
			let numMintedByUser = self.getNumMintedByUser(userAddress: claimerAddress, priceType: priceType)
			
			// Checks if the user has already claimed all their treasure NFTs
			var quantity = UInt64(numPassesOwned) - numMintedByUser
			if pool == "sockholders"{ 
				quantity = UInt64(numSocksOwned) - numMintedByUser
			}
			assert(quantity > 0, message: "User has already claimed all their treasure NFTs")
			let minter = self.minterCap.borrow()!
			var n: UInt64 = 0
			let claimedNFTIDs: [UInt64] = []
			while n < quantity{ 
				let randomIndex = revertibleRandom<UInt64>() % UInt64(availableEntityIDs.length)
				let entityID = availableEntityIDs[randomIndex]
				let nft <- minter.mint(entityID: entityID, minterAddress: claimerAddress)
				claimedNFTIDs.append(nft.id)
				claimerCollectionRef.deposit(token: <-nft)
				n = n + 1
			}
			emit ClaimedTreasures(primarySaleID: primarySaleID, nftIDs: claimedNFTIDs, passIDs: passIDs, sockIDs: sockIDs, claimerAddress: claimerAddress, pool: priceType)
			(			 // Increments the number of NFTs minted by the user
			 self.numMintedPerUser[priceType]!).insert(key: claimerAddress, numMintedByUser + quantity)
		}
		
		access(self)
		fun purchase(payment: @{FungibleToken.Vault}, data: PurchaseData){ 
			pre{ 
				self.primarySaleID == data.primarySaleID:
					"primarySaleID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				data.orders.length > 0:
					"must purchase at least one NFT"
				self.minterCap.borrow() != nil:
					"cannot borrow minter"
			}
			let priceData = self.prices[data.priceType] ?? panic("Invalid price type")
			if priceData.eligibleAddresses != nil{ 
				// check if purchaser is in eligible address list
				if !(priceData.eligibleAddresses!).contains(data.purchaserAddress){ 
					panic("Address is ineligible for purchase")
				}
			}
			if self.pooled{ 
				assert(self.pooledEntities.containsKey(data.priceType), message: "Pool does not exist for price type")
			}
			
			// Gets the number of NFTs minted by this user
			let numMintedByUser = self.getNumMintedByUser(userAddress: data.purchaserAddress, priceType: data.priceType)
			
			// check if purchaser does not exceed maxMintsPerUser limit
			var totalQuantity: UInt64 = 0
			for order in data.orders{ 
				totalQuantity = totalQuantity + order.quantity
			}
			assert(totalQuantity + UInt64(numMintedByUser) <= priceData.maxMintsPerUser, message: "maximum number of mints exceeded")
			assert(payment.balance == priceData.price * UFix64(totalQuantity), message: "payment vault does not contain requested price")
			var receiver = self.paymentReceiverCap.borrow()!
			
			// check if payment is in FUT (FlowUtilityCoin used by Dapper)
			if payment.isInstance(Type<@FlowUtilityToken.Vault>()){ 
				let dapperFUTCapability = getAccount(0xe24e5bbd46e38be1).capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!
				receiver = dapperFUTCapability.borrow()!
			}
			receiver.deposit(from: <-payment)
			let minter = self.minterCap.borrow()!
			var i: Int = 0
			while i < data.orders.length{ 
				let entityID = data.orders[i].entityID
				let quantity = data.orders[i].quantity
				if self.pooled{ 
					let pooledDict = self.pooledEntities[data.priceType]!
					assert(pooledDict.containsKey(entityID) && pooledDict[entityID]! >= quantity, message: "NFT is not available for purchase: ".concat(entityID.toString()))
					if pooledDict[entityID]! > quantity{ 
						(self.pooledEntities[data.priceType]!).insert(key: entityID, pooledDict[entityID]! - quantity)
					} else{ 
						(self.pooledEntities[data.priceType]!).remove(key: entityID)
					}
				} else{ 
					assert(self.availableEntities.containsKey(entityID) && self.availableEntities[entityID]! >= quantity, message: "NFT is not available for purchase: ".concat(entityID.toString()))
					if self.availableEntities[entityID]! > quantity{ 
						self.availableEntities[entityID] = self.availableEntities[entityID]! - quantity
					} else{ 
						self.availableEntities.remove(key: entityID)
					}
				}
				var n: UInt64 = 0
				let purchasedNFTIds: [UInt64] = []
				while n < quantity{ 
					let nft <- minter.mint(entityID: entityID, minterAddress: data.purchaserAddress)
					purchasedNFTIds.append(nft.id)
					data.purchaserCollectionRef.deposit(token: <-nft)
					n = n + 1
				}
				i = i + 1
				emit PurchasedOrder(primarySaleID: self.primarySaleID, entityID: entityID, quantity: quantity, nftIDs: purchasedNFTIds, purchaserAddress: data.purchaserAddress, priceType: data.priceType, price: priceData.price)
			}
			(			 // Increments the number of NFTs minted by the user
			 self.numMintedPerUser[data.priceType]!).insert(key: data.purchaserAddress, numMintedByUser + totalQuantity)
		}
		
		access(all)
		fun getAllAvailableEntities(pool: String?):{ UInt64: UInt64}{ 
			var availableEntities:{ UInt64: UInt64} ={} 
			if pool != nil{ 
				assert(self.pooledEntities.containsKey(pool!), message: "Pool does not exist")
				let pooledDict = self.pooledEntities[pool!]!
				for entityID in pooledDict.keys{ 
					availableEntities[entityID] = pooledDict[entityID]!
				}
			} else{ 
				for entityID in self.availableEntities.keys{ 
					availableEntities[entityID] = self.availableEntities[entityID]!
				}
			}
			return availableEntities
		}
		
		access(all)
		fun getAvailableEntities():{ UInt64: UInt64}{ 
			return self.availableEntities
		}
		
		access(all)
		fun getPooledEntities():{ String:{ UInt64: UInt64}}{ 
			return self.pooledEntities
		}
		
		access(all)
		fun updateLaunchDate(date: String){ 
			self.launchDate = date
			emit PrimarySaleDateUpdated(primarySaleID: self.primarySaleID, date: date, isLaunch: true)
		}
		
		access(all)
		fun updateEndDate(date: String){ 
			self.endDate = date
			emit PrimarySaleDateUpdated(primarySaleID: self.primarySaleID, date: date, isLaunch: false)
		}
		
		access(all)
		fun updatePaymentReceiver(paymentReceiverCap: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				paymentReceiverCap.borrow() != nil:
					"Could not borrow payment receiver capability"
			}
			self.paymentReceiverCap = paymentReceiverCap
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to create primary sales
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createPrimarySale(
			contractName: String,
			contractAddress: Address,
			setID: UInt64,
			prices:{ 
				String: PriceData
			},
			minterCap: Capability<&{IMinter}>,
			paymentReceiverCap: Capability<&{FungibleToken.Receiver}>,
			launchDate: String,
			endDate: String,
			pooled: Bool
		){ 
			pre{ 
				minterCap.borrow() != nil:
					"Could not borrow minter capability"
				paymentReceiverCap.borrow() != nil:
					"Could not borrow payment receiver capability"
			}
			let key = contractName.concat(contractAddress.toString().concat(setID.toString()))
			assert(
				!FlowversePrimarySale.primarySaleIDs.containsKey(key),
				message: "Primary sale with contractName, contractAddress, setID already exists"
			)
			var primarySale <-
				create PrimarySale(
					contractName: contractName,
					contractAddress: contractAddress,
					setID: setID,
					prices: prices,
					minterCap: minterCap,
					paymentReceiverCap: paymentReceiverCap,
					launchDate: launchDate,
					endDate: endDate,
					pooled: pooled
				)
			let primarySaleID = FlowversePrimarySale.nextPrimarySaleID
			FlowversePrimarySale.nextPrimarySaleID = FlowversePrimarySale.nextPrimarySaleID
				+ UInt64(1)
			FlowversePrimarySale.primarySales[primarySaleID] <-! primarySale
		}
		
		access(all)
		fun getPrimarySale(primarySaleID: UInt64): &PrimarySale?{ 
			if FlowversePrimarySale.primarySales.containsKey(primarySaleID){ 
				return (&FlowversePrimarySale.primarySales[primarySaleID] as &PrimarySale?)!
			}
			return nil
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	struct PrimarySaleData{ 
		access(all)
		let primarySaleID: UInt64
		
		access(all)
		let contractName: String
		
		access(all)
		let contractAddress: Address
		
		access(all)
		let setID: UInt64
		
		access(all)
		let supply: UInt64
		
		access(all)
		let prices:{ String: FlowversePrimarySale.PriceData}
		
		access(all)
		let status: String
		
		access(all)
		let availableEntities:{ UInt64: UInt64}
		
		access(all)
		let pooledEntities:{ String:{ UInt64: UInt64}}
		
		access(all)
		let launchDate: String
		
		access(all)
		let endDate: String
		
		access(all)
		let pooled: Bool
		
		access(all)
		let numMintedPerUser:{ String:{ Address: UInt64}}
		
		init(
			primarySaleID: UInt64,
			contractName: String,
			contractAddress: Address,
			setID: UInt64,
			supply: UInt64,
			prices:{ 
				String: FlowversePrimarySale.PriceData
			},
			status: String,
			availableEntities:{ 
				UInt64: UInt64
			},
			pooledEntities:{ 
				String:{ 
					UInt64: UInt64
				}
			},
			launchDate: String,
			endDate: String,
			pooled: Bool,
			numMintedPerUser:{ 
				String:{ 
					Address: UInt64
				}
			}
		){ 
			self.primarySaleID = primarySaleID
			self.contractName = contractName
			self.contractAddress = contractAddress
			self.setID = setID
			self.supply = supply
			self.prices = prices
			self.status = status
			self.availableEntities = availableEntities
			self.pooledEntities = pooledEntities
			self.launchDate = launchDate
			self.endDate = endDate
			self.pooled = pooled
			self.numMintedPerUser = numMintedPerUser
		}
	}
	
	access(all)
	fun getPrimarySaleData(primarySaleID: UInt64): PrimarySaleData{ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[primarySaleID] as &PrimarySale?)!
		return PrimarySaleData(
			primarySaleID: primarySale.getID(),
			contractName: primarySale.getContractName(),
			contractAddress: primarySale.getContractAddress(),
			setID: primarySale.getSetID(),
			supply: primarySale.getSupply(pool: nil),
			prices: primarySale.getPrices(),
			status: primarySale.getStatus(),
			availableEntities: primarySale.getAvailableEntities(),
			pooledEntities: primarySale.getPooledEntities(),
			launchDate: primarySale.getLaunchDate(),
			endDate: primarySale.getEndDate(),
			pooled: primarySale.getPooled(),
			numMintedPerUser: primarySale.getNumMintedPerUser()
		)
	}
	
	access(all)
	fun getPaymentReceiverAddress(primarySaleID: UInt64): Address?{ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[primarySaleID] as &PrimarySale?)!
		return primarySale.getPaymentReceiverAddress()
	}
	
	access(all)
	fun getPrice(primarySaleID: UInt64, type: String): UFix64{ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[primarySaleID] as &PrimarySale?)!
		let prices = primarySale.getPrices()
		assert(prices.containsKey(type), message: "price type does not exist")
		return (prices[type]!).price
	}
	
	access(all)
	fun purchaseRandomNFTs(
		payment: @{FungibleToken.Vault},
		data: PurchaseDataRandom,
		adminSignedPayload: AdminSignedPayload,
		signature: String
	){ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(data.primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[data.primarySaleID] as &PrimarySale?)!
		primarySale.purchaseRandomNFTs(
			payment: <-payment,
			data: data,
			adminSignedPayload: adminSignedPayload,
			signature: signature
		)
	}
	
	access(all)
	fun purchaseNFTs(
		payment: @{FungibleToken.Vault},
		data: PurchaseData,
		adminSignedPayload: AdminSignedPayload,
		signature: String
	){ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(data.primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[data.primarySaleID] as &PrimarySale?)!
		primarySale.purchaseNFTs(
			payment: <-payment,
			data: data,
			adminSignedPayload: adminSignedPayload,
			signature: signature
		)
	}
	
	access(all)
	fun claimTreasures(
		primarySaleID: UInt64,
		pool: String?,
		claimerAddress: Address,
		claimerCollectionRef: &{NonFungibleToken.Receiver},
		adminSignedPayload: AdminSignedPayload,
		signature: String
	){ 
		pre{ 
			FlowversePrimarySale.primarySales.containsKey(primarySaleID):
				"Primary sale does not exist"
		}
		let primarySale = (&FlowversePrimarySale.primarySales[primarySaleID] as &PrimarySale?)!
		primarySale.claimTreasures(
			primarySaleID: primarySaleID,
			pool: pool,
			claimerAddress: claimerAddress,
			claimerCollectionRef: claimerCollectionRef,
			adminSignedPayload: adminSignedPayload,
			signature: signature
		)
	}
	
	access(all)
	fun getID(contractName: String, contractAddress: Address, setID: UInt64): UInt64{ 
		let key = contractName.concat(contractAddress.toString().concat(setID.toString()))
		assert(
			FlowversePrimarySale.primarySaleIDs.containsKey(key),
			message: "primary sale does not exist"
		)
		return FlowversePrimarySale.primarySaleIDs[key]!
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlowversePrimarySaleAdminStoragePath
		self.primarySales <-{} 
		self.primarySaleIDs ={} 
		self.nextPrimarySaleID = 1
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
