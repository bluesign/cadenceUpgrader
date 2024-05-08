import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import JoyrideMultiToken from "./JoyrideMultiToken.cdc"

import JoyrideAccounts from "./JoyrideAccounts.cdc"

import GameEscrowMarker from "./GameEscrowMarker.cdc"

access(all)
contract JoyridePayments{ 
	access(contract)
	var accountsCapability: Capability<&{JoyrideAccounts.GrantsTokenRewards, JoyrideAccounts.SharesProfits, JoyrideAccounts.PlayerAccounts}>?
	
	access(contract)
	var treasuryCapability: Capability<&JoyrideMultiToken.PlatformAdmin>?
	
	access(contract)
	let authorizedBackendAccounts:{ Address: Bool}
	
	access(contract)
	let transactionStore:{ String:{ String: Bool}}
	
	access(all)
	event DebitTransactionCreate(
		playerID: String,
		txID: String,
		tokenContext: String,
		amount: UFix64,
		gameID: String,
		notes: String
	)
	
	access(all)
	event CreditTransactionCreate(
		playerID: String,
		txID: String,
		tokenContext: String,
		amount: UFix64,
		gameID: String,
		notes: String
	)
	
	access(all)
	event DebitTransactionReverted(
		playerID: String,
		txID: String,
		tokenContext: String,
		amount: UFix64,
		gameID: String
	)
	
	access(all)
	event DebitTransactionFinalized(
		playerID: String,
		txID: String,
		tokenContext: String,
		amount: UFix64,
		gameID: String,
		profit: UFix64
	)
	
	access(all)
	event TxFailed_DuplicateTxID(txID: String, notes: String)
	
	access(all)
	event TxFailed_ByTxTypeAndTxID(txID: String, txType: String, notes: String)
	
	init(){ 
		self.accountsCapability = nil
		self.treasuryCapability = nil
		self.authorizedBackendAccounts ={} 
		self.transactionStore ={} 
		let p2eAdmin <- create PaymentsAdmin()
		self.account.storage.save(<-p2eAdmin, to: /storage/PaymentsAdmin)
		var capability_1 =
			self.account.capabilities.storage.issue<&PaymentsAdmin>(/storage/PaymentsAdmin)
		self.account.capabilities.publish(capability_1, at: /private/PaymentsAdmin)
	}
	
	//Pretty sure this is safe to be public, since a valid Capability<&JRXToken.AdminVault.{JRXToken.ConvertsRewards}> can only be created by the JRXToken contract account.
	access(all)
	fun linkAccountsCapability(
		accountsCapability: Capability<&JoyrideAccounts.JoyrideAccountsAdmin>
	){ 
		if !accountsCapability.check(){ 
			panic("Capability from Invalid Source")
		}
		self.accountsCapability = accountsCapability
	}
	
	//Pretty sure this is safe to be public, since a valid Capability<&JRXToken.AdminVault.{JRXToken.ConvertsRewards}> can only be created by the JRXToken contract account.
	access(all)
	fun linkTreasuryCapability(treasuryCapability: Capability<&JoyrideMultiToken.PlatformAdmin>){ 
		if !treasuryCapability.check(){ 
			panic("Capability from Invalid Source")
		}
		self.treasuryCapability = treasuryCapability
	}
	
	access(all)
	fun getPlay2EarnCapabilities(account: AuthAccount): Capability<&PaymentsAdmin>{ 
		if account.address == self.account.address
		|| self.authorizedBackendAccounts.containsKey(account.address){ 
			return self.account.capabilities.get<&PaymentsAdmin>(/private/PaymentsAdmin)!
		}
		panic("Not Authorized")
	}
	
	access(all)
	resource interface WalletAdmin{ 
		access(all)
		fun PlayerTransaction(
			playerID: String,
			tokenContext: String,
			amount: Fix64,
			gameID: String,
			txID: String,
			reward: Bool,
			notes: String
		): Bool
		
		access(all)
		fun FinalizeTransactionWithDevPercentage(
			txID: String,
			profit: UFix64,
			devPercentage: UFix64
		): Bool
		
		access(all)
		fun RefundTransaction(txID: String): Bool
	}
	
	access(all)
	resource Transaction{ 
		access(all)
		var vault: @{FungibleToken.Vault}
		
		access(all)
		let playerID: String
		
		access(all)
		let transactionID: String
		
		access(all)
		let creationTime: UFix64
		
		access(all)
		let gameID: String
		
		init(vault: @{FungibleToken.Vault}, playerID: String, gameID: String, txID: String){ 
			let gameEscrowMarker <-
				GameEscrowMarker.createEmptyVault(vaultType: Type<@GameEscrowMarker.Vault>())
			gameEscrowMarker.depositToEscrowVault(gameID: gameID, vault: <-vault)
			self.vault <- gameEscrowMarker
			self.playerID = playerID
			self.transactionID = txID
			self.gameID = gameID
			self.creationTime = getCurrentBlock().timestamp
		}
		
		access(all)
		fun Refund(txID: String): Bool{ 
			if JoyridePayments.accountsCapability == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "RefundTX", notes: txID.concat(": JoyrideAccountsAdmin Accounts Capability Null"))
				return false
			}
			let accountsAdmin = (JoyridePayments.accountsCapability!).borrow()
			if accountsAdmin == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "RefundTX", notes: txID.concat(": JoyrideAccountsAdmin Accounts Capability Null"))
				return false
			}
			if self.vault.isInstance(Type<@GameEscrowMarker.Vault>()){ 
				let balance = self.vault.balance
				let escrow: @GameEscrowMarker.Vault <- self.vault.withdraw(amount: balance) as! @GameEscrowMarker.Vault
				var vault <- escrow.withdrawFromEscrowVault(amount: balance)
				let identifier = vault.getType().identifier
				destroy escrow
				return self.doRefund(vault: <-vault, balance: balance, identifier: identifier, txID: txID)
			} else{ 
				let balance = self.vault.balance
				var vault <- self.vault.withdraw(amount: self.vault.balance)
				let identifier = vault.getType().identifier
				return self.doRefund(vault: <-vault, balance: balance, identifier: identifier, txID: txID)
			}
		}
		
		access(self)
		fun doRefund(
			vault: @{FungibleToken.Vault},
			balance: UFix64,
			identifier: String,
			txID: String
		): Bool{ 
			let accountsAdmin = (JoyridePayments.accountsCapability!).borrow()
			let undepositable <-
				(accountsAdmin!).PlayerDeposit(playerID: self.playerID, vault: <-vault)
			if undepositable != nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "RefundTX", notes: txID.concat(": Failed to deposit Admin Withdrawn vault in PlayerAccount"))
				self.vault.deposit(from: <-undepositable!)
				return false
			} else{ 
				destroy undepositable
				emit DebitTransactionReverted(playerID: self.playerID, txID: self.transactionID, tokenContext: identifier, amount: balance, gameID: self.gameID)
				return true
			}
		}
		
		access(all)
		fun Finalize(txID: String, profit: UFix64, devPercentage: UFix64): Bool{ 
			if JoyridePayments.accountsCapability == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "FinalizeTX", notes: txID.concat(": JoyrideAccountsAdmin Accounts Capability Null"))
				return false
			}
			let accountsAdmin = (JoyridePayments.accountsCapability!).borrow()
			if accountsAdmin == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "FinalizeTX", notes: txID.concat(": JoyrideAccountsAdmin Accounts Capability Null"))
				return false
			}
			if JoyridePayments.treasuryCapability == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "FinalizeTX", notes: txID.concat(": JoyrideMultiToken PlatformAdmin Capability Null"))
				return false
			}
			let treasury = (JoyridePayments.treasuryCapability!).borrow()
			if treasury == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "FinalizeTX", notes: txID.concat(": JoyrideMultiToken PlatformAdmin Capability Null"))
				return false
			}
			if self.vault.isInstance(Type<@GameEscrowMarker.Vault>()){ 
				let balance = self.vault.balance
				let escrow: @GameEscrowMarker.Vault <- self.vault.withdraw(amount: balance) as! @GameEscrowMarker.Vault
				var vault <- escrow.withdrawFromEscrowVault(amount: balance)
				let identifier = vault.getType().identifier
				destroy escrow
				return self.doFinalize(vault: <-vault, balance: balance, identifier: identifier, profit: profit, txID: txID, devPercentage: devPercentage)
			} else{ 
				let balance = self.vault.balance
				var vault <- self.vault.withdraw(amount: self.vault.balance)
				let identifier = vault.getType().identifier
				return self.doFinalize(vault: <-vault, balance: balance, identifier: identifier, profit: profit, txID: txID, devPercentage: devPercentage)
			}
		}
		
		access(self)
		fun doFinalize(
			vault: @{FungibleToken.Vault},
			balance: UFix64,
			identifier: String,
			profit: UFix64,
			txID: String,
			devPercentage: UFix64
		): Bool{ 
			let accountsAdmin = (JoyridePayments.accountsCapability!).borrow()
			let profitVault <- vault.withdraw(amount: profit)
			let remainder <-
				(accountsAdmin!).ShareProfitsWithDevPercentage(
					profits: <-profitVault,
					inGameID: self.gameID,
					fromPlayerID: self.playerID,
					devPercentage: devPercentage
				)
			vault.deposit(from: <-remainder)
			let treasury = (JoyridePayments.treasuryCapability!).borrow()
			(treasury!).deposit(vault: JoyrideMultiToken.Vaults.treasury, from: <-vault)
			emit DebitTransactionFinalized(
				playerID: self.playerID,
				txID: self.transactionID,
				tokenContext: identifier,
				amount: balance,
				gameID: self.gameID,
				profit: profit
			)
			return true
		}
	}
	
	access(all)
	resource PaymentsAdmin: WalletAdmin{ 
		access(self)
		let pendingTransactions: @{String: Transaction}
		
		init(){ 
			self.pendingTransactions <-{} 
		}
		
		access(all)
		fun AuthorizeBackendAccount(authorizedAddress: Address){ 
			JoyridePayments.authorizedBackendAccounts[authorizedAddress] = true
		}
		
		access(all)
		fun DeAuthorizeBackendAccount(deauthorizedAddress: Address){ 
			JoyridePayments.authorizedBackendAccounts.remove(key: deauthorizedAddress)
		}
		
		access(all)
		fun PlayerTransaction(playerID: String, tokenContext: String, amount: Fix64, gameID: String, txID: String, reward: Bool, notes: String): Bool{ 
			if self.pendingTransactions.containsKey(txID) || JoyridePayments.transactionStore.containsKey(playerID) && (JoyridePayments.transactionStore[playerID]!)[txID] != nil{ 
				emit TxFailed_DuplicateTxID(txID: txID, notes: notes)
				return false
			}
			if amount < 0.0{ 
				let debit = UFix64(amount * -1.0)
				let accountManager = (JoyridePayments.accountsCapability!).borrow()
				if accountManager == nil{ 
					emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "DebitTX", notes: txID.concat(": JoyrideAccountsAdmin Accounts Capability Null"))
					return false
				}
				let vault <- (accountManager!).EscrowWithdrawWithTnxId(playerID: playerID, txID: txID, amount: debit, tokenContext: tokenContext)
				if vault == nil{ 
					emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "DebitTX", notes: txID.concat(": player withdraw vault failed"))
					destroy vault
					return false
				}
				let tx <- create Transaction(vault: <-vault!, playerID: playerID, gameID: gameID, txID: txID)
				destroy <-self.pendingTransactions.insert(key: txID, <-tx)
				emit DebitTransactionCreate(playerID: playerID, txID: txID, tokenContext: tokenContext, amount: debit, gameID: gameID, notes: notes)
			} else{ 
				let credit = UFix64(amount)
				let treasury = (JoyridePayments.treasuryCapability!).borrow()
				if treasury == nil{ 
					emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "CreditTX", notes: txID.concat(": JoyrideMultiToken PlatformAdmin Capability Null"))
					return false
				}
				let vault <- (treasury!).withdraw(vault: JoyrideMultiToken.Vaults.treasury, tokenContext: tokenContext, amount: credit, purpose: notes)
				if vault == nil{ 
					emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "CreditTX", notes: txID.concat(": Withdraw token vault from JoyrideMultiToken PlatformAdmin account is failed"))
					destroy vault
					return false
				} else{ 
					let undepositable <- ((JoyridePayments.accountsCapability!).borrow()!).PlayerDeposit(playerID: playerID, vault: <-vault!)
					if undepositable != nil{ 
						emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "CreditTX", notes: txID.concat(": Failed to deposit Admin Withdrawn vault in PlayerAccount"))
						(treasury!).deposit(vault: JoyrideMultiToken.Vaults.treasury, from: <-undepositable!)
						return false
					} else{ 
						emit CreditTransactionCreate(playerID: playerID, txID: txID, tokenContext: tokenContext, amount: credit, gameID: gameID, notes: "Vault Not Null")
						destroy undepositable
					}
				}
			}
			if !JoyridePayments.transactionStore.containsKey(playerID){ 
				JoyridePayments.transactionStore[playerID] ={} 
			}
			(JoyridePayments.transactionStore[playerID]!).insert(key: txID, true)
			return true
		}
		
		access(all)
		fun FinalizeTransaction(txID: String, profit: UFix64): Bool{ 
			return self.FinalizeTransactionWithDevPercentage(txID: txID, profit: profit, devPercentage: 0.0)
		}
		
		access(all)
		fun FinalizeTransactionWithDevPercentage(txID: String, profit: UFix64, devPercentage: UFix64): Bool{ 
			let tx <- self.pendingTransactions.remove(key: txID)
			if tx == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "FinalizeTX", notes: txID.concat(": Not found in pending debit transaction list"))
				destroy tx
				return false
			} else{ 
				let isFinalizeSuccess = tx?.Finalize(txID: txID, profit: profit, devPercentage: devPercentage)
				if isFinalizeSuccess == true{ 
					destroy tx
					return true
				} else{ 
					destroy <-self.pendingTransactions.insert(key: txID, <-tx!)
					return false
				}
			}
		}
		
		access(all)
		fun RefundTransaction(txID: String): Bool{ 
			let tx <- self.pendingTransactions.remove(key: txID)
			if tx == nil{ 
				emit TxFailed_ByTxTypeAndTxID(txID: txID, txType: "RefundTX", notes: txID.concat(": Not found in pending debit transaction list"))
				destroy tx
				return false
			} else{ 
				let isRefundSuccess = tx?.Refund(txID: txID) // if this false then send vault back to pending transactino
				
				if isRefundSuccess == true{ 
					destroy tx
					return true
				} else{ 
					destroy <-self.pendingTransactions.insert(key: txID, <-tx!)
					return false
				}
			}
		}
	}
	
	access(all)
	struct PlayerTransactionData{ 
		access(all)
		var playerID: String
		
		access(all)
		var reward: Fix64
		
		access(all)
		var txID: String
		
		access(all)
		var rewardTokens: Bool
		
		access(all)
		var gameID: String
		
		access(all)
		var notes: String
		
		access(all)
		var tokenTransactionType: String
		
		access(all)
		var profit: UFix64
		
		access(all)
		var currencyTokenContext: String
		
		init(
			playerID: String,
			reward: Fix64,
			txID: String,
			rewardTokens: Bool,
			gameID: String,
			notes: String,
			tokenTransactionType: String,
			profit: UFix64,
			currencyTokenContext: String
		){ 
			self.playerID = playerID
			self.reward = reward
			self.txID = txID
			self.rewardTokens = rewardTokens
			self.gameID = gameID
			self.notes = notes
			self.tokenTransactionType = tokenTransactionType
			self.profit = profit
			self.currencyTokenContext = currencyTokenContext
		}
	}
	
	access(all)
	struct PlayerTransactionDataWithDevPercentage{ 
		access(all)
		var playerID: String
		
		access(all)
		var reward: Fix64
		
		access(all)
		var txID: String
		
		access(all)
		var rewardTokens: Bool
		
		access(all)
		var gameID: String
		
		access(all)
		var notes: String
		
		access(all)
		var tokenTransactionType: String
		
		access(all)
		var profit: UFix64
		
		access(all)
		var currencyTokenContext: String
		
		access(all)
		var devPercentage: UFix64
		
		init(
			playerID: String,
			reward: Fix64,
			txID: String,
			rewardTokens: Bool,
			gameID: String,
			notes: String,
			tokenTransactionType: String,
			profit: UFix64,
			currencyTokenContext: String,
			devPercentage: UFix64
		){ 
			self.playerID = playerID
			self.reward = reward
			self.txID = txID
			self.rewardTokens = rewardTokens
			self.gameID = gameID
			self.notes = notes
			self.tokenTransactionType = tokenTransactionType
			self.profit = profit
			self.currencyTokenContext = currencyTokenContext
			self.devPercentage = devPercentage
		}
	}
	
	access(all)
	struct FinalizeTransactionData{ 
		access(all)
		var txID: String
		
		access(all)
		var profit: UFix64
		
		init(txID: String, profit: UFix64){ 
			self.txID = txID
			self.profit = profit
		}
	}
	
	access(all)
	struct RevertTransactionData{ 
		access(all)
		var txID: String
		
		init(txID: String){ 
			self.txID = txID
		}
	}
}
