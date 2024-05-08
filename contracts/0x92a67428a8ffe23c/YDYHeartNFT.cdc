import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract YDYHeartNFT: NonFungibleToken {

    pub var totalSupply: UInt64
    pub var price: UFix64
    pub var isMintingEnabled: Bool
    
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Bought(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub enum Rarity: UInt8 {
        pub case common
        pub case rare
        pub case legendary
        pub case epic
    }

    pub fun rarityToString(_ rarity: Rarity): String {
        switch rarity {
            case Rarity.common:
                return "Common"
            case Rarity.rare:
                return "Rare"
            case Rarity.legendary:
                return "Legendary"
            case Rarity.epic:
                return "Epic"
        }

        return ""
    }

    pub fun calculateAttribute(_ rarity: Rarity): UInt64 {
        let commonRange = unsafeRandom() % 5 + 1; // 1-5
        let rareRange = unsafeRandom() % 6 + 4; // 4-9
        let legendaryRange = unsafeRandom() % 11 + 8; //8-18
        let epicRange = unsafeRandom() % 18 + 14; //14-31

        switch rarity {
            case Rarity.common: 
                return commonRange
            case Rarity.rare: 
                return rareRange
            case Rarity.legendary: 
                return legendaryRange
            case Rarity.epic: 
                return epicRange
        }

        return 0
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        pub let name: String
        pub let description: String
        pub let thumbnailCID: String

        pub let background: String
        pub let body: String
        pub let mouth: String
        pub let eyes: String
        pub let pants: String

        pub let zone: String

        pub var level: UInt64
        pub var lastLeveledUp: UFix64

        pub var stamina: UFix64
        pub var lastStaminaUpdate: UFix64
        pub var endurance: UFix64
        pub var lastEnduranceBoost: UFix64
        pub var efficiency: UFix64
        pub var lastEfficiencyBoost: UFix64
        pub var luck: UFix64
        pub var lastLuckBoost: UFix64

        pub let rarity: String

        pub var version: String
        pub var versionLaunchDate: String

        init(
            thumbnailCID: String,
            background: String,
            body: String,
            mouth: String,
            eyes: String,
            pants: String,
            rarity: Rarity,
            version: String,
            versionLaunchDate: String
        ) {
            YDYHeartNFT.totalSupply = YDYHeartNFT.totalSupply + 1
            self.id = YDYHeartNFT.totalSupply

            self.name = "Heart #".concat(self.id.toString())
            self.description = "YDY Heart NFT #".concat(self.id.toString())
            self.thumbnailCID = thumbnailCID
            self.background = background
            self.body = body
            self.mouth = mouth
            self.eyes = eyes
            self.pants = pants

            self.zone = background

            self.level = 1
            self.lastLeveledUp = getCurrentBlock().timestamp

            self.stamina = 100.0
            self.lastStaminaUpdate = getCurrentBlock().timestamp

            self.endurance = UFix64(YDYHeartNFT.calculateAttribute(rarity))
            self.lastEnduranceBoost = getCurrentBlock().timestamp
            self.efficiency = UFix64(YDYHeartNFT.calculateAttribute(rarity))
            self.lastEfficiencyBoost = getCurrentBlock().timestamp
            self.luck = UFix64(YDYHeartNFT.calculateAttribute(rarity))
            self.lastLuckBoost = getCurrentBlock().timestamp

            self.rarity = YDYHeartNFT.rarityToString(rarity)

            self.version = version
            self.versionLaunchDate = versionLaunchDate
        }

        access(contract) fun levelUp() {
            self.level = self.level + 1
            self.lastLeveledUp = getCurrentBlock().timestamp
        }

        access(contract) fun repair(_ points: UFix64) {
            if (self.stamina + points > 100.0) {
                self.stamina = 100.0
            } else {
                self.stamina = self.stamina + points
            }
            self.lastStaminaUpdate = getCurrentBlock().timestamp
        }

        access(contract) fun reduceStamina(_ points: UFix64) {
            pre {
                self.stamina > points: "Not enough stamina to reduce by"
            }
            self.stamina = self.stamina - points
            self.lastStaminaUpdate = getCurrentBlock().timestamp
        }

        access(contract) fun boostEndurance(_ points: UFix64) {
            self.endurance = self.endurance + points
            self.lastEnduranceBoost = getCurrentBlock().timestamp
        }

        access(contract) fun boostEfficiency(_ points: UFix64) {
            self.efficiency = self.efficiency + points
            self.lastEfficiencyBoost = getCurrentBlock().timestamp
        }

        access(contract) fun boostLuck(_ points: UFix64) {
            self.luck = self.luck + points
            self.lastLuckBoost = getCurrentBlock().timestamp
        }
    
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.thumbnailCID,
                            path: "/".concat(self.id.toString()).concat(".png")
                        )
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: YDYHeartNFT.CollectionStoragePath,
                        publicPath: YDYHeartNFT.CollectionPublicPath,
                        providerPath: /private/ydyNFTCollection,
                        publicCollection: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYNFTCollectionPublic}>(),
                        publicLinkedType: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&YDYHeartNFT.Collection{YDYHeartNFT.YDYNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-YDYHeartNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "YDY NFT",
                        description: "Collection of YDY NFTs.",
                        externalURL: MetadataViews.ExternalURL("https://www.ydylife.com/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/ydylife")
                        }
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        "https://www.ydylife.com/"
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        [MetadataViews.Royalty(recepient: getAccount(YDYHeartNFT.account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.075, description: "This is the royalty receiver for YDY NFTs")]
                    )  
            }
            return nil
        }
    }

    pub resource interface YDYNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowYDYNFT(id: UInt64): &YDYHeartNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow YDYNFT reference: the ID of the returned reference is incorrect"
            }
        }
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}
    }

    pub resource interface YDYNFTCollectionPrivate {
        access(account) fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT
    }

    pub resource Collection: YDYNFTCollectionPublic, YDYNFTCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @YDYHeartNFT.NFT
            let id: UInt64 = token.id
            emit Deposit(id: id, to: self.owner?.address)

            self.ownedNFTs[id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        pub fun borrowYDYNFT(id: UInt64): &YDYHeartNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)
                return ref as! &YDYHeartNFT.NFT?
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let ydyNFT = nft as! &YDYHeartNFT.NFT
            return ydyNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun buy(collectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>, payment: @FlowToken.Vault, quantity: UInt64) {
        pre {
            YDYHeartNFT.isMintingEnabled == true: "Minting is not enabled."
            payment.balance == YDYHeartNFT.price * UFix64(quantity): "Payment does not match the price."
		}
            
        let ydyWallet = self.account.getCapability(/public/flowTokenReceiver)
							.borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
		ydyWallet.deposit(from: <- payment)

        let ydyCollection = self.account.getCapability(YDYHeartNFT.CollectionPublicPath)
                                .borrow<&Collection{YDYHeartNFT.YDYNFTCollectionPublic, YDYHeartNFT.YDYNFTCollectionPrivate}>()
                                ?? panic("Can't get YDY's collection.")
        
        let availableNFTs = ydyCollection.getIDs()
        
        if (availableNFTs.length > 0) {
            let receiver = collectionCapability.borrow() ?? panic("Cannot borrow")

            let randomInt = unsafeRandom() % UInt64(availableNFTs.length)
            let id = availableNFTs[randomInt]
            
            let token <- ydyCollection.withdraw(withdrawID: id) as! @YDYHeartNFT.NFT

            emit Bought(id: id, to: receiver.owner?.address)

            receiver.deposit(token: <- token)
        } else {
            panic("No NFTs available.")
        }
    }

    pub resource Admin {

        pub fun mintNFT(
            thumbnailCID: String, background: String, body: String, mouth: String, eyes: String, pants: String, rarity: Rarity, version: String, versionLaunchDate: String
        ) {
            let accountOwnerCollection = YDYHeartNFT.account.borrow<&Collection{NonFungibleToken.CollectionPublic}>(from: YDYHeartNFT.CollectionStoragePath)!
            accountOwnerCollection.deposit(token: <-create YDYHeartNFT.NFT(thumbnailCID: thumbnailCID, background: background, body: body, mouth: mouth, eyes: eyes, pants: pants, rarity: rarity, version: version, versionLaunchDate: versionLaunchDate))
        }

        pub fun transferNFT(collectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): UInt64 {
            let ydyCollection = YDYHeartNFT.account.getCapability(YDYHeartNFT.CollectionPublicPath)
                                    .borrow<&Collection{YDYHeartNFT.YDYNFTCollectionPublic, YDYHeartNFT.YDYNFTCollectionPrivate}>()
                                    ?? panic("Can't get YDY's collection.")
            
            let availableNFTs = ydyCollection.getIDs()
            
            if (availableNFTs.length > 0) {
                let receiver = collectionCapability.borrow() ?? panic("Cannot borrow")

                let randomInt = unsafeRandom() % UInt64(availableNFTs.length)
                let id = availableNFTs[randomInt]
                
                let token <- ydyCollection.withdraw(withdrawID: id) as! @YDYHeartNFT.NFT

                receiver.deposit(token: <- token)

                return id
            } else {
                panic("No NFTs available.")
            }

            return 0
        }

        pub fun levelUp(id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            post {
                nft.level == beforeLevel + 1: "The level must be increased by 1"
            }
            
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeLevel= nft.level
            nft.levelUp();
            return nft;
        }

        pub fun repair(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeStamina = nft.stamina
            nft.repair(points);
            return nft
        }

        pub fun reduceStamina(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            post {
                nft.stamina == beforeStamina - points: "The stamina must be reduced by the points"
            }

            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")

            let beforeStamina = nft.stamina
            nft.reduceStamina(points)
            return nft
        }

        pub fun boostEndurance(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
        
            nft.boostEndurance(points)
            return nft
        }

        pub fun boostEfficiency(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
            
            nft.boostEfficiency(points)
            return nft
        }

        pub fun boostLuck(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection{YDYHeartNFT.YDYNFTCollectionPublic}>): &YDYHeartNFT.NFT? {
            let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
            let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
            
            nft.boostLuck(points)
            return nft
        }

        pub fun changePrice(price: UFix64) {
            YDYHeartNFT.price = price
        }

        pub fun changeIsMintingEnabled(isMinting: Bool) {
            YDYHeartNFT.isMintingEnabled = isMinting
        }
    }

    init() {
        self.totalSupply = 0
        self.price = 100.0
        self.isMintingEnabled = false

        self.CollectionStoragePath = /storage/YDYHeartNFTCollection
        self.CollectionPublicPath = /public/YDYHeartNFTCollection
        self.AdminStoragePath = /storage/YDYHeartNFTAdmin

        let admin <- create Admin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}