import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract JoyrideMultiToken{ 
	// Always 0. This is not really a Token
	access(all)
	var totalSupply: UFix64
	
	// Defines paths for user accounts
	access(all)
	let UserStoragePath: StoragePath
	
	access(all)
	let UserPublicPath: PublicPath
	
	access(all)
	let UserPrivatePath: PrivatePath
	
	// Defines token vault storage paths
	access(contract)
	let TokenStoragePaths:{ UInt8: StoragePath}
	
	// Defines token vault public paths
	access(contract)
	let TokenPublicPaths:{ UInt8: PublicPath}
	
	/// TokensInitialized
	///
	/// The event that is emitted when the contract is created
	///
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event JoyrideMultiTokenInfoEvent(notes: String)
	
	/// TokensWithdrawn
	///
	/// The event that is emitted when tokens are withdrawn from a Vault
	///
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// TokensDeposited
	///
	/// The event that is emitted when tokens are deposited into a Vault
	///
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	enum Vaults: UInt8{ 
		access(all)
		case treasury
		
		access(all)
		case reserve
	}
	
	access(all)
	resource interface Receiver{ 
		access(all)
		fun depositToken(from: @{FungibleToken.Vault})
		
		access(all)
		fun balanceOf(tokenContext: String): UFix64
	}
	
	access(all)
	resource Vault: Receiver{ 
		access(all)
		let Depositories:{ String: Capability<&{FungibleToken.Vault}>}
		
		init(zero: UFix64){ 
			self.Depositories ={} 
		}
		
		/*pub fun deposit(from: @FungibleToken.Vault) {
					let mtv <- from as! @JoyrideMultiToken.Vault
					for vaultKey in mtv.Depositories.keys {
						let vault = mtv.Depositories[vaultKey]!.borrow() ??
							panic("unable to borow capability")
						self.depositToken(from: <- vault.withdraw(amount: vault.balance))
					}
					destroy mtv
				}*/
		
		access(all)
		fun depositToken(from: @{FungibleToken.Vault}){ 
			let tokenIdetifier: String = from.getType().identifier
			emit JoyrideMultiTokenInfoEvent(notes: "depositToken for user".concat(tokenIdetifier))
			let vault = self.Depositories[tokenIdetifier] ?? panic("unable to borrow capability depositToken")
			let capability = vault.borrow() ?? panic("unable to get vault capability")
			capability.deposit(from: <-from)
		}
		
		access(all)
		fun withdrawToken(tokenContext: String, amount: UFix64): @{FungibleToken.Vault}{ 
			//let tokenIdentifier: String = tokenContext.identifier
			let vault = self.Depositories[tokenContext]?.borrow() ?? panic("unable to borrow capability withdraw")
			return <-(vault!).withdraw(amount: amount)
		}
		
		access(all)
		fun registerCapability(tokenIdentifier: String, capability: Capability<&{FungibleToken.Vault}>){ 
			//let tokenIdentifier: String = capability.borrow()!.getType().identifier;
			emit JoyrideMultiTokenInfoEvent(notes: "registerCapability".concat(tokenIdentifier))
			self.Depositories[tokenIdentifier] = capability
		}
		
		access(all)
		fun doesCapabilityExists(tokenIdentifier: String): Bool{ 
			return self.Depositories.containsKey(tokenIdentifier)
		}
		
		access(all)
		fun balanceOf(tokenContext: String): UFix64{ 
			//let tokenIdentifier: String = tokenContext.identifier
			let vault = self.Depositories[tokenContext]?.borrow() ?? panic("Token tokenContext Unknown")
			emit JoyrideMultiTokenInfoEvent(notes: (vault!).getType().identifier)
			return (vault!).balance
		}
	}
	
	access(all)
	fun createEmptyVault(): @Vault{ 
		return <-create Vault(zero: 0.0)
	}
	
	access(contract)
	fun getPlatformBalance(vault: Vaults, tokenContext: String): UFix64{ 
		return self.account.storage.borrow<&Vault>(from: self.TokenStoragePaths[vault.rawValue]!)
			?.balanceOf(tokenContext: tokenContext)
		?? 0.0
	}
	
	access(contract)
	fun doPlatformWithdraw(vault: Vaults, tokenContext: String, amount: UFix64): @{
		FungibleToken.Vault
	}?{ 
		let path = self.TokenStoragePaths[vault.rawValue]
		emit JoyrideMultiTokenInfoEvent(notes: "vault Index".concat(vault.rawValue.toString()))
		if path == nil{ 
			return nil
		}
		let vault = self.account.storage.borrow<&Vault>(from: path!)
		if vault == nil{ 
			return nil
		}
		if (vault!).balanceOf(tokenContext: tokenContext) < amount{ 
			return nil
		}
		return <-(vault!).withdrawToken(tokenContext: tokenContext, amount: amount)
	}
	
	access(contract)
	fun doPlatformDeposit(vault: Vaults, from: @{FungibleToken.Vault}){ 
		(self.account.storage.borrow<&Vault>(from: self.TokenStoragePaths[vault.rawValue]!)!)
			.depositToken(from: <-from)
	}
	
	access(all)
	resource interface PlatformBalance{ 
		access(all)
		fun balance(vault: Vaults, tokenContext: String): UFix64
	}
	
	access(all)
	resource interface PlatformWithdraw{ 
		access(all)
		fun withdraw(vault: Vaults, tokenContext: String, amount: UFix64, purpose: String): @{
			FungibleToken.Vault
		}?
	}
	
	access(all)
	resource interface PlatformDeposit{ 
		access(all)
		fun deposit(vault: Vaults, from: @{FungibleToken.Vault})
	}
	
	access(all)
	resource PlatformAdmin: PlatformBalance, PlatformWithdraw, PlatformDeposit{ 
		access(all)
		fun balance(vault: Vaults, tokenContext: String): UFix64{ 
			return JoyrideMultiToken.getPlatformBalance(vault: vault, tokenContext: tokenContext)
		}
		
		access(all)
		fun withdraw(vault: Vaults, tokenContext: String, amount: UFix64, purpose: String): @{FungibleToken.Vault}?{ 
			return <-JoyrideMultiToken.doPlatformWithdraw(vault: vault, tokenContext: tokenContext, amount: amount)
		}
		
		access(all)
		fun deposit(vault: Vaults, from: @{FungibleToken.Vault}){ 
			JoyrideMultiToken.doPlatformDeposit(vault: vault, from: <-from)
		}
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.TokenStoragePaths ={} 
		self.TokenPublicPaths ={} 
		self.TokenStoragePaths[
			Vaults.treasury.rawValue
		] = /storage/JoyrideMultiToken_PlatformTreasury
		self.TokenPublicPaths[Vaults.treasury.rawValue] = /public/JoyrideMultiToken_PlatformTreasury
		self.TokenStoragePaths[Vaults.reserve.rawValue] = /storage/JoyrideMultiToken_PlatformReserve
		self.TokenPublicPaths[Vaults.reserve.rawValue] = /public/JoyrideMultiToken_PlatformReserve
		self.UserStoragePath = /storage/JoyrideMultiToken
		self.UserPublicPath = /public/JoyrideMultiToken
		self.UserPrivatePath = /private/JoyrideMultiToken
		let treasury <- self.createEmptyVault()
		self.account.storage.save(<-treasury, to: self.TokenStoragePaths[Vaults.treasury.rawValue]!)
		var capability_1 =
			self.account.capabilities.storage.issue<
				&{FungibleToken.Receiver, FungibleToken.Balance}
			>(self.TokenStoragePaths[Vaults.treasury.rawValue]!)
		self.account.capabilities.publish(
			capability_1,
			at: self.TokenPublicPaths[Vaults.treasury.rawValue]!
		)
		let reserve <- self.createEmptyVault()
		self.account.storage.save(<-reserve, to: self.TokenStoragePaths[Vaults.reserve.rawValue]!)
		var capability_2 =
			self.account.capabilities.storage.issue<
				&{FungibleToken.Receiver, FungibleToken.Balance}
			>(self.TokenStoragePaths[Vaults.reserve.rawValue]!)
		self.account.capabilities.publish(
			capability_2,
			at: self.TokenPublicPaths[Vaults.reserve.rawValue]!
		)
		let platformAdmin <- create PlatformAdmin()
		self.account.storage.save(<-platformAdmin, to: /storage/JoyrideMultiToken_PlatformAdmin)
		var capability_3 =
			self.account.capabilities.storage.issue<&JoyrideMultiToken.PlatformAdmin>(
				/storage/JoyrideMultiToken_PlatformAdmin
			)
		self.account.capabilities.publish(
			capability_3,
			at: /private/JoyrideMultiToken_PlatformAdmin
		)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
	
	access(all)
	struct TokenContextModel{ 
		access(all)
		var Symbol: String
		
		access(all)
		var TokenName: String
		
		access(all)
		var VaultName: String
		
		access(all)
		var FullAddress: String
		
		access(all)
		var TokenAddress: Address
		
		access(all)
		var StoragePath: String
		
		access(all)
		var BalancePath: String
		
		access(all)
		var ReceiverPath: String
		
		access(all)
		var PrivatePath: String
		
		init(
			Symbol: String,
			TokenName: String,
			VaultName: String,
			FullAddress: String,
			TokenAddress: Address,
			StoragePath: String,
			BalancePath: String,
			ReceiverPath: String,
			PrivatePath: String
		){ 
			self.Symbol = Symbol
			self.TokenName = TokenName
			self.VaultName = VaultName
			self.FullAddress = FullAddress
			self.TokenAddress = TokenAddress
			self.StoragePath = StoragePath
			self.BalancePath = BalancePath
			self.ReceiverPath = ReceiverPath
			self.PrivatePath = PrivatePath
		}
	}
}
