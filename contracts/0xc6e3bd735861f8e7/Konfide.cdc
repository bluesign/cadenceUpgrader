import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"
import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"
 
pub contract Konfide: FungibleToken, ViewResolver {

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
                Konfide.setBalance(address: owner, balance: self.balance)
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
                Konfide.setBalance(address: owner, balance: self.balance)
            }
        }

        pub fun getViews(): [Type]{
            return [
                Type<FungibleTokenMetadataViews.FTView>(),
                Type<FungibleTokenMetadataViews.FTDisplay>(),
                Type<FungibleTokenMetadataViews.FTVaultData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<FungibleTokenMetadataViews.FTView>():
                    return Konfide.resolveView(view)
                case Type<FungibleTokenMetadataViews.FTDisplay>():
                    return Konfide.resolveView(view)
                case Type<FungibleTokenMetadataViews.FTVaultData>():
                    return Konfide.resolveView(view)
            }
            return nil
        }
  
        init(balance: UFix64) {
            self.balance = balance
        }

        destroy() {
            if (self.balance > 0.0) {
                emit TokensBurned(amount: self.balance)
                Konfide.totalSupply = Konfide.totalSupply - self.balance
            }
        }
    }

    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    pub resource Minter: Toucans.Minter {
        pub fun mint(amount: UFix64): @Vault {
            post {
                Konfide.maxSupply == nil || Konfide.totalSupply <= Konfide.maxSupply!: 
                    "Exceeded the max supply of tokens allowd."
            }
            Konfide.totalSupply = Konfide.totalSupply + amount
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

    pub fun getViews(): [Type] {
        return [
            Type<FungibleTokenMetadataViews.FTView>(),
            Type<FungibleTokenMetadataViews.FTDisplay>(),
            Type<FungibleTokenMetadataViews.FTVaultData>()
        ]
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
                        url: "https://nftstorage.link/ipfs/bafkreidh2djmod6vkwkebg3vkr7fkroin6v2ymdkhnambdcbhi7kcbuaoy"
                    ),
                    mediaType: "image"
                )
                let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                        url: "https://nftstorage.link/ipfs/bafkreigzxr4itutpqpdaosu7iflx2aoxssyy2wyz47fv4lhiuy5woqsoe4"
                    ),
                    mediaType: "image"
                )
                let medias = MetadataViews.Medias([media, bannerMedia])
                return FungibleTokenMetadataViews.FTDisplay(
                    name: "Konfide",
                    symbol: "KFD",
                    description: "Konfide - Rede de Confiança ",
                    externalURL: MetadataViews.ExternalURL("www.konfide.com.br"),
                    logos: medias,
                    socials: {
                        "twitter": MetadataViews.ExternalURL(""),
                        "discord": MetadataViews.ExternalURL("2MpTRytNB3")
                    }
                )
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(
                    storagePath: Konfide.VaultStoragePath,
                    receiverPath: Konfide.ReceiverPublicPath,
                    metadataPath: Konfide.VaultPublicPath,
                    providerPath: /private/KonfideVault,
                    receiverLinkedType: Type<&Vault{FungibleToken.Receiver}>(),
                    metadataLinkedType: Type<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(),
                    providerLinkedType: Type<&Vault{FungibleToken.Provider}>(),
                    createEmptyVaultFunction: (fun (): @Vault {
                        return <- Konfide.createEmptyVault()
                    })
                )
        }
        return nil
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
      self.VaultStoragePath = /storage/KonfideVault
      self.ReceiverPublicPath = /public/KonfideReceiver
      self.VaultPublicPath = /public/KonfideMetadata
      self.MinterStoragePath = /storage/KonfideMinter
      self.AdministratorStoragePath = /storage/KonfideAdmin
 
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
        projectTokenInfo: ToucansTokens.TokenInfo("Konfide", self.account.address, "KFD", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), 
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
 