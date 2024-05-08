// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheToken: FungibleToken{ 
	
	// 属性
	access(all)
	var totalSupply: UFix64
	
	access(all)
	let max_totalSupply: UFix64
	
	access(all)
	var pairAddress: Address
	
	access(all)
	var burnAddress: Address
	
	access(all)
	var burnPer: UFix64
	
	access(all)
	let adminPath: StoragePath
	
	access(all)
	let minerPath: StoragePath
	
	access(all)
	let vaultPath: StoragePath
	
	access(all)
	let receiverPath: PublicPath
	
	access(all)
	let balancePath: PublicPath
	
	// 事件
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	access(all)
	event PairAddressChanged(pair: Address)
	
	access(all)
	event BurnAddressChanged(pair: Address)
	
	access(all)
	event BurnPerChanged(per: UFix64)
	
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	access(all)
	event TokensMinted(amount: UFix64)
	
	access(all)
	event TokensBurned(amount: UFix64)
	
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	access(all)
	event BurnerCreated()
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @TheToken.Vault
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
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		access(all)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
		
		access(all)
		fun changePairAddress(pair: Address){ 
			TheToken.pairAddress = pair
			emit PairAddressChanged(pair: pair)
		}
		
		access(all)
		fun changeBurnAddress(burn: Address){ 
			TheToken.burnAddress = burn
			emit BurnAddressChanged(pair: burn)
		}
		
		access(all)
		fun changeBurnPer(per: UFix64){ 
			TheToken.burnPer = per
			emit BurnPerChanged(per: per)
		}
	}
	
	access(all)
	resource Minter{ 
		access(all)
		var allowedAmount: UFix64
		
		access(all)
		fun mintTokens(amount: UFix64): @TheToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			post{ 
				TheToken.totalSupply <= TheToken.max_totalSupply:
					"TotalSupply must less than Max_totalSupply"
			}
			TheToken.totalSupply = TheToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	access(all)
	resource Burner{ 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @TheToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	init(){ 
		
		// 初始化一些属性
		self.totalSupply = 0.0
		self.max_totalSupply = 100.0
		self.adminPath = /storage/TheTokenAdmin
		self.minerPath = /storage/TheTokenMiner
		self.vaultPath = /storage/TheTokenVault
		self.receiverPath = /public/TheTokenReceiver
		self.balancePath = /public/TheTokenBalance
		self.pairAddress = self.account.address
		self.burnAddress = self.account.address
		self.burnPer = 0.01
		
		// 创建管理员
		let admin <- create Administrator()
		
		// 创建矿工
		let miner <- admin.createNewMinter(allowedAmount: self.max_totalSupply)
		
		// 把存款操作暴露给大家
		var capability_1 = self.account.capabilities.storage.issue<&TheToken.Vault>(self.vaultPath)
		self.account.capabilities.publish(capability_1, at: self.receiverPath)
		
		// 把余额暴露给大家
		var capability_2 = self.account.capabilities.storage.issue<&TheToken.Vault>(self.vaultPath)
		self.account.capabilities.publish(capability_2, at: self.balancePath)
		self.account.storage.save(<-admin, to: self.adminPath)
		self.account.storage.save(<-miner, to: self.minerPath)
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
