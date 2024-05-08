import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"
import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"
 
pub contract GreenBitcoin: FungibleToken {

    // The amount of tokens in existance
    pub var totalSupply: UFix64
    // nil if there is none
    pub let maxSupply: UFix64?

    // Paths
    pub let VaultStoragePath: StoragePath
    pub let ReceiverPublicPath: PublicPath
    pub let VaultPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let AdministratorStoragePath: StoragePath

    // Events
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensTransferred(amount: UFix64, from: Address, to: Address)
    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)

    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver {
        pub var balance: UFix64

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)

            if let owner: Address = self.owner?.address {
                GreenBitcoin.setBalance(address: owner, balance: self.balance)
            }
            return <- create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            let vault: @Vault <- from as! @Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            
            // We set the balance to 0.0 here so that it doesn't
            // decrease the totalSupply in the `destroy` function.
            vault.balance = 0.0
            destroy vault

            if let owner: Address = self.owner?.address {
                GreenBitcoin.setBalance(address: owner, balance: self.balance)
            }
        }

        pub fun getViews(): [Type]{
            return [Type<FungibleTokenMetadataViews.FTView>(),
                    Type<FungibleTokenMetadataViews.FTDisplay>(),
                    Type<FungibleTokenMetadataViews.FTVaultData>()]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<FungibleTokenMetadataViews.FTView>():
                    return FungibleTokenMetadataViews.FTView(
                        ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?,
                        ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?
                    )
                case Type<FungibleTokenMetadataViews.FTDisplay>():
                    let media = MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                            url: "https://nftstorage.link/ipfs/bafkreigglohoo25a4zqqf6qauofnkaufoz3g7g4huijphy3jwhyyzbpnxa"
                        ),
                        mediaType: "image"
                    )
                    let medias = MetadataViews.Medias([media])
                    return FungibleTokenMetadataViews.FTDisplay(
                        name: "Green Bitcoin",
                        symbol: "GBTC",
                        description: "Every blockchain deserves a Bitcoin, and with Green Bitcoin, we aim to provide the long-awaited stability that users deserve.In a world filled with digital transactions and innovation, cryptocurrencies have revolutionized the way we store and exchange value. Blockchain technology has brought unprecedented levels of decentralization and security, but it is not without challenges.Green Bitcoin takes it a step further by focusing on sustainability and ecological responsibility. We recognize that the success of a cryptocurrency should not only be measured in financial gains but also in its impact on the environment. Therefore, we strive to create a green and sustainable Bitcoin, utilizing energy-efficient mining processes and renewable energy sources.With Green Bitcoin, we want to bestow the long-awaited stability upon users. We understand the need for stability and reliability in the cryptocurrency market. By combining a solid technological foundation, green mining practices, and a passionate community, we aim to provide a cryptocurrency that not only preserves value but also maximizes positive environmental impact.Join the Green Bitcoin movement and experience a new dimension of cryptocurrency. Together, we can pave the way towards a more sustainable and stable future.",
                        externalURL: MetadataViews.ExternalURL(""),
                        logos: medias,
                        socials: {
                            "twitter": MetadataViews.ExternalURL(""),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/vY8pK9x8")
                        }
                    )
                case Type<FungibleTokenMetadataViews.FTVaultData>():
                    return FungibleTokenMetadataViews.FTVaultData(
                        storagePath: GreenBitcoin.VaultStoragePath,
                        receiverPath: GreenBitcoin.ReceiverPublicPath,
                        metadataPath: GreenBitcoin.VaultPublicPath,
                        providerPath: /private/GreenBitcoinVault,
                        receiverLinkedType: Type<&Vault{FungibleToken.Receiver}>(),
                        metadataLinkedType: Type<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(),
                        providerLinkedType: Type<&Vault{FungibleToken.Provider}>(),
                        createEmptyVaultFunction: (fun (): @Vault {
                            return <- GreenBitcoin.createEmptyVault()
                        })
                    )
            }
            return nil
        }
  
        init(balance: UFix64) {
            self.balance = balance
        }

        destroy() {
            emit TokensBurned(amount: self.balance)
            GreenBitcoin.totalSupply = GreenBitcoin.totalSupply - self.balance
        }
    }

    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    pub resource Minter: Toucans.Minter {
        pub fun mint(amount: UFix64): @Vault {
            post {
                GreenBitcoin.maxSupply == nil || GreenBitcoin.totalSupply <= GreenBitcoin.maxSupply!: 
                    "Exceeded the max supply of tokens allowd."
            }
            GreenBitcoin.totalSupply = GreenBitcoin.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <- create Vault(balance: amount)
        }
    }

    // We follow this pattern of storage
    // so the (potentially) huge dictionary 
    // isn't loaded when the contract is imported
    pub resource Administrator {
        // This is an experimental index and should
        // not be used for anything official
        // or monetary related
        access(self) let balances: {Address: UFix64}

        access(contract) fun setBalance(address: Address, balance: UFix64) {
            self.balances[address] = balance
        }

        pub fun getBalance(address: Address): UFix64 {
            return self.balances[address] ?? 0.0
        }

        pub fun getBalances(): {Address: UFix64} {
            return self.balances
        }

        init() {
            self.balances = {}
        }
    }

    access(contract) fun setBalance(address: Address, balance: UFix64) {
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        admin.setBalance(address: address, balance: balance)
    }

    pub fun getBalance(address: Address): UFix64 {
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        return admin.getBalance(address: address)
    }

    pub fun getBalances(): {Address: UFix64} {
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        return admin.getBalances()
    }

    init(
      _paymentTokenInfo: ToucansTokens.TokenInfo,
      _editDelay: UFix64,
      _minting: Bool,
      _initialTreasurySupply: UFix64,
      _maxSupply: UFix64?,
      _extra: {String: AnyStruct}
    ) {

      // Contract Variables
      self.totalSupply = 0.0
      self.maxSupply = _maxSupply

      // Paths
      self.VaultStoragePath = /storage/GreenBitcoinVault
      self.ReceiverPublicPath = /public/GreenBitcoinReceiver
      self.VaultPublicPath = /public/GreenBitcoinMetadata
      self.MinterStoragePath = /storage/GreenBitcoinMinter
      self.AdministratorStoragePath = /storage/GreenBitcoinAdmin
 
      // Admin Setup
      let vault <- create Vault(balance: self.totalSupply)
      self.account.save(<- vault, to: self.VaultStoragePath)

      self.account.link<&Vault{FungibleToken.Receiver}>(
          self.ReceiverPublicPath,
          target: self.VaultStoragePath
      )

      self.account.link<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(
          self.VaultPublicPath,
          target: self.VaultStoragePath
      )

      if self.account.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath) == nil {
        self.account.save(<- Toucans.createCollection(), to: Toucans.CollectionStoragePath)
        self.account.link<&Toucans.Collection{Toucans.CollectionPublic}>(Toucans.CollectionPublicPath, target: Toucans.CollectionStoragePath)
      }

      let toucansProjectCollection = self.account.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath)!
      toucansProjectCollection.createProject(
        projectTokenInfo: ToucansTokens.TokenInfo("GreenBitcoin", self.account.address, "GBTC", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), 
        paymentTokenInfo: _paymentTokenInfo, 
        minter: <- create Minter(), 
        editDelay: _editDelay,
        minting: _minting,
        initialTreasurySupply: _initialTreasurySupply,
        extra: _extra
      )

      self.account.save(<- create Administrator(), to: self.AdministratorStoragePath)

      // Events
      emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 