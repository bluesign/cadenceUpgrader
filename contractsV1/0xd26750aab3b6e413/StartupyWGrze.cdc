import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import CollecticoRoyalties from "../0xffe32280cd5b72a3/CollecticoRoyalties.cdc"

import CollecticoStandardNFT from "../0x11cbef9729b236f3/CollecticoStandardNFT.cdc"

import CollecticoStandardViews from "../0x11cbef9729b236f3/CollecticoStandardViews.cdc"

import CollectionResolver from "../0x11cbef9729b236f3/CollectionResolver.cdc"

/*
	Startupy w Grze
	(c) CollecticoLabs.com
 */

access(all)
contract StartupyWGrze: NonFungibleToken, CollecticoStandardNFT, CollectionResolver{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, itemId: UInt64, serialNumber: UInt64)
	
	access(all)
	event Claimed(id: UInt64, itemId: UInt64, claimId: String)
	
	access(all)
	event Destroyed(id: UInt64, itemId: UInt64, serialNumber: UInt64)
	
	access(all)
	event ItemCreated(id: UInt64, name: String)
	
	access(all)
	event ItemDeleted(id: UInt64)
	
	access(all)
	event CollectionMetadataUpdated(keys: [String])
	
	access(all)
	event NewAdminCreated(receiver: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionProviderPath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let contractName: String
	
	access(self)
	var items: @{UInt64: Item}
	
	access(self)
	var nextItemId: UInt64
	
	access(self)
	var metadata:{ String: AnyStruct}
	
	access(self)
	var claims:{ String: Bool}
	
	access(self)
	var defaultRoyalties: [MetadataViews.Royalty]
	
	// for the future use
	access(self)
	var nftViewResolvers: @{String:{ CollecticoStandardViews.NFTViewResolver}}
	
	access(self)
	var itemViewResolvers: @{String:{ CollecticoStandardViews.ItemViewResolver}}
	
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.License>(), Type<CollecticoStandardViews.ContractInfo>()]
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.Display>():
				return MetadataViews.Display(name: self.metadata["name"]! as! String, description: self.metadata["description"]! as! String, thumbnail: (self.metadata["squareImage"]! as! MetadataViews.Media).file)
			case Type<MetadataViews.ExternalURL>():
				return self.getExternalURL()
			case Type<MetadataViews.NFTCollectionDisplay>():
				return self.getCollectionDisplay()
			case Type<MetadataViews.NFTCollectionData>():
				return self.getCollectionData()
			case Type<MetadataViews.Royalties>():
				return MetadataViews.Royalties(self.defaultRoyalties.concat(CollecticoRoyalties.getIssuerRoyalties()))
			case Type<MetadataViews.License>():
				let licenseId: String? = self.metadata["_licenseId"] as! String?
				return licenseId != nil ? MetadataViews.License(licenseId!) : nil
			case Type<CollecticoStandardViews.ContractInfo>():
				return self.getContractInfo()
		}
		return nil
	}
	
	access(all)
	resource Item: CollecticoStandardNFT.IItem, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let maxSupply: UInt64?
		
		access(all)
		let royalties: MetadataViews.Royalties?
		
		access(all)
		var numMinted: UInt64
		
		access(all)
		var numDestroyed: UInt64
		
		access(all)
		var isLocked: Bool
		
		access(all)
		let isTransferable: Bool
		
		init(id: UInt64, name: String, description: String, thumbnail:{ MetadataViews.File}, metadata:{ String: AnyStruct}?, maxSupply: UInt64?, isTransferable: Bool, royalties: [MetadataViews.Royalty]?){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
			self.maxSupply = maxSupply
			self.isTransferable = isTransferable
			if royalties != nil && (royalties!).length > 0{ 
				self.royalties = MetadataViews.Royalties((royalties!).concat(CollecticoRoyalties.getIssuerRoyalties()))
			} else{ 
				let defaultRoyalties = StartupyWGrze.defaultRoyalties.concat(CollecticoRoyalties.getIssuerRoyalties())
				if defaultRoyalties.length > 0{ 
					self.royalties = MetadataViews.Royalties(defaultRoyalties)
				} else{ 
					self.royalties = nil
				}
			}
			self.numMinted = 0
			self.numDestroyed = 0
			self.isLocked = false
		}
		
		access(contract)
		fun incrementNumMinted(){ 
			self.numMinted = self.numMinted + 1
		}
		
		access(contract)
		fun incrementNumDestroyed(){ 
			self.numDestroyed = self.numDestroyed + 1
		}
		
		access(contract)
		fun lock(){ 
			self.isLocked = true
		}
		
		access(all)
		view fun getTotalSupply(): UInt64{ 
			return self.numMinted - self.numDestroyed
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<CollecticoStandardViews.ItemView>(), Type<CollecticoStandardViews.ContractInfo>(), Type<MetadataViews.Display>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>(), Type<MetadataViews.License>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<CollecticoStandardViews.ItemView>():
					return CollecticoStandardViews.ItemView(id: self.id, name: self.name, description: self.description, thumbnail: self.thumbnail, metadata: self.metadata, totalSupply: self.getTotalSupply(), maxSupply: self.maxSupply, isLocked: self.isLocked, isTransferable: self.isTransferable, contractInfo: StartupyWGrze.getContractInfo(), collectionDisplay: StartupyWGrze.getCollectionDisplay(), royalties: MetadataViews.getRoyalties(&self as &StartupyWGrze.Item), display: MetadataViews.getDisplay(&self as &StartupyWGrze.Item), traits: MetadataViews.getTraits(&self as &StartupyWGrze.Item), medias: MetadataViews.getMedias(&self as &StartupyWGrze.Item), license: MetadataViews.getLicense(&self as &StartupyWGrze.Item))
				case Type<CollecticoStandardViews.ContractInfo>():
					return StartupyWGrze.getContractInfo()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: self.thumbnail)
				case Type<MetadataViews.Traits>():
					return StartupyWGrze.dictToTraits(dict: self.metadata, excludedNames: nil)
				case Type<MetadataViews.Royalties>():
					return self.royalties
				case Type<MetadataViews.Medias>():
					return StartupyWGrze.dictToMedias(dict: self.metadata, excludedNames: nil)
				case Type<MetadataViews.License>():
					var licenseId: String? = StartupyWGrze.getDictValue(dict: self.metadata, key: "_licenseId", type: Type<String>()) as! String?
					if licenseId == nil{ 
						licenseId = StartupyWGrze.getDictValue(dict: StartupyWGrze.metadata, key: "_licenseId", type: Type<String>()) as! String?
					}
					return licenseId != nil ? MetadataViews.License(licenseId!) : nil
				case Type<MetadataViews.ExternalURL>():
					return StartupyWGrze.getExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return StartupyWGrze.getCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return StartupyWGrze.getCollectionData()
			}
			return nil
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let itemId: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let royalties: MetadataViews.Royalties? // reserved for the fututure use
		
		
		access(all)
		var isTransferable: Bool
		
		init(id: UInt64, itemId: UInt64, serialNumber: UInt64, isTransferable: Bool, metadata:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]?){ 
			self.id = id
			self.itemId = itemId
			self.serialNumber = serialNumber
			self.isTransferable = isTransferable
			self.metadata = metadata
			if royalties != nil && (royalties!).length > 0{ 
				self.royalties = MetadataViews.Royalties((royalties!).concat(CollecticoRoyalties.getIssuerRoyalties()))
			} else{ 
				self.royalties = nil // it will fallback to the item's royalties
			
			}
			emit Minted(id: id, itemId: itemId, serialNumber: serialNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<CollecticoStandardViews.NFTView>(), Type<CollecticoStandardViews.ContractInfo>(), Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>(), Type<MetadataViews.License>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let item = StartupyWGrze.getItemRef(itemId: self.itemId)
			switch view{ 
				case Type<CollecticoStandardViews.NFTView>():
					return CollecticoStandardViews.NFTView(id: self.id, itemId: self.itemId, itemName: item.name.concat(" #").concat(self.serialNumber.toString()), itemDescription: item.description, itemThumbnail: *item.thumbnail, itemMetadata: *item.metadata, serialNumber: self.serialNumber, metadata: self.metadata, itemTotalSupply: item.getTotalSupply(), itemMaxSupply: item.maxSupply, isTransferable: self.isTransferable, contractInfo: StartupyWGrze.getContractInfo(), collectionDisplay: StartupyWGrze.getCollectionDisplay(), royalties: MetadataViews.getRoyalties(&self as &StartupyWGrze.NFT), display: MetadataViews.getDisplay(&self as &StartupyWGrze.NFT), traits: MetadataViews.getTraits(&self as &StartupyWGrze.NFT), editions: MetadataViews.getEditions(&self as &StartupyWGrze.NFT), medias: MetadataViews.getMedias(&self as &StartupyWGrze.NFT), license: MetadataViews.getLicense(&self as &StartupyWGrze.NFT))
				case Type<CollecticoStandardViews.ContractInfo>():
					return StartupyWGrze.getContractInfo()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: item.name.concat(" #").concat(self.serialNumber.toString()), description: item.description, thumbnail: *item.thumbnail)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: item.name, number: self.serialNumber, max: item.maxSupply)
					return MetadataViews.Editions([editionInfo])
				case Type<MetadataViews.Traits>():
					let mergedMetadata = StartupyWGrze.mergeDicts(*item.metadata, self.metadata)
					return StartupyWGrze.dictToTraits(dict: mergedMetadata, excludedNames: nil)
				case Type<MetadataViews.Royalties>():
					return self.royalties != nil ? self.royalties : item.royalties
				case Type<MetadataViews.Medias>():
					return StartupyWGrze.dictToMedias(dict: *item.metadata, excludedNames: nil)
				case Type<MetadataViews.License>():
					return MetadataViews.getLicense(item as &{ViewResolver.Resolver})
				case Type<MetadataViews.ExternalURL>():
					return StartupyWGrze.getExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return StartupyWGrze.getCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return StartupyWGrze.getCollectionData()
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
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollecticoNFT(id: UInt64): &StartupyWGrze.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CollecticoNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			// Borrow nft and check if locked
			let nft = self.borrowCollecticoNFT(id: withdrawID) ?? panic("Requested NFT does not exist in the collection")
			if !nft.isTransferable{ 
				panic("Cannot withdraw: NFT is not transferable (Soulbound)")
			}
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @StartupyWGrze.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
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
		fun borrowCollecticoNFT(id: UInt64): &StartupyWGrze.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &StartupyWGrze.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let collecticoNFT = nft as! &StartupyWGrze.NFT
			return collecticoNFT
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
	fun getAllItemsRef(): [&Item]{ 
		let resultItems: [&Item] = []
		for key in self.items.keys{ 
			let item = self.getItemRef(itemId: key)
			resultItems.append(item)
		}
		return resultItems
	}
	
	access(all)
	fun getAllItems(view: Type): [AnyStruct]{ 
		let resultItems: [AnyStruct] = []
		for key in self.items.keys{ 
			let item = self.getItemRef(itemId: key)
			let itemView = item.resolveView(view)
			if itemView == nil{ 
				return [] // Unsupported view
			
			}
			resultItems.append(itemView!)
		}
		return resultItems
	}
	
	access(all)
	view fun getItemRef(itemId: UInt64): &Item{ 
		pre{ 
			self.items[itemId] != nil:
				"Item doesn't exist"
		}
		let item = &self.items[itemId] as &Item?
		return item!
	}
	
	access(all)
	fun getItem(itemId: UInt64, view: Type): AnyStruct?{ 
		pre{ 
			self.items[itemId] != nil:
				"Item doesn't exist"
		}
		let item: &Item = self.getItemRef(itemId: itemId)
		return item.resolveView(view)
	}
	
	access(all)
	fun isClaimed(claimId: String): Bool{ 
		return self.claims.containsKey(claimId)
	}
	
	access(all)
	fun areClaimed(claimIds: [String]):{ String: Bool}{ 
		let res:{ String: Bool} ={} 
		for claimId in claimIds{ 
			res.insert(key: claimId, self.isClaimed(claimId: claimId))
		}
		return res
	}
	
	access(all)
	view fun countNFTsMintedPerItem(itemId: UInt64): UInt64{ 
		let item = self.getItemRef(itemId: itemId)
		return item.numMinted
	}
	
	access(all)
	view fun countNFTsDestroyedPerItem(itemId: UInt64): UInt64{ 
		let item = self.getItemRef(itemId: itemId)
		return item.numDestroyed
	}
	
	access(all)
	view fun isItemSupplyValid(itemId: UInt64): Bool{ 
		let item = self.getItemRef(itemId: itemId)
		return item.maxSupply == nil || item.getTotalSupply() <= item.maxSupply!
	}
	
	access(all)
	view fun isItemLocked(itemId: UInt64): Bool{ 
		let item = self.getItemRef(itemId: itemId)
		return item.isLocked
	}
	
	access(all)
	fun assertCollectionMetadataIsValid(){ 
		// assert display data:
		self.assertDictEntry(self.metadata, "name", Type<String>(), true)
		self.assertDictEntry(self.metadata, "description", Type<String>(), true)
		self.assertDictEntry(self.metadata, "externalURL", Type<MetadataViews.ExternalURL>(), true)
		self.assertDictEntry(self.metadata, "squareImage", Type<MetadataViews.Media>(), true)
		self.assertDictEntry(self.metadata, "bannerImage", Type<MetadataViews.Media>(), true)
		self.assertDictEntry(self.metadata, "socials", Type<{String: MetadataViews.ExternalURL}>(), true)
		self.assertDictEntry(self.metadata, "_licenseId", Type<String>(), false)
	}
	
	access(all)
	fun getExternalURL(): MetadataViews.ExternalURL{ 
		return self.metadata["externalURL"]! as! MetadataViews.ExternalURL
	}
	
	access(all)
	fun getContractInfo(): CollecticoStandardViews.ContractInfo{ 
		return CollecticoStandardViews.ContractInfo(name: self.contractName, address: self.account.address)
	}
	
	access(all)
	fun getCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
		return MetadataViews.NFTCollectionDisplay(name: self.metadata["name"]! as! String, description: self.metadata["description"]! as! String, externalURL: self.metadata["externalURL"]! as! MetadataViews.ExternalURL, squareImage: self.metadata["squareImage"]! as! MetadataViews.Media, bannerImage: self.metadata["bannerImage"]! as! MetadataViews.Media, socials: self.metadata["socials"]! as!{ String: MetadataViews.ExternalURL})
	}
	
	access(all)
	fun getCollectionData(): MetadataViews.NFTCollectionData{ 
		return MetadataViews.NFTCollectionData(storagePath: self.CollectionStoragePath, publicPath: self.CollectionPublicPath, publicCollection: Type<&StartupyWGrze.Collection>(), publicLinkedType: Type<&StartupyWGrze.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
				return <-StartupyWGrze.createEmptyCollection(nftType: Type<@StartupyWGrze.Collection>())
			})
	}
	
	access(all)
	fun assertItemMetadataIsValid(itemId: UInt64){ 
		let item = self.getItemRef(itemId: itemId)
		self.assertDictEntry(*item.metadata, "_licenseId", Type<String>(), false)
	}
	
	access(all)
	fun assertDictEntry(_ dict:{ String: AnyStruct}?, _ key: String, _ type: Type, _ required: Bool){ 
		if dict != nil{ 
			self.assertValueAndType(name: key, value: (dict!)[key], type: type, required: required)
		}
	}
	
	access(all)
	fun assertValueAndType(name: String, value: AnyStruct?, type: Type, required: Bool){ 
		if required{ 
			assert(value != nil, message: "Missing required value for '".concat(name).concat("'"))
		}
		if value != nil{ 
			assert((value!).isInstance(type), message: "Incorrect type for '".concat(name).concat("' - expected ").concat(type.identifier).concat(", got ").concat((value!).getType().identifier))
		}
	}
	
	access(all)
	fun getDictValue(dict:{ String: AnyStruct}?, key: String, type: Type): AnyStruct?{ 
		if dict == nil || (dict!)[key] == nil || !((dict!)[key]!).isInstance(type){ 
			return nil
		}
		return (dict!)[key]!
	}
	
	access(all)
	fun dictToTraits(dict:{ String: AnyStruct}?, excludedNames: [String]?): MetadataViews.Traits?{ 
		let traits = self.dictToTraitArray(dict: dict, excludedNames: excludedNames)
		return traits.length != 0 ? MetadataViews.Traits(traits) : nil
	}
	
	access(all)
	fun dictToTraitArray(dict:{ String: AnyStruct}?, excludedNames: [String]?): [MetadataViews.Trait]{ 
		if dict == nil{ 
			return []
		}
		let dictionary = dict!
		if excludedNames != nil{ 
			for k in excludedNames!{ 
				dictionary.remove(key: k)
			}
		}
		let traits: [MetadataViews.Trait] = []
		for k in dictionary.keys{ 
			if dictionary[k] == nil || k.length < 1 || k[0] == "_"{ // key starts with '_' character or value is nil 
				
				continue
			}
			if (dictionary[k]!).isInstance(Type<MetadataViews.Trait>()){ 
				traits.append(dictionary[k]! as! MetadataViews.Trait)
			} else if (dictionary[k]!).isInstance(Type<String>()){ 
				traits.append(MetadataViews.Trait(name: k, value: dictionary[k]!, displayType: nil, rarity: nil))
			} else if (dictionary[k]!).isInstance(Type<{String: AnyStruct?}>()){ 
				let trait:{ String: AnyStruct?} = dictionary[k]! as!{ String: AnyStruct?}
				var displayType: String? = nil
				var rarity: MetadataViews.Rarity? = nil
				// Purposefully checking and casting to String? instead of String due to rare cases
				// when displayType != nil AND all the other fields == nil 
				// then the type of such dictionary is {String: String?} instead of {String: String}
				if trait["displayType"] != nil && (trait["displayType"]!).isInstance(Type<String?>()){ 
					displayType = trait["displayType"]! as! String?
				}
				// Purposefully checking and casting to MetadataViews.Rarity? instead of MetadataViews.Rarity- see reasoning above
				if trait["rarity"] != nil && (trait["rarity"]!).isInstance(Type<MetadataViews.Rarity?>()){ 
					rarity = trait["rarity"]! as! MetadataViews.Rarity?
				}
				traits.append(MetadataViews.Trait(name: k, value: trait["value"], displayType: displayType, rarity: rarity))
			}
		}
		return traits
	}
	
	access(all)
	fun dictToMedias(dict:{ String: AnyStruct}?, excludedNames: [String]?): MetadataViews.Medias?{ 
		let medias = self.dictToMediaArray(dict: dict, excludedNames: excludedNames)
		return medias.length != 0 ? MetadataViews.Medias(medias) : nil
	}
	
	access(all)
	fun dictToMediaArray(dict:{ String: AnyStruct}?, excludedNames: [String]?): [MetadataViews.Media]{ 
		if dict == nil{ 
			return []
		}
		let dictionary = dict!
		if excludedNames != nil{ 
			for k in excludedNames!{ 
				dictionary.remove(key: k)
			}
		}
		let medias: [MetadataViews.Media] = []
		for k in dictionary.keys{ 
			if dictionary[k] == nil || k.length < 6 || k.slice(from: 0, upTo: 6) != "_media"{ 
				continue
			}
			if (dictionary[k]!).isInstance(Type<MetadataViews.Media>()){ 
				medias.append(dictionary[k]! as! MetadataViews.Media)
			} else if (dictionary[k]!).isInstance(Type<{String: AnyStruct?}>()){ 
				let media:{ String: AnyStruct} = dictionary[k]! as!{ String: AnyStruct}
				var file:{ MetadataViews.File}? = nil
				var mediaType: String? = nil
				if media["mediaType"] != nil && (media["mediaType"]!).isInstance(Type<String>()){ 
					mediaType = media["mediaType"]! as! String
				}
				if media["file"] != nil && (media["file"]!).isInstance(Type<{MetadataViews.File}>()){ 
					file = media["file"]! as!{ MetadataViews.File}
				}
				if file != nil && mediaType != nil{ 
					medias.append(MetadataViews.Media(file: file!, mediaType: mediaType!))
				}
			}
		}
		return medias
	}
	
	access(all)
	fun mergeDicts(_ dict1:{ String: AnyStruct}?, _ dict2:{ String: AnyStruct}?):{ String: AnyStruct}?{ 
		if dict1 == nil{ 
			return dict2
		} else if dict2 == nil{ 
			return dict1
		}
		for k in (dict2!).keys{ 
			if (dict2!)[k]! != nil{ 
				(dict1!).insert(key: k, (dict2!)[k]!)
			}
		}
		return dict1
	}
	
	access(all)
	resource Admin{ 
		
		// for the future use
		access(all)
		let data:{ String: AnyStruct}
		
		init(){ 
			self.data ={} 
		}
		
		access(all)
		fun createItem(name: String, description: String, thumbnail: MetadataViews.Media, metadata:{ String: AnyStruct}?, maxSupply: UInt64?, isTransferable: Bool?, royalties: [MetadataViews.Royalty]?): UInt64{ 
			let newItemId = StartupyWGrze.nextItemId
			StartupyWGrze.items[newItemId] <-! create Item(id: newItemId, name: name, description: description, thumbnail: thumbnail.file, metadata: metadata != nil ? metadata! :{} , maxSupply: maxSupply, isTransferable: isTransferable != nil ? isTransferable! : true, royalties: royalties)
			StartupyWGrze.assertItemMetadataIsValid(itemId: newItemId)
			StartupyWGrze.nextItemId = newItemId + 1
			emit ItemCreated(id: newItemId, name: name)
			return newItemId
		}
		
		access(all)
		fun deleteItem(itemId: UInt64){ 
			pre{ 
				StartupyWGrze.items[itemId] != nil:
					"Item doesn't exist"
				StartupyWGrze.countNFTsMintedPerItem(itemId: itemId) == StartupyWGrze.countNFTsDestroyedPerItem(itemId: itemId):
					"Cannot delete item that has existing NFTs"
			}
			let item <- StartupyWGrze.items.remove(key: itemId)
			emit ItemDeleted(id: itemId)
			destroy item
		}
		
		access(all)
		fun lockItem(itemId: UInt64){ 
			pre{ 
				StartupyWGrze.items[itemId] != nil:
					"Item doesn't exist"
			}
			let item = StartupyWGrze.getItemRef(itemId: itemId)
			item.lock()
		}
		
		access(all)
		fun mintNFT(itemId: UInt64, isTransferable: Bool?, metadata:{ String: AnyStruct}?): @NFT{ 
			pre{ 
				StartupyWGrze.items[itemId] != nil:
					"Item doesn't exist"
				!StartupyWGrze.isItemLocked(itemId: itemId):
					"Item is locked and cannot be minted anymore"
			}
			post{ 
				StartupyWGrze.isItemSupplyValid(itemId: itemId):
					"Max supply reached- cannot mint more NFTs of this type"
			}
			let item = StartupyWGrze.getItemRef(itemId: itemId)
			let newNFTid = StartupyWGrze.totalSupply + 1
			let newSerialNumber = item.numMinted + 1
			let newNFT: @NFT <- create NFT(id: newNFTid, itemId: itemId, serialNumber: newSerialNumber, isTransferable: isTransferable != nil ? isTransferable! : item.isTransferable, metadata: metadata, royalties: nil)
			item.incrementNumMinted()
			StartupyWGrze.totalSupply = StartupyWGrze.totalSupply + 1
			return <-newNFT
		}
		
		access(all)
		fun mintAndClaim(itemId: UInt64, claimId: String, isTransferable: Bool?, metadata:{ String: AnyStruct}?): @NFT{ 
			pre{ 
				!StartupyWGrze.claims.containsKey(claimId):
					"Item already claimed"
			}
			post{ 
				StartupyWGrze.claims.containsKey(claimId):
					"Claim failed"
			}
			let newNFT: @NFT <- self.mintNFT(itemId: itemId, isTransferable: isTransferable, metadata: metadata)
			StartupyWGrze.claims.insert(key: claimId, true)
			emit Claimed(id: newNFT.id, itemId: newNFT.itemId, claimId: claimId)
			return <-newNFT
		}
		
		access(all)
		fun createNewAdmin(receiver: Address?): @Admin{ 
			emit NewAdminCreated(receiver: receiver)
			return <-create Admin()
		}
		
		access(all)
		fun updateCollectionMetadata(data:{ String: AnyStruct}){ 
			for key in data.keys{ 
				StartupyWGrze.metadata.insert(key: key, data[key]!)
			}
			StartupyWGrze.assertCollectionMetadataIsValid()
			emit CollectionMetadataUpdated(keys: data.keys)
		}
		
		access(all)
		fun updateDefaultRoyalties(royalties: [MetadataViews.Royalty]){ 
			StartupyWGrze.defaultRoyalties = royalties
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.nextItemId = 1
		self.items <-{} 
		self.claims ={} 
		self.defaultRoyalties = []
		self.nftViewResolvers <-{} 
		self.itemViewResolvers <-{} 
		self.contractName = "StartupyWGrze"
		self.metadata ={ "name": "Startupy w Grze", "description": "Zestaw kart kolekcjonerskich upami\u{119}tniaj\u{105}cych udzia\u{142} w programie 'Startupy w grze' zorganizowanym przez PZPN Invest, Rebels Valley i NASK. Program ten jest skierowany do polskich i mi\u{119}dzynarodowych startup\u{f3}w wspieraj\u{105}cych pi\u{142}k\u{119} no\u{17c}n\u{105} przy pomocy tworzonych i rozwijanych przez siebie nowoczesnych technologii. W sk\u{142}ad kolekcji wchodz\u{105} karty potwierdzaj\u{105}ce zaaplikowanie i dostanie si\u{119} do poszczeg\u{f3}lnych etap\u{f3}w, jak te\u{17c} pami\u{105}tkowe karty dla uczestnik\u{f3}w Demo Days oraz wspieraj\u{105}cych program os\u{f3}b i organizacji.", "externalURL": MetadataViews.ExternalURL("https://startupywgrze.pzpn.pl"), "squareImage": MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiaypf5it2qkvhyzmmkro5oaaclkgmggzcn2rr436yriyr6ame2spa", path: "square.png"), mediaType: "image/png"), "bannerImage": MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiaypf5it2qkvhyzmmkro5oaaclkgmggzcn2rr436yriyr6ame2spa", path: "banner.png"), mediaType: "image/png"), "socials":{ "twitter": MetadataViews.ExternalURL("https://twitter.com/LaczyNasPilka")}}
		
		// Set the named paths
		self.CollectionStoragePath = /storage/collecticoStartupyWGrzeCollection
		self.CollectionPublicPath = /public/collecticoStartupyWGrzeCollection
		self.CollectionProviderPath = /private/collecticoStartupyWGrzeCollection
		self.AdminStoragePath = /storage/collecticoStartupyWGrzeAdmin
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&StartupyWGrze.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create an Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
