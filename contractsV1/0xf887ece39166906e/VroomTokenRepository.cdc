// Testnet
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import VroomToken from "../0x6e9ac121d7106a09/VroomToken.cdc"

// Mainnet
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import VroomToken from 0xf887ece39166906e // Replace with actual address


access(all)
contract VroomTokenRepository{ 
	access(all)
	event TresorCreated(tresorId: UInt64, seller: Address, price: UFix64, amount: UFix64)
	
	access(all)
	event TokensPurchased(tresorId: UInt64, buyer: Address, price: UFix64, amount: UFix64)
	
	access(all)
	event TresorRemoved(tresorId: UInt64, seller: Address)
	
	access(all)
	let RepositoryStoragePath: StoragePath
	
	access(all)
	let RepositoryPublicPath: PublicPath
	
	access(all)
	var nextTresorId: UInt64
	
	access(all)
	struct TresorDetails{ 
		access(all)
		let tresorId: UInt64
		
		access(all)
		let seller: Address
		
		access(all)
		let price: UFix64
		
		access(all)
		let amount: UFix64
		
		init(tresorId: UInt64, seller: Address, price: UFix64, amount: UFix64){ 
			self.tresorId = tresorId
			self.seller = seller
			self.price = price
			self.amount = amount
		}
	}
	
	access(all)
	resource interface TresorPublic{ 
		access(all)
		fun transferAndRemoveTresor(
			buyerVaultRef: &{FungibleToken.Receiver},
			repositoryRef: &VroomTokenRepository.Repository
		)
		
		//		pub fun purchaseTokens(tresorId: UInt64, buyer: AuthAccount, paymentVault: @FungibleToken.Vault)
		access(all)
		fun transferTokens(buyerVaultRef: &{FungibleToken.Receiver})
		
		access(all)
		fun getDetails(): TresorDetails
	}
	
	access(all)
	resource Tresor: TresorPublic{ 
		access(all)
		let details: TresorDetails
		
		access(all)
		let seller: Address
		
		access(all)
		let price: UFix64
		
		access(all)
		let amount: UFix64
		
		access(all)
		var tokenVault: @{FungibleToken.Vault}
		
		access(all)
		fun getDetails(): TresorDetails{ 
			return self.details
		}
		
		// This method allows the transfer of tokens to a buyer's vault
		access(all)
		fun transferTokens(buyerVaultRef: &{FungibleToken.Receiver}){ 
			let amount = self.amount
			let tokens <- self.tokenVault.withdraw(amount: amount)
			buyerVaultRef.deposit(from: <-tokens)
		}
		
		// New function to handle the transfer and removal
		access(all)
		fun transferAndRemoveTresor(buyerVaultRef: &{FungibleToken.Receiver}, repositoryRef: &VroomTokenRepository.Repository){ 
			// Transfer tokens
			let amount = self.amount
			let tokens <- self.tokenVault.withdraw(amount: amount)
			buyerVaultRef.deposit(from: <-tokens)
			
			// Remove the Tresor from the repository, triggering destruction
			repositoryRef.removeTresor(signer: self.getDetails().seller, tresorId: self.getDetails().tresorId)
		//	emit TokensPurchased(tresorId: self.getDetails().tresorId, buyer: buyer.address, price: tresor.price, amount: tresor.amount)
		}
		
		init(_seller: Address, _price: UFix64, _amount: UFix64, _vault: @{FungibleToken.Vault}, _tresorId: UInt64){ 
			self.seller = _seller
			self.price = _price
			self.amount = _amount
			self.tokenVault <- _vault
			self.details = TresorDetails(tresorId: _tresorId, seller: _seller, price: _price, amount: _amount)
		}
	}
	
	access(all)
	resource interface RepositoryManager{ 
		access(all)
		fun purchaseTokens(
			tresorId: UInt64,
			buyer: AuthAccount,
			paymentVault: @{FungibleToken.Vault}
		)
		
		access(all)
		fun createTresor(signer: AuthAccount, price: UFix64, amount: UFix64): UInt64
		
		access(all)
		fun removeTresor(signer: Address, tresorId: UInt64)
	}
	
	access(all)
	resource interface RepositoryPublic{ 
		access(all)
		fun removeTresor(signer: Address, tresorId: UInt64)
		
		access(all)
		fun getTresorIDs(): [UInt64]
		
		//		pub fun getTresorDetails(tresorId: UInt64): TresorDetails
		access(all)
		fun borrowTresor(tresorResourceID: UInt64): &Tresor?
	}
	
	access(all)
	resource Repository: RepositoryManager, RepositoryPublic{ 
		access(all)
		var tresors: @{UInt64: Tresor}
		
		//A resource with the form of Tresor is created in the createTResor function
		// and moved to the tresors dictionary with the current index
		// When the purchase tokens function is called the resource is moved from that index
		// and the tokens are deposited into the buyers VroomTokenStorage
		// Function to purchase VroomTokens
		access(all)
		fun purchaseTokens(tresorId: UInt64, buyer: AuthAccount, paymentVault: @{FungibleToken.Vault}){ 
			let tresor <- self.tresors.remove(key: tresorId) ?? panic("Tresor does not exist.")
			let seller = getAccount(tresor.seller)
			
			// Ensure the paymentVault is a Flow token vault and deposit Flow tokens into the seller's vault
			let receiver = seller.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() ?? panic("Could not borrow receiver reference to the seller's Flow token vault")
			receiver.deposit(from: <-paymentVault)
			
			// Ensure the buyer has a VroomToken receiver and transfer VroomTokens from the tresor to the buyer
			let buyerReceiver = buyer.getCapability<&{FungibleToken.Receiver}>(VroomToken.VaultReceiverPath).borrow() ?? panic("Could not borrow receiver reference to the buyer's VroomToken vault")
			tresor.transferTokens(buyerVaultRef: buyerReceiver)
			emit TokensPurchased(tresorId: tresorId, buyer: buyer.address, price: tresor.price, amount: tresor.amount)
			destroy tresor
		}
		
		// Function to list VroomTokens for sale
		access(all)
		fun createTresor(signer: AuthAccount, price: UFix64, amount: UFix64): UInt64{ 
			let vaultRef = signer.borrow<&VroomToken.Vault>(from: VroomToken.VaultStoragePath) ?? panic("Could not borrow reference to the VroomToken vault")
			let tokens <- vaultRef.withdraw(amount: amount)
			
			// Use the contract-level nextTresorId for uniqueness
			let tresorId = VroomTokenRepository.nextTresorId
			VroomTokenRepository.nextTresorId = VroomTokenRepository.nextTresorId + 1
			let tresor <- create Tresor(_seller: signer.address, _price: price, _amount: amount, _vault: <-tokens, _tresorId: tresorId)
			self.tresors[tresorId] <-! tresor
			emit TresorCreated(tresorId: tresorId, seller: signer.address, price: price, amount: amount)
			return tresorId
		}
		
		// Function to remove a tresor
		access(all)
		fun removeTresor(signer: Address, tresorId: UInt64){ 
			let tresor <- self.tresors.remove(key: tresorId) ?? panic("Tresor does not exist.")
			
			// assert(tresor.seller == signer.address, message: "Only the seller can remove the tresor")
			emit TresorRemoved(tresorId: tresorId, seller: signer)
			destroy tresor
		}
		
		// This function works for this contract, the problem with this contract
		// is that we can't use the purchase function, because even though the 
		// IDs exist, the Tresor resource for some reason can't find them???
		access(all)
		fun getTresorIDs(): [UInt64]{ 
			return self.tresors.keys
		}
		
		access(all)
		fun borrowTresor(tresorResourceID: UInt64): &Tresor?{ 
			if self.tresors[tresorResourceID] != nil{ 
				return &self.tresors[tresorResourceID] as &Tresor?
			} else{ 
				return nil
			}
		}
		
		// Destructor to clean up the tresors dictionary
		init(){ 
			self.tresors <-{} 
		}
	}
	
	//		// Function to get details of all tresors
	//	pub fun getAllTresorDetails(): [TresorDetails] {
	//		let detailsArray: [TresorDetails] = []
	//		for tresor in self.tresors.values {
	//			detailsArray.append(tresor.getDetails())
	//		}
	//		return detailsArray
	//	}
	access(all)
	fun createRepository(): @Repository{ 
		return <-create Repository()
	}
	
	init(){ 
		self.RepositoryStoragePath = /storage/VroomTokenRepository
		self.RepositoryPublicPath = /public/VroomTokenRepository
		self.nextTresorId = 1
	}
}
