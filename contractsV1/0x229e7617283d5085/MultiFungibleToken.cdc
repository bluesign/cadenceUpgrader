import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

//import MetadataViews from 0x8ea44ab931cac762 // Only used for initializing MultiFungibleTokenReceiverPath
// Supported FungibleTokens
import FUSD from "./../../standardsV1/FUSD.cdc"

access(all)
contract MultiFungibleToken{ 
	// Events ---------------------------------------------------------------------------------
	access(all)
	event CreateNewWallet(user: Address, type: Type, amount: UFix64)
	
	// Paths  ---------------------------------------------------------------------------------
	access(all)
	let MultiFungibleTokenReceiverPath: PublicPath
	
	access(all)
	let MultiFungibleTokenBalancePath: PublicPath
	
	access(all)
	let MultiFungibleTokenStoragePath: StoragePath
	
	//Structs ---------------------------------------------------------------------------------
	access(all)
	struct FungibleTokenVaultInfo{ // Fungible Token Vault Basic Information, unique to each FT 
		
		access(all)
		let type: Type
		
		access(all)
		let identifier: String
		
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		init(type: Type, identifier: String, publicPath: PublicPath, storagePath: StoragePath){ 
			self.type = type
			self.identifier = identifier
			self.publicPath = publicPath
			self.storagePath = storagePath
		}
	}
	
	// Interfaces ---------------------------------------------------------------------------------
	access(all)
	resource interface MultiFungibleTokenBalance{ // An interface to get all the balances in storage 
		
		access(all)
		fun getStorageBalances():{ String: UFix64}
	}
	
	// Resources ---------------------------------------------------------------------------------
	access(all)
	resource MultiFungibleTokenManager: FungibleToken.Receiver, MultiFungibleTokenBalance{ 
		access(contract)
		var storage: @{String:{ FungibleToken.Vault}}
		
		init(){ 
			self.storage <-{} 
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ // deposit takes a Vault and deposits it into the implementing resource type 
			
			let type = from.getType()
			let identifier = type.identifier
			let balance = from.balance
			let ftInfo = MultiFungibleToken.getFungibleTokenInfo(type)
			if ftInfo == nil{ 
				self.storeDeposit(<-from)
				emit CreateNewWallet(user: (self.owner!).address, type: type, amount: balance)
				return
			}
			let ref = ((self.owner!).capabilities.get<&{FungibleToken.Receiver}>((ftInfo!).publicPath!)!).borrow() // Get a reference to the recipient's Receiver
			
			if ref == nil{ 
				self.storeDeposit(<-from)
				emit CreateNewWallet(user: (self.owner!).address, type: type, amount: balance)
				return
			}
			(ref!).deposit(from: <-from) // Deposit the withdrawn tokens in the recipient's receiver
		
		}
		
		access(self)
		fun storeDeposit(_ from: @{FungibleToken.Vault}){ 
			let type = from.getType()
			let identifier = type.identifier
			if !self.storage.containsKey(identifier){ 
				let old <- self.storage.insert(key: identifier, <-from)
				destroy old
			} else{ 
				let ref = &self.storage[identifier] as &{FungibleToken.Vault}?
				(ref!).deposit(from: <-from)
			}
		}
		
		access(contract)
		fun removeDeposit(_ identifier: String): @{FungibleToken.Vault}{ 
			pre{ 
				self.storage.containsKey(identifier):
					"Incorrent identifier: ".concat(identifier)
			}
			post{ 
				!self.storage.containsKey(identifier):
					"Illegal Operation: removeDeposit, identifier: ".concat(identifier)
			}
			return <-self.storage.remove(key: identifier)!
		}
		
		access(all)
		fun getStorageBalances():{ String: UFix64}{ 
			var balances:{ String: UFix64} ={} 
			for coin in self.storage.keys{ 
				let ref = &self.storage[coin] as &{FungibleToken.Vault}?
				let balance = ref?.balance!
				balances.insert(key: coin, balance)
			}
			return balances
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	// Contract Functions ---------------------------------------------------------------------------------
	access(all)
	fun createEmptyMultiFungibleTokenReceiver(): @MultiFungibleTokenManager{ 
		return <-create MultiFungibleTokenManager()
	}
	
	access(all)
	fun createMissingWalletsAndDeposit(_ owner: AuthAccount, _ mft: &MultiFungibleTokenManager){ 
		for identifier in mft.storage.keys{ 
			let ref = mft.storage[identifier] as &{FungibleToken.Vault}?
			let type = (ref!).getType()
			let ftInfo = MultiFungibleToken.getFungibleTokenInfo(type)
			if ftInfo == nil{ 
				continue
			}
			switch identifier{ 
				case "A.3c5959b568896393.FUSD.Vault":
					if owner.borrow<&FUSD.Vault>(from: (ftInfo!).storagePath) == nil{ 
						owner.save(<-FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>()), to: (ftInfo!).storagePath)
						owner.link<&FUSD.Vault>((ftInfo!).publicPath, target: (ftInfo!).storagePath)
					}
			/*case "A.0f9df91c9121c460.BloctoToken.Vault":
								if owner.borrow<&BloctoToken.Vault{FungibleToken.Receiver}>(from: ftInfo!.storagePath) == nil {
										owner.save(<-BloctoToken.createEmptyVault(), to: ftInfo!.storagePath)
										owner.link<&BloctoToken.Vault{FungibleToken.Receiver}>(ftInfo!.publicPath, target: ftInfo!.storagePath)
								}*/
			
			}
			self.depositCoins(mft, identifier)
		}
	}
	
	access(self)
	fun depositCoins(_ mft: &MultiFungibleTokenManager, _ identifier: String){ 
		let coins <- mft.removeDeposit(identifier)
		mft.deposit(from: <-coins)
	}
	
	access(contract)
	fun getFungibleTokenInfo(_ type: Type): FungibleTokenVaultInfo?{ 
		let identifier = type.identifier
		var publicPath: PublicPath? = nil
		var storagePath: StoragePath? = nil
		switch identifier{ 
			/* FUSD   */
			case "A.3c5959b568896393.FUSD.Vault":
				publicPath = /public/fusdReceiver
				storagePath = /storage/fusdVault
		//* BloctoToken */ case "A.0f9df91c9121c460.BloctoToken.Vault" : publicPath = /public/; storagePath = /storage/
		}
		return publicPath != nil && storagePath != nil
			? FungibleTokenVaultInfo(
					type: type,
					identifier: identifier,
					publicPath: publicPath!,
					storagePath: storagePath!
				)
			: nil
	}
	
	// Contract Init ---------------------------------------------------------------------------------
	init(){ 
		self.MultiFungibleTokenReceiverPath = /public/GenericFTReceiver // taken from MetadataViews
		
		self.MultiFungibleTokenStoragePath = /storage/MultiFungibleTokenManager
		self.MultiFungibleTokenBalancePath = /public/MultiFungibleTokenBalance
	}
}
