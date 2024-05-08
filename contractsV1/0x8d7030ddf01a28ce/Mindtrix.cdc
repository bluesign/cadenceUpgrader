/*

============================================================
Name: NFT Contract for Mindtrix
Author: AS
============================================================

Mindtrix is a decentralized podcast community on Flow.
A community derives from podcasters, listeners, and collectors.

Mindtrix aims to provide a better revenue stream for podcasters
and build a value-oriented NFT for collectors to support their
favorite podcasters easily. :)

The contract represents the core functionalities of Mindtrix
NFTs. Podcasters can mint the two kinds of NFTs, Essence Audio
and Essence Image, based on their podcast episodes. Collectors
can buy the NFTs from podcasters' public sales or secondary
market on Flow.

Besides implementing the MetadataViews(thanks for the strong
community to build this standard), we also add some structure
to encapsulate the view objects. For example, the SerialGenus
categorize NFTs in a hierarchical genus structure, explaining
the NFT's origin from a specific episode under a show. You can
check the detailed definition in the resolveView function of
the SerialGenuses type.

Mindtrix's vision is to create long-term value for NFTs.
If more collectors are willing to get meaningful ones, it
would also bring a new revenue stream for creators.
Therefore, more people would embrace the crypto world!

To flow into the Mindtrix forest, please check:
https://www.mindtrix.xyz

============================================================

*/


// dev
// import FungibleToken from "../0xee82856bf20e2aa6/FungibleToken.cdc"
// import NonFungibleToken from "../0xf8d6e0586b0a20c7/NonFungibleToken.cdc"
// import MetadataViews from "../0xf8d6e0586b0a20c7/MetadataViews.cdc"

// testnet
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"

