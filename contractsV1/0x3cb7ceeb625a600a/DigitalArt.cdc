import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Evergreen from "./Evergreen.cdc"

// DigitalArt defines NFTs that represent digital art in Sequel.
// See https://sequel.space for more details.
//
// DigitalArt tokens support Evergreen token standard.
//
// Source: https://github.com/piprate/sequel-flow-contracts
//
access(all)
contract DigitalArt: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, asset: String, edition: UInt64, modID: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// The total number of DigitalArt NFTs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// Variable size dictionary of Master resources
	access(self)
	var masters:{ String: Master}
	
	// Master enables mint-on-demand functionality and defines a master copy of a token
	// that is used to mint a number of editions (limited by metadata.maxEditions).
	// Once all editions are minted, the master is 'closed' but remains on-chain
	// to prevent re-minting NFTs with the same asset ID.
	//
	access(all)
	struct Master{ 
		access(all)
		var metadata: Metadata?
		
		access(all)
		var evergreenProfile: Evergreen.Profile?
		
		access(all)
		var nextEdition: UInt64
		
		access(all)
		var closed: Bool
		
		init(metadata: Metadata, evergreenProfile: Evergreen.Profile){ 
			self.metadata = metadata
			self.evergreenProfile = evergreenProfile
			self.nextEdition = 1
			self.closed = false
		}
		
		access(all)
		fun newEditionID(): UInt64{ 
			let val = self.nextEdition
			self.nextEdition = self.nextEdition + UInt64(1)
			return val
		}
		
		access(all)
		fun availableEditions(): UInt64{ 
			if !self.closed && (self.metadata!).maxEdition >= self.nextEdition{ 
				return (self.metadata!).maxEdition - self.nextEdition + UInt64(1)
			} else{ 
				return 0
			}
		}
		
		// We close masters after all editions are minted instead of deleting master records
		// This process ensures nobody can ever mint tokens with the same asset ID.
		access(all)
		fun close(){ 
			self.metadata = nil
			self.evergreenProfile = nil
			self.nextEdition = 0
			self.closed = true
		}
	}
	
	// Metadata defines Digital Art's metadata.
	//
	access(all)
	struct Metadata{ 
		// Name
		access(all)
		let name: String
		
		// Artist name
		access(all)
		let artist: String
		
		// Description
		access(all)
		let description: String
		
		// Media type: Image, Audio, Video
		access(all)
		let type: String
		
		// A URI of the original digital art content.
		access(all)
		let contentURI: String
		
		// A URI of the digital art preview content (i.e. a thumbnail).
		access(all)
		let contentPreviewURI: String
		
		// MIME type (e.g. 'image/jpeg')
		access(all)
		let mimetype: String
		
		// Edition number of the given NFT. Editions are unique for the same master,
		// identified by the asset ID.
		access(all)
		var edition: UInt64
		
		// The number of editions that may have been produced for the given master.
		// This number can't be exceeded by the contract, but there is no obligation
		// to mint all the declared editions.
		// If maxEdition == 1, the given NFT is one-of-a-kind.
		access(all)
		let maxEdition: UInt64
		
		// The DID of the master's asset. This ID is the same
		// for all editions of a particular Digital Art NFT.
		access(all)
		let asset: String
		
		// A URI of the full digital art's metadata JSON
		// as it existed at the time the master was sealed.
		access(all)
		let metadataURI: String
		
		// The ChainLocker record ID of the full metadata JSON
		// as it existed at the time the master was sealed.
		access(all)
		let record: String
		
		// The ChainLocker asset head ID of the full metadata JSON.
		// It can be used to retrieve the current metadata JSON (if changed).
		access(all)
		let assetHead: String
		
		init(name: String, artist: String, description: String, type: String, contentURI: String, contentPreviewURI: String, mimetype: String, edition: UInt64, maxEdition: UInt64, asset: String, metadataURI: String, record: String, assetHead: String){ 
			self.name = name
			self.artist = artist
			self.description = description
			self.type = type
			self.contentURI = contentURI
			self.contentPreviewURI = contentPreviewURI
			self.mimetype = mimetype
			self.edition = edition
			self.maxEdition = maxEdition
			self.asset = asset
			self.metadataURI = metadataURI
			self.record = record
			self.assetHead = assetHead
		}
		
		access(all)
		fun setEdition(edition: UInt64){ 
			self.edition = edition
		}
	}
	
	// NFT
	// DigitalArt as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, Evergreen.Token{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let evergreenProfile: Evergreen.Profile
		
		// initializer
		//
		init(initID: UInt64, metadata: Metadata, evergreenProfile: Evergreen.Profile){ 
			self.id = initID
			self.metadata = metadata
			self.evergreenProfile = evergreenProfile
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<DigitalArt.Metadata>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata.name, description: self.metadata.description, thumbnail: MetadataViews.HTTPFile(url: DigitalArt.getWebFriendlyURL(url: self.metadata.contentPreviewURI)))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.evergreenProfile.buildRoyalties(defaultReceiverPath: MetadataViews.getRoyaltyReceiverPublicPath()))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://app.sequel.space/tokens/digital-art/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DigitalArt.CollectionStoragePath, publicPath: DigitalArt.CollectionPublicPath, publicCollection: Type<&DigitalArt.Collection>(), publicLinkedType: Type<&DigitalArt.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DigitalArt.createEmptyCollection(nftType: Type<@DigitalArt.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://sequel.space/home/img/flow-sequel-logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Sequel Digital Art", description: "Sequel is a social platform where everything is for fun and purely fictional.", externalURL: MetadataViews.ExternalURL("https://sequel.space"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://sequel.space/home/img/flow-sequel-logo.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://sequel.space/home/img/flow-sequel-banner.jpg"), mediaType: "image/jpeg"), socials:{ "instagram": MetadataViews.ExternalURL("https://www.instagram.com/sequelspace"), "mastodon": MetadataViews.ExternalURL("https://mastodon.social/@sequel"), "discord": MetadataViews.ExternalURL("https://discord.gg/YaR7BFuXNk"), "twitter": MetadataViews.ExternalURL("https://twitter.com/sequelspace")})
				case Type<DigitalArt.Metadata>():
					return self.metadata
			}
			return nil
		}
		
		access(all)
		fun getAssetID(): String{ 
			return self.metadata.asset
		}
		
		access(all)
		fun getEvergreenProfile(): Evergreen.Profile{ 
			return self.evergreenProfile
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their DigitalArt Collection as
	// to allow others to deposit DigitalArt into their Collection. It also allows for reading
	// the details of DigitalArt in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDigitalArt(id: UInt64): &DigitalArt.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DigitalArt reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of DigitalArt NFTs owned by an account
	//
	access(all)
	resource Collection: CollectionPublic, Evergreen.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
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
			let token <- token as! @DigitalArt.NFT
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
		
		// borrowDigitalArt
		// Gets a reference to an NFT in the collection as a DigitalArt,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the DigitalArt.
		//
		access(all)
		fun borrowDigitalArt(id: UInt64): &DigitalArt.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DigitalArt.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &DigitalArt.NFT
		}
		
		access(all)
		fun borrowEvergreenToken(id: UInt64): &{Evergreen.Token}?{ 
			return self.borrowDigitalArt(id: id)
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
	
	access(all)
	fun getMetadata(address: Address, tokenId: UInt64): Metadata?{ 
		let acct = getAccount(address)
		let collectionRef = (acct.capabilities.get<&{DigitalArt.CollectionPublic}>(self.CollectionPublicPath)!).borrow() ?? panic("Could not borrow capability from public collection")
		return (collectionRef.borrowDigitalArt(id: tokenId)!).metadata
	}
	
	access(all)
	fun isClosed(masterId: String): Bool{ 
		if DigitalArt.masters.containsKey(masterId){ 
			let master = &DigitalArt.masters[masterId]! as &Master
			return master.closed
		} else{ 
			return false
		}
	}
	
	access(all)
	fun getWebFriendlyURL(url: String): String{ 
		if url.slice(from: 0, upTo: 4) == "ipfs"{ 
			return "https://sequel.mypinata.cloud/ipfs/".concat(url.slice(from: 7, upTo: url.length))
		} else{ 
			return url
		}
	}
	
	// Admin
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// sealMaster saves and freezes the master copy that then can be used
		// to mint NFT editions.
		access(all)
		fun sealMaster(metadata: Metadata, evergreenProfile: Evergreen.Profile){ 
			pre{ 
				metadata.asset != "":
					"Empty asset ID"
				metadata.edition == UInt64(0):
					"Edition should be zero"
				metadata.maxEdition >= UInt64(1):
					"MaxEdition should be positive"
				!DigitalArt.masters.containsKey(metadata.asset):
					"Master already sealed"
			}
			DigitalArt.masters[metadata.asset] = Master(metadata: metadata, evergreenProfile: evergreenProfile)
		}
		
		access(all)
		fun isSealed(masterId: String): Bool{ 
			return DigitalArt.masters.containsKey(masterId)
		}
		
		access(all)
		fun availableEditions(masterId: String): UInt64{ 
			pre{ 
				DigitalArt.masters.containsKey(masterId):
					"Master not found"
			}
			let master = &DigitalArt.masters[masterId]! as &Master
			return master.availableEditions()
		}
		
		access(all)
		fun evergreenProfile(masterId: String): Evergreen.Profile{ 
			pre{ 
				DigitalArt.masters.containsKey(masterId):
					"Master not found"
			}
			let master = &DigitalArt.masters[masterId]! as &Master
			return *master.evergreenProfile!
		}
		
		// mintEditionNFT mints a token from master with the given ID.
		// If it's a mint-on-demand, provide MOD ID to link it with the Marketplace database.
		// Otherwise, set modID to 0.
		access(all)
		fun mintEditionNFT(masterId: String, modID: UInt64): @DigitalArt.NFT{ 
			pre{ 
				DigitalArt.masters.containsKey(masterId):
					"Master not found"
			}
			let master = &DigitalArt.masters[masterId]! as &Master
			assert(master.availableEditions() > 0, message: "No more tokens to mint")
			let metadata = master.metadata!
			let edition = master.newEditionID()
			metadata.setEdition(edition: edition)
			
			// create a new NFT
			var newNFT <- create NFT(initID: DigitalArt.totalSupply, metadata: *metadata, evergreenProfile: *master.evergreenProfile!)
			emit Minted(id: DigitalArt.totalSupply, asset: metadata.asset, edition: edition, modID: modID)
			DigitalArt.totalSupply = DigitalArt.totalSupply + UInt64(1)
			if master.availableEditions() == 0{ 
				master.close()
			}
			return <-newNFT
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/sequelDigitalArtCollection
		self.CollectionPublicPath = /public/sequelDigitalArtCollection
		self.AdminStoragePath = /storage/digitalArtAdmin
		self.AdminPrivatePath = /private/digitalArtAdmin
		
		// Initialize the total supply
		self.totalSupply = 0
		self.masters ={} 
		
		// Create a Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
