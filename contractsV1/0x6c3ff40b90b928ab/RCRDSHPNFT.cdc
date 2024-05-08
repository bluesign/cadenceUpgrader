import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract RCRDSHPNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Burn(id: UInt64, from: Address?)
	
	access(all)
	event Sale(id: UInt64, price: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Serial>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = self.metadata
			fun getMetaValue(_ key: String, _ defaultVal: String): String{ 
				return metadata[key] ?? defaultVal
			}
			fun getThumbnail(): MetadataViews.HTTPFile{ 
				let url = metadata["uri"] == nil ? "https://rcrdshp-happyfox-assets.s3.amazonaws.com/Purple.svg" : (metadata["uri"]!).concat("/thumbnail")
				return MetadataViews.HTTPFile(url: url)
			}
			fun createGenericDisplay(): MetadataViews.Display{ 
				let name = getMetaValue("name", "?RCRDSHP NFT?")
				let serial = getMetaValue("serial_number", "?")
				return MetadataViews.Display(name: name, description: getMetaValue("description", "An unknown RCRDSHP Collection NFT"), thumbnail: getThumbnail())
			}
			fun createVoucherDisplay(): MetadataViews.Display{ 
				let name = getMetaValue("name", "?RCRDSHP Voucher NFT?")
				let serial = getMetaValue("voucher_serial_number", "?")
				let isFlowFest = name.slice(from: 0, upTo: 9) == "Flow fest"
				return MetadataViews.Display(name: name.concat(" #").concat(serial), description: getMetaValue("description", "An unknown RCRDSHP Collection Vouncher NFT"), thumbnail: isFlowFest ? MetadataViews.HTTPFile(url: "https://rcrdshp-happyfox-assets.s3.amazonaws.com/flowfest-pack.png") : getThumbnail())
			}
			fun createTraits(): MetadataViews.Traits{ 
				let rarity = metadata["rarity"]
				if rarity == nil{ 
					return MetadataViews.Traits([])
				} else{ 
					let rarityTrait = MetadataViews.Trait(name: "Rarity", value: rarity!, displayType: nil, rarity: nil)
					return MetadataViews.Traits([rarityTrait])
				}
			}
			fun createExternalURL(): MetadataViews.ExternalURL{ 
				return MetadataViews.ExternalURL(metadata["uri"] ?? "https://app.rcrdshp.com")
			}
			fun createCollectionData(): MetadataViews.NFTCollectionData{ 
				return MetadataViews.NFTCollectionData(storagePath: RCRDSHPNFT.collectionStoragePath, publicPath: RCRDSHPNFT.collectionPublicPath, publicCollection: Type<&RCRDSHPNFT.Collection>(), publicLinkedType: Type<&RCRDSHPNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-RCRDSHPNFT.createEmptyCollection(nftType: Type<@RCRDSHPNFT.Collection>())
					})
			}
			fun createCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
				let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://rcrdshp-happyfox-assets.s3.amazonaws.com/Purple.svg"), mediaType: "image/svg+xml")
				let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://rcrdshp-happyfox-assets.s3.amazonaws.com/banner.png"), mediaType: "image/png")
				return MetadataViews.NFTCollectionDisplay(name: "The RCRDSHP Collection", description: "Here comes the drop!", externalURL: MetadataViews.ExternalURL("https://app.rcrdshp.com"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/rcrdshp"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/rcrdshp"), "discord": MetadataViews.ExternalURL("https://discord.gg/rcrdshp"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/rcrdshp")})
			}
			fun createRoyalties(): MetadataViews.Royalties{ 
				let royalties: [MetadataViews.Royalty] = []
				return MetadataViews.Royalties(royalties)
			}
			fun parseUInt64(_ string: String): UInt64?{ 
				let chars:{ Character: UInt64} ={ "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9}
				var number: UInt64 = 0
				var i = 0
				while i < string.length{ 
					if let n = chars[string[i]]{ 
						number = number * 10 + n
					} else{ 
						return nil
					}
					i = i + 1
				}
				return number
			}
			switch view{ 
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(parseUInt64(getMetaValue("serial_number", "0")) ?? 0)
				case Type<MetadataViews.Display>():
					return metadata["type"] == "Voucher" ? createVoucherDisplay() : createGenericDisplay()
				case Type<MetadataViews.ExternalURL>():
					return createExternalURL()
				case Type<MetadataViews.NFTCollectionData>():
					return createCollectionData()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return createCollectionDisplay()
				case Type<MetadataViews.Royalties>():
					return createRoyalties()
				case Type<MetadataViews.Traits>():
					return createTraits()
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface RCRDSHPNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowRCRDSHPNFT(id: UInt64): &RCRDSHPNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow RCRDSHPNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: RCRDSHPNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("withdraw - missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @RCRDSHPNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun sale(id: UInt64, price: UInt64): @{NonFungibleToken.NFT}{ 
			emit Sale(id: id, price: price)
			return <-self.withdraw(withdrawID: id)
		}
		
		access(all)
		fun burn(burnID: UInt64){ 
			let token <- self.ownedNFTs.remove(key: burnID) ?? panic("burn - missing NFT")
			emit Burn(id: token.id, from: self.owner?.address)
			destroy token
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
		fun borrowRCRDSHPNFT(id: UInt64): &RCRDSHPNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &RCRDSHPNFT.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let rcrdshpNFT = nft as! &RCRDSHPNFT.NFT
			return rcrdshpNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, meta:{ String: String}){ 
			var newNFT <- create NFT(initID: RCRDSHPNFT.totalSupply, metadata: meta)
			recipient.deposit(token: <-newNFT)
			RCRDSHPNFT.totalSupply = RCRDSHPNFT.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.minterStoragePath = /storage/RCRDSHPNFTMinter
		self.collectionStoragePath = /storage/RCRDSHPNFTCollection
		self.collectionPublicPath = /public/RCRDSHPNFTCollection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.collectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&RCRDSHPNFT.Collection>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.collectionPublicPath)
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		emit ContractInitialized()
	}
}
