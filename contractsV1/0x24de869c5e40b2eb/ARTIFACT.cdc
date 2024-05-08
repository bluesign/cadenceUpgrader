// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import ARTIFACTViews from "./ARTIFACTViews.cdc"

access(all)
contract ARTIFACT: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// ARTIFACT contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The total supply that is used to create NFT. 
	// Every time a NFT is created,  
	// totalSupply is incremented by 1 and then is assigned to NFT's ID.
	access(all)
	var totalSupply: UInt64
	
	// The next template ID that is used to create Template. 
	// Every time a Template is created, nextTemplateId is assigned 
	// to the new Template's ID and then is incremented by 1.
	access(all)
	var nextTemplateId: UInt64
	
	// The next NFT ID that is used to create NFT. 
	// Every time a NFT is created, nextNFTId is assigned 
	// to the new NFT's ID and then is incremented by 1.
	access(all)
	var nextNFTId: UInt64
	
	// Variable size dictionary of Template structs
	access(account)
	var templateDatas:{ UInt64: Template}
	
	// Variable size dictionary of minted templates structs
	access(account)
	var numberMintedByTemplate:{ UInt64: UInt64}
	
	/// Path where the public capability for the `Collection` is available
	access(all)
	let collectionPublicPath: PublicPath
	
	/// Path where the `Collection` is stored
	access(all)
	let collectionStoragePath: StoragePath
	
	/// Path where the private capability for the `Collection` is available
	access(all)
	let collectionPrivatePath: PrivatePath
	
	/// Event used on create template
	access(all)
	event TemplateCreated(templateId: UInt64, databaseID: String)
	
	/// Event used on destroy NFT from collection
	access(all)
	event NFTDestroyed(nftId: UInt64)
	
	/// Event used on withdraw NFT from collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// Event used on deposit NFT to collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Event used on mint NFT
	access(all)
	event NFTMinted(nftId: UInt64, edition: UInt64, packID: UInt64, templateId: UInt64, owner: Address)
	
	/// Event used on contract initiation
	access(all)
	event ContractInitialized()
	
	// -----------------------------------------------------------------------
	// ARTIFACT contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	// Template is a Struct that holds metadata associated with a specific 
	// nft
	//
	// NFT resource will all reference a single template as the owner of
	// its metadata. The templates are publicly accessible, so anyone can
	// read the metadata associated with a specific NFT ID
	//
	access(all)
	struct Template{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let maxEditions: UInt64
		
		access(all)
		let creationDate: UInt64
		
		access(all)
		let rarity: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}, maxEditions: UInt64, creationDate: UInt64, rarity: UInt64, databaseID: String){ 
			pre{ 
				metadata.length != 0:
					"metadata cannot be empty"
				maxEditions != 0:
					"maxEditions cannot be 0"
				rarity != 0:
					"rarity cannot be 0"
			}
			self.templateId = ARTIFACT.nextTemplateId
			self.metadata = metadata
			self.maxEditions = maxEditions
			self.creationDate = creationDate
			self.rarity = rarity
			ARTIFACT.nextTemplateId = ARTIFACT.nextTemplateId + UInt64(1)
			emit TemplateCreated(templateId: self.templateId, databaseID: databaseID)
		}
	}
	
	// NFTData is a Struct that holds template's ID, metadata, 
	// edition number and rarity field
	//
	access(all)
	struct NFTData{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let rarity: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}, templateId: UInt64, edition: UInt64, rarity: UInt64, packID: UInt64){ 
			self.templateId = templateId
			self.metadata = metadata
			self.edition = edition
			self.rarity = rarity
			self.packID = packID
		}
	}
	
	// The resource that represents the NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: NFTData
		
		init(edition: UInt64, metadata:{ String: String}, templateId: UInt64, rarity: UInt64, packID: UInt64, owner: Address){ 
			self.id = ARTIFACT.nextNFTId
			metadata["artifactIdentifier"] = self.id.toString()
			metadata["artifactEditionNumber"] = edition.toString()
			metadata["artifactMintTimestamp"] = getCurrentBlock().timestamp.toString()
			self.data = NFTData(metadata: metadata, templateId: templateId, edition: edition, rarity: rarity, packID: packID)
			emit NFTMinted(nftId: self.id, edition: self.data.edition, packID: self.data.packID, templateId: templateId, owner: owner)
			ARTIFACT.nextNFTId = ARTIFACT.nextNFTId + UInt64(1)
			ARTIFACT.totalSupply = ARTIFACT.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<ARTIFACTViews.ArtifactsDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let artifactFileUri = self.data.metadata["artifactFileUri"]!
			let artifactFileUriFormatted = artifactFileUri.slice(from: 7, upTo: artifactFileUri.length - 1)
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.data.metadata["artifactName"]!, description: self.data.metadata["artifactShortDescription"]!, thumbnail: MetadataViews.IPFSFile(cid: artifactFileUriFormatted, path: nil))
				case Type<ARTIFACTViews.ArtifactsDisplay>():
					return ARTIFACTViews.ArtifactsDisplay(name: self.data.metadata["artifactName"]!, description: self.data.metadata["artifactShortDescription"]!, thumbnail: MetadataViews.IPFSFile(cid: artifactFileUriFormatted, path: nil), metadata: self.data.metadata)
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
		fun borrow(id: UInt64): &ARTIFACT.NFT?
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of NFTs conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an ARTIFACT from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: ARTIFACT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		// deposit takes a ARTIFACT and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
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
		
		// borrow Returns a borrowed reference to a ARTIFACT in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		access(all)
		fun borrow(id: UInt64): &ARTIFACT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ARTIFACT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let artifactsNFT = nft as! &NFT
			return artifactsNFT as &{MetadataViews.Resolver}
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
	// ARTIFACT contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new Collection a user can store 
	// it in their account storage.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ARTIFACT.Collection()
	}
	
	// getAllTemplates get all templates stored in the contract
	//
	access(all)
	fun getAllTemplates(): [Template]{ 
		return ARTIFACT.templateDatas.values
	}
	
	// getTemplate get a specific templates stored in the contract by id
	//
	access(all)
	fun getTemplate(templateId: UInt64): Template?{ 
		return ARTIFACT.templateDatas[templateId]
	}
	
	// getNumberMintedByTemplate get number nft minted by template
	//
	access(all)
	fun getNumberMintedByTemplate(templateId: UInt64): UInt64?{ 
		return ARTIFACT.numberMintedByTemplate[templateId]
	}
	
	// createNFT create a NFT used by ARTIFACTAdmin
	//
	access(account)
	fun createNFT(templateId: UInt64, packID: UInt64, owner: Address): @NFT{ 
		var template = ARTIFACT.templateDatas[templateId]!
		let edition = ARTIFACT.numberMintedByTemplate[templateId]!
		ARTIFACT.numberMintedByTemplate[templateId] = ARTIFACT.numberMintedByTemplate[templateId]! + 1
		return <-create NFT(edition: edition, metadata: (template!).metadata, templateId: templateId, rarity: (template!).rarity, packID: packID, owner: owner)
	}
	
	// createTemplate create a NFT template used by ARTIFACTAdmin
	//
	access(account)
	fun createTemplate(metadata:{ String: String}, maxEditions: UInt64, creationDate: UInt64, rarity: UInt64, databaseID: String): Template{ 
		var newTemplate = Template(metadata: metadata, maxEditions: maxEditions, creationDate: creationDate, rarity: rarity, databaseID: databaseID)
		ARTIFACT.numberMintedByTemplate[newTemplate.templateId] = 0
		ARTIFACT.templateDatas[newTemplate.templateId] = newTemplate
		return newTemplate
	}
	
	init(){ 
		// Paths
		self.collectionPublicPath = /public/ARTIFACTCollection
		self.collectionStoragePath = /storage/ARTIFACTCollection
		self.collectionPrivatePath = /private/ARTIFACTCollection
		self.nextTemplateId = 1
		self.nextNFTId = 1
		self.totalSupply = 0
		self.templateDatas ={} 
		self.numberMintedByTemplate ={} 
		emit ContractInitialized()
	}
}
