//import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
//import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
//import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
//import FlovatarDustCollectibleTemplate from "./FlovatarDustCollectibleTemplate.cdc"
//import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlovatarDustCollectibleTemplate from "./FlovatarDustCollectibleTemplate.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlovatarDustToken from "./FlovatarDustToken.cdc"

/*

 This contract defines the Flovatar Dust Collectible Accessory NFT and the Collection to manage them.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

access(all)
contract FlovatarDustCollectibleAccessory: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Counter for all the Components ever minted
	access(all)
	var totalSupply: UInt64
	
	// Standard events that will be emitted
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, templateId: UInt64, mint: UInt64)
	
	access(all)
	event Destroyed(id: UInt64, templateId: UInt64)
	
	// The public interface provides all the basic informations about
	// the Component and also the Template ID associated with it.
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData
		
		access(all)
		fun getSvg(): String
		
		access(all)
		fun getSeries(): UInt64
		
		access(all)
		fun getRarity(): String
		
		access(all)
		fun getMetadata():{ String: String}
		
		access(all)
		fun getLayer(): UInt32
		
		access(all)
		fun getBasePrice(): UFix64
		
		access(all)
		fun getCurrentPrice(): UFix64
		
		access(all)
		fun getTotalMinted(): UInt64
		
		//these three are added because I think they will be in the standard. At least Dieter thinks it will be needed
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
	}
	
	// The NFT resource that implements the Public interface as well
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		// Initiates the NFT from a Template ID.
		init(templateId: UInt64){ 
			FlovatarDustCollectibleAccessory.totalSupply = FlovatarDustCollectibleAccessory.totalSupply + UInt64(1)
			let collectibleTemplate = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
			self.id = FlovatarDustCollectibleAccessory.totalSupply
			self.templateId = templateId
			self.mint = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)! + UInt64(1)
			self.name = collectibleTemplate.name
			self.description = collectibleTemplate.description
			self.schema = nil
			
			// Increments the counter and stores the timestamp
			FlovatarDustCollectibleTemplate.setTotalMintedComponents(id: templateId, value: self.mint)
			FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
			FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: templateId)
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		// Returns the Template associated to the current Component
		access(all)
		fun getTemplate(): FlovatarDustCollectibleTemplate.CollectibleTemplateData{ 
			return FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: self.templateId)!
		}
		
		// Gets the SVG from the parent Template
		access(all)
		fun getSvg(): String{ 
			return self.getTemplate().svg!
		}
		
		// Gets the series number from the parent Template
		access(all)
		fun getSeries(): UInt64{ 
			return self.getTemplate().series
		}
		
		// Gets the rarity from the parent Template
		access(all)
		fun getRarity(): String{ 
			return self.getTemplate().rarity
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.getTemplate().metadata
		}
		
		access(all)
		fun getLayer(): UInt32{ 
			return self.getTemplate().layer
		}
		
		access(all)
		fun getBasePrice(): UFix64{ 
			return self.getTemplate().basePrice
		}
		
		access(all)
		fun getCurrentPrice(): UFix64{ 
			return self.getTemplate().currentPrice
		}
		
		access(all)
		fun getTotalMinted(): UInt64{ 
			return self.getTemplate().totalMintedComponents
		}
		
		// Emit a Destroyed event when it will be burned to create a Flovatar
		// This will help to keep track of how many Components are still
		// available on the market.
		access(all)
		view fun getViews(): [Type]{ 
			var views: [Type] = []
			views.append(Type<MetadataViews.NFTCollectionData>())
			views.append(Type<MetadataViews.NFTCollectionDisplay>())
			views.append(Type<MetadataViews.Display>())
			views.append(Type<MetadataViews.Royalties>())
			views.append(Type<MetadataViews.Edition>())
			views.append(Type<MetadataViews.ExternalURL>())
			views.append(Type<MetadataViews.Serial>())
			views.append(Type<MetadataViews.Traits>())
			return views
		}
		
		access(all)
		fun resolveView(_ type: Type): AnyStruct?{ 
			if type == Type<MetadataViews.ExternalURL>(){ 
				return MetadataViews.ExternalURL("https://flovatar.com")
			}
			if type == Type<MetadataViews.Royalties>(){ 
				let royalties: [MetadataViews.Royalty] = []
				royalties.append(MetadataViews.Royalty(receiver: FlovatarDustCollectibleAccessory.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, description: "Flovatar Royalty"))
				return MetadataViews.Royalties(royalties)
			}
			if type == Type<MetadataViews.Serial>(){ 
				return MetadataViews.Serial(self.id)
			}
			if type == Type<MetadataViews.Editions>(){ 
				let componentTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = self.getTemplate()
				let editionInfo = MetadataViews.Edition(name: "Flovatar Dust Collectible Accessory", number: self.mint, max: componentTemplate.maxMintableComponents)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(editionList)
			}
			if type == Type<MetadataViews.NFTCollectionDisplay>(){ 
				let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo.svg"), mediaType: "image/svg+xml")
				let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo-horizontal.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "Flovatar Dust Collectible Accessory", description: "The Flovatar Stardust Collectibles Accessories allow you customize and make your beloved Stardust Collectible even more unique and exclusive.", externalURL: MetadataViews.ExternalURL("https://flovatar.com"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"), "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"), "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")})
			}
			if type == Type<MetadataViews.Display>(){ 
				return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://flovatar.com/api/image/template/".concat(self.templateId.toString())))
			}
			if type == Type<MetadataViews.Traits>(){ 
				let traits: [MetadataViews.Trait] = []
				let template = self.getTemplate()
				let trait = MetadataViews.Trait(name: "Name", value: template.name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: template.rarity))
				traits.append(trait)
				return MetadataViews.Traits(traits)
			}
			if type == Type<MetadataViews.Rarity>(){ 
				let template = self.getTemplate()
				return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
			}
			if type == Type<MetadataViews.NFTCollectionData>(){ 
				return MetadataViews.NFTCollectionData(storagePath: FlovatarDustCollectibleAccessory.CollectionStoragePath, publicPath: FlovatarDustCollectibleAccessory.CollectionPublicPath, publicCollection: Type<&FlovatarDustCollectibleAccessory.Collection>(), publicLinkedType: Type<&FlovatarDustCollectibleAccessory.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.Collection>())
					})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Standard NFT collectionPublic interface that can also borrowCollectibleAccessory as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Component reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Main Collection to manage all the Components NFT
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlovatarDustCollectibleAccessory.NFT
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
		
		// borrowCollectibleAccessory returns a borrowed reference to a FlovatarComponent
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowCollectibleAccessory(id: UInt64): &FlovatarDustCollectibleAccessory.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlovatarDustCollectibleAccessory.NFT
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
			let componentNFT = nft as! &FlovatarDustCollectibleAccessory.NFT
			return componentNFT as &{ViewResolver.Resolver}
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
	
	// This struct is used to send a data representation of the Components
	// when retrieved using the contract helper methods outside the collection.
	access(all)
	struct CollectibleAccessoryData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let mint: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let rarity: String
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let layer: UInt32
		
		access(all)
		let basePrice: UFix64
		
		access(all)
		let currentPrice: UFix64
		
		access(all)
		let totalMinted: UInt64
		
		init(id: UInt64, templateId: UInt64, mint: UInt64){ 
			self.id = id
			self.templateId = templateId
			self.mint = mint
			let collectibleTemplate = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
			self.name = collectibleTemplate.name
			self.description = collectibleTemplate.description
			self.rarity = collectibleTemplate.rarity
			self.metadata = collectibleTemplate.metadata
			self.layer = collectibleTemplate.layer
			self.basePrice = collectibleTemplate.basePrice
			self.currentPrice = collectibleTemplate.currentPrice
			self.totalMinted = collectibleTemplate.totalMintedComponents
		}
	}
	
	// Get the SVG of a specific Component from an account and the ID
	access(all)
	fun getSvgForComponent(address: Address, componentId: UInt64): String?{ 
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(self.CollectionPublicPath).borrow<&FlovatarDustCollectibleAccessory.Collection>(){ 
			return (componentCollection.borrowCollectibleAccessory(id: componentId)!).getSvg()
		}
		return nil
	}
	
	// Get a specific Component from an account and the ID as CollectibleAccessoryData
	access(all)
	fun getAccessory(address: Address, componentId: UInt64): CollectibleAccessoryData?{ 
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(self.CollectionPublicPath).borrow<&FlovatarDustCollectibleAccessory.Collection>(){ 
			if let component = componentCollection.borrowCollectibleAccessory(id: componentId){ 
				return CollectibleAccessoryData(id: componentId, templateId: (component!).templateId, mint: (component!).mint)
			}
		}
		return nil
	}
	
	// Get an array of all the components in a specific account as CollectibleAccessoryData
	access(all)
	fun getAccessories(address: Address): [CollectibleAccessoryData]{ 
		var componentData: [CollectibleAccessoryData] = []
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&FlovatarDustCollectibleAccessory.Collection>(self.CollectionPublicPath).borrow<&FlovatarDustCollectibleAccessory.Collection>(){ 
			for id in componentCollection.getIDs(){ 
				var component = componentCollection.borrowCollectibleAccessory(id: id)
				componentData.append(CollectibleAccessoryData(id: id, templateId: (component!).templateId, mint: (component!).mint))
			}
		}
		return componentData
	}
	
	//This method is used to mint a new Dust Accessory by paying the necessary amount of DUST
	// The only parameters are the parent Template ID and the vault with the DUST token. It will return a Component NFT resource
	access(all)
	fun createCollectibleAccessory(templateId: UInt64, vault: @{FungibleToken.Vault}): @FlovatarDustCollectibleAccessory.NFT{ 
		pre{ 
			vault.isInstance(Type<@FlovatarDustToken.Vault>()):
				"Vault not of the right Token Type"
		}
		let collectibleTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
		let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)!
		
		// Makes sure that the original minting limit set for each Template has not been reached
		if totalMintedComponents >= collectibleTemplate.maxMintableComponents{ 
			panic("Reached maximum mintable components for this template")
		}
		if vault.balance < FlovatarDustCollectibleTemplate.getTemplateCurrentPrice(id: templateId)!{ 
			panic("Price mismatch between the current price and amount paid")
		}
		var newNFT <- create NFT(templateId: templateId)
		emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)
		destroy vault
		return <-newNFT
	}
	
	access(account)
	fun createCollectibleAccessoryInternal(templateId: UInt64): @FlovatarDustCollectibleAccessory.NFT{ 
		let collectibleTemplate: FlovatarDustCollectibleTemplate.CollectibleTemplateData = FlovatarDustCollectibleTemplate.getCollectibleTemplate(id: templateId)!
		let totalMintedComponents: UInt64 = FlovatarDustCollectibleTemplate.getTotalMintedComponents(id: templateId)!
		
		// Makes sure that the original minting limit set for each Template has not been reached
		if totalMintedComponents >= collectibleTemplate.maxMintableComponents{ 
			panic("Reached maximum mintable components for this template")
		}
		FlovatarDustCollectibleTemplate.increaseTotalMintedComponents(id: templateId)
		FlovatarDustCollectibleTemplate.increaseTemplatesCurrentPrice(id: templateId)
		FlovatarDustCollectibleTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
		var newNFT <- create NFT(templateId: templateId)
		emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)
		return <-newNFT
	}
	
	// This method can only be called from another contract in the same account.
	// In FlovatarComponent case it is called from the Flovatar Dust Collectible Admin that is used
	// to administer the components.
	// This function will batch create multiple Components and pass them back as a Collection
	access(account)
	fun batchCreateCollectibleAccessory(templateId: UInt64, quantity: UInt64): @Collection{ 
		let newCollection <- create Collection()
		var i: UInt64 = 0
		while i < quantity{ 
			newCollection.deposit(token: <-self.createCollectibleAccessoryInternal(templateId: templateId))
			i = i + UInt64(1)
		}
		return <-newCollection
	}
	
	init(){ 
		self.CollectionPublicPath = /public/FlovatarDustCollectibleAccessoryCollection
		self.CollectionStoragePath = /storage/FlovatarDustCollectibleAccessoryCollection
		
		// Initialize the total supply
		self.totalSupply = UInt64(0)
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-FlovatarDustCollectibleAccessory.createEmptyCollection(nftType: Type<@FlovatarDustCollectibleAccessory.Collection>()), to: FlovatarDustCollectibleAccessory.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FlovatarDustCollectibleAccessory.CollectionPublic}>(FlovatarDustCollectibleAccessory.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: FlovatarDustCollectibleAccessory.CollectionPublicPath)
		emit ContractInitialized()
	}
}
