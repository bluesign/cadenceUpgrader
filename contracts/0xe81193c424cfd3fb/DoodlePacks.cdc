import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import DoodlePackTypes from "./DoodlePackTypes.cdc"
import OpenDoodlePacks from "./OpenDoodlePacks.cdc"

pub contract DoodlePacks: NonFungibleToken {
	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, typeId:UInt64)
	pub event Opened(id: UInt64, address: Address)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub var totalSupply: UInt64
	pub var currentPackTypesSerialNumber: {UInt64: UInt64} // packTypeId => currentPackTypeSerialNumber
	pub var packTypesCurrentSupply: {UInt64: UInt64} // packTypeId => currentSupply

	access(self) let extra: {String: AnyStruct}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		pub let serialNumber: UInt64
		pub let typeId: UInt64

		init(typeId: UInt64) {
			pre {
				DoodlePackTypes.getPackType(id: typeId) != nil: "Invalid pack type"
			}
			DoodlePacks.totalSupply = DoodlePacks.totalSupply + 1
			DoodlePacks.currentPackTypesSerialNumber[typeId] = (DoodlePacks.currentPackTypesSerialNumber[typeId] ?? 0) + 1
			DoodlePacks.packTypesCurrentSupply[typeId] = (DoodlePacks.packTypesCurrentSupply[typeId] ?? 0) + 1

			self.id = self.uuid
			self.serialNumber = DoodlePacks.currentPackTypesSerialNumber[typeId]!
			self.typeId = typeId
		}

		pub fun getPackType(): DoodlePackTypes.PackType {
			return DoodlePackTypes.getPackType(id: self.typeId)!
		}

		destroy() {
            DoodlePacks.packTypesCurrentSupply[self.typeId] = DoodlePacks.packTypesCurrentSupply[self.typeId]! - 1
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
					// let cut: UFix64 = packType.saleInfo.secondaryMarketCut
					// let dapperReceiver = DoodlePackTypes.getPaymentReceiver(paymentToken: DoodlePackTypes.PaymentToken.DUC)!
					// let dapperReceiverAddress = dapperReceiver.address
					let dapperReceiverAddress = 0x014e9ddc4aaaf557
					let cut = 0.05

					let description: String = "Doodle Royalty"

					let doodlesMerchantAccountMainnet="0x014e9ddc4aaaf557"
					//royalties if we sell on something else then DapperWallet cannot go to the address stored in the contract, and Dapper will not allow us to setup forwarders for Flow/USDC
					if dapperReceiverAddress.toString() == doodlesMerchantAccountMainnet {
						//this is an account that have setup a forwarder for DUC/FUT to the merchant account of Doodles.
						let royaltyAccountWithDapperForwarder = getAccount(0x12be92985b852cb8)
						let cap = royaltyAccountWithDapperForwarder.getCapability<&{FungibleToken.Receiver}>(/public/fungibleTokenSwitchboardPublic)
						return MetadataViews.Royalties([MetadataViews.Royalty(receiver:cap, cut: cut, description: description)])
					}
					let doodlesMerchanAccountTestnet="0xd5b1a1553d0ed52e"
					if dapperReceiverAddress.toString() == doodlesMerchanAccountTestnet {
						//on testnet we just send this to the main vault, it is not important
						let cap = DoodlePacks.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
						return MetadataViews.Royalties([MetadataViews.Royalty(receiver:cap, cut: cut, description: description)])
					}
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
			return DoodlePacks.resolveView(view)
		}
	}

	pub resource interface CollectionPublic {
		pub fun deposit(token: @NonFungibleToken.NFT)
		pub fun getIDs(): [UInt64]
		pub fun contains(_ id: UInt64): Bool
		pub fun getPacksLeft(): Int
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
		pub fun borrowDoodlePack(id: UInt64): &DoodlePacks.NFT? 
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic, MetadataViews.ResolverCollection {
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Could not withdraw nft")

			let nft <- token as! @NFT

			emit Withdraw(id: nft.id, from: self.owner?.address)

			return <-nft
		}

		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @DoodlePacks.NFT

			let id: UInt64 = token.id

			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)

			destroy oldToken
		}

		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		pub fun contains(_ id: UInt64): Bool {
			return self.ownedNFTs.containsKey(id)
		}

		pub fun getPacksLeft(): Int {
			return self.ownedNFTs.length
		}

		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowDoodlePack(id: UInt64): &DoodlePacks.NFT? {
			if self.ownedNFTs[id] != nil {
				let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
				return ref as! &DoodlePacks.NFT
			} else {
				return nil
			}
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let pack = nft as! &NFT
			return pack
		}

		destroy() {
			destroy self.ownedNFTs
		}

		init () {
			self.ownedNFTs <- {}
		}
	}

	access(account) fun mintNFT(recipient: &{NonFungibleToken.Receiver}, typeId: UInt64) {
		let packType = DoodlePackTypes.getPackType(id: typeId) ?? panic("Invalid pack type")
		assert(packType.maxSupply == nil || DoodlePackTypes.getPackTypesMintedCount(typeId: packType.id) < packType.maxSupply!, message: "Max supply reached")
		
		let pack: @DoodlePacks.NFT <- create DoodlePacks.NFT(typeId: typeId)

		DoodlePackTypes.addMintedCountToPackType(typeId: typeId, amount: 1)

		emit Minted(id: pack.id, typeId: typeId)
		
		recipient.deposit(token: <-pack)
	}

	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub fun open(collection: &{DoodlePacks.CollectionPublic, NonFungibleToken.Provider}, packId: UInt64): @OpenDoodlePacks.NFT {
		let pack = collection.borrowDoodlePack(id: packId) ?? panic("Could not borrow a reference to the pack")

		let openPack <- OpenDoodlePacks.mintNFT(id: pack.id, serialNumber: pack.serialNumber, typeId: pack.typeId)
		emit Opened(id: packId, address: collection.owner!.address)
		destroy <- collection.withdraw(withdrawID: packId)
		return <- openPack
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
					name: "Doodle Packs",
					description: "Doodle Packs can be open to obtain multiple NFTs!",
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
					storagePath: DoodlePacks.CollectionStoragePath,
					publicPath: DoodlePacks.CollectionPublicPath,
					providerPath: DoodlePacks.CollectionPrivatePath,
					publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {
						return <- DoodlePacks.createEmptyCollection()
					}
				)
        }
        return nil
    }

	init() {
		self.CollectionStoragePath = /storage/DoodlePacksCollection
		self.CollectionPublicPath = /public/DoodlePacksCollection
		self.CollectionPrivatePath = /private/DoodlePacksCollection

		self.totalSupply = 0
		self.currentPackTypesSerialNumber = {}
		self.packTypesCurrentSupply = {}

		self.extra = {}

		self.account.save<@NonFungibleToken.Collection>(<- DoodlePacks.createEmptyCollection(), to: DoodlePacks.CollectionStoragePath)
		self.account.link<&DoodlePacks.Collection{DoodlePacks.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			DoodlePacks.CollectionPublicPath,
			target: DoodlePacks.CollectionStoragePath
		)
		self.account.link<&DoodlePacks.Collection{DoodlePacks.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			DoodlePacks.CollectionPrivatePath,
			target: DoodlePacks.CollectionStoragePath
		)

		emit ContractInitialized()

	}
}


 