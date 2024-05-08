import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import MikoSeaNFTMetadata from "./MikoSeaNFTMetadata.cdc"

pub contract MIKOSEANFTV2: NonFungibleToken {
    // start from 1
    pub var totalSupply: UInt64
    pub var nextProjectId: UInt64

    pub var nextCommentId: UInt64

    // mapping nftID - holderAdderss
    pub let nftHolderMap: {UInt64: Address}

    pub var mikoseaCap: Capability<&AnyResource{FungibleToken.Receiver}>
    pub var tokenPublicPath: PublicPath

    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------
    pub event ContractInitialized()
    // project events
    pub event ProjectCreated(projectId: UInt64, title:String, description:String, thumbnail: String, creatorAddress:Address, mintPrice: UFix64, maxSupply: UInt64, isPublic: Bool)
    pub event ProjectUpdated(projectId: UInt64, title:String, description:String, thumbnail: String, creatorAddress:Address, mintPrice: UFix64, maxSupply: UInt64)
    pub event ProjectPublic(projectId:UInt64)
    pub event ProjectUnPublic(projectId:UInt64)
    pub event ProjectReveal(projectId: UInt64)

    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, nftData: NFTData, recipient: Address)
    pub event NFTTransferred(nftID: UInt64, nftData: NFTData, from: Address, to: Address)
    pub event NFTDestroy(nftID: UInt64)
    pub event SetInMarket(nftID: UInt64)

    //------------------------------------------------------------
    // Path
    //------------------------------------------------------------
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let PrivatePath: PrivatePath
    pub let MinterStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath


    //------------------------------------------------------------
    // Comment Struct
    //------------------------------------------------------------

    pub struct CommentData {
        pub let commentId: UInt64
        pub let nftID: UInt64
        pub var comment: String
        pub let createdDate: UFix64
        pub var updatedDate: UFix64

        init( nftID:UInt64, comment: String) {
            pre{
                comment.length != 0 : "Comment can not be empty"
            }
            self.commentId = MIKOSEANFTV2.nextCommentId
            self.nftID = nftID
            self.comment = comment
            self.createdDate = getCurrentBlock().timestamp
            self.updatedDate = getCurrentBlock().timestamp
            MIKOSEANFTV2.nextCommentId = MIKOSEANFTV2.nextCommentId + 1
        }

        access(account) fun update(comment: String): CommentData {
            self.comment = comment
            self.updatedDate = getCurrentBlock().timestamp
            return self
        }
    }

    pub resource ProjectData{
        pub let projectId: UInt64
        pub var isPublic: Bool
        pub var title: String
        pub var description: String
        pub var thumbnail: String
        pub var creatorAddress: Address
        pub var platformFee: UFix64
        pub var creatorMarketFee: UFix64
        pub var platformMarketFee: UFix64
        pub var mintPrice: UFix64
        pub var isReveal: Bool

        pub var totalSupply: UInt64

        // nftID minted
        pub let nftMinted: [UInt64]
        // max mint number
        pub var maxSupply: UInt64

        access(self) var metadata: {String: AnyStruct}

        init(
            title: String,
            description: String,
            thumbnail: String,
            creatorAddress: Address,
            platformFee: UFix64,
            creatorMarketFee: UFix64,
            platformMarketFee: UFix64,
            mintPrice: UFix64,
            maxSupply: UInt64,
            isPublic: Bool,
            metadata: {String: AnyStruct}
        ) {
            pre {
                title.length > 0: "PROJECT_TITLE_IS_INVALID"
                description.length > 0: "PROJECT_DESCRIPTION_IS_INVALID"
                maxSupply > 0 : "PROJECT_MAX_SUPPLY_IS_INVALID"
                platformFee <= 1.0: "PLATFORM_FEE_IS_INVALID"
                creatorMarketFee <= 1.0: "CRAETER_FEE_IS_INVALID"
                platformMarketFee <= 1.0: "PLATFORM_FEE_IS_INVALID"
                (creatorMarketFee + platformMarketFee) <= 1.0: "TOTAL_FEE_IS_INVALID"
            }
            self.projectId = MIKOSEANFTV2.nextProjectId
            self.title = title
            self.description = description
            self.thumbnail = thumbnail
            self.creatorAddress = creatorAddress
            self.platformFee = platformFee
            self.creatorMarketFee = creatorMarketFee
            self.platformMarketFee = platformMarketFee
            self.mintPrice = mintPrice
            self.maxSupply = maxSupply
            self.isPublic = isPublic
            self.totalSupply = 0
            self.nftMinted = []
            self.isReveal = false
            self.metadata = metadata

            MIKOSEANFTV2.nextProjectId = MIKOSEANFTV2.nextProjectId + 1

            emit ProjectCreated(
                projectId: self.projectId,
                title: title,
                description: description,
                thumbnail: thumbnail,
                creatorAddress: creatorAddress,
                mintPrice: mintPrice,
                maxSupply: maxSupply,
                isPublic: isPublic)
        }

        access(account) fun public(){
            self.isPublic = true
            emit ProjectPublic(projectId: self.projectId)
        }

        access(account) fun unPublic(){
            self.isPublic = false
            emit ProjectUnPublic(projectId: self.projectId)
        }

        access(account) fun reveal() {
            self.isReveal = true
            emit ProjectReveal(projectId: self.projectId)
        }

        access(account) fun unRevealProject() {
            self.isReveal = false
        }

        pub fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        access(account) fun setMetadata(_metadata: {String: AnyStruct}) : {String: AnyStruct} {
            self.metadata = _metadata
            return _metadata
        }

        access(contract) fun update(title: String?,
            description: String?,
            thumbnail: String?,
            creatorAddress: Address?,
            platformFee: UFix64?,
            creatorMarketFee: UFix64?,
            platformMarketFee: UFix64?,
            mintPrice: UFix64?,
            maxSupply: UInt64?,
            metadata: {String: AnyStruct}?) {
            post {
                self.title.length > 0: "New Project name cannot be empty"
                self.description.length > 0: "New Project description cannot be empty"
                self.maxSupply > 0 : "Max supply must be > 0"
                self.platformFee <= 1.0: "PLATFORM_FEE_IS_INVALID"
                self.creatorMarketFee <= 1.0: "CRAETER_FEE_IS_INVALID"
                self.platformMarketFee <= 1.0: "PLATFORM_FEE_IS_INVALID"
                (self.creatorMarketFee + self.platformMarketFee) <= 1.0: "TOTAL_FEE_IS_INVALID"
            }

            self.title = title ?? self.title
            self.description = description ?? self.description
            self.thumbnail = thumbnail ?? self.thumbnail
            self.creatorAddress = creatorAddress ?? self.creatorAddress
            self.platformFee = platformFee ?? self.platformFee
            self.creatorMarketFee = creatorMarketFee ?? self.creatorMarketFee
            self.platformMarketFee = platformMarketFee ?? self.platformMarketFee
            self.mintPrice = mintPrice ?? self.mintPrice
            self.maxSupply = maxSupply ?? self.maxSupply
            self.metadata = metadata ?? self.metadata

            emit ProjectUpdated(
                projectId: self.projectId,
                title: self.title,
                description: self.description,
                thumbnail: self.thumbnail,
                creatorAddress: self.creatorAddress,
                mintPrice: self.mintPrice,
                maxSupply: self.maxSupply
            )
        }

        pub fun getRoyalties(): MetadataViews.Royalties {
            return MetadataViews.Royalties([
                MetadataViews.Royalty(
                    receiver: MIKOSEANFTV2.mikoseaCap,
                    cut: self.platformFee,
                    description: "Platform fee"
                ),
                MetadataViews.Royalty(
                    receiver: getAccount(self.creatorAddress).getCapability<&{FungibleToken.Receiver}>(MIKOSEANFTV2.tokenPublicPath),
                    cut: 0.0,
                    description: "Creater market fee, when this nft is in the market, the creater fee is 5%"
                )
            ])
        }

        pub fun getRoyaltiesMarket(): MetadataViews.Royalties {
            return MetadataViews.Royalties([
                MetadataViews.Royalty(
                    receiver: MIKOSEANFTV2.mikoseaCap,
                    cut: self.platformMarketFee,
                    description: "Platform market fee"
                ),
                MetadataViews.Royalty(
                    receiver: getAccount(self.creatorAddress).getCapability<&{FungibleToken.Receiver}>(MIKOSEANFTV2.tokenPublicPath),
                    cut: self.creatorMarketFee,
                    description: "Creater market fee"
                )
            ])
        }

        priv fun _mintNFT(image: String, metadata: {String:String}, recipientRef: &{CollectionPublic}): UInt64 {
            self.totalSupply = self.totalSupply + 1
            let newNFT: @NFT <- create NFT(
                projectId: self.projectId,
                serialNumber: self.totalSupply,
                image: image,
                metadata: metadata,
                royalties: self.getRoyalties(),
                royaltiesMarket: self.getRoyaltiesMarket())
            let nftIDminted = newNFT.id

            self.nftMinted.append(newNFT.id)
            emit Minted(
                id: newNFT.id,
                nftData: newNFT.nftData,
                recipient: recipientRef.owner!.address
            )
            recipientRef.deposit(token: <- newNFT)
            return nftIDminted
        }

        // mint nfts and return list of nftID
        access(contract) fun batchMintNFT(quantity: UInt64, images: [String], metadatas: [{String:String}], recipientCap: Capability<&{CollectionPublic}>): [UInt64]  {
            pre {
                self.isPublic: "PROJECT_LOCKED"
                self.totalSupply + quantity <= self.maxSupply : "PROJECT_NOT_ENOUGH"
                recipientCap.check(): "ACCOUNT_NOT_CREATED"
                quantity == UInt64(images.length) : "QUANTITY_IN_VALID"
                quantity == UInt64(metadatas.length) : "QUANTITY_IN_VALID"
            }
            let nftIDs: [UInt64] = []
            var i: UInt64 = 0
            while i < quantity {
                let nftID = self._mintNFT(image: images[i], metadata:metadatas[i], recipientRef: recipientCap.borrow()!)
                i = i + 1
                nftIDs.append(nftID)
            }
            return nftIDs
        }
    }

    pub struct NFTData {
        pub let projectId: UInt64
        pub let serialNumber: UInt64

        // base image URL
        access(contract) let image: String

        access(contract) let metadata: {String: String}
        pub let createdDate: UFix64
        pub let blockHeight: UInt64

        access(contract) fun updateMetadata(_ metadata: {String: String}) {
            for key in metadata.keys {
                self.metadata[key] = metadata[key]
            }
        }

        init(projectId: UInt64, serialNumber:UInt64, image: String, metadata: {String: String}) {
            self.projectId = projectId
            self.serialNumber = serialNumber
            self.metadata = metadata
            self.image = image
            self.createdDate = getCurrentBlock().timestamp
            self.blockHeight = getCurrentBlock().height
        }
    }
  //------------------------------------------------------------
  // NFT Resource
  //------------------------------------------------------------
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let nftData: NFTData
        access(self) var isInMarket: Bool
        access(self) let royalties: MetadataViews.Royalties
        access(self) let royaltiesMarket: MetadataViews.Royalties
        pub let commentData: {UInt64: CommentData}

        init(projectId: UInt64, serialNumber:UInt64, image: String, metadata: {String: String}, royalties: MetadataViews.Royalties, royaltiesMarket: MetadataViews.Royalties) {
            MIKOSEANFTV2.totalSupply = MIKOSEANFTV2.totalSupply + 1
            self.id = MIKOSEANFTV2.totalSupply
            self.nftData = NFTData(
                projectId: projectId,
                serialNumber : serialNumber,
                image: image,
                metadata: metadata
            )
            self.royalties = royalties
            self.royaltiesMarket = royaltiesMarket
            self.commentData = {}
            self.isInMarket = false
        }

        pub fun getMetadata(): {String: String} {
            let requiredMetadata = MikoSeaNFTMetadata.getNFTMetadata(nftType: "mikoseav2", nftID: self.id) ?? {}
            if MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.isReveal {
                let metadata = self.nftData.metadata
                requiredMetadata.forEachKey(fun (key: String): Bool {
                    metadata.insert(key: key, requiredMetadata[key] ?? "")
                    return true
                })
                return metadata
            }
            return requiredMetadata
        }

        access(account) fun updateMetadata(_ metadata: {String:String}) {
            self.nftData.updateMetadata(metadata)
        }

        pub fun getImage() : String {
            if MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.isReveal {
                return self.nftData.image
            }
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.thumbnail
        }

        pub fun getTitle() : String {
            if MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.isReveal {
                let title =  self.getMetadata()["title"] ?? MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
                return title
            }
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
        }

        pub fun getName(): String {
            if MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.isReveal {
                let name = self.getMetadata()["name"] ?? self.getTitle()
                return name.concat(" #").concat(self.nftData.serialNumber.toString())
            }
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
        }

        pub fun getDescription() : String {
            if MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.isReveal {
                return self.getMetadata()["description"] ?? MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.description ?? ""
            }
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.description ?? ""

        }

        // receiver: Capability<&AnyResource{FungibleToken.Receiver}>, cut: UFix64, description: String
        pub fun getRoyalties(): MetadataViews.Royalties {
            if self.isInMarket {
                return self.getRoyaltiesMarket()
            }
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.getRoyalties()
        }

        pub fun getRoyaltiesMarket(): MetadataViews.Royalties {
            return MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.getRoyaltiesMarket()
        }

        access(account) fun setInMarket(_ value: Bool) {
            self.isInMarket = value
            emit SetInMarket(nftID: self.id)
        }

        pub fun getIsInMarket(): Bool {
            return self.isInMarket
        }

        access(account) fun createComment(comment: String): CommentData {
            let newComment = CommentData(
                nftID: self.id,
                comment: comment
            )
            self.commentData[newComment.commentId] = newComment
            return newComment
        }

        access(account) fun updateComment(commentId: UInt64, comment: String) {
            let commentData = self.commentData[commentId] ?? panic("COMMENT_NOT_FOUND")
            self.commentData[commentId] = commentData.update(comment: comment)
        }

        access(account) fun deleteComment(commentId: UInt64) {
            self.commentData.remove(key: commentId)
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
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.getName(),
                        description: self.getDescription(),
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.getImage()
                        )
                )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.nftData.serialNumber
                )
                case Type<MetadataViews.Royalties>():
                    return self.getRoyalties()
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://mikosea.io/nft/detail/mikoseav2/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MIKOSEANFTV2.CollectionStoragePath,
                        publicPath: MIKOSEANFTV2.CollectionPublicPath,
                        providerPath: MIKOSEANFTV2.PrivatePath,
                        publicCollection: Type<&MIKOSEANFTV2.Collection{MIKOSEANFTV2.CollectionPublic}>(),
                        publicLinkedType: Type<&MIKOSEANFTV2.Collection{MIKOSEANFTV2.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MIKOSEANFTV2.Collection{MIKOSEANFTV2.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MIKOSEANFTV2.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let bannerImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://storage.googleapis.com/studio-design-asset-files/projects/1pqD36e6Oj/s-300x50_aa59a692-741b-408b-aea3-bcd25d29c6bd.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    let projectImageType = MIKOSEANFTV2.getProjectImageType(self.nftData.projectId) ?? "png"
                    let squareImage = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.thumbnail
                        ),
                        mediaType: "image/".concat(projectImageType)
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.title,
                        description: MIKOSEANFTV2.getProjectById(self.nftData.projectId)!.description,
                        externalURL: MetadataViews.ExternalURL("https://mikosea.io/"),
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/MikoSea_io")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits = ["image", "imageURL", "payment_uuid", "fileExt", "fileType"]
                    let traitsView = MetadataViews.dictToTraits(dict: self.getMetadata(), excludedNames: excludedTraits)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeStr = self.getMetadata()["mintedTime"]
                    if mintedTimeStr != nil {
                        let mintedTime = UInt64.fromString(mintedTimeStr!)
                        let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: mintedTime, displayType: "Date", rarity: nil)
                        traitsView.addTrait(mintedTimeTrait)
                    }

                    return traitsView
            }
            return nil
        }
    }

    //------------------------------------------------------------
    // Collection Public Interface
    //------------------------------------------------------------

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun borrowMIKOSEANFTV2(id: UInt64): &MIKOSEANFTV2.NFT?
        pub fun borrowMIKOSEANFTV2s(): [&MIKOSEANFTV2.NFT]
        pub fun getCommentByNftID(nftID: UInt64): [CommentData]
    }

    //------------------------------------------------------------
    // Collection Resource
    //------------------------------------------------------------

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        pub let commentNFTMap: {UInt64:UInt64}

        init () {
            self.ownedNFTs <- {}
            self.commentNFTMap = {}
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @MIKOSEANFTV2.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token

            // update owner
            if self.owner?.address != nil {
                MIKOSEANFTV2.nftHolderMap[id] = self.owner!.address
                emit Deposit(id: id, to: self.owner!.address)
            }
            destroy oldToken
        }

        pub fun borrowMIKOSEANFTV2(id: UInt64): &MIKOSEANFTV2.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &MIKOSEANFTV2.NFT
            } else {
                return nil
            }
        }

        pub fun borrowMIKOSEANFTV2s(): [&MIKOSEANFTV2.NFT] {
            let res: [&MIKOSEANFTV2.NFT] = []
            for id in self.ownedNFTs.keys {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
                if ref != nil {
                    res.append(ref! as! &MIKOSEANFTV2.NFT)
                }
            }
            return res
        }

        pub fun getCommentByNftID(nftID: UInt64): [CommentData] {
            return self.borrowMIKOSEANFTV2(id: nftID)?.commentData?.values ?? []
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner!.address)

            // update owner
            MIKOSEANFTV2.nftHolderMap.remove(key: withdrawID)

            // remove comment
            let comments = self.getCommentByNftID(nftID: withdrawID)
            for comment in comments {
                self.deleteComment(commentId: comment.commentId)
            }

            // remove is in market
            self.setInMarket(nftID: withdrawID, value: false)
            return <-token
        }

        pub fun transfer(nftID: UInt64, recipient: &{MIKOSEANFTV2.CollectionPublic}) {
            post {
                self.ownedNFTs[nftID] == nil: "The specified NFT was not transferred"
            }
            let nft <- self.withdraw(withdrawID: nftID)
            recipient.deposit(token: <- nft)

            let nftData = recipient.borrowMIKOSEANFTV2(id: nftID)!
            emit NFTTransferred(nftID: nftID, nftData: nftData.nftData, from: self.owner!.address, to: recipient.owner!.address)
        }

        pub fun burn(id: UInt64) {
            post {
                self.ownedNFTs[id] == nil: "The specified NFT was not burned"
            }
            destroy <- self.withdraw(withdrawID: id)
            emit NFTDestroy(nftID: id)
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            if self.ownedNFTs[id] != nil {
                return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
            }
            panic("NFT not found in collection.")
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let nftAs = nft as! &MIKOSEANFTV2.NFT
            return nftAs
        }

        /// Safe way to borrow a reference to an NFT that does not panic
        ///
        /// @param id: The ID of the NFT that want to be borrowed
        /// @return An optional reference to the desired NFT, will be nil if the passed id does not exist
        ///
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            if self.ownedNFTs[id] != nil {
                return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)
            }
            return nil
        }

        pub fun createComment(nftID: UInt64, comment: String) {
            let newComment = self.borrowMIKOSEANFTV2(id: nftID)?.createComment(comment: comment) ?? panic("NFT_NOT_FOUND")
            self.commentNFTMap[newComment.commentId] = nftID
        }

        pub fun updateComment(commentId: UInt64, comment: String) {
            let nftID = self.commentNFTMap[commentId] ?? panic("COMMENT_NOT_FOUND")
            self.borrowMIKOSEANFTV2(id: nftID)?.updateComment(commentId: commentId, comment: comment) ?? panic("NFT_NOT_FOUND")
        }

        pub fun deleteComment(commentId: UInt64) {
            if let nftID = self.commentNFTMap[commentId] {
                self.borrowMIKOSEANFTV2(id: nftID)?.deleteComment(commentId: commentId)
            }
        }

        pub fun setInMarket(nftID: UInt64, value: Bool) {
            if let nft = self.borrowMIKOSEANFTV2(id: nftID) {
                nft.setInMarket(value)
            }
        }

        pub fun updateMetadata(nftID: UInt64, metadata: {String: String}) {
            if let nft = self.borrowMIKOSEANFTV2(id: nftID) {
                nft.updateMetadata(metadata)
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // createEmptyCollection
    pub fun createEmptyCollection(): @MIKOSEANFTV2.Collection {
        return <- create Collection()
    }

    //------------------------------------------------------------
    // Minter
    //------------------------------------------------------------
    pub resource Minter {
        // mint nfts and return list of nftID
        pub fun mintNFTs(projectId: UInt64, quantity: UInt64, images: [String], metadatas: [{String:String}], recipientCap: Capability<&{CollectionPublic}>): [UInt64] {
            let project = MIKOSEANFTV2.getProjectById(projectId) ?? panic("NOT_FOUND_PROJECT")
            return project.batchMintNFT(quantity: quantity, images: images, metadatas: metadatas, recipientCap: recipientCap)
        }

        pub fun revealProject(_ projectId: UInt64) {
            MIKOSEANFTV2.getProjectById(projectId)!.reveal()
        }

        pub fun unRevealProject(_ projectId: UInt64) {
            MIKOSEANFTV2.getProjectById(projectId)!.unRevealProject()
        }
    }


    //------------------------------------------------------------
    // Admin
    //------------------------------------------------------------
    pub resource Admin {
        pub var projectData: @{UInt64: ProjectData}

        init() {
            self.projectData <- {}
        }

        pub fun getProjectById(_ projectId: UInt64): &ProjectData? {
            return &self.projectData[projectId] as &ProjectData?
        }

        pub fun getProjectFromNftId(_ nftID: UInt64): &ProjectData? {
            if nftID > 0 && nftID <= MIKOSEANFTV2.totalSupply {
                for projectId in self.projectData.keys {
                    if (&self.projectData[projectId] as &ProjectData?)!.nftMinted.contains(nftID) {
                        return (&self.projectData[projectId] as &ProjectData?)
                    }
                }
            }
            return nil
        }

        pub fun getProjects(): [&ProjectData] {
            let res: [&ProjectData] = []
            for projectId in self.projectData.keys {
                res.append(self.getProjectById(projectId)!)
            }
            return res
        }

        pub fun createProject(
            title: String,
            description: String,
            thumbnail: String,
            creatorAddress: Address,
            platformFee: UFix64,
            creatorMarketFee: UFix64,
            platformMarketFee: UFix64,
            mintPrice: UFix64,
            maxSupply: UInt64,
            isPublic: Bool,
            metadata: {String: AnyStruct}
        ) {
            let projectData <- create ProjectData(
                title: title,
                description: description,
                thumbnail: thumbnail,
                creatorAddress: creatorAddress,
                platformFee: platformFee,
                creatorMarketFee: creatorMarketFee,
                platformMarketFee: platformMarketFee,
                mintPrice: mintPrice,
                maxSupply: maxSupply,
                isPublic: isPublic,
                metadata: metadata
            )
            let old <- self.projectData[projectData.projectId] <- projectData
            destroy old
        }

        pub fun updateProject(
            projectId: UInt64,
            title: String?,
            description: String?,
            thumbnail: String?,
            creatorAddress: Address?,
            platformFee: UFix64?,
            creatorMarketFee: UFix64?,
            platformMarketFee: UFix64?,
            mintPrice: UFix64?,
            maxSupply: UInt64?,
            metadata: {String: AnyStruct}?
        ) {
            let projectData = self.getProjectById(projectId) ?? panic("PROJECT_NOT_FOUND")
            projectData.update(
                title: title,
                description: description,
                thumbnail: thumbnail,
                creatorAddress: creatorAddress,
                platformFee: platformFee,
                creatorMarketFee: creatorMarketFee,
                platformMarketFee: platformMarketFee,
                mintPrice: mintPrice,
                maxSupply: maxSupply,
                metadata: metadata
            )
        }

        pub fun publicProject(projectId: UInt64) {
            self.getProjectById(projectId)?.public() ?? panic("PROJECT_NOT_FOUND")
        }

        pub fun unPublicProject(projectId: UInt64) {
            self.getProjectById(projectId)?.unPublic() ?? panic("PROJECT_NOT_FOUND")
        }

        pub fun updateTokenPublicPath(_ path: PublicPath){
            MIKOSEANFTV2.tokenPublicPath = path
            MIKOSEANFTV2.mikoseaCap = getAccount(self.owner!.address).getCapability<&{FungibleToken.Receiver}>(path)
        }

        pub fun createMinter(): @Minter{
            return <- create Minter()
        }

        destroy() {
            destroy self.projectData
        }
    }

    // getOwner
    // Gets the current owner of the given item
    pub fun getHolder(nftID: UInt64): Address? {
        if nftID > 0 && nftID <= self.totalSupply {
            return MIKOSEANFTV2.nftHolderMap[nftID]
        }
        return nil
    }

    pub fun getProjectById(_ projectId: UInt64): &ProjectData? {
        return self.account.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!.getProjectById(projectId)
    }

    pub fun getProjectImageType(_ projectId: UInt64): String? {
        let str = MIKOSEANFTV2.getProjectById(projectId)?.thumbnail ?? ""
        if str.length == 0 {
            return nil
        }
        var res = ""
        let len = str.length
        var i = str.length-1
        while(i>0){
            if str[i] == "." {
            i = i+1
            while(i<str.length){
                res = res.concat(str[i].toString())
                i = i+1
            }
            return res
            }
            i = i-1
        }
        return res
    }

    pub fun getProjectFromNftId(_ nftID: UInt64): &ProjectData? {
        return self.account.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!.getProjectFromNftId(nftID)
    }

    pub fun getProjects(): [&ProjectData] {
        return self.account.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!.getProjects()
    }

  //------------------------------------------------------------
  // Initializer
  //------------------------------------------------------------
    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MIKOSEANFTV2Collections
        self.CollectionPublicPath = /public/MIKOSEANFTV2Collections
        self.PrivatePath = /private/MIKOSEANFTV2PrivatePath
        self.MinterStoragePath = /storage/MIKOSEANFTV2Minters
        self.AdminStoragePath = /storage/MIKOSEANFTV2Admin
        self.AdminPublicPath = /public/MIKOSEANFTV2Admin

        // default token path
        self.tokenPublicPath = /public/flowTokenReceiver
        self.mikoseaCap = self.account.getCapability<&{FungibleToken.Receiver}>(self.tokenPublicPath)

        self.totalSupply = 0
        self.nextProjectId = 1
        self.nextCommentId = 1
        self.nftHolderMap = {}

        let admin <- create Admin()
        let minter <- admin.createMinter()
        self.account.save(<- admin, to: self.AdminStoragePath)

        self.account.save(<- minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
