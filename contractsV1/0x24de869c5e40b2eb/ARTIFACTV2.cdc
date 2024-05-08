// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import ARTIFACTViews, Interfaces from 0x24de869c5e40b2eb

access(all)
contract ARTIFACTV2: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// ARTIFACTV2 contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The total supply that is used to create NFT. 
	// Every time a NFT is created,  
	// totalSupply is incremented by 1 and then is assigned to NFT's ID.
	access(all)
	var totalSupply: UInt64
	
	// The next NFT ID that is used to create NFT. 
	// Every time a NFT is created, nextNFTId is assigned 
	// to the new NFT's ID and then is incremented by 1.
	access(all)
	var nextNFTId: UInt64
	
	/// Path where the public capability for the `Collection` is available
	access(all)
	let collectionPublicPath: PublicPath
	
	/// Path where the `Collection` is stored
	access(all)
	let collectionStoragePath: StoragePath
	
	/// Path where the private capability for the `Collection` is available
	access(all)
	let collectionPrivatePath: PrivatePath
	
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
	event NFTMinted(nftId: UInt64, packID: UInt64, templateOffChainId: String, owner: Address)
	
	/// Event used on mint NFT
	access(all)
	event NFTRevealed(templateOffChainId: String)
	
	/// Event used on contract initiation
	access(all)
	event ContractInitialized()
	
	// -----------------------------------------------------------------------
	// ARTIFACTV2 contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	access(all)
	struct HashMetadata: Interfaces.IHashMetadata{ 
		access(all)
		let hash: String
		
		access(all)
		let start: UInt64
		
		access(all)
		let end: UInt64
		
		init(hash: String, start: UInt64, end: UInt64){ 
			self.hash = hash
			self.start = start
			self.end = end
		}
	}
	
	// NFTData is a Struct that holds template's ID, metadata, 
	// edition number and rarity field
	//
	access(all)
	struct NFTData{ 
		access(all)
		let templateOffChainId: String
		
		access(all)
		var edition: UInt64
		
		access(all)
		var rarity: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		let hashMetadata: HashMetadata
		
		access(account)
		var metadata:{ String: String}
		
		access(account)
		let royalties: [MetadataViews.Royalty]
		
		init(templateOffChainId: String, packID: UInt64, royalties: [MetadataViews.Royalty], hashMetadata: HashMetadata){ 
			self.templateOffChainId = templateOffChainId
			self.packID = packID
			self.royalties = royalties
			self.hashMetadata = hashMetadata
			self.metadata ={} 
			self.edition = 0
			self.rarity = 0
		}
		
		access(account)
		fun reveal(metadata:{ String: String}, edition: UInt64, rarity: UInt64){ 
			self.metadata = metadata
			self.edition = edition
			self.rarity = rarity
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
		
		init(templateId: String, packID: UInt64, owner: Address, royalties: [MetadataViews.Royalty], hashMetadata: HashMetadata){ 
			self.id = ARTIFACTV2.nextNFTId
			self.data = NFTData(templateOffChainId: templateId, packID: packID, royalties: royalties, hashMetadata: hashMetadata)
			emit NFTMinted(nftId: self.id, packID: self.data.packID, templateOffChainId: templateId, owner: owner)
			ARTIFACTV2.nextNFTId = ARTIFACTV2.nextNFTId + UInt64(1)
			ARTIFACTV2.totalSupply = ARTIFACTV2.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<ARTIFACTViews.ArtifactsDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
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
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.data.royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ARTIFACTV2.collectionStoragePath, publicPath: ARTIFACTV2.collectionPublicPath, publicCollection: Type<&ARTIFACTV2.Collection>(), publicLinkedType: Type<&ARTIFACTV2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ARTIFACTV2.createEmptyCollection(nftType: Type<@ARTIFACTV2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.data.metadata["collectionFileUri"]!), mediaType: self.data.metadata["collectionMediaType"]!)
					return MetadataViews.NFTCollectionDisplay(name: self.data.metadata["collectionName"]!, description: self.data.metadata["collectionDescription"]!, externalURL: MetadataViews.ExternalURL("https://artifact.scmp.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/artifactsbyscmp"), "discord": MetadataViews.ExternalURL("https://discord.gg/PwbEbFbQZX")})
			}
			return nil
		}
		
		access(account)
		fun reveal(metadata:{ String: String}, edition: UInt64, rarity: UInt64){ 
			metadata["artifactIdentifier"] = self.id.toString()
			metadata["artifactEditionNumber"] = edition.toString()
			self.data.reveal(metadata: metadata, edition: edition, rarity: rarity)
			emit NFTRevealed(templateOffChainId: self.data.templateOffChainId)
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
		fun borrow(id: UInt64): &ARTIFACTV2.NFT?
	}
	
	access(all)
	resource interface IRevealNFT{ 
		access(account)
		fun revealNFT(id: UInt64, metadata:{ String: String}, edition: UInt64, rarity: UInt64)
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection, IRevealNFT{ 
		// Dictionary of NFTs conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an ARTIFACTV2 from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: ARTIFACTV2 does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		// deposit takes a ARTIFACTV2 and adds it to the Collections dictionary
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
		
		// borrow Returns a borrowed reference to a ARTIFACTV2 in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		access(all)
		fun borrow(id: UInt64): &ARTIFACTV2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ARTIFACTV2.NFT
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
		
		access(account)
		fun revealNFT(id: UInt64, metadata:{ String: String}, edition: UInt64, rarity: UInt64){ 
			if self.ownedNFTs[id] != nil{ 
				let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let artifactNFT = nft as! &NFT
				artifactNFT.reveal(metadata: metadata, edition: edition, rarity: rarity)
			} else{ 
				panic("can't find nft id")
			}
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
	// ARTIFACTV2 contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new Collection a user can store 
	// it in their account storage.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ARTIFACTV2.Collection()
	}
	
	// createNFT create a NFT used by ARTIFACTAdmin
	//
	access(account)
	fun createNFT(templateId: String, packID: UInt64, owner: Address, royalties: [MetadataViews.Royalty], hashMetadata: HashMetadata): @NFT{ 
		return <-create NFT(templateId: templateId, packID: packID, owner: owner, royalties: royalties, hashMetadata: hashMetadata)
	}
	
	init(){ 
		// Paths
		self.collectionPublicPath = /public/ARTIFACTV2Collection
		self.collectionStoragePath = /storage/ARTIFACTV2Collection
		self.collectionPrivatePath = /private/ARTIFACTV2Collection
		self.nextNFTId = 1
		self.totalSupply = 0
		emit ContractInitialized()
	}
}
