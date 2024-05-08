import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Redeemables: NonFungibleToken {
	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, address: Address, setId: UInt64, templateId: UInt64, name: String)
	pub event Redeemed(id: UInt64, address: Address, setId: UInt64, templateId: UInt64, name: String)
	pub event Burned(id: UInt64, address: Address, setId: UInt64, templateId: UInt64, name: String)
    pub event SetCreated(id: UInt64, name: String)
	pub event TemplateCreated(id: UInt64, setId: UInt64, name: String)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
	pub let AdminStoragePath: StoragePath

	pub var totalSupply: UInt64
	pub let sets: {UInt64 : Set}
	pub let templates: {UInt64 : Template}
	pub let templateNextSerialNumber: {UInt64 : UInt64}

	access(self) let extra: {String: AnyStruct}

	pub struct Set {
		pub let id: UInt64
		pub var name: String
		pub var canRedeem: Bool
        pub var redeemLimitTimestamp : UFix64
		pub var active: Bool
	    access(contract) let ownersRecord: [Address]

		access(self) let extra: {String: AnyStruct}

		init(name: String, canRedeem: Bool, redeemLimitTimestamp: UFix64, active: Bool) {
			self.id = UInt64(Redeemables.sets.keys.length) + 1
			self.name = name
			self.canRedeem = canRedeem
			self.redeemLimitTimestamp = redeemLimitTimestamp
			self.active = active
			self.ownersRecord = []
			self.extra = {}
		}

		pub fun getName() : String {
			return self.name
		}

		pub fun isRedeemLimitExceeded() : Bool {
			return self.redeemLimitTimestamp < getCurrentBlock().timestamp
		}

		access(contract) fun setActive(_ active: Bool) {
			self.active = active
		}

		access(contract) fun setCanRedeem(_ canRedeem: Bool) {
			self.canRedeem = canRedeem
		}

		access(contract) fun setRedeemLimitTimestamp(_ redeemLimitTimestamp: UFix64) {
			self.redeemLimitTimestamp = redeemLimitTimestamp
		}

		access(contract) fun addOwnerRecord(_ address: Address): Bool {
			if self.ownersRecord.contains(address) {
				return false
			}
			self.ownersRecord.append(address)
			return true
		}
	}

	pub struct Template {
		pub let id: UInt64
		pub let setId: UInt64
		pub var name: String
		pub var description: String
		pub var brand: String
		pub var royalties: [MetadataViews.Royalty]
		pub var type: String
		pub var thumbnail: MetadataViews.Media
		pub var image: MetadataViews.Media
		pub var active: Bool

		access(self) let extra: {String : AnyStruct}

		init(setId: UInt64, name: String, description: String, brand: String, royalties: [MetadataViews.Royalty], type: String, thumbnail: MetadataViews.Media, image: MetadataViews.Media, active: Bool) {
			pre {
				Redeemables.sets.containsKey(setId) : "Set does not exist. Id: ".concat(setId.toString())
			}
			self.id = UInt64(Redeemables.templates.keys.length) + 1
			self.setId = setId
			self.name = name
			self.description = description
			self.brand = brand
			self.royalties = royalties
			self.type = type
			self.thumbnail = thumbnail
			self.image = image
			self.active = active
			self.extra = {}
		}

		pub fun getSet() : Redeemables.Set {
			return Redeemables.sets[self.setId]!
		}

		access(contract) fun setActive(_ active: Bool) {
			self.active = active
		}

		pub fun getTermsOfService() : String? {
			return self.extra["termsOfService"] as! String?
		}

		access(contract) fun setTermsOfService(_ termsOfService: String) {
			self.extra["termsOfService"] = termsOfService
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id:UInt64
		pub let templateId: UInt64
		pub let serialNumber: UInt64

		access(self) let extra: {String : AnyStruct}

		init(templateId: UInt64) {
			self.id = self.uuid
			self.templateId = templateId
			self.serialNumber = Redeemables.templateNextSerialNumber[templateId] ?? 1
			self.extra = {}

			Redeemables.templateNextSerialNumber[templateId] = self.serialNumber + 1
			Redeemables.totalSupply = Redeemables.totalSupply + 1
		}

		pub fun getViews(): [Type] {
			return  [
				Type<MetadataViews.Display>(),
				Type<MetadataViews.Royalties>(),
				Type<MetadataViews.ExternalURL>(),
				Type<MetadataViews.NFTCollectionData>(),
				Type<MetadataViews.NFTCollectionDisplay>(),
				Type<MetadataViews.Traits>(),
				Type<MetadataViews.Editions>()
			]
		}

		pub fun getTemplate() : Template {
			return Redeemables.templates[self.templateId]!
		}

		pub fun getSet() : Set {
			return self.getTemplate().getSet()
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
				case Type<MetadataViews.Display>():
					let template = self.getTemplate()
					return MetadataViews.Display(
						name: template.name,
						description: template.description,
						thumbnail: template.thumbnail.file,
					)

				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://doodles.app")

				case Type<MetadataViews.Traits>():
					let template=self.getTemplate()
					let traits : [MetadataViews.Trait]= []

					traits.append(MetadataViews.Trait(
						name: "Name",
						value: template.name,
							displayType: "string",
						rarity: nil
					))

					traits.append(MetadataViews.Trait(
						name: "Brand",
						value: template.brand,
						displayType: "string",
						rarity: nil
					))

					traits.append(MetadataViews.Trait(
						name: "Set",
						value: template.getSet().name,
						displayType: "string",
						rarity: nil
					))

					traits.append(MetadataViews.Trait(
						name: "Type",
						value: template.type,
						displayType: "string",
						rarity: nil
					))

					traits.append(MetadataViews.Trait(
						name: "Redeem Limit Date",
						value: template.getSet().redeemLimitTimestamp,
						displayType: "Date",
						rarity: nil
					))

					if template.getTermsOfService() != nil {
						traits.append(MetadataViews.Trait(
							name: "Terms of Service",
							value: template.getTermsOfService(),
							displayType: "string",
							rarity: nil
						))
					}

					return MetadataViews.Traits(traits)

				case Type<MetadataViews.Royalties>():
					let royalties = self.getTemplate().royalties
					let royalty=royalties[0]

					let doodlesMerchantAccountMainnet="0x014e9ddc4aaaf557"
					//royalties if we sell on something else then DapperWallet cannot go to the address stored in the contract, and Dapper will not allow us to setup forwarders for Flow/USDC
					if royalty.receiver.address.toString() == doodlesMerchantAccountMainnet {

						//this is an account that have setup a forwarder for DUC/FUT to the merchant account of Doodles.
						let royaltyAccountWithDapperForwarder = getAccount(0x12be92985b852cb8)
						let cap = royaltyAccountWithDapperForwarder.getCapability<&{FungibleToken.Receiver}>(/public/fungibleTokenSwitchboardPublic)
						return MetadataViews.Royalties([MetadataViews.Royalty(receiver:cap, cut: royalty.cut, description:royalty.description)])
					}

					let doodlesMerchanAccountTestnet="0xd5b1a1553d0ed52e"
					if royalty.receiver.address.toString() == doodlesMerchanAccountTestnet {
						//on testnet we just send this to the main vault, it is not important
						let cap = Redeemables.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
						return MetadataViews.Royalties([MetadataViews.Royalty(receiver:cap, cut: royalty.cut, description:royalty.description)])
					}

					return royalties
			}

			return Redeemables.resolveView(view)
		}
	}

	pub resource interface RedeemablesCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowRedeemable(id: UInt64): &Redeemables.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow RedeemNFT reference: the ID of the returned reference is incorrect"
            }
        }
        pub fun redeem(id: UInt64)
        pub fun burnUnredeemedSet(set: Redeemables.Set)
    }

	pub resource Collection: RedeemablesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection  {
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- (self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")) as! @NFT

			assert(!token.getSet().isRedeemLimitExceeded(), message: "Set redeem limit timestamp reached")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			assert(!token.getSet().isRedeemLimitExceeded(), message: "Set redeem limit timestamp reached")

			let set = token.getSet()
			set.addOwnerRecord(self.owner!.address)
			Redeemables.sets[set.id] = set

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

		pub fun borrowRedeemable(id: UInt64) : &Redeemables.NFT? {
			if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Redeemables.NFT
            }

            return nil
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let redeemable = nft as! &NFT
			return redeemable
		}

		pub fun redeem(id: UInt64) {
			let nft <- (self.ownedNFTs.remove(key: id) ?? panic("missing NFT")) as! @NFT
			let template = nft.getTemplate()
			let set = template.getSet()

			assert(set.canRedeem, message: "Set not available to redeem: ".concat(set.name))
			assert(!set.isRedeemLimitExceeded(), message: "Set redeem limit timestamp reached: ".concat(set.name))

			emit Redeemed(id: id, address: self.owner!.address, setId: set.id, templateId: template.id, name: template.name)
			emit Burned(id: id, address: self.owner!.address, setId: set.id, templateId: template.id, name: template.name)

			destroy nft
		}

		pub fun burnUnredeemedSet(set: Redeemables.Set) {
			assert(set.isRedeemLimitExceeded(), message: "Set redeem limit timestamp not reached: ".concat(set.name))

			let ids = self.ownedNFTs.keys
			for id in ids {
				let nft = self.borrowRedeemable(id: id)!
				let template = nft.getTemplate()
				if template.getSet().id == set.id {
					emit Burned(id: id, address: self.owner!.address, setId: set.id, templateId: template.id, name: template.name)
					destroy <- self.ownedNFTs.remove(key: id)!
				}
			}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub resource Admin {}

	access(account) fun createSet(name: String, canRedeem: Bool, redeemLimitTimestamp: UFix64, active: Bool) {
		let set = Set(name: name, canRedeem: canRedeem, redeemLimitTimestamp: redeemLimitTimestamp, active: active)
		emit SetCreated(id: set.id, name: set.name)
		Redeemables.sets[set.id] = set
	}

	access(account) fun updateSetActive(setId: UInt64, active: Bool) {
		pre {
			Redeemables.sets.containsKey(setId) : "Set does not exist. Id: ".concat(setId.toString())
		}
		let set = Redeemables.sets[setId]!
		set.setActive(active)
		Redeemables.sets[setId] = set
	}

	access(account) fun updateSetCanRedeem(setId: UInt64, canRedeem: Bool) {
		pre {
			Redeemables.sets.containsKey(setId) : "Set does not exist. Id: ".concat(setId.toString())
		}
		let set = Redeemables.sets[setId]!
		set.setCanRedeem(canRedeem)
		Redeemables.sets[setId] = set
	}

	access(account) fun updateSetRedeemLimitTimestamp(setId: UInt64, redeemLimitTimestamp: UFix64) {
		pre {
			Redeemables.sets.containsKey(setId) : "Set does not exist. Id: ".concat(setId.toString())
		}
		let set = Redeemables.sets[setId]!
		set.setRedeemLimitTimestamp(redeemLimitTimestamp)
		Redeemables.sets[setId] = set
	}

	access(account) fun createTemplate(
		setId: UInt64,
		name: String,
		description: String,
		brand: String,
		royalties: [MetadataViews.Royalty],
		type: String,
		thumbnail: MetadataViews.Media, 
		image: MetadataViews.Media,
		active: Bool,
		extra: {String: AnyStruct}
	) {
		pre {
			Redeemables.sets.containsKey(setId) : "Set does not exist. Id: ".concat(setId.toString())
		}
		let template = Template(setId: setId, name: name, description: description, brand: brand, royalties: royalties, type: type, thumbnail: thumbnail, image: image, active: active)
		
		let termsOfService = extra["termsOfService"] as! String?
		if termsOfService != nil {
			template.setTermsOfService(termsOfService!)
		}

		emit TemplateCreated(id: template.id, setId: setId, name: name)
		Redeemables.templates[template.id] = template
	}

	access(account) fun updateTemplateActive(templateId: UInt64, active: Bool) {
		pre {
			Redeemables.templates.containsKey(templateId) : "Template does not exist. Id: ".concat(templateId.toString())
		}
		let template = Redeemables.templates[templateId]!
		template.setActive(active)
		Redeemables.templates[templateId] = template
	}
	
	access(account) fun mintNFT(recipient: &{NonFungibleToken.Receiver}, templateId: UInt64){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
			Redeemables.templates.containsKey(templateId) : "Template does not exist. Id: ".concat(templateId.toString())
		}

		let template = Redeemables.templates[templateId] ?? panic("Template does not exist. Id: ".concat(templateId.toString()))
		let set = Redeemables.sets[template.setId] ?? panic("Set does not exist. Id: ".concat(template.setId.toString()))

		assert(!set.isRedeemLimitExceeded(), message: "Set redeem limit timestamp reached: ".concat(set.name))
		assert(set.active, message: "Set not active: ".concat(set.name))
		assert(template.active, message: "Template not active: ".concat(template.name))

		var newNFT <- create NFT(templateId: templateId)
		
		emit Minted(id: newNFT.id, address:recipient.owner!.address, setId: set.id, templateId: template.id, name: template.name)

		recipient.deposit(token: <-newNFT)
	}

	access(account) fun burnUnredeemedSet(setId: UInt64) {
		let set = Redeemables.sets[setId] ?? panic("Set does not exist. Id: ".concat(setId.toString()))

		assert(set.isRedeemLimitExceeded(), message: "Set redeem limit timestamp not reached: ".concat(set.name))

		let addresses = set.ownersRecord

		for address in addresses {
			let collection =
				getAccount(address).getCapability<&{Redeemables.RedeemablesCollectionPublic}>(Redeemables.CollectionPublicPath).borrow()
			if collection != nil {
				collection!.burnUnredeemedSet(set: set)
			}
		}
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
					name: "Redeemables",
					description: "Doodles 2 lets anyone create a uniquely personalized and endlessly customizable character in a one-of-a-kind style. Wearables and other collectibles can easily be bought, traded, or sold. Doodles 2 will also incorporate collaborative releases with top brands in fashion, music, sports, gaming, and more. Redeemables are a part of the Doodles ecosystem that will allow you to turn in this NFT within a particular period of time to receive a physical collectible.",
					externalURL: MetadataViews.ExternalURL("https://doodles.app"),
					squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path: nil), mediaType:"image/png"),
					bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVoTikzygffMaPcacyTjF8mQ71Eg3zsMF4p4fbsAtGQmQ", path: nil), mediaType:"image/png"),
					socials: {
						"instagram": MetadataViews.ExternalURL("https://www.instagram.com/thedoodles"),
						"discord": MetadataViews.ExternalURL("https://discord.gg/doodles"),
						"twitter": MetadataViews.ExternalURL("https://twitter.com/doodles")
					}
				)
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(
					storagePath: Redeemables.CollectionStoragePath,
					publicPath: Redeemables.CollectionPublicPath,
					providerPath: Redeemables.CollectionPrivatePath,
					publicCollection: Type<&Collection{Redeemables.RedeemablesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					publicLinkedType: Type<&Collection{Redeemables.RedeemablesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					providerLinkedType: Type<&Collection{NonFungibleToken.Provider, Redeemables.RedeemablesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
					createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {
						return <- Redeemables.createEmptyCollection()
					}
				)
        }
        return nil
    }

	init() {
		self.totalSupply = 0

		self.sets = {}
		self.templates = {}
		self.templateNextSerialNumber = {}
		self.extra = {}

		self.CollectionStoragePath = /storage/redeemables
		self.CollectionPublicPath = /public/redeemables
		self.CollectionPrivatePath = /private/redeemables

		self.AdminStoragePath = /storage/redeemablesAdmin

		self.account.save<@NonFungibleToken.Collection>(<- Redeemables.createEmptyCollection(), to: Redeemables.CollectionStoragePath)
		self.account.link<&Redeemables.Collection{Redeemables.RedeemablesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			Redeemables.CollectionPublicPath,
			target: Redeemables.CollectionStoragePath
		)
		self.account.link<&Redeemables.Collection{Redeemables.RedeemablesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			Redeemables.CollectionPrivatePath,
			target: Redeemables.CollectionStoragePath
		)

        self.account.save(<-create Admin(), to: self.AdminStoragePath)

		emit ContractInitialized()
	}
}
 