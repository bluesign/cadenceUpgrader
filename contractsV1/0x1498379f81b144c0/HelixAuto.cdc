import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract HelixAuto: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	// NFT Counter
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, vehicle_type: String)
	
	// Storage Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	enum VehicleType: UInt8{ 
		access(all)
		case hero
		
		access(all)
		case hunter
		
		access(all)
		case hammer
		
		access(all)
		case hype
		
		access(all)
		case hacker
	}
	
	access(all)
	fun vehicleTypeToString(_ type: VehicleType): String{ 
		switch type{ 
			case VehicleType.hero:
				return "Hero"
			case VehicleType.hunter:
				return "Hunter"
			case VehicleType.hammer:
				return "Hammer"
			case VehicleType.hype:
				return "Hype"
			case VehicleType.hacker:
				return "Hacker"
		}
		return ""
	}
	
	access(all)
	fun vehicleVinType(_ type: VehicleType): String{ 
		switch type{ 
			case VehicleType.hero:
				return "HLX-HR-"
			case VehicleType.hunter:
				return "HLX-HU-"
			case VehicleType.hammer:
				return "HLX-HM-"
			case VehicleType.hype:
				return "HLX-HY-"
			case VehicleType.hacker:
				return "HLX-HK-"
		}
		return ""
	}
	
	access(all)
	fun vehicleDescriptionType(_ type: VehicleType): String{ 
		switch type{ 
			case VehicleType.hero:
				return "Agile handling with a relentless swagger to match, the Helix Hero is the epitome of style and performance."
			case VehicleType.hunter:
				return "Unlike its Hacker counterpart, the Helix Hunter is the optimal cryptocycle for fun and gun missions."
			case VehicleType.hammer:
				return "The workhorse of the Helix AI vehicles, the Helix Hammer is a beautiful blend of uncompromising power, durability and design."
			case VehicleType.hype:
				return "The Helix Hype boasts good looks, big wheels and swag for days. Choose this vehicle if you're ready to let the community buy into your Hype!"
			case VehicleType.hacker:
				return "Blaze by the competition in the nimble Helix Hacker. What this cryptocycle lacks in raw power, it makes up for in top notch speed and maneuverability."
		}
		return ""
	}
	
	// NFT Resource
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Variables
		access(all)
		let id: UInt64
		
		access(all)
		let vehicle_type: VehicleType
		
		access(all)
		let glbCID: String
		
		access(all)
		let imageCID: String
		
		// Attributes
		access(all)
		let traits:{ String: AnyStruct}
		
		//  Metadata fields
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		// pub function to send back the NFT name
		// used in the metadata resolver
		access(all)
		fun name(): String{ 
			return "Helix ".concat(HelixAuto.vehicleTypeToString(self.vehicle_type)).concat(" ").concat(HelixAuto.vehicleVinType(self.vehicle_type)).concat(self.id.toString())
		}
		
		// pub function to send back the NFT description
		// used in the metadata resolver
		access(all)
		fun description(): String{ 
			return HelixAuto.vehicleDescriptionType(self.vehicle_type)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.IPFSFile(cid: self.imageCID, path: nil))
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					for key in self.traits.keys{ 
						traits.append(MetadataViews.Trait(name: key, value: self.traits[key], displayType: "String", rarity: nil))
					}
					return MetadataViews.Traits(traits)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.nft.thecela/helix/showcase/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: HelixAuto.CollectionStoragePath, publicPath: HelixAuto.CollectionPublicPath, publicCollection: Type<&HelixAuto.Collection>(), publicLinkedType: Type<&HelixAuto.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-HelixAuto.createEmptyCollection(nftType: Type<@HelixAuto.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://helix.infura-ipfs.io/ipfs/QmXMYU4xzL4ChHHCsuodzStQFuMcfXhvpQ3UVfQ98uJvab"), mediaType: "image/png")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://helix.infura-ipfs.io/ipfs/QmaWP21VobjXmKV18vSuv6kbJUc7isTGaLmEdgc6MusmM8"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: self.name(), description: self.description(), externalURL: MetadataViews.ExternalURL("https://www.helix-auto.com"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://mobile.twitter.com/helix_auto"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/7vVJewPTY4")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_traits:{ String: AnyStruct}, _glbCID: String, _imageCID: String, _vehicle_type: VehicleType, royalties: [MetadataViews.Royalty]){ 
			self.id = HelixAuto.totalSupply
			HelixAuto.totalSupply = HelixAuto.totalSupply + 1
			self.vehicle_type = _vehicle_type
			self.glbCID = _glbCID
			self.imageCID = _imageCID
			self.traits = _traits
			self.royalties = royalties
		}
	}
	
	// Public Collection Interface
	access(all)
	resource interface HelixAutoCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowEntireNFT(id: UInt64): &HelixAuto.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow VehicleItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Container for NFTs, where users NFT are stored
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, HelixAutoCollectionPublic, ViewResolver.ResolverCollection{ 
		// map id of the nft --> nft with that id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Deposit
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Security to make sure we are depositing an NFT fom this collection
			let ourNft <- token as! @NFT
			emit Deposit(id: ourNft.id, to: self.owner?.address)
			self.ownedNFTs[ourNft.id] <-! ourNft
		}
		
		// Deposit
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This collection doesn't contain an NFT with that id")
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			// get nft from collection
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			// down cast it too this contracts public NFT collection
			let HelixAuto = nft as! &HelixAuto.NFT
			// return downcasted items metadata resolver
			return HelixAuto as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Borrow reference to nft standard
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowEntireNFT(id: UInt64): &HelixAuto.NFT?{ 
			// If account owns an NFT
			if self.ownedNFTs[id] != nil{ 
				// get nft, and down cast it too this contracts public NFT collection
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				// Return downcasted item
				return ref as! &HelixAuto.NFT
			} else{ 
				return nil
			}
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
	
	// Create Collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFT Minter
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, _traits:{ String: AnyStruct}, _vehicle_type: VehicleType, _glbCID: String, _imageCID: String, royalties: [MetadataViews.Royalty]){ 
			recipient.deposit(token: <-create HelixAuto.NFT(_traits: _traits, _glbCID: _glbCID, _imageCID: _imageCID, _vehicle_type: _vehicle_type, royalties: royalties))
			emit Minted(id: HelixAuto.totalSupply, vehicle_type: HelixAuto.vehicleTypeToString(_vehicle_type))
		}
	}
	
	// fetch
	// Get a reference to a vehicle item from an account's collection, if available
	// If an account does not have a collection, panic
	// If it has a collection, but does not contain the itemID, return nil
	// If it has a collection and it contains the itemID, return a reference to that
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &HelixAuto.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&HelixAuto.Collection>(HelixAuto.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust that HelixAuto.collection.borrowEntireNFT to get the correct itemID
		// (it checks it before returning it)
		return collection.borrowEntireNFT(id: itemID)
	}
	
	// Contract initialiser, ran everytime contract is deployed
	init(){ 
		
		// Init the total supply
		self.totalSupply = 0
		
		// set named paths
		self.CollectionStoragePath = /storage/HelixAutoStorageV3
		self.CollectionPublicPath = /public/HelixAutoCollectionV3
		self.MinterStoragePath = /storage/HelixAutoMinterV3
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&HelixAuto.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create the Minter resource and save to storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
