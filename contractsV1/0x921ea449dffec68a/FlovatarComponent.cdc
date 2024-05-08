//import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
//import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
//import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
//import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"
//import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlovatarComponentTemplate from "./FlovatarComponentTemplate.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/*

 This contract defines the Flovatar Component NFT and the Collection to manage them.
 Components are like the building blocks (lego bricks) of the final Flovatar (body, mouth, hair, eyes, etc.) and they can be traded as normal NFTs.
 Components are linked to a specific Template that will ultimately contain the SVG and all the other metadata

 */

access(all)
contract FlovatarComponent: NonFungibleToken{ 
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
		fun getTemplate(): FlovatarComponentTemplate.ComponentTemplateData
		
		access(all)
		fun getSvg(): String
		
		access(all)
		fun getCategory(): String
		
		access(all)
		fun getSeries(): UInt32
		
		access(all)
		fun getRarity(): String
		
		access(all)
		fun isBooster(rarity: String): Bool
		
		access(all)
		fun checkCategorySeries(category: String, series: UInt32): Bool
		
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
			FlovatarComponent.totalSupply = FlovatarComponent.totalSupply + UInt64(1)
			let componentTemplate = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!
			self.id = FlovatarComponent.totalSupply
			self.templateId = templateId
			self.mint = FlovatarComponentTemplate.getTotalMintedComponents(id: templateId)! + UInt64(1)
			self.name = componentTemplate.name
			self.description = componentTemplate.description
			self.schema = nil
			
			// Increments the counter and stores the timestamp
			FlovatarComponentTemplate.setTotalMintedComponents(id: templateId, value: self.mint)
			FlovatarComponentTemplate.setLastComponentMintedAt(id: templateId, value: getCurrentBlock().timestamp)
		}
		
		access(all)
		fun getID(): UInt64{ 
			return self.id
		}
		
		// Returns the Template associated to the current Component
		access(all)
		fun getTemplate(): FlovatarComponentTemplate.ComponentTemplateData{ 
			return FlovatarComponentTemplate.getComponentTemplate(id: self.templateId)!
		}
		
		// Gets the SVG from the parent Template
		access(all)
		fun getSvg(): String{ 
			return self.getTemplate().svg!
		}
		
		// Gets the category from the parent Template
		access(all)
		fun getCategory(): String{ 
			return self.getTemplate().category
		}
		
		// Gets the series number from the parent Template
		access(all)
		fun getSeries(): UInt32{ 
			return self.getTemplate().series
		}
		
		// Gets the rarity from the parent Template
		access(all)
		fun getRarity(): String{ 
			return self.getTemplate().rarity
		}
		
		// Check the boost and rarity from the parent Template
		access(all)
		fun isBooster(rarity: String): Bool{ 
			let template = self.getTemplate()
			return template.category == "boost" && template.rarity == rarity
		}
		
		//Check the category and series from the parent Template
		access(all)
		fun checkCategorySeries(category: String, series: UInt32): Bool{ 
			let template = self.getTemplate()
			return template.category == category && template.series == series
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
				let address = self.owner?.address
				let url = address == nil ? "https://flovatar.com/builder/" : "https://flovatar.com/components/".concat(self.id.toString()).concat("/").concat((address!).toString())
				return MetadataViews.ExternalURL("https://flovatar.com/builder/")
			}
			if type == Type<MetadataViews.Royalties>(){ 
				let royalties: [MetadataViews.Royalty] = []
				royalties.append(MetadataViews.Royalty(receiver: FlovatarComponent.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, description: "Flovatar Royalty"))
				return MetadataViews.Royalties(royalties)
			}
			if type == Type<MetadataViews.Serial>(){ 
				return MetadataViews.Serial(self.id)
			}
			if type == Type<MetadataViews.Editions>(){ 
				let componentTemplate: FlovatarComponentTemplate.ComponentTemplateData = self.getTemplate()
				let editionInfo = MetadataViews.Edition(name: "Flovatar Component", number: self.mint, max: componentTemplate.maxMintableComponents)
				let editionList: [MetadataViews.Edition] = [editionInfo]
				return MetadataViews.Editions(editionList)
			}
			if type == Type<MetadataViews.NFTCollectionDisplay>(){ 
				let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo.svg"), mediaType: "image/svg+xml")
				let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://images.flovatar.com/logo-horizontal.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "Flovatar Component", description: "Flovatar is pioneering a new way to unleash community creativity in Web3 by allowing users to be co-creators of their prized NFTs, instead of just being passive collectors.", externalURL: MetadataViews.ExternalURL("https://flovatar.com"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/flovatar"), "twitter": MetadataViews.ExternalURL("https://twitter.com/flovatar"), "instagram": MetadataViews.ExternalURL("https://instagram.com/flovatar_nft"), "tiktok": MetadataViews.ExternalURL("https://www.tiktok.com/@flovatar")})
			}
			if type == Type<MetadataViews.Display>(){ 
				return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://flovatar.com/api/image/template/".concat(self.templateId.toString())))
			}
			if type == Type<MetadataViews.Traits>(){ 
				let traits: [MetadataViews.Trait] = []
				let template = self.getTemplate()
				let trait = MetadataViews.Trait(name: template.category, value: template.name, displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: template.rarity))
				traits.append(trait)
				let setTrait = MetadataViews.Trait(name: "set", value: template.category, displayType: "String", rarity: nil)
				traits.append(setTrait)
				return MetadataViews.Traits(traits)
			}
			if type == Type<MetadataViews.Rarity>(){ 
				let template = self.getTemplate()
				return MetadataViews.Rarity(score: nil, max: nil, description: template.rarity)
			}
			if type == Type<MetadataViews.NFTCollectionData>(){ 
				return MetadataViews.NFTCollectionData(storagePath: FlovatarComponent.CollectionStoragePath, publicPath: FlovatarComponent.CollectionPublicPath, publicCollection: Type<&FlovatarComponent.Collection>(), publicLinkedType: Type<&FlovatarComponent.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlovatarComponent.createEmptyCollection(nftType: Type<@FlovatarComponent.Collection>())
					})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Standard NFT collectionPublic interface that can also borrowComponent as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowComponent(id: UInt64): &FlovatarComponent.NFT?{ 
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
			let token <- token as! @FlovatarComponent.NFT
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
		
		// borrowComponent returns a borrowed reference to a FlovatarComponent
		// so that the caller can read data and call methods from it.
		access(all)
		fun borrowComponent(id: UInt64): &FlovatarComponent.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlovatarComponent.NFT
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
			let componentNFT = nft as! &FlovatarComponent.NFT
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
	struct ComponentData{ 
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
		let category: String
		
		access(all)
		let rarity: String
		
		access(all)
		let color: String
		
		init(id: UInt64, templateId: UInt64, mint: UInt64){ 
			self.id = id
			self.templateId = templateId
			self.mint = mint
			let componentTemplate = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!
			self.name = componentTemplate.name
			self.description = componentTemplate.description
			self.category = componentTemplate.category
			self.rarity = componentTemplate.rarity
			self.color = componentTemplate.color
		}
	}
	
	// Get the SVG of a specific Component from an account and the ID
	access(all)
	fun getSvgForComponent(address: Address, componentId: UInt64): String?{ 
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&{FlovatarComponent.CollectionPublic}>(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>(){ 
			return (componentCollection.borrowComponent(id: componentId)!).getSvg()
		}
		return nil
	}
	
	// Get a specific Component from an account and the ID as ComponentData
	access(all)
	fun getComponent(address: Address, componentId: UInt64): ComponentData?{ 
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&{FlovatarComponent.CollectionPublic}>(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>(){ 
			if !componentCollection.isInstance(Type<@FlovatarComponent.Collection>()){ 
				panic("The Collection is not from the correct Type")
			}
			if let component = componentCollection.borrowComponent(id: componentId){ 
				return ComponentData(id: componentId, templateId: (component!).templateId, mint: (component!).mint)
			}
		}
		return nil
	}
	
	// Get an array of all the components in a specific account as ComponentData
	access(all)
	fun getComponents(address: Address): [ComponentData]{ 
		var componentData: [ComponentData] = []
		let account = getAccount(address)
		if let componentCollection = account.capabilities.get<&{FlovatarComponent.CollectionPublic}>(self.CollectionPublicPath).borrow<&{FlovatarComponent.CollectionPublic}>(){ 
			if !componentCollection.isInstance(Type<@FlovatarComponent.Collection>()){ 
				panic("The Collection is not from the correct Type")
			}
			for id in componentCollection.getIDs(){ 
				var component = componentCollection.borrowComponent(id: id)
				componentData.append(ComponentData(id: id, templateId: (component!).templateId, mint: (component!).mint))
			}
		}
		return componentData
	}
	
	// This method can only be called from another contract in the same account.
	// In FlovatarComponent case it is called from the Flovatar Admin that is used
	// to administer the components.
	// The only parameter is the parent Template ID and it will return a Component NFT resource
	access(account)
	fun createComponent(templateId: UInt64): @FlovatarComponent.NFT{ 
		let componentTemplate: FlovatarComponentTemplate.ComponentTemplateData = FlovatarComponentTemplate.getComponentTemplate(id: templateId)!
		let totalMintedComponents: UInt64 = FlovatarComponentTemplate.getTotalMintedComponents(id: templateId)!
		
		// Makes sure that the original minting limit set for each Template has not been reached
		if totalMintedComponents >= componentTemplate.maxMintableComponents{ 
			panic("Reached maximum mintable components for this type")
		}
		var newNFT <- create NFT(templateId: templateId)
		emit Created(id: newNFT.id, templateId: templateId, mint: newNFT.mint)
		return <-newNFT
	}
	
	// This function will batch create multiple Components and pass them back as a Collection
	access(account)
	fun batchCreateComponents(templateId: UInt64, quantity: UInt64): @Collection{ 
		let newCollection <- create Collection()
		var i: UInt64 = 0
		while i < quantity{ 
			newCollection.deposit(token: <-self.createComponent(templateId: templateId))
			i = i + UInt64(1)
		}
		return <-newCollection
	}
	
	init(){ 
		self.CollectionPublicPath = /public/FlovatarComponentCollection
		self.CollectionStoragePath = /storage/FlovatarComponentCollection
		
		// Initialize the total supply
		self.totalSupply = UInt64(0)
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-FlovatarComponent.createEmptyCollection(nftType: Type<@FlovatarComponent.Collection>()), to: FlovatarComponent.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{FlovatarComponent.CollectionPublic}>(FlovatarComponent.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: FlovatarComponent.CollectionPublicPath)
		emit ContractInitialized()
	}
}
