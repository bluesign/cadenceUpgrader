// Flickplay

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract UnpublishedHos: NonFungibleToken {
    /// Events
    ///
    pub event ContractInitialized() /// emitted when the contract is initialized
    pub event Withdraw(id: UInt64, from: Address?) /// emitted when an NFT is withdrawn from an account
    pub event Deposit(id: UInt64, to: Address?) /// emitted when an NFT is deposited into an account
    pub event Minted(id: UInt64) /// emitted when a new NFT is minted
    pub event NFTDestroyed(id: UInt64) /// emitted when an NFT is destroyed
    pub event SetCreated(setId: UInt32) /// emitted when a new NFT set is created
    pub event SetMetadataUpdated(setId: UInt32) /// emitted when the metadata of an NFT set is updated
    pub event NFTMinted(tokenId: UInt64,setId: UInt32, editionNum: UInt64) /// emitted when a new NFT is minted within a specific set
    pub event ActionsAllowed(setId: UInt32, ids: [UInt64]) /// emitted when actions are allowed for a specific set and IDs
    pub event ActionsRestricted(setId: UInt32, ids: [UInt64]) /// emitted when actions are restricted for a specific set and IDs
    pub event AddedToWhitelist(addedAddresses: [Address]) /// emitted when addresses are added to the whitelist
    pub event RemovedFromWhitelist(removedAddresses: [Address]) /// emitted when addresses are removed from the whitelist
    pub event RoyaltyCutUpdated(newRoyaltyCut: UFix64) /// emitted when the royalty cut is updated
    pub event RoyaltyAddressUpdated(newAddress: Address) /// emitted when the royalty address is updated
    pub event NewAdminCreated() /// emitted when a new admin is created
    pub event Unboxed(setId: UInt32) /// emitted when set id updated when unboxing

    /// Contract paths
    ///
    pub let CollectionStoragePath: StoragePath /// the storage path for NFT collections
    pub let CollectionPublicPath: PublicPath /// the public path for NFT collections
    pub let AdminStoragePath: StoragePath
    pub let AdminPrivatePath: PrivatePath

    pub var totalSupply: UInt64 /// the total number of NFTs minted by the contract
    access(self) var royaltyCut: UFix64 //// the percentage of royalties to be distributed
    pub var royaltyAddress: Address /// the address to receive royalties
    pub var whitelist:{Address:Bool} /// a dictionary that maps addresses to a boolean value, indicating if the address is whitelisted
    access(self) var setMetadata: {UInt32: NFTSetMetadata} /// a dictionary that maps set IDs to NFTSetMetadata resources
    pub var allowedActions: {UInt32:{UInt64: Bool}} /// a dictionary that maps set IDs to a dictionary of token IDs and their allowed actions
    access(self) var series: @Series /// a reference to the Series resource




    pub resource Series {

        /// Resource state variables
        ///
        access(self) var setIds: [UInt32]
        access(self) var tokenIDs: UInt64
        access(self) var numberEditionsMintedPerSet: {UInt32: UInt64}

        /// Initialize the Series resource
        ///
        init() {
            self.numberEditionsMintedPerSet = {}
            self.setIds = []
            self.tokenIDs = 0
        }



        pub fun addNftSet(
            setId: UInt32,
            name: String,
            edition:String,
            thumbnail: String,
            description: String,
            httpFile: String,
            maxEditions: UInt64,
            mediaFile: String,
            externalUrl:String,
            twitterLink:String,
            toyStats: ToyStats,
            toyProperties: {String: AnyStruct}
           ) {
            pre {
                self.setIds.contains(setId) == false: "The Set has already been added to the Series."
            }

            var newNFTSet = NFTSetMetadata(
                setId: setId,
                name: name,
                edition: edition,
                thumbnail: thumbnail,
                description: description,
                httpFile: httpFile,
                maxEditions: maxEditions,
                mediaFile: mediaFile,
                externalUrl: externalUrl,
                twitterLink: twitterLink,
                toyStats: toyStats,
                toyProperties: toyProperties
            )
            self.setIds.append(setId)
            self.numberEditionsMintedPerSet[setId] = 0
            UnpublishedHos.setMetadata[setId] = newNFTSet

            emit SetCreated(setId: setId)
        }


        pub fun updateSetMetadata(
            setId: UInt32,
            name: String,
            edition:String,
            thumbnail: String,
            description: String,
            httpFile: String,
            maxEditions: UInt64,
            mediaFile: String,
            externalUrl:String,
            twitterLink:String,
            toyStats: ToyStats,
            toyProperties: {String: AnyStruct}
            ) {
            pre {
                self.setIds.contains(setId) == true: "The Set is not part of this Series."
            }
            let newSetMetadata = NFTSetMetadata(
                setId: setId,
                name: name,
                edition: edition,
                thumbnail: thumbnail,
                description: description,
                httpFile: httpFile,
                maxEditions: maxEditions,
                mediaFile: mediaFile,
                externalUrl: externalUrl,
                twitterLink: twitterLink,
                toyStats: toyStats,
                toyProperties: toyProperties
            )
            UnpublishedHos.setMetadata[setId] = newSetMetadata

            emit SetMetadataUpdated(setId: setId)
        }


        pub fun updateSetStats(
            setId: UInt32,
            toyStats: ToyStats,
            ) {
            pre {
                self.setIds.contains(setId) == true: "The Set is not part of this Series."
            }
         
            let newSetMetadata = NFTSetMetadata(
                setId: setId,
                name: UnpublishedHos.getSetMetadata(setId: setId).name,
                edition: UnpublishedHos.getSetMetadata(setId: setId).edition,
                thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail,
                description: UnpublishedHos.getSetMetadata(setId: setId).description,
                httpFile: UnpublishedHos.getSetMetadata(setId: setId).httpFile,
                maxEditions: UnpublishedHos.getSetMetadata(setId: setId).maxEditions,
                mediaFile: UnpublishedHos.getSetMetadata(setId: setId).mediaFile,
                externalUrl: UnpublishedHos.getSetMetadata(setId: setId).externalUrl,
                twitterLink: UnpublishedHos.getSetMetadata(setId: setId).twitterLink,
                toyStats: toyStats,
                toyProperties: UnpublishedHos.getSetMetadata(setId: setId).toyProperties
            )
            UnpublishedHos.setMetadata[setId] = newSetMetadata

            emit SetMetadataUpdated(setId: setId)
        }

        pub fun updateSetTraits(
            setId: UInt32,
            toyProperties: {String: AnyStruct},
            ) {
            pre {
                self.setIds.contains(setId) == true: "The Set is not part of this Series."
            }

            let newSetMetadata = NFTSetMetadata(
                setId: setId,
                name: UnpublishedHos.getSetMetadata(setId: setId).name,
                edition: UnpublishedHos.getSetMetadata(setId: setId).edition,
                thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail,
                description: UnpublishedHos.getSetMetadata(setId: setId).description,
                httpFile: UnpublishedHos.getSetMetadata(setId: setId).httpFile,
                maxEditions: UnpublishedHos.getSetMetadata(setId: setId).maxEditions,
                mediaFile: UnpublishedHos.getSetMetadata(setId: setId).mediaFile,
                externalUrl: UnpublishedHos.getSetMetadata(setId: setId).externalUrl,
                twitterLink: UnpublishedHos.getSetMetadata(setId: setId).twitterLink,
                toyStats: UnpublishedHos.getSetMetadata(setId: setId).toyStats,
                toyProperties: toyProperties
            )
            UnpublishedHos.setMetadata[setId] = newSetMetadata

            emit SetMetadataUpdated(setId: setId)
        }

        pub fun updateGenericMetadata(
            setId: UInt32,
            name: String,
            edition: String,
            thumbnail: String,
            description: String,
            httpFile: String,
            maxEditions: UInt64,
            mediaFile: String,
            externalUrl:String,
            twitterLink:String,
        ) {
            pre {
                self.setIds.contains(setId) == true: "The Set is not part of this Series."
            }
            let newSetMetadata = NFTSetMetadata(
                setId: setId,
                name: name,
                edition: edition,
                thumbnail: thumbnail,
                description: description,
                httpFile: httpFile,
                maxEditions: maxEditions,
                mediaFile: mediaFile,
                externalUrl: externalUrl,
                twitterLink: twitterLink,
                toyStats: UnpublishedHos.getSetMetadata(setId: setId).toyStats,
                toyProperties: UnpublishedHos.getSetMetadata(setId: setId).toyProperties
            )
            UnpublishedHos.setMetadata[setId] = newSetMetadata

            emit SetMetadataUpdated(setId: setId)
        }

	    pub fun mintFlickplaySeriesNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            setId: UInt32) {

            pre {
                self.numberEditionsMintedPerSet[setId] != nil: "The Set does not exist."
                self.numberEditionsMintedPerSet[setId]! < UnpublishedHos.getSetMaxEditions(setId: setId)!:
                    "Set has reached maximum NFT edition capacity."
            }

            let tokenId: UInt64 = self.tokenIDs
            let editionNum: UInt64 = self.numberEditionsMintedPerSet[setId]! + 1

			recipient.deposit(token: <-create UnpublishedHos.NFT(
                tokenId: tokenId,
                setId: setId,
                editionNum: editionNum,
                name: UnpublishedHos.getSetMetadata(setId: setId).name,
                description: UnpublishedHos.getSetMetadata(setId: setId).description,
                thumbnail: UnpublishedHos.getSetMetadata(setId: setId).thumbnail
            ))

            self.tokenIDs = self.tokenIDs + 1

            UnpublishedHos.totalSupply = UnpublishedHos.totalSupply + 1
            self.numberEditionsMintedPerSet[setId] = editionNum

            emit NFTMinted(tokenId: tokenId,setId: setId, editionNum: editionNum)
        }


		pub fun batchMintFlickplaySeriesNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            setId: UInt32,
            amount: UInt32,
            ) {

            pre {
                amount > 0:
                    "Amount must be > 0"
            }

            var i: UInt32 = 0
            while i < amount {
                self.mintFlickplaySeriesNFT(
                    recipient: recipient,
                    setId: setId,
                )
                i = i + 1
            }
		}
	}

    pub struct ToyStats {
        pub var level: UInt32
        pub var xp: UInt32
        pub var likes: UInt32
        pub var views: UInt32
        pub var uses: UInt32
        // pub var animation: String

        init(
            level: UInt32,
            xp: UInt32,
            likes: UInt32,
            views: UInt32,
            uses: UInt32
            // animation: String,
        ) {
            self.level = level
            self.xp = xp
            self.likes = likes
            self.views = views
            self.uses = uses
            // self.animation = animation
        }
    }

    pub fun getStats(_ viewResolver: &{MetadataViews.Resolver}) : ToyStats? {
        if let view = viewResolver.resolveView(Type<UnpublishedHos.ToyStats>()) {
            if let v = view as? ToyStats {
                return v
            }
        }
        return nil
    }

       pub struct NFTSetMetadata {

        pub var setId: UInt32
        pub var name: String
        pub var edition: String
        pub var thumbnail: String
        pub var description: String
        pub var httpFile: String
        pub var maxEditions: UInt64
        pub var mediaFile: String
        pub var externalUrl: String
        pub var twitterLink: String
        pub var toyStats: ToyStats
        pub var toyProperties: {String: AnyStruct}

        init(
            setId: UInt32,
            name: String,
            edition: String,
            thumbnail: String,
            description: String,
            httpFile: String,
            maxEditions: UInt64,
            mediaFile: String,
            externalUrl: String,
            twitterLink: String,
            toyStats: ToyStats,
            toyProperties: {String: AnyStruct}
) {

            self.setId = setId
            self.name = name
            self.edition = edition
            self.thumbnail = thumbnail
            self.description = description
            self.httpFile = httpFile
            self.maxEditions = maxEditions
            self.mediaFile = mediaFile
            self.externalUrl = externalUrl
            self.twitterLink = twitterLink
            self.toyStats = toyStats
            self.toyProperties = toyProperties
            

            emit SetCreated(setId: self.setId)
        }
    }



    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub var setId: UInt32
        pub let editionNum: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        init(
          tokenId: UInt64,
          setId: UInt32,
          editionNum: UInt64,
          name: String,
          description: String,
          thumbnail: String) {
            self.id = tokenId
            self.setId = setId
            self.editionNum = editionNum
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            emit Minted(id: self.id)
        }

        destroy() {
            UnpublishedHos.totalSupply = UnpublishedHos.totalSupply - 1
            emit NFTDestroyed(id: self.id)
        }

        access(contract) fun unbox(newSetId: UInt32){
            self.setId = newSetId
            emit Unboxed(setId: newSetId)
        }



        pub fun getViews(): [Type] {
            return [
               Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>(),
                Type<UnpublishedHos.ToyStats>()
            ]
        }


      pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: UnpublishedHos.getSetMetadata(setId: self.setId).name,
                        description: UnpublishedHos.getSetMetadata(setId: self.setId).description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: UnpublishedHos.getSetMetadata(setId: self.setId).thumbnail,
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(
                     name: UnpublishedHos.getSetMetadata(setId: self.setId).edition,
                     number: self.editionNum,
                     max: UnpublishedHos.getSetMetadata(setId: self.setId).maxEditions)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                        return MetadataViews.Editions(
                        editionList
                     )
                case Type<MetadataViews.HTTPFile>():
                    return MetadataViews.HTTPFile(
                        UnpublishedHos.getSetMetadata(setId: self.setId).httpFile
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).externalUrl)
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: UnpublishedHos.CollectionStoragePath,
                        publicPath: UnpublishedHos.CollectionPublicPath,
                        providerPath: /private/UnpublishedHosCollection,
                        publicCollection: Type<&UnpublishedHos.Collection{UnpublishedHos.FlickplaySeriesCollectionPublic}>(),
                        publicLinkedType: Type<&UnpublishedHos.Collection{UnpublishedHos.FlickplaySeriesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&UnpublishedHos.Collection{UnpublishedHos.FlickplaySeriesCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-UnpublishedHos.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: UnpublishedHos.getSetMetadata(setId: self.setId).mediaFile
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: UnpublishedHos.getSetMetadata(setId: self.setId).name,
                        description:  UnpublishedHos.getSetMetadata(setId: self.setId).description,
                        externalURL: MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).externalUrl),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL(UnpublishedHos.getSetMetadata(setId: self.setId).twitterLink)
                        }
                    )
                case Type<MetadataViews.Royalties>():
                    let royaltyReceiver: Capability<&{FungibleToken.Receiver}> =
                        getAccount(UnpublishedHos.royaltyAddress).getCapability<&AnyResource{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
                    return MetadataViews.Royalties(
                        royalties: [
                            MetadataViews.Royalty(
                                receiver: royaltyReceiver,
                                cut: UnpublishedHos.royaltyCut,
                                description: "Flickplay Royalty"
                            )
                        ]
                    )
                case Type<MetadataViews.Traits>():
                    let traitsView = MetadataViews.dictToTraits(dict:  UnpublishedHos.getSetMetadata(setId: self.setId).toyProperties, excludedNames: [])
                    return traitsView
                case Type<UnpublishedHos.ToyStats>():
                    return  UnpublishedHos.getSetMetadata(setId: self.setId).toyStats
            }
            return nil
        }
    }



    pub resource Admin: IAdminSafeShare {



        pub fun borrowSeries(): &Series  {
            return &UnpublishedHos.series as &Series
        }



        pub fun setAllowedActions(setId: UInt32, ids: [UInt64]) {
            let set = UnpublishedHos.allowedActions[setId] ?? {}
            for id in ids {
                set[id] = true
                }
            UnpublishedHos.allowedActions[setId] = set
            emit ActionsAllowed(setId: setId, ids: ids)
        }



        pub fun setRestrictedActions(setId: UInt32, ids: [UInt64]) {
            let set = UnpublishedHos.allowedActions[setId] ?? {}
            for id in ids {
                set[id] = false
            }
            UnpublishedHos.allowedActions[setId] = set
            emit ActionsRestricted(setId: setId, ids: ids)
        }




        pub fun addToWhitelist(_toAddAddresses: [Address]) {
            for address in _toAddAddresses {
                UnpublishedHos.whitelist[address] = true
            }
            emit AddedToWhitelist(addedAddresses: _toAddAddresses)
        }



        pub fun removeFromWhitelist(_toRemoveAddresses: [Address]) {
            for address in _toRemoveAddresses {
                UnpublishedHos.whitelist[address] = false
            }
            emit RemovedFromWhitelist(removedAddresses: _toRemoveAddresses)
        }




        pub fun unboxNft(address: Address, nftId: UInt64, newSetId: UInt32 ){
            let collectionRef = getAccount(address).getCapability<&{UnpublishedHos.FlickplaySeriesCollectionPublic}>(UnpublishedHos.CollectionPublicPath).borrow()
            let nftRef = collectionRef!.borrowFlickplaySeries(id: nftId)
            nftRef?.unbox(newSetId: newSetId)
        }



        pub fun setRoyaltyCut(newRoyalty: UFix64){
            UnpublishedHos.royaltyCut = newRoyalty
            emit RoyaltyCutUpdated(newRoyaltyCut: newRoyalty)
        }



        pub fun setRoyaltyAddress(newReceiver: Address){
            UnpublishedHos.royaltyAddress = newReceiver
            emit RoyaltyAddressUpdated(newAddress: newReceiver)
        }



        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }

    }



    pub resource interface IAdminSafeShare{
        pub fun borrowSeries(): &Series
        pub fun setAllowedActions(setId: UInt32, ids: [UInt64])
        pub fun setRestrictedActions(setId: UInt32, ids: [UInt64])
        pub fun addToWhitelist(_toAddAddresses: [Address])
        pub fun removeFromWhitelist(_toRemoveAddresses: [Address])
        pub fun unboxNft(address: Address, nftId: UInt64, newSetId: UInt32 )
    }




    pub resource interface FlickplaySeriesCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlickplaySeries(id: UInt64): &UnpublishedHos.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow UnpublishedHos reference: The ID of the returned reference is incorrect"
            }
        }
    }



    pub resource Collection: FlickplaySeriesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}



        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let ref = (&self.ownedNFTs[withdrawID] as auth &NonFungibleToken.NFT?)!
            let flickplayNFT = ref as! &UnpublishedHos.NFT
            UnpublishedHos.getAllowedActionsStatus(setId: flickplayNFT.setId,tokenId: flickplayNFT.id) ?? panic("Actions for this token NOT allowed")
            let token <- self.ownedNFTs.remove(key: withdrawID)  ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }



        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            var batchCollection <- create Collection()
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            return <-batchCollection
        }



        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @UnpublishedHos.NFT
            // UnpublishedHos.getAllowedActionsStatus(setId: token.setId,tokenId: token.id) ?? panic("Actions for this token NOT allowed")
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        // access(contract) fun depositInternal(token: @UnpublishedHos.NFT) {
        //     let id: UInt64 = token.id
        //     let oldToken <- self.ownedNFTs[id] <- token
        //     emit Deposit(id: id, to: self.owner?.address)
        //     destroy oldToken
        // }



        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {
            let keys = tokens.getIDs()
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }
            destroy tokens
        }



        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }



        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }



        pub fun borrowFlickplaySeries(id: UInt64): &UnpublishedHos.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &UnpublishedHos.NFT
            } else {
                return nil
            }
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let flickplayNFT = nft as! &UnpublishedHos.NFT
            return flickplayNFT as &AnyResource{MetadataViews.Resolver}
        }



        destroy() {
            destroy self.ownedNFTs
        }


        pub fun burn(id: UInt64) {
            let nft <- self.ownedNFTs.remove(key: id) as! @UnpublishedHos.NFT?
            destroy nft
        }

        init () {
            self.ownedNFTs <- {}
        }
    }



    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create UnpublishedHos.Collection()
    }



    pub fun fetch(_ from: Address, id: UInt64): &UnpublishedHos.NFT? {
        let collection = getAccount(from)
            .getCapability(UnpublishedHos.CollectionPublicPath)
            .borrow<&UnpublishedHos.Collection{UnpublishedHos.FlickplaySeriesCollectionPublic}>()
            ?? panic("Couldn't get collection")
        return collection.borrowFlickplaySeries(id: id)
    }




    pub fun getSetMetadata(setId: UInt32): UnpublishedHos.NFTSetMetadata {
        return UnpublishedHos.setMetadata[setId]!
    }



    pub fun getAllowedActionsStatus(setId: UInt32, tokenId: UInt64): Bool? {
        if let set = UnpublishedHos.allowedActions[setId] {
            return set[tokenId]
        } else {
            return nil
        }
    }


    pub fun getAllSets(): [UnpublishedHos.NFTSetMetadata] {
        return UnpublishedHos.setMetadata.values
    }



    pub fun getSetMaxEditions(setId: UInt32): UInt64? {
        return UnpublishedHos.setMetadata[setId]?.maxEditions
    }



	init() {
        self.CollectionStoragePath = /storage/UnpublishedHosCollection
        self.CollectionPublicPath = /public/UnpublishedHosCollection
        self.AdminStoragePath = /storage/UnpublishedHosAdmin
        self.AdminPrivatePath = /private/UnpublishedHosAdminPrivate
        self.totalSupply = 0
        self.royaltyCut = 0.02
        self.royaltyAddress = self.account.address
        self.setMetadata = {}
        self.whitelist = {}
        self.allowedActions = {}
        self.series <- create Series()
        self.account.save(<-create Admin(), to: self.AdminStoragePath)
        self.account.link<&UnpublishedHos.Admin>(
            self.AdminPrivatePath,
            target: self.AdminStoragePath
        ) ?? panic("Could not get a capability to the admin")        

        emit ContractInitialized()
	}
}
 