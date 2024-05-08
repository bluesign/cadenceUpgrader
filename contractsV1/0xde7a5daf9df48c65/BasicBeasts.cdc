import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract BasicBeasts: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// BasicBeasts Events
	// -----------------------------------------------------------------------
	access(all)
	event BeastMinted(id: UInt64, address: Address?, beastTemplateID: UInt32, serialNumber: UInt32, sex: String, matron: BeastNftStruct?, sire: BeastNftStruct?)
	
	access(all)
	event BeastNewNicknameSet(id: UInt64, nickname: String)
	
	access(all)
	event BeastFirstOwnerSet(id: UInt64, firstOwner: Address)
	
	access(all)
	event BeastDestroyed(id: UInt64, serialNumber: UInt32, beastTemplateID: UInt32)
	
	access(all)
	event BeastTemplateCreated(beastTemplateID: UInt32, name: String, skin: String)
	
	access(all)
	event NewGenerationStarted(newCurrentGeneration: UInt32)
	
	access(all)
	event BeastRetired(beastTemplateID: UInt32, numberMintedPerBeastTemplate: UInt32)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// BasicBeasts Fields
	// -----------------------------------------------------------------------
	// Generation that a BeastTemplate belongs to.
	// Generation is a concept that indicates a group of BeastTemplates through time.
	// Many BeastTemplates can exist at a time, but only one generation.
	access(all)
	var currentGeneration: UInt32
	
	// Variable size dictionary of beastTemplate structs
	access(self)
	var beastTemplates:{ UInt32: BeastTemplate}
	
	access(self)
	var retired:{ UInt32: Bool}
	
	access(self)
	var numberMintedPerBeastTemplate:{ UInt32: UInt32}
	
	access(self)
	var royalties: [MetadataViews.Royalty]
	
	access(all)
	struct BeastTemplate{ 
		access(all)
		let beastTemplateID: UInt32
		
		access(all)
		let generation: UInt32
		
		access(all)
		let dexNumber: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let imageTransparentBg: String
		
		access(all)
		let rarity: String
		
		access(all)
		let skin: String
		
		access(all)
		let starLevel: UInt32
		
		access(all)
		let asexual: Bool
		
		// The Beast Template ID that can be born from this Beast Template
		access(all)
		let breedableBeastTemplateID: UInt32
		
		// Maximum mint by Admin allowed
		access(all)
		let maxAdminMintAllowed: UInt32
		
		access(all)
		let ultimateSkill: String
		
		access(all)
		let basicSkills: [String]
		
		access(all)
		let elements: [String]
		
		access(all)
		let data:{ String: String}
		
		init(beastTemplateID: UInt32, dexNumber: UInt32, name: String, description: String, image: String, imageTransparentBg: String, rarity: String, skin: String, starLevel: UInt32, asexual: Bool, breedableBeastTemplateID: UInt32, maxAdminMintAllowed: UInt32, ultimateSkill: String, basicSkills: [String], elements: [String], data:{ String: String}){ 
			pre{ 
				dexNumber > 0:
					"Cannot initialize new Beast Template: dexNumber cannot be 0"
				name != "":
					"Cannot initialize new Beast Template: name cannot be blank"
				description != "":
					"Cannot initialize new Beast Template: description cannot be blank"
				image != "":
					"Cannot initialize new Beast Template: image cannot be blank"
				imageTransparentBg != "":
					"Cannot initialize new Beast Template: imageTransparentBg cannot be blank"
				rarity != "":
					"Cannot initialize new Beast Template: rarity cannot be blank"
				skin != "":
					"Cannot initialize new Beast Template: skin cannot be blank"
				ultimateSkill != "":
					"Cannot initialize new Beast Template: ultimate cannot be blank"
				basicSkills.length != 0:
					"Cannot initialize new Beast Template: basicSkills cannot be empty"
			}
			self.beastTemplateID = beastTemplateID
			self.generation = BasicBeasts.currentGeneration
			self.dexNumber = dexNumber
			self.name = name
			self.description = description
			self.image = image
			self.imageTransparentBg = imageTransparentBg
			self.rarity = rarity
			self.skin = skin
			self.starLevel = starLevel
			self.asexual = asexual
			self.breedableBeastTemplateID = breedableBeastTemplateID
			self.maxAdminMintAllowed = maxAdminMintAllowed
			self.ultimateSkill = ultimateSkill
			self.basicSkills = basicSkills
			self.elements = elements
			self.data = data
		}
	}
	
	access(all)
	struct BeastNftStruct{ 
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let sex: String
		
		access(all)
		let beastTemplateID: UInt32
		
		access(all)
		let firstOwner: Address?
		
		init(id: UInt64, serialNumber: UInt32, sex: String, beastTemplateID: UInt32, firstOwner: Address?){ 
			self.id = id
			self.serialNumber = serialNumber
			self.sex = sex
			self.beastTemplateID = beastTemplateID
			self.firstOwner = firstOwner
		}
	}
	
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let sex: String
		
		access(all)
		let matron: BeastNftStruct?
		
		access(all)
		let sire: BeastNftStruct?
		
		access(contract)
		let beastTemplate: BeastTemplate
		
		access(contract)
		var nickname: String
		
		access(contract)
		var firstOwner: Address?
		
		access(contract)
		let evolvedFrom: [BeastNftStruct]?
		
		access(all)
		fun getBeastTemplate(): BeastTemplate
		
		access(all)
		fun getNickname(): String?
		
		access(all)
		fun getFirstOwner(): Address?
		
		access(all)
		fun getEvolvedFrom(): [BeastNftStruct]?
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let sex: String
		
		access(all)
		let matron: BeastNftStruct?
		
		access(all)
		let sire: BeastNftStruct?
		
		access(contract)
		let beastTemplate: BeastTemplate
		
		access(contract)
		var nickname: String
		
		access(contract)
		var firstOwner: Address?
		
		access(contract)
		let evolvedFrom: [BeastNftStruct]?
		
		init(beastTemplateID: UInt32, matron: BeastNftStruct?, sire: BeastNftStruct?, evolvedFrom: [BeastNftStruct]?){ 
			pre{ 
				BasicBeasts.beastTemplates[beastTemplateID] != nil:
					"Cannot mint Beast: Beast Template ID does not exist"
			}
			BasicBeasts.totalSupply = BasicBeasts.totalSupply + 1
			BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID] = BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID]! + 1
			self.id = self.uuid
			self.serialNumber = BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID]!
			var beastTemplate = BasicBeasts.beastTemplates[beastTemplateID]!
			var sex = "Asexual"
			if !beastTemplate.asexual{ 
				// Female or Male depending on the result
				var probability = 0.5
				var isFemale = Int(self.uuid) * Int(revertibleRandom<UInt64>()) % 100_000_000 < Int(100_000_000.0 * probability)
				if isFemale{ 
					sex = "Female"
				} else{ 
					sex = "Male"
				}
			}
			self.sex = sex
			self.matron = matron
			self.sire = sire
			self.beastTemplate = beastTemplate
			self.nickname = beastTemplate.name
			self.firstOwner = nil
			self.evolvedFrom = evolvedFrom
			emit BeastMinted(id: self.id, address: self.owner?.address, beastTemplateID: self.beastTemplate.beastTemplateID, serialNumber: self.serialNumber, sex: self.sex, matron: self.matron, sire: self.sire)
		}
		
		access(all)
		fun setNickname(nickname: String){ 
			pre{ 
				BasicBeasts.validateNickname(nickname: nickname):
					"Can't change nickname: Nickname is more than 16 characters"
			}
			if nickname.length == 0{ 
				self.nickname = self.beastTemplate.name
			} else{ 
				self.nickname = nickname
			}
			emit BeastNewNicknameSet(id: self.id, nickname: self.nickname)
		}
		
		// setFirstOwner sets the First Owner of this NFT
		// this action cannot be undone
		// 
		// Parameters: firstOwner: The address of the firstOwner
		//
		access(all)
		fun setFirstOwner(firstOwner: Address){ 
			pre{ 
				self.firstOwner == nil:
					"First Owner is already initialized"
			}
			self.firstOwner = firstOwner
			emit BeastFirstOwnerSet(id: self.id, firstOwner: self.firstOwner!)
		}
		
		access(all)
		fun getBeastTemplate(): BeastTemplate{ 
			return self.beastTemplate
		}
		
		access(all)
		fun getNickname(): String?{ 
			return self.nickname
		}
		
		access(all)
		fun getFirstOwner(): Address?{ 
			return self.firstOwner
		}
		
		access(all)
		fun getEvolvedFrom(): [BeastNftStruct]?{ 
			return self.evolvedFrom
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.nickname, description: self.beastTemplate.description, thumbnail: MetadataViews.IPFSFile(cid: self.beastTemplate.image, path: nil))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = BasicBeasts.royalties
					if self.firstOwner != nil{ 
						royalties.append(MetadataViews.Royalty(receiver: getAccount(self.firstOwner!).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, // 5% royalty on secondary sales																																												
																																												description: "First owner 5% royalty from secondary sales."))
					}
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Basic Beasts Edition".concat(" ").concat(self.beastTemplate.name).concat(" ").concat(self.beastTemplate.skin), number: UInt64(self.serialNumber), max: UInt64(BasicBeasts.getNumberMintedPerBeastTemplate(beastTemplateID: self.beastTemplate.beastTemplateID)!))
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.ExternalURL>():
					//Get dexNumber in url format e.g. 010, 001, etc.
					let num: String = "00".concat(self.beastTemplate.dexNumber.toString())
					let dex: String = num.slice(from: num.length - 3, upTo: num.length)
					
					//Get skin in url format e.g. normal, shiny-gold
					let skin: String = self.beastTemplate.skin.toLower()
					var skinFormatted: String = ""
					var i = 0
					while i < skin.length{ 
						let char = skin[i]
						if char == " "{ 
							skinFormatted = skinFormatted.concat("-")
						} else{ 
							skinFormatted = skinFormatted.concat(char.toString())
						}
						i = i + 1
					}
					return MetadataViews.ExternalURL("https://basicbeasts.io/".concat("beast").concat("/").concat(dex).concat("-").concat(skinFormatted)) // e.g. https://basicbeasts.io/beast/001-cursed-black/
				
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BasicBeasts.CollectionStoragePath, publicPath: BasicBeasts.CollectionPublicPath, publicCollection: Type<&BasicBeasts.Collection>(), publicLinkedType: Type<&BasicBeasts.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BasicBeasts.createEmptyCollection(nftType: Type<@BasicBeasts.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://basicbeasts.io")
					let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "Qmd9d2EcdfKovAxQVDCgtUXh5RiqhoRRW1HYpg4zN75JND", path: nil), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmQXF95pcL9j7wEQAV9NFUiV6NnHRAbD2SZjkpezr3hJgp", path: nil), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/basicbeastsnft"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/xgFtWhwSaR")}
					return MetadataViews.NFTCollectionDisplay(name: "Basic Beasts", description: "Basic Beasts by BB Club DAO", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(UInt64(self.serialNumber))
				case Type<MetadataViews.Rarity>():
					var rarity: UFix64 = 0.0
					var max: UFix64? = nil
					if self.beastTemplate.starLevel == 1{ 
						max = UFix64(self.beastTemplate.maxAdminMintAllowed)
					}
					switch self.beastTemplate.skin{ 
						case "Normal":
							rarity = 1.0
							max = nil
						case "Metallic Silver":
							rarity = 2.0
							max = nil
						case "Cursed Black":
							rarity = 3.0
						case "Shiny Gold":
							rarity = 4.0
						case "Mythic Diamond":
							rarity = 5.0
					}
					if self.beastTemplate.rarity == "Legendary"{ 
						rarity = rarity + 5.0
					}
					return MetadataViews.Rarity(score: rarity, max: max, description: self.beastTemplate.skin)
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					let skin: MetadataViews.Trait = MetadataViews.Trait(name: "Skin", value: self.beastTemplate.skin, displayType: "String", rarity: nil)
					traits.append(skin)
					let dex: MetadataViews.Trait = MetadataViews.Trait(name: "Dex Number", value: self.beastTemplate.dexNumber, displayType: "Number", rarity: nil)
					traits.append(dex)
					let starLevel: MetadataViews.Trait = MetadataViews.Trait(name: "Star Level", value: self.beastTemplate.starLevel, displayType: "Number", rarity: nil)
					traits.append(starLevel)
					let gender: MetadataViews.Trait = MetadataViews.Trait(name: "Gender", value: self.sex, displayType: "String", rarity: nil)
					traits.append(gender)
					let element: MetadataViews.Trait = MetadataViews.Trait(name: "Element", value: self.beastTemplate.elements[0], displayType: "String", rarity: nil)
					traits.append(element)
					let gen: MetadataViews.Trait = MetadataViews.Trait(name: "Generation", value: self.beastTemplate.generation, displayType: "Number", rarity: nil)
					traits.append(gen)
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// -----------------------------------------------------------------------
	// Admin Resource Functions
	//
	// Admin is a special authorization resource that 
	// allows the owner to perform important NFT 
	// functions
	// -----------------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun createBeastTemplate(beastTemplateID: UInt32, dexNumber: UInt32, name: String, description: String, image: String, imageTransparentBg: String, rarity: String, skin: String, starLevel: UInt32, asexual: Bool, breedableBeastTemplateID: UInt32, maxAdminMintAllowed: UInt32, ultimateSkill: String, basicSkills: [String], elements: [String], data:{ String: String}): UInt32{ 
			pre{ 
				BasicBeasts.beastTemplates[beastTemplateID] == nil:
					"Cannot create Beast Template: Beast Template ID already exist"
				BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID] == nil:
					"Cannot create Beast Template: Beast Template has already been created"
			}
			var newBeastTemplate = BeastTemplate(beastTemplateID: beastTemplateID, dexNumber: dexNumber, name: name, description: description, image: image, imageTransparentBg: imageTransparentBg, rarity: rarity, skin: skin, starLevel: starLevel, asexual: asexual, breedableBeastTemplateID: breedableBeastTemplateID, maxAdminMintAllowed: maxAdminMintAllowed, ultimateSkill: ultimateSkill, basicSkills: basicSkills, elements: elements, data: data)
			BasicBeasts.retired[beastTemplateID] = false
			BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID] = 0
			BasicBeasts.beastTemplates[beastTemplateID] = newBeastTemplate
			emit BeastTemplateCreated(beastTemplateID: beastTemplateID, name: name, skin: skin)
			return newBeastTemplate.beastTemplateID
		}
		
		access(all)
		fun mintBeast(beastTemplateID: UInt32): @NFT{ 
			// Admin specific pre-condition for minting a beast
			pre{ 
				BasicBeasts.beastTemplates[beastTemplateID] != nil:
					"Cannot mint Beast: Beast Template ID does not exist"
				BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID]! < (BasicBeasts.beastTemplates[beastTemplateID]!).maxAdminMintAllowed:
					"Cannot mint Beast: Max mint by Admin allowance for this Beast is reached"
			}
			
			// When minting genesis beasts. Set matron, sire, evolvedFrom to nil
			let newBeast: @NFT <- BasicBeasts.mintBeast(beastTemplateID: beastTemplateID, matron: nil, sire: nil, evolvedFrom: nil)
			return <-newBeast
		}
		
		access(all)
		fun retireBeast(beastTemplateID: UInt32){ 
			BasicBeasts.retireBeast(beastTemplateID: beastTemplateID)
		}
		
		access(all)
		fun startNewGeneration(): UInt32{ 
			BasicBeasts.currentGeneration = BasicBeasts.currentGeneration + 1
			emit NewGenerationStarted(newCurrentGeneration: BasicBeasts.currentGeneration)
			return BasicBeasts.currentGeneration
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface BeastCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBeast(id: UInt64): &BasicBeasts.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Beast reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: BeastCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: The Beast does not exist in the Collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @BasicBeasts.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowBeast(id: UInt64): &BasicBeasts.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &BasicBeasts.NFT?
		}
		
		access(all)
		fun borrowEntireBeast(id: UInt64): &BasicBeasts.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &BasicBeasts.NFT?
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let basicBeastsNFT = nft as! &BasicBeasts.NFT
			return basicBeastsNFT
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// -----------------------------------------------------------------------
	// Access(Account) Functions
	// -----------------------------------------------------------------------
	// Used for all types of minting of beasts: admin minting, evolution minting, and breeding minting
	access(account)
	fun mintBeast(beastTemplateID: UInt32, matron: BeastNftStruct?, sire: BeastNftStruct?, evolvedFrom: [BeastNftStruct]?): @NFT{ 
		// Pre-condition that has to be followed regardless of Admin Minting, Evolution Minting, or Breeding Minting.
		pre{ 
			BasicBeasts.beastTemplates[beastTemplateID] != nil:
				"Cannot mint Beast: Beast Template ID does not exist"
			!BasicBeasts.retired[beastTemplateID]!:
				"Cannot mint Beast: Beast is retired"
		}
		let newBeast: @NFT <- create NFT(beastTemplateID: beastTemplateID, matron: matron, sire: sire, evolvedFrom: evolvedFrom)
		let skin = newBeast.getBeastTemplate().skin
		if skin == "Mythic Diamond"{ 
			BasicBeasts.retireBeast(beastTemplateID: newBeast.getBeastTemplate().beastTemplateID)
		}
		return <-newBeast
	}
	
	access(account)
	fun retireBeast(beastTemplateID: UInt32){ 
		pre{ 
			BasicBeasts.retired[beastTemplateID] != nil:
				"Cannot retire the Beast: The Beast Template ID doesn't exist."
			(BasicBeasts.beastTemplates[beastTemplateID]!).skin != "Normal":
				"Cannot retire the Beast: Cannot retire Normal skin beasts."
		}
		if !BasicBeasts.retired[beastTemplateID]!{ 
			BasicBeasts.retired[beastTemplateID] = true
			emit BeastRetired(beastTemplateID: beastTemplateID, numberMintedPerBeastTemplate: BasicBeasts.numberMintedPerBeastTemplate[beastTemplateID]!)
		}
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	view fun validateNickname(nickname: String): Bool{ 
		if nickname.length > 16{ 
			return false
		}
		return true
	}
	
	// -----------------------------------------------------------------------
	// Public Getter Functions
	// -----------------------------------------------------------------------	
	access(all)
	fun getAllBeastTemplates():{ UInt32: BeastTemplate}{ 
		return self.beastTemplates
	}
	
	access(all)
	fun getAllBeastTemplateIDs(): [UInt32]{ 
		return self.beastTemplates.keys
	}
	
	access(all)
	fun getBeastTemplate(beastTemplateID: UInt32): BeastTemplate?{ 
		return self.beastTemplates[beastTemplateID]
	}
	
	access(all)
	fun getRetiredDictionary():{ UInt32: Bool}{ 
		return self.retired
	}
	
	access(all)
	fun getAllRetiredKeys(): [UInt32]{ 
		return self.retired.keys
	}
	
	access(all)
	fun isBeastRetired(beastTemplateID: UInt32): Bool?{ 
		return self.retired[beastTemplateID]
	}
	
	access(all)
	fun getAllNumberMintedPerBeastTemplate():{ UInt32: UInt32}{ 
		return self.numberMintedPerBeastTemplate
	}
	
	access(all)
	fun getAllNumberMintedPerBeastTemplateKeys(): [UInt32]{ 
		return self.numberMintedPerBeastTemplate.keys
	}
	
	access(all)
	fun getNumberMintedPerBeastTemplate(beastTemplateID: UInt32): UInt32?{ 
		return self.numberMintedPerBeastTemplate[beastTemplateID]
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create self.Collection()
	}
	
	init(){ 
		// Set named paths
		self.CollectionStoragePath = /storage/BasicBeastsCollection
		self.CollectionPublicPath = /public/BasicBeastsCollection
		self.CollectionPrivatePath = /private/BasicBeastsCollection
		self.AdminStoragePath = /storage/BasicBeastsAdmin
		self.AdminPrivatePath = /private/BasicBeastsAdminUpgrade
		
		// Initialize the fields
		self.totalSupply = 0
		self.currentGeneration = 1
		self.beastTemplates ={} 
		self.retired ={} 
		self.numberMintedPerBeastTemplate ={} 
		self.royalties = [MetadataViews.Royalty(receiver: self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, // 5% royalty on secondary sales																																				 
																																				 description: "Basic Beasts 5% royalty from secondary sales.")]
		
		// Put Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&BasicBeasts.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}/*
	Basic Beasts was initially a simple idea made by a 10-year-old boy in late 2021. 
	However, this idea would have never come to fruition without the help and support of the community.
	We are here because of you. Thank you for creating Basic Beasts.
	
	bb boy, wb, swt, jake, bz, pan, xpromt, alxo, hsuan, bjartek, unlocked, james, nish, 

	mik, roham, dete, maxstarka, bebner, joshua, kim, albert, chandan, andreh, sonia, 

	gel, morgan, saihaj, techbubble, quin, aivan, kyle, bswides, wheel, yadra, alfredoo, jingtao, 
	
	coopervodka, nick, cryptonautik, dotti, fidelio, angelo, maxime, ersin, 17pgts, 
	flowpark, alpventure, ranger, demarcal, devboi, mokville, 
	knotbean, nh, chimkenparm, ricky, bam, kelcoin, timon, pavspec, klaimer, 
	misterzenzi, vovaedet, jegs, lakeshow32, hempdoctor420, ripcityreign, cdavis82, 
	tonyprofits, scorpius, dankochen, lonestarsmoker, kingkong, v1a0, demisteward, 
	davep, andy2112, santiago, viktozi, jamesdillonbond, superstar, phoenix, massmike4200, 
	kozak99, s41ntl3ss, tippah, nunot, qjb, dverity, diabulos, txseppe, cabruhl, 
	suurikat, eekmanni, echapa, dbone, mikey31, f8xj, packdrip, defkeet, thetafuelz, 
	elite4max, mrfred, annyongnewman, petethetipsybeet49, abo, jhoem, thekingbeej, 
	mak, gauchoide, nikitak, kselian, kody2323, carrie, dutts, spyturtle1122, 
	burntfrito, blutroyal, pooowei, yoghurt4, maxbasev, slackhash, ballinonabudget05, 
	flowlifer, ahmetbaksi, jjyumyum, ranger, kazimirzenit, bad81, divisionday, svejk, 
	pyangot, giottoarts, earlyadopter, 54srn54, ninobrown34, sse0321, laguitte, woods, 
	vkurenkov, valor, vitalyk, groat, duskykoyote, royrumbler, yeahyou27, kybleu, 
	intoxicaitlyn, nicekid, marci, dhrussel, pennyhoardaway, roaringhammy, smuge, anpol, 
	kaneluo, valentime, bhrtt, borough, rg, lessthanx3, kizobe9d9, tk24, nokalaka, nftrell, 
	fragglecar, twix4us, makolacky, charlenek, idinakhuy, thedarkside, wigwag, kel, foulmdp, 
	bign8ive, unboxinglife, sirmpineapple, hector, cal, mauro06, aguswjy, lorklein, henniganx, 
	t1les, robocot34, dickson, luba22, sebatessey, robelc, hitsuji, icedragonslayer, 
	squeakytadpole, papavader, edogg1976, jiexawow, ezweezy, zenyk2, briando, fen, joka, 
	mr2194, apaxngh, baldmamba, regoisreal, furkangg, bigedude, srchadwick, lild923, and many more.
	
	Let's have fun beastkid21!

*/


