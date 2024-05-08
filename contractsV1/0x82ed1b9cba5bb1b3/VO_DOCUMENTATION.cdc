/*
 * Copyright (c) 2021 24Karat. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * This file is part of Project: 24karat flow contract (https://github.com/24karat-io/flow-contract)
 *
 * This source code is licensed under the MIT License found in the
 * LICENSE file in the root directory of this source tree or at
 * https://opensource.org/licenses/MIT.
 */

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract VO_DOCUMENTATION: FungibleToken{ 
	// TokensInitialized
	//
	// The event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// TokensWithdrawn
	//
	// The event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// TokensDeposited
	//
	// The event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// TokensMinted
	//
	// The event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	// TokensBurned
	//
	// The event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	// MinterCreated
	//
	// The event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	// Named paths
	//
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	access(all)
	let BalancePublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Total supply of token in existence
	access(all)
	var totalSupply: UFix64
	
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
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		// The total balance of this vault
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		// withdraw
		//
		// Function that takes an amount as an argument
		// and withdraws that amount from the Vault.
		//
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		//
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		// deposit
		//
		// Function that takes a Vault object as an argument and adds
		// its balance to the balance of the owners Vault.
		//
		// It is allowed to destroy the sent Vault because the Vault
		// was a temporary holder of the tokens. The Vault's balance has
		// been consumed and therefore can be destroyed.
		//
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @VO_DOCUMENTATION.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
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
	
	access(all)
	resource Administrator{ 
		
		// createNewMinter
		//
		// Function that creates and returns a new minter resource
		//
		access(all)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
	}
	
	// Minter
	//
	// Resource object that token admin accounts can hold to mint new tokens.
	//
	access(all)
	resource Minter{ 
		
		// The amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		// mintTokens
		//
		// Function that mints new tokens, adds them to the total supply,
		// and returns them to the calling context.
		//
		access(all)
		fun mintTokens(amount: UFix64): @VO_DOCUMENTATION.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			VO_DOCUMENTATION.totalSupply = VO_DOCUMENTATION.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	init(){ 
		// Set our named paths.
		self.VaultStoragePath = /storage/VO_DOCUMENTATIONVault
		self.ReceiverPublicPath = /public/VO_DOCUMENTATIONReceiver
		self.BalancePublicPath = /public/VO_DOCUMENTATIONBalance
		self.AdminStoragePath = /storage/VO_DOCUMENTATIONAdmin
		
		// Initialize contract state.
		self.totalSupply = 0.0
		
		// Create the one true Admin object and deposit it into the conttract account.
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Emit an event that shows that the contract was initialized.
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
