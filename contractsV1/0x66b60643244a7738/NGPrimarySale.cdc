/**
	NGPrimarySale.cdc

	Description: Facilitates the exchange of Fungible Tokens for NFTs.
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract NGPrimarySale{ 
	access(all)
	let PrimarySaleStoragePath: StoragePath
	
	access(all)
	let PrimarySalePublicPath: PublicPath
	
	access(all)
	let PrimarySalePrivatePath: PrivatePath
	
	access(all)
	event PrimarySaleCreated(
		externalID: String,
		name: String,
		description: String,
		imageURI: String,
		nftType: Type,
		prices:{ 
			String: UFix64
		}
	)
	
	access(all)
	event PrimarySaleStatusChanged(externalID: String, status: String)
	
	access(all)
	event PriceSet(externalID: String, type: String, price: UFix64)
	
	access(all)
	event PriceRemoved(externalID: String, type: String)
	
	access(all)
	event AssetAdded(externalID: String, assetID: UInt64)
	
	access(all)
	event NFTPurchased(
		externalID: String,
		nftType: Type,
		assetID: UInt64,
		nftID: UInt64,
		purchaserAddress: Address,
		priceType: String,
		price: UFix64
	)
	
	access(all)
	event ContractInitialized()
	
	access(contract)
	let primarySaleIDs: [String]
	
	access(all)
	resource interface IMinter{ 
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}
	}
	
	// Data struct signed by account with specified "adminPublicKey."
	//
	// Permits accounts to purchase specific NFTs for some period of time.
	access(all)
	struct AdminSignedData{ 
		access(all)
		let externalID: String
		
		access(all)
		let priceType: String
		
		access(all)
		let primarySaleAddress: Address
		
		access(all)
		let purchaserAddress: Address
		
		access(all)
		let assetIDs: [UInt64]
		
		access(all)
		let expiration: UInt64 // unix timestamp
		
		
		init(
			externalID: String,
			primarySaleAddress: Address,
			purchaserAddress: Address,
			assetIDs: [
				UInt64
			],
			priceType: String,
			expiration: UInt64
		){ 
			self.externalID = externalID
			self.primarySaleAddress = primarySaleAddress
			self.purchaserAddress = purchaserAddress
			self.assetIDs = assetIDs
			self.priceType = priceType
			self.expiration = expiration
		}
		
		access(all)
		view fun toString(): String{ 
			var assetIDs = ""
			var i = 0
			while i < self.assetIDs.length{ 
				if i > 0{ 
					assetIDs = assetIDs.concat(",")
				}
				assetIDs = assetIDs.concat(self.assetIDs[i].toString())
				i = i + 1
			}
			return self.externalID.concat(":").concat(self.primarySaleAddress.toString()).concat(
				":"
			).concat(self.purchaserAddress.toString()).concat(":").concat(assetIDs).concat(":")
				.concat(self.priceType).concat(":").concat(self.expiration.toString())
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
		fun getDetails(): PrimarySaleDetails
		
		access(all)
		fun getSupply(): Int
		
		access(all)
		fun getPrices():{ String: UFix64}
		
		access(all)
		fun getStatus(): String
		
		access(all)
		fun purchaseNFTs(payment: @{FungibleToken.Vault}, data: AdminSignedData, sig: String): @[{
			NonFungibleToken.NFT}
		]
		
		access(all)
		fun claimNFTs(data: AdminSignedData, sig: String): @[{NonFungibleToken.NFT}]
	}
	
	access(all)
	resource interface PrimarySalePrivate{ 
		access(all)
		fun pause()
		
		access(all)
		fun open()
		
		access(all)
		fun close()
		
		access(all)
		fun setDetails(name: String, description: String, imageURI: String)
		
		access(all)
		fun setPrice(priceType: String, price: UFix64)
		
		access(all)
		fun setAdminPublicKey(adminPublicKey: String)
		
		access(all)
		fun addAsset(assetID: UInt64)
	}
	
	access(all)
	struct PrimarySaleDetails{ 
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var imageURI: String
		
		init(name: String, description: String, imageURI: String){ 
			self.name = name
			self.description = description
			self.imageURI = imageURI
		}
	}
	
	access(all)
	resource PrimarySale: PrimarySalePublic, PrimarySalePrivate{ 
		access(self)
		var externalID: String
		
		access(all)
		let nftType: Type
		
		access(self)
		var status: PrimarySaleStatus
		
		access(self)
		var prices:{ String: UFix64}
		
		access(self)
		var availableAssetIDs:{ UInt64: Bool}
		
		// primary sale metadata
		access(self)
		var details: PrimarySaleDetails
		
		access(self)
		let minterCap: Capability<&{IMinter}>
		
		access(self)
		let paymentReceiverCap: Capability<&{FungibleToken.Receiver}>
		
		// pub key used to verify signatures from a specified admin
		access(self)
		var adminPublicKey: String
		
		init(externalID: String, name: String, description: String, imageURI: String, nftType: Type, prices:{ String: UFix64}, minterCap: Capability<&{IMinter}>, paymentReceiverCap: Capability<&{FungibleToken.Receiver}>, adminPublicKey: String){ 
			self.externalID = externalID
			self.details = PrimarySaleDetails(name: name, description: description, imageURI: imageURI)
			self.nftType = nftType
			self.status = PrimarySaleStatus.PAUSED // primary sale is paused initially
			
			self.availableAssetIDs ={} // no asset IDs assigned to primary sale initially 
			
			self.prices = prices
			self.minterCap = minterCap
			self.paymentReceiverCap = paymentReceiverCap
			self.adminPublicKey = adminPublicKey
			emit PrimarySaleCreated(externalID: externalID, name: name, description: description, imageURI: imageURI, nftType: nftType, prices: prices)
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
		fun setDetails(name: String, description: String, imageURI: String){ 
			self.details = PrimarySaleDetails(name: name, description: description, imageURI: imageURI)
		}
		
		access(all)
		fun getDetails(): PrimarySaleDetails{ 
			return self.details
		}
		
		access(all)
		fun setPrice(priceType: String, price: UFix64){ 
			self.prices[priceType] = price
			emit PriceSet(externalID: self.externalID, type: priceType, price: price)
		}
		
		access(all)
		fun removePrice(priceType: String){ 
			self.prices.remove(key: priceType)
			emit PriceRemoved(externalID: self.externalID, type: priceType)
		}
		
		access(all)
		fun getPrices():{ String: UFix64}{ 
			return self.prices
		}
		
		access(all)
		fun getSupply(): Int{ 
			return self.availableAssetIDs.length
		}
		
		access(all)
		fun setAdminPublicKey(adminPublicKey: String){ 
			self.adminPublicKey = adminPublicKey
		}
		
		access(all)
		fun addAsset(assetID: UInt64){ 
			self.availableAssetIDs[assetID] = true
			emit AssetAdded(externalID: self.externalID, assetID: assetID)
		}
		
		access(all)
		fun pause(){ 
			self.status = PrimarySaleStatus.PAUSED
			emit PrimarySaleStatusChanged(externalID: self.externalID, status: self.getStatus())
		}
		
		access(all)
		fun open(){ 
			pre{ 
				self.status != PrimarySaleStatus.OPEN:
					"Primary sale is already open"
				self.status != PrimarySaleStatus.CLOSED:
					"Cannot resume primary sale that is closed"
			}
			self.status = PrimarySaleStatus.OPEN
			emit PrimarySaleStatusChanged(externalID: self.externalID, status: self.getStatus())
		}
		
		access(all)
		fun close(){ 
			self.status = PrimarySaleStatus.CLOSED
			emit PrimarySaleStatusChanged(externalID: self.externalID, status: self.getStatus())
		}
		
		access(self)
		view fun verifyAdminSignedData(data: AdminSignedData, sig: String): Bool{ 
			let publicKey = PublicKey(publicKey: self.adminPublicKey.decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
			return publicKey.verify(signature: sig.decodeHex(), signedData: data.toString().utf8, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
		}
		
		access(all)
		fun purchaseNFTs(payment: @{FungibleToken.Vault}, data: AdminSignedData, sig: String): @[{NonFungibleToken.NFT}]{ 
			pre{ 
				self.externalID == data.externalID:
					"externalID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				data.assetIDs.length > 0:
					"must purchase at least one NFT"
				self.verifyAdminSignedData(data: data, sig: sig):
					"invalid admin signature for data"
				data.expiration >= UInt64(getCurrentBlock().timestamp):
					"expired signature"
			}
			let price = self.prices[data.priceType] ?? panic("Invalid price type")
			assert(payment.balance == price * UFix64(data.assetIDs.length), message: "payment vault does not contain requested price")
			let receiver = self.paymentReceiverCap.borrow()!
			receiver.deposit(from: <-payment)
			let minter = self.minterCap.borrow() ?? panic("cannot borrow minter")
			var i: Int = 0
			let nfts: @[{NonFungibleToken.NFT}] <- []
			while i < data.assetIDs.length{ 
				let assetID = data.assetIDs[i]
				assert(self.availableAssetIDs.containsKey(assetID), message: "NFT is not available for purchase: ".concat(assetID.toString()))
				self.availableAssetIDs.remove(key: assetID)
				let nft <- minter.mint(assetID: assetID, creator: data.purchaserAddress)
				emit NFTPurchased(externalID: self.externalID, nftType: nft.getType(), assetID: assetID, nftID: nft.id, purchaserAddress: data.purchaserAddress, priceType: data.priceType, price: price)
				nfts.append(<-nft)
				i = i + 1
			}
			assert(nfts.length == data.assetIDs.length, message: "nft count mismatch")
			return <-nfts
		}
		
		access(all)
		fun claimNFTs(data: AdminSignedData, sig: String): @[{NonFungibleToken.NFT}]{ 
			pre{ 
				self.externalID == data.externalID:
					"externalID mismatch"
				self.status == PrimarySaleStatus.OPEN:
					"primary sale is not open"
				data.assetIDs.length > 0:
					"must purchase at least one NFT"
				self.verifyAdminSignedData(data: data, sig: sig):
					"invalid admin signature for data"
				data.expiration >= UInt64(getCurrentBlock().timestamp):
					"expired signature"
			}
			let price = self.prices[data.priceType] ?? panic("Invalid price type")
			assert(price == 0.0, message: "Can only claim zero price assets")
			let minter = self.minterCap.borrow() ?? panic("cannot borrow minter")
			var i: Int = 0
			let nfts: @[{NonFungibleToken.NFT}] <- []
			while i < data.assetIDs.length{ 
				let assetID = data.assetIDs[i]
				assert(self.availableAssetIDs.containsKey(assetID), message: "NFT is not available for purchase: ".concat(assetID.toString()))
				self.availableAssetIDs.remove(key: assetID)
				let nft <- minter.mint(assetID: assetID, creator: data.purchaserAddress)
				emit NFTPurchased(externalID: self.externalID, nftType: nft.getType(), assetID: assetID, nftID: nft.id, purchaserAddress: data.purchaserAddress, priceType: data.priceType, price: price)
				nfts.append(<-nft)
				i = i + 1
			}
			assert(nfts.length == data.assetIDs.length, message: "nft count mismatch")
			return <-nfts
		}
	}
	
	access(all)
	fun createPrimarySale(
		externalID: String,
		name: String,
		description: String,
		imageURI: String,
		nftType: Type,
		prices:{ 
			String: UFix64
		},
		minterCap: Capability<&{IMinter}>,
		paymentReceiverCap: Capability<&{FungibleToken.Receiver}>,
		adminPublicKey: String
	): @PrimarySale{ 
		assert(
			!self.primarySaleIDs.contains(externalID),
			message: "Primary sale external ID is already in use"
		)
		self.primarySaleIDs.append(externalID)
		return <-create PrimarySale(
			externalID: externalID,
			name: name,
			description: description,
			imageURI: imageURI,
			nftType: nftType,
			prices: prices,
			minterCap: minterCap,
			paymentReceiverCap: paymentReceiverCap,
			adminPublicKey: adminPublicKey
		)
	}
	
	init(){ 
		// default paths but not intended for multiple primary sales on same acct
		self.PrimarySaleStoragePath = /storage/NGPrimarySale001
		self.PrimarySalePublicPath = /public/NGPrimarySale001
		self.PrimarySalePrivatePath = /private/NGPrimarySale001
		self.primarySaleIDs = []
		emit ContractInitialized()
	}
}
