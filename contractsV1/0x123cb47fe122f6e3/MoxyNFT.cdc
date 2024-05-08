import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MoxyNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	var editions:{ UInt64: Edition}
	
	access(contract)
	var editionIndex: UInt64
	
	access(contract)
	var catalogList:{ UInt64: Catalog}
	
	access(contract)
	var catalogListIndex: UInt64
	
	access(contract)
	var mintRequest: MintRequest?
	
	access(all)
	var catalogsTotalSupply:{ UInt64: UInt64}
	
	access(all)
	var editionsTotalSupply:{ UInt64: UInt64}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event NFTMinted(catalogId: UInt64, editionId: UInt64, tokensMinted: UInt64)
	
	access(all)
	event CatalogAdded(collectionId: UInt64, name: String)
	
	access(all)
	event NFTMintRequestStored(catalogId: UInt64, editionId: UInt64, tokensToMint: UInt64)
	
	access(all)
	event NFTMintRequestFinished(catalogId: UInt64, editionId: UInt64, tokensMinted: UInt64)
	
	access(all)
	event ProcessMintRequestStarted(catalogId: UInt64, editionId: UInt64)
	
	access(all)
	event ProcessMintRequestFinished(catalogId: UInt64, editionId: UInt64, nftMinted: UInt64, remaining: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let catalogId: UInt64
		
		access(all)
		let editionId: UInt64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(all)
		let edition: UInt64
		
		init(id: UInt64, catalogId: UInt64, editionId: UInt64, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}, edition: UInt64){ 
			pre{ 
				MoxyNFT.editions[editionId] != nil:
					"The edition does not exists"
				MoxyNFT.catalogList[catalogId] != nil:
					"Catalog/Collection does not exists"
			}
			self.id = id
			self.catalogId = catalogId
			self.editionId = editionId
			self.royalties = royalties
			self.metadata = metadata
			self.edition = edition
		}
		
		access(all)
		fun getEdition(): Edition{ 
			return MoxyNFT.editions[self.editionId]!
		}
		
		access(all)
		fun getCid(): String{ 
			return self.getEdition().cid
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.IPFSFile>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let edition = self.getEdition()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: edition.name, description: edition.description, thumbnail: MetadataViews.HTTPFile(url: edition.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.getEdition().name, number: self.edition, max: edition.maxEdition)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://moxy.io/nft".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MoxyNFT.CollectionStoragePath, publicPath: MoxyNFT.CollectionPublicPath, publicCollection: Type<&MoxyNFT.Collection>(), publicLinkedType: Type<&MoxyNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MoxyNFT.createEmptyCollection(nftType: Type<@MoxyNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let catalog = MoxyNFT.getCatalog(id: self.catalogId)!
					return MetadataViews.NFTCollectionDisplay(name: catalog.name, description: catalog.description, externalURL: MetadataViews.ExternalURL(catalog.externalURL), squareImage: catalog.squareImage, bannerImage: catalog.bannerImage, socials: catalog.socials)
				case Type<MetadataViews.Traits>():
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					let rarityTag = MetadataViews.Rarity(score: nil, max: nil, description: edition.rarityDescription)
					let rarityTrait = MetadataViews.Trait(name: "rarityTag", value: rarityTag, displayType: nil, rarity: rarityTag)
					traitsView.addTrait(rarityTrait)
					return traitsView
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: edition.cid, path: "path/algo")
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface MoxyNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getCatalogsInfo():{ UInt64: UInt64}
		
		access(all)
		fun getEditionsInfo():{ UInt64: UInt64}
		
		access(all)
		fun getCatalogTotal(catalogId: UInt64): UInt64
		
		access(all)
		fun getEditionTotal(editionId: UInt64): UInt64
		
		access(all)
		fun hasCatalog(catalogId: UInt64): Bool
		
		access(all)
		fun hasEdition(editionId: UInt64): Bool
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMoxyNFT(id: UInt64): &MoxyNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MoxyNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	// Struct to return info from a Catalog to be used on Views
	access(all)
	struct CatalogInfo{ 
		access(all)
		var id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var externalURL: String
		
		access(all)
		var squareImage: MetadataViews.Media
		
		access(all)
		var bannerImage: MetadataViews.Media
		
		access(all)
		var socials:{ String: MetadataViews.ExternalURL}
		
		init(id: UInt64, name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, socials:{ String: MetadataViews.ExternalURL}){ 
			self.id = id
			self.name = name
			self.description = description
			self.externalURL = externalURL
			self.squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: squareImage), mediaType: "image/jpeg")
			self.bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: bannerImage), mediaType: "image/jpeg")
			self.socials = socials
		}
	}
	
	access(all)
	struct Catalog{ 
		access(all)
		var id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var externalURL: String
		
		access(all)
		var squareImage: String
		
		access(all)
		var bannerImage: String
		
		access(all)
		var socials:{ String: MetadataViews.ExternalURL}
		
		access(all)
		fun getInfo(): CatalogInfo{ 
			return CatalogInfo(id: self.id, name: self.name, description: self.description, externalURL: self.externalURL, squareImage: self.squareImage, bannerImage: self.bannerImage, socials: self.socials)
		}
		
		init(id: UInt64, name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, socials:{ String: MetadataViews.ExternalURL}){ 
			self.id = id
			self.name = name
			self.description = description
			self.externalURL = externalURL
			self.squareImage = squareImage
			self.bannerImage = bannerImage
			self.socials = socials
		}
	}
	
	access(all)
	struct Edition{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let cid: String
		
		access(all)
		let rarityDescription: String
		
		access(all)
		let maxEdition: UInt64
		
		init(name: String, description: String, thumbnail: String, cid: String, rarityDescription: String, maxEdition: UInt64){ 
			MoxyNFT.editionIndex = MoxyNFT.editionIndex + 1
			self.id = MoxyNFT.editionIndex
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.cid = cid
			self.rarityDescription = rarityDescription
			self.maxEdition = maxEdition
		}
	}
	
	access(all)
	resource Collection: MoxyNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var catalogs:{ UInt64: UInt64}
		
		access(all)
		var editions:{ UInt64: UInt64}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.catalogs ={} 
			self.editions ={} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let to <- token as! @MoxyNFT.NFT
			self.unregisterToken(catalogId: to.catalogId, editionId: to.editionId)
			let tok <- to as @{NonFungibleToken.NFT}
			emit Withdraw(id: tok.id, from: self.owner?.address)
			return <-tok
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MoxyNFT.NFT
			let id: UInt64 = token.id
			self.registerToken(catalogId: token.catalogId, editionId: token.editionId)
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun registerToken(catalogId: UInt64, editionId: UInt64){ 
			if self.catalogs[catalogId] == nil{ 
				self.catalogs[catalogId] = 0
			}
			if self.editions[editionId] == nil{ 
				self.editions[editionId] = 0
			}
			self.catalogs[catalogId] = self.catalogs[catalogId]! + 1
			self.editions[editionId] = self.editions[editionId]! + 1
		}
		
		access(all)
		fun unregisterToken(catalogId: UInt64, editionId: UInt64){ 
			self.catalogs[catalogId] = self.catalogs[catalogId]! - 1
			self.editions[editionId] = self.editions[editionId]! - 1
			if self.catalogs[catalogId] == 0{ 
				self.catalogs.remove(key: catalogId)
			}
			if self.editions[editionId] == 0{ 
				self.editions.remove(key: editionId)
			}
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun getCatalogsInfo():{ UInt64: UInt64}{ 
			return self.catalogs
		}
		
		access(all)
		fun getEditionsInfo():{ UInt64: UInt64}{ 
			return self.editions
		}
		
		access(all)
		fun getCatalogTotal(catalogId: UInt64): UInt64{ 
			if self.catalogs[catalogId] == nil{ 
				return 0
			}
			return self.catalogs[catalogId]!
		}
		
		access(all)
		fun getEditionTotal(editionId: UInt64): UInt64{ 
			if self.editions[editionId] == nil{ 
				return 0
			}
			return self.editions[editionId]!
		}
		
		access(all)
		fun hasCatalog(catalogId: UInt64): Bool{ 
			return self.catalogs[catalogId] != nil
		}
		
		access(all)
		fun hasEdition(editionId: UInt64): Bool{ 
			return self.editions[editionId] != nil
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowMoxyNFT(id: UInt64): &MoxyNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MoxyNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let MoxyNFT = nft as! &MoxyNFT.NFT
			return MoxyNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	struct MintRequest{ 
		access(all)
		var recipient: Address
		
		access(all)
		var catalogId: UInt64
		
		access(all)
		var editionId: UInt64
		
		access(all)
		var royalties: [MetadataViews.Royalty]
		
		access(all)
		var currentEdition: UInt64
		
		access(all)
		fun editionMinted(){ 
			self.currentEdition = self.currentEdition + 1
		}
		
		access(all)
		fun hasFinished(): Bool{ 
			return self.currentEdition > (MoxyNFT.editions[self.editionId]!).maxEdition
		}
		
		access(all)
		fun hasPendings(): Bool{ 
			return !self.hasFinished()
		}
		
		access(all)
		fun getRemainings(): UInt64{ 
			return (MoxyNFT.editions[self.editionId]!).maxEdition - (self.currentEdition - 1)
		}
		
		init(recipient: Address, catalogId: UInt64, editionId: UInt64, royalties: [MetadataViews.Royalty]){ 
			self.recipient = recipient
			self.catalogId = catalogId
			self.editionId = editionId
			self.royalties = royalties
			self.currentEdition = 1
		}
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(contract)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, catalogId: UInt64, editionId: UInt64, royalties: [MetadataViews.Royalty], edition: UInt64){ 
			pre{ 
				MoxyNFT.editions[editionId] != nil:
					"The edition does not exists."
			}
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			
			// create a new NFT
			var newNFT <- create NFT(id: MoxyNFT.totalSupply, catalogId: catalogId, editionId: editionId, royalties: royalties, metadata: metadata, edition: edition)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MoxyNFT.totalSupply = MoxyNFT.totalSupply + 1
			
			// Increment total supply by catalog id and edition id
			if MoxyNFT.catalogsTotalSupply[catalogId] == nil{ 
				MoxyNFT.catalogsTotalSupply[catalogId] = 0
			}
			if MoxyNFT.editionsTotalSupply[editionId] == nil{ 
				MoxyNFT.editionsTotalSupply[editionId] = 0
			}
			MoxyNFT.catalogsTotalSupply[catalogId] = MoxyNFT.catalogsTotalSupply[catalogId]! + 1
			MoxyNFT.editionsTotalSupply[editionId] = MoxyNFT.editionsTotalSupply[editionId]! + 1
		}
		
		access(all)
		fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, catalogId: UInt64, name: String, description: String, thumbnail: String, cid: String, rarityDescription: String, royalties: [MetadataViews.Royalty], maxEdition: UInt64){ 
			pre{ 
				MoxyNFT.mintRequest == nil:
					"Can't mint, there is a mint request in course."
			}
			let edition = Edition(name: name, description: description, thumbnail: thumbnail, cid: cid, rarityDescription: rarityDescription, maxEdition: maxEdition)
			MoxyNFT.editions[edition.id] = edition
			MoxyNFT.mintRequest = MintRequest(recipient: (recipient.owner!).address, catalogId: catalogId, editionId: edition.id, royalties: royalties)
			emit NFTMintRequestStored(catalogId: catalogId, editionId: edition.id, tokensToMint: maxEdition)
			self.processMintRequest(quantity: 100)
		}
		
		access(all)
		fun processMintRequest(quantity: UInt64){ 
			pre{ 
				MoxyNFT.mintRequest != nil:
					"Can't process mint request, there is not a mint request in course."
			}
			var counter: UInt64 = 1
			emit ProcessMintRequestStarted(catalogId: (MoxyNFT.mintRequest!).catalogId, editionId: (MoxyNFT.mintRequest!).editionId)
			let recipientRef = getAccount((MoxyNFT.mintRequest!).recipient).capabilities.get<&{NonFungibleToken.CollectionPublic}>(MoxyNFT.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			while (MoxyNFT.mintRequest!).hasPendings() && counter <= quantity{ 
				// create a new NFT
				self.mintNFT(recipient: recipientRef, catalogId: (MoxyNFT.mintRequest!).catalogId, editionId: (MoxyNFT.mintRequest!).editionId, royalties: (MoxyNFT.mintRequest!).royalties, edition: (MoxyNFT.mintRequest!).currentEdition)
				counter = counter + 1
				(MoxyNFT.mintRequest!).editionMinted()
			}
			emit ProcessMintRequestFinished(catalogId: (MoxyNFT.mintRequest!).catalogId, editionId: (MoxyNFT.mintRequest!).editionId, nftMinted: counter - 1, remaining: (MoxyNFT.mintRequest!).getRemainings())
			if (MoxyNFT.mintRequest!).hasFinished(){ 
				emit NFTMinted(catalogId: (MoxyNFT.mintRequest!).catalogId, editionId: (MoxyNFT.mintRequest!).editionId, tokensMinted: (MoxyNFT.editions[(MoxyNFT.mintRequest!).editionId]!).maxEdition)
				emit NFTMintRequestFinished(catalogId: (MoxyNFT.mintRequest!).catalogId, editionId: (MoxyNFT.mintRequest!).editionId, tokensMinted: (MoxyNFT.editions[(MoxyNFT.mintRequest!).editionId]!).maxEdition)
				MoxyNFT.mintRequest = nil
			}
		}
		
		access(all)
		fun addCatalog(name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, socials:{ String: MetadataViews.ExternalURL}){ 
			MoxyNFT.catalogListIndex = MoxyNFT.catalogListIndex + 1
			let col = Catalog(id: MoxyNFT.catalogListIndex, name: name, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials)
			MoxyNFT.catalogList[col.id] = col
			emit CatalogAdded(collectionId: col.id, name: col.name)
		}
	}
	
	access(all)
	fun getCatalog(id: UInt64): CatalogInfo?{ 
		if MoxyNFT.catalogList[id] == nil{ 
			return nil
		}
		return (MoxyNFT.catalogList[id]!).getInfo()
	}
	
	access(all)
	fun getCatalogTotalSupply(catalogId: UInt64): UInt64{ 
		if MoxyNFT.catalogsTotalSupply[catalogId] == nil{ 
			return 0
		}
		return MoxyNFT.catalogsTotalSupply[catalogId]!
	}
	
	access(all)
	fun getEditionTotalSupply(editionId: UInt64): UInt64{ 
		if MoxyNFT.editionsTotalSupply[editionId] == nil{ 
			return 0
		}
		return MoxyNFT.editionsTotalSupply[editionId]!
	}
	
	access(all)
	fun isNFTMiningInProgress(): Bool{ 
		return MoxyNFT.mintRequest != nil
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.editions ={} 
		self.editionIndex = 0
		self.catalogList ={} 
		self.catalogListIndex = 0
		self.catalogsTotalSupply ={} 
		self.editionsTotalSupply ={} 
		self.mintRequest = nil
		
		// Set the named paths
		self.CollectionStoragePath = /storage/moxyNFTCollection
		self.CollectionPublicPath = /public/moxyNFTCollection
		self.MinterStoragePath = /storage/moxyNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&MoxyNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
