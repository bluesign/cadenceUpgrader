import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Momentables
// NFT items for Momentables!
//
access(all)
contract Momentables: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, momentableId: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Momentables that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Creator{ 
		access(all)
		let creatorName: String
		
		access(all)
		let creatorWallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let creatorRoyalty: UFix64
		
		init(creatorName: String, creatorWallet: Capability<&{FungibleToken.Receiver}>, creatorRoyalty: UFix64){ 
			self.creatorName = creatorName
			self.creatorWallet = creatorWallet
			self.creatorRoyalty = creatorRoyalty
		}
	}
	
	access(all)
	struct Collaborator{ 
		access(all)
		let collaboratorName: String
		
		access(all)
		let collaboratorWallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let collaboratorRoyalty: UFix64
		
		init(collaboratorName: String, collaboratorWallet: Capability<&{FungibleToken.Receiver}>, collaboratorRoyalty: UFix64){ 
			self.collaboratorName = collaboratorName
			self.collaboratorWallet = collaboratorWallet
			self.collaboratorRoyalty = collaboratorRoyalty
		}
	}
	
	access(all)
	struct RarityView{ 
		access(all)
		let traits:{ String:{ String: String}}
		
		init(traits:{ String:{ String: String}}){ 
			self.traits = traits
		}
	}
	
	// NFT
	// A Momentable Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let momentableId: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageCID: String
		
		access(all)
		let directoryPath: String
		
		access(self)
		let traits:{ String:{ String: String}}
		
		access(self)
		let creator: Creator
		
		access(self)
		let collaborators: [Collaborator]
		
		access(self)
		let momentableCollectionDetails:{ String: String}
		
		// initializer
		//
		init(initID: UInt64, initMomentableId: String, name: String, description: String, imageCID: String, directoryPath: String, traits:{ String:{ String: String}}, creator: Creator, collaborators: [Collaborator], momentableCollectionDetails:{ String: String}){ 
			self.id = initID
			self.momentableId = initMomentableId
			self.name = name
			self.description = description
			self.imageCID = imageCID
			self.directoryPath = directoryPath
			self.traits = traits
			self.creator = creator
			self.collaborators = collaborators
			self.momentableCollectionDetails = momentableCollectionDetails
		}
		
		access(all)
		fun getTraits():{ String:{ String: String}}{ 
			return self.traits
		}
		
		access(all)
		fun getCreator(): Creator{ 
			return self.creator
		}
		
		access(all)
		fun getColloboarators(): [Collaborator]{ 
			return self.collaborators
		}
		
		access(all)
		fun getMomentableCollectionDetails():{ String: String}{ 
			return self.momentableCollectionDetails
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<RarityView>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: "https://ik.imagekit.io/jxb3nwqfm/tr:w-600,h-600/".concat(self.imageCID)))
				case Type<RarityView>():
					return RarityView(traits: self.traits)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let momentableRoyalties: [MetadataViews.Royalty] = []
					var totalRoyalties: UFix64 = self.creator.creatorRoyalty
					for collaborator in self.collaborators{ 
						totalRoyalties = totalRoyalties + collaborator.collaboratorRoyalty
					}
					
					// Add the creator's royalty
					momentableRoyalties.append(MetadataViews.Royalty(receiver: self.creator.creatorWallet, cut: self.creator.creatorRoyalty / 100.0, description: "Sale cut for : ".concat(self.creator.creatorName)))
					
					// Add the collaborator's royalty
					for collaborator in self.collaborators{ 
						momentableRoyalties.append(MetadataViews.Royalty(receiver: collaborator.collaboratorWallet, cut: collaborator.collaboratorRoyalty / 100.0, description: "Sale cut for : ".concat(collaborator.collaboratorName)))
					}
					return MetadataViews.Royalties(momentableRoyalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.momentable.ai/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Momentables.CollectionStoragePath, publicPath: Momentables.CollectionPublicPath, publicCollection: Type<&Momentables.Collection>(), publicLinkedType: Type<&Momentables.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Momentables.createEmptyCollection(nftType: Type<@Momentables.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://s3.amazonaws.com/xyz.find.momentable/logo.svg"), mediaType: "image/svg+xml")
					let bannerImageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://s3.amazonaws.com/xyz.find.momentable/banner.svg"), mediaType: "image/svg+xml")
					var momentablesCollectionName: String = ""
					var momentablesCollectionDescription: String = ""
					var momentablesCollectionURL: String = ""
					if self.momentableCollectionDetails["name"] != nil{ 
						momentablesCollectionName = self.momentableCollectionDetails["name"]!
					} else if self.momentableCollectionDetails["Collection Name"] != nil{ 
						momentablesCollectionName = self.momentableCollectionDetails["Collection Name"]!
					} else{ 
						momentablesCollectionName = "Crypto Pharaohs"
					}
					if self.momentableCollectionDetails["description"] != nil{ 
						momentablesCollectionDescription = self.momentableCollectionDetails["description"]!
					} else{ 
						momentablesCollectionDescription = "Welcome to The Crypto Pharaohs World, a world of magic, wonder, and fantasy where you can collect artworks, comics, and digital collectables including Crytpo Pharaohs, Pharaoh Cats, Pharaoh Names, and much more. As your journey unfolds, you'll help shape the roadmap, unlock special perks, earn rewards, and make the world a better place."
					}
					if self.momentableCollectionDetails["ExternalURL"] != nil{ 
						momentablesCollectionURL = self.momentableCollectionDetails["ExternalURL"]!
					} else{ 
						momentablesCollectionURL = "https://storefront.momentable.ai/the-crypto-pharaohs-world"
					}
					return MetadataViews.NFTCollectionDisplay(name: momentablesCollectionName, description: momentablesCollectionDescription, externalURL: MetadataViews.ExternalURL(momentablesCollectionURL), squareImage: squareImageMedia, bannerImage: bannerImageMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/nextdecentrum"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/nextdecentrum"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/nextdecentrum")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["common"]
					let traitsView = MetadataViews.dictToTraits(dict: self.traits, excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Momentables Collection as
	// to allow others to deposit Momentables into their Collection. It also allows for reading
	// the details of Momentables in the Collection.
	access(all)
	resource interface MomentablesCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMomentables(id: UInt64): &Momentables.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Momentables reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Momentables NFTs owned by an account
	//
	access(all)
	resource Collection: MomentablesCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Momentables.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowMomentables
		// Gets a reference to an NFT in the collection as a Momentable,
		// exposing all of its fields (including the momentableId).
		// This is safe as there are no functions that can be called on the Momentables.
		//
		access(all)
		fun borrowMomentables(id: UInt64): &Momentables.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Momentables.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let momentable = nft as! &Momentables.NFT
			return momentable as &{ViewResolver.Resolver}
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, momentableId: String, name: String, description: String, imageCID: String, directoryPath: String, traits:{ String:{ String: String}}, creator: Creator, collaborators: [Collaborator], momentableCollectionDetails:{ String: String}){ 
			emit Minted(id: Momentables.totalSupply, momentableId: momentableId)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Momentables.NFT(initID: Momentables.totalSupply, initMomentableId: momentableId, name: name, description: description, imageCID: imageCID, directoryPath: directoryPath, traits: traits, creator: creator, collaborators: collaborators, momentableCollectionDetails: momentableCollectionDetails))
			Momentables.totalSupply = Momentables.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a Momentables from an account's Collection, if available.
	// If an account does not have a Momentables.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Momentables.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Momentables.Collection>(Momentables.CollectionPublicPath).borrow<&Momentables.Collection>() ?? panic("Couldn't get collection")
		// We trust Momentables.Collection.borowMomentables to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowMomentables(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/MomentablesCollection
		self.CollectionPublicPath = /public/MomentablesCollection
		self.MinterStoragePath = /storage/MomentablesMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
