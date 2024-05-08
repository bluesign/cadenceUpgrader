import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Controller{ 
	
	// Variable size dictionary of TokenStructure
	access(contract)
	var allSocialTokens:{ String: TokenStructure}
	
	// Events
	// Emitted when a Reserve is incremented while minting social tokens
	access(all)
	event incrementReserve(_ newReserve: UFix64)
	
	// Emitted when a Reserve is decremented while burning social tokens
	access(all)
	event decrementReserve(_ newReserve: UFix64)
	
	// Emitted when a IssuedSupply is incremented after minting social tokens
	access(all)
	event incrementIssuedSupply(_ amount: UFix64)
	
	// Emitted when a IssuedSupply is decremented after minting social tokens
	access(all)
	event decrementIssuedSupply(_ amount: UFix64)
	
	// Emitted when a social Token is registered 
	access(all)
	event registerToken(_ tokenId: String, _ symbol: String, _ maxSupply: UFix64, _ artist: Address)
	
	// Emitted when a Percentage of social token is updated 
	access(all)
	event updatePercentage(_ percentage: UFix64)
	
	// Emitted when fee for social token is updated 
	access(all)
	event updateFeeSplitterDetail(_ tokenId: String)
	
	// Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let SocialTokenResourceStoragePath: StoragePath
	
	access(all)
	let SpecialCapabilityPrivatePath: PrivatePath
	
	access(all)
	let SocialTokenResourcePrivatePath: PrivatePath
	
	// A structure that contains all the data related to the Token 
	access(all)
	struct TokenStructure{ 
		access(all)
		var tokenId: String
		
		access(all)
		var symbol: String
		
		access(all)
		var issuedSupply: UFix64
		
		access(all)
		var maxSupply: UFix64
		
		access(all)
		var artist: Address
		
		access(all)
		var slope: UFix64
		
		access(contract)
		var feeSplitterDetail:{ Address: FeeStructure}
		
		access(all)
		var reserve: UFix64
		
		access(all)
		var tokenResourceStoragePath: StoragePath
		
		access(all)
		var tokenResourcePublicPath: PublicPath
		
		access(all)
		var socialMinterStoragePath: StoragePath
		
		access(all)
		var socialMinterPublicPath: PublicPath
		
		access(all)
		var socialBurnerStoragePath: StoragePath
		
		access(all)
		var socialBurnerPublicPath: PublicPath
		
		init(
			_ tokenId: String,
			_ symbol: String,
			_ maxSupply: UFix64,
			_ artist: Address,
			_ tokenStoragePath: StoragePath,
			_ tokenPublicPath: PublicPath,
			_ socialMinterStoragePath: StoragePath,
			_ socialMinterPublicPath: PublicPath,
			_ socialBurnerStoragePath: StoragePath,
			_ socialBurnerPublicPath: PublicPath
		){ 
			self.tokenId = tokenId
			self.symbol = symbol
			self.issuedSupply = 0.0
			self.maxSupply = maxSupply
			self.artist = artist
			self.slope = 0.5
			self.feeSplitterDetail ={} 
			self.reserve = 0.0
			self.tokenResourceStoragePath = tokenStoragePath
			self.tokenResourcePublicPath = tokenPublicPath
			self.socialMinterStoragePath = socialMinterStoragePath
			self.socialMinterPublicPath = socialMinterPublicPath
			self.socialBurnerStoragePath = socialBurnerStoragePath
			self.socialBurnerPublicPath = socialBurnerPublicPath
		}
		
		access(all)
		fun incrementReserve(_ newReserve: UFix64){ 
			pre{ 
				newReserve != nil:
					"reserve must not be null"
				newReserve > 0.0:
					"reserve must be greater than zero"
			}
			self.reserve = self.reserve + newReserve
			emit incrementReserve(newReserve)
		}
		
		access(all)
		fun decrementReserve(_ newReserve: UFix64){ 
			pre{ 
				newReserve != nil:
					"reserve must not be null"
				newReserve > 0.0:
					"reserve must be greater than zero"
			}
			self.reserve = self.reserve - newReserve
			emit decrementReserve(newReserve)
		}
		
		access(all)
		fun incrementIssuedSupply(_ amount: UFix64){ 
			pre{ 
				self.issuedSupply + amount <= self.maxSupply:
					"max supply reached"
			}
			self.issuedSupply = self.issuedSupply + amount
			emit incrementIssuedSupply(amount)
		}
		
		access(all)
		fun decrementIssuedSupply(_ amount: UFix64){ 
			pre{ 
				self.issuedSupply - amount >= 0.0:
					"issued supply must not be zero"
			}
			self.issuedSupply = self.issuedSupply - amount
			emit decrementIssuedSupply(amount)
		}
		
		access(all)
		fun setFeeSplitterDetail(_ feeSplitterDetail:{ Address: FeeStructure}){ 
			self.feeSplitterDetail = feeSplitterDetail
		}
		
		access(all)
		fun getFeeSplitterDetail():{ Address: FeeStructure}{ 
			return self.feeSplitterDetail
		}
	}
	
	access(all)
	resource interface SpecialCapability{ 
		access(all)
		fun registerToken(
			_ symbol: String,
			_ maxSupply: UFix64,
			_ artist: Address,
			_ tokenStoragePath: StoragePath,
			_ tokenPublicPath: PublicPath,
			_ socialMinterStoragePath: StoragePath,
			_ socialMinterPublicPath: PublicPath,
			_ socialBurnerStoragePath: StoragePath,
			_ socialBurnerPublicPath: PublicPath
		)
		
		access(all)
		fun updateFeeSplitterDetail(_ tokenId: String, _ feeSplitterDetail:{ Address: FeeStructure})
	}
	
	access(all)
	resource interface UserSpecialCapability{ 
		access(all)
		fun addCapability(cap: Capability<&{SpecialCapability}>)
	}
	
	access(all)
	resource interface SocialTokenResourcePublic{ 
		access(all)
		fun incrementIssuedSupply(_ tokenId: String, _ amount: UFix64)
		
		access(all)
		fun decrementIssuedSupply(_ tokenId: String, _ amount: UFix64)
		
		access(all)
		fun incrementReserve(_ tokenId: String, _ newReserve: UFix64)
		
		access(all)
		fun decrementReserve(_ tokenId: String, _ newReserve: UFix64)
	}
	
	access(all)
	resource Admin: SpecialCapability{ 
		access(all)
		fun registerToken(_ symbol: String, _ maxSupply: UFix64, _ artist: Address, _ tokenStoragePath: StoragePath, _ tokenPublicPath: PublicPath, _ socialMinterStoragePath: StoragePath, _ socialMinterPublicPath: PublicPath, _ socialBurnerStoragePath: StoragePath, _ socialBurnerPublicPath: PublicPath){ 
			pre{ 
				symbol != nil:
					"symbol must not be null"
				maxSupply > 0.0:
					"max supply must be greater than zero"
			}
			let artistAddress = artist
			let resourceOwner = (self.owner!).address
			let tokenId = symbol.concat("_").concat(artistAddress.toString())
			assert(Controller.allSocialTokens[tokenId] == nil, message: "token already registered")
			Controller.allSocialTokens[tokenId] = Controller.TokenStructure(tokenId, symbol, maxSupply, artistAddress, tokenStoragePath, tokenPublicPath, socialMinterStoragePath, socialMinterPublicPath, socialBurnerStoragePath, socialBurnerPublicPath)
			emit registerToken(tokenId, symbol, maxSupply, artistAddress)
		}
		
		access(all)
		fun updateFeeSplitterDetail(_ tokenId: String, _ feeSplitterDetail:{ Address: FeeStructure}){ 
			(Controller.allSocialTokens[tokenId]!).setFeeSplitterDetail(feeSplitterDetail)
			emit updateFeeSplitterDetail(tokenId)
		}
	}
	
	access(all)
	resource SocialTokenResource: SocialTokenResourcePublic, UserSpecialCapability{ 
		// a variable that store user capability to utilize methods 
		access(contract)
		var capability: Capability<&{SpecialCapability}>?
		
		// method which provide capability to user to utilize methods
		access(all)
		fun addCapability(cap: Capability<&{SpecialCapability}>){ 
			pre{ 
				// we make sure the SpecialCapability is 
				// valid before executing the method
				cap.borrow() != nil:
					"could not borrow a reference to the SpecialCapability"
				self.capability == nil:
					"resource already has the SpecialCapability"
			}
			// add the SpecialCapability
			self.capability = cap
		}
		
		//method to increment issued supply, only access by the verified user
		access(all)
		fun incrementIssuedSupply(_ tokenId: String, _ amount: UFix64){ 
			pre{ 
				amount > 0.0:
					"Amount must be greator than zero"
				tokenId != "":
					"token id must not be null"
				Controller.allSocialTokens[tokenId] != nil:
					"token id must not be null"
			}
			(Controller.allSocialTokens[tokenId]!).incrementIssuedSupply(amount)
		}
		
		// method to decrement issued supply, only access by the verified user
		access(all)
		fun decrementIssuedSupply(_ tokenId: String, _ amount: UFix64){ 
			pre{ 
				amount > 0.0:
					"Amount must be greator than zero"
				tokenId != "":
					"token id must not be null"
				Controller.allSocialTokens[tokenId] != nil:
					"token id must not be null"
			}
			(Controller.allSocialTokens[tokenId]!).decrementIssuedSupply(amount)
		}
		
		// method to increment reserve of a token, only access by the verified user
		access(all)
		fun incrementReserve(_ tokenId: String, _ newReserve: UFix64){ 
			pre{ 
				newReserve != nil:
					"reserve must not be null"
				newReserve > 0.0:
					"reserve must be greater than zero"
			}
			(Controller.allSocialTokens[tokenId]!).incrementReserve(newReserve)
		}
		
		// method to decrement reserve of a token, only access by the verified user
		access(all)
		fun decrementReserve(_ tokenId: String, _ newReserve: UFix64){ 
			pre{ 
				newReserve != nil:
					"reserve must not be null"
				newReserve > 0.0:
					"reserve must be greater than zero"
			}
			(Controller.allSocialTokens[tokenId]!).decrementReserve(newReserve)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	// A structure that contains all the data related to the Fee
	access(all)
	struct FeeStructure{ 
		access(all)
		var percentage: UFix64
		
		init(_ percentage: UFix64){ 
			self.percentage = percentage
		}
		
		// method to update the percentage of the token
		access(account)
		fun updatePercentage(_ percentage: UFix64){ 
			pre{ 
				percentage > 0.0:
					"Percentage should be greater than zero"
			}
			self.percentage = percentage
			emit updatePercentage(percentage)
		}
	}
	
	// method to get all the token details
	access(all)
	fun getTokenDetails(_ tokenId: String): Controller.TokenStructure{ 
		pre{ 
			tokenId != nil:
				"token id must not be null"
			(Controller.allSocialTokens[tokenId]!).tokenId == tokenId:
				"token id is not same"
		}
		return self.allSocialTokens[tokenId]!
	}
	
	// method to create a SocialTokenResource
	access(all)
	fun createSocialTokenResource(): @SocialTokenResource{ 
		return <-create SocialTokenResource()
	}
	
	init(){ 
		self.allSocialTokens ={} 
		self.AdminStoragePath = /storage/ControllerAdmin
		self.SocialTokenResourceStoragePath = /storage/ControllerSocialTokenResource
		self.SpecialCapabilityPrivatePath = /private/ControllerSpecialCapability
		self.SocialTokenResourcePrivatePath = /private/ControllerSocialTokenResourcePrivate
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{SpecialCapability}>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.SpecialCapabilityPrivatePath)
	}
}
