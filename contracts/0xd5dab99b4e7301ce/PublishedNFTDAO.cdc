import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FungibleTokenMetadataViews from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"
import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"
 
pub contract PublishedNFTDAO: FungibleToken {

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
                PublishedNFTDAO.setBalance(address: owner, balance: self.balance)
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
                PublishedNFTDAO.setBalance(address: owner, balance: self.balance)
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
                            url: "https://nftstorage.link/ipfs/bafybeifsbguk3gajq6hwmoc772wldkadgxicbq6kodxp4vfp772helmwyq"
                        ),
                        mediaType: "image"
                    )
                    let bannerMedia = MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                            url: "https://nftstorage.link/ipfs/bafybeib4tiwtu437dttkerj62g6sdlnq2jprhvzpskiidh6ywadg3nikgm"
                        ),
                        mediaType: "image"
                    )
                    let medias = MetadataViews.Medias([media, bannerMedia])
                    return FungibleTokenMetadataViews.FTDisplay(
                        name: "Published NFT DAO",
                        symbol: "PAGE",
                        description: "Published NFT is a decentralized autonomous organization (DAO) that revolutionizes the world of eBook publishing by leveraging the power of Non-Fungible Tokens (NFTs). As an innovative platform, it allows users to engage in various activities such as donating, staking, and burning eBook NFTs to earn rewards in the form of page tokens.By acquiring eBook NFTs, users gain ownership of unique digital books, granting them exclusive rights and benefits within the ecosystem. These NFTs can be utilized in different ways, including staking them to earn page tokens. The more eBook NFTs staked, the greater the potential rewards.Page tokens hold significant value within the Published NFT DAO, as they serve as a voting mechanism. Holders of page tokens have the opportunity to influence important decisions regarding the platform's operations, such as the selection of new eBook titles, marketing strategies, and community initiatives. This democratic approach ensures that the DAO represents the collective interests of its members.Additionally, users have the option to burn their eBook NFTs, essentially removing them from circulation. In return for this action, they receive page tokens as a reward. Burning NFTs not only reduces the supply but also increases the scarcity and value of the remaining eBook NFTs held by the community.Published NFT empowers both eBook authors and readers, creating an inclusive ecosystem where creators are fairly compensated for their work and readers have a say in shaping the platform's direction. Through the use of NFTs, staking, burning, and page tokens, Published NFT establishes an innovative model that combines ownership, rewards, and community governance, ensuring a vibrant and engaging experience for all participants.",
                        externalURL: MetadataViews.ExternalURL("publishednft.io/"),
                        logos: medias,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("publishednft"),
                            "discord": MetadataViews.ExternalURL("RHH5aH44k9")
                        }
                    )
                case Type<FungibleTokenMetadataViews.FTVaultData>():
                    return FungibleTokenMetadataViews.FTVaultData(
                        storagePath: PublishedNFTDAO.VaultStoragePath,
                        receiverPath: PublishedNFTDAO.ReceiverPublicPath,
                        metadataPath: PublishedNFTDAO.VaultPublicPath,
                        providerPath: /private/PublishedNFTDAOVault,
                        receiverLinkedType: Type<&Vault{FungibleToken.Receiver}>(),
                        metadataLinkedType: Type<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(),
                        providerLinkedType: Type<&Vault{FungibleToken.Provider}>(),
                        createEmptyVaultFunction: (fun (): @Vault {
                            return <- PublishedNFTDAO.createEmptyVault()
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
            PublishedNFTDAO.totalSupply = PublishedNFTDAO.totalSupply - self.balance
        }
    }

    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    pub resource Minter: Toucans.Minter {
        pub fun mint(amount: UFix64): @Vault {
            post {
                PublishedNFTDAO.maxSupply == nil || PublishedNFTDAO.totalSupply <= PublishedNFTDAO.maxSupply!: 
                    "Exceeded the max supply of tokens allowd."
            }
            PublishedNFTDAO.totalSupply = PublishedNFTDAO.totalSupply + amount
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
      self.VaultStoragePath = /storage/PublishedNFTDAOVault
      self.ReceiverPublicPath = /public/PublishedNFTDAOReceiver
      self.VaultPublicPath = /public/PublishedNFTDAOMetadata
      self.MinterStoragePath = /storage/PublishedNFTDAOMinter
      self.AdministratorStoragePath = /storage/PublishedNFTDAOAdmin
 
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
        projectTokenInfo: ToucansTokens.TokenInfo("PublishedNFTDAO", self.account.address, "PAGE", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), 
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
 