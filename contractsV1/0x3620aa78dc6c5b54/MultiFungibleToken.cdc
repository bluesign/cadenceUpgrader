/**

MultiFungibleToken is a semi-fungible token contract which helps to publish a group of fungible tokens without the need
of deploying multiple contracts. There are two cases to consider:
	- tokens are not compatible (non-fungible) when they have different token IDs
	- tokens are compatible (fungible) when they have the same token ID

@author Metapier Foundation Ltd.

 */

access(all)
contract interface MultiFungibleToken{ 
	
	/// TokensInitialized
	///
	/// The event that is emitted when the contract is created
	///
	access(all)
	event ContractInitialized()
	
	/// TokensWithdrawn
	///
	/// The event that is emitted when tokens are withdrawn from a Vault of some token ID
	///
	access(all)
	event TokensWithdrawn(tokenId: UInt64, amount: UFix64, from: Address?)
	
	/// TokensDeposited
	///
	/// The event that is emitted when tokens are deposited into a Vault of some token ID
	///
	access(all)
	event TokensDeposited(tokenId: UInt64, amount: UFix64, to: Address?)
	
	/// Provider
	///
	/// The interface that enforces the requirements for withdrawing
	/// tokens from the implementing type.
	///
	/// It does not enforce requirements on `balance` here,
	/// because it leaves open the possibility of creating custom providers
	/// that do not necessarily need their own balance.
	///
	access(all)
	resource interface Provider{ 
		
		/// withdraw subtracts tokens from the owner's Vault
		/// and returns a Vault with the removed tokens.
		///
		/// The function's access level is public, but this is not a problem
		/// because only the owner storing the resource in their account
		/// can initially call this function.
		///
		/// The owner may grant other accounts access by creating a private
		/// capability that allows specific other users to access
		/// the provider resource through a reference.
		///
		/// The owner may also grant all accounts access by creating a public
		/// capability that allows all users to access the provider
		/// resource through a reference.
		///
		access(all)
		fun withdraw(tokenId: UInt64, amount: UFix64): @{MultiFungibleToken.Vault}{ 
			post{ 
				// `result` refers to the return value
				result.balance == amount:
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
				result.tokenId == tokenId:
					"The withdrawn Vault must match with the given token ID"
			}
		}
	}
	
	/// Receiver
	///
	/// The interface that enforces the requirements for depositing
	/// tokens into the implementing type.
	///
	/// We do not include a condition that checks the balance because
	/// we want to give users the ability to make custom receivers that
	/// can do custom things with the tokens, like split them up and
	/// send them to different places.
	///
	access(all)
	resource interface Receiver{ 
		
		/// deposit takes a Vault and deposits it into the implementing resource type
		///
		access(all)
		fun deposit(from: @{MultiFungibleToken.Vault})
	}
	
	/// View
	///
	/// The interface that contains the `balance` and the `tokenId`
	/// fields of the Vault and enforces that when new Vaults are
	/// created, the fields are initialized correctly.
	///
	access(all)
	resource interface View{ 
		access(all)
		var balance: UFix64
		
		access(all)
		let tokenId: UInt64
		
		init(tokenId: UInt64, balance: UFix64){ 
			post{ 
				self.tokenId == tokenId:
					"Token ID must be initialized to the initial tokenId"
				self.balance == balance:
					"Balance must be initialized to the initial balance"
			}
		}
	}
	
	/// Vault
	///
	/// The resource that contains the functions to send and receive tokens.
	///
	access(all)
	resource interface Vault: Receiver, View{ 
		
		/// The total balance of the vault
		///
		access(all)
		var balance: UFix64
		
		/// The token ID of the vault
		///
		access(all)
		let tokenId: UInt64
		
		/// The conforming type must declare an initializer
		/// that allows providing the initial balance and token ID
		/// of the Vault
		///
		init(tokenId: UInt64, balance: UFix64)
		
		/// withdraw subtracts `amount` from the Vault's balance
		/// and returns a new Vault with the same token ID and
		/// the subtracted balance
		///
		access(all)
		fun withdraw(amount: UFix64): @{MultiFungibleToken.Vault}{ 
			pre{ 
				self.balance >= amount:
					"Amount withdrawn must be less than or equal than the balance of the Vault"
			}
			post{ 
				self.balance == before(self.balance) - amount:
					"New Vault balance must be the difference of the previous balance and the withdrawn Vault"
				result.balance == amount:
					"Withdrawal amount must be the same as the balance of the withdrawn Vault"
				self.tokenId == result.tokenId:
					"The withdrawn tokens must match the given token ID"
			}
		}
		
		/// deposit takes a Vault of the same token ID and adds its
		/// balance to the balance of this Vault
		///
		access(all)
		fun deposit(from: @{MultiFungibleToken.Vault}){ 
			pre{ 
				from.isInstance(self.getType()):
					"Cannot deposit an incompatible token type"
				from.tokenId == self.tokenId:
					"Cannot deposit a token of a different token ID"
			}
			post{ 
				self.balance == before(self.balance) + before(from.balance):
					"New Vault balance must be the sum of the previous balance and the deposited Vault"
			}
		}
	}
	
	// Interface that an account would commonly use to
	// organize and store all the published tokens
	///
	access(all)
	resource interface CollectionPublic{ 
		
		/// deposit stores the given vault into the collection
		/// or merges it into the vault of the same token ID in
		/// the collection if one exists
		///
		access(all)
		fun deposit(from: @{MultiFungibleToken.Vault})
		
		/// getTokenIds returns the token IDs of all vaults
		/// in the collection
		///
		access(all)
		view fun getTokenIds(): [UInt64]
		
		/// hasToken returns true iff the vault of the given
		/// token ID exists in the collection
		///
		access(all)
		view fun hasToken(tokenId: UInt64): Bool
		
		/// getPublicVault returns a restricted vault for
		/// public access, or throws an error if it doesn't
		/// have a vault of the requested token id
		///
		access(all)
		fun getPublicVault(tokenId: UInt64): &{Receiver, View}{ 
			pre{ 
				self.hasToken(tokenId: tokenId):
					"Vault of the given ID does not exist in the collection"
			}
		}
	}
	
	/// Requirement for the the concrete resource type
	/// to be declared in the implementing contract
	///
	access(all)
	resource interface Collection: Provider, Receiver, CollectionPublic{ 
		access(all)
		fun withdraw(tokenId: UInt64, amount: UFix64): @{MultiFungibleToken.Vault}
		
		access(all)
		fun deposit(from: @{MultiFungibleToken.Vault})
		
		access(all)
		view fun getTokenIds(): [UInt64]
		
		access(all)
		view fun hasToken(tokenId: UInt64): Bool
		
		access(all)
		fun getPublicVault(tokenId: UInt64): &{Receiver, View}
	}
	
	/// createEmptyCollection creates an empty Collection
	/// and returns it to the caller so that they can own NFTs
	///
	access(all)
	fun createEmptyCollection(): @{MultiFungibleToken.Collection}{ 
		post{ 
			result.getTokenIds().length == 0:
				"The created collection must be empty!"
		}
	}
	
	/// createEmptyVault allows any user to create a new Vault (of a valid token ID)
	/// that has a zero balance, or throws an error if the requested token id has
	/// not yet been initialized
	///
	access(all)
	fun createEmptyVault(tokenId: UInt64): @{MultiFungibleToken.Vault}{ 
		pre{ 
			self.getTotalSupply(tokenId: tokenId) != nil:
				"Token of the given token ID does not exist"
		}
		post{ 
			result.tokenId == tokenId:
				"The newly created Vault must have the requested token ID"
			result.balance == 0.0:
				"The newly created Vault must have zero balance"
		}
	}
	
	/// getTotalSupply returns the total supply of the token
	/// corresponds to the given token ID, or nil if the token
	/// does not exist
	///
	access(all)
	view fun getTotalSupply(tokenId: UInt64): UFix64?
}
