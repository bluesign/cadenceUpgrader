import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import OverluConfig from "./OverluConfig.cdc"

import OverluError from "./OverluError.cdc"

access(all)
contract OverluDNA: NonFungibleToken{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeId: UInt64, to: Address?)
	
	access(all)
	event TypeTransfered(id: UInt64, typeId: UInt64, to: Address?)
	
	access(all)
	event Destroyed(id: UInt64, typeId: UInt64, operator: Address?)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var currentSupply: UInt64
	
	access(all)
	var baseURI: String
	
	access(all)
	var pause: Bool
	
	access(all)
	var intervalPerEnergy: UFix64
	
	access(contract)
	var exemptionTypeIds: [UInt64]
	
	// multi edition count for metadata
	access(contract)
	var supplyOfTypes:{ UInt64: UInt64}
	
	/// Reserved parameter fields: {ParamName: Value}
	access(contract)
	let _reservedFields:{ String: AnyStruct}
	
	// energy records
	access(contract)
	let energyAddedRecords:{ UInt64: [UFix64]}
	
	// metadata 
	access(contract)
	var predefinedMetadata:{ UInt64:{ String: AnyStruct}}
	
	// rarity records
	access(contract)
	var rarityMapping:{ String: AnyStruct}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
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
		let typeId: UInt64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, typeId: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.typeId = typeId
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
		}
		
		access(all)
		fun calculateEnergy(): UFix64{ 
			var energy = 0.0
			if OverluDNA.exemptionTypeIds.contains(self.typeId){ 
				return 100.0
			}
			// calc added energy
			let energyAdded = OverluDNA.energyAddedRecords[self.id] ?? []
			for e in energyAdded{ 
				energy = energy + e
			}
			if OverluDNA.intervalPerEnergy == 0.0{ 
				return energy
			}
			let mintedTime = (self.metadata["mintedTime"] as? UFix64?)!
			let currentTime = getCurrentBlock().timestamp
			let timeDiff = currentTime - mintedTime!
			let energyBase = timeDiff / OverluDNA.intervalPerEnergy
			energy = energy + energyBase
			
			// fully energy
			if energy > 100.0{ 
				energy = 100.0
			}
			return energy
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			let metadata = OverluDNA.predefinedMetadata[self.typeId] ??{} 
			// todo other meta data
			if OverluDNA.exemptionTypeIds.contains(self.typeId){ 
				metadata["exemption"] = true
			}
			metadata["metadata"] = self.metadata
			metadata["energy"] = self.calculateEnergy()
			return metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = OverluDNA.predefinedMetadata[self.typeId]!
			switch view{ 
				case Type<MetadataViews.Display>():
					let name = (metadata["name"] as? String?)!
					let description = (metadata["description"] as? String?)!
					let thumbnail = (metadata["thumbnail"] as? String?)!
					return MetadataViews.Display(name: name!, description: description!, thumbnail: MetadataViews.HTTPFile(url: thumbnail!))
				case Type<MetadataViews.Editions>():
					let number = (self.metadata["number"] as? UInt64?)!
					let max = (metadata["max"] as? UInt64?)!
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Overlu DNA NFT", number: number!, max: max!)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					let serial = (self.metadata["number"] as? UInt64?)!
					return MetadataViews.Serial(serial!)
				case Type<MetadataViews.Royalties>():
					let royalties = (metadata["royalties"] as? [MetadataViews.Royalty]?)!
					return MetadataViews.Royalties(royalties!)
				case Type<MetadataViews.ExternalURL>():
					let url = OverluDNA.baseURI.concat(self.typeId.toString())
					return MetadataViews.ExternalURL(url!)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: OverluDNA.CollectionStoragePath, publicPath: OverluDNA.CollectionPublicPath, publicCollection: Type<&OverluDNA.Collection>(), publicLinkedType: Type<&OverluDNA.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-OverluDNA.createEmptyCollection(nftType: Type<@OverluDNA.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: OverluDNA.baseURI), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Overlu LU Collection", description: "LU is of significance that carries info and value. It not only records changes in appearance but also is a component and a proof of utility in the real world. There are currently five types of initial LU acting on 5 different parts of the avatar. Noted that it\u{2019}s irreversible when initial LU functions, but when it does, the utility follows.", externalURL: MetadataViews.ExternalURL("https://www.overlu.io"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62f22a8782c301212eb2bee8/attachments/62f22ac549eec37d05a12068/previews/62f22ac649eec37d05a1217b/download/image.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62f22a8782c301212eb2bee8/attachments/62f22ac549eec37d05a12068/previews/62f22ac649eec37d05a1217b/download/image.png"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/OVERLU_NFT")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					// let excludedTraits = ["mintedTime"]
					let metadata = OverluDNA.predefinedMetadata[self.typeId]!
					let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: nil)
					
					// let traitsTest = MetadataViews.dictToTraits(dict: metadataStruct , excludedNames: nil)
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					let numberTrait = MetadataViews.Trait(name: "number", value: self.metadata["number"]!, displayType: "Number", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					traitsView.addTrait(numberTrait)
					return traitsView
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
		fun borrowOverluDNA(id: UInt64): &OverluDNA.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow OverluDNA reference: the ID of the returned reference is incorrect"
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
			pre{ 
				OverluDNA.pause == false:
					OverluError.errorEncode(msg: "DNA: contract pause", err: OverluError.ErrorCode.CONTRACT_PAUSE)
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let dna <- token as! @OverluDNA.NFT
			let typeId = dna.typeId
			let isOwner = OverluDNA.account.address == self.owner?.address
			if !OverluDNA.exemptionTypeIds.contains(typeId) && !isOwner{ 
				let energy = dna.calculateEnergy()
				assert(energy >= 100.0, message: OverluError.errorEncode(msg: "DNA: energy not enough to transfer", err: OverluError.ErrorCode.INSUFFICIENT_ENERGY))
			}
			// for DNA that use to upgrade do not allow transfer
			if OverluConfig.getDNANestRecords(dna.id) != nil{ 
				panic(OverluError.errorEncode(msg: "DNA: withdraw not allow after upgrade", err: OverluError.ErrorCode.ACCESS_DENY))
			}
			emit Withdraw(id: dna.id, from: self.owner?.address)
			return <-dna
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @OverluDNA.NFT
			let id: UInt64 = token.id
			emit TypeTransfered(id: id, typeId: token.typeId, to: self.owner?.address)
			
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
		fun borrowOverluDNA(id: UInt64): &OverluDNA.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &OverluDNA.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let OverluDNA = nft as! &OverluDNA.NFT
			return OverluDNA as &{ViewResolver.Resolver}
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
	
	// pub resource interface MinterPublic {
	//	 pub fun openPackage(userCertificateCap: Capability<&{OverluConfig.IdentityCertificate}>)
	// }
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(typeId: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty]){ 
			let preMetadata = OverluDNA.predefinedMetadata[typeId]!
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			var NFTNum: UInt64 = 0
			let typeSupply = OverluDNA.supplyOfTypes[typeId] ?? 0
			let max = (preMetadata["max"] as? UInt64?)!
			if typeSupply == max!{ 
				panic(OverluError.errorEncode(msg: "DNA: edition number exceed", err: OverluError.ErrorCode.EDITION_NUMBER_EXCEED))
			}
			if typeSupply == 0{ 
				OverluDNA.supplyOfTypes[typeId] = 1
			} else{ 
				OverluDNA.supplyOfTypes[typeId] = typeSupply + 1 as UInt64
				NFTNum = typeSupply
			}
			metadata["number"] = NFTNum
			metadata["id"] = OverluDNA.totalSupply
			// create a new NFT
			var newNFT <- create NFT(id: OverluDNA.totalSupply, typeId: typeId, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata)
			emit Minted(id: newNFT.id, typeId: typeId, to: (recipient.owner!).address)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			OverluDNA.totalSupply = OverluDNA.totalSupply + UInt64(1)
			OverluDNA.currentSupply = OverluDNA.currentSupply + UInt64(1)
		}
		
		// energy logic
		access(all)
		fun setEnergy(id: UInt64, energies: [UFix64]){ 
			// pre{
			//	 energies.length > 0 : OverluError.errorEncode(msg: "DNA: energy array is empty", err: OverluError.ErrorCode.INVALID_PARAMETERS)
			// }
			OverluDNA.energyAddedRecords[id] = energies
		}
		
		access(all)
		fun addEnergy(id: UInt64, energy: UFix64){ 
			let energies = OverluDNA.energyAddedRecords[id] ?? []
			energies.append(energy)
			OverluDNA.energyAddedRecords[id] = energies
		}
		
		access(all)
		fun setInterval(_ interval: UFix64){ 
			OverluDNA.intervalPerEnergy = interval
		}
		
		access(all)
		fun setPause(_ pause: Bool){ 
			OverluDNA.pause = pause
		}
		
		access(all)
		fun AddExemptionTypeIds(_ id: UInt64){ 
			pre{ 
				OverluDNA.exemptionTypeIds.contains(id) != true:
					OverluError.errorEncode(msg: "DNA: exemption type id already exists", err: OverluError.ErrorCode.ALREADY_EXIST)
			}
			OverluDNA.exemptionTypeIds.append(id)
		}
		
		access(all)
		fun removeExemptionTypeIds(_ id: UInt64){ 
			let idx = OverluDNA.exemptionTypeIds.firstIndex(of: id)
			OverluDNA.exemptionTypeIds.remove(at: idx!)
		}
		
		access(all)
		fun setBaseURI(_ uri: String){ 
			OverluDNA.baseURI = uri
		}
		
		// UpdateMetadata
		// Update metadata for a typeId
		//  type // max // name // description // thumbnail // royalties
		//
		access(all)
		fun updateMetadata(typeId: UInt64, metadata:{ String: AnyStruct}){ 
			let currentSupply = OverluDNA.supplyOfTypes[typeId] ?? 0
			let max = (metadata["max"] as? UInt64?)!
			if currentSupply != nil && currentSupply > 0{ 
				assert(currentSupply! <= max!, message: "Can not set max lower than supply")
			}
			OverluDNA.predefinedMetadata[typeId] = metadata
		}
		
		init(){} 
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// getTypeSupply
	// Get NFT supply of typeId
	//
	access(all)
	fun getTypeSupply(_ typeId: UInt64): UInt64?{ 
		return OverluDNA.supplyOfTypes[typeId]
	}
	
	// Get metadata
	//
	access(all)
	fun getMetadata(_ typeId: UInt64):{ String: AnyStruct}{ 
		return OverluDNA.predefinedMetadata[typeId] ??{} 
	}
	
	access(all)
	fun getExemptionTypeIds(): [UInt64]{ 
		return OverluDNA.exemptionTypeIds
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.currentSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/OverluDNACollection
		self.CollectionPublicPath = /public/OverluDNACollection
		self.MinterStoragePath = /storage/OverluDNAMinter
		self.MinterPublicPath = /public/OverluDNAMinter
		self.predefinedMetadata ={} 
		self._reservedFields ={} 
		self.intervalPerEnergy = 0.0
		self.energyAddedRecords ={} 
		self.supplyOfTypes ={} 
		self.baseURI = ""
		self.pause = true
		self.exemptionTypeIds = []
		self.rarityMapping ={} 
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&OverluDNA.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		// self.account.link<&OverluDNA.NFTMinter{OverluDNA.MinterPublic}>(self.MinterPublicPath, target: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
