import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract PiratesOfTheMetaverse: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let ClaimedPiratesPath: PublicPath
	
	// totalSupply
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let imageUrl: String
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, imageUrl: String, metadata:{ String: String}){ 
			self.id = id
			self.imageUrl = imageUrl
			self.metadata = metadata
		}
		
		access(all)
		fun name(): String{ 
			return "POTM #".concat(self.id.toString())
		}
		
		access(all)
		fun description(): String{ 
			return "Thrust into a strange future by tragedy and twist of fate, Ethero Caspain must rally a crew of degen pirates to help him locate the most coveted treasure in all the metaverse: a key rumored to unlock inter-dimensional travel.\n\nPirates of the Metaverse\u{2122} by Drip Studios is a collection of 10,000 digitally unique NFTs about to embark on an uncharted journey across blockchains."
		}
		
		access(all)
		fun imageCID(): String{ 
			return self.imageUrl
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.IPFSFile(cid: self.imageCID(), path: nil))
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: nil)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.piratesnft.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PiratesOfTheMetaverse.CollectionStoragePath, publicPath: PiratesOfTheMetaverse.CollectionPublicPath, publicCollection: Type<&PiratesOfTheMetaverse.Collection>(), publicLinkedType: Type<&PiratesOfTheMetaverse.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PiratesOfTheMetaverse.createEmptyCollection(nftType: Type<@PiratesOfTheMetaverse.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let banner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://potm-collection-images.s3.amazonaws.com/banner.jpeg"), mediaType: "image/jpeg")
					let square = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://potm-collection-images.s3.amazonaws.com/square.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Pirates Of The Metaverse", description: self.description(), externalURL: MetadataViews.ExternalURL("https://www.piratesnft.io/"), squareImage: square, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/PiratesMeta")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0x260bb5cff66b4697).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, description: "POTM royalties")])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their pirates Collection as
	// to allow others to deposit pirates into their Collection. It also allows for reading
	// the details of pirate in the Collection.
	access(all)
	resource interface PiratesOfTheMetaverseCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPirate(id: UInt64): &PiratesOfTheMetaverse.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow pirate reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	//
	access(all)
	resource Collection: PiratesOfTheMetaverseCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @PiratesOfTheMetaverse.NFT
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
		
		// borrowPirate
		// Gets a reference to an NFT in the collection
		// exposing all of its fields (including the typeID & rarityID).
		// This is safe as there are no functions that can be called on the pirate.
		//
		access(all)
		fun borrowPirate(id: UInt64): &PiratesOfTheMetaverse.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PiratesOfTheMetaverse.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let pirate = nft as! &PiratesOfTheMetaverse.NFT
			return pirate as &{ViewResolver.Resolver}
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
	resource interface HasClaims{ 
		access(all)
		fun hasBeenClaimed(id: UInt64): Bool
	}
	
	access(all)
	resource NFTMinter: HasClaims{ 
		access(contract)
		var mintedAlready:{ UInt64: Bool}
		
		init(){ 
			self.mintedAlready ={} 
		}
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, id: UInt64, imageUrl: String, metadata:{ String: String}){ 
			if self.mintedAlready.containsKey(id){ 
				panic("Id has already been claimed!")
			}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create PiratesOfTheMetaverse.NFT(id: id, imageUrl: imageUrl, metadata: metadata))
			self.mintedAlready.insert(key: id, true)
			emit Minted(id: id)
		}
		
		access(all)
		fun hasBeenClaimed(id: UInt64): Bool{ 
			return self.mintedAlready.containsKey(id)
		}
	}
	
	// fetch
	// Get a reference to a pirate from an account's Collection, if available.
	// If an account does not have a pirate.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &PiratesOfTheMetaverse.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&PiratesOfTheMetaverse.Collection>(PiratesOfTheMetaverse.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust pirate.Collection.borowPirate to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowPirate(id: itemID)
	}
	
	access(all)
	fun hasBeenClaimed(id: UInt64): Bool{ 
		let claimedPirates = self.account.capabilities.get<&{HasClaims}>(self.ClaimedPiratesPath)
		let claimedPiratesRef = claimedPirates.borrow()!
		return claimedPiratesRef.hasBeenClaimed(id: id)
	}
	
	// initializer
	//
	init(){ 
		
		// Set our named paths
		self.CollectionStoragePath = /storage/piratesOfTheMetaverseCollection
		self.CollectionPublicPath = /public/piratesOfTheMetaverseCollection
		self.MinterStoragePath = /storage/piratesOfTheMetaverseMinter
		self.ClaimedPiratesPath = /public/claimedPirates
		
		// Initialize the total supply
		self.totalSupply = 10000
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{HasClaims}>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ClaimedPiratesPath)
		emit ContractInitialized()
	}
}
