/*
	authors: Joseph Djenandji, Matthew Balazsi, Jennifer McIntyre

	Description: 

	20-Jan-23	Bologna
	21-Jan-23	Bologna
	26-Jan-23	Antwerp
	28-Jan-23	Amsterdam
	29-Jan-23	Amsterdam
	05-Feb-23	Cologne
	06-Feb-23	Cologne
	08-Feb-23	Cologne
	13-Feb-23	Amsterdam
	15-Feb-23	Frankfurt
	16-Feb-23	Frankfurt
	20-Feb-23	Berlin
	21-Feb-23	Berlin
	24-Feb-23	Hamburg
	26-Feb-23	Herning
	27-Feb-23	Copenhagen
	27-Feb-23	Copenhagen
	05-Mar-23	Tampere
	09-Mar-23	Riga
	10-Mar-23	Kaunas
	12-Mar-23	Krakow
	14-Mar-23	Budapest
	16-Mar-23	Vienna
	17-Mar-23	Vienna
	20-Mar-23	Paris
	24-Mar-23	Barcelona
	25-Mar-23	Barcelona
	27-Mar-23	Lisbon

	This limited Lufthaus NFT was designed by Robbie Williams and Ed Godrich. 
	The NFT will provide access for future benefits across the Lufthaus community.

*/

// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"
// for tests
// import NonFungibleToken from "../"0xNonFungibleToken"/NonFungibleToken.cdc"
// import MetadataViews from "../"0xMetadataViews"/MetadataViews.cdc"
// import FungibleToken from "../"0xFungibleToken"/FungibleToken.cdc"
// for testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"
// for mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Lufthaus: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// MintPFPs contract Events
	// -----------------------------------------------------------------------
	// Emitted when the MintPFPs contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a new item was minted
	access(all)
	event ItemMinted(itemID: UInt64, merchantID: UInt32, name: String)
	
	// Item related events 
	//
	// Emitted when an Item is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted when an Item is deposited into a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emitted when an Item is withdrawn from a Collection
	access(all)
	event ItemMutated(id: UInt64, mutation: ItemData)
	
	// Emitted when adding a default royalty recipient
	access(all)
	event DefaultRoyaltyAdded(name: String, rate: UFix64)
	
	// Emitted when removing a default royalty recipient
	access(all)
	event DefaultRoyaltyRemoved(name: String)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event DefaultRoyaltyRateChanged(name: String, previousRate: UFix64, rate: UFix64)
	
	// Emitted when adding a royalty for a specific NFT
	access(all)
	event RoyaltyForPFPAdded(tokenID: UInt64, name: String, rate: UFix64)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event RoyaltyForPFPChanged(tokenID: UInt64, name: String, previousRate: UFix64, rate: UFix64)
	
	// Emitted when an existing Royalty rate is changed
	access(all)
	event RoyaltyForPFPRemoved(tokenID: UInt64, name: String)
	
	// Emitted when reverting the Royalty rate of a given NFT back to default settings
	access(all)
	event RoyaltyForPFPRevertedToDefault(tokenID: UInt64)
	
	// Emitted when an Item is destroyed
	access(all)
	event ItemDestroyed(id: UInt64)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MutatorStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// MintPFPs contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The ID that is used to create Admins. 
	// Every Admins should have a unique identifier.
	access(all)
	var nextAdminID: UInt32
	
	// The ID that is used to create Mutators. 
	// Every Mutators should have a unique identifier.
	access(all)
	var nextMutatorID: UInt32
	
	// If ever a mutator goes rouge, we would like to be able to have the option of
	// locking the mutator's ability to mutate NFTs. Additionally, we would like
	// to be able to unlock them too.
	access(all)
	var lockedMutators:{ UInt32: Bool}
	
	// The merchant ID (see MintPFPs)
	access(all)
	var merchantID: UInt32
	
	// The total number of MintPFPs NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as global nft IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// Mutations are upgrades or modifications of the NFTs' metadata.
	// These will be store at the contract level, allowing dapps administrators to 
	// mutate NFTs even after they have been transferred to other wallets.
	// It also ensures that the original metadata of the NFT will never be deleted
	// offering some protection to the holder.
	access(all)
	var mutations:{ UInt64: ItemData}
	
	// the default royalties will be applied to all PFPs unless a specific royalty 
	// is set for a given PFP
	access(all)
	var defaultRoyalties:{ String: MetadataViews.Royalty}
	
	// If a specific NFT requires their own royalties, 
	// the default royalties can be overwritten in this dictionary.
	access(all)
	var royaltiesForSpecificPFP:{ UInt64:{ String: MetadataViews.Royalty}}
	
	access(all)
	var ExternalURL: MetadataViews.ExternalURL
	
	access(all)
	var Socials:{ String: MetadataViews.ExternalURL}
	
	access(all)
	var Description: String
	
	access(all)
	var SquareImage: MetadataViews.Media
	
	access(all)
	var BannerImage: MetadataViews.Media
	
	// -----------------------------------------------------------------------
	// MintPFPs contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// The struct representing an NFT Item data
	access(all)
	struct ItemData{ 
		// The ID of the merchant 
		access(all)
		let merchantID: UInt32
		
		// the name
		access(all)
		let name: String
		
		// the description
		access(all)
		let description: String
		
		// The thumbnail
		access(all)
		let thumbnail: String
		
		// the thumbnail cid (if thumbnailHosting is IPFS )
		access(all)
		let thumbnailCID: String
		
		// the thumbnail path (if thumbnailHosting is IPFS )
		access(all)
		let thumbnailPathIPFS: String?
		
		// The mimetype of the thumbnail
		access(all)
		let thumbnailMimeType: String
		
		// The method of hosting the thumbnail (IPFS | HTTPFile)
		access(all)
		let thumbnailHosting: String
		
		// the media file
		access(all)
		let mediaURL: String
		
		// the media cid (if mediaHosting is IPFS )
		access(all)
		let mediaCID: String
		
		// the media path (if mediaHosting is IPFS )
		access(all)
		let mediaPathIPFS: String?
		
		// the mimetype
		access(all)
		let mimetype: String
		
		// the method of hosting the media file (IPFS | HTTPFile)
		access(all)
		let mediaHosting: String
		
		// the attributes
		access(all)
		let attributes:{ String: String}
		
		// rarity
		access(all)
		let rarity: String
		
		init(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			self.merchantID = Lufthaus.merchantID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.thumbnailMimeType = thumbnailMimeType
			self.thumbnailCID = thumbnailCID
			self.thumbnailPathIPFS = thumbnailPathIPFS
			self.thumbnailHosting = thumbnailHosting
			self.mediaURL = mediaURL
			self.mediaCID = mediaCID
			self.mediaPathIPFS = mediaPathIPFS
			self.mediaHosting = mediaHosting
			self.mimetype = mimetype
			self.attributes = attributes
			self.rarity = rarity
		}
	}
	
	// The resource that represents the Item NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Global unique item ID
		access(all)
		let id: UInt64
		
		// Struct of MintPFPs metadata
		access(all)
		let data: ItemData
		
		init(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			Lufthaus					// Increment the global Item IDs
					.totalSupply = Lufthaus.totalSupply + 1 as UInt64
			self.id = Lufthaus.totalSupply
			// Set the metadata struct
			self.data = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			emit ItemMinted(itemID: self.id, merchantID: Lufthaus.merchantID, name: name)
		}
		
		access(all)
		fun getSerialNumber(): UInt64{ 
			return self.id
		}
		
		access(all)
		fun getOriginalData(): ItemData{ 
			return self.data
		}
		
		access(all)
		fun getMutation(): ItemData?{ 
			return Lufthaus.mutations[self.id]
		}
		
		access(all)
		fun getData(): ItemData{ 
			return self.getMutation() ?? self.getOriginalData()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let data = self.getData()
					var thumbnail:{ MetadataViews.File} = MetadataViews.HTTPFile(url: data.thumbnail)
					if data.thumbnailHosting == "IPFS"{ 
						thumbnail = MetadataViews.IPFSFile(cid: data.thumbnailCID, path: data.thumbnailPathIPFS)
					}
					return MetadataViews.Display(name: data.name, description: data.description, thumbnail: thumbnail)
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.data.name, number: UInt64(1), max: 1)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Royalties>():
					let royaltiesDictionary = Lufthaus.royaltiesForSpecificPFP[self.id] ?? Lufthaus.defaultRoyalties
					var royalties: [MetadataViews.Royalty] = []
					for royaltyName in royaltiesDictionary.keys{ 
						royalties.append(royaltiesDictionary[royaltyName]!)
					}
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					return Lufthaus.ExternalURL
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Lufthaus.CollectionStoragePath, publicPath: Lufthaus.CollectionPublicPath, publicCollection: Type<&Lufthaus.Collection>(), publicLinkedType: Type<&Lufthaus.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Lufthaus.createEmptyCollection(nftType: Type<@Lufthaus.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let data = self.getData()
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: data.thumbnail), mediaType: data.thumbnailMimeType)
					return MetadataViews.NFTCollectionDisplay(name: "Lufthaus", description: Lufthaus.Description, externalURL: Lufthaus.ExternalURL, squareImage: Lufthaus.SquareImage, bannerImage: Lufthaus.BannerImage, socials: Lufthaus.Socials)
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits = ["name", "description", "thumbnail", "externalUrl"]
					let data = self.getData()
					let dict = data.attributes
					let traitsView = MetadataViews.dictToTraits(dict: dict, excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	// If the Item is destroyed, emit an event to indicate 
	// to outside ovbservers that it has been destroyed
	}
	
	// Mutator is an authorization resource that allows for the mutations of NFTs 
	access(all)
	resource Mutator{ 
		access(all)
		let id: UInt32
		
		init(id: UInt32){ 
			self.id = id
		}
		
		// Mutator role should only be able to mutate a NFT
		access(all)
		fun mutatePFP(tokenID: UInt64, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			pre{ 
				tokenID <= Lufthaus.totalSupply:
					"the tokenID does not exist"
			}
			if Lufthaus.lockedMutators[self.id] != true{ 
				let mutation = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
				Lufthaus.mutations[tokenID] = mutation
				emit ItemMutated(id: tokenID, mutation: mutation)
			} else{ 
				log("Cannot let mutator mutate")
			}
		}
	}
	
	// Admin is a special authorization resource that 
	// allows the owner to perform important functions to modify the 
	// various aspects of the Editions and Items
	//
	access(all)
	resource Admin{ 
		access(all)
		let id: UInt32
		
		init(id: UInt32){ 
			self.id = id
		}
		
		access(all)
		fun setExternalURL(url: String){ 
			Lufthaus.ExternalURL = MetadataViews.ExternalURL(url)
		}
		
		access(all)
		fun addSocial(key: String, url: String):{ String: MetadataViews.ExternalURL}{ 
			Lufthaus.Socials.insert(key: key, MetadataViews.ExternalURL(url))
			return Lufthaus.getSocials()
		}
		
		access(all)
		fun removeSocial(key: String):{ String: MetadataViews.ExternalURL}{ 
			Lufthaus.Socials.remove(key: key)
			return Lufthaus.getSocials()
		}
		
		access(all)
		fun setDescription(description: String){ 
			Lufthaus.Description = description
		}
		
		access(all)
		fun setSquareImage(url: String, mediaType: String){ 
			Lufthaus.SquareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: url), mediaType: mediaType)
		}
		
		access(all)
		fun setBannerImage(url: String, mediaType: String){ 
			Lufthaus.BannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: url), mediaType: mediaType)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			let newID = Lufthaus.nextAdminID
			// Increment the ID so that it isn't used again
			Lufthaus.nextAdminID = Lufthaus.nextAdminID + 1 as UInt32
			return <-create Admin(id: newID)
		}
		
		// createNewMutator creates a new Mutator resource
		access(all)
		fun createNewMutator(): @Mutator{ 
			let newID = Lufthaus.nextMutatorID
			// Increment the ID so that it isn't used again
			Lufthaus.nextMutatorID = Lufthaus.nextMutatorID + 1 as UInt32
			return <-create Mutator(id: newID)
		}
		
		// Locks a mutator
		access(all)
		fun lockMutator(id: UInt32): Int{ 
			Lufthaus.lockedMutators.insert(key: id, true)
			return Lufthaus.lockedMutators.length
		}
		
		// Unlocks a mutator
		access(all)
		fun unlockMutator(id: UInt32): Int{ 
			Lufthaus.lockedMutators.remove(key: id)
			return Lufthaus.lockedMutators.length
		}
		
		access(all)
		fun setMerchantID(merchantID: UInt32): UInt32{ 
			Lufthaus.merchantID = merchantID
			return Lufthaus.merchantID
		}
		
		access(all)
		fun mintPFP(name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String): @NFT{ 
			// Mint the new item
			let newItem: @NFT <- create NFT(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			return <-newItem
		}
		
		access(all)
		fun batchMintPFP(quantity: UInt32, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String): @Collection{ 
			var i: UInt32 = 0
			let newCollection <- create Collection()
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintPFP(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity))
				i = i + 1 as UInt32
			}
			return <-newCollection
		}
		
		access(all)
		fun mutatePFP(tokenID: UInt64, name: String, description: String, thumbnail: String, thumbnailCID: String, thumbnailPathIPFS: String?, thumbnailMimeType: String, thumbnailHosting: String, mediaURL: String, mediaCID: String, mediaPathIPFS: String?, mimetype: String, mediaHosting: String, attributes:{ String: String}, rarity: String){ 
			pre{ 
				tokenID <= Lufthaus.totalSupply:
					"the tokenID does not exist"
			}
			let mutation = ItemData(name: name, description: description, thumbnail: thumbnail, thumbnailCID: thumbnailCID, thumbnailPathIPFS: thumbnailPathIPFS, thumbnailMimeType: thumbnailMimeType, thumbnailHosting: thumbnailHosting, mediaURL: mediaURL, mediaCID: mediaCID, mediaPathIPFS: mediaPathIPFS, mimetype: mimetype, mediaHosting: mediaHosting, attributes: attributes, rarity: rarity)
			Lufthaus.mutations[tokenID] = mutation
			emit ItemMutated(id: tokenID, mutation: mutation)
		}
		
		// addDefaultRoyalty adds a new default recipient for the cut of the sale
		//
		// Parameters: name: the key to store the new royalty
		//			 recipientAddress: the wallet address of the recipient of the cut of the sale
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(all)
		fun addDefaultRoyalty(name: String, royalty: MetadataViews.Royalty, rate: UFix64){ 
			pre{ 
				Lufthaus.defaultRoyalties[name] == nil:
					"The royalty with that name already exists"
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			Lufthaus.defaultRoyalties[name] = royalty
		// emit DefaultRoyaltyAdded(name: name, rate: rate)
		}
		
		// changeDefaultRoyaltyRate updates a recipient's part of the cut of the sale
		//
		// Parameters: name: the key of the recipient to update
		//			 rate: the new percentage of the sale that goes to that recipient
		//
		access(all)
		fun changeDefaultRoyaltyRate(name: String, rate: UFix64){ 
			pre{ 
				Lufthaus.defaultRoyalties[name] != nil:
					"The royalty with that name does not exist"
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			let royalty = Lufthaus.defaultRoyalties[name]!
			let previousRate = royalty.cut
			let previousRecipientAddress = royalty.receiver
			Lufthaus.defaultRoyalties[name] = MetadataViews.Royalty(receiver: previousRecipientAddress, cut: UFix64(rate), description: "Lufthaus Royalties")
			emit DefaultRoyaltyRateChanged(name: name, previousRate: previousRate, rate: rate)
		}
		
		// removeDefaultRoyalty removes a default recipient from the cut of the sale
		//
		// Parameters: name: the key to store the royalty to remove
		access(all)
		fun removeDefaultRoyalty(name: String){ 
			pre{ 
				Lufthaus.defaultRoyalties[name] != nil:
					"The royalty with that name does not exist"
			}
			Lufthaus.defaultRoyalties.remove(key: name)
			emit DefaultRoyaltyRemoved(name: name)
		}
		
		// addRoyaltyForPFP adds a new recipient for the cut of the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the new royalty
		//			 recipientAddress: the wallet address of the recipient of the cut of the sale
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(all)
		fun addRoyaltyForPFP(tokenID: UInt64, name: String, royalty: MetadataViews.Royalty, rate: UFix64){ 
			pre{ 
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			if Lufthaus.royaltiesForSpecificPFP.containsKey(tokenID) == false{ 
				let newEntry:{ String: MetadataViews.Royalty} ={} 
				newEntry.insert(key: name, royalty)
				(Lufthaus.royaltiesForSpecificPFP!).insert(key: tokenID, newEntry)
				emit RoyaltyForPFPAdded(tokenID: tokenID, name: name, rate: rate)
				return
			}
			// the TokenID already has an entry
			if (Lufthaus.royaltiesForSpecificPFP[tokenID]!).containsKey(name){ 
				// the entry already exists
				panic("The royalty with that name already exists")
			}
			(Lufthaus.royaltiesForSpecificPFP[tokenID]!).insert(key: name, royalty)
			emit RoyaltyForPFPAdded(tokenID: tokenID, name: name, rate: rate)
		}
		
		// changeRoyaltyRateForPFP changes the royalty rate for the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the new royalty
		//			 rate: the percentage of the sale that goes to that recipient
		//
		access(all)
		fun changeRoyaltyRateForPFP(tokenID: UInt64, name: String, rate: UFix64){ 
			pre{ 
				rate > 0.0:
					"Cannot set rate to less than 0%"
				rate <= 1.0:
					"Cannot set rate to more than 100%"
			}
			let previousRoyalty: MetadataViews.Royalty = (Lufthaus.royaltiesForSpecificPFP[tokenID]!)[name]!
			let newRoyalty = MetadataViews.Royalty(receiver: previousRoyalty.receiver, cut: UFix64(rate), description: "Lufthaus Royalties")
			(Lufthaus.royaltiesForSpecificPFP[tokenID]!).insert(key: name, newRoyalty)
			emit RoyaltyForPFPChanged(tokenID: tokenID, name: name, previousRate: previousRoyalty.cut, rate: rate)
		}
		
		// removeRoyaltyForPFP changes the royalty rate for the sale on a specific PFP
		//
		// Parameters: tokenID: the unique ID of the PFP
		//			 name: the key to store the royalty to remove
		//
		access(all)
		fun removeRoyaltyForPFP(tokenID: UInt64, name: String){ 
			(Lufthaus.royaltiesForSpecificPFP[tokenID]!).remove(key: name)
			emit RoyaltyForPFPRemoved(tokenID: tokenID, name: name)
		}
		
		// revertRoyaltyForPFPToDefault removes the royalty setttings for the specific PFP
		// so it uses the default roylaties going forward
		//
		// Parameters: tokenID: the unique ID of the PFP
		//
		access(all)
		fun revertRoyaltyForPFPToDefault(tokenID: UInt64){ 
			Lufthaus.royaltiesForSpecificPFP.remove(key: tokenID)
			emit RoyaltyForPFPRevertedToDefault(tokenID: tokenID)
		}
	}
	
	// This is the interface that users can cast their MintPFPs Collection as
	// to allow others to deposit MintPFPs into their Collection. It also allows for reading
	// the IDs of MintPFPs in the Collection.
	access(all)
	resource interface LufthausCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowLufthaus(id: UInt64): &Lufthaus.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PFP reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection is a resource that every user who owns NFTs 
	// will store in their account to manage their NFTS
	//
	access(all)
	resource Collection: LufthausCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of MintPFPs conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes a MintPFPs from the Collection and moves it to the caller
		//
		// Parameters: withdrawID: The ID of the NFT 
		// that is to be removed from the Collection
		//
		// returns: @NonFungibleToken.NFT the token that was withdrawn
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: PFP does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn MintPFPs items
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				let token <- self.withdraw(withdrawID: id)
				batchCollection.deposit(token: <-token)
			}
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a MintPFPs and adds it to the Collections dictionary
		//
		// Paramters: token: the NFT to be deposited in the collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as a MintPFPs NFT to make sure
			// it is the correct type
			let token <- token as! @Lufthaus.NFT
			// Get the token's ID
			let id = token.id
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			// Destroy the empty Collection
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a MintPFPs in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		//
		// Note: This only allows the caller to read the ID of the NFT,
		// not any MintPFPs specific data. Please use borrowLufthauss to 
		// read MintPFPs data.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowLufthaus returns a borrowed reference to a MintPFPs
		// so that the caller can read data and call methods from it.
		// They can use this to read its editionID, editionNumber,
		// or any edition data associated with it by
		// getting the editionID and reading those fields from
		// the smart contract.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		fun borrowLufthaus(id: UInt64): &Lufthaus.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Lufthaus.NFT
			} else{ 
				return nil
			}
		}
		
		// Making the collection conform to MetadataViews.Resolver
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let LufthausNFT = nft as! &Lufthaus.NFT
			return LufthausNFT as &{ViewResolver.Resolver}
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
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed
	//
	}
	
	// -----------------------------------------------------------------------
	// MintPFPs contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection creates a new, empty Collection object so that
	// a user can store it in their account storage.
	// Once they have a Collection in their storage, they are able to receive
	// MintPFPs in transactions.
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Lufthaus.Collection()
	}
	
	access(all)
	fun createEmptyMintPFPsCollection(): @Lufthaus.Collection{ 
		return <-create Lufthaus.Collection()
	}
	
	access(all)
	fun getExternalURL(): MetadataViews.ExternalURL{ 
		return Lufthaus.ExternalURL
	}
	
	access(all)
	fun getSocials():{ String: MetadataViews.ExternalURL}{ 
		return Lufthaus.Socials
	}
	
	access(all)
	fun getDescription(): String{ 
		return Lufthaus.Description
	}
	
	access(all)
	fun getSquareImage(): MetadataViews.Media{ 
		return Lufthaus.SquareImage
	}
	
	access(all)
	fun getBannerImage(): MetadataViews.Media{ 
		return Lufthaus.BannerImage
	}
	
	// Returns all of the locked mutator IDs
	access(all)
	fun getLockedMutators():{ UInt32: Bool}{ 
		return Lufthaus.lockedMutators
	}
	
	// getMerchantID returns the merchant ID
	access(all)
	fun getMerchantID(): UInt32{ 
		return self.merchantID
	}
	
	// getDefaultRoyalties returns the default royalties
	access(all)
	fun getDefaultRoyalties():{ String: MetadataViews.Royalty}{ 
		return self.defaultRoyalties
	}
	
	// getDefaultRoyalties returns the default royalties
	access(all)
	fun getDefaultRoyaltyNames(): [String]{ 
		return self.defaultRoyalties.keys
	}
	
	// getDefaultRoyaltyRate returns a royalty object
	access(all)
	fun getDefaultRoyalty(name: String): MetadataViews.Royalty?{ 
		return self.defaultRoyalties[name]
	}
	
	// returns the default
	access(all)
	fun getTotalDefaultRoyaltyRate(): UFix64{ 
		var totalRoyalty = 0.0
		for key in self.defaultRoyalties.keys{ 
			let royal = self.defaultRoyalties[key] ?? panic("Royalty does not exist")
			totalRoyalty = totalRoyalty + royal.cut
		}
		return totalRoyalty
	}
	
	// getRoyaltiesForPFP returns the specific royalties for a PFP or the default royalties
	access(all)
	fun getRoyaltiesForPFP(tokenID: UInt64):{ String: MetadataViews.Royalty}{ 
		return self.royaltiesForSpecificPFP[tokenID] ?? self.getDefaultRoyalties()
	}
	
	//  getRoyaltyNamesForPFP returns the  royalty names for a specific PFP or the default royalty names
	access(all)
	fun getRoyaltyNamesForPFP(tokenID: UInt64): [String]{ 
		return self.royaltiesForSpecificPFP[tokenID]?.keys ?? self.getDefaultRoyaltyNames()
	}
	
	// getRoyaltyNamesForPFP returns a given royalty for a specific PFP or the default royalty names
	access(all)
	fun getRoyaltyForPFP(tokenID: UInt64, name: String): MetadataViews.Royalty?{ 
		if self.royaltiesForSpecificPFP.containsKey(tokenID){ 
			let royaltiesForPFP:{ String: MetadataViews.Royalty} = self.royaltiesForSpecificPFP[tokenID]!
			return royaltiesForPFP[name]!
		}
		// if no specific royalty is set
		return self.getDefaultRoyalty(name: name)
	}
	
	// getTotalRoyaltyRateForPFP returns the total royalty rate for a give PFP
	access(all)
	fun getTotalRoyaltyRateForPFP(tokenID: UInt64): UFix64{ 
		var totalRoyalty = 0.0
		let royalties = self.getRoyaltiesForPFP(tokenID: tokenID)
		for key in royalties.keys{ 
			let royal = royalties[key] ?? panic("Royalty does not exist")
			totalRoyalty = totalRoyalty + royal.cut
		}
		return totalRoyalty
	}
	
	// -----------------------------------------------------------------------
	// MintPFPs initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.totalSupply = 0
		self.merchantID = 89
		self.mutations ={} 
		self.defaultRoyalties ={} 
		self.royaltiesForSpecificPFP ={} 
		self.lockedMutators ={} 
		self.ExternalURL = MetadataViews.ExternalURL("https://www.armadamusic.com/artists/lufthaus")
		self.Socials ={} 
		self.Description = "Lufthaus contract"
		self.SquareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://mint-store-metadata.s3.us-east-2.amazonaws.com/lufthaus/Laufthause+1+x+1.png"), mediaType: "image/png")
		self.BannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://mint-store-metadata.s3.us-east-2.amazonaws.com/lufthaus/Laufthause+2+x+1.png"), mediaType: "image/png")
		self.CollectionStoragePath = /storage/LufthausCollection
		self.CollectionPublicPath = /public/LufthausCollection
		self.AdminStoragePath = /storage/LufthausAdmin
		self.MutatorStoragePath = /storage/LufthausMutator
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{LufthausCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		// Put the admin ressource in storage
		self.account.storage.save<@Admin>(<-create Admin(id: 1), to: self.AdminStoragePath)
		self.nextAdminID = 2
		// Put the admin ressource in storage
		self.account.storage.save<@Mutator>(<-create Mutator(id: 1), to: self.MutatorStoragePath)
		self.nextMutatorID = 2
		emit ContractInitialized()
	}
}
