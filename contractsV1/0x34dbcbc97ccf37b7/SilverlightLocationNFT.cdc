// SilverlightLocationNFT NFT Contract
//
// Extends the NonFungibleToken standard with extra metadata for each Silverlight NFT.
// Tracks which accounts are holding the NFTs when they are deposited 
//
// Each Silverlight NFT has on-chain metadata stored in the NFT itself.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SilverlightLocationNFT: NonFungibleToken{ 
	
	// Mapping of locationID to the respective Metadata
	access(contract)
	var metadata:{ UInt64: Metadata}
	
	access(contract)
	var resourceIDsByLocationID:{ UInt64: [UInt64]}
	
	// We also track mapping of nft resource id to owner 
	// which is updated whenever an nfts is deposited
	// This is for ease of rewarding effort tokens to the owners
	access(contract)
	var currentOwnerByIDs:{ UInt64: Address}
	
	// NonFungibleToken Interface Standards
	// 
	// Total number of Silverlight Location NFT's in existance
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
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
		var locationID: UInt64
		
		access(all)
		var maxEdition: UInt64
		
		access(all)
		var totalMinted: UInt64
		
		access(all)
		var isLocked: Bool
		
		access(all)
		var landmark: Bool
		
		access(all)
		let title: String
		
		access(all)
		let category: String
		
		access(all)
		let rarity: String
		
		access(all)
		let description: String
		
		access(all)
		let svgImageURL: String
		
		access(all)
		let jpgImageURL: String
		
		access(all)
		let cardURL: String
		
		access(all)
		let location: String
		
		access(all)
		let state: String
		
		access(all)
		let country: String
		
		access(all)
		let continent: String
		
		access(all)
		let lattitude: Fix64
		
		access(all)
		let longitude: Fix64
		
		access(all)
		let elevationMeters: UFix64?
		
		access(all)
		let elevationFt: UFix64?
		
		access(all)
		let ipfsCID: String
		
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
		
		access(all)
		fun lock(){ 
			self.isLocked = true
		}
		
		init(locationID: UInt64, maxEdition: UInt64, landmark: Bool, title: String, category: String, rarity: String, description: String, imageURL: String, cardURL: String, ipfsCID: String, location: String, state: String, country: String, continent: String, longitude: Fix64, lattitude: Fix64, elevationMeters: UFix64, metadata:{ String: String}){ 
			self.edition = nil
			self.locationID = locationID
			self.maxEdition = maxEdition
			self.landmark = landmark
			self.totalMinted = 0
			self.title = title
			self.category = category
			self.rarity = rarity
			self.description = description
			self.svgImageURL = imageURL.concat(".svg")
			self.jpgImageURL = imageURL.concat(".jpg")
			self.cardURL = cardURL
			self.ipfsCID = ipfsCID
			self.location = location
			self.state = state
			self.country = country
			self.continent = continent
			self.longitude = longitude
			self.lattitude = lattitude
			self.elevationMeters = elevationMeters
			self.elevationFt = elevationMeters * 3.28084
			self.metadata = metadata
			self.isLocked = false
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
	fun getLocationIDs(): [UInt64]{ 
		return self.metadata.keys
	}
	
	access(all)
	fun getLocation(id: UInt64): AnyStruct{ 
		return self.metadata[id]
	}
	
	access(all)
	fun getLocations():{ UInt64: AnyStruct}{ 
		return self.metadata
	}
	
	access(all)
	fun getCurrentOwners():{ UInt64: Address}{ 
		return self.currentOwnerByIDs
	}
	
	// getIDs returns the IDs minted by locationID 
	access(all)
	fun getResourceIDsFor(locationID: UInt64): [UInt64]{ 
		return self.resourceIDsByLocationID[locationID]!
	}
	
	// Returns list of all owners of a particular location NFT
	access(all)
	fun getOwners(locationID: UInt64): [Address]{ 
		let addresses: [Address] = []
		for key in self.getResourceIDsFor(locationID: locationID){ 
			let owner = SilverlightLocationNFT.currentOwnerByIDs[key]
			if owner != nil{ // nil if in owners account 
				
				addresses.append(owner!)
			}
		}
		return addresses
	}
	
	// Resources
	//
	// Silverlight.NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let locationID: UInt64
		
		access(all)
		let edition: UInt64
		
		// MetadataViews
		//
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<SilverlightLocationNFT.Metadata>()]
		}
		
		access(all)
		fun getMetadata(): Metadata{ 
			let metadata = SilverlightLocationNFT.metadata[self.locationID]!
			metadata.setEdition(self.edition)
			return metadata
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = SilverlightLocationNFT.metadata[self.locationID]!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.title.concat(" #".concat((metadata.edition!).toString().concat("/".concat(metadata.maxEdition.toString())))), description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.ipfsCID, path: nil))
				case Type<SilverlightLocationNFT.Metadata>():
					return self.getMetadata()
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(locationID: UInt64, edition: UInt64){ 
			self.id = self.uuid
			self.locationID = locationID
			self.edition = edition
			// When NFT is minted we update the totalMinted in the master metadata
			SilverlightLocationNFT.metadata[locationID]?.setTotalMinted(SilverlightLocationNFT.metadata[locationID]?.totalMinted! + 1)
			// And add the id to a mapping of locationIDs -> resource uuid
			if SilverlightLocationNFT.resourceIDsByLocationID[locationID] == nil{ 
				SilverlightLocationNFT.resourceIDsByLocationID[locationID] = [self.id]
			} else{ 
				SilverlightLocationNFT.resourceIDsByLocationID[locationID]?.append(self.id)
			}
		}
	}
	
	// Public Interface for SilverlightLocationNFTs Collection to expose metadata
	// includes all functions from NonFungibleToken Interface
	access(all)
	resource interface SilverlightLocationNFTCollectionPublic{ 
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
		fun borrowSilverlightLocationNFT(id: UInt64): &SilverlightLocationNFT.NFT?
	}
	
	// standard implmentation for managing a collection of NFTs
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, SilverlightLocationNFTCollectionPublic{ 
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
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			let collection <- SilverlightLocationNFT.createEmptyCollection(nftType: Type<@SilverlightLocationNFT.Collection>())
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
			let token <- token as! @SilverlightLocationNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
			
			// store owner at contract level
			if self.owner?.address != SilverlightLocationNFT.account.address{ 
				SilverlightLocationNFT.currentOwnerByIDs[id] = self.owner?.address
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
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowSilverlightLocationNFT gets a reference to an NFT from the collection
		// so the caller can read the NFT's extended information
		access(all)
		fun borrowSilverlightLocationNFT(id: UInt64): &SilverlightLocationNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &SilverlightLocationNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun getMetadatadata(id: UInt64): Metadata{ 
			return (self.borrowSilverlightLocationNFT(id: id)!).getMetadata()
		}
		
		access(all)
		fun getAllItemMetadata(): [Metadata]{ 
			var itemsMetadata: [Metadata] = []
			for key in self.ownedNFTs.keys{ 
				itemsMetadata.append(self.getMetadatadata(id: key))
			}
			return itemsMetadata
		}
		
		// MetadataViews 
		//
		access(all)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let locationNFT = nft as! &SilverlightLocationNFT.NFT
			return locationNFT // as &AnyResource{MetadataViews.Resolver}
		
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// Set the Location Metadata for a locationID
		// either updates without affecting number minted
		access(all)
		fun setLocation(id: UInt64, maxEdition: UInt64, landmark: Bool, title: String, category: String, rarity: String, description: String, imageURL: String, cardURL: String, ipfsCID: String, location: String, state: String, country: String, continent: String, longitude: Fix64, lattitude: Fix64, elevationMeters: UFix64, metadata:{ String: String}){ 
			var totalMinted: UInt64 = 0
			if SilverlightLocationNFT.metadata[id] != nil{ 
				assert(SilverlightLocationNFT.metadata[id]?.isLocked! == false, message: "Set is locked! Cannot update metadata.")
				totalMinted = SilverlightLocationNFT.metadata[id]?.totalMinted!
			}
			SilverlightLocationNFT.metadata[id] = Metadata(locationID: id, maxEdition: maxEdition, landmark: landmark, title: title, category: category, rarity: rarity, description: description, imageURL: imageURL, cardURL: cardURL, ipfsCID: ipfsCID, location: location, state: state, country: country, continent: continent, longitude: longitude, lattitude: lattitude, elevationMeters: elevationMeters, metadata: metadata)
			SilverlightLocationNFT.metadata[id]?.setTotalMinted(totalMinted)
		}
		
		access(all)
		fun setLocationMetadata(id: UInt64, key: String, value: String){ 
			SilverlightLocationNFT.metadata[id]?.setMetadata(key, value)
		}
		
		access(all)
		fun lockLocation(id: UInt64){ 
			SilverlightLocationNFT.metadata[id]?.lock()
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun batchMintNFTs(recipient: &{SilverlightLocationNFT.SilverlightLocationNFTCollectionPublic}, locationID: UInt64, numberOfEditionsToMint: UInt64){ 
			pre{ 
				numberOfEditionsToMint > 0:
					"Cannot mint 0 NFTs!"
				SilverlightLocationNFT.metadata.containsKey(locationID):
					"LocationID not found!"
			}
			let totalMinted = SilverlightLocationNFT.metadata[locationID]?.totalMinted!
			assert(numberOfEditionsToMint <= SilverlightLocationNFT.metadata[locationID]?.maxEdition! - totalMinted, message: "Number of editions to mint exceeds max edition size.")
			var edition = totalMinted + 1
			while edition <= totalMinted + numberOfEditionsToMint{ 
				// create a new NFT
				var newNFT <- create NFT(locationID: locationID, edition: edition)
				
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-newNFT)
				SilverlightLocationNFT.totalSupply = SilverlightLocationNFT.totalSupply + 1
				edition = edition + 1
			}
		}
	}
	
	init(){ 
		self.currentOwnerByIDs ={} 
		self.resourceIDsByLocationID ={} 
		self.metadata ={} 
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initalize paths for scripts and transactions usage
		self.AdminStoragePath = /storage/SilverlightLocationAdmin
		self.CollectionStoragePath = /storage/SilverlightLocationNFTCollection
		self.CollectionPublicPath = /public/SilverlightLocationNFTCollection
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: SilverlightLocationNFT.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{SilverlightLocationNFT.SilverlightLocationNFTCollectionPublic}>(SilverlightLocationNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: SilverlightLocationNFT.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: SilverlightLocationNFT.AdminStoragePath)
		emit ContractInitialized()
	}
}
