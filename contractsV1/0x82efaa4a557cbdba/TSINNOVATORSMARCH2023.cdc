import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TSINNOVATORSMARCH2023: NonFungibleToken{ 
	
	//################################### STATE ############################
	// total amount of TSINNOVATORSMARCH2023 tokens ever created
	access(all)
	var totalSupply: UInt64
	
	// Storing all the  
	access(account)
	var attendees:{ Address: SimpleTokenView}
	
	// A description of the TribalScale Event
	access(all)
	let eventDescription: String
	
	//################################### PATHS ############################
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	//################################### EVENTS ###########################
	//Standard events from NonFungibleToken standard
	access(all)
	event ContractInitialized()
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// TSINNOVATORSMARCH2023 events
	access(all)
	event POAPTokenCreated(id: UInt64, email: String, description: String, org: String, ipfsHash: String, timeCreated: UFix64)
	
	access(all)
	event POAPTokenDesposited(id: UInt64, reciever: Address?, timestamp: UFix64)
	
	//################################### LOGIC ############################
	access(all)
	fun getAttendees():{ Address: SimpleTokenView}{ 
		return self.attendees
	}
	
	// Minimal token view struct
	access(all)
	struct SimpleTokenView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let address: Address
		
		access(all)
		let name: String
		
		init(id: UInt64, address: Address, name: String){ 
			self.id = id
			self.address = address
			self.name = name
		}
	}
	
	// Full token view 
	access(all)
	struct TSTokenView{ 
		access(all)
		let ipfsHash: String
		
		access(all)
		let email: String
		
		access(all)
		let description: String
		
		access(all)
		let org: String
		
		access(all)
		let id: UInt64
		
		access(all)
		let eventName: String
		
		access(all)
		let timeCreated: UFix64
		
		init(ipfsHash: String, email: String, description: String, org: String, id: UInt64, eventName: String, timeCreated: UFix64){ 
			self.ipfsHash = ipfsHash
			self.email = email
			self.description = description
			self.org = org
			self.id = id
			self.eventName = eventName
			self.timeCreated = timeCreated
		}
	}
	
	//Function to return view 
	access(all)
	fun getTSTokenView(_ viewResolver: &{ViewResolver.Resolver}): TSTokenView?{ 
		if let view = viewResolver.resolveView(Type<TSTokenView>()){ 
			if let v = view as? TSTokenView{ 
				return v
			}
		}
		return nil
	}
	
	//#############################################################################
	//############################# NFT RESOURCE ##################################
	//#############################################################################
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The unique identifier of your token
		access(all)
		let id: UInt64
		
		// ####################### TSINNOVATORSMARCH2023 attributes ############################
		access(all)
		let email: String
		
		access(all)
		let description: String
		
		access(all)
		let ipfsHash: String
		
		access(all)
		let org: String
		
		access(all)
		let eventName: String
		
		access(all)
		let timeCreated: UFix64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		// ################### MetaData ################
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<TSTokenView>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var baseUrl = "https://d39cc1gi1l4yig.cloudfront.net/ipfs/"
			var url = baseUrl.concat(self.ipfsHash)
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.email, description: self.description, thumbnail: MetadataViews.HTTPFile(url: url))
				case Type<TSTokenView>():
					return TSTokenView(ipfsHash: self.ipfsHash, email: self.email, description: self.description, org: self.org, id: self.id, eventName: self.eventName, timeCreated: self.timeCreated)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(url)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TSINNOVATORSMARCH2023.CollectionStoragePath, publicPath: TSINNOVATORSMARCH2023.CollectionPublicPath, publicCollection: Type<&TSINNOVATORSMARCH2023.Collection>(), publicLinkedType: Type<&TSINNOVATORSMARCH2023.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TSINNOVATORSMARCH2023.createEmptyCollection(nftType: Type<@TSINNOVATORSMARCH2023.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "tribalscalelogo"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "TribalScale Web3 Innovators connect - March 22nd 2023", description: "This collection is for the Web3 Innovators connect hosted by TribalScale March 22nd 2023", externalURL: MetadataViews.ExternalURL("https://www.tribalscale.com/"), squareImage: media, bannerImage: media, socials:{ "website": MetadataViews.ExternalURL("https://www.tribalscale.com/"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/tribalscale?trk=public_post_share-update_actor-text"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/tribalscale/?hl=en"), "twitter": MetadataViews.ExternalURL("https://twitter.com/TribalScale")})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(email: String, description: String, ipfsHash: String, org: String, royalties: [MetadataViews.Royalty]){ 
			self.id = TSINNOVATORSMARCH2023.totalSupply
			self.ipfsHash = ipfsHash
			self.email = email
			self.description = description
			self.org = org
			self.royalties = royalties
			self.eventName = "TS Web3 Innovators connect 2023"
			
			// Getting timestamp
			let timestamp = getCurrentBlock().timestamp
			self.timeCreated = timestamp
			// Emit that a token has been created 
			emit POAPTokenCreated(id: self.id, email: self.email, description: self.description, org: self.org, ipfsHash: self.ipfsHash, timeCreated: timestamp)
			
			// Increment total supply
			TSINNOVATORSMARCH2023.totalSupply = TSINNOVATORSMARCH2023.totalSupply + 1
		}
	}
	
	//#############################################################################
	//############################# COLLECTION ####################################
	//#############################################################################
	access(all)
	resource interface TSINNOVATORSMARCH2023CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		// returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]
		
		// Borrow reference to NFT
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		// Check if user has a token 
		access(all)
		fun hasToken(): Bool
		
		// Force casting to a specific 
		access(all)
		fun borrowTSINNOVATORSMARCH2023NFT(id: UInt64): &TSINNOVATORSMARCH2023.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: TSINNOVATORSMARCH2023CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of all tokens in the collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// takes an NFT and adds it to the user's collection 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			pre{ 
				self.getIDs().length == 0:
					"You Already Own A Token From the TribalScale event"
			}
			let myToken <- token as! @TSINNOVATORSMARCH2023.NFT
			
			// emitting events
			let timestamp = getCurrentBlock().timestamp
			emit Deposit(id: myToken.id, to: self.owner?.address)
			emit POAPTokenDesposited(id: myToken.id, reciever: self.owner?.address, timestamp: timestamp)
			
			// Update attendees
			TSINNOVATORSMARCH2023.attendees[self.owner?.address!] = TSINNOVATORSMARCH2023.SimpleTokenView(id: myToken.id, address: self.owner?.address!, name: myToken.email)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		// returns whether there is already a token in the collection
		access(all)
		fun hasToken(): Bool{ 
			return !(self.getIDs().length == 0)
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns reference to a metadata view resolver (used to view token data)
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let TSNFT = nft as! &TSINNOVATORSMARCH2023.NFT
			return TSNFT as &{ViewResolver.Resolver}
		}
		
		// Returns reference to a token of type NonFungibleToken.NFT
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Returns a reference to a token downcasted to TSINNOVATORSMARCH2023.NFT type
		access(all)
		fun borrowTSINNOVATORSMARCH2023NFT(id: UInt64): &TSINNOVATORSMARCH2023.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TSINNOVATORSMARCH2023.NFT
			}
			return nil
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("You do not own a token with that ID")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createToken(email: String, description: String, ipfsHash: String, org: String, royalties: [MetadataViews.Royalty]): @TSINNOVATORSMARCH2023.NFT{ 
		return <-create NFT(email: email, description: description, ipfsHash: ipfsHash, org: org, royalties: royalties)
	}
	
	//################# Contract init #######################
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/TSINNOVATORSMARCH2023Collection
		self.CollectionPublicPath = /public/TSINNOVATORSMARCH2023Collection
		
		// Set event description
		self.eventDescription = "Innovators connect hosted by TribalScale on March 22nd 2023"
		
		// Set attendees
		self.attendees ={} 
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&TSINNOVATORSMARCH2023.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
