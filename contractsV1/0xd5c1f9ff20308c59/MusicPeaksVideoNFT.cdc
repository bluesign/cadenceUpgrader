// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MusicPeaksVideoNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, nodeID: String)
	
	access(all)
	event EditionCreated(id: String)
	
	access(all)
	event CollectionCreated(id: String)
	
	access(all)
	event NodeCreated(id: String)
	
	access(all)
	event ProofCreated(id: String)
	
	access(all)
	event EditionAddedToList(proofID: String, editionID: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Metadata Dictionaries
	access(self)
	let collectionByID: @{String: CollectionNode}
	
	access(self)
	let editionByID: @{String: EditionNode}
	
	access(self)
	let nodeByID: @{String: Node}
	
	access(self)
	let proofByID: @{String: ProofNode}
	
	// A top level resource that contains necessary Collection node metadata
	//
	access(all)
	resource CollectionNode{ 
		access(all)
		let id: String
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.metadata = metadata
			emit CollectionCreated(id: self.id)
		}
	}
	
	// A top level resource that contains necessary Edition node metadata
	//
	access(all)
	resource EditionNode{ 
		access(all)
		let id: String
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.metadata = metadata
			emit EditionCreated(id: self.id)
		}
	}
	
	// A top level resource that contains node metadata
	//
	access(all)
	resource Node{ 
		access(all)
		let id: String
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.metadata = metadata
			emit NodeCreated(id: self.id)
		}
	}
	
	access(all)
	resource ProofNode{ 
		access(all)
		let id: String
		
		access(contract)
		var editions: [String]
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.editions = []
			self.metadata = metadata
			emit ProofCreated(id: self.id)
		}
		
		access(all)
		fun addEdition(editionID: String){ 
			if !self.editions.contains(editionID){ 
				// Add the Edition to the array of Editions
				self.editions.append(editionID)
				emit EditionAddedToList(proofID: self.id, editionID: editionID)
			}
		}
	}
	
	// This is an implementation of a custom metadata view for MusicPeaks Video NFT.
	// This view contains the video metadata, like artist name, show, production etc.
	//
	access(all)
	struct MusicPeaksVideoNFTMetadataView{ 
		access(all)
		let nodeID: String
		
		access(all)
		let canonicalNodeID: String
		
		access(all)
		let artistName: String?
		
		access(all)
		let showName: String?
		
		access(all)
		let clipTitle: String?
		
		access(all)
		let clipType: String?
		
		access(all)
		let clipDate: String?
		
		access(all)
		let videoResolution: String?
		
		access(all)
		let productionCompany: String?
		
		access(all)
		let tags: AnyStruct?
		
		init(nodeID: String, canonicalNodeID: String, artistName: String?, showName: String?, clipTitle: String?, clipType: String?, clipDate: String?, videoResolution: String?, productionCompany: String?, tags: AnyStruct?){ 
			self.nodeID = nodeID
			self.canonicalNodeID = canonicalNodeID
			self.artistName = artistName
			self.showName = showName
			self.clipTitle = clipTitle
			self.clipType = clipType
			self.clipDate = clipDate
			self.videoResolution = videoResolution
			self.productionCompany = productionCompany
			self.tags = tags
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let nodeID: String
		
		access(all)
		let canonicalNodeID: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, nodeID: String, canonicalNodeID: String, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.nodeID = nodeID
			self.canonicalNodeID = canonicalNodeID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
			emit Minted(id: self.id, nodeID: self.nodeID)
		}
		
		access(all)
		fun getNodeID(): String{ 
			return self.nodeID
		}
		
		access(all)
		fun getCanonicalNodeID(): String{ 
			return self.canonicalNodeID
		}
		
		// Keep the old way of getting metadata
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		access(all)
		fun getCollectionData():{ String: String}{ 
			return (self.metadata!)["collection"]! as?{ String: String} ??{} 
		}
		
		access(all)
		fun getName(): String{ 
			// Trim string > 100 chars due to Dapper limitation
			if self.name.length > 100{ 
				return self.name.slice(from: 0, upTo: 97).concat("...")
			}
			return self.name
		}
		
		access(all)
		fun getDescription(): String{ 
			// Prepend full name before description
			return self.name.concat(": ").concat(self.description)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MusicPeaksVideoNFTMetadataView>()]
		}
		
		access(all)
		fun getCanonicalUrl(): String{ 
			return self.metadata["canonicalUrl"] as! String? ?? "https://marketplace.musicpeaks.com"
		}
		
		access(all)
		fun getEditionID(): String{ 
			return (self.metadata!)["editionID"] as! String? ?? "0"
		}
		
		access(all)
		fun getCollectionID(): String{ 
			return (self.metadata!)["collectionID"] as! String? ?? "0"
		}
		
		access(all)
		fun getProofID(): String{ 
			return (self.metadata!)["proofID"] as! String? ?? "0"
		}
		
		access(all)
		fun getMarketplaceRoyaltyRate(): UFix64{ 
			// Marketplace (Dapp) royalty, 5% by default.
			return (self.metadata!)["marketplaceRoyaltyRate"] as! UFix64? ?? 0.05
		}
		
		access(all)
		fun getOngoingRoyaltyRate(): UFix64{ 
			// Ongoing royalty rate, usually in range 0%..10%, 10% by default.
			return (self.metadata!)["ongoingRoyaltyRate"] as! UFix64? ?? 0.1
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getName(), description: self.getDescription(), thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Example NFT Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.metadata["externalUrl"] as! String? ?? self.getCanonicalUrl().concat("/card/").concat(self.canonicalNodeID))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MusicPeaksVideoNFT.CollectionStoragePath, publicPath: MusicPeaksVideoNFT.CollectionPublicPath, publicCollection: Type<&MusicPeaksVideoNFT.Collection>(), publicLinkedType: Type<&MusicPeaksVideoNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MusicPeaksVideoNFT.createEmptyCollection(nftType: Type<@MusicPeaksVideoNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://rockpeaksassets.s3.amazonaws.com/cubePackages/cd333d40-e993-4506-bc23-0bb6f0ca8a99/miniCube150.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "MusicPeaks Video NFT", description: "The MusicPeaks NFT marketplace features collectible 3D cards that showcase top audio-visual moments from the history of music, including promotional videos, live performances, interviews, news clips and more.", externalURL: MetadataViews.ExternalURL("https://musicpeaks.com"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/musicpeaks")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits = ["mintedTime", "foo"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					
					// foo is a trait with its own rarity
					let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
					let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
					traitsView.addTrait(fooTrait)
					return traitsView
				case Type<MusicPeaksVideoNFTMetadataView>():
					return MusicPeaksVideoNFTMetadataView(nodeID: self.nodeID, canonicalNodeID: self.canonicalNodeID, artistName: self.metadata["artistName"] as! String?, showName: self.metadata["showName"] as! String?, clipTitle: self.metadata["clipTitle"] as! String?, clipType: self.metadata["clipType"] as! String?, clipDate: self.metadata["clipDate"] as! String?, videoResolution: self.metadata["videoResolution"] as! String?, productionCompany: self.metadata["productionCompany"] as! String?, tags: self.metadata["tags"] as! AnyStruct?)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface MusicPeaksVideoNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMusicPeaksVideoNFT(id: UInt64): &MusicPeaksVideoNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MusicPeaksVideoNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MusicPeaksVideoNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @MusicPeaksVideoNFT.NFT
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
		fun borrowMusicPeaksVideoNFT(id: UInt64): &MusicPeaksVideoNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MusicPeaksVideoNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let musicPeaksVideoNFT = nft as! &MusicPeaksVideoNFT.NFT
			return musicPeaksVideoNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, nodeID: String, canonicalNodeID: String, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], nodeMetadata:{ String: AnyStruct}){ 
			let metadata:{ String: AnyStruct} ={} 
			let editionMetaData:{ String: AnyStruct} ={} 
			let itemMetaData:{ String: AnyStruct} ={} 
			let nftMetaData:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			
			// Add node metadata
			for key in nodeMetadata.keys{ 
				let value = nodeMetadata[key]!
				metadata[key] = value
			}
			if metadata.containsKey("collection"){ 
				let collectionMetaData = (metadata!)["collection"]! as?{ String: String} ??{} 
				if collectionMetaData.containsKey("uuid"){ 
					let collectionID = (collectionMetaData!)["uuid"]! as! String
					
					// Check if collection already exist
					if MusicPeaksVideoNFT.collectionByID[collectionID] == nil{ 
						// Create a new Collection node
						var collectionNode <- create CollectionNode(id: collectionID, metadata: collectionMetaData)
						MusicPeaksVideoNFT.collectionByID[collectionID] <-! collectionNode
					}
					
					// Adjust general metadata
					metadata["collectionID"] = collectionID
				}
			}
			if metadata.containsKey("proof"){ 
				let proofMetaData = (metadata!)["proof"]! as?{ String: AnyStruct} ??{} 
				if proofMetaData.containsKey("uuid"){ 
					let proofID = (proofMetaData!)["uuid"]! as! String
					if MusicPeaksVideoNFT.proofByID[proofID] == nil{ 
						// Create a new Proof node
						var proofNode <- create ProofNode(id: proofID, metadata: proofMetaData)
						MusicPeaksVideoNFT.proofByID[proofID] <-! proofNode
					}
					
					// Adjust general metadata
					metadata["proofID"] = proofID
				}
			}
			if metadata.containsKey("edition"){ 
				let editionData = (metadata!)["edition"]! as?{ String: AnyStruct} ??{} 
				if editionData.containsKey("uuid"){ 
					let editionID = (editionData!)["uuid"]! as! String
					
					// Check if edition already exist
					if MusicPeaksVideoNFT.editionByID[editionID] == nil{ 
						for key in editionData.keys{ 
							let value = editionData[key]!
							editionMetaData[key] = value
						}
						
						// Store everything related to edition
						editionMetaData["tags"] = metadata["tags"]
						editionMetaData["splitsValues"] = metadata["splitsValues"]
						editionMetaData["splitsEntities"] = metadata["splitsEntities"]
						
						// Create a new Edition node
						var editionNode <- create EditionNode(id: editionID, metadata: editionMetaData)
						MusicPeaksVideoNFT.editionByID[editionID] <-! editionNode
					}
					if metadata.containsKey("proof"){ 
						let proofMetaData = (metadata!)["proof"]! as?{ String: AnyStruct} ??{} 
						if proofMetaData.containsKey("uuid"){ 
							let proofID = (proofMetaData!)["uuid"]! as! String
							if MusicPeaksVideoNFT.proofByID[proofID] != nil{ 
								// Borrow a reference to the set to be added to
								let proofRef = (&MusicPeaksVideoNFT.proofByID[proofID] as &ProofNode?)!
								// Add the specified play ID
								proofRef.addEdition(editionID: editionID)
							}
						}
					}
					
					// Adjust general metadata
					metadata["editionID"] = editionID
				}
			}
			
			// Use item node uuid as ID to avoid issues on different env
			// Check if item node already exist
			if MusicPeaksVideoNFT.nodeByID[nodeID] == nil{ 
				// Create a new item node
				var node <- create Node(id: nodeID, metadata: metadata)
				MusicPeaksVideoNFT.nodeByID[nodeID] <-! node
			}
			
			// create a new NFT
			var newNFT <- create NFT(id: MusicPeaksVideoNFT.totalSupply, nodeID: nodeID, canonicalNodeID: canonicalNodeID, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MusicPeaksVideoNFT.totalSupply = MusicPeaksVideoNFT.totalSupply + UInt64(1)
		}
	}
	
	// Returns: The metadata field as a String Optional
	access(all)
	fun getCollectionMetaDataByField(id: String, field: String): String?{ 
		// Don't force a revert if the collection ID or field is invalid
		if let collection = &MusicPeaksVideoNFT.collectionByID[id] as &MusicPeaksVideoNFT.CollectionNode?{ 
			return collection.metadata[field] as! String?
		} else{ 
			return nil
		}
	}
	
	// Returns: The metadata field as a String Optional
	access(all)
	fun getEditionMetaDataByField(id: String, field: String): String?{ 
		// Don't force a revert if the edition ID or field is invalid
		if let edition = &MusicPeaksVideoNFT.editionByID[id] as &MusicPeaksVideoNFT.EditionNode?{ 
			return edition.metadata[field] as! String?
		} else{ 
			return nil
		}
	}
	
	// Returns: The metadata field as a String Optional
	access(all)
	fun getNodeMetaDataByField(id: String, field: String): String?{ 
		// Don't force a revert if the node ID or field is invalid
		if let node = &MusicPeaksVideoNFT.nodeByID[id] as &MusicPeaksVideoNFT.Node?{ 
			return node.metadata[field] as! String?
		} else{ 
			return nil
		}
	}
	
	// Returns: The metadata field as a String Optional
	access(all)
	fun getProofMetaDataByField(id: String, field: String): String?{ 
		// Don't force a revert if the proof node ID or field is invalid
		if let proof = &MusicPeaksVideoNFT.proofByID[id] as &MusicPeaksVideoNFT.ProofNode?{ 
			return proof.metadata[field] as! String?
		} else{ 
			return nil
		}
	}
	
	// Returns: The metadata as a String to AnyStruct mapping optional
	access(all)
	fun getCollectionNodeMetaData(id: String):{ String: AnyStruct}?{ 
		return self.collectionByID[id]?.metadata
	}
	
	// Returns: The metadata as a String to AnyStruct mapping optional
	access(all)
	fun getEditionNodeMetaData(id: String):{ String: AnyStruct}?{ 
		return self.editionByID[id]?.metadata
	}
	
	// Returns: The metadata as a String to AnyStruct mapping optional
	access(all)
	fun getNodeMetaData(id: String):{ String: AnyStruct}?{ 
		return self.nodeByID[id]?.metadata
	}
	
	// Returns: The metadata as a String to AnyStruct mapping optional
	access(all)
	fun getProofMetaData(id: String):{ String: AnyStruct}?{ 
		return self.proofByID[id]?.metadata
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.editionByID <-{} 
		self.collectionByID <-{} 
		self.nodeByID <-{} 
		self.proofByID <-{} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MusicPeaksVideoCollection
		self.CollectionPublicPath = /public/MusicPeaksVideoCollection
		self.MinterStoragePath = /storage/MusicPeaksVideoMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&MusicPeaksVideoNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
