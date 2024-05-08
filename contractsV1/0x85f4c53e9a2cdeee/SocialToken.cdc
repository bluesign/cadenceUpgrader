import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Controller from "./Controller.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract SocialToken: FungibleToken{ 
	
	// Total supply of all social tokens that are minted using this contract
	access(all)
	var totalSupply: UFix64
	
	// Events
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensMinted(_ tokenId: String, _ mintPrice: UFix64, _ amount: UFix64)
	
	access(all)
	event TokensBurned(_ tokenId: String, _ burnPrice: UFix64, _ amount: UFix64)
	
	access(all)
	event SingleTokenMintPrice(_ tokenId: String, _ mintPrice: UFix64)
	
	access(all)
	event SingleTokenBurnPrice(_ tokenId: String, _ burnPrice: UFix64)
	
	// a variable that store admin capability to utilize methods of controller contract
	access(contract)
	let adminRef: Capability<&{Controller.SocialTokenResourcePublic}>
	
	// a variable which will store the structure of FUSDPool
	access(contract)
	var collateralPool: FUSDPool
	
	access(all)
	resource interface SocialTokenPublic{ 
		access(all)
		fun getTokenId(): String
	}
	
	// Vault
	//
	// Each user stores an instance of only the Vault in their storage
	// The functions in the Vault and governed by the pre and post conditions
	// in FungibleToken when they are called.
	// The checks happen at runtime whenever a function is called.
	//
	// Resources can only be created in the context of the contract that they
	// are defined in, so there is no way for a malicious user to create Vaults
	// out of thin air. A special Minter resource needs to be defined to mint
	// new tokens.
	//
	access(all)
	resource Vault: SocialTokenPublic, FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		access(all)
		var tokenId: String
		
		init(balance: UFix64){ 
			self.balance = balance
			self.tokenId = ""
		}
		
		access(all)
		fun setTokenId(_ tokenId: String){ 
			pre{ 
				tokenId != nil:
					"token id must not be null"
			}
			self.tokenId = tokenId
		}
		
		access(all)
		fun getTokenId(): String{ 
			return self.tokenId
		}
		
		// deposit
		//
		// Function that takes a Vault object as an argument and adds
		// its balance to the balance of the owners Vault.
		// It is allowed to destroy the sent Vault because the Vault
		// was a temporary holder of the tokens. The Vault's balance has
		// been consumed and therefore can be destroyed.
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @SocialToken.Vault
			if self.tokenId == ""{ 
				self.tokenId = vault.tokenId
			}
			assert(vault.tokenId == self.tokenId, message: "error: invalid token id")
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		// withdraw
		//
		// Function that takes an integer amount as an argument
		// and withdraws that amount from the Vault.
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		//
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			let vault <- create Vault(balance: amount)
			vault.setTokenId(self.tokenId)
			emit TokensWithdrawn(amount: amount, from: (self.owner!).address)
			return <-vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	// createEmptyVault
	//
	// Function that creates a new Vault with a balance of zero
	// and returns it to the calling context. A user must call this function
	// and store the returned Vault in their storage in order to allow their
	// account to be able to receive deposits of this token type.
	//
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	// createNewMinter
	//
	// Function that creates a new minter
	// and returns it to the calling context. A user must call this function
	// and store the returned Minter in their storage in order to allow their
	// account to be able to mint new tokens.
	//
	access(all)
	fun createNewMinter(): @Minter{ 
		return <-create Minter()
	}
	
	// createNewBurner
	//
	// Function that creates a new burner
	// and returns it to the calling context. A user must call this function
	// and store the returned Burner in their storage in order to allow their
	// account to be able to burn tokens.
	//
	access(all)
	fun createNewBurner(): @Burner{ 
		return <-create Burner()
	}
	
	// A structure that contains all the data related to the FUSDPool
	access(all)
	struct FUSDPool{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let provider: Capability<&{FungibleToken.Provider}>
		
		access(all)
		let balance: Capability<&{FungibleToken.Balance}>
		
		init(_receiver: Capability<&{FungibleToken.Receiver}>, _provider: Capability<&{FungibleToken.Provider}>, _balance: Capability<&{FungibleToken.Balance}>){ 
			self.receiver = _receiver
			self.provider = _provider
			self.balance = _balance
		}
	}
	
	// method to distribute fee of a token when a token minted, distribute to admin and artist
	access(contract)
	fun distributeFee(_ tokenId: String, _ fusdPayment: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
		let amount = fusdPayment.balance
		let tokenDetails = Controller.getTokenDetails(tokenId)
		let detailData = tokenDetails.getFeeSplitterDetail()
		assert(detailData.length < 10, message: "Maximum Limit Reached. Please update Fee Structure")
		for address in detailData.keys{ 
			let feeStructuredetail = tokenDetails.getFeeSplitterDetail()
			let feeStructure = feeStructuredetail[address]
			let tempAmmount = amount * (feeStructure!).percentage
			let tempraryVault <- fusdPayment.withdraw(amount: tempAmmount)
			let account = getAccount(address)
			let depositSigner = account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow() ?? panic("could not borrow reference to the receiver")
			depositSigner.deposit(from: <-tempraryVault)
		}
		return <-fusdPayment
	}
	
	access(all)
	fun getMintPrice(_ tokenId: String, _ amount: UFix64): UFix64{ 
		pre{ 
			amount > 0.0:
				"Amount must be greator than zero"
			tokenId != "":
				"token id must not be null"
			Controller.getTokenDetails(tokenId).tokenId != nil:
				"token not registered"
		}
		let tokenDetails = Controller.getTokenDetails(tokenId)
		let supply = tokenDetails.issuedSupply
		let newSupply = supply + amount
		let reserve = tokenDetails.reserve
		assert(amount + tokenDetails.issuedSupply <= tokenDetails.maxSupply, message: "maximum supply reached")
		if supply == 0.0{ 
			return tokenDetails.slope.saturatingMultiply(amount.saturatingMultiply(amount / 2.0 / 10000.0))
		} else{ 
			return reserve.saturatingMultiply(newSupply.saturatingMultiply(newSupply) / supply.saturatingMultiply(supply)) - reserve
		}
	}
	
	access(all)
	fun getBurnPrice(_ tokenId: String, _ amount: UFix64): UFix64{ 
		pre{ 
			amount > 0.0:
				"Amount must be greator than zero"
			Controller.getTokenDetails(tokenId).tokenId != nil:
				"token not registered"
		}
		let decimalPoints: UFix64 = 1000.0
		let tokenDetails = Controller.getTokenDetails(tokenId)
		assert(tokenDetails.tokenId != "", message: "token id must not be null")
		let supply: Int256 = Int256(tokenDetails.issuedSupply)
		assert(tokenDetails.issuedSupply > 0.0, message: "Token supply is zero")
		assert(tokenDetails.issuedSupply >= amount, message: "amount greater than supply")
		let newSupply: Int256 = Int256(tokenDetails.issuedSupply - amount).saturatingMultiply(Int256(decimalPoints))
		var _reserve = tokenDetails.reserve
		var supplyPercentage: UFix64 = UFix64(newSupply.saturatingMultiply(newSupply) / supply.saturatingMultiply(supply)) / (decimalPoints * decimalPoints)
		return UFix64(_reserve - _reserve.saturatingMultiply(supplyPercentage))
	}
	
	access(all)
	resource interface MinterPublic{ 
		access(all)
		fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @{FungibleToken.Vault}, receiverVault: Capability<&{FungibleToken.Receiver}>): @SocialToken.Vault
	}
	
	access(all)
	resource Minter: MinterPublic{ 
		// mintTokens mints new tokens
		// 
		// Parameters:
		// tokenId: The ID of the token that will be minted
		// amount: amount to pay for the tokens
		// fusdPayment: will take the fusd balance
		// receiverVault: will return the remaining balance to the user
		// Pre-Conditions:
		// tokenId must not be null
		// amoutn must be greater than zero
		// issued supply will be less than or equal to maximum supply
		// 
		// Returns: The SocialToken Vault
		// 
		access(all)
		fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @{FungibleToken.Vault}, receiverVault: Capability<&{FungibleToken.Receiver}>): @SocialToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				fusdPayment.balance > 0.0:
					"Balance should be greater than zero"
				Controller.getTokenDetails(tokenId).tokenId != nil:
					"toke not registered"
				amount + Controller.getTokenDetails(tokenId).issuedSupply <= Controller.getTokenDetails(tokenId).maxSupply:
					"Max supply reached"
				SocialToken.adminRef.borrow() != nil:
					"social token does not have controller capability"
			}
			var remainingFUSD = 0.0
			var remainingSocialToken = 0.0
			let mintPrice = SocialToken.getMintPrice(tokenId, amount)
			let mintedTokenPrice = SocialToken.getMintPrice(tokenId, 1.0)
			assert(fusdPayment.balance >= mintPrice, message: "You don't have sufficient balance to mint tokens")
			var totalPayment = fusdPayment.balance
			assert(totalPayment >= mintPrice, message: "No payment yet")
			let extraAmount = totalPayment - mintPrice
			if extraAmount > 0.0{ 
				//Create Vault of extra amount and deposit back to user
				totalPayment = totalPayment - extraAmount
				let remainingAmountVault <- fusdPayment.withdraw(amount: extraAmount)
				let remainingVault = receiverVault.borrow()!
				remainingVault.deposit(from: <-remainingAmountVault)
			}
			let tempraryVar <- create SocialToken.Vault(balance: amount)
			tempraryVar.setTokenId(tokenId)
			let tokenDetails = Controller.getTokenDetails(tokenId)
			(SocialToken.adminRef.borrow()!).incrementIssuedSupply(tokenId, amount)
			let remainingAmount <- SocialToken.distributeFee(tokenId, <-fusdPayment)
			SocialToken.totalSupply = SocialToken.totalSupply + amount
			(SocialToken.adminRef.borrow()!).incrementReserve(tokenId, remainingAmount.balance)
			(SocialToken.collateralPool.receiver.borrow()!).deposit(from: <-remainingAmount)
			emit TokensMinted(tokenId, mintPrice, amount)
			emit SingleTokenMintPrice(tokenId, mintedTokenPrice)
			return <-tempraryVar
		}
	}
	
	access(all)
	resource interface BurnerPublic{ 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}): @{FungibleToken.Vault}
	}
	
	access(all)
	resource Burner: BurnerPublic{ 
		// burnTokens burns tokens
		// 
		// Parameters:
		// It will take the Vault
		// and burn the tokens, decrement the issued supply and reserve of the tokens
		// 
		// Returns: The Vault
		// 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
			let vault <- from as! @SocialToken.Vault
			let amount = vault.balance
			let tokenId = vault.getTokenId()
			let burnedTokenPrice = SocialToken.getBurnPrice(tokenId, 1.0)
			let burnPrice = SocialToken.getBurnPrice(tokenId, amount)
			let tokenDetails = Controller.getTokenDetails(tokenId)
			(SocialToken.adminRef.borrow()!).decrementIssuedSupply(tokenId, amount)
			(SocialToken.adminRef.borrow()!).decrementReserve(tokenId, burnPrice)
			emit TokensBurned(tokenId, burnPrice, amount)
			emit SingleTokenBurnPrice(tokenId, burnedTokenPrice)
			destroy vault
			return <-(SocialToken.collateralPool.provider.borrow()!).withdraw(amount: burnPrice)
		}
	}
	
	init(){ 
		self.totalSupply = 0.0
		var adminPrivateCap = self.account.capabilities.get<&{Controller.SocialTokenResourcePublic}>(/private/SocialTokenResourcePrivatePath)
		self.adminRef = adminPrivateCap!
		let vault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
		self.account.storage.save(<-vault, to: /storage/fusdVault)
		var capability_1 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
		self.account.capabilities.publish(capability_1, at: /public/fusdReceiver)
		var capability_2 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
		self.account.capabilities.publish(capability_2, at: /public/fusdBalance)
		var capability_3 = self.account.capabilities.storage.issue<&FUSD.Vault>(/storage/fusdVault)
		self.account.capabilities.publish(capability_3, at: /private/fusdProvider)
		self.collateralPool = FUSDPool(_receiver: self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver), _provider: self.account.capabilities.get<&FUSD.Vault>(/private/fusdProvider), _balance: self.account.capabilities.get<&FUSD.Vault>(/public/fusdBalance))
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
