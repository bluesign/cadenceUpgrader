import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Random from "./Random.cdc"
import DoodlePackTypes from "./DoodlePackTypes.cdc"
import Wearables from "./Wearables.cdc"
import Redeemables from "./Redeemables.cdc"

pub contract OpenDoodlePacks: NonFungibleToken {
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Burned(id: UInt64)
    pub event Minted(id: UInt64, typeId: UInt64, block: UInt64)
	pub event Revealed(id: UInt64)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

    pub var totalSupply: UInt64
	pub var packTypesCurrentSupply: {UInt64: UInt64} // packTypeId => currentSupply
	pub var packTypesTotalBurned: {UInt64: UInt64} // packTypeId => totalBurned

    // Amount of blocks that need to pass before a pack can be revealed.
    // This is part of the commit-reveal scheme to prevent transaction rollbacks.
	pub var revealBlocks: UInt64

    access(self) let extra: {String: AnyStruct}

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
		pub let serialNumber: UInt64
		pub let typeId: UInt64
		pub let openedBlock: UInt64
    
        init(id: UInt64, serialNumber: UInt64, typeId: UInt64) {
            pre {
				DoodlePackTypes.getPackType(id: typeId) != nil: "Invalid pack type"
			}

            self.id = id
            self.serialNumber = serialNumber
            self.typeId = typeId
            self.openedBlock = getCurrentBlock().height

	        OpenDoodlePacks.totalSupply = OpenDoodlePacks.totalSupply + 1
            OpenDoodlePacks.packTypesCurrentSupply[typeId] = (OpenDoodlePacks.packTypesCurrentSupply[typeId] ?? 0) + 1
        }

        pub fun getPackType(): DoodlePackTypes.PackType {
			return DoodlePackTypes.getPackType(id: self.typeId)!
		}

        pub fun canReveal(): Bool {
            return getCurrentBlock().height >= self.openedBlock + OpenDoodlePacks.revealBlocks
        }

        destroy() {
            OpenDoodlePacks.packTypesCurrentSupply[self.typeId] = OpenDoodlePacks.packTypesCurrentSupply[self.typeId]! - 1
            OpenDoodlePacks.packTypesTotalBurned[self.typeId] = (OpenDoodlePacks.packTypesTotalBurned[self.typeId] ?? 0) + 1
		}

        pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>(),
				Type<MetadataViews.Royalties>(),
				Type<MetadataViews.ExternalURL>(),
				Type<MetadataViews.NFTCollectionDisplay>(),
				Type<MetadataViews.NFTCollectionData>(),
				Type<MetadataViews.Traits>(),
				Type<MetadataViews.Editions>()
			]
		}

        pub fun resolveView(_ view: Type): AnyStruct? {
			let packType: DoodlePackTypes.PackType = DoodlePackTypes.getPackType(id: self.typeId)!
			switch view {
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(
						name: packType.name,
						description: packType.description,
						thumbnail: packType.thumbnail.file,
					)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://doodles.app")
				case Type<MetadataViews.Royalties>():
					return []
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([
						MetadataViews.Edition(
							name: packType.name,
							number: self.serialNumber,
							max: nil
						)
					])
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits([
						MetadataViews.Trait(
							name: "name",
							value: packType.name,
							displayType: "string",
							rarity: nil,
						),
                        MetadataViews.Trait(
							name: "pack_type_id",
							value: packType.id.toString(),
							displayType: "string",
							rarity: nil,
						)
					])
			}
			return OpenDoodlePacks.resolveView(view)
		}

    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowOpenDoodlePack(id: UInt64): &OpenDoodlePacks.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow OpenDoodlePacks reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            let token <- token as! @OpenDoodlePacks.NFT

            let id: UInt64 = token.id

            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        pub fun borrowOpenDoodlePack(id: UInt64): &OpenDoodlePacks.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &OpenDoodlePacks.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let openDoodlePack = nft as! &OpenDoodlePacks.NFT
            return openDoodlePack
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    access(account) fun mintNFT(id: UInt64, serialNumber: UInt64, typeId: UInt64): @OpenDoodlePacks.NFT {
        let openPack <- create NFT(id: id, serialNumber: serialNumber, typeId: typeId)
        emit Minted(id: id, typeId: typeId, block: openPack.openedBlock)
        return <- openPack
    }

    access(account) fun updateRevealBlocks(revealBlocks: UInt64) {
        OpenDoodlePacks.revealBlocks = revealBlocks
    }

    pub struct MintableTemplateDistribution {
        pub let packType: DoodlePackTypes.PackType
        pub var templateDistribution: DoodlePackTypes.TemplateDistribution
        pub let totalProbability: UFix64
        pub var mintedAmount: UInt8
        pub let ponderation: UFix64

        init(packType: DoodlePackTypes.PackType, templateDistribution: DoodlePackTypes.TemplateDistribution) {
            self.packType = packType
            self.templateDistribution = templateDistribution
            self.mintedAmount = 0

            // Calculate total probability of the distribution based on the probability of each template.
            var totalProbability = 0.0
            for distribution in templateDistribution.templateProbabilities {
                totalProbability = totalProbability + distribution.probability
            }
            self.totalProbability = totalProbability

            // Only ponderate if there is a limited supply (at distribution and pack levels)
            if templateDistribution.maxMint == nil || packType.maxSupply == nil {
                self.ponderation = 1.0
            } else {
                // Ponderation will ensure that very low probability templates (like 1:1) are not minted in the last pack,
                // because fixed probabilities will always benefit the distributions with highest probability.
                // In an scenario of limited supply, this could lead to situations where a template with 1:1 probability
                // is minted not because it was selected, but rather because the other templates didn't have any supply left.
                
                // Ponderation will ensure that the probability of a template is not fixed, but rather it is adjusted
                // based on the remaining supply of the distribution.
                self.ponderation = 1.0 - UFix64(
                    DoodlePackTypes.getTemplateDistributionMintedCount(
                        typeId: packType.id,
                        templateDistributionId: templateDistribution.id
                    )
                ) / UFix64(templateDistribution.maxMint!)
            }
        }

        access(contract) fun addMinted() {
            self.mintedAmount = self.mintedAmount + 1
        }
    }

    pub fun reveal(collection: &{OpenDoodlePacks.CollectionPublic, NonFungibleToken.Provider}, packId: UInt64, receiverAddress: Address) {
        let pack = collection.borrowOpenDoodlePack(id: packId) ?? panic ("This pack is not in your collection")
        if !pack.canReveal() {
            panic("You can only reveal the pack after ".concat(OpenDoodlePacks.revealBlocks.toString()).concat(" blocks"))
        }
        let seedHeight = pack.openedBlock + OpenDoodlePacks.revealBlocks

        let packType = pack.getPackType()

        var randomNumbers: [UFix64] = self.getRandomNumbersFromPack(pack: pack, amount: packType.amountOfTokens)

        var remainingDistributions: [OpenDoodlePacks.MintableTemplateDistribution] = []
        var minAmountToMint: UInt64 = 0
        for templateDistribution in packType.templateDistributions {
            if templateDistribution.maxMint != nil
                && DoodlePackTypes.getTemplateDistributionMintedCount(typeId: packType.id, templateDistributionId: templateDistribution.id) >= templateDistribution.maxMint!
            {
                continue
            }
            remainingDistributions.append(
                OpenDoodlePacks.MintableTemplateDistribution(packType: packType, templateDistribution: templateDistribution)
            )
            minAmountToMint = minAmountToMint + UInt64(templateDistribution.minAmount)
        }

        if (minAmountToMint > 0) {
            remainingDistributions = OpenDoodlePacks.revealRemainingDistributionsMinAmount(
                receiverAddress: receiverAddress,
                randomNumbers: randomNumbers,
                packId: packId,
                packType: packType,
                remainingDistributions: remainingDistributions
            )
            randomNumbers = randomNumbers.slice(from: Int(minAmountToMint), upTo: randomNumbers.length)
        }

        while randomNumbers.length > 0 {
            let randomNumber = randomNumbers.removeFirst()
            remainingDistributions = OpenDoodlePacks.revealRemainingDistributions(
                receiverAddress: receiverAddress,
                packId: packId,
                packType: packType,
                randomNumber: randomNumber,
                remainingDistributions: remainingDistributions
            )
        }

        emit Revealed(id: packId)

        destroy <- collection.withdraw(withdrawID: packId)
        emit Burned(id: packId)
    }

    access(contract) fun revealRemainingDistributionsMinAmount(
        receiverAddress: Address,
        randomNumbers: [UFix64],
        packId: UInt64,
        packType: DoodlePackTypes.PackType,
        remainingDistributions: [OpenDoodlePacks.MintableTemplateDistribution]
    ): [OpenDoodlePacks.MintableTemplateDistribution] {
        let completedDistributionIndexes: [Int] = []
        for index, remainingDistribution in remainingDistributions {
            let templateDistribution = remainingDistribution.templateDistribution
            while remainingDistribution.mintedAmount < templateDistribution.minAmount
                && (templateDistribution.maxMint == nil || DoodlePackTypes.getTemplateDistributionMintedCount(typeId: packType.id, templateDistributionId: templateDistribution.id) < templateDistribution.maxMint!)
            {
                var accumulatedProbability: UFix64 = 0.0
                let random = randomNumbers.remove(at: 0)
                let adaptedProbability: UFix64 = random * remainingDistribution.totalProbability
                for templateProbability in templateDistribution.templateProbabilities {
                    accumulatedProbability = accumulatedProbability + templateProbability.probability
                    if accumulatedProbability >= adaptedProbability {
                        OpenDoodlePacks.mintNFTFromPack(
                            collection: templateProbability.collection,
                            receiverAddress: receiverAddress,
                            templateId: templateProbability.templateId,
                            packId: packId,
                            packType: packType
                        )
                        remainingDistribution.addMinted()
                        DoodlePackTypes.addMintedCountToTemplateDistribution(
                            typeId: packType.id,
                            templateDistributionId: templateDistribution.id,
                            amount: 1
                        )

                        if remainingDistribution.mintedAmount == templateDistribution.maxAmount
                            || (templateDistribution.maxMint != nil && DoodlePackTypes.getTemplateDistributionMintedCount(typeId: packType.id, templateDistributionId: templateDistribution.id) == templateDistribution.maxMint!)
                        {
                            completedDistributionIndexes.append(index)
                        }
                        break
                    }
                }
            }
        }
        let updatedRemainingDistributions: [OpenDoodlePacks.MintableTemplateDistribution] = []
        for index, remainingDistribution in remainingDistributions {
            if !completedDistributionIndexes.contains(index) {
                updatedRemainingDistributions.append(remainingDistribution)
            }
        }
        return updatedRemainingDistributions
    }

    access(contract) fun revealRemainingDistributions(
        receiverAddress: Address,
        packId: UInt64,
        packType: DoodlePackTypes.PackType,
        randomNumber: UFix64,
        remainingDistributions: [OpenDoodlePacks.MintableTemplateDistribution]
    ): [OpenDoodlePacks.MintableTemplateDistribution] {
        var remainingPackProbability: UFix64 = 0.0
        var accumulatedPackProbability: UFix64 = 0.0

        for distribution in remainingDistributions {
            remainingPackProbability = remainingPackProbability + distribution.totalProbability * distribution.ponderation
        }

        let adaptedProbability = randomNumber * remainingPackProbability

        var accumulatedProbability: UFix64 = 0.0
        for index, remainingDistribution in remainingDistributions {
            let templateDistribution = remainingDistribution.templateDistribution
            for templateProbability in templateDistribution.templateProbabilities {
                accumulatedProbability = accumulatedProbability + templateProbability.probability * remainingDistribution.ponderation
                if accumulatedProbability >= adaptedProbability {
                    OpenDoodlePacks.mintNFTFromPack(
                        collection: templateProbability.collection,
                        receiverAddress: receiverAddress,
                        templateId: templateProbability.templateId,
                        packId: packId,
                        packType: packType
                    )
                    remainingDistribution.addMinted()
                    DoodlePackTypes.addMintedCountToTemplateDistribution(
                        typeId: packType.id,
                        templateDistributionId: templateDistribution.id,
                        amount: 1
                    )
                    remainingDistributions.insert(at: index, remainingDistribution)
                    remainingDistributions.remove(at: index + 1)
                    if remainingDistribution.mintedAmount == templateDistribution.maxAmount
                        || (templateDistribution.maxMint != nil  && DoodlePackTypes.getTemplateDistributionMintedCount(typeId: packType.id, templateDistributionId: templateDistribution.id) == templateDistribution.maxMint!)
                    {
                        remainingDistributions.remove(at: index)
                    }
                    return remainingDistributions
                }
            }
        }
        return remainingDistributions
    }

    access(self) fun mintNFTFromPack(
        collection: DoodlePackTypes.Collection,
        receiverAddress: Address,
        templateId: UInt64,
        packId: UInt64,
        packType: DoodlePackTypes.PackType
    ) {
        switch collection {
            case DoodlePackTypes.Collection.Wearables:
                let recipient = getAccount(receiverAddress).getCapability<&{NonFungibleToken.Receiver}>(Wearables.CollectionPublicPath).borrow()
                    ?? panic("Could not borrow wearables receiver capability")
                Wearables.mintNFT(
                    recipient: recipient,
                    template: templateId,
                    context: {
                        "pack_id": packId.toString(),
                        "pack_name": packType.name
                    },
                )
            case DoodlePackTypes.Collection.Redeemables:
                let recipient = getAccount(receiverAddress).getCapability<&{NonFungibleToken.Receiver}>(Redeemables.CollectionPublicPath).borrow()
                    ?? panic("Could not borrow redeemables receiver capability")
                Redeemables.mintNFT(recipient: recipient, templateId: templateId)
        }
        
    }

    access(self) fun getRandomNumbersFromPack(pack: &OpenDoodlePacks.NFT, amount: UInt8): [UFix64] {
        let hash: [UInt8] = HashAlgorithm.SHA3_256.hash(pack.id.toBigEndianBytes())
        let blockHash = getBlock(at: pack.openedBlock + OpenDoodlePacks.revealBlocks)!.id
        for bit in blockHash  {
			hash.append(bit)
		}
        return Random.generateWithBytesSeed(seed: hash, amount: amount)
    }

    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.NFTCollectionData>()
        ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionDisplay>():
                return MetadataViews.NFTCollectionDisplay(
                    name: "Open Doodle Packs",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://doodles.app"),
                    squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "", path: nil), mediaType:"image/png"),
                    bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "", path: nil), mediaType:"image/png"),
                    socials: {
                        "instagram": MetadataViews.ExternalURL("https://www.instagram.com/thedoodles"),
                        "discord": MetadataViews.ExternalURL("https://discord.gg/doodles"),
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/doodles")
                    }
                )
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: OpenDoodlePacks.CollectionStoragePath,
                    publicPath: OpenDoodlePacks.CollectionPublicPath,
                    providerPath: OpenDoodlePacks.CollectionPrivatePath,
                    publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                    publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {
                        return <- OpenDoodlePacks.createEmptyCollection()
                    }
                )
        }
        return nil
    }

    init() {
        self.CollectionStoragePath = /storage/OpenDoodlePacksCollection
        self.CollectionPublicPath = /public/OpenDoodlePacksCollection
		self.CollectionPrivatePath = /private/OpenDoodlePacksCollection

        self.totalSupply = 0
		self.packTypesCurrentSupply = {}
		self.packTypesTotalBurned = {}
		self.revealBlocks = 1

        self.extra = {}

        self.account.save<@NonFungibleToken.Collection>(<- OpenDoodlePacks.createEmptyCollection(), to: OpenDoodlePacks.CollectionStoragePath)
		self.account.link<&OpenDoodlePacks.Collection{OpenDoodlePacks.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			OpenDoodlePacks.CollectionPublicPath,
			target: OpenDoodlePacks.CollectionStoragePath
		)
		self.account.link<&OpenDoodlePacks.Collection{OpenDoodlePacks.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			OpenDoodlePacks.CollectionPrivatePath,
			target: OpenDoodlePacks.CollectionStoragePath
		)

        emit ContractInitialized()
    }
}
 