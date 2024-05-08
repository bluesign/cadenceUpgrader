import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import RaptaAccessory from "./RaptaAccessory.cdc"

access(all)
contract RaptaIcon: NonFungibleToken{ 
	
	//STORAGE PATHS
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//EVENTS
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event AccessoryAdded(raptaIconId: UInt64, accessory: String)
	
	access(all)
	event AccessoryRemoved(raptaIconId: UInt64, accessory: String)
	
	access(all)
	event Updated(iconId: UInt64)
	
	//VARIABLES
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var dynamicImage: String
	
	access(all)
	var png: String
	
	access(all)
	var layer: String
	
	access(all)
	var royalties: [Royalty]
	
	access(account)
	var royaltyCut: UFix64
	
	access(account)
	var marketplaceCut: UFix64
	
	//ENUMERABLES
	access(all)
	enum RoyaltyType: UInt8{ 
		access(all)
		case fixed
		
		access(all)
		case percentage
	}
	
	//STRUCTS
	access(all)
	struct Royalties{ 
		access(all)
		let royalty: [Royalty]
		
		init(royalty: [Royalty]){ 
			self.royalty = royalty
		}
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cut: UFix64
		
		access(all)
		let type: RoyaltyType
		
		init(wallet: Capability<&{FungibleToken.Receiver}>, cut: UFix64, type: RoyaltyType){ 
			self.wallet = wallet
			self.cut = cut
			self.type = type
		}
	}
	
	access(all)
	struct IconData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let accessories: &{String: RaptaAccessory.NFT}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, accessories: &{String: RaptaAccessory.NFT}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.accessories = accessories
		}
	}
	
	//INTERFACES
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		fun getAccessories(): &{String: RaptaAccessory.NFT}
		
		access(all)
		fun getPng(): String
	}
	
	access(all)
	resource interface Private{ 
		access(all)
		fun addAccessory(accessory: @RaptaAccessory.NFT): @RaptaAccessory.NFT?
		
		access(all)
		fun removeAccessory(category: String): @RaptaAccessory.NFT?
		
		access(contract)
		fun toggleThumbnail()
		
		access(contract)
		fun updatePNG(newPNG: String)
		
		access(contract)
		fun updateLayer(newLayer: String)
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
		fun borrowIcon(id: UInt64): &RaptaIcon.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Rapta reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	//RESOURCES
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, Private, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// ipfs base image
		access(all)
		var png: String
		
		// base layer without accessories
		access(all)
		var layer: String
		
		// dynamic image compiled according to accessories
		access(all)
		var dynamicImage: String
		
		// public image (dymanic vs png) 
		access(all)
		var thumbnail: String
		
		access(contract)
		let accessories: @{String: RaptaAccessory.NFT}
		
		access(contract)
		let royalties: Royalties
		
		init(royalties: Royalties){ 
			RaptaIcon.totalSupply = RaptaIcon.totalSupply + 1
			self.id = RaptaIcon.totalSupply
			self.name = "Rapta Icon"
			self.description = "the icon is a clay-character representation of Rapta in his 2022 era, designed by @krovenn."
			self.png = RaptaIcon.png
			self.layer = RaptaIcon.layer
			self.dynamicImage = RaptaIcon.dynamicImage.concat(self.id.toString().concat(".png"))
			self.thumbnail = self.png
			self.accessories <-{ "jacket": <-RaptaAccessory.initialAccessories(templateId: 1), "pants": <-RaptaAccessory.initialAccessories(templateId: 2), "shoes": <-RaptaAccessory.initialAccessories(templateId: 3)}
			self.royalties = royalties
			emit Mint(id: self.id)
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getName(): String{ 
			return self.name
		}
		
		access(all)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(all)
		fun getPng(): String{ 
			return self.png
		}
		
		access(all)
		fun getThumbnail(): String{ 
			return self.thumbnail
		}
		
		access(all)
		fun getAccessories(): &{String: RaptaAccessory.NFT}{ 
			return &self.accessories as &{String: RaptaAccessory.NFT}
		}
		
		access(all)
		fun addAccessory(accessory: @RaptaAccessory.NFT): @RaptaAccessory.NFT?{ 
			let id: UInt64 = accessory.id
			let category = accessory.getCategory()
			let name = accessory.getName()
			let removedAccessory <- self.accessories[category] <- accessory
			emit AccessoryAdded(raptaIconId: self.id, accessory: name)
			return <-removedAccessory
		}
		
		access(all)
		fun removeAccessory(category: String): @RaptaAccessory.NFT?{ 
			let removedAccessory <- self.accessories.remove(key: category)!
			emit AccessoryRemoved(raptaIconId: self.id, accessory: category)
			return <-removedAccessory
		}
		
		access(all)
		fun toggleThumbnail(){ 
			if self.thumbnail == self.png{ 
				self.thumbnail = self.dynamicImage
			} else if self.thumbnail == self.dynamicImage{ 
				self.thumbnail = self.png
			} else{ 
				self.thumbnail = self.png
			}
		}
		
		access(contract)
		fun updateLayer(newLayer: String){ 
			self.layer = newLayer
		}
		
		access(contract)
		fun updatePNG(newPNG: String){ 
			self.png = newPNG
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://eqmusic.io/rapta/icons/".concat(self.id.toString()).concat(".png"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: RaptaIcon.CollectionStoragePath, publicPath: RaptaIcon.CollectionPublicPath, publicCollection: Type<&RaptaIcon.Collection>(), publicLinkedType: Type<&RaptaIcon.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-RaptaIcon.createEmptyCollection(nftType: Type<@RaptaIcon.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://eqmusic.io/media/raptaCollection.png"), mediaType: "image/png+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The Rapta Collection", description: "444 icons. collect and get access to exclusive offerings and interactive experiences with Rapta.", externalURL: MetadataViews.ExternalURL("https://eqmusic.io/rapta"), squareImage: media, bannerImage: media, socials:{ "hoo.be": MetadataViews.ExternalURL("https://hoo.be/rapta"), "twitter": MetadataViews.ExternalURL("https://twitter.com/_rapta"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/rapta")})
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					var count: Int = 0
					for royalty in self.royalties.royalty{ 
						royalties.append(MetadataViews.Royalty(receiver: royalty.wallet, cut: royalty.cut, description: "Rapta Icon Royalty ".concat(count.toString())))
						count = count + Int(1)
					}
					return MetadataViews.Royalties(royalties)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let id: UInt64 = token.id
			let token <- token as! @RaptaIcon.NFT
			let removedToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy removedToken
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist in this collection.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
		fun borrowIcon(id: UInt64): &RaptaIcon.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &RaptaIcon.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowIconPrivate(id: UInt64): &{RaptaIcon.Private}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &RaptaIcon.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist"
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let RaptaIcon = nft as! &RaptaIcon.NFT
			return RaptaIcon as &{ViewResolver.Resolver}
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
	resource Admin{ 
		access(all)
		fun mintIcon(user: Address): @NFT{ 
			pre{ 
				RaptaIcon.totalSupply < 444:
					"This collection is sold out"
			}
			let acct = getAccount(user)
			let collection = acct.capabilities.get<&RaptaIcon.Collection>(RaptaIcon.CollectionPublicPath).borrow()!
			let icons = collection.getIDs().length
			return <-create NFT(royalties: Royalties(royalty: RaptaIcon.royalties))
		}
		
		access(all)
		fun mintAccessory(templateId: UInt64): @RaptaAccessory.NFT{ 
			let accessory <- RaptaAccessory.mintAccessory(templateId: templateId)
			return <-accessory
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(all)
		fun updateContractPng(newPng: String){ 
			RaptaIcon.png = newPng
		}
		
		access(all)
		fun updateIconLayer(user: AuthAccount, id: UInt64, newLayer: String){ 
			let icon = (user.borrow<&RaptaIcon.Collection>(from: RaptaIcon.CollectionStoragePath)!).borrowIcon(id: id)!
			icon.updateLayer(newLayer: newLayer)
			emit Updated(iconId: id)
		}
		
		access(all)
		fun updateIconPng(user: AuthAccount, id: UInt64, newPNG: String){ 
			let icon = (user.borrow<&RaptaIcon.Collection>(from: RaptaIcon.CollectionStoragePath)!).borrowIcon(id: id)!
			icon.updatePNG(newPNG: newPNG)
			emit Updated(iconId: id)
		}
		
		access(all)
		fun setRoyaltyCut(value: UFix64){ 
			RaptaIcon.setRoyaltyCut(value: value)
		}
		
		access(all)
		fun setMarketplaceCut(value: UFix64){ 
			RaptaIcon.setMarketplaceCut(value: value)
		}
		
		access(all)
		fun createAccessoryTemplate(name: String, description: String, category: String, mintLimit: UInt64, png: String, layer: String){ 
			RaptaAccessory.createAccessoryTemplate(name: name, description: description, category: category, mintLimit: mintLimit, png: png, layer: layer)
		}
		
		access(all)
		fun setRoyalites(newRoyalties: [Royalty]): [RaptaIcon.Royalty]{ 
			RaptaIcon.setRoyalites(newRoyalties: newRoyalties)
			return RaptaIcon.royalties
		}
	}
	
	//FUNCTIONS
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getRoyaltyCut(): UFix64{ 
		return self.royaltyCut
	}
	
	access(all)
	fun getMarketplaceCut(): UFix64{ 
		return self.marketplaceCut
	}
	
	access(account)
	fun setRoyaltyCut(value: UFix64){ 
		self.royaltyCut = value
	}
	
	access(account)
	fun setMarketplaceCut(value: UFix64){ 
		self.marketplaceCut = value
	}
	
	access(account)
	fun setRoyalites(newRoyalties: [Royalty]): [RaptaIcon.Royalty]{ 
		self.royalties = newRoyalties
		return self.royalties
	}
	
	access(all)
	fun addAccessory(account: AuthAccount, iconId: UInt64, accessoryId: UInt64){ 
		let iconCollection: &RaptaIcon.Collection = account.borrow<&RaptaIcon.Collection>(from: RaptaIcon.CollectionStoragePath)!
		let accessories: &RaptaAccessory.Collection = account.borrow<&RaptaAccessory.Collection>(from: RaptaAccessory.CollectionStoragePath)!
		let accessory: @RaptaAccessory.NFT <- accessories.withdraw(withdrawID: accessoryId) as! @RaptaAccessory.NFT
		let icon: &{RaptaIcon.Private} = iconCollection.borrowIcon(id: iconId)!
		let accessorize <- icon.addAccessory(accessory: <-accessory)
		if accessorize != nil{ 
			accessories.deposit(token: <-accessorize!)
		} else{ 
			destroy accessorize
		}
		emit Updated(iconId: iconId)
	}
	
	access(all)
	fun removeAccessory(account: AuthAccount, iconId: UInt64, category: String){ 
		let icon: &RaptaIcon.NFT = (account.borrow<&RaptaIcon.Collection>(from: RaptaIcon.CollectionStoragePath)!).borrowIcon(id: iconId)!
		let accessories: &RaptaAccessory.Collection = account.borrow<&RaptaAccessory.Collection>(from: RaptaAccessory.CollectionStoragePath)!
		let removedAccessory <- icon.removeAccessory(category: category)
		if removedAccessory != nil{ 
			accessories.deposit(token: <-removedAccessory!)
		} else{ 
			destroy removedAccessory
		}
	}
	
	access(all)
	fun mintIcon(user: Address): @NFT{ 
		pre{ 
			RaptaIcon.totalSupply < 444:
				"This collection is sold out"
		}
		let acct = getAccount(user)
		let collection = acct.capabilities.get<&RaptaIcon.Collection>(RaptaIcon.CollectionPublicPath).borrow()!
		let icons = collection.getIDs().length
		if icons >= 1{ 
			panic("This collection only allows one mint per wallet")
		}
		return <-create NFT(royalties: Royalties(royalty: RaptaIcon.royalties))
	}
	
	//INITIALIZER
	init(){ 
		self.CollectionPublicPath = /public/RaptaIconCollection
		self.CollectionStoragePath = /storage/RaptaIconCollection
		self.AdminStoragePath = /storage/RaptaIconAdmin
		self.totalSupply = 0
		self.dynamicImage = "https://eqmusic.io/rapta/icons/"
		self.png = "https://ipfs.io/ipfs/QmQS5yghWJGHSohUqy1M1yR2QDTq3cUJKifQMXopdgQdsV"
		self.layer = "raptaBaseLayer.png"
		self.royalties = []
		self.royaltyCut = 0.025
		self.marketplaceCut = 0.05
		self.account.storage.save(<-create Admin(), to: RaptaIcon.AdminStoragePath)
		self.account.storage.save(<-RaptaIcon.createEmptyCollection(nftType: Type<@RaptaIcon.Collection>()), to: RaptaIcon.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&RaptaIcon.Collection>(RaptaIcon.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: RaptaIcon.CollectionPublicPath)
		emit ContractInitialized()
	}
}
