
  import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
  
   access(all) contract ChainlinkFlowToken2: FungibleToken {
      pub var totalSupply: UFix64 
  
      /// TokensInitialized
      ///
      /// The event that is emitted when the contract is created
      pub event TokensInitialized(initialSupply: UFix64)
  
      /// TokensWithdrawn
      ///
      /// The event that is emitted when tokens are withdrawn from a Vault
      pub event TokensWithdrawn(amount: UFix64, from: Address?)
  
      /// TokensDeposited
      ///
      /// The event that is emitted when tokens are deposited to a Vault
      pub event TokensDeposited(amount: UFix64, to: Address?)
  
      /// TokensMinted
      ///
      /// The event that is emitted when new tokens are minted
      pub event TokensMinted(amount: UFix64)
  
      pub let TokenVaultStoragePath: StoragePath
      pub let TokenVaultPublicPath: PublicPath
      pub let TokenMinterStoragePath: StoragePath
  
      pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
          pub var balance: UFix64
  
          init(balance: UFix64) {
              self.balance = balance
          }
  
          pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
              self.balance = self.balance - amount
              emit TokensWithdrawn(amount: amount, from: self.owner?.address)
              return <- create Vault(balance: amount)
          }
  
          pub fun deposit(from: @FungibleToken.Vault) {
              let vault <- from as! @ChainlinkFlowToken2.Vault
              self.balance = self.balance + vault.balance 
              emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
              vault.balance = 0.0
              destroy vault // Make sure we get rid of the vault
          }
  
          destroy() {
              ChainlinkFlowToken2.totalSupply = ChainlinkFlowToken2.totalSupply - self.balance
          }
      }
  
      pub fun createEmptyVault(): @FungibleToken.Vault {
          return <- create Vault(balance: 0.0)
      }
  
      access(contract) fun initialMint(initialMintValue: UFix64): @FungibleToken.Vault {
          return <- create Vault(balance: initialMintValue)
      }
  
      pub resource Minter {
          pub fun mintTokens(amount: UFix64): @FungibleToken.Vault {
          pre {
                  amount > 0.0: "Amount minted must be greater than zero"
              }
              ChainlinkFlowToken2.totalSupply = ChainlinkFlowToken2.totalSupply + amount
              return <- create Vault(balance:amount)
          }
          
      }
  
      init() {
          self.totalSupply = 100.00
          self.TokenVaultStoragePath = /storage/ChainlinkFlowToken2Vault
          self.TokenVaultPublicPath = /public/ChainlinkFlowToken2Vault
          self.TokenMinterStoragePath = /storage/ChainlinkFlowToken2Minter
  
          self.account.save(<- create Minter(), to: ChainlinkFlowToken2.TokenMinterStoragePath)
  
         //
         // Create an Empty Vault for the Minter
         //
          self.account.save(<- ChainlinkFlowToken2.initialMint(initialMintValue: self.totalSupply), to: ChainlinkFlowToken2.TokenVaultStoragePath)
          self.account.link<&ChainlinkFlowToken2.Vault{FungibleToken.Balance, FungibleToken.Receiver}>(ChainlinkFlowToken2.TokenVaultPublicPath, target: ChainlinkFlowToken2.TokenVaultStoragePath)
      }
   }
   
      