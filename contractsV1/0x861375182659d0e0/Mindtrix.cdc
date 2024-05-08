/*

============================================================
Name: Smart Contract for Mindtrix
Author: AS
Version: 0.1.0
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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

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
	let MinterStoragePath: StoragePath
	
	// ========================================================
	//						  EVENT
	// ========================================================
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// ========================================================
	//					   MUTABLE STATE
	// ========================================================
	access(all)
	var totalSupply: UInt64
	
	// ========================================================
	//					  IMMUTABLE STATE
	// ========================================================
	access(all)
	let AdminAddress: Address
	
	// ========================================================
	//						   ENUM
	// ========================================================
	access(all)
	enum FirstSerial: UInt8{ 
		access(all)
		case voice
	}
	
	access(all)
	enum VoiceSerial: UInt8{ 
		// audio = 0 + 1 = 1 in Serial, 0 is a reserved number
		access(all)
		case audio
		
		// image = 1 + 1 = 2 in Serial
		access(all)
		case image
		
		// quest = 2 + 1 = 3 in Serial
		access(all)
		case quest
	}
	
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
	
	// AudioEssence struct is optional and only exists when an NFT is a VoiceSerial.essence.
	access(all)
	struct AudioEssence{ 
		// e.g. startTime = 96 = 00:01:36
		access(all)
		let startTime: UInt16?
		
		// e.g. endTime = 365 = 00:06:05
		access(all)
		let endTime: UInt16?
		
		// e.g. originalDuration = 1864 = 00:31:04
		access(all)
		let originalDuration: UInt16?
		
		init(startTime: UInt16?, endTime: UInt16?, originalDuration: UInt16?){ 
			self.startTime = startTime
			self.endTime = endTime
			self.originalDuration = originalDuration
		}
	}
	
	access(all)
	struct SerialString{ 
		access(all)
		let str: String
		
		init(str: String){ 
			self.str = str
		}
	}
	
	// ========================================================
	//			   COMPOSITE TYPES: RESOURCE
	// ========================================================
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
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
		
		access(account)
		var extraMetadata:{ String: AnyStruct}
		
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
		
		init(id: UInt64, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64, editionQuantity: UInt64, extraMetadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.ipfsCid = ipfsCid
			self.ipfsDirectory = ipfsDirectory
			self.royalties = royalties
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
			self.extraMetadata = extraMetadata
		}
		
		access(all)
		fun updateMetadata(newExtraMetadata:{ String: AnyStruct}){ 
			for key in newExtraMetadata.keys{ 
				if !self.extraMetadata.containsKey(key){ 
					self.extraMetadata[key] = newExtraMetadata[key]
				}
			}
		}
		
		access(all)
		fun getExtraMetadata():{ String: AnyStruct}{ 
			return self.extraMetadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.License>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<Mindtrix.SerialString>(), Type<Mindtrix.SerialGenuses>(), Type<Mindtrix.AudioEssence>()]
		}
		
		access(all)
		fun getSerialNumber(): UInt64{ 
			assert(self.firstSerial <= 18, message: "The first serial number should not be over 18 because the serial is an UInt64 number.")
			let fullSerial = UInt64(self.firstSerial) * 1000000000000000000 + UInt64(self.secondSerial) * 10000000000000000 + UInt64(self.thirdSerial) * 10000000000000 + UInt64(self.fourthSerial) * 100000000 + UInt64(self.fifthSerial) * 100000 + UInt64(self.editionNumber)
			return fullSerial
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
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
					let first = Mindtrix.SerialGenus(tier: 1, number: self.firstSerial, name: "nftRealm", description: "e.g. the Podcast, Literature, or Video")
					let second = Mindtrix.SerialGenus(tier: 2, number: self.secondSerial, name: "nftEnum", description: "e.g. the Audio, Image, or Quest in a Podcast Show")
					let third = Mindtrix.SerialGenus(tier: 3, number: self.thirdSerial, name: "nftFirstSet", description: "e.g. the 2nd podcast show of a creator")
					let fourth = Mindtrix.SerialGenus(tier: 4, number: self.fourthSerial, name: "nftSecondSet", description: "e.g. the 18th episode of a podcast show")
					let fifth = Mindtrix.SerialGenus(tier: 5, number: self.fifthSerial, name: "nftThirdSet", description: "e.g. the 10th essence of an episode")
					let sixth = Mindtrix.SerialGenus(tier: 6, number: self.editionNumber, name: "nftEdtionNumber", description: "e.g. the 100th edition of a essence")
					let genusList: [Mindtrix.SerialGenus] = [first, second, third, fourth, fifth, sixth]
					return genusList
				case Type<Mindtrix.AudioEssence>():
					let audioEssenceStartTime = self.extraMetadata["audioEssenceStartTime"] as? UInt16
					let audioEssenceEndTime = self.extraMetadata["audioEssenceEndTime"] as? UInt16
					let audioEssenceOriginalTime = self.extraMetadata["audioEssenceOriginalTime"] as? UInt16
					return Mindtrix.AudioEssence(startTime: audioEssenceStartTime, endTime: audioEssenceEndTime, originalDuration: audioEssenceOriginalTime)
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
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
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
		fun borrowMindtrix(id: UInt64): &Mindtrix.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Mindtrix reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MindtrixCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
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
			let token <- token as! @Mindtrix.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
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
		fun borrowMindtrix(id: UInt64): &Mindtrix.NFT?{ 
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionNumber: UInt64, editionQuantity: UInt64, extraMetadata:{ String: AnyStruct}){ 
			
			// create a new NFT
			var newNFT <- create NFT(id: Mindtrix.totalSupply, name: name, description: description, thumbnail: thumbnail, ipfsCid: ipfsCid, ipfsDirectory: ipfsDirectory, royalties: royalties, collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, licenseIdentifier: licenseIdentifier, firstSerial: firstSerial, secondSerial: secondSerial, thirdSerial: thirdSerial, fourthSerial: fourthSerial, fifthSerial: fifthSerial, editionNumber: editionNumber, editionQuantity: editionQuantity, extraMetadata: extraMetadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Mindtrix.totalSupply = Mindtrix.totalSupply + UInt64(1)
		}
		
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, ipfsCid: String, ipfsDirectory: String, royalties: [MetadataViews.Royalty], collectionName: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImageUrl: String, collectionSquareImageType: String, collectionSocials:{ String: String}, licenseIdentifier: String, firstSerial: UInt16, secondSerial: UInt16, thirdSerial: UInt16, fourthSerial: UInt32, fifthSerial: UInt16, editionQuantity: UInt64, extraMetadata:{ String: AnyStruct}){ 
			var i: UInt64 = 0
			while i < editionQuantity{ 
				self.mintNFT(recipient: recipient, name: name, description: description, thumbnail: thumbnail, ipfsCid: ipfsCid, ipfsDirectory: ipfsDirectory, royalties: royalties, collectionName: collectionName, collectionDescription: collectionDescription, collectionExternalURL: collectionExternalURL, collectionSquareImageUrl: collectionSquareImageUrl, collectionSquareImageType: collectionSquareImageType, collectionSocials: collectionSocials, licenseIdentifier: licenseIdentifier, firstSerial: firstSerial, secondSerial: secondSerial, thirdSerial: thirdSerial, fourthSerial: fourthSerial, fifthSerial: fifthSerial, editionNumber: UInt64(i), editionQuantity: editionQuantity, extraMetadata: extraMetadata)
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
	
	// ========================================================
	//					   CONTRACT INIT
	// ========================================================
	init(){ 
		self.totalSupply = 0
		self.AdminAddress = self.account.address
		self.RoyaltyReceiverPublicPath = /public/flowTokenReceiver
		self.CollectionStoragePath = /storage/MindtrixCollection
		self.CollectionPublicPath = /public/MindtrixCollection
		self.MinterStoragePath = /storage/MindtrixMinter
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Mindtrix.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
