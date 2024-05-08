import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract BlockpartyNFT: NonFungibleToken {
    pub var totalSupply: UInt64

    // addresses that should be used to store account's collection 
    // and for interactions with it within transactions
    // WARNING: only resources of type BlockpartyNFT.Collection 
    //          should be stored by this paths.
    //          Storing resources of other types can lead to undefined behavior
    pub var BNFTCollectionStoragePath: StoragePath 
    pub var BNFTCollectionPublicPath: PublicPath
    pub var FullBNFTCollectionPublicPath: PublicPath

    // addresses that should be used use to store tokenD account's address. 
    // Only one tokenD address can be stored at a time. 
    // Address stored by this path is allowed to be overriden but 
    // be careful that after you override it new address will 
    // be used to all TokenD interactions 
    pub var TokenDAccountAddressProviderStoragePath: StoragePath
    pub var TokenDAccountAddressProviderPublicPath: PublicPath

    pub var AccountPreparedProviderStoragePath: StoragePath
    pub var AccountPreparedProviderPublicPath: PublicPath

    pub var IsStorageUpdatedToV1ProviderStoragePath: StoragePath
    pub var IsStorageUpdatedToV1ProviderPublicPath: PublicPath

    pub var MinterStoragePath: StoragePath

    // pub var adminPublicCollection: &AnyResource{NonFungibleToken.CollectionPublic}

    // access(self) var NFTMetadataMap:  {UInt64:NFTMetadata}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    // Including `id` and addresses here to avoid complex event parsing logic
    pub event TransferredToServiceAccount(id: UInt64, from: Address, extSystemAddrToMint: String)
    pub event MintedFromWithdraw(id: UInt64, withdrawRequestID: UInt64, to: Address?)
    pub event MintedFromIssuance(id: UInt64, issuanceRequestID: UInt64, to: Address?)

    pub event Burned(id: UInt64)

    pub struct IssuanceMintMsg {
        pub let issuanceRequestID: UInt64
        pub let detailsURL: String

        init(id: UInt64, detailsURL: String) {
            self.issuanceRequestID = id
            self.detailsURL = detailsURL
        }
    }

    pub struct TokenDAddressProvider {
        pub let tokenDAddress: String
        pub init(tokenDAddress: String) {
            self.tokenDAddress = tokenDAddress
        }
    }

    pub struct AccountPreparedProvider { // TODO move to separate proxy contract
        pub var isPrepared: Bool
        pub init(isPrepared: Bool) {
            self.isPrepared = isPrepared
        }
        pub fun setPrepared(isPrepared: Bool) {
            self.isPrepared = isPrepared
        }
    }

    pub struct IsStorageUpdatedToV1Provider { // TODO move to separate proxy contract
        pub var isUpdated: Bool
        pub init(isUpdated: Bool) {
            self.isUpdated = isUpdated
        }
        pub fun setUpdated(isUpdated: Bool) {
            self.isUpdated = isUpdated
        }
    }

    pub struct NFTMetadata {
        pub var values: {String:String}

        init(values: {String:String}){
          self.values = values
        }

        pub fun setMetadata(values: {String:String}) {
            self.values = values
        }

        pub fun getMetadata() : {String:String} {
          return self.values
        }

        pub fun setMetadataValue(key: String, value: String) {
            self.values.insert(key: key, value)
        }

        pub fun getMetadataValue(key: String) : String? {
          return self.values[key]
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let detailsURL: String

        init(id: UInt64, detailsURL: String) {
            self.id = id
            self.detailsURL = detailsURL
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.IPFSFile>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
                // Type<MetadataViews.Traits>()
            ]
        }

        /// Function that resolves a metadata viewmetadata.getMetadataValue("name") as Stringiew.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            let metadataStroge = BlockpartyNFT.account.borrow<&NFTMetadataStorage>(from: /storage/NFTMetadata)!
            let metadata = metadataStroge.NFTMetadataMap[self.id] ?? BlockpartyNFT.NFTMetadata(values:{})
            
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: metadata.getMetadataValue(key: "name") ?? "",
                        description: metadata.getMetadataValue(key: "description") ?? "",
                        thumbnail: MetadataViews.IPFSFile(
                            cid: metadata.getMetadataValue(key: "thumbnail") ?? "",
                            path: nil
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "Blockparty NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        []
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://blockparty.co")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: BlockpartyNFT.BNFTCollectionStoragePath,
                        publicPath: BlockpartyNFT.BNFTCollectionPublicPath,
                        providerPath: /private/NFTCollection,
                        publicCollection: Type<&BlockpartyNFT.Collection{BlockpartyNFT.BNFTCollectionPublic}>(),
                        publicLinkedType: Type<&BlockpartyNFT.Collection{BlockpartyNFT.BNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&BlockpartyNFT.Collection{BlockpartyNFT.BNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-BlockpartyNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(cid: "QmT1Vmi2aYbVvHN24M2yMTCVPK4NdmDW1XiBvmZWyW7TQd", path: nil),
                        mediaType: "image/jpg"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The Blockparty Collection",
                        description: "Blockparty NFT collection",
                        externalURL: MetadataViews.ExternalURL("https://blockparty.co"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {}
                    )
            }
            return nil
        }
    }

    

    pub resource interface BNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT

        pub fun borrowBNFT(id: UInt64): &BlockpartyNFT.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow NFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, BNFTCollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        pub var tokenDDepositerCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>
        
        init(tokenDDepositerCap: Capability<&AnyResource{NonFungibleToken.CollectionPublic}>) {
            self.tokenDDepositerCap = tokenDDepositerCap
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("no token found with provided withdrawID")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @BlockpartyNFT.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun depositToTokenD(id: UInt64) {
            if !self.tokenDDepositerCap.check() {
                panic("TokenD depositer cap not found. You either trying to deposit from admin account or something wrong with collection initialization")
            }

            let token <- self.withdraw(withdrawID: id)

            self.tokenDDepositerCap.borrow()!.deposit(token: <-token)

            let addrToIssueProvider = self.owner!.getCapability<&TokenDAddressProvider>(BlockpartyNFT.TokenDAccountAddressProviderPublicPath).borrow()!

            emit TransferredToServiceAccount(id: id, from: self.owner!.address, extSystemAddrToMint: addrToIssueProvider.tokenDAddress)
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            let ref = &self.ownedNFTs[id]  as &NonFungibleToken.NFT? 
            return ref!
        }

        pub fun borrowBNFT(id: UInt64): &BlockpartyNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
                return ref as! &BlockpartyNFT.NFT?
            }
            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let BlockpartyNFT = nft as! &BlockpartyNFT.NFT
            return BlockpartyNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource NFTMinter {
        access(self) var BNFTCollectionPublicPath: PublicPath

        init(collectionPublicPath: PublicPath) {
            self.BNFTCollectionPublicPath = collectionPublicPath
        }

        pub fun mintNFTByIssuance( 
            requests: [IssuanceMintMsg],
            metadatas: [{String:String}]
        ) {
            let minterOwner = self.owner ?? panic("could not get minter owner")

            let minterOwnerCollection = minterOwner.getCapability(self.BNFTCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Could not get reference to the service account's NFT Collection")

            var creationID = BlockpartyNFT.totalSupply + 1 as UInt64

            BlockpartyNFT.totalSupply = BlockpartyNFT.totalSupply + UInt64(requests.length)

            for i, req in requests {
                let token <-create NFT(id: creationID, detailsURL: req.detailsURL)
                let id = token.id

                // deposit it in the recipient's account using their reference
                minterOwnerCollection.deposit(token: <-token)

                let storage = BlockpartyNFT.account.borrow<&BlockpartyNFT.NFTMetadataStorage>(from: BlockpartyNFT.NFTMetadataStoragePath()) ?? panic("Could not get NFTMetadataStorage")
                storage.setNFTMetadata(id: id, metadataMap: metadatas[i])

                emit MintedFromIssuance(id: id, issuanceRequestID: req.issuanceRequestID, to: self.owner?.address)
                creationID = creationID + 1 as UInt64
            }
        }

        // TODO redesign it it operate with tokens stored in a vault of the account which is owner of the Minter resource
        pub fun mintNFT(
            withdrawRequestID: UInt64,
            detailsURL: String,
            metadataMap: {String:String},
            receiver: Address
        ) {
            // Borrow the recipient's public NFT collection reference
            let recipientAccount = getAccount(receiver)

            let recipientCollection = recipientAccount
                .getCapability(self.BNFTCollectionPublicPath)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Could not get receiver reference to the NFT Collection")

            // create token with provided name and data
            let token <-create NFT(id: BlockpartyNFT.totalSupply + 1 as UInt64, detailsURL: detailsURL)
            let id = token.id

            // deposit it in the recipient's account using their reference
            recipientCollection.deposit(token: <-token)

            BlockpartyNFT.totalSupply = BlockpartyNFT.totalSupply + 1 as UInt64
            
            let storage = BlockpartyNFT.account.borrow<&BlockpartyNFT.NFTMetadataStorage>(from: BlockpartyNFT.NFTMetadataStoragePath()) ?? panic("Could not get NFTMetadataStorage")
            storage.setNFTMetadata(id: id, metadataMap: metadataMap)

            emit MintedFromWithdraw(id: id, withdrawRequestID: withdrawRequestID, to: receiver)
        }
    }

    pub resource NFTBurner {
        pub fun burnNFT(token: @NonFungibleToken.NFT) {
            let id = token.id
            destroy token
            emit Burned(id: id)
        }
    }

    pub resource NFTMetadataStorage {
        access(account) var NFTMetadataMap:  {UInt64:NFTMetadata}

        pub fun setNFTMetadata(id: UInt64, metadataMap: {String:String}) {
            var metadata = self.NFTMetadataMap[id] ?? BlockpartyNFT.NFTMetadata(values: {})
            
            metadata.setMetadata(values: metadataMap)

            self.NFTMetadataMap.insert(key: id, metadata)
        }

        pub fun getNFTMetadata(id: UInt64) : NFTMetadata? {
          return self.NFTMetadataMap[id]
        }

        pub fun setMetadataMap(NFTMetadataMap: {UInt64:BlockpartyNFT.NFTMetadata}) {
            self.NFTMetadataMap = NFTMetadataMap
        }

        init() {
            self.NFTMetadataMap = {}
        }
    }

    pub fun NFTMetadataStoragePath(): StoragePath {
        return /storage/NFTMetadata
    }

    pub fun createAccountPreparedProvider(isPrepared: Bool): AccountPreparedProvider {
        return AccountPreparedProvider(isPrepared: isPrepared)
    }

    pub fun createIsStorageUpdatedToV1Provider(isUpdated: Bool): IsStorageUpdatedToV1Provider {
        return IsStorageUpdatedToV1Provider(isUpdated: isUpdated)
    }

    pub fun createTokenDAddressProvider(tokenDAddress: String): TokenDAddressProvider {
        return TokenDAddressProvider(tokenDAddress: tokenDAddress)
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection(tokenDDepositerCap: self.account.getCapability<&AnyResource{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath))
    }

    // public function that anyone can call to create a burner to burn their oun tokens
    pub fun createBurner(): @NFTBurner {
        return <- create NFTBurner()
    }

    // public function that anyone can call to create a metadata storage
    pub fun createMetadataStorage(): @NFTMetadataStorage {
        return <- create NFTMetadataStorage()
    }

    init() {
        self.totalSupply = 1050

        self.BNFTCollectionStoragePath = /storage/NFTCollection
        self.BNFTCollectionPublicPath = /public/NFTCollection
        self.FullBNFTCollectionPublicPath = /public/BNFTCollection

        self.MinterStoragePath = /storage/NFTMinter

        self.TokenDAccountAddressProviderStoragePath = /storage/tokenDAccountAddr
        self.TokenDAccountAddressProviderPublicPath = /public/tokenDAccountAddr

        self.AccountPreparedProviderStoragePath = /storage/accountPrepared
        self.AccountPreparedProviderPublicPath = /public/accountPrepared

        self.IsStorageUpdatedToV1ProviderStoragePath = /storage/isStorageUpdatedToV1
        self.IsStorageUpdatedToV1ProviderPublicPath = /public/isStorageUpdatedToV1

        // self.NFTMetadataMap = {}

        // not linking it to public path to avoid unauthorized access attempts
        // TODO make minter internal and use in only within contract
        let existingMinter = self.account.borrow<&NFTMinter>(from: self.MinterStoragePath)
        if existingMinter == nil { 
            // in case when contract is being deployed after removal minter does already exist and no need to save it once more
            self.account.save(<-create NFTMinter(collectionPublicPath: self.BNFTCollectionPublicPath), to: self.MinterStoragePath)
        }

        let adminCollectionExists = self.account.getCapability<&AnyResource{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath).check()
        if !adminCollectionExists {
            self.account.save(<-self.createEmptyCollection(), to: self.BNFTCollectionStoragePath)
            // adminCollection <-! self.createEmptyCollection() as @BlockpartyNFT.Collection?
        }
        self.account.link<&AnyResource{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(self.BNFTCollectionPublicPath, target: self.BNFTCollectionStoragePath)

        let accountPrepared = self.account.copy<&AccountPreparedProvider>(from: self.AccountPreparedProviderStoragePath)
        if accountPrepared != nil && !(accountPrepared!.isPrepared) {
            self.account.save(AccountPreparedProvider(isPrepared: true), to: self.AccountPreparedProviderStoragePath)
            self.account.link<&AccountPreparedProvider>(self.AccountPreparedProviderPublicPath, target: self.AccountPreparedProviderStoragePath)
        }
        
        let isStorageUpdatedToV1 = self.account.copy<&IsStorageUpdatedToV1Provider>(from: self.IsStorageUpdatedToV1ProviderStoragePath)
        if isStorageUpdatedToV1 != nil && !(isStorageUpdatedToV1!.isUpdated) {
            self.account.save(IsStorageUpdatedToV1Provider(isUpdated: true), to: self.IsStorageUpdatedToV1ProviderStoragePath)
            self.account.link<&IsStorageUpdatedToV1Provider>(self.IsStorageUpdatedToV1ProviderPublicPath, target: self.IsStorageUpdatedToV1ProviderStoragePath)
        }

        let existingMetadataStorage = self.account.borrow<&NFTMetadataStorage>(from: self.NFTMetadataStoragePath())
        if existingMetadataStorage == nil { 
            // in case when contract is being deployed after removal NFTMetadata does already exist and no need to save it once more
            self.account.save(<-create NFTMetadataStorage(), to: self.NFTMetadataStoragePath())
        }
        
        emit ContractInitialized()
    }
}
 