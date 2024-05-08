// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract CryptoZooNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTTemplateCreated(typeID: UInt64, name: String, mintLimit: UInt64, priceUSD: UFix64, priceFlow: UFix64, metadata:{ String: String}, isPack: Bool)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64, serialNumber: UInt64, metadata:{ String: String})
	
	access(all)
	event LandMinted(id: UInt64, typeID: UInt64, serialNumber: UInt64, metadata:{ String: String}, coord: [UInt64])
	
	access(all)
	event PackOpened(id: UInt64, typeID: UInt64, name: String, address: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(self)
	var CryptoZooNFTTypeDict:{ UInt64: CryptoZooNFTTemplate}
	
	access(self)
	var tokenMintedPerTypeID:{ UInt64: UInt64}
	
	access(all)
	resource interface CryptoZooNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCryptoZooNFT(id: UInt64): &CryptoZooNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CryptoZooNFT NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct CryptoZooNFTTemplate{ 
		access(all)
		let isPack: Bool
		
		access(all)
		let typeID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var mintLimit: UInt64
		
		access(all)
		var priceUSD: UFix64
		
		access(all)
		var priceFlow: UFix64
		
		access(all)
		var tokenMinted: UInt64
		
		access(all)
		var isExpired: Bool
		
		access(all)
		var isLand: Bool
		
		access(self)
		var metadata:{ String: String}
		
		access(self)
		var timestamps:{ String: UFix64}
		
		access(self)
		var coordMinted:{ UInt64: [UInt64]}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getTimestamps():{ String: UFix64}{ 
			return self.timestamps
		}
		
		access(all)
		view fun checkIsCoordMinted(coord: [UInt64]): Bool{ 
			if !self.isLand{ 
				return false
			}
			if self.coordMinted.containsKey(coord[0]) && (self.coordMinted[coord[0]]!).contains(coord[1]){ 
				return true
			}
			return false
		}
		
		access(all)
		fun addCoordMinted(coord: [UInt64]){ 
			pre{ 
				!self.checkIsCoordMinted(coord: coord):
					"coord already exists"
				coord.length == 2:
					"invalid coord length"
			}
			if !self.coordMinted.containsKey(coord[0]){ 
				self.coordMinted[coord[0]] = [coord[1]]
			} else{ 
				(self.coordMinted[coord[0]]!).append(coord[1])
			}
		}
		
		access(all)
		fun getCoordMinted():{ UInt64: [UInt64]}{ 
			return self.coordMinted
		}
		
		access(contract)
		fun updatePriceUSD(newPriceUSD: UFix64){ 
			self.priceUSD = newPriceUSD
		}
		
		access(contract)
		fun updatePriceFlow(newPriceFlow: UFix64){ 
			self.priceFlow = newPriceFlow
		}
		
		access(contract)
		fun updateMintLimit(newMintLimit: UInt64){ 
			self.mintLimit = newMintLimit
			self.unExpireNFTTemplate()
		}
		
		access(contract)
		fun updateMetadata(newMetadata:{ String: String}){ 
			self.metadata = newMetadata
		}
		
		access(contract)
		fun updateTimestamps(newTimestamps:{ String: UFix64}){ 
			self.timestamps = newTimestamps
		}
		
		access(contract)
		fun expireNFTTemplate(){ 
			self.isExpired = true
		}
		
		access(contract)
		fun unExpireNFTTemplate(){ 
			self.isExpired = false
		}
		
		init(initTypeID: UInt64, initIsPack: Bool, initName: String, initDescription: String, initMintLimit: UInt64, initPriceUSD: UFix64, initPriceFlow: UFix64, initMetadata:{ String: String}, initTimestamps:{ String: UFix64}, initIsLand: Bool){ 
			self.isPack = initIsPack
			self.typeID = initTypeID
			self.name = initName
			self.description = initDescription
			self.mintLimit = initMintLimit
			self.metadata = initMetadata
			self.timestamps = initTimestamps
			self.priceUSD = initPriceUSD
			self.priceFlow = initPriceFlow
			self.tokenMinted = 0
			self.isExpired = false
			self.isLand = initIsLand
			self.coordMinted ={} 
			emit NFTTemplateCreated(typeID: initTypeID, name: initName, mintLimit: initMintLimit, priceUSD: initPriceUSD, priceFlow: initPriceFlow, metadata: initMetadata, isPack: self.isPack)
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let name: String
		
		access(all)
		let id: UInt64
		
		access(all)
		let typeID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(self)
		let coord: [UInt64]
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.HTTPThumbnail>(), Type<MetadataViews.IPFSThumbnail>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: (self.getNFTTemplate()!).description)
				case Type<MetadataViews.HTTPThumbnail>():
					return MetadataViews.HTTPThumbnail(uri: (self.getNFTTemplate()!).getMetadata()["uri"]!, mimetype: (self.getNFTTemplate()!).getMetadata()["mimetype"]!)
				case Type<MetadataViews.IPFSThumbnail>():
					return MetadataViews.IPFSThumbnail(cid: (self.getNFTTemplate()!).getMetadata()["cid"]!, mimetype: (self.getNFTTemplate()!).getMetadata()["mimetype"]!)
			}
			return nil
		}
		
		access(all)
		fun getNFTTemplate(): CryptoZooNFTTemplate?{ 
			return CryptoZooNFT.CryptoZooNFTTypeDict[self.typeID]
		}
		
		access(all)
		fun getCoord(): [UInt64]{ 
			return self.coord
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initTypeID: UInt64, initName: String, initSerialNumber: UInt64, initCoord: [UInt64]){ 
			self.id = initID
			self.name = initName
			self.typeID = initTypeID
			self.serialNumber = initSerialNumber
			self.coord = initCoord
		}
	}
	
	access(all)
	resource Collection: CryptoZooNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @CryptoZooNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(collection: @Collection){ 
			let keys = collection.getIDs()
			for key in keys{ 
				self.deposit(token: <-collection.withdraw(withdrawID: key))
			}
			destroy collection
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
		fun borrowCryptoZooNFT(id: UInt64): &CryptoZooNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &CryptoZooNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun openPack(packID: UInt64){ 
			pre{ 
				self.ownedNFTs[packID] != nil:
					"invalid packID."
			}
			let packRef = &self.ownedNFTs[packID] as &{NonFungibleToken.NFT}? as! &CryptoZooNFT.NFT
			let packTemplateInfo = packRef.getNFTTemplate()!
			if !packTemplateInfo.isPack{ 
				panic("NFT is not a pack.")
			}
			let pack <- self.ownedNFTs.remove(key: packID)
			emit PackOpened(id: packID, typeID: packTemplateInfo.typeID, name: packTemplateInfo.name, address: self.owner?.address)
			destroy pack
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
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64){ 
			pre{ 
				CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID):
					"invalid typeID"
				!(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).isExpired:
					"sold out"
			}
			let metadata = (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).getMetadata()
			if !CryptoZooNFT.tokenMintedPerTypeID.containsKey(typeID){ 
				CryptoZooNFT.tokenMintedPerTypeID[typeID] = 0 as UInt64
			}
			let serialNumber = CryptoZooNFT.tokenMintedPerTypeID[typeID]! + 1 as UInt64
			emit Minted(id: CryptoZooNFT.totalSupply, typeID: typeID, serialNumber: serialNumber, metadata: metadata)
			recipient.deposit(token: <-create CryptoZooNFT.NFT(initID: CryptoZooNFT.totalSupply, initTypeID: typeID, initName: (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).name, initSerialNumber: serialNumber, initCoord: []))
			CryptoZooNFT.totalSupply = CryptoZooNFT.totalSupply + 1 as UInt64
			if serialNumber >= (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).mintLimit{ 
				(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).expireNFTTemplate()
			}
			CryptoZooNFT.tokenMintedPerTypeID[typeID] = CryptoZooNFT.tokenMintedPerTypeID[typeID]! + 1 as UInt64
		}
		
		access(all)
		fun mintLandNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, coord: [UInt64], nftName: String){ 
			pre{ 
				CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID):
					"invalid typeID"
				!(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).isExpired:
					"sold out"
				coord.length == 2:
					"invalid coord length"
				!(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).checkIsCoordMinted(coord: coord):
					"invalid coord"
			}
			let metadata = (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).getMetadata()
			if !CryptoZooNFT.tokenMintedPerTypeID.containsKey(typeID){ 
				CryptoZooNFT.tokenMintedPerTypeID[typeID] = 0 as UInt64
			}
			let serialNumber = CryptoZooNFT.tokenMintedPerTypeID[typeID]! + 1 as UInt64
			emit LandMinted(id: CryptoZooNFT.totalSupply, typeID: typeID, serialNumber: serialNumber, metadata: metadata, coord: coord)
			recipient.deposit(token: <-create CryptoZooNFT.NFT(initID: CryptoZooNFT.totalSupply, initTypeID: typeID, initName: nftName, initSerialNumber: serialNumber, initCoord: coord))
			CryptoZooNFT.totalSupply = CryptoZooNFT.totalSupply + 1 as UInt64
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).addCoordMinted(coord: coord)
			if serialNumber >= (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).mintLimit{ 
				(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).expireNFTTemplate()
			}
			CryptoZooNFT.tokenMintedPerTypeID[typeID] = CryptoZooNFT.tokenMintedPerTypeID[typeID]! + 1 as UInt64
		}
		
		access(all)
		fun updateTemplateMetadata(typeID: UInt64, newMetadata:{ String: String}): CryptoZooNFT.CryptoZooNFTTemplate{ 
			pre{ 
				CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID) != nil:
					"Token with the typeID does not exist."
			}
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).updateMetadata(newMetadata: newMetadata)
			return CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!
		}
		
		access(all)
		fun createNFTTemplate(typeID: UInt64, isPack: Bool, name: String, description: String, mintLimit: UInt64, priceUSD: UFix64, priceFlow: UFix64, metadata:{ String: String}, timestamps:{ String: UFix64}, isLand: Bool){ 
			pre{ 
				!CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID):
					"NFT template with the same typeID already exists."
			}
			let newNFTTemplate = CryptoZooNFTTemplate(initTypeID: typeID, initIsPack: isPack, initName: name, initDescription: description, initMintLimit: mintLimit, initPriceUSD: priceUSD, initPriceFlow: priceFlow, initMetadata: metadata, initTimestamps: timestamps, initIsLand: isLand)
			CryptoZooNFT.CryptoZooNFTTypeDict[newNFTTemplate.typeID] = newNFTTemplate
		}
		
		access(all)
		fun updateNFTTemplatePriceUSD(typeID: UInt64, newPriceUSD: UFix64){ 
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).updatePriceUSD(newPriceUSD: newPriceUSD)
		}
		
		access(all)
		fun updateNFTTemplatePriceFlow(typeID: UInt64, newPriceFlow: UFix64){ 
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).updatePriceFlow(newPriceFlow: newPriceFlow)
		}
		
		access(all)
		fun updateNFTTemplateMintLimit(typeID: UInt64, newMintLimit: UInt64){ 
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).updateMintLimit(newMintLimit: newMintLimit)
		}
		
		access(all)
		fun expireNFTTemplate(typeID: UInt64){ 
			(CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).expireNFTTemplate()
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	fun checkMintLimit(typeID: UInt64): UInt64?{ 
		if let token = CryptoZooNFT.CryptoZooNFTTypeDict[typeID]{ 
			return token.mintLimit
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun checkNFTTemplates(): [CryptoZooNFTTemplate]{ 
		return CryptoZooNFT.CryptoZooNFTTypeDict.values
	}
	
	access(all)
	fun checkNFTTemplatesTypeIDs(): [UInt64]{ 
		return CryptoZooNFT.CryptoZooNFTTypeDict.keys
	}
	
	access(all)
	fun isNFTTemplateExpired(typeID: UInt64): Bool{ 
		if !CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID){ 
			return true
		}
		return (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).isExpired
	}
	
	access(all)
	fun isNFTTemplateExist(typeID: UInt64): Bool{ 
		if CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID){ 
			return true
		}
		return false
	}
	
	access(all)
	fun getNFTTemplateMetadata(typeID: UInt64):{ String: String}{ 
		if !CryptoZooNFT.CryptoZooNFTTypeDict.containsKey(typeID){ 
			panic("invalid typeID")
		}
		return (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).getMetadata()
	}
	
	access(all)
	fun getNFTTemplateByTypeID(typeID: UInt64): CryptoZooNFTTemplate{ 
		return CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!
	}
	
	access(all)
	view fun checkIsCoordMinted(typeID: UInt64, coord: [UInt64]): Bool{ 
		return (CryptoZooNFT.CryptoZooNFTTypeDict[typeID]!).checkIsCoordMinted(coord: coord)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/CryptoZooCollection
		self.CollectionPublicPath = /public/CryptoZooCollection
		self.AdminStoragePath = /storage/CryptoZooAdmin
		self.totalSupply = 0
		self.tokenMintedPerTypeID ={} 
		self.CryptoZooNFTTypeDict ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
