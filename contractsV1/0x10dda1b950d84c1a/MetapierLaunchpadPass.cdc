import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

/**

A Metapier launchpad pass is designed to help with identity verification so 
that we know funds are withdrawn from a whitelisted account, and we can also
ensure launch tokens are distributed to the same account.

Since launch pool will perform the whitelist check, anyone can mint a pass
to try to participate.

 */

access(all)
contract MetapierLaunchpadPass: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event PassMinted(id: UInt64, _for: Address)
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	resource interface PublicPass{ 
		// the owner of the collection that the pass is initially deposited into
		access(all)
		let originalOwner: Address
		
		// the type of the funds vault used by this pass
		access(all)
		let fundsType: Type
		
		// the type of the launch token vault used by this pass
		access(all)
		let launchTokenType: Type
		
		access(all)
		fun getFundsBalance(): UFix64
		
		access(all)
		fun getLaunchTokenBalance(): UFix64
		
		access(all)
		fun depositFunds(vault: @{FungibleToken.Vault})
		
		access(all)
		fun depositLaunchToken(vault: @{FungibleToken.Vault})
	}
	
	access(all)
	resource interface PrivatePass{ 
		access(all)
		fun withdrawFunds(amount: UFix64): @{FungibleToken.Vault}
		
		access(all)
		fun withdrawLaunchToken(amount: UFix64): @{FungibleToken.Vault}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, PublicPass, PrivatePass{ 
		access(all)
		let id: UInt64
		
		access(all)
		let originalOwner: Address
		
		access(all)
		let fundsType: Type
		
		access(all)
		let launchTokenType: Type
		
		access(self)
		let fundsVault: @{FungibleToken.Vault}
		
		access(self)
		let launchTokenVault: @{FungibleToken.Vault}
		
		init(initID: UInt64, originalOwner: Address, fundsVault: @{FungibleToken.Vault}, launchTokenVault: @{FungibleToken.Vault}){ 
			self.id = initID
			self.originalOwner = originalOwner
			self.fundsType = fundsVault.getType()
			self.fundsVault <- fundsVault
			self.launchTokenType = launchTokenVault.getType()
			self.launchTokenVault <- launchTokenVault
		}
		
		access(all)
		fun getFundsBalance(): UFix64{ 
			return self.fundsVault.balance
		}
		
		access(all)
		fun getLaunchTokenBalance(): UFix64{ 
			return self.launchTokenVault.balance
		}
		
		access(all)
		fun depositFunds(vault: @{FungibleToken.Vault}){ 
			self.fundsVault.deposit(from: <-vault)
		}
		
		access(all)
		fun depositLaunchToken(vault: @{FungibleToken.Vault}){ 
			self.launchTokenVault.deposit(from: <-vault)
		}
		
		access(all)
		fun withdrawFunds(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.fundsVault.withdraw(amount: amount)
		}
		
		access(all)
		fun withdrawLaunchToken(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.launchTokenVault.withdraw(amount: amount)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		fun borrowPublicPass(id: UInt64): &MetapierLaunchpadPass.NFT
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(all)
		fun borrowPrivatePass(id: UInt64): &MetapierLaunchpadPass.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, CollectionPrivate{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// make sure the token has the right type
			let token <- token as! @MetapierLaunchpadPass.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary with a force assignment
			// if there is already a value at that key, it will fail and revert
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowPublicPass(id: UInt64): &MetapierLaunchpadPass.NFT{ 
			let passRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let intermediateRef = passRef as! &MetapierLaunchpadPass.NFT
			return intermediateRef as &MetapierLaunchpadPass.NFT
		}
		
		access(all)
		fun borrowPrivatePass(id: UInt64): &MetapierLaunchpadPass.NFT{ 
			let passRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return passRef as! &MetapierLaunchpadPass.NFT
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// anyone can create a new pass to try participating a launch pool
	access(all)
	fun mintNewPass(recipient: Capability<&{NonFungibleToken.CollectionPublic}>, fundsVault: @{FungibleToken.Vault}, launchTokenVault: @{FungibleToken.Vault}): UInt64{ 
		let newPass <- create NFT(initID: MetapierLaunchpadPass.totalSupply, // id never repeats																			 
																			 originalOwner: recipient.address, fundsVault: <-fundsVault, launchTokenVault: <-launchTokenVault)
		let newPassId = newPass.id
		MetapierLaunchpadPass.totalSupply = MetapierLaunchpadPass.totalSupply + 1
		emit PassMinted(id: newPassId, _for: recipient.address)
		(		 
		 // save this pass into the recipient's collection
		 recipient.borrow()!).deposit(token: <-newPass)
		return newPassId
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/MetapierLaunchpadPassCollection
		self.CollectionPublicPath = /public/MetapierLaunchpadPassCollection
		emit ContractInitialized()
	}
}