// pro
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"
access(all)
contract Mindtrix: NonFungibleToken{ 
	
	// ========================================================
	//						  PATH
	// ========================================================
	access(all)
	let RoyaltyReceiverPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MindtrixEssenceCollectionStoragePath: StoragePath
	
	access(all)
	let MindtrixEssenceCollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// ========================================================
	//						  EVENT
	// ========================================================
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTMinted(id: UInt64, name: String, description: String, ipfsCid: String, ipfsDirectory: String, serial: UInt64, editionNumber: UInt64, royaltyRecipient: [Address])
	
	access(all)
	event NFTFreeMinted(essenceId: UInt64, minter: Address, essenceName: String, essenceDescription: String, ipfsCid: String, ipfsDirectory: String)
	
	access(all)
	event AudioEssenceCreated(offChainedId: String, essenceId: UInt64, essenceName: String, essenceDescription: String, showGuid: String, episodeGuid: String, audioStartTime: UFix64, audioEndTime: UFix64, fullEpisodeDuration: UFix64, externalURL: String)
	
	access(all)
	event ImageEssenceCreated(offChainedId: String, essenceId: UInt64, essenceName: String, essenceDescription: String, showGuid: String, episodeGuid: String, imageUrl: String, externalURL: String)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// ========================================================
	//					   MUTABLE STATE
	// ========================================================
	access(all)
	var totalSupply: UInt64
	
	// store Essences' public link for ppl to access its public metadata
	access(self)
	var showGuidToEssenceIds:{ String:{ UInt64: Bool}}
	
	access(self)
	var essenceDic: @{UInt64: Essence}
	
	access(self)
	var essenceIdsToCreationIds:{ UInt64:{ UInt64: Bool}}
	
	// TODO: a creation should be accessed its public metadata
	//	access(self) var creationDic: @{UInt64: NFT}
	// ========================================================
	//					  IMMUTABLE STATE
	// ========================================================
	access(all)
	let AdminAddress: Address
	
	access(all)
	let MindtrixDaoTreasuryRef: Capability<&{FungibleToken.Receiver}>
	
	// ========================================================
	//			   COMPOSITE TYPES: STRUCTURE
	// ========================================================
	access(all)
	struct SerialGenuses{ 
		access(all)
		let infoList: [SerialGenus]
		
		init(infoList: [SerialGenus]){ 
			self.infoList = infoList
		}
	}
	
	// SerialGenus aims to breakdown an NFT's genus
	access(all)
	struct SerialGenus{ 
		// number 1 here is defined as the top tier
		access(all)
		let tier: UInt8
		
		access(all)
		let name: String
		
		access(all)
		let description: String?
		
		access(all)
		let number: Number
		
		init(tier: UInt8, number: Number, name: String, description: String?){ 
			self.tier = tier
			self.number = number
			self.name = name
			self.description = description
		}
	}
	
	// AudioEssence is optional and only exists when an NFT is a VoiceSerial.audio.
	access(all)
	struct AudioEssence{ 
		// The UFix64 type is to support the time in milliseconds, e.g. startTime = 96.0 = 00:01:36
		access(all)
		let startTime: UFix64?
		
		// The UFix64 type is to support the time in milliseconds, e.g. endTime = 365.0 = 00:06:05
		access(all)
		let endTime: UFix64?
		
		// The UFix64 type is to support the time in milliseconds, e.g. fullEpisodeDuration = 1864.0 = 00:31:04
		access(all)
		let fullEpisodeDuration: UFix64?
		
		init(startTime: UFix64?, endTime: UFix64?, fullEpisodeDuration: UFix64?){ 
			self.startTime = startTime
			self.endTime = endTime
			self.fullEpisodeDuration = fullEpisodeDuration
		}
	}
	
	// SerialString represents a searching purpose to discern the NFTs genus.
	access(all)
	struct SerialString{ 
		access(all)
		let str: String
		
		init(str: String){ 
			self.str = str
		}
	}
	
	access(all)
	struct EssenceIdentifier{ 
		access(all)
		let uuid: UInt64
		
		// UInt64 from getSerialNumber()
		access(all)
		let serial: UInt64
		
		// owner of the token at that time
		access(all)
		let holder: Address
		
		access(all)
		let showGuid: String
		
		access(all)
		let episodeGuid: String
		
		// The time this identifier is created, could be a claimTime, transferTime
		access(all)
		let createdTime: UFix64
		
		init(uuid: UInt64, serial: UInt64, holder: Address, showGuid: String, episodeGuid: String, createdTime: UFix64){ 
			self.uuid = uuid
			self.serial = serial
			self.showGuid = showGuid
			self.episodeGuid = episodeGuid
			self.holder = holder
			self.createdTime = getCurrentBlock().timestamp
		}
	}
	
	// EssenceToNFTId is a helper struct and stores collector's all Mindtrix NFTs mapping to a specific collection
	access(all)
	struct EssenceToNFTId{ 
		access(account)
		var dic:{ UInt64:{ UInt64: Bool}}
		
		access(account)
		fun addNFT(collectionId: UInt64, nftId: UInt64): Void{ 
			self.dic.insert(key: collectionId,{ nftId: true})
		}
		
		access(account)
		fun removeNFT(collectionId: UInt64, nftId: UInt64): Void{ 
			(self.dic[collectionId]!).remove(key: nftId)
		}
		
		access(account)
		fun getOwnedNFTIdsFromCollection(collectionId: UInt64): [UInt64]{ 
			let nftIds: [UInt64] = []
			let nftIdsFromCollection = self.dic[collectionId]!
			if nftIdsFromCollection.length > 0{ 
				for nftId in nftIdsFromCollection.keys{ 
					if nftIdsFromCollection[nftId] != nil{ 
						nftIds.append(nftId)
					}
				}
			}
			return nftIds
		}
		
		init(){ 
			self.dic ={} 
		}
	}
	
	access(all)
	struct NFTIdentifier{ 
		access(all)
		let uuid: UInt64
		
		// UInt64 from getSerialNumber()
		access(all)
		let serial: UInt64
		
		// owner of the token at that time
		access(all)
		let holder: Address
		
		// The time this identifier is created, could be a claimTime, transferTime
		access(all)
		let createdTime: UFix64
		
		init(uuid: UInt64, serial: UInt64, holder: Address){ 
			self.uuid = uuid
			self.serial = serial
			self.holder = holder
			self.createdTime = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	struct FT{ 
		access(all)
		let path: PublicPath
		
		access(all)
		let price: UFix64
		
		init(path: PublicPath, price: UFix64){ 
			self.path = path
			self.price = price
		}
	}
	
	access(all)
	struct Prices{ 
		access(all)
		var ftDic:{ String: FT}
		
		init(ftDic:{ String: FT}){ 
			self.ftDic = ftDic
		}
	}
	
	// verify the conditions that a user should pass during minting
	access(all)
	struct interface IVerifier{ 
		access(account)
		fun verify(_ params:{ String: AnyStruct})
	}
	
	// ========================================================
	//			   COMPOSITE TYPES: RESOURCE
	// ========================================================
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// format in uuid for a better mapping with off-chain data
		access(all)
		let id: UInt64
		
		access(all)
		let essenceId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let ipfsCid: String
		
		access(all)
		let ipfsDirectory: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		let showGuid: String
		
		access(all)
		let episodeGuid: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionExternalURL: String
		
		access(all)
		let collectionSquareImageUrl: String
		
		access(all)
		let collectionSquareImageType: String
		
		access(all)
		let collectionSocials:{ String: String}
		
		access(all)
		let firstSerial: UInt16
		
		access(all)
		let secondSerial: UInt16
		
		access(all)
		let thirdSerial: UInt16
		
		access(all)
		let fourthSerial: UInt32
		
		access(all)
		let fifthSerial: UInt16
		
		access(all)
		let editionNumber: UInt64
		
		access(all)
		let editionQuantity: UInt64
		
		access(all)
		let licenseIdentifier: String
		
		init(essenceId: UInt64, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64, editionQuantity: UInt64, metadata:{ String: AnyStruct}){ 
			self.id = self.uuid
			self.essenceId = essenceId
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.ipfsCid = ipfsCid
			self.ipfsDirectory = ipfsDirectory
			self.royalties = royalties
			self.showGuid = showGuid
			self.episodeGuid = episodeGuid
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionExternalURL = collectionExternalURL
			self.collectionSquareImageUrl = collectionSquareImageUrl
			self.collectionSquareImageType = collectionSquareImageType
			self.collectionSocials = collectionSocials
			self.licenseIdentifier = licenseIdentifier
			self.firstSerial = firstSerial
			self.secondSerial = secondSerial
			self.thirdSerial = thirdSerial
			self.fourthSerial = fourthSerial
			self.fifthSerial = fifthSerial
			self.editionNumber = editionNumber
			self.editionQuantity = editionQuantity
			self.metadata = metadata
			var royaltyRecipient: [Address] = []
			for ele in royalties{ 
				royaltyRecipient.append(ele.receiver.address)
			}
			emit NFTMinted(id: self.id, name: name, description: description, ipfsCid: self.ipfsCid, ipfsDirectory: self.ipfsDirectory, serial: self.getSerialNumber(), editionNumber: editionNumber, royaltyRecipient: royaltyRecipient)
			Mindtrix.totalSupply = Mindtrix.totalSupply + UInt64(1)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.License>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<Mindtrix.SerialString>(), Type<Mindtrix.SerialGenuses>(), Type<Mindtrix.EssenceIdentifier>()]
		}
		
		access(all)
		fun getSerialNumber(): UInt64{ 
			return Mindtrix.getSerialNumber(firstSerial: self.firstSerial, secondSerial: self.secondSerial, thirdSerial: self.thirdSerial, fourthSerial: self.fourthSerial, fifthSerial: self.fifthSerial, editionNumber: self.editionNumber)
		}
		
		access(all)
		fun getSerialGenus(): [Mindtrix.SerialGenus]{ 
			return Mindtrix.getSerialGenus(firstSerial: self.firstSerial, secondSerial: self.secondSerial, thirdSerial: self.thirdSerial, fourthSerial: self.fourthSerial, fifthSerial: self.fifthSerial, editionNumber: self.editionNumber)
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.ExternalURL>():
					// the URL will be replaced with a gallery link in the future.
					return MetadataViews.ExternalURL(self.collectionExternalURL)
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: self.collectionName, number: self.editionNumber, max: self.editionQuantity)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.getSerialNumber())
				case Type<Mindtrix.SerialString>():
					return Mindtrix.SerialString(str: self.getSerialNumber().toString())
				case Type<Mindtrix.SerialGenuses>():
					return self.getSerialGenus()
				case Type<Mindtrix.AudioEssence>():
					return self.metadata["audioEssence"] ?? Mindtrix.AudioEssence(startTime: 0.0, endTime: 0.0, fullEpisodeDuration: 0.0)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.ipfsCid, path: self.ipfsDirectory)
				case Type<MetadataViews.License>():
					return MetadataViews.License(self.licenseIdentifier)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Mindtrix.CollectionStoragePath, publicPath: Mindtrix.CollectionPublicPath, publicCollection: Type<&Mindtrix.Collection>(), publicLinkedType: Type<&Mindtrix.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Mindtrix.createEmptyCollection(nftType: Type<@Mindtrix.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.collectionSquareImageUrl), mediaType: self.collectionSquareImageType)
					var socials ={}  as{ String: MetadataViews.ExternalURL}
					for key in self.collectionSocials.keys{ 
						let socialUrl = self.collectionSocials[key]!
						socials.insert(key: key, MetadataViews.ExternalURL(socialUrl))
					}
					return MetadataViews.NFTCollectionDisplay(name: self.collectionName, description: self.collectionDescription, externalURL: MetadataViews.ExternalURL(self.collectionExternalURL), squareImage: media, bannerImage: media, socials: socials)
				case Type<MetadataViews.Traits>():
					// exclude the following fields to show other uses of Traits
					let excludedTraits = ["mintedTime", "mintedBlock", "minter", "audioEssenceStartTime", "audioEssenceEndTime", "fullEpisodeDuration"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we mark it with a Date displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					let audioEssenceStartTimeTrait = MetadataViews.Trait(name: "audioEssenceStartTime", value: self.metadata["audioEssenceStartTime"] ?? 0.0, displayType: "Time", rarity: nil)
					let audioEssenceEndTimeTrait = MetadataViews.Trait(name: "audioEssenceEndTime", value: self.metadata["audioEssenceEndTime"] ?? 0.0, displayType: "Time", rarity: nil)
					let fullEpisodeDurationTrait = MetadataViews.Trait(name: "fullEpisodeDuration", value: self.metadata["fullEpisodeDuration"] ?? 0.0, displayType: "Time", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					traitsView.addTrait(audioEssenceStartTimeTrait)
					traitsView.addTrait(audioEssenceEndTimeTrait)
					traitsView.addTrait(fullEpisodeDurationTrait)
					return traitsView
				case Type<Mindtrix.EssenceIdentifier>():
					return Mindtrix.EssenceIdentifier(uuid: self.uuid, serial: self.getSerialNumber(), holder: Mindtrix.AdminAddress, showGuid: self.showGuid, episodeGuid: self.episodeGuid,																																															  // TODO: need to pass essence createdTime to nft
																																															  createdTime: 0.0)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// EssencePublic is only for public usage, and it should not be authorized to change any metadata
	access(all)
	resource interface EssencePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		let ipfsCid: String
		
		access(all)
		let ipfsDirectory: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionExternalURL: String
		
		access(all)
		let collectionSquareImageUrl: String
		
		access(all)
		let collectionSquareImageType: String
		
		access(all)
		var collectionSocials:{ String: String}
		
		access(all)
		var essenceExternalURL: String
		
		access(all)
		let limitedEdition: UInt64
		
		access(all)
		let licenseIdentifier: String
		
		access(all)
		fun freeMint(recipient: &{NonFungibleToken.CollectionPublic}, params:{ String: AnyStruct})
		
		access(all)
		fun getCurrentHolders():{ UInt64: NFTIdentifier}
		
		access(all)
		fun getCurrentHolder(essenceId: UInt64): NFTIdentifier?
		
		access(all)
		view fun getPrices():{ String: FT}?
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	// Declare a resource that only includes one function.
	access(all)
	resource Essence: EssencePublic, ViewResolver.Resolver{ 
		// The minter to a token info
		access(account)
		var minters:{ Address: NFTIdentifier}
		
		// The NFT uuid to a current holder info
		access(account)
		var currentHolders:{ UInt64: NFTIdentifier}
		
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		var prices:{ String: FT}?
		
		access(all)
		let ipfsCid: String
		
		access(all)
		let ipfsDirectory: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		let showGuid: String
		
		access(all)
		let episodeGuid: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionExternalURL: String
		
		access(all)
		let collectionSquareImageUrl: String
		
		access(all)
		let collectionSquareImageType: String
		
		access(all)
		var collectionSocials:{ String: String}
		
		access(all)
		var essenceExternalURL: String
		
		// firstSerial: nft realm enum
		access(all)
		let firstSerial: UInt16
		
		// secondSerial: nft enum
		access(all)
		let secondSerial: UInt16
		
		// thirdSerial: podcast show serial
		access(all)
		let thirdSerial: UInt16
		
		// fourthSerial: episode number
		access(all)
		let fourthSerial: UInt32
		
		// fifthSerial: essence edition
		access(all)
		let fifthSerial: UInt16
		
		access(all)
		var currentEdition: UInt64
		
		access(all)
		let limitedEdition: UInt64
		
		access(all)
		let licenseIdentifier: String
		
		access(all)
		let createdTime: UFix64
		
		access(account)
		let verifiers:{ String: [{Mindtrix.IVerifier}]}
		
		access(all)
		fun freeMint(recipient: &{NonFungibleToken.CollectionPublic}, params:{ String: AnyStruct}){ 
			pre{ 
				self.getPrices() == nil:
					"You have to purchase this essence."
			// self.claimable:
			//	"This Essence is not claimable, and thus not currently active."
			}
			self.verifyAndMint(recipient: recipient, params: params)
			log("essenceId:".concat(self.id.toString()))
			emit NFTFreeMinted(essenceId: self.id, minter: (recipient.owner!).address, essenceName: self.name, essenceDescription: self.description, ipfsCid: self.ipfsCid, ipfsDirectory: self.ipfsDirectory)
		}
		
		access(all)
		view fun getPrices():{ String: FT}?{ 
			if let prices = self.prices{ 
				return prices as!{ String: FT}
			}
			return nil
		}
		
		access(all)
		fun getCurrentHolder(essenceId: UInt64): NFTIdentifier?{ 
			pre{ 
				self.currentHolders[essenceId] != nil:
					"This serial has not been created yet."
			}
			let identifier = self.currentHolders[essenceId]!
			let collection = getAccount(identifier.holder).capabilities.get<&Collection>(Mindtrix.MindtrixEssenceCollectionPublicPath).borrow<&Collection>()
			if collection?.borrowMindtrix(id: identifier.uuid) != nil{ 
				return identifier
			}
			return nil
		}
		
		access(all)
		fun getCurrentHolders():{ UInt64: NFTIdentifier}{ 
			return self.currentHolders
		}
		
		// If the NFT is free
		access(account)
		fun verifyAndMint(recipient: &{NonFungibleToken.CollectionPublic}, params:{ String: AnyStruct}){ 
			params["essence"] = &self as &Essence
			params["recipient"] = (recipient.owner!).address
			
			// Runs a loop over all the verifiers that this FLOAT Events
			// implements. For example, "Limited", "Timelock", "Secret", etc.
			// All the verifiers are in the FLOATVerifiers.cdc contract
			for identifier in self.verifiers.keys{ 
				let typedModules = (&self.verifiers[identifier] as &[{Mindtrix.IVerifier}]?)!
				var i = 0
				while i < typedModules.length{ 
					let verifier = typedModules[i] as &{Mindtrix.IVerifier}
					verifier.verify(params)
					i = i + 1
				}
			}
			log("ready to mint!")
			// pass all the conditions, so it can be minted
			let id = self.mint(recipient: recipient)
		}
		
		// track who is the first minter
		access(all)
		fun updateDicOnFirstMint(uuid: UInt64, serial: UInt64, holder: Address){ 
			self.minters[holder] = NFTIdentifier(uuid: uuid, serial: serial, holder: holder)
			self.updateDicOnDeposit(uuid: uuid, serial: serial, holder: holder)
		}
		
		// make sure to keep the holder map up to date
		access(all)
		fun updateDicOnDeposit(uuid: UInt64, serial: UInt64, holder: Address){ 
			self.currentHolders[uuid] = NFTIdentifier(uuid: uuid, serial: serial, holder: holder)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.IPFSFile>(), Type<MetadataViews.License>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<Mindtrix.AudioEssence>(), Type<Mindtrix.SerialString>(), Type<Mindtrix.SerialGenuses>(), Type<Mindtrix.EssenceIdentifier>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description,																								 // get Collection Image
																								 thumbnail: MetadataViews.IPFSFile(cid: self.collectionSquareImageUrl, path: nil))
				case Type<MetadataViews.ExternalURL>():
					// the URL will be replaced with a gallery link in the future.
					return MetadataViews.ExternalURL(self.collectionExternalURL)
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: self.name, number: 0, max: self.limitedEdition)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<Mindtrix.AudioEssence>():
					return self.metadata["audioEssence"] ?? Mindtrix.AudioEssence(startTime: 0.0, endTime: 0.0, fullEpisodeDuration: 0.0)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.getSerialNumber())
				case Type<Mindtrix.SerialGenuses>():
					return self.getSerialGenus()
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.ipfsCid, path: self.ipfsDirectory)
				case Type<MetadataViews.License>():
					return MetadataViews.License(self.licenseIdentifier)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.collectionSquareImageUrl), mediaType: self.collectionSquareImageType)
					var socials ={}  as{ String: MetadataViews.ExternalURL}
					for key in self.collectionSocials.keys{ 
						let socialUrl = self.collectionSocials[key]!
						socials.insert(key: key, MetadataViews.ExternalURL(socialUrl))
					}
					return MetadataViews.NFTCollectionDisplay(name: self.collectionName, description: self.collectionDescription, externalURL: MetadataViews.ExternalURL(self.collectionExternalURL), squareImage: media, bannerImage: media, socials: socials)
				case Type<Mindtrix.EssenceIdentifier>():
					return Mindtrix.EssenceIdentifier(uuid: self.uuid, serial: self.getSerialNumber(), holder: Mindtrix.AdminAddress, showGuid: self.showGuid, episodeGuid: self.episodeGuid, createdTime: self.createdTime)
				case Type<Mindtrix.Prices>():
					return self.getPrices()
			}
			return nil
		}
		
		access(all)
		fun getSerialNumber(): UInt64{ 
			return Mindtrix.getSerialNumber(firstSerial: self.firstSerial, secondSerial: self.secondSerial, thirdSerial: self.thirdSerial, fourthSerial: self.fourthSerial, fifthSerial: self.fifthSerial, editionNumber: self.currentEdition)
		}
		
		access(all)
		fun getSerialGenus(): [Mindtrix.SerialGenus]{ 
			return Mindtrix.getSerialGenus(firstSerial: self.firstSerial, secondSerial: self.secondSerial, thirdSerial: self.thirdSerial, fourthSerial: self.fourthSerial, fifthSerial: self.fifthSerial, editionNumber: self.currentEdition)
		}
		
		access(all)
		fun mint(recipient: &{NonFungibleToken.CollectionPublic}){ 
			
			// pass Essence collection data to Mindtrix NFT
			var metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			
			// general metadata that every NFT would include
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			// To reduce the param number, struct should be encapsulated and appended in metadata of tx, such as AudioEssence
			var creation <- create Mindtrix.NFT(essenceId: self.id, name: self.name, description: self.description, thumbnail: self.thumbnail, ipfsCid: self.ipfsCid, ipfsDirectory: self.ipfsDirectory, royalties: self.royalties, showGuid: self.showGuid, episodeGuid: self.episodeGuid, collectionName: self.collectionName, collectionDescription: self.collectionDescription, collectionExternalURL: self.collectionExternalURL, collectionSquareImageUrl: self.collectionSquareImageUrl, collectionSquareImageType: self.collectionSquareImageType, collectionSocials: self.collectionSocials, licenseIdentifier: self.licenseIdentifier, firstSerial: self.firstSerial, secondSerial: self.secondSerial, thirdSerial: self.thirdSerial, fourthSerial: self.fourthSerial, fifthSerial: self.fifthSerial, editionNumber: self.currentEdition, editionQuantity: self.limitedEdition, metadata: metadata)
			let uuid = creation.id
			let serial = creation.getSerialNumber()
			let holder = (recipient.owner!).address
			// add the edition number on minting every NFT
			log("currentEdition before:")
			log(self.currentEdition.toString())
			self.currentEdition = self.currentEdition + UInt64(1)
			log("currentEdition after:")
			log(self.currentEdition.toString())
			self.updateDicOnFirstMint(uuid: uuid, serial: serial, holder: holder)
			recipient.deposit(token: <-creation)
		}
		
		init(name: String, description: String, thumbnail: String, prices:{ String: FT}?, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, essenceExternalURL: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, limitedEdition: UInt64, licenseIdentifier: String, metadata:{ String: AnyStruct}, verifiers:{ String: [{Mindtrix.IVerifier}]}){ 
			royalties.append(MetadataViews.Royalty(receiver: Mindtrix.MindtrixDaoTreasuryRef, cut: 0.05, description: "Mindtrix DAO Treasury"))
			log("create essence royalties:")
			log(royalties)
			// 該 essence 一開始是 0 個
			self.minters ={} 
			self.currentHolders ={} 
			self.currentEdition = 0
			self.id = self.uuid
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.showGuid = showGuid
			self.episodeGuid = episodeGuid
			self.prices = prices
			self.ipfsCid = ipfsCid
			self.ipfsDirectory = ipfsDirectory
			self.royalties = royalties
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionExternalURL = collectionExternalURL
			self.collectionSquareImageUrl = collectionSquareImageUrl
			self.collectionSquareImageType = collectionSquareImageType
			self.collectionSocials = collectionSocials
			self.essenceExternalURL = essenceExternalURL
			self.firstSerial = firstSerial
			self.secondSerial = secondSerial
			self.thirdSerial = thirdSerial
			self.fourthSerial = fourthSerial
			self.fifthSerial = fifthSerial
			self.limitedEdition = limitedEdition
			self.licenseIdentifier = licenseIdentifier
			self.metadata = metadata
			self.verifiers = verifiers
			self.createdTime = getCurrentBlock().timestamp
		}
	}
	
	// TODO: Add BrandCollection
	// EssenceCollection owns by each creator
	access(all)
	resource EssenceCollection{ 
		access(all)
		fun batchCreateEssence(names: [String], descriptions: [String], thumbnails: [String], prices: [{String: FT}?], ipfsCids: [String], ipfsDirectories: [String], royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, offChainedIds: [String], collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, essenceExternalURLs: [String], licenseIdentifiers: [String], firstSerials: [UInt16], secondSerials: [UInt16], thirdSerials: [UInt16], fourthSerials: [UInt32], fifthSerials: [UInt16], limitedEditions: [UInt64], metadatas: [{String: AnyStruct}], verifiers: [[{IVerifier}]]){ 
			var i: UInt64 = 0
			let len = UInt64(names.length)
			log("batchCreateEssence len:".concat(len.toString()))
			let verifierLen = UInt64(verifiers.length)
			while i < len{ 
				var verifier: [{IVerifier}] = []
				if verifierLen > i{ 
					verifier = verifiers[i]
				}
				self.createEssence(name: names[i], description: descriptions[i], thumbnail: thumbnails[i], prices: prices[i], ipfsCid: ipfsCids[i], ipfsDirectory: ipfsDirectories[i], royalties: royalties, showGuid: showGuid, episodeGuid: episodeGuid, offChainedId: offChainedIds[i], collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, essenceExternalURL: essenceExternalURLs[i], licenseIdentifier: licenseIdentifiers[i], firstSerial: firstSerials[i], secondSerial: secondSerials[i], thirdSerial: thirdSerials[i], fourthSerial: fourthSerials[i], fifthSerial: fifthSerials[i], limitedEdition: limitedEditions[i], metadata: metadatas[i], verifiers: verifier)
				i = i + UInt64(1)
			}
		}
		
		access(all)
		fun createEssence(name: String, description: String, thumbnail: String, prices:{ String: FT}?, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, offChainedId: String, collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, essenceExternalURL: String, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, limitedEdition: UInt64, metadata:{ String: AnyStruct}, verifiers: [{IVerifier}]): UInt64{ 
			let currentBlock = getCurrentBlock()
			metadata["createdBlock"] = currentBlock.height
			metadata["createdTime"] = currentBlock.timestamp
			let typeToVerifier:{ String: [{IVerifier}]} ={} 
			for verifier in verifiers{ 
				let identifier = verifier.getType().identifier
				if typeToVerifier[identifier] == nil{ 
					typeToVerifier[identifier] = [verifier]
				} else{ 
					(typeToVerifier[identifier]!).append(verifier)
				}
			}
			let essence <- create Essence(name: name, description: description, thumbnail: thumbnail, prices: prices, ipfsCid: ipfsCid, ipfsDirectory: ipfsDirectory, royalties: royalties, showGuid: showGuid, episodeGuid: episodeGuid, collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, essenceExternalURL: essenceExternalURL, firstSerial: firstSerial, secondSerial: secondSerial, thirdSerial: thirdSerial, fourthSerial: fourthSerial, fifthSerial: fifthSerial, limitedEdition: limitedEdition, licenseIdentifier: licenseIdentifier, metadata: metadata, verifiers: typeToVerifier)
			let essenceId = essence.id
			Mindtrix.essenceDic[essenceId] <-! essence
			var essenceObj:{ UInt64: Bool} ={} 
			essenceObj[essenceId] = true
			Mindtrix.showGuidToEssenceIds[showGuid] = essenceObj
			log("created essenceId:".concat(essenceId.toString()))
			let audioEssence = metadata["audioEssence"] as? AudioEssence
			let audioStartTime = audioEssence?.startTime ?? 0.0
			let audioEndTime = audioEssence?.endTime ?? 0.0
			let fullEpisodeDuration = audioEssence?.fullEpisodeDuration ?? 0.0
			emit AudioEssenceCreated(offChainedId: offChainedId, essenceId: essenceId, essenceName: name, essenceDescription: description, showGuid: showGuid, episodeGuid: episodeGuid, audioStartTime: audioStartTime, audioEndTime: audioEndTime, fullEpisodeDuration: fullEpisodeDuration, externalURL: collectionExternalURL)
			return essenceId
		}
		
		init(){} 
	}
	
	access(all)
	resource interface MindtrixCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMindtrix(id: UInt64): &Mindtrix.NFT{ 
			post{ 
				result == nil || result.id == id:
					"Cannot borrow Mindtrix reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	// The Collection that stores all of the users' Mindtrix NFT
	access(all)
	resource Collection: MindtrixCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(account)
		let essenceToNFTId: EssenceToNFTId
		
		init(){ 
			self.ownedNFTs <-{} 
			self.essenceToNFTId = EssenceToNFTId()
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			// let collectionId = nft.collectionId
			
			// self.essenceToNFTId.addNFT(collectionId: collectionId, nftId: id)
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowMindtrix(id: UInt64): &Mindtrix.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &Mindtrix.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let Mindtrix = nft as! &Mindtrix.NFT
			return Mindtrix as &{ViewResolver.Resolver}
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64, editionQuantity: UInt64, audioEssence: AudioEssence, metadata:{ String: AnyStruct}){ 
			let currentBlock = getCurrentBlock()
			// general metadata that every NFT would include
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			// only exist in audioEssence
			metadata["audioEssence"] = audioEssence
			
			// create a new NFT
			var newNFT <- create NFT(									 // 0 means the NFT did not be minted from a Essence Resource
									 essenceId: 0, name: name, description: description, thumbnail: thumbnail, ipfsCid: ipfsCid, ipfsDirectory: ipfsDirectory, royalties: royalties, showGuid: showGuid, episodeGuid: episodeGuid, collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, licenseIdentifier: licenseIdentifier, firstSerial: firstSerial, secondSerial: secondSerial, thirdSerial: thirdSerial, fourthSerial: fourthSerial, fifthSerial: fifthSerial, editionNumber: editionNumber, editionQuantity: editionQuantity, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
		
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], showGuid: String, episodeGuid: String, collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionQuantity: UInt64, audioEssence: AudioEssence, metadata:{ String: AnyStruct}){ 
			var i: UInt64 = 0
			while i < editionQuantity{ 
				// we'll put most params into structs to cut down the numbers of params in the next stage
				self.mintNFT(recipient: recipient, name: name, description: description, thumbnail: thumbnail, ipfsCid: ipfsCid, ipfsDirectory: ipfsDirectory, royalties: royalties, showGuid: showGuid, episodeGuid: episodeGuid, collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, licenseIdentifier: licenseIdentifier, firstSerial: firstSerial, secondSerial: secondSerial, thirdSerial: thirdSerial, fourthSerial: fourthSerial, fifthSerial: fifthSerial, editionNumber: UInt64(i), editionQuantity: editionQuantity, audioEssence: audioEssence, metadata: metadata)
				i = i + UInt64(1)
			}
		}
	}
	
	// ========================================================
	//						 FUNCTION
	// ========================================================
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createEmptyEssenceCollection(): @EssenceCollection{ 
		return <-create EssenceCollection()
	}
	
	// fetch essence
	// TODO: access(account) fun removeEssence()
	access(all)
	fun getAllEssenceIds(): [UInt64]{ 
		return Mindtrix.essenceDic.keys
	}
	
	access(all)
	fun getEssencesByShowGuid(showGuid: String):{ UInt64: Bool}{ 
		return Mindtrix.showGuidToEssenceIds[showGuid]!
	}
	
	access(all)
	fun getOneEssence(essenceId: UInt64): &Essence{ 
		return (&Mindtrix.essenceDic[essenceId] as &Essence?)!
	}
	
	access(all)
	fun borrowEssenceViewResolver(id: UInt64): &{ViewResolver.Resolver}{ 
		let essence = (&Mindtrix.essenceDic[id] as &Mindtrix.Essence?)!
		return essence as &{ViewResolver.Resolver}
	}
	
	// helper functions
	access(all)
	fun getSerialNumber(firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64): UInt64{ 
		assert(firstSerial <= 18, message: "The first serial number should not be over 18 because the serial is an UInt64 number.")
		let fullSerial = UInt64(firstSerial) * 1000000000000000000 + UInt64(secondSerial) * 10000000000000000 + UInt64(thirdSerial) * 10000000000000 + UInt64(fourthSerial) * 100000000 + UInt64(fifthSerial) * 100000 + UInt64(editionNumber)
		return fullSerial
	}
	
	access(all)
	fun getSerialGenus(firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64): [Mindtrix.SerialGenus]{ 
		let first = Mindtrix.SerialGenus(tier: 1, number: firstSerial, name: "nftRealm", description: "e.g. the Podcast, Literature, or Video")
		let second = Mindtrix.SerialGenus(tier: 2, number: secondSerial, name: "nftEnum", description: "e.g. the Audio, Image, or Quest in a Podcast Show")
		let third = Mindtrix.SerialGenus(tier: 3, number: thirdSerial, name: "nftFirstSet", description: "e.g. the 2nd podcast show of a creator")
		let fourth = Mindtrix.SerialGenus(tier: 4, number: fourthSerial, name: "nftSecondSet", description: "e.g. the 18th episode of a podcast show")
		let fifth = Mindtrix.SerialGenus(tier: 5, number: fifthSerial, name: "nftThirdSet", description: "e.g. the 10th essence of an episode")
		let sixth = Mindtrix.SerialGenus(tier: 6, number: editionNumber, name: "nftEdtionNumber", description: "e.g. the 100th edition of a essence")
		let genusList: [Mindtrix.SerialGenus] = [first, second, third, fourth, fifth, sixth]
		return genusList
	}
	
	// ========================================================
	//					   CONTRACT INIT
	// ========================================================
	init(){ 
		self.totalSupply = 0
		self.essenceDic <-{} 
		self.showGuidToEssenceIds ={} 
		self.essenceIdsToCreationIds ={} 
		self.AdminAddress = self.account.address
		let royaltyReceiverPublicPath: PublicPath = /public/flowTokenReceiver
		self.MindtrixDaoTreasuryRef = self.account.capabilities.get<&{FungibleToken.Receiver}>(royaltyReceiverPublicPath)!
		self.RoyaltyReceiverPublicPath = /public/flowTokenReceiver
		// TODO: should change to MindtrixCollectionStoragePath
		self.CollectionStoragePath = /storage/MindtrixCollection
		// TODO: should change to MindtrixCollectionPublicPath
		self.CollectionPublicPath = /public/MindtrixCollection
		self.MindtrixEssenceCollectionStoragePath = /storage/MindtrixEssenceCollectionStoragePath
		self.MindtrixEssenceCollectionPublicPath = /public/MindtrixEssenceCollectionPublicPath
		self.MinterStoragePath = /storage/MindtrixMinter
		self.account.storage.save(<-Mindtrix.createEmptyCollection(nftType: Type<@Mindtrix.Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Mindtrix.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
