// SPDX-License-Identifier: MIT
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract KlktnVoucher: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event VoucherTemplateCreated(templateID: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, templateID: UInt64, serialNumber: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextTemplateID: UInt64
	
	access(self)
	var KlktnVoucherTemplates:{ UInt64: KlktnVoucherTemplate}
	
	access(all)
	resource interface KlktnVoucherCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowKlktnVoucher(id: UInt64): &KlktnVoucher.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow KlktnVoucher reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct KlktnVoucherTemplate{ 
		access(all)
		let templateID: UInt64
		
		access(all)
		var description: String
		
		access(all)
		var uri: String
		
		access(all)
		var mintLimit: UInt64
		
		access(all)
		var nextSerialNumber: UInt64
		
		access(all)
		fun updateUri(uri: String){ 
			self.uri = uri
		}
		
		access(all)
		fun incrementNextSerialNumber(){ 
			self.nextSerialNumber = self.nextSerialNumber + UInt64(1)
		}
		
		init(templateID: UInt64, description: String, uri: String, mintLimit: UInt64){ 
			self.templateID = templateID
			self.description = description
			self.uri = uri
			self.mintLimit = mintLimit
			self.nextSerialNumber = 1
			KlktnVoucher.nextTemplateID = KlktnVoucher.nextTemplateID + 1
			emit VoucherTemplateCreated(templateID: self.templateID)
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Klktn Voucher", description: self.getTemplate().description, thumbnail: MetadataViews.HTTPFile(url: self.getTemplate().uri))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("http://www.mangakollektion.xyz/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: KlktnVoucher.CollectionStoragePath, publicPath: KlktnVoucher.CollectionPublicPath, publicCollection: Type<&KlktnVoucher.Collection>(), publicLinkedType: Type<&KlktnVoucher.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-KlktnVoucher.createEmptyCollection(nftType: Type<@KlktnVoucher.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: ""), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "KlktnVoucher", description: "Building the largest community of manga and anime fans through a new web3 powered collectible brand.", externalURL: MetadataViews.ExternalURL("http://www.mangakollektion.xyz/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/MangaKollektion")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
			}
			return nil
		}
		
		access(all)
		fun getTemplate(): KlktnVoucherTemplate{ 
			return KlktnVoucher.KlktnVoucherTemplates[self.templateID]!
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initTemplateID: UInt64, serialNumber: UInt64){ 
			self.id = initID
			self.templateID = initTemplateID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource Collection: KlktnVoucherCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @KlktnVoucher.NFT
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
		fun borrowKlktnVoucher(id: UInt64): &KlktnVoucher.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &KlktnVoucher.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &KlktnVoucher.NFT
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
	resource Admin{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, templateID: UInt64){ 
			pre{ 
				KlktnVoucher.KlktnVoucherTemplates[templateID] != nil:
					"Template does not exist"
				(KlktnVoucher.KlktnVoucherTemplates[templateID]!).mintLimit >= (KlktnVoucher.KlktnVoucherTemplates[templateID]!).nextSerialNumber:
					"Mint limit reached"
			}
			let KlktnVoucherTemplate = KlktnVoucher.KlktnVoucherTemplates[templateID]!
			let newNFT <- create KlktnVoucher.NFT(initID: KlktnVoucher.totalSupply, initTemplateID: templateID, serialNumber: KlktnVoucherTemplate.nextSerialNumber)
			emit Mint(id: newNFT.id, templateID: templateID, serialNumber: newNFT.serialNumber)
			recipient.deposit(token: <-newNFT)
			
			// Increment total supply & nextSerialNumber
			KlktnVoucher.totalSupply = KlktnVoucher.totalSupply + 1
			(KlktnVoucher.KlktnVoucherTemplates[templateID]!).incrementNextSerialNumber()
		}
		
		access(all)
		fun createKlktnVoucherTemplate(description: String, uri: String, mintLimit: UInt64){ 
			KlktnVoucher.KlktnVoucherTemplates[KlktnVoucher.nextTemplateID] = KlktnVoucherTemplate(templateID: KlktnVoucher.nextTemplateID, description: description, uri: uri, mintLimit: mintLimit)
		}
		
		access(all)
		fun updateKlktnVoucherUri(templateID: UInt64, uri: String){ 
			pre{ 
				KlktnVoucher.KlktnVoucherTemplates.containsKey(templateID) != nil:
					"Template does not exits."
			}
			(KlktnVoucher.KlktnVoucherTemplates[templateID]!).updateUri(uri: uri)
		}
	}
	
	access(all)
	fun getKlktnVoucherTemplateByID(templateID: UInt64): KlktnVoucher.KlktnVoucherTemplate{ 
		return KlktnVoucher.KlktnVoucherTemplates[templateID]!
	}
	
	access(all)
	fun getKlktnVoucherTemplates():{ UInt64: KlktnVoucher.KlktnVoucherTemplate}{ 
		return KlktnVoucher.KlktnVoucherTemplates
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/KlktnVoucherCollection
		self.CollectionPublicPath = /public/KlktnVoucherCollection
		self.AdminStoragePath = /storage/KlktnVoucherAdmin
		self.totalSupply = 1
		self.nextTemplateID = 1
		self.KlktnVoucherTemplates ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
