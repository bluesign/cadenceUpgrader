// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import Interfaces from "./Interfaces.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ARTIFACTViews from "./ARTIFACTViews.cdc"

import ARTIFACTV2 from "./ARTIFACTV2.cdc"

access(all)
contract ARTIFACTPackV3: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// ARTIFACTPackV3 contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The total supply that is used to create NFT. 
	// Every time a NFT is created,  
	// totalSupply is incremented by 1 and then is assigned to NFT's ID.
	access(all)
	var totalSupply: UInt64
	
	// The next pack template ID that is used to create PackTemplate. 
	// Every time a PackTemplate is created, nextTemplateId is assigned 
	// to the new PackTemplate's ID and then is incremented by 1.
	access(all)
	var nextTemplateId: UInt64
	
	// The next PACK ID that is used to create pack. 
	// Every time a Pack is created, nextPackId is assigned 
	// to the new Pack's ID and then is incremented by 1.
	access(all)
	var nextPackId: UInt64
	
	// Variable size dictionary of PackTemplate structs
	access(account)
	var templateDatas:{ UInt64: PackTemplate}
	
	// Variable size dictionary of PackTemplate structs
	access(account)
	var packOptionsByTemplateId:{ UInt64: [PackOption]}
	
	// Variable size dictionary of minted packs
	access(account)
	var numberMintedByPack:{ UInt64: UInt64}
	
	/// Path where the public capability for the `Collection` is available
	access(all)
	let collectionPublicPath: PublicPath
	
	/// Path where the `Collection` is stored
	access(all)
	let collectionStoragePath: StoragePath
	
	/// Event used on destroy Pack NFT from collection
	access(all)
	event NFTDestroyed(nftId: UInt64)
	
	/// Event used on withdraw Pack NFT from collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// Event used on deposit Pack NFT to collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Event used on contract initiation
	access(all)
	event ContractInitialized()
	
	/// Event used on mint Pack
	access(all)
	event PackMinted(packId: UInt64, owner: Address, listingID: UInt64, edition: UInt64)
	
	/// Event used on create template
	access(all)
	event PackTemplateCreated(templateId: UInt64, totalSupply: UInt64)
	
	/// Event used on open Pack
	access(all)
	event OpenPack(owner: Address, packId: UInt64, options: [String], nftIds: [UInt64])
	
	// -----------------------------------------------------------------------
	// ARTIFACTPackV3 contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	/// Tarnishment used on Pack
	access(all)
	enum Tarnishment: UInt8{ 
		access(all)
		case good
		
		access(all)
		case great
		
		access(all)
		case bad
	}
	
	// PackOption is a struct that holds the offchain identifier to the template ID/metadata
	access(all)
	struct PackOption: Interfaces.IPackOption{ 
		access(all)
		let options: [String]
		
		access(all)
		let hash:{ Interfaces.IHashMetadata}
		
		init(options: [String], hash:{ Interfaces.IHashMetadata}){ 
			self.options = options
			self.hash = hash
		}
	}
	
	// PackTemplate is a Struct that holds metadata associated with a specific 
	// pack nft
	//
	// Pack NFT resource will all reference a single template as the owner of
	// its metadata. The templates are publicly accessible, so anyone can
	// read the metadata associated with a specific Pack NFT ID
	//
	access(all)
	struct PackTemplate: Interfaces.IPackTemplate{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let totalSupply: UInt64
		
		access(all)
		let maxQuantityPerTransaction: UInt64
		
		access(all)
		var lockStatus: Bool
		
		init(metadata:{ String: String}, totalSupply: UInt64, maxQuantityPerTransaction: UInt64){ 
			self.templateId = ARTIFACTPackV3.nextTemplateId
			self.metadata = metadata
			self.totalSupply = totalSupply
			self.maxQuantityPerTransaction = maxQuantityPerTransaction
			self.lockStatus = true
			emit PackTemplateCreated(templateId: self.templateId, totalSupply: self.totalSupply)
			ARTIFACTPackV3.nextTemplateId = ARTIFACTPackV3.nextTemplateId + UInt64(1)
		}
		
		access(all)
		fun updateLockStatus(lockStatus: Bool){ 
			self.lockStatus = lockStatus
		}
		
		access(all)
		fun removeIndex(indexPackAvailable: UInt64){ 
			(ARTIFACTPackV3.packOptionsByTemplateId[self.templateId]!).remove(at: indexPackAvailable)
		}
	}
	
	// The resource that represents the Pack
	//
	access(all)
	resource NFT: Interfaces.IPack, NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		var isOpen: Bool
		
		access(all)
		let templateId: UInt64
		
		access(all)
		var tarnishment: Tarnishment?
		
		access(all)
		var packOption: PackOption?
		
		access(all)
		let adminRef: Capability<&{Interfaces.ARTIFACTAdminOpener}>
		
		access(account)
		let metadata:{ String: String}
		
		access(account)
		let royalties: [MetadataViews.Royalty]
		
		init(packTemplate:{ Interfaces.IPackTemplate}, adminRef: Capability<&{Interfaces.ARTIFACTAdminOpener}>, owner: Address, listingID: UInt64, edition: UInt64, royalties: [MetadataViews.Royalty]){ 
			self.id = ARTIFACTPackV3.nextPackId
			self.edition = edition
			self.adminRef = adminRef
			self.tarnishment = nil
			self.isOpen = false
			self.metadata = packTemplate.metadata
			self.templateId = packTemplate.templateId
			self.royalties = royalties
			self.packOption = nil
			emit PackMinted(packId: self.id, owner: owner, listingID: listingID, edition: edition)
			ARTIFACTPackV3.nextPackId = ARTIFACTPackV3.nextPackId + UInt64(1)
			ARTIFACTPackV3.totalSupply = ARTIFACTPackV3.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<ARTIFACTViews.ArtifactsDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var mediaUri = ""
			var description = ""
			if self.isOpen{ 
				description = self.metadata["descriptionOpened"]!
				mediaUri = self.metadata["fileUriOpened"]!
			} else{ 
				description = self.metadata["descriptionUnopened"]!
				mediaUri = self.metadata["fileUriUnopened"]!
			}
			let fileUri = mediaUri.slice(from: 7, upTo: mediaUri.length - 1)
			var title = self.metadata["name"]!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: description, thumbnail: MetadataViews.IPFSFile(cid: fileUri, path: nil))
				case Type<ARTIFACTViews.ArtifactsDisplay>():
					return ARTIFACTViews.ArtifactsDisplay(name: self.metadata["name"]!, description: description, thumbnail: MetadataViews.IPFSFile(cid: fileUri, path: nil), metadata: self.metadata)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ARTIFACTPackV3.collectionStoragePath, publicPath: ARTIFACTPackV3.collectionPublicPath, publicCollection: Type<&ARTIFACTPackV3.Collection>(), publicLinkedType: Type<&ARTIFACTPackV3.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ARTIFACTPackV3.createEmptyCollection(nftType: Type<@ARTIFACTPackV3.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.metadata["collectionFileUri"]!), mediaType: self.metadata["collectionMediaType"]!)
					return MetadataViews.NFTCollectionDisplay(name: self.metadata["collectionName"]!, description: self.metadata["collectionDescription"]!, externalURL: MetadataViews.ExternalURL("https://artifact.scmp.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/artifactsbyscmp"), "discord": MetadataViews.ExternalURL("https://discord.gg/PwbEbFbQZX")})
			}
			return nil
		}
		
		access(all)
		fun open(owner: Address): @[{NonFungibleToken.NFT}]{ 
			pre{ 
				!self.isOpen:
					"User Pack must be closed"
			}
			let userPackRef: &{Interfaces.IPack} = &self as &{Interfaces.IPack}
			let packTemplate = ARTIFACTPackV3.getPackTemplate(templateId: userPackRef.templateId)!
			self.packOption = ARTIFACTPackV3.getTemplateIdsFromPacksAvailable(packTemplate: packTemplate)
			var nfts: @[{NonFungibleToken.NFT}] <- (self.adminRef.borrow()!).openPack(userPack: userPackRef, packID: self.id, owner: owner, royalties: self.royalties, packOption: self.packOption! as{ Interfaces.IPackOption})
			self.isOpen = true
			self.tarnishment = Tarnishment.good
			var nftIds: [UInt64] = []
			var quantity: Int = nfts.length
			var i: Int = 0
			while i < quantity{ 
				nftIds.append(nfts[i].id)
				i = i + 1
			}
			emit OpenPack(owner: owner, packId: self.id, options: (self.packOption!).options, nftIds: nftIds)
			return <-nfts
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
		fun borrow(id: UInt64): &ARTIFACTPackV3.NFT?
	}
	
	// Collection is a resource that every user who owns Pack NFTs 
	// will store in their account to manage their Pack NFTS
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of Pack NFT conforming tokens
		// Pack NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// openPack mint new NFTs from a Pack ID 
		//
		// Paramters: packID: The NFT id to open
		// Paramters: owner: The Pack NFT owner
		// Paramters: collection: The NFTs collection
		//
		access(all)
		fun openPack(packID: UInt64, owner: Address, collection: &{ARTIFACTV2.CollectionPublic}){ 
			let packRef = (&self.ownedNFTs[packID] as &{NonFungibleToken.NFT}?)!
			let pack = packRef as! &NFT
			var nfts: @[{NonFungibleToken.NFT}] <- pack.open(owner: owner)
			var quantity: Int = nfts.length
			var i: Int = 0
			while i < quantity{ 
				collection.deposit(token: <-nfts.removeFirst())
				i = i + 1
			}
			destroy nfts
		}
		
		// withdraw removes an ARTIFACTPackV3 from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: ARTIFACTPackV3 does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		// deposit takes a ARTIFACTPackV3 and adds it to the Collections dictionary
		//
		// Paramters: token: The NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrow Returns a borrowed reference to a ARTIFACTPackV3 in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		access(all)
		fun borrow(id: UInt64): &ARTIFACTPackV3.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ARTIFACTPackV3.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let artifactsPack = nft as! &NFT
			return artifactsPack as &{ViewResolver.Resolver}
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
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	// Much like when Damian Lillard destroys the hopes and
	// dreams of the entire city of Houston.
	//
	}
	
	// -----------------------------------------------------------------------
	// ARTIFACTPackV3 contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new Collection a user can store 
	// it in their account storage.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ARTIFACTPackV3.Collection()
	}
	
	// createPack creates a new Pack NFT used by ARTIFACTAdmin
	//
	access(account)
	fun createPack(packTemplate:{ Interfaces.IPackTemplate}, adminRef: Capability<&{Interfaces.ARTIFACTAdminOpener}>, owner: Address, listingID: UInt64, royalties: [MetadataViews.Royalty]): @NFT{ 
		if ARTIFACTPackV3.numberMintedByPack[packTemplate.templateId] == nil{ 
			ARTIFACTPackV3.numberMintedByPack[packTemplate.templateId] = 0
		}
		let edition = ARTIFACTPackV3.numberMintedByPack[packTemplate.templateId]!
		ARTIFACTPackV3.numberMintedByPack[packTemplate.templateId] = ARTIFACTPackV3.numberMintedByPack[packTemplate.templateId]! + 1
		let userPack <- create NFT(packTemplate: packTemplate, adminRef: adminRef, owner: owner, listingID: listingID, edition: edition, royalties: royalties)
		return <-userPack
	}
	
	// createPackTemplate creates a new Pack NFT template used by ARTIFACTAdmin
	//
	access(account)
	fun createPackTemplate(metadata:{ String: String}, totalSupply: UInt64, maxQuantityPerTransaction: UInt64): PackTemplate{ 
		var newPackTemplate = PackTemplate(metadata: metadata, totalSupply: totalSupply, maxQuantityPerTransaction: maxQuantityPerTransaction)
		ARTIFACTPackV3.templateDatas[newPackTemplate.templateId] = newPackTemplate
		return newPackTemplate
	}
	
	access(account)
	fun checkPackTemplateLockStatus(packTemplateId: UInt64): Bool{ 
		let packTemplate = ARTIFACTPackV3.templateDatas[packTemplateId]!
		return packTemplate.lockStatus
	}
	
	access(account)
	fun updateLockStatus(packTemplateId: UInt64, lockStatus: Bool){ 
		(ARTIFACTPackV3.templateDatas[packTemplateId]!).updateLockStatus(lockStatus: lockStatus)
	}
	
	// getPackTemplate get a specific templates stored in the contract by id
	//
	access(all)
	fun getPackTemplate(templateId: UInt64): PackTemplate?{ 
		return ARTIFACTPackV3.templateDatas[templateId]
	}
	
	// updatePackTemplate update a specific templates stored in the contract by id
	//
	access(account)
	fun updatePackTemplate(packTemplate: PackTemplate){ 
		ARTIFACTPackV3.templateDatas[packTemplate.templateId] = packTemplate
	}
	
	// addPackOptions add pack options in the contract by id
	//
	access(account)
	fun addPackOptions(packTemplateId: UInt64, packsAvailable: [ARTIFACTPackV3.PackOption]){ 
		if ARTIFACTPackV3.packOptionsByTemplateId[packTemplateId] == nil{ 
			ARTIFACTPackV3.packOptionsByTemplateId[packTemplateId] = []
		}
		(ARTIFACTPackV3.packOptionsByTemplateId[packTemplateId]!).appendAll(packsAvailable)
	}
	
	access(account)
	fun getTemplateIdsFromPacksAvailable(packTemplate: ARTIFACTPackV3.PackTemplate): ARTIFACTPackV3.PackOption{ 
		pre{ 
			(ARTIFACTPackV3.packOptionsByTemplateId[packTemplate.templateId]!).length > 0:
				"No pack available"
		}
		let templateIDs = (ARTIFACTPackV3.packOptionsByTemplateId[packTemplate.templateId]!)[0]!
		packTemplate.removeIndex(indexPackAvailable: 0)
		ARTIFACTPackV3.updatePackTemplate(packTemplate: packTemplate)
		return templateIDs
	}
	
	init(){ 
		// Paths
		self.collectionPublicPath = /public/ARTIFACTPackV3Collection
		self.collectionStoragePath = /storage/ARTIFACTPackV3Collection
		self.nextTemplateId = 1
		self.nextPackId = 1
		self.totalSupply = 0
		self.templateDatas ={} 
		self.numberMintedByPack ={} 
		self.packOptionsByTemplateId ={} 
		emit ContractInitialized()
	}
}
