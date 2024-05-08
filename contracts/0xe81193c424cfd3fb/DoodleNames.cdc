import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FIND from "../0x097bafa4e0b48eef/FIND.cdc"
import Templates from "./Templates.cdc"

pub contract DoodleNames: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	//J: What fields do we want here
	pub event Minted(id:UInt64, address:Address, name: String, context: {String : String})

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub var royalties : [Templates.Royalty]
	pub let registry : {String : NamePointer}

	pub struct NamePointer {
		pub let id: UInt64
		pub let name: String
		pub let address: Address?
		pub let characterId: UInt64?

		init(id: UInt64, name: String , address: Address?, characterId: UInt64?) {
			self.id = id
			self.name = name
			self.address = address
			self.characterId = characterId
		}

		pub fun equipped() : Bool {
			return self.characterId != nil
		}

	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

		pub let id:UInt64
		pub let name: String

		pub var nounce:UInt64
		pub let royalties: MetadataViews.Royalties
		pub let tag: {String : String}
		pub let scalar: {String : UFix64}
		pub let extra: {String : AnyStruct}

		init(
			name: String,
		) {
			self.nounce=0
			self.id=self.uuid
			self.name=name
			self.royalties=MetadataViews.Royalties(DoodleNames.getRoyalties())
			self.tag={}
			self.scalar={}
			self.extra={}
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {

			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: self.name,
					description: "Every Doodle name is unique and reserved by its owner.",
					thumbnail: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path:nil),
				)

			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://doodles.app")

			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.NFTCollectionDisplay>():
				let externalURL = MetadataViews.ExternalURL("https://doodles.app")
				let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path:nil), mediaType:"image/png")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://res.cloudinary.com/hxn7xk7oa/image/upload/v1675121458/doodles2_banner_ee7a035d05.jpg"), mediaType: "image/jpeg")
				return MetadataViews.NFTCollectionDisplay(name: "DoodleNames", description: "Every Doodle name is unique and reserved by its owner.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: { "discord": MetadataViews.ExternalURL("https://discord.gg/doodles"), "twitter" : MetadataViews.ExternalURL("https://twitter.com/doodles")})

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: DoodleNames.CollectionStoragePath,
				publicPath: DoodleNames.CollectionPublicPath,
				providerPath: DoodleNames.CollectionPrivatePath,
				publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- DoodleNames.createEmptyCollection()})

			}
			return nil
		}

		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}

		access(account) fun withdrawn() {
			DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name , address: self.owner?.address, characterId: nil)
		}

		access(account) fun deposited(owner: Address?, characterId: UInt64?) {
			if let o = owner {
				DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name , address: owner, characterId: characterId)
			}
			DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name , address: self.owner?.address, characterId: characterId)
		}
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let typedToken <- token as! @DoodleNames.NFT
			typedToken.withdrawn()
			emit Withdraw(id: typedToken.id, from: self.owner?.address)

			return <-typedToken
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id

			token.increaseNounce()
			token.deposited(owner: self.owner?.address, characterId: nil)
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token

			emit Deposit(id: id, to: self.owner?.address)


			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let wearable = nft as! &NFT
			//return wearable as &AnyResource{MetadataViews.Resolver}
			return wearable
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event

	//TODO: this needs to be access account
	access(account) fun mintNFT(
		recipient: &{NonFungibleToken.Receiver},
		name: String,
		context: {String:String}
	){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
			!self.registry.containsKey(name) : "Name already exist. Name : ".concat(name)
			FIND.validateFindName(name) : "This name is not valid for registering"
		}

		DoodleNames.totalSupply = DoodleNames.totalSupply + 1

		// create a new NFT
		var newNFT <- create NFT(
			name: name,
		)

		//Always emit events on state changes! always contain human readable and machine readable information
		//J: discuss that fields we want in this event. Or do we prefer to use the richer deposit event, since this is really done in the backend
		emit Minted(id:newNFT.id, address:recipient.owner!.address, name: name, context: context)
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newNFT)

	}

	access(account) fun mintName(
		name: String,
		context: {String:String},
		address:Address,
	) : @NFT{
		pre {
			!self.registry.containsKey(name) : "Name already exist. Name : ".concat(name)
			FIND.validateFindName(name) : "This name is not valid for registering"
		}

		DoodleNames.totalSupply = DoodleNames.totalSupply + 1

		// create a new NFT
		var newNFT <- create NFT(
			name: name,
		)

		emit Minted(id:newNFT.id, address:address, name: name, context: context)

		return <- newNFT
	}

	pub fun isNameFree(_ name:String) : Bool{
		return !self.registry.containsKey(name)
	}

	pub fun getRoyalties() : [MetadataViews.Royalty] {
		let royalties : [MetadataViews.Royalty] = []
		for r in DoodleNames.royalties {
			royalties.append(r.getRoyalty())
		}
		return royalties
	}

	pub fun setRoyalties(_ r: [Templates.Royalty]) {
		self.royalties = r
	}

	init() {
		// Initialize the total supply
		self.totalSupply = 0
		self.royalties = []
		self.registry = {}

		// Set the named paths
		self.CollectionStoragePath = /storage/doodleNames
		self.CollectionPublicPath = /public/doodleNames
		self.CollectionPrivatePath = /private/doodleNames

		self.account.save<@NonFungibleToken.Collection>(<- DoodleNames.createEmptyCollection(), to: DoodleNames.CollectionStoragePath)
		self.account.link<&DoodleNames.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			DoodleNames.CollectionPublicPath,
			target: DoodleNames.CollectionStoragePath
		)
		self.account.link<&DoodleNames.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			DoodleNames.CollectionPrivatePath,
			target: DoodleNames.CollectionStoragePath
		)

		emit ContractInitialized()
	}
}
