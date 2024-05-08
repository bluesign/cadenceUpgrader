import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Gaia
// NFT an open NFT standard!
//
access(all)
contract Gaia: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event TemplateCreated(id: UInt64, metadata:{ String: String})
	
	access(all)
	event SetCreated(setID: UInt64, name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64)
	
	access(all)
	event SetAddedAllowedAccount(setID: UInt64, allowedAccount: Address)
	
	access(all)
	event SetRemovedAllowedAccount(setID: UInt64, allowedAccount: Address)
	
	access(all)
	event TemplateAddedToSet(setID: UInt64, templateID: UInt64)
	
	access(all)
	event TemplateLockedFromSet(setID: UInt64, templateID: UInt64, numNFTs: UInt64)
	
	access(all)
	event SetLocked(setID: UInt64)
	
	access(all)
	event Minted(assetID: UInt64, templateID: UInt64, setID: UInt64, mintNumber: UInt64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Variable size dictionary of Play structs
	access(self)
	var templateDatas:{ UInt64: Template}
	
	// Variable size dictionary of SetData structs
	access(self)
	var setDatas:{ UInt64: SetData}
	
	// Variable size dictionary of Set resources
	access(self)
	var sets: @{UInt64: Set}
	
	// totalSupply
	// The total number of Gaia that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// The ID that is used to create Templates.
	// Every time a Template is created, templateID is assigned
	// to the new Template's ID and then is incremented by 1.
	access(all)
	var nextTemplateID: UInt64
	
	// The ID that is used to create Sets. Every time a Set is created
	// setID is assigned to the new set's ID and then is incremented by 1.
	access(all)
	var nextSetID: UInt64
	
	access(all)
	fun royaltyAddress(): Address{ 
		return 0x9eef2e4511390ce4
	}
	
	// -----------------------------------------------------------------------
	// Gaia contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// Template is a Struct that holds metadata associated
	// with a specific NFT template
	// NFTs will all reference a single template as the owner of
	// its metadata. The templates are publicly accessible, so anyone can
	// read the metadata associated with a specific template ID
	//
	access(all)
	struct Template{ 
		
		// The unique ID for the template
		access(all)
		let templateID: UInt64
		
		// Stores all the metadata about the template as a string mapping
		// This is not the long term way NFT metadata will be stored.
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			pre{ 
				metadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.templateID = Gaia.nextTemplateID
			self.metadata = metadata
			
			// Increment the ID so that it isn't used again
			Gaia.nextTemplateID = Gaia.nextTemplateID + 1 as UInt64
			emit TemplateCreated(id: self.templateID, metadata: metadata)
		}
	}
	
	// A Set is a grouping of Templates that have occured in the real world
	// that make up a related group of collectibles, like sets of Magic cards.
	// A Template can exist in multiple different sets.
	// SetData is a struct that is stored in a field of the contract.
	// Anyone can query the constant information
	// about a set by calling various getters located
	// at the end of the contract. Only the admin has the ability
	// to modify any data in the private Set resource.
	//
	access(all)
	struct SetData{ 
		
		// Unique ID for the Set
		access(all)
		let setID: UInt64
		
		// Name of the Set
		access(all)
		let name: String
		
		// Brief description of the Set
		access(all)
		let description: String
		
		// Set cover image
		access(all)
		let imageURI: String
		
		// Set website url
		access(all)
		let website: String
		
		// Set creator account address
		access(all)
		let creator: Address
		
		// Accounts allowed to mint
		access(self)
		let allowedAccounts: [Address]
		
		access(all)
		view fun returnAllowedAccounts(): [Address]{ 
			return self.allowedAccounts
		}
		
		// Set marketplace fee
		access(all)
		let marketFee: UFix64
		
		init(name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64){ 
			pre{ 
				name.length > 0:
					"New set name cannot be empty"
				description.length > 0:
					"New set description cannot be empty"
				imageURI.length > 0:
					"New set imageURI cannot be empty"
				creator != nil:
					"Creator must not be nil"
				marketFee >= 0.0 && marketFee <= 0.15:
					"Market fee must be a number between 0.00 and 0.15"
			}
			self.setID = Gaia.nextSetID
			self.name = name
			self.description = description
			self.website = website
			self.imageURI = imageURI
			self.creator = creator
			self.allowedAccounts = [creator, Gaia.account.address]
			self.marketFee = marketFee
			
			// Increment the setID so that it isn't used again
			Gaia.nextSetID = Gaia.nextSetID + 1 as UInt64
			emit SetCreated(setID: self.setID, name: name, description: description, website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)
		}
		
		access(all)
		fun addAllowedAccount(account: Address){ 
			pre{ 
				!self.allowedAccounts.contains(account):
					"Account already allowed"
			}
			self.allowedAccounts.append(account)
			emit SetAddedAllowedAccount(setID: self.setID, allowedAccount: account)
		}
		
		access(all)
		fun removeAllowedAccount(account: Address){ 
			pre{ 
				self.creator != account:
					"Cannot remove set creator"
				self.allowedAccounts.contains(account):
					"Not in allowed accounts"
			}
			var index = 0
			for acc in self.allowedAccounts{ 
				if acc == account{ 
					self.allowedAccounts.remove(at: index)
					break
				}
				index = index + 1
			}
			emit SetRemovedAllowedAccount(setID: self.setID, allowedAccount: account)
		}
	}
	
	// Set is a resource type that contains the functions to add and remove
	// Templates from a set and mint NFTs.
	//
	// It is stored in a private field in the contract so that
	// the admin resource can call its methods.
	//
	// The admin can add Templates to a Set so that the set can mint NFTs
	// that reference that template data.
	// The NFTs that are minted by a Set will be listed as belonging to
	// the Set that minted it, as well as the Template it references.
	//
	// Admin can also lock Templates from the Set, meaning that the lockd
	// Template can no longer have NFTs minted from it.
	//
	// If the admin locks the Set, no more Templates can be added to it, but
	// NFTs can still be minted.
	//
	// If lockAll() and lock() are called back-to-back,
	// the Set is closed off forever and nothing more can be done with it.
	access(all)
	resource Set{ 
		
		// Unique ID for the set
		access(all)
		let setID: UInt64
		
		// Array of templates that are a part of this set.
		// When a template is added to the set, its ID gets appended here.
		// The ID does not get removed from this array when a templates is locked.
		access(all)
		var templates: [UInt64]
		
		// Map of template IDs that Indicates if a template in this Set can be minted.
		// When a templates is added to a Set, it is mapped to false (not locked).
		// When a templates is locked, this is set to true and cannot be changed.
		access(all)
		var lockedTemplates:{ UInt64: Bool}
		
		// Indicates if the Set is currently locked.
		// When a Set is created, it is unlocked
		// and templates are allowed to be added to it.
		// When a set is locked, templates cannot be added.
		// A Set can never be changed from locked to unlocked,
		// the decision to lock a Set it is final.
		// If a Set is locked, templates cannot be added, but
		// NFTs can still be minted from templates
		// that exist in the Set.
		access(all)
		var locked: Bool
		
		// Mapping of Template IDs that indicates the number of NFTs
		// that have been minted for specific Templates in this Set.
		// When a NFT is minted, this value is stored in the NFT to
		// show its place in the Set, eg. 13 of 60.
		access(all)
		var numberMintedPerTemplate:{ UInt64: UInt64}
		
		init(name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64){ 
			self.setID = Gaia.nextSetID
			self.templates = []
			self.lockedTemplates ={} 
			self.locked = false
			self.numberMintedPerTemplate ={} 
			// Create a new SetData for this Set and store it in contract storage
			Gaia.setDatas[self.setID] = SetData(name: name, description: description, website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)
		}
		
		// addTemplate adds a template to the set
		//
		// Parameters: templateID: The ID of the template that is being added
		//
		// Pre-Conditions:
		// The template needs to be an existing template
		// The Set needs to be not locked
		// The template can't have already been added to the Set
		//
		access(all)
		fun addTemplate(templateID: UInt64){ 
			pre{ 
				Gaia.templateDatas[templateID] != nil:
					"Cannot add the Template to Set: Template doesn't exist."
				!self.locked:
					"Cannot add the template to the Set after the set has been locked."
				self.numberMintedPerTemplate[templateID] == nil:
					"The template has already beed added to the set."
			}
			
			// Add the Play to the array of Plays
			self.templates.append(templateID)
			
			// Open the Play up for minting
			self.lockedTemplates[templateID] = false
			
			// Initialize the Moment count to zero
			self.numberMintedPerTemplate[templateID] = 0
			emit TemplateAddedToSet(setID: self.setID, templateID: templateID)
		}
		
		// addTemplates adds multiple templates to the Set
		//
		// Parameters: templateIDs: The IDs of the templates that are being added
		//
		access(all)
		fun addTemplates(templateIDs: [UInt64]){ 
			for template in templateIDs{ 
				self.addTemplate(templateID: template)
			}
		}
		
		// retirePlay retires a Play from the Set so that it can't mint new Moments
		//
		// Parameters: playID: The ID of the Play that is being retired
		//
		// Pre-Conditions:
		// The Play is part of the Set and not retired (available for minting).
		//
		access(all)
		fun lockTemplate(templateID: UInt64){ 
			pre{ 
				self.lockedTemplates[templateID] != nil:
					"Cannot lock the template: Template doesn't exist in this set!"
			}
			if !self.lockedTemplates[templateID]!{ 
				self.lockedTemplates[templateID] = true
				emit TemplateLockedFromSet(setID: self.setID, templateID: templateID, numNFTs: self.numberMintedPerTemplate[templateID]!)
			}
		}
		
		// lockAll lock all the templates in the Set
		// Afterwards, none of the locked templates will be able to mint new NFTs
		//
		access(all)
		fun lockAll(){ 
			for template in self.templates{ 
				self.lockTemplate(templateID: template)
			}
		}
		
		// lock() locks the Set so that no more Templates can be added to it
		//
		// Pre-Conditions:
		// The Set should not be locked
		access(all)
		fun lock(){ 
			if !self.locked{ 
				self.locked = true
				emit SetLocked(setID: self.setID)
			}
		}
		
		// mintNFT mints a new NFT and returns the newly minted NFT
		//
		// Parameters: templateID: The ID of the Template that the NFT references
		//
		// Pre-Conditions:
		// The Template must exist in the Set and be allowed to mint new NFTs
		//
		// Returns: The NFT that was minted
		//
		access(all)
		fun mintNFT(templateID: UInt64): @NFT{ 
			pre{ 
				self.lockedTemplates[templateID] != nil:
					"Cannot mint the NFT: This template doesn't exist."
				!self.lockedTemplates[templateID]!:
					"Cannot mint the NFT from this template: This template has been locked."
			}
			
			// Gets the number of NFTs that have been minted for this Template
			// to use as this NFT's serial number
			let numInTemplate = self.numberMintedPerTemplate[templateID]!
			
			// Mint the new moment
			let newNFT: @NFT <- create NFT(mintNumber: numInTemplate + 1 as UInt64, templateID: templateID, setID: self.setID)
			
			// Increment the count of Moments minted for this Play
			self.numberMintedPerTemplate[templateID] = numInTemplate + 1 as UInt64
			return <-newNFT
		}
		
		// batchMintNFT mints an arbitrary quantity of NFTs
		// and returns them as a Collection
		//
		// Parameters: templateID: the ID of the Template that the NFTs are minted for
		//			 quantity: The quantity of NFTs to be minted
		//
		// Returns: Collection object that contains all the NFTs that were minted
		//
		access(all)
		fun batchMintNFT(templateID: UInt64, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(templateID: templateID))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
	}
	
	access(all)
	struct NFTData{ 
		
		// The ID of the Set that the Moment comes from
		access(all)
		let setID: UInt64
		
		// The ID of the Play that the Moment references
		access(all)
		let templateID: UInt64
		
		// The place in the edition that this Moment was minted
		// Otherwise know as the serial number
		access(all)
		let mintNumber: UInt64
		
		init(setID: UInt64, templateID: UInt64, mintNumber: UInt64){ 
			self.setID = setID
			self.templateID = templateID
			self.mintNumber = mintNumber
		}
	}
	
	// NFT
	// A Flow Asset as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// Struct of NFT metadata
		access(all)
		let data: NFTData
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>()]
		}
		
		access(contract)
		fun parseIPFSURICID(uri: String): String{ 
			return uri.slice(from: 7, upTo: 53)
		}
		
		access(contract)
		fun parseIPFSURIPath(uri: String): String?{ 
			return uri.length > 55 ? uri.slice(from: 54, upTo: uri.length) : nil
		}
		
		access(contract)
		fun parseThumbnail(img: String):{ MetadataViews.File}?{ 
			var file:{ MetadataViews.File}? = nil
			if img.slice(from: 0, upTo: 7) == "ipfs://"{ 
				file = MetadataViews.IPFSFile(cid: self.parseIPFSURICID(uri: img), path: self.parseIPFSURIPath(uri: img))
			} else{ 
				file = MetadataViews.HTTPFile(url: img)
			}
			return file
		}
		
		access(contract)
		fun parseExternalURL(setData: SetData): MetadataViews.ExternalURL{ 
			let baseURI = "https://ongaia.com/"
			return MetadataViews.ExternalURL(baseURI)
		}
		
		access(contract)
		fun getCollectionSquareImage(setData: SetData): MetadataViews.Media{ 
			return MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d3ihoi13u6g9y2.cloudfront.net/metadata/ballerz-square.png"), mediaType: "image/png")
		}
		
		access(contract)
		fun getCollectionBannerImage(setData: SetData): MetadataViews.Media{ 
			return MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d3ihoi13u6g9y2.cloudfront.net/metadata/ballerz-banner.png"), mediaType: "image/png")
		}
		
		access(contract)
		fun parseTraits(metadata:{ String: String}, setData: SetData): MetadataViews.Traits?{ 
			var traits: [MetadataViews.Trait] = []
			var bypass: [String] = ["id", "name", "title", "description", "img", "url", "uri", "video", "editions", "series", "series_description", "set", "setID"]
			for key in metadata.keys{ 
				if bypass.contains(key){ 
					continue
				}
				traits.append(MetadataViews.Trait(name: key, value: metadata[key]!, displayType: nil, rarity: nil))
			}
			traits.append(MetadataViews.Trait(name: "setID", value: setData.setID.toString(), displayType: nil, rarity: nil))
			traits.append(MetadataViews.Trait(name: "set", value: setData.name, displayType: nil, rarity: nil))
			return MetadataViews.Traits(traits)
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var setData: SetData = Gaia.getSetInfo(setID: self.data.setID)!
			var templateMetadata:{ String: String} = Gaia.getTemplateMetaData(templateID: self.data.templateID)!
			switch view{ 
				case Type<MetadataViews.NFTView>():
					let viewResolver = &self as &{ViewResolver.Resolver}
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
				case Type<MetadataViews.Display>():
					var name: String = setData.name == "Ballerz" ? "Baller #".concat(templateMetadata["id"]!) : templateMetadata["title"]!
					var description: String = templateMetadata["description"]!
					var thumbnail:{ MetadataViews.File}? = self.parseThumbnail(img: templateMetadata["img"]!)
					return MetadataViews.Display(name: name, description: description, thumbnail: thumbnail!)
				case Type<MetadataViews.ExternalURL>():
					return self.parseExternalURL(setData: setData)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Gaia.CollectionStoragePath, publicPath: Gaia.CollectionPublicPath, publicCollection: Type<&Gaia.Collection>(), publicLinkedType: Type<&Gaia.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Gaia.createEmptyCollection(nftType: Type<@Gaia.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Ballerz", description: "A basketball-inspired generative NFT living on the Flow blockchain", externalURL: self.parseExternalURL(setData: setData), squareImage: self.getCollectionSquareImage(setData: setData), bannerImage: self.getCollectionBannerImage(setData: setData), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/ongaia")})
				case Type<MetadataViews.Traits>():
					var metadata = Gaia.getTemplateMetaData(templateID: self.data.templateID)
					return self.parseTraits(metadata: metadata!, setData: setData)
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					let royaltyReceiverCap = getAccount(Gaia.royaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
					if royaltyReceiverCap.check(){ 
						royalties.append(MetadataViews.Royalty(receiver: royaltyReceiverCap!, cut: 0.05, description: "Creator royalty fee."))
					}
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Serial>():
					var metadata = Gaia.getTemplateMetaData(templateID: self.data.templateID)
					let serial: UInt64? = metadata != nil && (metadata!).containsKey("id") ? UInt64.fromString((metadata!)["id"]!) : nil
					return serial != nil ? MetadataViews.Serial(serial!) : nil
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(mintNumber: UInt64, templateID: UInt64, setID: UInt64){ 
			// Increment the global Moment IDs
			Gaia.totalSupply = Gaia.totalSupply + 1 as UInt64
			self.id = Gaia.totalSupply
			
			// Set the metadata struct
			self.data = NFTData(setID: setID, templateID: templateID, mintNumber: mintNumber)
			emit Minted(assetID: self.id, templateID: templateID, setID: self.data.setID, mintNumber: self.data.mintNumber)
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important functions to modify the
	// various aspects of the Templates, Sets, and NFTs
	//
	access(all)
	resource Admin{ 
		
		// createTemplate creates a new Template struct
		// and stores it in the Templates dictionary in the TopShot smart contract
		//
		// Parameters: metadata: A dictionary mapping metadata titles to their data
		//					   example: {"Name": "John Doe", "DoB": "4/14/1990"}
		//
		// Returns: the ID of the new Template object
		//
		access(all)
		fun createTemplate(metadata:{ String: String}): UInt64{ 
			// Create the new Template
			var newTemplate = Template(metadata: metadata)
			let newID = newTemplate.templateID
			
			// Store it in the contract storage
			Gaia.templateDatas[newID] = newTemplate
			return newID
		}
		
		access(all)
		fun createTemplates(templates: [{String: String}], setID: UInt64, authorizedAccount: Address){ 
			var templateIDs: [UInt64] = []
			for metadata in templates{ 
				var ID = self.createTemplate(metadata: metadata)
				templateIDs.append(ID)
			}
			self.borrowSet(setID: setID, authorizedAccount: authorizedAccount).addTemplates(templateIDs: templateIDs)
		}
		
		// createSet creates a new Set resource and stores it
		// in the sets mapping in the contract
		//
		// Parameters: name: The name of the Set
		//
		access(all)
		fun createSet(name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64){ 
			// Create the new Set
			var newSet <- create Set(name: name, description: description, website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)
			// Store it in the sets mapping field
			Gaia.sets[newSet.setID] <-! newSet
		}
		
		// borrowSet returns a reference to a set in the contract
		// so that the admin can call methods on it
		//
		// Parameters: setID: The ID of the Set that you want to
		// get a reference to
		//
		// Returns: A reference to the Set with all of the fields
		// and methods exposed
		//
		access(all)
		fun borrowSet(setID: UInt64, authorizedAccount: Address): &Set{ 
			pre{ 
				Gaia.sets[setID] != nil:
					"Cannot borrow Set: The Set doesn't exist"
				(Gaia.setDatas[setID]!).returnAllowedAccounts().contains(authorizedAccount):
					"Account not authorized"
			}
			
			// Get a reference to the Set and return it
			// use `&` to indicate the reference to the object and type
			return (&Gaia.sets[setID] as &Set?)!
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// This is the interface that users can cast their Gaia Collection as
	// to allow others to deposit Gaia into their Collection. It also allows for reading
	// the details of Gaia in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowGaiaNFT(id: UInt64): &Gaia.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GaiaAsset reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of GaiaAsset NFTs owned by an account
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn NFTs
		//
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Gaia.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
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
		
		// borrowGaiaNFT
		// Gets a reference to an NFT in the collection as a GaiaAsset,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the GaiaAsset.
		//
		access(all)
		fun borrowGaiaNFT(id: UInt64): &Gaia.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Gaia.NFT
			} else{ 
				return nil
			}
		}
		
		// borrowViewResolver
		// Gets a reference to an NFT in the collection as a GaiaAsset,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the GaiaAsset.
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let gaiaNFT = nft as! &Gaia.NFT
			return gaiaNFT as &{ViewResolver.Resolver}
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
	
	// getAllTemplates returns all the plays in topshot
	//
	// Returns: An array of all the plays that have been created
	access(all)
	fun getAllTemplates(): [Gaia.Template]{ 
		return Gaia.templateDatas.values
	}
	
	// getTemplateMetaData returns all the metadata associated with a specific Template
	//
	// Parameters: templateID: The id of the Template that is being searched
	//
	// Returns: The metadata as a String to String mapping optional
	access(all)
	fun getTemplateMetaData(templateID: UInt64):{ String: String}?{ 
		return self.templateDatas[templateID]?.metadata
	}
	
	// getTemplateMetaDataByField returns the metadata associated with a
	//						specific field of the metadata
	//						Ex: field: "Name" will return something
	//						like "John Doe"
	//
	// Parameters: templateID: The id of the Template that is being searched
	//			 field: The field to search for
	//
	// Returns: The metadata field as a String Optional
	access(all)
	fun getTemplateMetaDataByField(templateID: UInt64, field: String): String?{ 
		// Don't force a revert if the playID or field is invalid
		if let template = Gaia.templateDatas[templateID]{ 
			return template.metadata[field]
		} else{ 
			return nil
		}
	}
	
	// getSetName returns the name that the specified Set
	//			is associated with.
	//
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: The name of the Set
	access(all)
	fun getSetName(setID: UInt64): String?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.setDatas[setID]?.name
	}
	
	access(all)
	fun getSetMarketFee(setID: UInt64): UFix64?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.setDatas[setID]?.marketFee
	}
	
	access(all)
	fun getSetImage(setID: UInt64): String?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.setDatas[setID]?.imageURI
	}
	
	access(all)
	fun getSetInfo(setID: UInt64): SetData?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.setDatas[setID]
	}
	
	// getSetIDsByName returns the IDs that the specified Set name
	//				 is associated with.
	//
	// Parameters: setName: The name of the Set that is being searched
	//
	// Returns: An array of the IDs of the Set if it exists, or nil if doesn't
	access(all)
	fun getSetIDsByName(setName: String): [UInt64]?{ 
		var setIDs: [UInt64] = []
		
		// Iterate through all the setDatas and search for the name
		for setData in Gaia.setDatas.values{ 
			if setName == setData.name{ 
				// If the name is found, return the ID
				setIDs.append(setData.setID)
			}
		}
		
		// If the name isn't found, return nil
		// Don't force a revert if the setName is invalid
		if setIDs.length == 0{ 
			return nil
		} else{ 
			return setIDs
		}
	}
	
	// getTemplatesInSet returns the list of Template IDs that are in the Set
	//
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: An array of Template IDs
	access(all)
	fun getTemplatesInSet(setID: UInt64): [UInt64]?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.sets[setID]?.templates
	}
	
	// isSetTemplateLocked returns a boolean that indicates if a Set/Template combo
	//				  is locked.
	//				  If an template is locked, it still remains in the Set,
	//				  but NFTs can no longer be minted from it.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 playID: The id of the Play that is being searched
	//
	// Returns: Boolean indicating if the template is locked or not
	access(all)
	fun isSetTemplateLocked(setID: UInt64, templateID: UInt64): Bool?{ 
		// Don't force a revert if the set or play ID is invalid
		// Remove the set from the dictionary to get its field
		if let setToRead <- Gaia.sets.remove(key: setID){ 
			
			// See if the Play is retired from this Set
			let locked = setToRead.lockedTemplates[templateID]
			
			// Put the Set back in the contract storage
			Gaia.sets[setID] <-! setToRead
			
			// Return the retired status
			return locked
		} else{ 
			
			// If the Set wasn't found, return nil
			return nil
		}
	}
	
	// isSetLocked returns a boolean that indicates if a Set
	//			 is locked. If it's locked,
	//			 new Plays can no longer be added to it,
	//			 but NFTs can still be minted from Templates the set contains.
	//
	// Parameters: setID: The id of the Set that is being searched
	//
	// Returns: Boolean indicating if the Set is locked or not
	access(all)
	fun isSetLocked(setID: UInt64): Bool?{ 
		// Don't force a revert if the setID is invalid
		return Gaia.sets[setID]?.locked
	}
	
	// getTotalMinted return the number of NFTS that have been
	//						minted from a certain set and template.
	//
	// Parameters: setID: The id of the Set that is being searched
	//			 templateID: The id of the Template that is being searched
	//
	// Returns: The total number of NFTs
	//		  that have been minted from an set and template
	access(all)
	fun getTotalMinted(setID: UInt64, templateID: UInt64): UInt64?{ 
		// Don't force a revert if the Set or play ID is invalid
		// Remove the Set from the dictionary to get its field
		if let setToRead <- Gaia.sets.remove(key: setID){ 
			
			// Read the numMintedPerPlay
			let amount = setToRead.numberMintedPerTemplate[templateID]
			
			// Put the Set back into the Sets dictionary
			Gaia.sets[setID] <-! setToRead
			return amount
		} else{ 
			// If the set wasn't found return nil
			return nil
		}
	}
	
	// fetch
	// Get a reference to a GaiaAsset from an account's Collection, if available.
	// If an account does not have a Gaia.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &Gaia.NFT?{ 
		let collection = getAccount(from).capabilities.get<&Gaia.Collection>(Gaia.CollectionPublicPath).borrow<&Gaia.Collection>() ?? panic("Couldn't get collection")
		// We trust Gaia.Collection.borowGaiaAsset to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowGaiaNFT(id: itemID)
	}
	
	// checkSetup
	// Get a reference to a GaiaAsset from an account's Collection, if available.
	// If an account does not have a Gaia.Collection, returns false.
	// If it has a collection, return true.
	//
	access(all)
	fun checkSetup(_ address: Address): Bool{ 
		return getAccount(address).capabilities.get<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath).check()
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		//FIXME: REMOVE SUFFIX BEFORE RELEASE
		self.CollectionStoragePath = /storage/GaiaCollection001
		self.CollectionPublicPath = /public/GaiaCollection001
		
		// Initialize contract fields
		self.templateDatas ={} 
		self.setDatas ={} 
		self.sets <-{} 
		self.nextTemplateID = 1
		self.nextSetID = 1
		self.totalSupply = 0
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{CollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/GaiaAdmin)
	}
}
