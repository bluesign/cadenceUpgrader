// Digital Art as Fungible Tokens

// Each piece of artwork on Nanobash has a certain number of "editions".
// However, instead of these editions being numbered in the way NFTs generally are, they are fungible and interchangeable.
// This contract is used to create multiple tokens each representing a unique piece of artwork stored via ipfs within the metadata.
// Each token will have a predefined maximum quantity when created.
// Once the maximum number of editions are created or the token is locked, no additional editions will be able to be created.
// Accounts are free to send / exchange any of these tokens with one another.
access(all)
contract Nanobash{ 
	
	// Total supply of all tokens in existence.
	access(all)
	var nextTokenID: UInt64
	
	access(self)
	var tokens: @{UInt64: Token}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(tokenID: UInt64, quantity: UInt64, from: Address?)
	
	access(all)
	event Deposit(tokenID: UInt64, quantity: UInt64, to: Address?)
	
	access(all)
	event TokenCreated(tokenID: UInt64, metadata:{ String: String})
	
	access(all)
	event TokensMinted(tokenID: UInt64, quantity: UInt64)
	
	access(all)
	resource Token{ 
		access(all)
		let tokenID: UInt64
		
		access(all)
		let maxEditions: UInt64
		
		access(all)
		var numberMinted: UInt64
		
		// Intended to contain name and ipfs link to asset
		access(self)
		let metadata:{ String: String}
		
		// Additional editions of tokens are un-mintable when the token is locked
		access(all)
		var locked: Bool
		
		init(metadata:{ String: String}, maxEditions: UInt64){ 
			self.tokenID = Nanobash.nextTokenID
			self.maxEditions = maxEditions
			self.numberMinted = 0
			self.metadata = metadata
			self.locked = false
			Nanobash.nextTokenID = Nanobash.nextTokenID + 1 as UInt64
			emit TokenCreated(tokenID: self.tokenID, metadata: self.metadata)
		}
		
		// Lock the token to prevent additional editions being minted
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
			}
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		// Creates a vault with a specific quantity of the current token
		access(all)
		fun mintTokens(quantity: UInt64): @Vault{ 
			pre{ 
				!self.locked:
					"Unable to mint an edition after the piece has been locked."
				self.numberMinted + quantity <= self.maxEditions:
					"Maximum editions minted."
			}
			self.numberMinted = self.numberMinted + quantity
			emit TokensMinted(tokenID: self.tokenID, quantity: quantity)
			return <-create Vault(balances:{ self.tokenID: quantity})
		}
	}
	
	access(all)
	resource Admin{ 
		// Allows creation of new token types by the admin
		access(all)
		fun createToken(metadata:{ String: String}, maxEditions: UInt64): UInt64{ 
			var newToken <- create Token(metadata: metadata, maxEditions: maxEditions)
			let newID = newToken.tokenID
			Nanobash.tokens[newID] <-! newToken
			return newID
		}
		
		// Allow admins to borrow the token instance for token specific methods
		access(all)
		fun borrowToken(tokenID: UInt64): &Token{ 
			pre{ 
				Nanobash.tokens[tokenID] != nil:
					"Cannot borrow Token: The Token doesn't exist"
			}
			return &Nanobash.tokens[tokenID] as &Nanobash.Token?
		}
	}
	
	access(all)
	resource interface Provider{ 
		access(all)
		fun withdraw(amount: UInt64, tokenID: UInt64): @Vault{ 
			post{ 
				result.getBalance(tokenID: tokenID) == UInt64(amount):
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
			}
		}
	}
	
	access(all)
	resource interface Receiver{ 
		access(all)
		fun deposit(from: @Vault)
	}
	
	access(all)
	resource interface Balance{ 
		access(all)
		view fun getBalance(tokenID: UInt64): UInt64
		
		access(all)
		fun getBalances():{ UInt64: UInt64}
	}
	
	access(all)
	resource Vault: Provider, Receiver, Balance{ 
		// Map of tokenIDs to # of editions within the vault
		access(self)
		let balances:{ UInt64: UInt64}
		
		init(balances:{ UInt64: UInt64}){ 
			self.balances = balances
		}
		
		access(all)
		fun getBalances():{ UInt64: UInt64}{ 
			return self.balances
		}
		
		access(all)
		view fun getBalance(tokenID: UInt64): UInt64{ 
			return self.balances[tokenID] ?? 0 as UInt64
		}
		
		access(all)
		fun withdraw(amount: UInt64, tokenID: UInt64): @Vault{ 
			pre{ 
				self.balances[tokenID] != nil:
					"User does not own this token"
				self.balances[tokenID]! >= amount:
					"Insufficient tokens"
			}
			let balance: UInt64 = self.balances[tokenID]!
			self.balances[tokenID] = balance - amount
			emit Withdraw(tokenID: tokenID, quantity: amount, from: self.owner?.address)
			return <-create Vault(balances:{ tokenID: amount})
		}
		
		access(all)
		fun deposit(from: @Vault){ 
			// For each entry in our {tokenID: quantity} map, add tokens in vault to account balances
			let tokenIDs = from.balances.keys
			for tokenID in tokenIDs{ 
				// Create empty balance for any tokens not yet owned
				if self.balances[tokenID] == nil{ 
					self.balances[tokenID] = 0
				}
				emit Deposit(tokenID: tokenID, quantity: from.balances[tokenID]!, to: self.owner?.address)
				self.balances[tokenID] = self.balances[tokenID]! + from.balances[tokenID]!
			}
			destroy from
		}
	}
	
	access(all)
	fun createEmptyVault(): @Vault{ 
		return <-create Vault(balances:{} )
	}
	
	access(all)
	fun getNumberMinted(tokenID: UInt64): UInt64{ 
		return self.tokens[tokenID]?.numberMinted ?? 0 as UInt64
	}
	
	access(all)
	fun getMaxEditions(tokenID: UInt64): UInt64{ 
		return self.tokens[tokenID]?.maxEditions ?? 0 as UInt64
	}
	
	access(all)
	fun getTokenMetadata(tokenID: UInt64):{ String: String}{ 
		return self.tokens[tokenID]?.getMetadata() ??{}  as{ String: String}
	}
	
	access(all)
	fun isTokenLocked(tokenID: UInt64): Bool{ 
		return Nanobash.tokens[tokenID]?.locked ?? false
	}
	
	init(){ 
		// A map of tokenIDs to Tokens contained within the contract
		self.tokens <-{} 
		self.nextTokenID = 1
		
		// Create a vault for the contract creator
		let vault <- create Vault(balances:{} )
		self.account.storage.save(<-vault, to: /storage/MainVault)
		
		// Create an admin resource for token methods
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/NanobashAdmin)
	}
}
