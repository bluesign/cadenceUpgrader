import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GaiaElementNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event SetAdded(id: UInt64, name: String)
	
	access(all)
	event SetUpdated(id: UInt64, name: String)
	
	access(all)
	event SetRemoved(id: UInt64, name: String)
	
	access(all)
	event ElementAdded(id: UInt64, name: String, setID: UInt64)
	
	access(all)
	event ElementUpdated(id: UInt64, name: String)
	
	access(all)
	event ElementRemoved(id: UInt64, name: String)
	
	access(all)
	event Mint(id: UInt64, setID: UInt64, elementID: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let OwnerStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionDisplay: MetadataViews.NFTCollectionDisplay
	
	access(contract)
	fun setCollectionDisplay(_ collectionDisplay: MetadataViews.NFTCollectionDisplay){ 
		self.collectionDisplay = collectionDisplay
	}
	
	access(all)
	var royalties: MetadataViews.Royalties
	
	access(contract)
	fun setRoyalties(_ royalties: MetadataViews.Royalties){ 
		self.royalties = royalties
	}
	
	access(all)
	struct Set{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		access(all)
		let elements:{ UInt64: Element}
		
		access(all)
		fun elementCount(): Int{ 
			return self.elements.keys.length
		}
		
		access(all)
		fun getElementRef(id: UInt64): &Element{ 
			return &self.elements[id]! as &GaiaElementNFT.Element
		}
		
		access(contract)
		fun addElement(elementID: UInt64, name: String, description: String, color: String, image:{ MetadataViews.File}, video:{ MetadataViews.File}?, metadata:{ String: AnyStruct}, maxSupply: UInt64){ 
			pre{ 
				self.elements.containsKey(elementID) == false:
					"Element ID already in use"
			}
			let element = GaiaElementNFT.Element(id: elementID, setID: self.id, name: name, description: description, color: color, image: image, video: video, metadata: metadata, maxSupply: maxSupply)
			self.elements[elementID] = element
			emit GaiaElementNFT.ElementAdded(id: element.id, name: element.name, setID: self.id)
		}
		
		access(contract)
		fun removeElement(id: UInt64){ 
			let element = self.getElementRef(id: id)
			assert(!element.isLocked(), message: "Element locked")
			emit GaiaElementNFT.ElementRemoved(id: element.id, name: element.name)
			self.elements.remove(key: element.id)
		}
		
		// lock set if it has any child elements
		access(all)
		fun isLocked(): Bool{ 
			return self.elementCount() > 0
		}
		
		init(id: UInt64, name: String, description: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.metadata = metadata
			self.elements ={} 
		}
	}
	
	access(all)
	let sets:{ UInt64: Set}
	
	access(all)
	fun setCount(): Int{ 
		return self.sets.keys.length
	}
	
	access(all)
	fun getSetRef(id: UInt64): &GaiaElementNFT.Set{ 
		return &GaiaElementNFT.sets[id]! as &GaiaElementNFT.Set
	}
	
	access(contract)
	fun addSet(setID: UInt64, name: String, description: String, metadata:{ String: AnyStruct}){ 
		pre{ 
			GaiaElementNFT.sets.containsKey(setID) == false:
				"Set ID already in use"
		}
		GaiaElementNFT.sets[setID] = GaiaElementNFT.Set(id: setID, name: name, description: description, metadata: metadata)
		emit GaiaElementNFT.SetAdded(id: setID, name: name)
	}
	
	access(contract)
	fun removeSet(id: UInt64){ 
		let set = GaiaElementNFT.getSetRef(id: id)
		assert(!set.isLocked(), message: "Set is locked")
		emit GaiaElementNFT.SetRemoved(id: set.id, name: set.name)
		GaiaElementNFT.sets.remove(key: id)
	}
	
	access(all)
	struct Element{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let color: String
		
		access(all)
		let image:{ MetadataViews.File}
		
		access(all)
		let video:{ MetadataViews.File}?
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		access(all)
		var totalSupply: UInt64
		
		access(all)
		let maxSupply: UInt64
		
		// mapping of nft mint sequence number to nft id
		access(all)
		let nftSerials:{ UInt64: UInt64}
		
		access(all)
		fun getNFTSerial(nftID: UInt64): UInt64?{ 
			return self.nftSerials[nftID]
		}
		
		access(all)
		fun set(): GaiaElementNFT.Set{ 
			return GaiaElementNFT.sets[self.setID]!
		}
		
		access(contract)
		fun mintNFT(nftID: UInt64): @GaiaElementNFT.NFT{ 
			pre{ 
				self.totalSupply < self.maxSupply
			}
			let nft <- GaiaElementNFT.mintNFT(nftID: nftID, setID: self.setID, elementID: self.id)
			let serial = self.totalSupply + 1
			self.nftSerials.insert(key: nft.id, serial)
			self.totalSupply = self.totalSupply + 1
			return <-nft
		}
		
		// lock element if it minted any child NFTs
		access(all)
		fun isLocked(): Bool{ 
			return self.totalSupply > 0
		}
		
		init(id: UInt64, setID: UInt64, name: String, description: String, color: String, image:{ MetadataViews.File}, video:{ MetadataViews.File}?, metadata:{ String: AnyStruct}, maxSupply: UInt64){ 
			self.id = id
			self.setID = setID
			self.name = name
			self.description = description
			self.color = color
			self.image = image
			self.video = video
			self.metadata = metadata
			self.maxSupply = maxSupply
			self.nftSerials ={} 
			self.totalSupply = 0
		}
	}
	
	access(all)
	struct ElementNFTView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		let setName: String
		
		access(all)
		let elementID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let color: String
		
		access(all)
		let image:{ MetadataViews.File}
		
		access(all)
		let video:{ MetadataViews.File}?
		
		access(all)
		let serialNumber: UInt64
		
		init(id: UInt64, setID: UInt64, setName: String, elementID: UInt64, name: String, description: String, color: String, image:{ MetadataViews.File}, video:{ MetadataViews.File}?, serialNumber: UInt64){ 
			self.id = id
			self.setID = setID
			self.setName = setName
			self.elementID = elementID
			self.name = name
			self.description = description
			self.color = color
			self.image = image
			self.video = video
			self.serialNumber = serialNumber
		}
	}
	
	access(contract)
	let nftIDs:{ UInt64: Bool}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let elementID: UInt64
		
		access(all)
		let setID: UInt64
		
		access(all)
		fun set(): &GaiaElementNFT.Set{ 
			return GaiaElementNFT.getSetRef(id: self.setID)
		}
		
		access(all)
		fun element(): &GaiaElementNFT.Element{ 
			return self.set().getElementRef(id: self.elementID)
		}
		
		access(all)
		fun serial(): UInt64{ 
			return self.element().getNFTSerial(nftID: self.id)!
		}
		
		access(all)
		fun name(): String{ 
			return self.element().name.concat(" #").concat(self.serial().toString())
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTView>(), Type<ElementNFTView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<ElementNFTView>():
					let element = self.element()
					return ElementNFTView(id: self.id, setID: self.setID, setName: self.set().name, elementID: self.elementID, name: element.name, description: element.description, color: element.color, image: *element.image, video: *element.video, serialNumber: self.serial())
				case Type<MetadataViews.NFTView>():
					let viewResolver = &self as &{ViewResolver.Resolver}
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.element().description, thumbnail: *self.element().image)
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.name(), number: self.serial(), max: self.element().maxSupply)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial())
				case Type<MetadataViews.Royalties>():
					return GaiaElementNFT.royalties
				case Type<MetadataViews.ExternalURL>():
					return GaiaElementNFT.collectionDisplay.externalURL
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: GaiaElementNFT.CollectionStoragePath, publicPath: GaiaElementNFT.CollectionPublicPath, publicCollection: Type<&GaiaElementNFT.Collection>(), publicLinkedType: Type<&GaiaElementNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-GaiaElementNFT.createEmptyCollection(nftType: Type<@GaiaElementNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return GaiaElementNFT.collectionDisplay
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, setID: UInt64, elementID: UInt64){ 
			self.id = id
			self.setID = setID
			self.elementID = elementID
		}
	}
	
	access(contract)
	fun mintNFT(nftID: UInt64, setID: UInt64, elementID: UInt64): @GaiaElementNFT.NFT{ 
		pre{ 
			GaiaElementNFT.nftIDs.containsKey(nftID) == false:
				"NFT ID is already in use"
		}
		let nft <- create NFT(id: nftID, setID: setID, elementID: elementID)
		GaiaElementNFT.nftIDs[nftID] = true
		GaiaElementNFT.totalSupply = GaiaElementNFT.totalSupply + 1
		emit GaiaElementNFT.Mint(id: nftID, setID: setID, elementID: elementID)
		return <-nft
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
		fun borrowGaiaElementNFT(id: UInt64): &GaiaElementNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GaiaElementNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GaiaElementNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
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
		fun borrowGaiaElementNFT(id: UInt64): &GaiaElementNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &GaiaElementNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &GaiaElementNFT.NFT
			return exampleNFT as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		let maxMints: UInt64
		
		access(self)
		var totalMints: UInt64
		
		access(all)
		fun mintNFT(nftID: UInt64, setID: UInt64, elementID: UInt64): @GaiaElementNFT.NFT{ 
			pre{ 
				self.totalMints < self.maxMints:
					"Minter exhausted"
			}
			let set = GaiaElementNFT.getSetRef(id: setID)
			let element = set.getElementRef(id: elementID)
			let nft <- element.mintNFT(nftID: nftID)
			self.totalMints = self.totalMints + 1
			return <-nft
		}
		
		init(maxMints: UInt64){ 
			self.maxMints = maxMints
			self.totalMints = 0
		}
	}
	
	access(contract)
	fun createMinter(maxMints: UInt64): @GaiaElementNFT.NFTMinter{ 
		return <-create GaiaElementNFT.NFTMinter(maxMints: maxMints)
	}
	
	access(all)
	resource Owner{ 
		access(all)
		fun setCollectionDisplay(_ collectionDisplay: MetadataViews.NFTCollectionDisplay){ 
			GaiaElementNFT.collectionDisplay = collectionDisplay
		}
		
		access(all)
		fun setRoyalties(_ royalties: MetadataViews.Royalties){ 
			GaiaElementNFT.royalties = royalties
		}
		
		access(all)
		fun addSet(setID: UInt64, name: String, description: String, metadata:{ String: AnyStruct}){ 
			GaiaElementNFT.addSet(setID: setID, name: name, description: description, metadata: metadata)
		}
		
		access(all)
		fun removeSet(id: UInt64){ 
			GaiaElementNFT.removeSet(id: id)
		}
		
		access(all)
		fun addElementToSet(elementID: UInt64, setID: UInt64, name: String, description: String, color: String, image:{ MetadataViews.File}, video:{ MetadataViews.File}?, metadata:{ String: AnyStruct}, maxSupply: UInt64){ 
			let set = GaiaElementNFT.getSetRef(id: setID)
			set.addElement(elementID: elementID, name: name, description: description, color: color, image: image, video: video, metadata: metadata, maxSupply: maxSupply)
		}
		
		access(all)
		fun removeElementInSet(setID: UInt64, elementID: UInt64){ 
			let set = GaiaElementNFT.getSetRef(id: setID)
			set.removeElement(id: elementID)
		}
		
		access(all)
		fun createMinter(maxMints: UInt64): @GaiaElementNFT.NFTMinter{ 
			return <-GaiaElementNFT.createMinter(maxMints: maxMints)
		}
	}
	
	access(contract)
	fun createOwner(): @GaiaElementNFT.Owner{ 
		return <-create Owner()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/GaiaElementNFTCollection002
		self.CollectionPrivatePath = /private/GaiaElementNFTCollection002
		self.CollectionPublicPath = /public/GaiaElementNFTCollection002
		self.MinterStoragePath = /storage/GaiaElementNFTMinter001
		self.OwnerStoragePath = /storage/GaiaElementNFTOwner
		self.totalSupply = 0
		self.sets ={} 
		self.nftIDs ={} 
		self.royalties = MetadataViews.Royalties([])
		self.collectionDisplay = MetadataViews.NFTCollectionDisplay(name: "Gaia Elements", description: "Gaia Element NFTs on the Flow Blockchain", externalURL: MetadataViews.ExternalURL("https://ongaia.com/elements"), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmdV7UDXCjTj5hVxrLsETwBbp4cHQwUG1m6GfEpotW7wHf", path: "elements-icon.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "Qmdd43Z3AjLtirHnLk2XbE8XruBg2fCoHoyYpNWhAhGqMb", path: "elements-banner.png"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/GaiaMarketplace")})
		let collection <- GaiaElementNFT.createEmptyCollection(nftType: Type<@GaiaElementNFT.Collection>())
		self.account.storage.save(<-collection, to: GaiaElementNFT.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&GaiaElementNFT.Collection>(GaiaElementNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: GaiaElementNFT.CollectionPublicPath)
		let owner <- GaiaElementNFT.createOwner()
		self.account.storage.save(<-owner, to: GaiaElementNFT.OwnerStoragePath)
		emit ContractInitialized()
	}
}
