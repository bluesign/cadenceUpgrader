import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract EpisodeNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// Variable size dictionary of episodes structs
	access(contract)
	var metadata:{ String: Metadata}
	
	access(contract)
	var resourceIDsByEpisodeID:{ String: [UInt64]}
	
	// We also track mapping of nft resource id to owner 
	// which is updated whenever an nfts is deposited
	// This is for ease of rewarding Kickback tokens to the owners
	access(contract)
	var currentOwnerByID:{ UInt64: Address}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Structs
	//
	// Metadata 
	//
	// Structure for Location NFTs metadata
	// stored in private contract level dictionary by locationID
	// a copy of which is returned when querying an individual NFT's metadata
	// hence the edition field is an optional
	//
	access(all)
	struct Metadata{ 
		access(all)
		var edition: UInt64?
		
		access(all)
		var maxEdition: UInt64
		
		access(all)
		var totalMinted: UInt64
		
		access(all)
		var podcastID: String
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		fun setMetadata(_ key: String, _ value: String){ 
			self.metadata[key] = value
		}
		
		access(all)
		fun setTotalMinted(_ total: UInt64){ 
			self.totalMinted = total
		}
		
		access(all)
		fun setEdition(_ edition: UInt64){ 
			self.edition = edition
		}
		
		init(maxEdition: UInt64, podcastID: String, metadata:{ String: String}){ 
			self.edition = nil
			self.maxEdition = maxEdition
			self.totalMinted = 0
			self.podcastID = podcastID
			self.metadata = metadata
		}
	}
	
	// Public Functions
	//
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun getCurrentOwners():{ UInt64: Address}{ 
		return self.currentOwnerByID
	}
	
	// getIDs returns the IDs minted by episodeID 
	access(all)
	fun getResourceIDsFor(episodeID: String): [UInt64]{ 
		return self.resourceIDsByEpisodeID[episodeID]!
	}
	
	// This is the main function 
	access(all)
	fun getOwners(episodeID: String): [Address]{ 
		let addresses: [Address] = []
		for key in self.getResourceIDsFor(episodeID: episodeID){ 
			let owner = EpisodeNFT.currentOwnerByID[key]
			if owner != nil{ // nil if in owners account 
				
				addresses.append(owner!)
			}
		}
		return addresses
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let episodeID: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let edition: UInt64
		
		init(name: String, episodeID: String, description: String, thumbnail: String, edition: UInt64){ 
			self.id = EpisodeNFT.totalSupply
			self.name = name.concat(" #").concat(self.id.toString())
			self.episodeID = episodeID
			self.description = description
			self.thumbnail = thumbnail
			self.edition = edition
			
			// When NFT is minted we update the totalMinted in the master metadata
			EpisodeNFT.metadata[episodeID]?.setTotalMinted(EpisodeNFT.metadata[episodeID]?.totalMinted! + 1)
			
			// And add the id to a mapping of episodeIDs -> resource uuid
			if EpisodeNFT.resourceIDsByEpisodeID[episodeID] == nil{ 
				EpisodeNFT.resourceIDsByEpisodeID[episodeID] = [self.id]
			} else{ 
				EpisodeNFT.resourceIDsByEpisodeID[episodeID]?.append(self.id)
			}
			emit Minted(id: self.id)
		}
		
		access(all)
		fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun getMetadata(): Metadata{ 
			let metadata = EpisodeNFT.metadata[self.episodeID]!
			metadata.setEdition(self.edition)
			return metadata
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://open.kickback.fm/episode/nft/".concat(self.episodeID))
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://kickback-photos.s3.amazonaws.com/logo.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Kickback Podcasts Episodes Collection", description: "Welcome to the Kickback Episodes Collection! Collect free listener NFTs to unlock exclusive perks, content, and project allow lists.", externalURL: MetadataViews.ExternalURL("https://open.kickback.fm"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://kickback-photos.s3.amazonaws.com/logo.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://kickback-photos.s3.amazonaws.com/banner.png"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/viaKickback"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/5BrvrMxaJ2")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface EpisodeNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(collection: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun getMetadatadata(id: UInt64): Metadata
		
		access(all)
		fun borrowViewResolver(id: UInt64): &EpisodeNFT.NFT
		
		access(all)
		fun buy(collectionCapability: Capability<&Collection>, episodeID: String)
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, EpisodeNFTCollectionPublic{ 
		// the id of the NFT --> the NFT with that id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			let collection <- EpisodeNFT.createEmptyCollection(nftType: Type<@EpisodeNFT.Collection>())
			for id in ids{ 
				let nft <- self.withdraw(withdrawID: id)
				collection.deposit(token: <-nft)
			}
			return <-collection
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @EpisodeNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
			
			// store owner at contract level
			if self.owner?.address != EpisodeNFT.account.address{ 
				EpisodeNFT.currentOwnerByID[id] = self.owner?.address
			}
		}
		
		access(all)
		fun batchDeposit(collection: @{NonFungibleToken.Collection}){ 
			for id in collection.getIDs(){ 
				let token <- collection.withdraw(withdrawID: id)
				self.deposit(token: <-token)
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
		
		// borrowEpisodeNFT gets a reference to an NFT from the collection
		// so the caller can read the NFT's extended information
		access(all)
		fun borrowEpisodeNFT(id: UInt64): &EpisodeNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &EpisodeNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun getMetadatadata(id: UInt64): Metadata{ 
			return (self.borrowEpisodeNFT(id: id)!).getMetadata()
		}
		
		access(all)
		fun getAllItemMetadata(): [Metadata]{ 
			var itemsMetadata: [Metadata] = []
			for key in self.ownedNFTs.keys{ 
				itemsMetadata.append(self.getMetadatadata(id: key))
			}
			return itemsMetadata
		}
		
		access(all)
		fun borrowViewResolver(id: UInt64): &EpisodeNFT.NFT{ 
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = token as! &NFT
			return nft as &EpisodeNFT.NFT
		}
		
		access(all)
		fun buy(collectionCapability: Capability<&Collection>, episodeID: String){ 
			pre{ 
				(self.owner!).address == EpisodeNFT.account.address:
					"You can only buy the NFT directly from the EpisodeNFT account"
			}
			let kickbackCollection = EpisodeNFT.account.capabilities.get<&{EpisodeNFT.EpisodeNFTCollectionPublic}>(EpisodeNFT.CollectionPublicPath).borrow<&{EpisodeNFT.EpisodeNFTCollectionPublic}>() ?? panic("Can't get the EpisodeNFT collection.")
			let availableNFTs = kickbackCollection.getIDs()
			var availableID: UInt64? = nil
			for id in availableNFTs{ 
				let resolver = kickbackCollection.borrowViewResolver(id: id)!
				if resolver.episodeID == episodeID{ 
					availableID = id
				}
			}
			if availableID != nil{ 
				let receiver = collectionCapability.borrow() ?? panic("Could not borrow EpisodeNFT collection")
				let token <- self.withdraw(withdrawID: availableID!) as! @EpisodeNFT.NFT
				receiver.deposit(token: <-token)
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// Set the Episode Metadata for a episodeID
		// either updates without affecting number minted
		access(all)
		fun setEpisode(episodeID: String, maxEdition: UInt64, podcastID: String, metadata:{ String: String}){ 
			var totalMinted: UInt64 = 0
			if EpisodeNFT.metadata[episodeID] != nil{ 
				totalMinted = EpisodeNFT.metadata[episodeID]?.totalMinted!
			}
			EpisodeNFT.metadata[episodeID] = Metadata(maxEdition: maxEdition, podcastID: podcastID, metadata: metadata)
			EpisodeNFT.metadata[episodeID]?.setTotalMinted(totalMinted)
		}
		
		access(all)
		fun setEpisodeMetadata(episodeID: String, key: String, value: String){ 
			EpisodeNFT.metadata[episodeID]?.setMetadata(key, value)
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun batchMintNFTs(recipient: &{NonFungibleToken.CollectionPublic}, name: String, episodeID: String, description: String, thumbnail: String, numberOfEditionsToMint: UInt64){ 
			pre{ 
				numberOfEditionsToMint > 0:
					"Cannot mint 0 NFTs!"
				EpisodeNFT.metadata.containsKey(episodeID):
					"EpisodeID not found!"
			}
			let totalMinted = EpisodeNFT.metadata[episodeID]?.totalMinted!
			assert(numberOfEditionsToMint <= EpisodeNFT.metadata[episodeID]?.maxEdition! - totalMinted, message: "Number of editions to mint exceeds max edition size.")
			var edition = totalMinted + 1
			while edition <= totalMinted + numberOfEditionsToMint{ 
				// create a new NFT
				var newNFT <- create NFT(name: name, episodeID: episodeID, description: description, thumbnail: thumbnail, edition: edition)
				
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-newNFT)
				EpisodeNFT.totalSupply = EpisodeNFT.totalSupply + 1
				edition = edition + 1
			}
		}
	}
	
	init(){ 
		self.currentOwnerByID ={} 
		self.resourceIDsByEpisodeID ={} 
		self.metadata ={} 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/EpisodeNFTCollection
		self.CollectionPublicPath = /public/EpisodeNFTCollection
		self.AdminStoragePath = /storage/EpisodeNFTAdmin
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: EpisodeNFT.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&EpisodeNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: EpisodeNFT.AdminStoragePath)
		emit ContractInitialized()
	}
}
