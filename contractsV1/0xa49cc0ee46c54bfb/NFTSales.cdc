import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import REVV from "../0xd01e482eb680ec9f/REVV.cdc"

import SHRD from "../0xd01e482eb680ec9f/SHRD.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

import MotoGPCard from "./MotoGPCard.cdc"

import CardMintAccess from "./CardMintAccess.cdc"

import ContractVersion from "./ContractVersion.cdc"

import SHRDMintAccess from "../0xd01e482eb680ec9f/SHRDMintAccess.cdc"

import MotoGPCardMetadata from "./MotoGPCardMetadata.cdc"

import MotoGPCardSerialPoolV2 from "./MotoGPCardSerialPoolV2.cdc"

access(all)
contract NFTSales: ContractVersion{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.5"
	}
	
	access(all)
	event OrderIdRegistered(orderId: String)
	
	access(all)
	event PackOpened(cardIDs: [UInt64], serials: [UInt64], shrdAmount: UFix64)
	
	access(all)
	resource OpenedPack{ 
		access(all)
		var collection: @MotoGPCard.Collection
		
		access(all)
		var vault: @SHRD.Vault
		
		init(collection_: @MotoGPCard.Collection, vault_: @SHRD.Vault){ 
			self.collection <- collection_
			self.vault <- vault_
		}
	}
	
	access(all)
	enum SalesOpenOverride: UInt8{ 
		access(all)
		case NoOverride
		
		access(all)
		case ForceOpen
		
		access(all)
		case ForceClose
	}
	
	access(all)
	resource Sales{ 
		access(all)
		let id: UInt64
		
		access(all)
		var salesOpenOverride: UInt8 // Used to override the blocktime-based open status, for emergency situations, e.g. block start time doesn't sync with IRL time
		
		
		access(all)
		var maxSHRD: UFix64 //The maximum allowed amount of SHRD which can be minted by this Sales
		
		
		access(all)
		var mintedSHRD: UFix64 //Keeps count of how much SHRD has been minted
		
		
		access(self)
		var shrdPerGrade:{ String: UFix64} // grade (rarity, e.g. Legendary) => amount of SHRD
		
		
		access(all)
		var cardsPerPack: UInt64 //how many cards will be minted when a pack is opened
		
		
		access(all)
		let nonces:{ Address: UInt64} //how many packs have been opened for an account
		
		
		access(all)
		var price: UFix64 // for use when paying with Vault
		
		
		access(all)
		var publicKey: String // used to verify the signature during an open pack call
		
		
		access(all)
		var signatureAlgorithm: UInt8 // SignatureAlorithm type is not storable 
		
		
		access(all)
		var startTime: UFix64 // start time in unix time stamp seconds (not milliseconds), to be compared to block time. Note: block timestamps are UFix64.
		
		
		access(all)
		var endTime: UFix64 // end time in unix time stamp seconds (not milliseconds), to be compared to block time. Note: block timestamps are UFix64.
		
		
		access(all)
		var maxPerWallet: UInt64 // max number of cards a buyer can mint
		
		
		access(all)
		var cardCountByWallet:{ Address: UInt64} // keeps track of how many cards a buyer has minted
		
		
		access(all)
		var cardCount: UInt64 // the number of cards minted from this Sales resource
		
		
		access(self)
		var cardTypeWeights: [[UInt32]] // A list of bucket card probability weights. Each inner array holds the weights for one bucket
		
		
		access(self)
		var cardTypes: [[UInt64]] // A list of bucket card types. Each inner array holds the types for one bucket. Needs to be ordered to match cardTypeWeights's order
		
		
		init(maxSHRD: UFix64, shrdPerGrade:{ String: UFix64}, cardsPerPack: UInt64, price: UFix64, startTime: UFix64, endTime: UFix64, maxPerWallet: UInt64, cardTypeWeights: [[UInt32]], // If empty, should be [], not [[],[],[]]																																														  
																																														  cardTypes: [[UInt64]]){ // If empty, should be [], not [[],[],[]] 
			
			pre{ 
				NFTSales.isEqual2DArrayLengths(cardTypeWeights, cardTypes):
					"inconsistent initial card type weight array lengths"
			}
			self.id = self.uuid
			self.salesOpenOverride = SalesOpenOverride.NoOverride.rawValue
			self.maxSHRD = maxSHRD
			self.mintedSHRD = 0.0
			self.shrdPerGrade = shrdPerGrade
			self.cardsPerPack = cardsPerPack
			self.nonces ={} 
			self.price = price
			self.publicKey = ""
			self.signatureAlgorithm = SignatureAlgorithm.ECDSA_P256.rawValue // To convert back to enum, use: SignatureAlgorithm(rawValue: self.signatureAlgorithm)
			
			self.startTime = startTime
			self.endTime = endTime
			self.maxPerWallet = maxPerWallet
			self.cardCountByWallet ={} 
			self.cardCount = 0
			self.cardTypeWeights = cardTypeWeights
			self.cardTypes = cardTypes
		}
		
		access(contract)
		fun addCardTypeWeights(cardTypeWeights: [UInt32], cardTypes: [UInt64]){ 
			pre{ 
				cardTypeWeights.length == cardTypes.length:
					"inconsistent card type weight array lengths"
			}
			self.cardTypeWeights.append(cardTypeWeights)
			self.cardTypes.append(cardTypes)
		}
		
		access(contract)
		fun removeCardTypeWeights(at index: UInt64){ 
			self.cardTypeWeights.remove(at: index)
			self.cardTypes.remove(at: index)
		}
		
		access(contract)
		fun clearCardTypeWeights(){ 
			self.cardTypeWeights = []
			self.cardTypes = []
		}
		
		access(contract)
		fun setSalesOpenOverride(state: SalesOpenOverride){ 
			self.salesOpenOverride = state.rawValue
		}
		
		access(contract)
		fun setMaxSHRD(maxSHRD: UFix64){ 
			self.maxSHRD = maxSHRD
		}
		
		access(contract)
		fun setStartTime(startTime: UFix64){ 
			self.startTime = startTime
		}
		
		access(contract)
		fun setEndTime(endTime: UFix64){ 
			self.endTime = endTime
		}
		
		access(contract)
		fun setPublicKey(publicKey: String, signatureAlgorithm: SignatureAlgorithm){ 
			self.publicKey = publicKey
			self.signatureAlgorithm = signatureAlgorithm.rawValue
		}
		
		access(contract)
		fun setMaxPerWallet(maxPerWallet: UInt64){ 
			self.maxPerWallet = maxPerWallet
		}
		
		access(contract)
		fun setCardsPerPack(cardsPerPack: UInt64){ 
			self.cardsPerPack = cardsPerPack
		}
		
		access(contract)
		fun setSHRDPerGrade(shrdPerGrade:{ String: UFix64}){ 
			self.shrdPerGrade = shrdPerGrade
		}
		
		access(contract)
		fun setPrice(price: UFix64){ 
			self.price = price
		}
		
		access(all)
		fun getSHRDPerGrade():{ String: UFix64}{ 
			return self.shrdPerGrade
		}
		
		access(all)
		view fun isOpen(): Bool{ 
			if self.salesOpenOverride == SalesOpenOverride.ForceOpen.rawValue{ 
				return true
			}
			if self.salesOpenOverride == SalesOpenOverride.ForceClose.rawValue{ 
				return false
			}
			let ts = getCurrentBlock().timestamp
			return self.startTime <= ts && self.endTime >= ts
		}
		
		access(all)
		fun openPacksWithCreditCardPayment(signature: String, orderId: String, address: Address, quantity: UInt64, hashAlgorithm: HashAlgorithm): @OpenedPack{ 
			pre{ 
				NFTSales.orderIds[orderId] == nil:
					"orderId already used"
			}
			NFTSales.orderIds[orderId] = getCurrentBlock().height
			let message = address.toString().concat(orderId).concat(self.uuid.toString()).concat(quantity.toString())
			let isValid = NFTSales.isValidSignature(publicKey: self.publicKey, signatureAlgorithm: SignatureAlgorithm(rawValue: self.signatureAlgorithm)!, hashAlgorithm: hashAlgorithm, signature: signature, message: message)
			if isValid == false{ 
				panic("Signature isn't valid")
			}
			emit OrderIdRegistered(orderId: orderId)
			let res <- self.openPack(signature: signature, address: address, quantity: quantity, message: message)
			return <-res
		}
		
		access(all)
		fun openPacksWithVaultPayment(signature: String, revvVault: @REVV.Vault, address: Address, quantity: UInt64, hashAlgorithm: HashAlgorithm): @OpenedPack{ 
			pre{ 
				self.isOpen():
					"Sales is not open"
				revvVault.balance == self.price * UFix64(quantity):
					"revvVault balance doesn't match price * quantity"
			}
			((NFTSales.paymentReceiverCap!).borrow()!).deposit(from: <-revvVault)
			if self.nonces[address] == nil{ 
				self.nonces[address] = UInt64(1)
			} else{ 
				self.nonces[address] = self.nonces[address]! + UInt64(1)
			}
			let message = (self.nonces[address]!).toString().concat(address.toString()).concat(self.uuid.toString())
			let isValid = NFTSales.isValidSignature(publicKey: self.publicKey, signatureAlgorithm: SignatureAlgorithm(rawValue: self.signatureAlgorithm)!, hashAlgorithm: hashAlgorithm, signature: signature, message: message)
			if isValid == false{ 
				panic("Signature isn't valid")
			}
			let res <- self.openPack(signature: signature, address: address, quantity: quantity, message: message)
			return <-res
		}
		
		access(contract)
		fun openPack( // TODO: change to access(self)					 
					 signature: String, address: Address, quantity: UInt64, message: String): @OpenedPack{ 
			
			// Mint cards
			let cardIDsAndSerials = self.generateCardIDsAndSerials(signature: signature, quantity: quantity)
			let cardIDs = cardIDsAndSerials[0]
			let serials = cardIDsAndSerials[1]
			let collection: @MotoGPCard.Collection <- NFTSales.mintCards(cardIDs: cardIDs, serials: serials)
			
			// Mint shrd
			var shrdAmount = self.calculateSHRDAmount(cardIDs: cardIDs)
			let vault <- SHRD.createEmptyVault(vaultType: Type<@SHRD.Vault>()) as! @SHRD.Vault
			if shrdAmount > 0.0{ 
				vault.deposit(from: <-NFTSales.mintSHRD(amount: shrdAmount))
			}
			
			// Check and update minted card counts
			self.cardCount = self.cardCount + UInt64(cardIDs.length)
			if self.cardCountByWallet[address] == nil{ 
				self.cardCountByWallet[address] = 0
			}
			let newCountForWallet = self.cardCountByWallet[address]! + UInt64(cardIDs.length)
			if newCountForWallet > self.maxPerWallet{ 
				panic("max cards exceeded for this wallet")
			}
			self.cardCountByWallet[address] = newCountForWallet
			emit PackOpened(cardIDs: cardIDs, serials: serials, shrdAmount: shrdAmount)
			return <-create OpenedPack(collection_: <-collection, vault_: <-vault)
		}
		
		access(all)
		fun getNonce(address: Address): UInt64{ 
			return self.nonces[address] ?? 0 as UInt64
		}
		
		access(contract)
		fun digestToUInt64(digest: [UInt8]): UInt64{ 
			return (UInt64(digest[0]) << UInt64(56)) + (UInt64(digest[1]) << UInt64(48)) + (UInt64(digest[2]) << UInt64(40)) + (UInt64(digest[3]) << UInt64(32)) + (UInt64(digest[4]) << UInt64(24)) + (UInt64(digest[5]) << UInt64(16)) + (UInt64(digest[6]) << UInt64(8)) + UInt64(digest[7])
		}
		
		access(contract)
		fun generateCardIDsAndSerials(signature: String, quantity: UInt64): [[UInt64]; 2]{ 
			let res: [[UInt64]; 2] = [[], []]
			var index: UInt64 = 0
			var digest: [UInt8] = signature.decodeHex()
			let numCards = self.cardsPerPack * quantity
			let numBuckets = UInt64(self.cardTypeWeights.length)
			while index < numCards{ 
				let bucketIndex = index % numBuckets
				digest = index == 0 ? digest : HashAlgorithm.KECCAK_256.hash(digest)
				var n = self.digestToUInt64(digest: digest)
				let cardID = self.generateSingleCardIDFromDigest(n: n, bucketIndex: bucketIndex)
				res[0].append(cardID)
				digest = HashAlgorithm.KECCAK_256.hash(digest)
				n = self.digestToUInt64(digest: digest)
				res[1].append(MotoGPCardSerialPoolV2.pickSerial(n: n, cardID: cardID))
				index = index + 1
			}
			return res
		}
		
		access(contract)
		fun generateSingleCardIDFromDigest(n: UInt64, bucketIndex: UInt64): UInt64{ 
			let cardTypeWeights = self.cardTypeWeights[bucketIndex]
			let totalWeight = cardTypeWeights[cardTypeWeights.length - 1]
			let r = n % UInt64(totalWeight)
			for i, weight in cardTypeWeights{ 
				if r <= UInt64(weight){ 
					return self.cardTypes[bucketIndex][i]
				}
			}
			panic("no cardType matched to weight: ".concat(r.toString().concat(" with totalWeight: ").concat(totalWeight.toString())))
		}
		
		access(contract)
		fun calculateSHRDAmount(cardIDs: [UInt64]): UFix64{ 
			if self.mintedSHRD >= self.maxSHRD{ 
				return 0.0
			}
			var res = 0.0
			for cardID in cardIDs{ 
				let metadata = MotoGPCardMetadata.getMetadataForCardID(cardID: cardID) ?? panic("cardID ".concat(cardID.toString()).concat(" has no matching metadata"))
				let grade = metadata.data["grade"] ?? panic("cardID ".concat(cardID.toString()).concat(" metadata has no grade"))
				let shrdAmount = self.shrdPerGrade[grade] ?? 0.0
				res = res + shrdAmount
			}
			if res + self.mintedSHRD > self.maxSHRD{ 
				res = self.maxSHRD - self.mintedSHRD
			}
			self.mintedSHRD = self.mintedSHRD + res
			return res
		}
	}
	
	access(all)
	resource interface SalesCollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowSales(salesID: UInt64): &Sales
		
		access(all)
		fun getCardCount(salesID: UInt64): UInt64
	}
	
	access(all)
	resource SalesCollection: SalesCollectionPublic{ 
		access(all)
		var salesMap: @{UInt64: Sales}
		
		access(all)
		fun addSales(sales: @Sales){ 
			pre{ 
				NFTSales.isPaymentReceiverCapSet() == true:
					"payment receiver is not set"
			}
			let salesID = sales.id
			let oldItem <- self.salesMap[salesID] <- sales
			// TODO: Add event
			destroy oldItem
		}
		
		access(all)
		fun removeSales(salesID: UInt64): @Sales{ 
			let sales <- self.salesMap.remove(key: salesID) ?? panic("missing Sales")
			// TODO: Add event
			return <-sales
		}
		
		access(all)
		fun setSalesOpenOverride(salesID: UInt64, state: NFTSales.SalesOpenOverride){ 
			self.borrowSales(salesID: salesID).setSalesOpenOverride(state: state)
		}
		
		access(all)
		fun setMaxSHRD(salesID: UInt64, maxSHRD: UFix64){ 
			self.borrowSales(salesID: salesID).setMaxSHRD(maxSHRD: maxSHRD)
		}
		
		access(all)
		fun setPublicKey(salesID: UInt64, publicKey: String, signatureAlgorithm: SignatureAlgorithm){ 
			self.borrowSales(salesID: salesID).setPublicKey(publicKey: publicKey, signatureAlgorithm: signatureAlgorithm)
		}
		
		access(all)
		fun setMaxPerWallet(salesID: UInt64, maxPerWallet: UInt64){ 
			self.borrowSales(salesID: salesID).setMaxPerWallet(maxPerWallet: maxPerWallet)
		}
		
		access(all)
		fun setCardPerPack(salesID: UInt64, cardsPerPack: UInt64){ 
			self.borrowSales(salesID: salesID).setCardsPerPack(cardsPerPack: cardsPerPack)
		}
		
		access(all)
		fun setStartTime(salesID: UInt64, startTime: UFix64){ 
			self.borrowSales(salesID: salesID).setStartTime(startTime: startTime)
		}
		
		access(all)
		fun setEndTime(salesID: UInt64, endTime: UFix64){ 
			self.borrowSales(salesID: salesID).setEndTime(endTime: endTime)
		}
		
		access(all)
		fun addCardTypeWeights(salesID: UInt64, cardTypeWeights: [UInt32], cardTypes: [UInt64]){ 
			self.borrowSales(salesID: salesID).addCardTypeWeights(cardTypeWeights: cardTypeWeights, cardTypes: cardTypes)
		}
		
		access(all)
		fun setSHRDPerGrade(salesID: UInt64, shrdPerGrade:{ String: UFix64}){ 
			self.borrowSales(salesID: salesID).setSHRDPerGrade(shrdPerGrade: shrdPerGrade)
		}
		
		access(all)
		fun setPrice(salesID: UInt64, price: UFix64){ 
			self.borrowSales(salesID: salesID).setPrice(price: price)
		}
		
		access(all)
		fun removeCardTypeWeights(salesID: UInt64, at index: UInt64){ 
			self.borrowSales(salesID: salesID).removeCardTypeWeights(at: index)
		}
		
		access(all)
		fun clearCardTypeWeights(salesID: UInt64){ 
			self.borrowSales(salesID: salesID).clearCardTypeWeights()
		}
		
		access(all)
		fun getCardCount(salesID: UInt64): UInt64{ 
			return self.borrowSales(salesID: salesID).cardCount
		}
		
		access(all)
		fun getNonceForSales(salesID: UInt64, address: Address): UInt64{ 
			return self.borrowSales(salesID: salesID).getNonce(address: address)
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.salesMap.keys
		}
		
		access(all)
		fun borrowSales(salesID: UInt64): &Sales{ 
			return (&self.salesMap[salesID] as &Sales?)!
		}
		
		init(){ 
			self.salesMap <-{} 
		}
	}
	
	access(all)
	let SalesCollectionStoragePath: StoragePath
	
	access(all)
	let SalesCollectionPublicPath: PublicPath
	
	access(all)
	let SalesCollectionPrivatePath: PrivatePath
	
	access(all)
	let orderIds:{ String: UInt64}
	
	access(all)
	let VaultPurchaseType: UInt8
	
	access(all)
	let ExternalPaymentPurchaseType: UInt8
	
	access(contract)
	var shrdMintProxyCap: Capability<&SHRDMintAccess.MintProxy>?
	
	access(contract)
	var cardMintProxyCap: Capability<&CardMintAccess.MintProxy>?
	
	access(contract)
	var paymentReceiverCap: Capability<&{FungibleToken.Receiver}>?
	
	access(all)
	fun isSHRDMintProxyCapSet(): Bool{ 
		return self.shrdMintProxyCap != nil
	}
	
	access(all)
	fun isCardMintProxyCapSet(): Bool{ 
		return self.cardMintProxyCap != nil
	}
	
	access(all)
	view fun isPaymentReceiverCapSet(): Bool{ 
		return self.paymentReceiverCap != nil
	}
	
	access(all)
	fun isOrderIdUsed(orderId: String): Bool{ 
		return NFTSales.orderIds[orderId] != nil
	}
	
	access(all)
	fun getBlockHeightForOrderId(orderId: String): UInt64?{ 
		return NFTSales.orderIds[orderId]
	}
	
	access(all)
	fun createSales(adminRef: &MotoGPAdmin.Admin, maxSHRD: UFix64, shrdPerGrade:{ String: UFix64}, cardsPerPack: UInt64, price: UFix64, startTime: UFix64, endTime: UFix64, maxPerWallet: UInt64, cardTypeWeights: [[UInt32]], cardTypes: [[UInt64]]): @Sales{ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		return <-create Sales(maxSHRD: maxSHRD, shrdPerGrade: shrdPerGrade, cardsPerPack: cardsPerPack, price: price, startTime: startTime, endTime: endTime, maxPerWallet: maxPerWallet, cardTypeWeights: cardTypeWeights, cardTypes: cardTypes)
	}
	
	access(all)
	fun createSalesCollection(adminRef: &MotoGPAdmin.Admin): @SalesCollection{ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		return <-create SalesCollection()
	}
	
	access(all)
	fun setCardMintProxyCapability(adminRef: &MotoGPAdmin.Admin, capability: Capability<&CardMintAccess.MintProxy>){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
			capability.check() == true:
				"capability.check() is false"
			(capability!).borrow() != nil:
				"can't borrow capability"
		}
		self.cardMintProxyCap = capability
	}
	
	access(all)
	fun setSHRDMintProxyCapability(adminRef: &MotoGPAdmin.Admin, capability: Capability<&SHRDMintAccess.MintProxy>){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
			capability.check() == true:
				"capability.check() is false"
			(capability!).borrow() != nil:
				"can't borrow capability"
		}
		self.shrdMintProxyCap = capability
	}
	
	access(all)
	fun setPaymentReceiverCapability(adminRef: &MotoGPAdmin.Admin, capability: Capability<&{FungibleToken.Receiver}>){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		self.paymentReceiverCap = capability
	}
	
	access(contract)
	view fun isEqual2DArrayLengths(_ array1: [[AnyStruct]], _ array2: [[AnyStruct]]): Bool{ 
		if array1.length != array2.length{ 
			return false
		}
		for i, innerArray1 in array1{ 
			if innerArray1.length != array2[i].length{ 
				return false
			}
		}
		return true
	}
	
	access(contract)
	fun isValidSignature(publicKey: String, signatureAlgorithm: SignatureAlgorithm, hashAlgorithm: HashAlgorithm, signature: String, message: String): Bool{ 
		let pk = PublicKey(publicKey: publicKey.decodeHex(), signatureAlgorithm: signatureAlgorithm)
		let isValid = pk.verify(signature: signature.decodeHex(), signedData: message.utf8, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: hashAlgorithm)
		return isValid
	}
	
	access(contract)
	fun mintSHRD(amount: UFix64): @SHRD.Vault{ 
		return <-((self.shrdMintProxyCap!).borrow()!).mint(amount: amount)
	}
	
	access(contract)
	fun mintCards(cardIDs: [UInt64], serials: [UInt64]): @MotoGPCard.Collection{ 
		pre{ 
			cardIDs.length == serials.length:
				"Inconsistent array lengths"
		}
		let collection <- MotoGPCard.createEmptyCollection(nftType: Type<@MotoGPCard.Collection>())
		for index, cardID in cardIDs{ 
			let card <- ((self.cardMintProxyCap!).borrow()!).mint(cardID: cardID, serial: serials[index])
			collection.deposit(token: <-card)
		}
		return <-collection
	}
	
	init(){ 
		self.orderIds ={} 
		self.shrdMintProxyCap = nil
		self.cardMintProxyCap = nil
		self.paymentReceiverCap = nil
		self.ExternalPaymentPurchaseType = 1
		self.VaultPurchaseType = 2
		self.SalesCollectionStoragePath = /storage/salesCollection
		self.SalesCollectionPublicPath = /public/salesCollection
		self.SalesCollectionPrivatePath = /private/salesCollection
	}
}
