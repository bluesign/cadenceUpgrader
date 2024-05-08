
    import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
    import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
    import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
    import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
    import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"
    
    pub contract Memento: NonFungibleToken, ViewResolver {
    
        // Collection Information
        access(self) let collectionInfo: {String: AnyStruct}
    
        // Contract Information
        pub var totalSupply: UInt64
    
        // Events
        pub event ContractInitialized()
        pub event Withdraw(id: UInt64, from: Address?)
        pub event Deposit(id: UInt64, to: Address?)
        pub event Minted(id: UInt64, serial: UInt64, recipient: Address, creatorID: UInt64)
        pub event MetadataSuccess(creatorID: UInt64, description: String)
        pub event MetadataError(error: String)
    
        // Paths
        pub let CollectionStoragePath: StoragePath
        pub let CollectionPublicPath: PublicPath
        pub let CollectionPrivatePath: PrivatePath
        pub let AdministratorStoragePath: StoragePath
        pub let MetadataStoragePath: StoragePath
        pub let MetadataPublicPath: PublicPath
    
        access(account) let nftStorage: @{Address: {UInt64: NFT}}
    
        pub resource MetadataStorage: MetadataStoragePublic {
            // List of Creator 
            pub var creatorsIds: {UInt64: [NFTMetadata]}
    
            init () {
                self.creatorsIds = {}
            }
            access(account) fun creatorExist(_ creatorId: UInt64)  {
                    if self.creatorsIds[creatorId] == nil {
                        self.creatorsIds[creatorId] = []
                    }
            }
            access (account) fun metadataIsNew(_ creatorId: UInt64, _ description: String): Bool {
                self.creatorExist(creatorId)
                let metadata = self.findMetadata(creatorId, description)
                if metadata == nil {
                    return true
                } else {
                    return false
                }
            }
            access(account) fun addMetadata(_ creatorId: UInt64,_ metadata: NFTMetadata) {
                    if self.creatorsIds[creatorId] == nil {
                        self.creatorsIds[creatorId] = []
                    }
    
                    self.creatorsIds[creatorId]?.append(metadata)
            }
    
            access(account) fun updateMinted(_ creatorId: UInt64,_ description: String) {
                let metadataRef = self.findMetadataRef(creatorId, description)!
                metadataRef.updateMinted()
    
            }
                    // Public Functions
            pub fun findMetadataRef(_ creatorId: UInt64,_ description: String): &Memento.NFTMetadata? {
                let metadatas = self.creatorsIds[creatorId]!
                var i = metadatas.length - 1
                while i >= 0 {
                    if (metadatas[i].description == description) {
                        let metadataRef: &Memento.NFTMetadata = (&self.creatorsIds[creatorId]![i] as &NFTMetadata)
                        return metadataRef
                     }
                    i = i - 1
                }
                return nil
            } 
    
            // Public Functions
            pub fun findMetadata(_ creatorId: UInt64,_ description: String): Memento.NFTMetadata? {
                let metadatas = self.creatorsIds[creatorId]!
                var i = metadatas.length - 1
                while i >= 0 {
                    if (metadatas[i].description == description) {
                        return metadatas[i]
                     }
                    i = i - 1
                }
                return nil
            } 
            pub fun getTimeRemaining(_ creatorID: UInt64,_ description: String): UFix64? {
                let metadata = self.findMetadata(creatorID, description)!
                let answer = (metadata.creationTime + 86400.0) - getCurrentBlock().timestamp
                return answer
            }
        }
    
        /// Defines the methods that are particular to this NFT contract collection
        ///
        pub resource interface MetadataStoragePublic {
            pub fun getTimeRemaining(_ creatorID: UInt64,_ description: String): UFix64?
            pub fun findMetadata(_ creatorId: UInt64,_ description: String): Memento.NFTMetadata?
        }
    
        pub struct NFTMetadata {
            pub let creatorID: UInt64
            pub var creatorUsername: String
            pub let creatorAddress: Address
            pub let description: String
            pub let image: MetadataViews.HTTPFile
            pub let metadataId: UInt64
            pub var supply: UInt64
            pub var minted: UInt64
            pub let unlimited: Bool
            pub var extra: {String: AnyStruct}
            pub var timer: UInt64
            pub let MementoCreationDate: String
            pub let contentCreationDate: String
            pub let creationTime: UFix64
            pub let lockdownTime: UFix64
            pub let embededHTML: String
    
            access(account) fun updateMinted() {
                self.minted = self.minted + 1
                if(self.unlimited) {
                    self.supply = self.supply + 1
                }
            }
            init(
                _creatorID: UInt64,
                _creatorUsername: String,
                _creatorAddress: Address,
                _description: String,
                _image: MetadataViews.HTTPFile,
                _supply: UInt64,
                _extra: {String: AnyStruct},
                _MementoCreationDate: String,
                _contentCreationDate: String,
                _currentTime: UFix64,
                _lockdownTime: UFix64,
                _embededHTML: String,
                ) {
    
                self.metadataId = _creatorID
                self.creatorID = _creatorID
                self.creatorUsername = _creatorUsername
                self.creatorAddress = _creatorAddress
                self.description = _description
                self.image = _image
                self.extra = _extra
                self.supply = _supply
                self.unlimited = _supply == 0
                self.minted = 0
                self.timer = 0
                self.MementoCreationDate = _MementoCreationDate
                self.contentCreationDate = _contentCreationDate
                self.creationTime = _currentTime
                self.lockdownTime = _lockdownTime
                self.embededHTML = _embededHTML
            }
        }
    
        pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
            pub let id: UInt64
            // The 'metadataId' is what maps this NFT to its 'NFTMetadata'
            pub let creatorID: UInt64
            pub let serial: UInt64
            pub let description: String
            pub let originalMinter: Address
    
            pub fun getMetadata(): NFTMetadata {
                return Memento.getNFTMetadata(self.creatorID, self.description )!
            }
    
            pub fun getViews(): [Type] {
                return [
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.ExternalURL>(),
                    Type<MetadataViews.NFTCollectionData>(),
                    Type<MetadataViews.NFTCollectionDisplay>(),
                    Type<MetadataViews.Royalties>(),
                    Type<MetadataViews.Serial>(),
                    Type<MetadataViews.NFTView>()
                ]
            }
    
            pub fun resolveView(_ view: Type): AnyStruct? {
                let metadata = self.getMetadata()
                switch view {
                    case Type<MetadataViews.Display>():
                        return MetadataViews.Display(
                            creatorID: metadata.creatorUsername.concat(" ").concat(metadata.contentCreationDate),
                            description: metadata.description,
                            thumbnail: metadata.image
                        )
                    case Type<MetadataViews.Traits>():
                        let metaCopy = metadata.extra
                        metaCopy["Serial"] = self.serial
                        return MetadataViews.dictToTraits(dict: metaCopy, excludedNames: nil)
    
                    case Type<MetadataViews.NFTView>():
                        return MetadataViews.NFTView(
                            id: self.id,
                            uuid: self.uuid,
                            display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?,
                            externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?,
                            collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?,
                            collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?,
                            royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?,
                            traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?
                        )
                    case Type<MetadataViews.NFTCollectionData>():
                        return Memento.resolveView(view)
                    case Type<MetadataViews.ExternalURL>():
                        return Memento.getCollectionAttribute(key: "website") as! MetadataViews.ExternalURL
                    case Type<MetadataViews.NFTCollectionDisplay>():
                        return Memento.resolveView(view)
                    case Type<MetadataViews.Medias>():
                        if metadata.embededHTML != nil {
                            return MetadataViews.Medias(
                                items: [
                                    MetadataViews.Media(
                                        file: MetadataViews.HTTPFile(
                                            url: metadata.embededHTML
                                        ),
                                        mediaType: "html"
                                    )
                                ]
                            )
                        }
                    case Type<MetadataViews.Royalties>():
                          return MetadataViews.Royalties([
                            MetadataViews.Royalty(
                                  recepient: getAccount(metadata.creatorAddress).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
                                  cut: 0.10, // 10% royalty on secondary sales
                                  description: "The creator of the original content gets 10% of every secondary sale."
                            )
                          ])
                    case Type<MetadataViews.Serial>():
                        return MetadataViews.Serial(
                            self.serial
                        )
                }
                return nil
            }
    
            init(_creatorID: UInt64, _description: String, _recipient: Address) {
    
                // Fetch the metadata blueprint
                let metadatas = Memento.account.borrow<&Memento.MetadataStorage>(from: Memento.MetadataStoragePath)!
                let metadataRef = metadatas.findMetadata(_creatorID, _description)!
                // Assign serial number to the NFT based on the number of minted NFTs
                self.id = self.uuid
                self.creatorID = _creatorID
                self.serial = metadataRef.minted + 1
                self.description = _description
                self.originalMinter = _recipient
    
                // Update the total supply of this MetadataId by 1
                metadatas.updateMinted(_creatorID, _description)
                // Update Memento collection NFTs count 
                Memento.totalSupply = Memento.totalSupply + 1
    
                emit Minted(id: self.id, serial: self.serial, recipient: _recipient, creatorID: _creatorID)
    
            //	Memento.account.save(<- metadatas, to: Memento.MetadataStoragePath)
            }
        }
    
        /// Defines the methods that are particular to this NFT contract collection
        ///
        pub resource interface MementoCollectionPublic {
            pub fun deposit(token: @NonFungibleToken.NFT)
            pub fun getIDs(): [UInt64]
            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
            pub fun borrowMemento(id: UInt64): &Memento.NFT? {
                post {
                    (result == nil) || (result?.id == id):
                        "Cannot borrow Memento NFT reference: the ID of the returned reference is incorrect"
                }
            }
        }
    
        pub resource Collection: MementoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    
            pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
    
            // Withdraw removes an NFT from the collection and moves it to the caller(for Trading)
            pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
                let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
    
                emit Withdraw(id: token.id, from: self.owner?.address)
    
                return <-token
            }
            // Deposit takes a NFT and adds it to the collections dictionary
            // and adds the ID to the id array
            pub fun deposit(token: @NonFungibleToken.NFT) {
                let token <- token as! @NFT
    
                let id: UInt64 = token.id
    
                // Add the new token to the dictionary
                self.ownedNFTs[id] <-! token
    
                emit Deposit(id: id, to: self.owner?.address)
            }
    
            // GetIDs returns an array of the IDs that are in the collection
            pub fun getIDs(): [UInt64] {
                return self.ownedNFTs.keys
            }
    
            // BorrowNFT gets a reference to an NFT in the collection
            pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
                return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            }
    
            /// Gets a reference to an NFT in the collection so that 
            /// the caller can read its metadata and call its methods
            ///
            /// @param id: The ID of the wanted NFT
            /// @return A reference to the wanted NFT resource
            ///        
            pub fun borrowMemento(id: UInt64): &Memento.NFT? {
                if self.ownedNFTs[id] != nil {
                    // Create an authorized reference to allow downcasting
                    let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                    return ref as! &Memento.NFT
                }
    
                return nil
            }
    
            pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
                let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let nft = token as! &NFT
                return nft
            }
    
            pub fun claim() {
                if let storage = &Memento.nftStorage[self.owner!.address] as &{UInt64: NFT}? {
                    for id in storage.keys {
                        self.deposit(token: <- storage.remove(key: id)!)
                    }
                }
            }
    
            init () {
                self.ownedNFTs <- {}
            }
    
            destroy() {
                destroy self.ownedNFTs
            }
        }
    
        pub resource Administrator {
            // Function to upload the Metadata to the contract.
            pub fun createNFTMetadata(
                channel: String,
                creatorID: UInt64,
                creatorUsername: String, 
                creatorAddress: Address,
                sourceURL: String,
                description: String,
                MementoCreationDate: String,
                contentCreationDate: String,
                lockdownOption: Int,
                supplyOption: UInt64,
                imgUrl: String,
                embededHTML: String,
            ) {
                // Load the metadata from the Memento account
                let metadatas = Memento.account.borrow<&Memento.MetadataStorage>(from: Memento.MetadataStoragePath)!
                    // Check if Metadata already exist
                if metadatas.metadataIsNew(creatorID, description) {
                        metadatas.addMetadata(creatorID, NFTMetadata(
                                _creatorID: creatorID,
                                _creatorUsername: creatorUsername,
                                _creatorAddress: creatorAddress,
                                _description: description,
                                _image: MetadataViews.HTTPFile(
                                    url: imgUrl,
                                ),
                                _supply: supplyOption,
                                _extra: {
                                    "Creator username": creatorUsername,
                                    "Creator ID": creatorID,
                                    "Channel": channel,
                                    "Text content": description,
                                    "Source": sourceURL,
                                    "Memento creation date": MementoCreationDate,
                                    "Content creation date": contentCreationDate
                                    },
                                _MementoCreationDate: MementoCreationDate,
                                _contentCreationDate: contentCreationDate,
                                _currentTime: getCurrentBlock().timestamp,
                                _lockdownTime: self.getLockdownTime(lockdownOption),
                                _embededHTML: embededHTML,
                        ))
                        emit MetadataSuccess(creatorID: creatorID, description: description)
                    } else {
                        emit MetadataError(error: "A Metadata for this Event already exist")
                    }
    
                // Memento.account.save(<- metadatas, to: Memento.MetadataStoragePath)
            }
    
            // mintNFT mints a new NFT and deposits
            // it in the recipients collection
            pub fun mintNFT(creatorId: UInt64, description: String, recipient: Address) {
                pre {
                    self.isMintingAvailable(creatorId, description): "Minting for this NFT has ended or reached max supply."
                }
    
                let nft <- create NFT(_creatorID: creatorId, _description: description, _recipient: recipient)
    
                if let recipientCollection = getAccount(recipient).getCapability(Memento.CollectionPublicPath).borrow<&Memento.Collection{NonFungibleToken.CollectionPublic}>() {
                    recipientCollection.deposit(token: <- nft)
                } else {
                    if let storage = &Memento.nftStorage[recipient] as &{UInt64: NFT}? {
                        storage[nft.id] <-! nft
                    } else {
                        Memento.nftStorage[recipient] <-! {nft.id: <- nft}
                    }
                }
            }
    
            // create a new Administrator resource
            pub fun createAdmin(): @Administrator {
                return <- create Administrator()
            }
            // change Memento of collection info
            pub fun changeField(key: String, value: AnyStruct) {
                Memento.collectionInfo[key] = value
            }
            access(account) fun isMintingAvailable(_ creatorId: UInt64, _ description: String): Bool {
                let metadata = Memento.getNFTMetadata(creatorId, description)!
                if (metadata.unlimited) {
                    if (metadata.lockdownTime != 0.0) {
                        let answer = getCurrentBlock().timestamp <= (metadata.creationTime + metadata.lockdownTime)
                        return answer
    
                    } else {
                        return true
                    }
                } else {
                    if(metadata.minted < metadata.supply) {
                        if (metadata.lockdownTime != 0.0) {
                            let answer = getCurrentBlock().timestamp <= (metadata.creationTime + metadata.lockdownTime)
                            return answer
    
                        } else {
                            return true
                        }
    
                    } else {
                        return false
                    }
                }
    
            }
            access(account) fun getLockdownTime(_ lockdownOption: Int): UFix64 {
                switch lockdownOption {
                    case 0: 
                        return 21600.0
                    case 1: 
                        return 43200.0
                    case 2:
                        return 86400.0
                    case 3: 
                        return 172800.0
                    default:
                        return 0.0
                }
            }
    
        }
    
    
        // public function that anyone can call to create a new empty collection
        pub fun createEmptyCollection(): @NonFungibleToken.Collection {
            return <- create Collection()
        }
    
        /// Function that resolves a metadata view for this contract.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Memento.CollectionStoragePath,
                        publicPath: Memento.CollectionPublicPath,
                        providerPath: Memento.CollectionPrivatePath,
                        publicCollection: Type<&Memento.Collection{Memento.MementoCollectionPublic}>(),
                        publicLinkedType: Type<&Memento.Collection{Memento.MementoCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Memento.Collection{Memento.MementoCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Memento.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = Memento.getCollectionAttribute(key: "image") as! MetadataViews.Media	
                    return MetadataViews.NFTCollectionDisplay(
                            name: "Memento",
                            description: "Sell Mementos of any Tweet in seconds.",
                            externalURL: MetadataViews.ExternalURL("https://Memento.gg/"),
                            squareImage: media,
                            bannerImage: media,
                            socials: {
                                "twitter": MetadataViews.ExternalURL("https://twitter.com/CreateAMemento")
                            }
                        )
            }
            return nil
        }
    
        // Get information about a NFTMetadata
        pub fun getNFTMetadata(_ creatorId: UInt64,_ description: String): Memento.NFTMetadata? {
            let publicAccount = self.account
            let metadataCapability: Capability<&AnyResource{Memento.MetadataStoragePublic}> = publicAccount.getCapability<&{MetadataStoragePublic}>(self.MetadataPublicPath)
            let metadatasRef: &AnyResource{Memento.MetadataStoragePublic} = metadataCapability.borrow()!
            let metadatas: Memento.NFTMetadata? = metadatasRef.findMetadata(creatorId, description)
    
            return metadatas
        }
    
        pub fun getCollectionInfo(): {String: AnyStruct} {
            let collectionInfo = self.collectionInfo
            collectionInfo["totalSupply"] = self.totalSupply
            collectionInfo["version"] = 1
            return collectionInfo
        }
    
        pub fun getCollectionAttribute(key: String): AnyStruct {
            return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
        }

        pub fun isMintingAvailable(_ creatorId: UInt64, _ description: String): Bool {

            let metadata = Memento.getNFTMetadata(creatorId, description)!
    
            if (metadata.unlimited) {
    
                if (metadata.lockdownTime != 0.0) {
                    
                    let answer = getCurrentBlock().timestamp <= (metadata.creationTime + metadata.lockdownTime)
                    return answer
    
                    } else {
                        return true
                    }
                } else {
                    if(metadata.minted < metadata.supply) {
                        if (metadata.lockdownTime != 0.0) {
                            let answer = getCurrentBlock().timestamp <= (metadata.creationTime + metadata.lockdownTime)
                            return answer
    
                        } else {
                            return true
                        }
    
                    } else {
                        return false
                    }
                }
        }
    
        init() {
            // Collection Info
            self.collectionInfo = {}
            self.collectionInfo["name"] = "Memento"
            self.collectionInfo["description"] = "Sell Mementos of any Tweet in seconds."
            self.collectionInfo["image"] = MetadataViews.Media(
                            file: MetadataViews.HTTPFile(
                                url: "https://media.discordapp.net/attachments/1075564743152107530/1149417271597473913/Memento_collection_image.png?width=1422&height=1422"
                            ),
                            mediaType: "image/jpeg"
                          )			
            self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
            self.collectionInfo["website"] = MetadataViews.ExternalURL("https://www.Memento.gg/")
            self.collectionInfo["socials"] = {"Twitter": MetadataViews.ExternalURL("https://frontend-react-git-testing-Memento.vercel.app/")}
            self.totalSupply = 0
            self.nftStorage <- {}
    
            let identifier = "Memento_Collection".concat(self.account.address.toString())
    
            // Set the named paths
            self.CollectionStoragePath = StoragePath(identifier: identifier)!
            self.CollectionPublicPath = PublicPath(identifier: identifier)!
            self.CollectionPrivatePath = PrivatePath(identifier: identifier)!
            self.AdministratorStoragePath = StoragePath(identifier: identifier.concat("_Administrator"))!
            self.MetadataStoragePath = StoragePath(identifier: identifier.concat("_Metadata"))!
            self.MetadataPublicPath = PublicPath(identifier: identifier.concat("_Metadata"))!
    
            // Create a Collection resource and save it to storage
            let collection <- create Collection()
            self.account.save(<- collection, to: self.CollectionStoragePath)
    
            // Create a public capability for the collection
            self.account.link<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                self.CollectionPublicPath,
                target: self.CollectionStoragePath
            )
    
            // Create a Administrator resource and save it to Memento account storage
            let administrator <- create Administrator()
            self.account.save(<- administrator, to: self.AdministratorStoragePath)
    
            // Create a Metadata Storage resource and save it to Memento account storage
            let metadataStorage <- create MetadataStorage()
            self.account.save(<- metadataStorage, to: self.MetadataStoragePath)
    
            // Create a public capability for the Metadata Storage
            self.account.link<&MetadataStorage{MetadataStoragePublic}>(
                self.MetadataPublicPath,
                target: self.MetadataStoragePath
            )
    
            emit ContractInitialized()
        }
    }
    