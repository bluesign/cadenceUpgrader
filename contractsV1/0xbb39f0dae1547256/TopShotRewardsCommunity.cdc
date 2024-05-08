import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FungibleTokenMetadataViews from "./../../standardsV1/FungibleTokenMetadataViews.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"

import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract TopShotRewardsCommunity: FungibleToken, ViewResolver{ 
	
	// The amount of tokens in existance
	access(all)
	var totalSupply: UFix64
	
	// nil if there is none
	access(all)
	let maxSupply: UFix64?
	
	// Paths
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let ReceiverPublicPath: PublicPath
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdministratorStoragePath: StoragePath
	
	// Events
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensTransferred(amount: UFix64, from: Address, to: Address)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, ViewResolver.Resolver{ 
		access(all)
		var balance: UFix64
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			if let owner: Address = self.owner?.address{ 
				TopShotRewardsCommunity.setBalance(address: owner, balance: self.balance)
			}
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault: @Vault <- from as! @Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			
			// We set the balance to 0.0 here so that it doesn't
			// decrease the totalSupply in the `destroy` function.
			vault.balance = 0.0
			destroy vault
			if let owner: Address = self.owner?.address{ 
				TopShotRewardsCommunity.setBalance(address: owner, balance: self.balance)
			}
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<FungibleTokenMetadataViews.FTView>():
					return TopShotRewardsCommunity.resolveView(view)
				case Type<FungibleTokenMetadataViews.FTDisplay>():
					return TopShotRewardsCommunity.resolveView(view)
				case Type<FungibleTokenMetadataViews.FTVaultData>():
					return TopShotRewardsCommunity.resolveView(view)
			}
			return nil
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
		
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Minter: Toucans.Minter{ 
		access(all)
		fun mint(amount: UFix64): @Vault{ 
			post{ 
				TopShotRewardsCommunity.maxSupply == nil || TopShotRewardsCommunity.totalSupply <= TopShotRewardsCommunity.maxSupply!:
					"Exceeded the max supply of tokens allowd."
			}
			TopShotRewardsCommunity.totalSupply = TopShotRewardsCommunity.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	// We follow this pattern of storage
	// so the (potentially) huge dictionary 
	// isn't loaded when the contract is imported
	access(all)
	resource Administrator{ 
		// This is an experimental index and should
		// not be used for anything official
		// or monetary related
		access(self)
		let balances:{ Address: UFix64}
		
		access(contract)
		fun setBalance(address: Address, balance: UFix64){ 
			self.balances[address] = balance
		}
		
		access(all)
		fun getBalance(address: Address): UFix64{ 
			return self.balances[address] ?? 0.0
		}
		
		access(all)
		fun getBalances():{ Address: UFix64}{ 
			return self.balances
		}
		
		init(){ 
			self.balances ={} 
		}
	}
	
	access(contract)
	fun setBalance(address: Address, balance: UFix64){ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		admin.setBalance(address: address, balance: balance)
	}
	
	access(all)
	fun getBalance(address: Address): UFix64{ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		return admin.getBalance(address: address)
	}
	
	access(all)
	fun getBalances():{ Address: UFix64}{ 
		let admin: &Administrator = self.account.storage.borrow<&Administrator>(from: self.AdministratorStoragePath)!
		return admin.getBalances()
	}
	
	access(all)
	fun getViews(): [Type]{ 
		return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>()]
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<FungibleTokenMetadataViews.FTView>():
				return FungibleTokenMetadataViews.FTView(ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?, ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?)
			case Type<FungibleTokenMetadataViews.FTDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreid5sova5e3aaratgc2lotv266thsf3xo5cssfj2npknq7wqdm77wq"), mediaType: "image")
				let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafybeidza2ubipfpilwfffjbp3dh2rzzaz5rbrtahoy4m4shtjf6oua7uu"), mediaType: "image")
				let medias = MetadataViews.Medias([media, bannerMedia])
				return FungibleTokenMetadataViews.FTDisplay(name: "Top Shot Rewards Community", symbol: "TSR", description: "A DAO for all the collectors of NBA Top Shot and beyond. We Rise together.", externalURL: MetadataViews.ExternalURL(""), logos: medias, socials:{ "twitter": MetadataViews.ExternalURL("TopShotRewards"), "discord": MetadataViews.ExternalURL("Eh5c8k2gUu")})
			case Type<FungibleTokenMetadataViews.FTVaultData>():
				return FungibleTokenMetadataViews.FTVaultData(storagePath: TopShotRewardsCommunity.VaultStoragePath, receiverPath: TopShotRewardsCommunity.ReceiverPublicPath, metadataPath: TopShotRewardsCommunity.VaultPublicPath, receiverLinkedType: /private/TopShotRewardsCommunityVault, metadataLinkedType: Type<&Vault>(), createEmptyVaultFunction: Type<&Vault>(), providerLinkedType: Type<&Vault>(), createEmptyVaultFunction: fun (): @Vault{ 
						return <-TopShotRewardsCommunity.createEmptyVault(vaultType: Type<@TopShotRewardsCommunity.Vault>())
					})
		}
		return nil
	}
	
	init(_paymentTokenInfo: ToucansTokens.TokenInfo, _editDelay: UFix64, _minting: Bool, _initialTreasurySupply: UFix64, _maxSupply: UFix64?, _extra:{ String: AnyStruct}){ 
		
		// Contract Variables
		self.totalSupply = 0.0
		self.maxSupply = _maxSupply
		
		// Paths
		self.VaultStoragePath = /storage/TopShotRewardsCommunityVault
		self.ReceiverPublicPath = /public/TopShotRewardsCommunityReceiver
		self.VaultPublicPath = /public/TopShotRewardsCommunityMetadata
		self.MinterStoragePath = /storage/TopShotRewardsCommunityMinter
		self.AdministratorStoragePath = /storage/TopShotRewardsCommunityAdmin
		
		// Admin Setup
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.VaultPublicPath)
		if self.account.storage.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath) == nil{ 
			self.account.storage.save(<-Toucans.createCollection(), to: Toucans.CollectionStoragePath)
			var capability_3 = self.account.capabilities.storage.issue<&Toucans.Collection>(Toucans.CollectionStoragePath)
			self.account.capabilities.publish(capability_3, at: Toucans.CollectionPublicPath)
		}
		let toucansProjectCollection = self.account.storage.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath)!
		toucansProjectCollection.createProject(projectTokenInfo: ToucansTokens.TokenInfo("TopShotRewardsCommunity", self.account.address, "TSR", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), paymentTokenInfo: _paymentTokenInfo, minter: <-create Minter(), editDelay: _editDelay, minting: _minting, initialTreasurySupply: _initialTreasurySupply, extra: _extra)
		self.account.storage.save(<-create Administrator(), to: self.AdministratorStoragePath)
		
		// Events
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
