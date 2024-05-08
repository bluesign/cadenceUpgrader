// This contract represents the Otter NFT minted from the Pack NFT
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MindtrixUtility from "./MindtrixUtility.cdc"

import MindtrixViews from "./MindtrixViews.cdc"

access(all)
contract MindtrixOtter: NonFungibleToken{ 
	
	//========================================================
	// PATH
	//========================================================
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	//========================================================
	// EVENT
	//========================================================
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, metadataHash: [UInt8], strMetadata:{ String: String}, intMetadata:{ String: UInt64}, fixMetadata:{ String: UFix64}, components:{ String: UInt64})
	
	//========================================================
	// MUTABLE STATE
	//========================================================
	access(all)
	var totalSupply: UInt64
	
	//========================================================
	// STRUCT
	//========================================================
	// Tier defines the rarity score of Otter Trait
	access(all)
	struct Tier{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let score: UFix64
		
		init(id: UInt64, name: String, description: String, score: UFix64){ 
			self.id = id
			self.name = name
			self.score = score
			self.description = description
		}
	}
	
	// OtterVo represents the important data of the Otter NFT, such as fields defined in MetadataViews.
	access(all)
	struct OtterVo{ 
		access(all)
		let nftID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let collectionImgURL: String
		
		access(all)
		let entityID: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let editionName: String
		
		access(all)
		var maxSupply: UInt64?
		
		access(all)
		let externalURL: String
		
		access(all)
		let thumbnailURL: String
		
		access(all)
		let bannerURL: String
		
		access(all)
		let metadataHashString: String
		
		access(all)
		let traits: MetadataViews.Traits
		
		access(all)
		let royalties: [MetadataViews.Royalty]
		
		init(nftID: UInt64, strMetadata:{ String: String}, intMetadata:{ String: UInt64}, components:{ String: UInt64}, metadataHash: [UInt8], royalties: [MetadataViews.Royalty]){ 
			self.nftID = nftID
			// the Otter NFT comes from a pack minted by an entity(template) in a set.
			self.collectionImgURL = "https://bafybeie275kmvc3ssk2sub4nfgsnsuzoqnttrluw6zcspyeqeaiiiusfr4.ipfs.w3s.link/otter_nft_collection_square.jpg"
			self.setID = intMetadata["setID"] ?? 0
			self.entityID = intMetadata["entityID"] ?? 0
			self.packID = intMetadata["packID"] ?? 0
			self.name = strMetadata["name"] ?? ""
			self.serial = intMetadata["metadataSerial"] ?? MindtrixOtter.getMetadataSerial(nameWithSerial: self.name) ?? intMetadata["mintedSerial"] ?? 0
			self.description = "9,999 adventurous 3D Otter equipped with unique accessories landing in Mindtrixverse. The Otter is your digital identity. For example, holders are eligible to claim a .gltf and .vrm file and exchange accessories. Moreover, you are one of the Alpha to join exclusive events such as Voice to Earn, Voice Wormhole, Voting, etc. Collectively, we will form long-term values and become the voice community leader in Web3. Learn more: mindtrix.xyz Mindtrix, LTD. All Rights Reserved."
			self.editionName = strMetadata["edition_name"] ?? "Mindtrix Otter NFT Series 1"
			// maxSupply should be assigned from the sum of entities' supply in the MindtrixPack.Set
			self.maxSupply = nil
			self.externalURL = strMetadata["external_url"] ?? ""
			self.thumbnailURL = strMetadata["thumbnail_url"] ?? ""
			self.bannerURL = strMetadata["banner_url"] ?? "https://firebasestorage.googleapis.com/v0/b/mindtrix-pro.appspot.com/o/public%2Fmindtrix%2Fmindtrix_banner.svg?alt=media&token=34a09a8e-50ad-415c-8d65-a57e6ed9aef6"
			self.metadataHashString = String.encodeHex(metadataHash)
			self.royalties = royalties
			let traits: [MetadataViews.Trait] = []
			for k in strMetadata.keys{ 
				let traitKeyWords = "trait_"
				let traitKeyWordsLen = traitKeyWords.length
				if k.length < traitKeyWordsLen{ 
					continue
				}
				let attrKey = k.slice(from: 0, upTo: traitKeyWordsLen)
				let value = strMetadata[k]!
				let isNone = value == "none"
				let isAttributes = !isNone && attrKey == traitKeyWords
				if isAttributes{ 
					let attrName = MindtrixUtility.upperCaseFirstChar(k.slice(from: traitKeyWordsLen, upTo: k.length))
					let rarity = MindtrixOtter.getAccessoryRarityByTraitName(attrName, value)
					let trait = MetadataViews.Trait(name: attrName, value: value, displayType: "String", rarity: rarity)
					traits.append(trait)
				}
			}
			let landmarkTraitName = "Landmark"
			let landmarkTraitValue = strMetadata["landmark_name"] ?? ""
			let trait = MetadataViews.Trait(name: landmarkTraitName, value: landmarkTraitValue, displayType: "String", rarity: MindtrixOtter.getAccessoryRarityByTraitName(landmarkTraitName, landmarkTraitValue))
			traits.append(trait)
			self.traits = MetadataViews.Traits(traits)
		}
		
		access(all)
		fun updateMaxSupply(_ maxSupply: UInt64){ 
			self.maxSupply = maxSupply
		}
	}
	
	//========================================================
	// RESOURCE
	//========================================================
	access(all)
	resource interface INFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let minterAddress: Address
		
		// getVo() aims to provide commonly-used data, such as fields defined in MetadataViews.
		access(all)
		fun getVo(): OtterVo
		
		access(all)
		fun getMetadataHash(): [UInt8]
		
		access(all)
		fun getStrMetadata():{ String: String}
		
		access(all)
		fun getIntMetadata():{ String: UInt64}
		
		access(all)
		fun getFixMetadata():{ String: UFix64}
		
		access(all)
		fun getComponents():{ String: UInt64}
		
		access(all)
		fun verifyHash(): Bool
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, INFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let minterAddress: Address
		
		access(contract)
		let metadataHash: [UInt8]
		
		access(self)
		let setCollectionPublicCap: Capability<&{MindtrixViews.IHashProvider}>
		
		access(self)
		var strMetadata:{ String: String}
		
		access(self)
		var intMetadata:{ String: UInt64}
		
		access(self)
		var fixMetadata:{ String: UFix64}
		
		// components is a reserved field for mapping the future Accessory NFT
		access(self)
		var components:{ String: UInt64}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		var extra:{ String: AnyStruct}
		
		init(minterAddress: Address, metadataHash: [UInt8], setCollectionPublicCap: Capability<&{MindtrixViews.IHashProvider}>, strMetadata:{ String: String}, intMetadata:{ String: UInt64}, fixMetadata:{ String: UFix64}, components:{ String: UInt64}, royalties: [MetadataViews.Royalty]){ 
			self.id = self.uuid
			self.minterAddress = minterAddress
			self.metadataHash = metadataHash
			self.setCollectionPublicCap = setCollectionPublicCap
			self.strMetadata = strMetadata
			self.intMetadata = intMetadata
			self.fixMetadata = fixMetadata
			self.components = components
			self.royalties = royalties
			self.extra ={} 
			let serial = MindtrixOtter.totalSupply + UInt64(1)
			self.intMetadata["mintedSerial"] = serial
			self.intMetadata["metadataSerial"] = MindtrixOtter.getMetadataSerial(nameWithSerial: self.strMetadata["name"] ?? "")
			emit Created(id: self.id, metadataHash: metadataHash, strMetadata: self.strMetadata, intMetadata: self.intMetadata, fixMetadata: self.fixMetadata, components: self.components)
			MindtrixOtter.totalSupply = serial
		}
		
		access(all)
		fun getMetadataHash(): [UInt8]{ 
			return self.metadataHash
		}
		
		access(all)
		fun generateMetadataHash(): [UInt8]{ 
			return MindtrixUtility.generateMetadataHash(strMetadata: self.getStrMetadata())
		}
		
		access(all)
		fun verifyHash(): Bool{ 
			let setID = self.intMetadata["setID"]!
			let packID = self.intMetadata["packID"]!
			let hashVerifier = (self.setCollectionPublicCap.borrow()!).borrowHashVerifier(setID: setID, packID: packID)
			return hashVerifier.verifyHash(setID: setID, packID: packID, metadataHash: self.generateMetadataHash())
		}
		
		access(all)
		fun getSetCollectionPublicCap(): Capability<&{MindtrixViews.IHashProvider}>{ 
			return self.setCollectionPublicCap
		}
		
		access(all)
		fun getStrMetadata():{ String: String}{ 
			return self.strMetadata
		}
		
		access(all)
		fun getIntMetadata():{ String: UInt64}{ 
			return self.intMetadata
		}
		
		access(all)
		fun getFixMetadata():{ String: UFix64}{ 
			return self.fixMetadata
		}
		
		access(all)
		fun getComponents():{ String: UInt64}{ 
			return self.getComponents()
		}
		
		access(all)
		fun getVo(): OtterVo{ 
			return OtterVo(nftID: self.id, strMetadata: self.strMetadata, intMetadata: self.intMetadata, components: self.components, metadataHash: self.getMetadataHash(), royalties: self.royalties)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Edition>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let nftData = self.getVo()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: nftData.name, description: nftData.description, thumbnail: MetadataViews.HTTPFile(url: nftData.thumbnailURL))
				case Type<MetadataViews.Edition>():
					return MetadataViews.Edition(name: nftData.editionName, number: nftData.serial, max: nftData.maxSupply)
				case Type<MetadataViews.Serial>():
					let mintedSerial = self.intMetadata["mintedSerial"] ?? 0
					let metadataSerial = self.intMetadata["metadataSerial"] ?? MindtrixOtter.getMetadataSerial(nameWithSerial: self.strMetadata["name"] ?? mintedSerial.toString()) ?? mintedSerial
					return MetadataViews.Serial(metadataSerial)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(nftData.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://mindtrix.xyz/verse")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MindtrixOtter.CollectionStoragePath, publicPath: MindtrixOtter.CollectionPublicPath, publicCollection: Type<&MindtrixOtter.Collection>(), publicLinkedType: Type<&MindtrixOtter.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MindtrixOtter.createEmptyCollection(nftType: Type<@MindtrixOtter.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bafybeie275kmvc3ssk2sub4nfgsnsuzoqnttrluw6zcspyeqeaiiiusfr4.ipfs.w3s.link/otter_nft_collection_square.jpg"), mediaType: "image/jpeg")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bafybeigjvtszqps3frwnx5pnoqyqdtjcqc3pyzpbfkxzrxuuviz34nlmba.ipfs.w3s.link/banner_otter_nft_collection.jpg"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "Mindtrix Otter", description: "9,999 adventurous 3D Otter equipped with unique accessories landing in Mindtrixverse. The Otter is your digital identity. For example, holders are eligible to claim a .gltf and .vrm file and exchange accessories. Moreover, you are one of the Alpha to join exclusive events such as Voice to Earn, Voice Wormhole, Voting, etc. Collectively, we will form long-term values and become the voice community leader in Web3. Learn more: mindtrix.xyz Mindtrix, LTD. All Rights Reserved.", externalURL: MetadataViews.ExternalURL("https://mindtrix.xyz"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "discord": MetadataViews.ExternalURL("https://link.mindtrix.xyz/Discord"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/mindtrix_dao"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/mindtrix.dao"), "twitter": MetadataViews.ExternalURL("https://twitter.com/mindtrix_dao")})
				case Type<MetadataViews.Rarity>():
					return MindtrixOtter.getOtterRarityByTraits(nftData.traits)
				case Type<MetadataViews.Traits>():
					return nftData.traits
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMindtrixOtterNFTPublic(id: UInt64): &MindtrixOtter.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Mindtrix Otter NFT reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MindtrixOtter.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowMindtrixOtterNFTPublic(id: UInt64): &MindtrixOtter.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let otter = ref as! &MindtrixOtter.NFT
				let otterPublic = otter as &MindtrixOtter.NFT
				return otterPublic
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mindtrixOtterNFT = nft as! &MindtrixOtter.NFT
			return mindtrixOtterNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	fun getMetadataSerial(nameWithSerial: String): UInt64?{ 
		let prefixName = "Otter #"
		let serialStr = nameWithSerial.slice(from: prefixName.length, upTo: nameWithSerial.length)
		let int = Int.fromString(serialStr)
		return int == nil ? nil : UInt64(int!)
	}
	
	access(all)
	fun getAccessoryRarityByTraitName(_ traitName: String, _ traitValue: String?): MetadataViews.Rarity{ 
		let max = 5.0
		let commonTraitName = ["Background"]
		let defaultRarity = MetadataViews.Rarity(score: 1.0, max: max, description: "Common")
		if traitValue == nil || commonTraitName.contains(traitName){ 
			return defaultRarity
		}
		let rarities = [MetadataViews.Rarity(score: 5.0, max: max, description: "Epic"), MetadataViews.Rarity(score: 3.0, max: max, description: "Rare"), MetadataViews.Rarity(score: 1.0, max: max, description: "Common")]
		// Check if the traitName is Color since they dont' have customTiers' keyword
		if traitName == "Color"{ 
			if traitValue == "Original"{ 
				return rarities[2]
			} else if traitValue == "Beige" || traitValue == "Hyacinth" || traitValue == "Lime"{ 
				return rarities[1]
			} else if traitValue == "Black"{ 
				return rarities[0]
			}
		}
		let customTiers = ["Golden", "Cyberpunk", "Common"]
		for i, cTier in customTiers{ 
			let tierNameLen = cTier.length
			let traitValueLen = (traitValue!).length
			if traitValueLen < tierNameLen{ 
				continue
			}
			if (traitValue!).slice(from: 0, upTo: tierNameLen).toLower() == cTier.toLower(){ 
				return rarities[i]
			}
		}
		return defaultRarity
	}
	
	access(all)
	fun getOtterRarityByTraits(_ traits: MetadataViews.Traits): MetadataViews.Rarity{ 
		let max = 35.0
		let defaultRarity = MetadataViews.Rarity(score: 0.0, max: max, description: "Common")
		if traits.traits.length < 1{ 
			return defaultRarity
		}
		let customTiers = [Tier(id: 1, name: "Epic", description: "", score: 35.0), Tier(id: 2, name: "Legendary", description: "", score: 17.0), Tier(id: 3, name: "Rare", description: "", score: 13.0), Tier(id: 4, name: "Common", description: "", score: 11.0)]
		var scoreSum = 0.0
		for i, trait in traits.traits{ 
			scoreSum = scoreSum + (trait.rarity?.score ?? 0.0)
		}
		var rarityDescription = "Common"
		for i, cTier in customTiers{ 
			let isFirst = i == 0
			if scoreSum > cTier.score{ 
				let index = isFirst ? i : i - 1
				rarityDescription = customTiers[index].name
			}
		}
		return MetadataViews.Rarity(score: scoreSum, max: max, description: rarityDescription)
	}
	
	access(account)
	fun mintNFT(minterAddress: Address, metadataHash: [UInt8], setCollectionPublicCap: Capability<&{MindtrixViews.IHashProvider}>, strMetadata:{ String: String}, intMetadata:{ String: UInt64}, fixMetadata:{ String: UFix64}, components:{ String: UInt64}, royalties: [MetadataViews.Royalty]): @NFT{ 
		pre{ 
			strMetadata.keys.length > 0:
				"Cannot mint Otter NFT with empty strMetadata"
			royalties.length > 0:
				"Cannot mint Otter NFT with empty royalties"
		}
		let currentBlock = getCurrentBlock()
		intMetadata["mintedBlock"] = currentBlock.height
		fixMetadata["mintedTime"] = currentBlock.timestamp
		var newNFT <- create NFT(minterAddress: minterAddress, metadataHash: metadataHash, setCollectionPublicCap: setCollectionPublicCap, strMetadata: strMetadata, intMetadata: intMetadata, fixMetadata: fixMetadata, components: components, royalties: royalties)
		return <-newNFT
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/MindtrixOtterNFTCollection
		self.CollectionPublicPath = /public/MindtrixOtterNFTCollection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&MindtrixOtter.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
