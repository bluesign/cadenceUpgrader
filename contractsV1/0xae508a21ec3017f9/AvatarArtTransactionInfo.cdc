import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AvatarArtTransactionInfo{ 
	access(self)
	var acceptCurrencies: [Type]
	
	access(self)
	var nftInfo:{ UInt64: NFTInfo}
	
	access(all)
	let FeeInfoStoragePath: StoragePath
	
	access(all)
	let FeeInfoPublicPath: PublicPath
	
	access(all)
	let TransactionAddressStoragePath: StoragePath
	
	access(all)
	let TransactionAddressPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event FeeUpdated(
		tokenId: UInt64,
		affiliate: UFix64,
		storing: UFix64,
		insurance: UFix64,
		contractor: UFix64,
		platform: UFix64
	)
	
	access(all)
	event TransactionAddressUpdated(
		tokenId: UInt64,
		storing: Address?,
		insurance: Address?,
		contractor: Address?,
		platform: Address?
	)
	
	access(all)
	event DefaultAddressChanged(
		storing: Address?,
		insurance: Address?,
		contractor: Address?,
		platform: Address?
	)
	
	access(all)
	event DefaultFeeChanged(
		affiliate: UFix64,
		storing: UFix64,
		insurance: UFix64,
		contractor: UFix64,
		platform: UFix64
	)
	
	access(all)
	struct NFTInfo{ 
		// 0 for Digital, 1 for Physical
		access(all)
		let type: UInt
		
		access(all)
		var isFirstOwner: Bool
		
		access(all)
		var author:{ String: Capability<&{FungibleToken.Receiver}>}
		
		access(all)
		var authorFee: UFix64?
		
		init(
			type: UInt,
			authorFee: UFix64?,
			author:{ 
				String: Capability<&{FungibleToken.Receiver}>
			}
		){ 
			self.type = type
			self.isFirstOwner = true
			self.author = author
			self.authorFee = authorFee
		}
		
		access(contract)
		fun setFirstOwner(_ isFirst: Bool){ 
			self.isFirstOwner = isFirst
		}
	}
	
	access(all)
	struct FeeInfoItem{ 
		access(all)
		let affiliate: UFix64
		
		access(all)
		let storing: UFix64
		
		access(all)
		let insurance: UFix64
		
		access(all)
		let contractor: UFix64
		
		access(all)
		let platform: UFix64
		
		init(
			_affiliate: UFix64,
			_storing: UFix64,
			_insurance: UFix64,
			_contractor: UFix64,
			_platform: UFix64
		){ 
			self.affiliate = _affiliate
			self.storing = _storing
			self.insurance = _insurance
			self.contractor = _contractor
			self.platform = _platform
		}
	}
	
	access(all)
	resource interface PublicFeeInfo{ 
		access(all)
		fun getFee(tokenId: UInt64): FeeInfoItem?
	}
	
	access(all)
	resource FeeInfo: PublicFeeInfo{ 
		
		//Store fee for each NFT specific
		access(all)
		var fees:{ UInt64: FeeInfoItem}
		
		// The defaults fee if not specific
		// 0: Digital
		// 1: Physical 1st
		// 2: Physical 2st
		access(all)
		var defaultFees:{ UInt: FeeInfoItem}
		
		access(all)
		fun setFee(tokenId: UInt64, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64){ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			self.fees[tokenId] = FeeInfoItem(_affiliate: affiliate, _storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform)
			emit FeeUpdated(tokenId: tokenId, affiliate: affiliate, storing: storing, insurance: insurance, contractor: contractor, platform: platform)
		}
		
		access(all)
		fun getFee(tokenId: UInt64): FeeInfoItem?{ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			let nftInfo = AvatarArtTransactionInfo.nftInfo[tokenId]
			if nftInfo == nil{ 
				return nil
			}
			
			// For Digital NFT
			if (nftInfo!).type == 0{ 
				return self.defaultFees[0]
			}
			
			// For Physical NFT
			if (nftInfo!).type == 1{ 
				if (nftInfo!).isFirstOwner{ 
					return self.fees[tokenId] ?? self.defaultFees[1]
				}
				return self.defaultFees[2]
			}
			return nil
		}
		
		access(all)
		fun setDefaultFee(type: UInt, affiliate: UFix64, storing: UFix64, insurance: UFix64, contractor: UFix64, platform: UFix64){ 
			pre{ 
				[0 as UInt, 1, 2].contains(type):
					"Type should be 0, 1, 2"
			}
			self.defaultFees[type] = FeeInfoItem(_affiliate: affiliate, _storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform)
			emit DefaultFeeChanged(affiliate: affiliate, storing: storing, insurance: insurance, contractor: contractor, platform: platform)
		}
		
		// initializer
		init(){ 
			self.fees ={} 
			self.defaultFees ={} 
		}
	}
	
	// destructor
	access(all)
	struct TransactionRecipientItem{ 
		access(all)
		let storing: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let insurance: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let contractor: Capability<&{FungibleToken.Receiver}>?
		
		access(all)
		let platform: Capability<&{FungibleToken.Receiver}>?
		
		init(
			_storing: Capability<&{FungibleToken.Receiver}>?,
			_insurance: Capability<&{FungibleToken.Receiver}>?,
			_contractor: Capability<&{FungibleToken.Receiver}>?,
			_platform: Capability<&{FungibleToken.Receiver}>?
		){ 
			self.storing = _storing
			self.insurance = _insurance
			self.contractor = _contractor
			self.platform = _platform
		}
	}
	
	access(all)
	resource interface PublicTransactionAddress{ 
		access(all)
		fun getAddress(tokenId: UInt64, payType: Type): TransactionRecipientItem?
	}
	
	access(all)
	resource TransactionAddress: PublicTransactionAddress{ 
		// Store fee for each NFT
		// map tokenID => { payTypeIdentifier => TransactionRecipientItem }
		access(all)
		var addresses:{ UInt64:{ String: TransactionRecipientItem}}
		
		access(all)
		var defaultAddresses:{ String: TransactionRecipientItem}
		
		access(all)
		fun setAddress(tokenId: UInt64, payType: Type, storing: Capability<&{FungibleToken.Receiver}>?, insurance: Capability<&{FungibleToken.Receiver}>?, contractor: Capability<&{FungibleToken.Receiver}>?, platform: Capability<&{FungibleToken.Receiver}>?){ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			let address = self.addresses[tokenId] ??{} 
			address.insert(key: payType.identifier, TransactionRecipientItem(_storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform))
			self.addresses[tokenId] = address
			emit TransactionAddressUpdated(tokenId: tokenId, storing: storing?.address, insurance: insurance?.address, contractor: contractor?.address, platform: platform?.address)
		}
		
		access(all)
		fun getAddress(tokenId: UInt64, payType: Type): TransactionRecipientItem?{ 
			pre{ 
				tokenId > 0:
					"tokenId parameter is zero"
			}
			if let addr = self.addresses[tokenId]{ 
				return addr[payType.identifier]
			}
			return self.defaultAddresses[payType.identifier]
		}
		
		access(all)
		fun setDefaultAddress(payType: Type, storing: Capability<&{FungibleToken.Receiver}>?, insurance: Capability<&{FungibleToken.Receiver}>?, contractor: Capability<&{FungibleToken.Receiver}>?, platform: Capability<&{FungibleToken.Receiver}>?){ 
			self.defaultAddresses.insert(key: payType.identifier, TransactionRecipientItem(_storing: storing, _insurance: insurance, _contractor: contractor, _platform: platform))
			emit DefaultAddressChanged(storing: storing?.address, insurance: insurance?.address, contractor: contractor?.address, platform: platform?.address)
		}
		
		init(){ 
			self.addresses ={} 
			self.defaultAddresses ={} 
		}
	}
	
	// destructor
	access(all)
	resource Administrator{ 
		access(all)
		fun setAcceptCurrencies(types: [Type]){ 
			for type in types{ 
				assert(type.isSubtype(of: Type<@{FungibleToken.Vault}>()), message: "Should be a sub type of FungibleToken.Vault")
			}
			AvatarArtTransactionInfo.acceptCurrencies = types
		}
		
		access(all)
		fun setNFTInfo(
			tokenID: UInt64,
			type: UInt,
			author:{ 
				String: Capability<&{FungibleToken.Receiver}>
			},
			authorFee: UFix64?
		){ 
			AvatarArtTransactionInfo.nftInfo[tokenID] = NFTInfo(
					type: type,
					authorFee: authorFee,
					author: author
				)
		}
	}
	
	access(account)
	fun setFirstOwner(tokenID: UInt64, _ isFirst: Bool){ 
		if let nft = self.nftInfo[tokenID]{ 
			nft.setFirstOwner(isFirst)
			self.nftInfo[tokenID] = nft
		}
	}
	
	access(account)
	fun getNFTInfo(tokenID: UInt64): NFTInfo?{ 
		return self.nftInfo[tokenID]
	}
	
	access(all)
	fun getAcceptCurrentcies(): [Type]{ 
		return self.acceptCurrencies
	}
	
	access(all)
	fun isCurrencyAccepted(type: Type): Bool{ 
		return self.acceptCurrencies.contains(type)
	}
	
	init(){ 
		self.acceptCurrencies = []
		self.nftInfo ={} 
		self.FeeInfoStoragePath = /storage/avatarArtTransactionInfoFeeInfo
		self.FeeInfoPublicPath = /public/avatarArtTransactionInfoFeeInfo
		self.TransactionAddressStoragePath = /storage/avatarArtTransactionInfoRecepientAddress
		self.TransactionAddressPublicPath = /public/avatarArtTransactionInfoRecepientAddress
		let feeInfo <- create FeeInfo()
		self.account.storage.save(<-feeInfo, to: self.FeeInfoStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&AvatarArtTransactionInfo.FeeInfo>(
				AvatarArtTransactionInfo.FeeInfoStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: AvatarArtTransactionInfo.FeeInfoPublicPath
		)
		let transactionAddress <- create TransactionAddress()
		self.account.storage.save(<-transactionAddress, to: self.TransactionAddressStoragePath)
		var capability_2 =
			self.account.capabilities.storage.issue<&AvatarArtTransactionInfo.TransactionAddress>(
				AvatarArtTransactionInfo.TransactionAddressStoragePath
			)
		self.account.capabilities.publish(
			capability_2,
			at: AvatarArtTransactionInfo.TransactionAddressPublicPath
		)
		self.AdminStoragePath = /storage/avatarArtTransactionInfoAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
