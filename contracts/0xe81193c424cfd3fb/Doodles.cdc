import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Wearables from "./Wearables.cdc"
import Templates from "./Templates.cdc"
import DoodleNames from "./DoodleNames.cdc"
import FindUtils from "../0x097bafa4e0b48eef/FindUtils.cdc"
import Debug from "./Debug.cdc"
import FlowtyViews from "../0x3cdbb3d569211ff3/FlowtyViews.cdc"

pub contract Doodles: NonFungibleToken {

	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	pub event Minted(id:UInt64, address:Address, set: String, setNumber: UInt64, name: String, context: {String : String})
	pub event Equipped(id: UInt64, subId:UInt64, subSlot: String, resourceType: String, address:Address, tags: {String: String} , context: {String: String})
	pub event Unequipped(id: UInt64, subId:UInt64, subSlot:String, resourceType: String, address:Address, tags: {String: String} , context: {String: String})
	pub event SetRegistered(id: UInt64, name:String, royalties:[Templates.Royalty])
	pub event SetRetired(id:UInt64, name:String)
	pub event SpeciesRegistered(id: UInt64, name:String)
	pub event SpeciesRetired(id: UInt64, name:String)
 	pub event BaseCharacterRegistered(id: UInt64, species:String, name:String, baseCharacterTraits: {String: String}, image: String)
	pub event BaseCharacterRetired(id: UInt64, name:String)
	pub event DoodleUpdated(id: UInt64, owner: Address)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub let sets: {UInt64: Set}
	pub let species : {UInt64: Species}
	pub let baseCharacters : {UInt64 : BaseCharacter}

	pub struct Set : Templates.Retirable, Templates.Editionable, Templates.RoyaltyHolder {
		pub let id:UInt64
		pub let name: String
		pub var active:Bool
		pub let royalties: [Templates.Royalty]
		access(self) let extra: {String : AnyStruct}

		init(id:UInt64, name:String, royalties: [Templates.Royalty]) {
			self.id=id
			self.name=name
			self.active=true
			self.royalties=royalties
			self.extra={}
		}

		pub fun getClassifier() : String{
			return "set"
		}

		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "doodles"
		}

	}

	pub struct Species : Templates.Retirable, Templates.Editionable {
		pub let id: UInt64
		pub let name: String
		pub var active:Bool
		access(self) let extra: {String : AnyStruct}

		init(id: UInt64, name:String) {
			self.id=id
			self.name=name
			self.active=true
			self.extra={}
		}

		pub fun getClassifier() :String {
			return "species"
		}

		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "doodles"
		}
	}

	pub struct BaseCharacter : Templates.Retirable, Templates.Editionable{
		pub let id: UInt64
		pub let name: String
		pub let species: UInt64
		pub let set: UInt64
		//TODO: What kind of traits exsist? Do we not want to have control over that?
		pub let baseCharacterTraits: {String: BaseCharacterTrait}
		pub var thumbnail: {MetadataViews.File}
		pub let image: {MetadataViews.File}
		pub var active:Bool
		access(self) let extra: {String : AnyStruct}

		init(id: UInt64, name:String, species:UInt64, set: UInt64, baseCharacterTraits: {String: BaseCharacterTrait}, thumbnail: {MetadataViews.File}, image: {MetadataViews.File}) {
			self.id=id
			self.species=species
			self.name=name
			self.set=set
			self.baseCharacterTraits=baseCharacterTraits
			self.thumbnail=thumbnail
			self.image=image
			self.active=true
			self.extra={}
		}

		pub fun getClassifier() :String {
			return "doodles"
		}

		pub fun getCounterSuffix() : String {
			return self.name
		}

		pub fun getContract() : String {
			return "doodles"
		}

		pub fun getSpecies() : Doodles.Species {
			return Doodles.species[self.species]!
		}

		pub fun getSet() : Doodles.Set {
			return Doodles.sets[self.set]!
		}

		pub fun getTraits() : [MetadataViews.Trait] {
			let t : [MetadataViews.Trait] = []
			for v in self.baseCharacterTraits.values {
				if v.value != "" {
					t.append(v.getTrait())
				}
			}
			return t
		}

		pub fun getTraitsAsMap() : {String : String} {
			let t : {String :  String} = {}
			for key in self.baseCharacterTraits.keys {
				t[key] = self.baseCharacterTraits[key]!.value
			}
			return t
		}

		access(account) fun updateTrait(name:String, value:String) {
			if let curr = self.baseCharacterTraits[name] {
				if curr.value!=value{
					self.baseCharacterTraits[name]= BaseCharacterTrait(name:name, value:value)
				}
			} else {
				self.baseCharacterTraits[name]= BaseCharacterTrait(name:name, value:value)
			}
		}

	}

	access(account) fun addSet(_ set: Doodles.Set) {
		emit SetRegistered(id: set.id, name:set.name, royalties:set.royalties)
		self.sets[set.id] = set
	}

	access(account) fun retireSet(_ id: UInt64) {
		pre{
			self.sets.containsKey(id) : "Set does not exist. Id : ".concat(id.toString())
		}
		emit SetRetired(id: id, name:self.sets[id]!.name)
		self.sets[id]!.enable(false)
	}

	access(account) fun addSpecies(_ species: Doodles.Species) {
		emit SpeciesRegistered(id: species.id, name: species.name)
		self.species[species.id] = species
	}

	access(account) fun retireSpecies(_ id: UInt64) {
		pre{
			self.species.containsKey(id) : "Species does not exist. Id : ".concat(id.toString())
		}
		emit SpeciesRetired(id: id, name:self.species[id]!.name)
		self.species[id]!.enable(false)
	}

	access(account) fun setBaseCharacter(_ bc: Doodles.BaseCharacter) {
		// we do not check here because baseCharacterTraits are updatable and it can be overwritten
		emit BaseCharacterRegistered(id: bc.id, species:bc.getSpecies().name, name:bc.name, baseCharacterTraits: bc.getTraitsAsMap(), image: bc.image.uri())
		self.baseCharacters[bc.id] = bc
	}

	access(account) fun retireBaseCharacter(_ id: UInt64) {
		pre{
			self.baseCharacters.containsKey(id) : "Base Character does not exist. Id : ".concat(id.toString())
		}
		emit BaseCharacterRetired(id: id, name:self.baseCharacters[id]!.name)
		self.baseCharacters[id]!.enable(false)
	}

	pub struct BaseCharacterTrait {
		pub let name: String
		pub let value: String
		pub let tag: {String : String}
		pub let extra: {String : AnyStruct}

		init(name: String , value: String) {
			self.name = name
			self.value = value
			self.tag = {}
			self.extra = {}
		}

		pub fun getTrait() : MetadataViews.Trait {
			return MetadataViews.Trait(name: "trait_".concat(self.name), value: self.value, displayType: "string", rarity: nil)
		}

		pub fun getTraitAsMap() : {String : String} {
			let t = self.tag
			t["name"] = self.name
			t["value"] = self.value
			return t
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, MetadataViews.ResolverCollection {

		pub let id:UInt64
		// At the moment this will only store one name. A map of {id : name resource}
		pub var name: @{UInt64 : DoodleNames.NFT}
		pub var nounce:UInt64
		pub let editions: [Templates.EditionInfo]
		pub let baseCharacter: BaseCharacter

		//This is resourceId to index for the item
		pub let positionIndex: {UInt64 : UInt64}
		// mapping of wearable ids to wearables resources
		pub let wearables: @{UInt64: Wearables.NFT}

		pub let royalties: MetadataViews.Royalties
		pub let extra: {String : AnyStruct}

		pub let context: { String: String}
		init(
			baseCharacter: BaseCharacter,
			editions: [Templates.EditionInfo],
			context: {String:String}

		) {
			self.nounce=0
			self.id=self.uuid
			self.name<-{}
			self.editions=editions
			self.baseCharacter=baseCharacter
			self.wearables<- {}
			self.positionIndex={}
			let s = baseCharacter.getSet()
			self.royalties=MetadataViews.Royalties(s.getRoyalties())
			self.context=context
			self.extra ={}
		}

		/// implemente ResolverCollection
		pub fun getIDs() : [UInt64] {
			let keys=self.wearables.keys
			keys.appendAll(self.name.keys)
			return keys
		}

		pub fun getSet() : Set {
			return self.baseCharacter.getSet()
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			if self.name.containsKey(id) {
				return (&self.name[id] as &DoodleNames.NFT?)!
			}
			return (&self.wearables[id] as &Wearables.NFT?)!
		}

		pub fun getContext() : {String:String} {
			return self.context
		}

		destroy(){
			destroy self.wearables
			destroy self.name
		}

		pub fun getViews(): [Type] {
			return  [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Medias>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Editions>(),
			Type<MetadataViews.Traits>(),
			Type<FlowtyViews.DNA>()
			]
		}


		pub fun resolveView(_ view: Type): AnyStruct? {

			var fullMediaType="image/png"

			let imageFile = self.baseCharacter.thumbnail

			let fullMedia=MetadataViews.Media(file:self.baseCharacter.image, mediaType: fullMediaType)
			let set = self.getSet()
			
			var name =""
			if let ownedName = self.getName() {
				name = ownedName
			}

      let description="This Doodle is a uniquely personalized customizable character in a one-of-a-kind style."

			switch view {
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(
					name: name,
					description: description,
					thumbnail: imageFile
				)

			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://doodles.app")

			case Type<MetadataViews.Royalties>():
				return self.royalties

			case Type<MetadataViews.Medias>():
				let medias: [MetadataViews.Media] = []
				for key in self.wearables.keys{
					let w = self.borrowWearable(key)
					medias.append(w.getTemplate().thumbnail)
				}
				return MetadataViews.Medias(medias)

			case Type<MetadataViews.NFTCollectionDisplay>():
        let description="Doodles are uniquely personalized and endlessly customizable characters in a one-of-a-kind style. Wearables and other collectibles can easily be bought, traded, or sold. Doodles 2 will also incorporate collaborative releases with top brands in fashion, music, sports, gaming, and more."
				let externalURL = MetadataViews.ExternalURL("https://doodles.app")
				let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path:nil), mediaType:"image/png")
				let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://res.cloudinary.com/hxn7xk7oa/image/upload/v1675121458/doodles2_banner_ee7a035d05.jpg"), mediaType: "image/jpeg")
				return MetadataViews.NFTCollectionDisplay(name: "Doodles", description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: { "discord": MetadataViews.ExternalURL("https://discord.gg/doodles"), "twitter" : MetadataViews.ExternalURL("https://twitter.com/Doodles")})

			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: Doodles.CollectionStoragePath,
				publicPath: Doodles.CollectionPublicPath,
				providerPath: Doodles.CollectionPrivatePath,
				publicCollection: Type<&Collection{Doodles.DoodlesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				publicLinkedType: Type<&Collection{Doodles.DoodlesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				providerLinkedType: Type<&Collection{Doodles.DoodlesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
				createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection {return <- Doodles.createEmptyCollection()})

			case Type<MetadataViews.Traits>():
				return self.getTraitsAsTraits()

			case Type<MetadataViews.Editions>():
				let edition=self.editions[0]
				let active = self.getActive(edition.name)
				let editions : [MetadataViews.Edition] =[
					edition.getAsMetadataEdition(active)
				]
				return MetadataViews.Editions(editions)

			case Type<FlowtyViews.DNA>():
				return FlowtyViews.DNA(self.calculateDNA())
			}
			return nil
		}

		pub fun getSetActive() : Bool {
			let t = Doodles.sets[self.baseCharacter.set]!
			return t.active
		}

		pub fun getSpeciesActive() : Bool {
			let t = Doodles.species[self.baseCharacter.species]!
			return t.active
		}

		pub fun getBaseCharacterActive() : Bool {
			let t = Doodles.baseCharacters[self.baseCharacter.id]!
			return t.active
		}

		pub fun getActive(_ classifier: String) : Bool {
			switch classifier {
				case "baseCharacter" :
					return self.getBaseCharacterActive()

				case "species" :
					return self.getSpeciesActive()

				case "set" :
					return self.getSetActive()
			}
			return true
		}

		pub fun getName() : String? {
			if let id = self.getNameId() {
				let ref = self.borrowName(id)
				return ref.name
			}
			return nil
		}

		pub fun getNameId() : UInt64? {
			if self.name.length > 0 {
				return self.name.keys[0]
			}
			return nil
		}

		pub fun getRoyalties() : [MetadataViews.Royalty] {
			return self.royalties.getRoyalties()
		}

		//This needs to change
		pub fun getWearablesAt(_ position: UInt64) : [UInt64] {
			//map from index to resourceId
			let ids : { UInt64 : UInt64}  = {}

			for key in self.wearables.keys {
				let w = self.borrowWearable(key)
				if w.template.position == position {
					ids[self.positionIndex[key]!]=key
				}
			}

			var i=0
			let idArrays : [UInt64]=[]
			while(i < ids.length) {
				idArrays.append(ids[UInt64(i)]!)
				i=i+1
			}
			return idArrays
		}

		//todo: collapse
		pub fun updateDoodle(wearableCollection: &Wearables.Collection, equipped: [UInt64],quote: String, expression: String, mood: String, background: String, hairStyle: String, hairColor: String, facialHair: String, facialHairColor: String, skinTone: String, pose: String, stage: String, location: String) {

			let existingIds = self.wearables.keys

			for wId in existingIds {
				if equipped.contains(wId) {
					//if an id is already equipped skip it
					continue
				}
				let nft  <- self.wearables.remove(key: wId)!
				let p = nft.template.getPosition()
				emit Unequipped(id:self.id, subId: wId, subSlot: p.name, resourceType: nft.getType().identifier, address:self.owner!.address, tags: {"wearableId": wId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : nft.template.name})
				wearableCollection.deposit(token: <- nft)
			}

			for wId in equipped {
				if existingIds.contains(wId) {
					//we already have it on
					continue
				}

				let wearableNFT <- wearableCollection.withdraw(withdrawID: wId)
				let nft <- wearableNFT as! @Wearables.NFT
				nft.equipped(owner: self.owner!.address, characterId: self.id)
				let p = nft.template.getPosition()
				let t = nft.getType()
				emit Equipped(id:self.id, subId:wId, subSlot: p.name, resourceType: t.identifier, address:self.owner!.address, tags: {"wearableId": wId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : nft.getName()})
				self.wearables[wId] <-! nft

			}

			self.baseCharacter.updateTrait(name:"quote",value: quote)
			self.baseCharacter.updateTrait(name:"expression",value: expression)
			self.baseCharacter.updateTrait(name:"mood",value: mood)
			self.baseCharacter.updateTrait(name:"background",value: background)
			self.baseCharacter.updateTrait(name:"hair_style",value: hairStyle)
			self.baseCharacter.updateTrait(name:"hair_color",value: hairColor)
			self.baseCharacter.updateTrait(name:"facial_hair",value: facialHair)
			self.baseCharacter.updateTrait(name:"facial_hair_color",value: facialHairColor)
			self.baseCharacter.updateTrait(name:"skin_tone",value: skinTone)
			self.baseCharacter.updateTrait(name:"pose",value: pose)
			self.baseCharacter.updateTrait(name:"stage",value: stage)
			self.baseCharacter.updateTrait(name:"location",value: location)

			emit DoodleUpdated(id: self.id, owner: self.owner!.address)
		}

		//expand
        pub fun editDoodle(wearableCollection: &NonFungibleToken.Collection, equipped: [UInt64],quote: String, expression: String, mood: String, background: String, hairStyle: String, hairColor: String, facialHair: String, facialHairColor: String, skinTone: String, pose: String, stage: String, location: String, hairPinched:Bool, hideExpression:Bool) {
			self.internalEditDoodle(
				wearableReceiver: wearableCollection,
				wearableProviders: [wearableCollection],
				equipped: equipped,
				quote: quote,
				expression: expression,
				mood: mood,
				background: background,
				hairStyle: hairStyle,
				hairColor: hairColor,
				facialHair: facialHair,
				facialHairColor: facialHairColor,
				skinTone: skinTone,
				pose: pose,
				stage: stage,
				location: location,
				hairPinched: hairPinched,
				hideExpression: hideExpression
			)
        }

		pub fun editDoodleWithMultipleCollections(receiverWearableCollection: &{NonFungibleToken.Receiver}, wearableCollections: [&{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}], equipped: [UInt64],quote: String, expression: String, mood: String, background: String, hairStyle: String, hairColor: String, facialHair: String, facialHairColor: String, skinTone: String, pose: String, stage: String, location: String, hairPinched:Bool, hideExpression:Bool) {
			self.internalEditDoodle(
				wearableReceiver: receiverWearableCollection,
				wearableProviders: wearableCollections,
				equipped: equipped,
				quote: quote,
				expression: expression,
				mood: mood,
				background: background,
				hairStyle: hairStyle,
				hairColor: hairColor,
				facialHair: facialHair,
				facialHairColor: facialHairColor,
				skinTone: skinTone,
				pose: pose,
				stage: stage,
				location: location,
				hairPinched: hairPinched,
				hideExpression: hideExpression
			)
		}

		access(contract) fun internalEditDoodle(wearableReceiver: &{NonFungibleToken.Receiver}, wearableProviders: [&{NonFungibleToken.CollectionPublic, NonFungibleToken.Provider}], equipped: [UInt64],quote: String, expression: String, mood: String, background: String, hairStyle: String, hairColor: String, facialHair: String, facialHairColor: String, skinTone: String, pose: String, stage: String, location: String, hairPinched:Bool, hideExpression:Bool) {
			let existingIds = self.wearables.keys

            for wId in existingIds {
                if equipped.contains(wId) {
                    //if an id is already equipped skip it
                    continue
                }
                let nft  <- self.wearables.remove(key: wId)!
                let p = nft.template.getPosition()
                emit Unequipped(id:self.id, subId: wId, subSlot: p.name, resourceType: nft.getType().identifier, address:self.owner!.address, tags: {"wearableId": wId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : nft.template.name})
                wearableReceiver.deposit(token: <- nft)
            }

			for wearableProvider in wearableProviders {
				for wId in equipped {
					if !wearableProvider.getIDs().contains(wId) {
						continue
					}

					let wearableNFT <- wearableProvider.withdraw(withdrawID: wId)
					let nft <- wearableNFT as! @Wearables.NFT
					nft.equipped(owner: self.owner!.address, characterId: self.id)
					let p = nft.template.getPosition()
					let t = nft.getType()
					emit Equipped(id:self.id, subId:wId, subSlot: p.name, resourceType: t.identifier, address:self.owner!.address, tags: {"wearableId": wId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : nft.getName()})
					self.wearables[wId] <-! nft

				}
			}

            var hairPinchedValue=""
            if hairPinched {
                hairPinchedValue="true"
            }

            var hideExpressionValue=""
            if hideExpression {
                hideExpressionValue="true"
            }

            self.baseCharacter.updateTrait(name:"quote",value: quote)
            self.baseCharacter.updateTrait(name:"expression",value: expression)
            self.baseCharacter.updateTrait(name:"expression_hide",value: hideExpressionValue)
            self.baseCharacter.updateTrait(name:"mood",value: mood)
            self.baseCharacter.updateTrait(name:"background",value: background)
            self.baseCharacter.updateTrait(name:"hair_style",value: hairStyle)
            self.baseCharacter.updateTrait(name:"hair_color",value: hairColor)
            self.baseCharacter.updateTrait(name:"hair_pinched",value: hairPinchedValue)
            self.baseCharacter.updateTrait(name:"facial_hair",value: facialHair)
            self.baseCharacter.updateTrait(name:"facial_hair_color",value: facialHairColor)
            self.baseCharacter.updateTrait(name:"skin_tone",value: skinTone)
            self.baseCharacter.updateTrait(name:"pose",value: pose)
            self.baseCharacter.updateTrait(name:"stage",value: stage)
            self.baseCharacter.updateTrait(name:"location",value: location)

			emit DoodleUpdated(id: self.id, owner: self.owner!.address)
		}

		access(account) fun addName(_ nft: @DoodleNames.NFT, owner:Address) {
			pre{
				self.name.length == 0 : "This doodles have name equipped ID : ".concat(self.name.keys[0].toString())
			}

			nft.deposited(owner: owner, characterId: self.id)
			self.name[nft.id] <-! nft
		}


		pub fun equipName(_ nft: @DoodleNames.NFT) {
			pre{
				self.name.length == 0 : "This doodles have name equipped ID : ".concat(self.name.keys[0].toString())
			}

			let action = "equipName"
			Templates.assertFeatureEnabled(action)

			let resourceId = nft.id
			let t = nft.getType()
			let characterName = nft.name
			nft.deposited(owner: self.owner!.address, characterId: self.id)
			self.name[nft.id] <-! nft
			emit Equipped(id:self.id, subId: resourceId, subSlot: "name", resourceType: t.identifier, address:self.owner!.address, tags: {}, context: {"Name" : characterName})
		}


		access(contract) fun unequipName() : @DoodleNames.NFT {
			pre{
				self.name.length > 0 : "This character does not have name equipped ID : ".concat(self.id.toString())
			}

			let action = "unequipName"
			Templates.assertFeatureEnabled(action)

			let resourceId = self.getNameId()!
			let nft <- self.name.remove(key: resourceId)!
			nft.withdrawn()
			let characterName = nft.name
			let t = nft.getType()
			emit Unequipped(id:self.id, subId: resourceId, subSlot: "name", resourceType: t.identifier, address:self.owner!.address, tags: {}, context: {"Name" : characterName})
			return <- nft
		}

		access(contract) fun equipWearable(_ nft: @Wearables.NFT, index: UInt64) {
			let action = "equipWearable"
			Templates.assertFeatureEnabled(action)

			let resourceId = nft.id
			let t = nft.getType()
			let name = nft.template.name
			let p = nft.template.getPosition()
			let positionCount = p.getPositionCount()
			if UInt64(positionCount - 1) < index {
				panic("Position index does not exist. Maximum index : ".concat((positionCount - 1).toString()))
			}
			let equipped = self.getWearablesAt(p.id)

			//loop over these and order them by the value in positionIndex

			for w in equipped {
				if self.positionIndex[w]! == index {
					panic("Position with index is already equipped. index : ".concat(index.toString()) )
				}
			}
			self.positionIndex[resourceId] = index
			equipped.append(resourceId)
			assert(equipped.length <= positionCount, message : "You already equipped more wearables than you can at this position : ".concat(p.name).concat(" Max number of wearables : ".concat(positionCount.toString())))
			nft.equipped(owner: self.owner!.address, characterId: self.id)
			self.wearables[resourceId] <-! nft
			assert(equipped.length <= positionCount, message : "You already equipped more wearables than you can at this position : ".concat(p.name).concat(" Max number of wearables : ".concat(positionCount.toString())))
			emit Equipped(id:self.id, subId: resourceId, subSlot: p.name, resourceType: t.identifier, address:self.owner!.address, tags: {"wearableId": resourceId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : name})
		}


		access(contract) fun unequipWearable(_ resourceId: UInt64) : @Wearables.NFT {
			pre{
				self.wearables.containsKey(resourceId) : "Wearables with id is not equipped : ".concat(resourceId.toString())
			}

			self.positionIndex.remove(key: resourceId)!
			let action = "unequipWearable"
			Templates.assertFeatureEnabled(action)


			let nft  <- self.wearables.remove(key: resourceId)!
			let p = nft.template.getPosition()
			emit Unequipped(id:self.id, subId: resourceId, subSlot: p.name, resourceType: nft.getType().identifier, address:self.owner!.address, tags: {"wearableId": resourceId.toString()}, context: {"wearablePosition" : p.name, "wearableName" : nft.template.name})
			return <- nft
		}


		pub fun borrowWearable(_ id: UInt64) : &Wearables.NFT {
			return (&self.wearables[id] as &Wearables.NFT?)!
		}

		pub fun borrowName(_ id: UInt64) : &DoodleNames.NFT {
			return (&self.name[id] as &DoodleNames.NFT?)!
		}

		pub fun borrowWearableViewResolver(_ id: UInt64) : &{MetadataViews.Resolver} {
			let nft = (&self.wearables[id] as auth &NonFungibleToken.NFT?)!
			let wearable = nft as! &Wearables.NFT
			return wearable
		}

		pub fun increaseNounce() {
			self.nounce=self.nounce+1
		}

		pub fun getTraitsAsTraits() : MetadataViews.Traits {
			let traits=self.getAllTraitsMetadata()
			let res : [MetadataViews.Trait] = []
			for t in traits.values {
				res.appendAll(t)
			}
			return MetadataViews.Traits(res)
		}

		pub fun getAllTraitsMetadata() : {String : [MetadataViews.Trait]} {

			var traitMetadata : [MetadataViews.Trait] = self.baseCharacter.getTraits()
			let wearableTraits = self.getWearableTraits()
			wearableTraits["doodles"] = traitMetadata
			if let nameTrait = self.getNameTrait() {
				wearableTraits["name"] = [nameTrait]
			}

      		wearableTraits["dna"] = [MetadataViews.Trait(name:"dna", value:self.calculateDNA(), displayType:"string", rarity:nil)]

			let ctx = self.getContext()
			for key in ctx.keys{
				let traitKey ="context_".concat(key)
				wearableTraits[traitKey]=[MetadataViews.Trait(name:traitKey, value: ctx[key], displayType:"string", rarity:nil)]
			}
			return wearableTraits
		}

		pub fun getNameTrait() : MetadataViews.Trait? {
			if let name = self.getName() {
				return MetadataViews.Trait(name: "doodle_name", value: name, displayType:"string", rarity:nil)
			}
			return nil
		}

    	//b64(<doodleName>-<pose value>-<expression value>-<skinTone value>-<hairStyle value>-<hairColor value>-<id of doodle>-[<array of equipped NFT Ids>])
		pub fun calculateDNA() : String {
			return self.calculateDNACustom(sep: "|", encode: true)
		}

		pub fun calculateDNACustom(sep: String, encode: Bool) : String {
			let seperator=sep
			let traits =self.baseCharacter.getTraitsAsMap()
			var dna=""
			dna=dna.concat(self.getName() ?? "").concat(seperator)
			dna=dna.concat(traits["pose"] ?? "").concat(seperator)
			dna=dna.concat(traits["expression"]?? "").concat(seperator)
			dna=dna.concat(traits["skin_tone"] ?? "").concat(seperator)
			dna=dna.concat(traits["hair_style"]?? "").concat(seperator)
			dna=dna.concat(traits["hair_color"] ?? "").concat(seperator)
			dna=dna.concat(self.id.toString()).concat(seperator)
			dna=dna.concat("[")

			//https://www.geeksforgeeks.org/insertion-sort/
			var ids = self.wearables.keys
					for i, key in ids {
				var j=i
				while j >0 && ids[j-1] > ids[j] {
				ids[j] <-> ids[j-1]
				j=j-1
				}
			}

			for id in ids {
				dna = dna.concat(id.toString()).concat(seperator)
			}
			//remove the last seperator
			dna=dna.slice(from: 0, upTo: dna.length - seperator.length)
			dna=dna.concat("]")

			if !encode {
				return dna
			}
			return Doodles.base64encode(dna)
		}

		pub fun getWearableTraits() : {String : [MetadataViews.Trait]} {
			let traitsToKeep = ["name",  "position", "set", "layer"]
			let mvt : {String : [MetadataViews.Trait]} = {}
			let counter : {UInt64:Int} = {}
			for key in self.wearables.keys{
				let w = self.borrowWearable(key)

				let position=w.getTemplate().id.toString()

				let trait = MetadataViews.getTraits(w)
				if trait != nil {
					let cleanedTraits : [MetadataViews.Trait] = []
					let traitIdentifer = "wearable_".concat(position).concat("_")

					let idTrait=MetadataViews.Trait(name: traitIdentifer.concat("id"), value: w.id, displayType:"Number", rarity:nil)
					cleanedTraits.append(idTrait)

					let templateIdTrait=MetadataViews.Trait(name: traitIdentifer.concat("template_id"), value: w.getTemplate().id, displayType:"Number", rarity:nil)
					cleanedTraits.append(templateIdTrait)

					for t in trait!.traits {
						if !traitsToKeep.contains(t.name) {
							continue
						}
						let traitName = FindUtils.trimSuffix(traitIdentifer.concat(t.name), suffix: "_name")
						let newTrait=MetadataViews.Trait(name: traitName, value: t.value, displayType:t.displayType, rarity:t.rarity)
						cleanedTraits.append(newTrait)
					}

					let array = mvt[position] ?? []
					array.appendAll(cleanedTraits)
					mvt[position] = array
				}
			}
			return mvt
		}
	}

	pub resource interface DoodlesCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDoodlesNFT(id: UInt64) : &NFT
    }

	pub resource Collection: DoodlesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		init () {
			self.ownedNFTs <- {}
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id

			token.increaseNounce()
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

		pub fun borrowDoodlesNFT(id: UInt64) : &NFT {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let doodles = nft as! &NFT
			return doodles
		}

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let doodles = nft as! &NFT
			return doodles
		}

		pub fun borrowSubCollection(id: UInt64): &AnyResource{MetadataViews.ResolverCollection}? {
			let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
			if nft==nil {
				return nil
			}
			let doodles = nft as! &NFT
			return doodles
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub fun mintDoodle(
		recipient: &{NonFungibleToken.Receiver},
		betaPass: @Wearables.NFT,
		doodleName: String,
		baseCharacter: UInt64
	){
		pre {
			recipient.owner != nil : "Recipients NFT collection is not owned"
		}

		let template: Wearables.Template = betaPass.getTemplate()
		assert(template.id == 244, message: "Not a valid beta pass")
		let context: {String: String} = betaPass.context
		destroy <- betaPass

		let newNFT <- self.adminMintDoodle(
			recipientAddress: recipient.owner!.address,
			doodleName: doodleName,
			baseCharacter: baseCharacter,
			context: context
		)

		recipient.deposit(token: <-newNFT)
	}

	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account) fun adminMintDoodle(
		recipientAddress: Address,
		doodleName: String,
		baseCharacter: UInt64,
		context: {String : String}
	): @Doodles.NFT {
		pre {
			self.baseCharacters.containsKey(baseCharacter) : "Base Character does not exist. Id : ".concat(baseCharacter.toString())
		}

		Doodles.totalSupply = Doodles.totalSupply + 1
		let baseCharacter = Doodles.borrowBaseCharacter(baseCharacter)
		let set = Doodles.borrowSet(baseCharacter.set)
		let species =  Doodles.borrowSpecies(baseCharacter.species)

		assert(set.active, message: "Set Retired : ".concat(set.name))
		assert(species.active, message: "Species Retired : ".concat(species.name))
		assert(baseCharacter.active, message: "BaseCharacter Retired : ".concat(baseCharacter.name))

		let name <- DoodleNames.mintName(name:doodleName, context:context, address: recipientAddress)

		let editions=[
			baseCharacter.createEditionInfo(nil),
			species.createEditionInfo(nil),
			set.createEditionInfo(nil)
		]

		// create a new NFT
		var newNFT <- create NFT(
			baseCharacter: Doodles.baseCharacters[baseCharacter.id]!,
			editions: editions,
			context:context
		)
		newNFT.addName(<- name, owner: recipientAddress)

		emit Minted(id:newNFT.id, address: recipientAddress, set: set.name, setNumber: set.id, name: doodleName, context: context)

		return <- newNFT
	}

	access(account) fun borrowSet(_ id: UInt64) : &Doodles.Set {
		pre{
			self.sets.containsKey(id) : "Set does not exist. Id : ".concat(id.toString())
		}
		return &Doodles.sets[id]! as &Doodles.Set
	}

	access(account) fun borrowSpecies(_ id: UInt64) : &Doodles.Species {
		pre{
			self.species.containsKey(id) : "Species does not exist. Id : ".concat(id.toString())
		}
		return &Doodles.species[id]! as &Doodles.Species
	}

	access(account) fun borrowBaseCharacter(_ id: UInt64) : &Doodles.BaseCharacter {
		pre{
			self.baseCharacters.containsKey(id) : "BaseCharacter does not exist. Id : ".concat(id.toString())
		}
		return &Doodles.baseCharacters[id]! as &Doodles.BaseCharacter
	}


  //MOVE TO UTIL
  //https://forum.onflow.org/t/base64-encode-in-cadence/1915/6
  pub fun base64encode(_ input: String): String {

    let data = input.utf8

    let baseChars: [String] = [
      "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
      "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
      "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"
    ]


    var encoded = ""
    var padding = ""
    var padCount = data.length % 3

    // Add a right zero pad to make the input a multiple of 3 characters
    if padCount > 0 {
        while padCount < 3 {
            padding = padding.concat("=")
            data.append(0)
            padCount = padCount + 1
        }
    }

    // Increment over the length of the input, three bytes at a time
    var i = 0
    while i < data.length {

        // Each three bytes become one 24-bit number
        let n = (UInt32(data[i]) << 16)
            + (UInt32(data[i + 1]) << 8)
            + UInt32(data[i + 2])

        // This 24-bit number gets separated into four 6-bit numbers
        let n1 = (n >> 18) & 63
        let n2 = (n >> 12) & 63
        let n3 = (n >> 6) & 63
        let n4 = n & 63

        // Those four 6-bit numbers are used as indices into the base64 character list
        encoded = encoded
            .concat(baseChars[n1])
            .concat(baseChars[n2])
            .concat(baseChars[n3])
            .concat(baseChars[n4])

        i = i + 3
    }

    return encoded
        .slice(from: 0, upTo: encoded.length - padding.length)
        .concat(padding)
}

	init() {
		// Initialize the total supply
		self.totalSupply = 0

		self.sets = {}
		self.species = {}
		self.baseCharacters = {}

		// Set the named paths
		self.CollectionStoragePath = /storage/doodles
		self.CollectionPublicPath = /public/doodles
		self.CollectionPrivatePath = /private/doodles

		self.account.save<@NonFungibleToken.Collection>(<- Doodles.createEmptyCollection(), to: Doodles.CollectionStoragePath)
		self.account.link<&Doodles.Collection{Doodles.DoodlesCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			Doodles.CollectionPublicPath,
			target: Doodles.CollectionStoragePath
		)
		self.account.link<&Doodles.Collection{Doodles.DoodlesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			Doodles.CollectionPrivatePath,
			target: Doodles.CollectionStoragePath
		)

		emit ContractInitialized()
	}
}