import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MemeToken from "./MemeToken.cdc"

/// Meme 
/// Defines a non fungible token. 
///
access(all)
contract Meme: NonFungibleToken{ 
	
	/// defines the total supply and also
	/// used to identify nft tokens 
	access(all)
	var totalSupply: UInt64
	
	/// event emitted when this contract is initialized
	access(all)
	event ContractInitialized()
	
	/// event is emitted when nft is created
	access(all)
	event NFTCreated(id: UInt64, title: String, description: String, hash: String, owner: Address, tags: String)
	
	/// event is emitted when a nft is moved away from collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// event is emitted when a nft is moved to a collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// paths used to store collection, nfts and assign capabilities
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionAdminStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// the actual nft resource 
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		/// nft identifier - in that case total supply is used 
		access(all)
		let id: UInt64
		
		/// name oft the nft 
		access(all)
		let title: String
		
		/// descript of the nft 
		access(all)
		let description: String
		
		/// hash idfentifier 
		access(all)
		let hash: String
		
		/// struct of royalties
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		/// addional expendable metadata to store addional information
		access(all)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, title: String, description: String, hash: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.title = title
			self.description = description
			self.hash = hash
			self.royalties = royalties
			self.metadata = metadata
			emit NFTCreated(id: id, title: title, description: description, hash: hash, owner: self.metadata["minter"]! as! Address, tags: self.metadata["tags"]! as! String)
		}
		
		/// returns all possible view for nft type
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		/// resolves for a specific view type a struct of data
		/// e.g. if you want to display royalties - please use 
		/// resolve(Type<MetadataViews.Royalties>()) to display royalties
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.title, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.hash))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Meme NFT Edition", number: self.id, max: Meme.totalSupply)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Meme.CollectionStoragePath, publicPath: Meme.CollectionPublicPath, publicCollection: Type<&Meme.Collection>(), publicLinkedType: Type<&Meme.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Meme.createEmptyCollection(nftType: Type<@Meme.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The Example Collection", description: "This collection is used as an example to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")})
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: nil)
			}
			return nil
		}
		
		/// Update metadata
		/// Updates the metadata key by key and reassign the original one
		access(all)
		fun update(metadata:{ String: AnyStruct}){ 
			for key in metadata.keys{ 
				self.metadata[key] = metadata[key]
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface NFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMemeNFT(id: UInt64): &Meme.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Meme NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource interface NFTTemplate{ 
		access(all)
		fun template(id: UInt64, title: String, hash: String)
	}
	
	access(all)
	resource Collection: NFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Meme.NFT
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
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, title: String, description: String, hash: String, tags: String, payment: @{FungibleToken.Vault}?){ 
			// destroy payment for now
			destroy payment
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["block"] = currentBlock.height
			metadata["timestamp"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			metadata["tags"] = tags
			
			// get recipient address by force 
			let address = (recipient.owner!).address
			
			// construct royalties
			var royalties: [MetadataViews.Royalty] = []
			let creatorCapability = getAccount((recipient.owner!).address).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
			
			// Make sure the royalty capability is valid before minting the NFT
			if !creatorCapability.check(){ 
				panic("Beneficiary capability is not valid!")
			}
			
			// create a new NFT
			var nft <- create NFT(id: Meme.totalSupply, title: title, description: description, hash: hash, royalties: royalties, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-nft)
			Meme.totalSupply = Meme.totalSupply + UInt64(1)
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowMemeNFT(id: UInt64): &Meme.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Meme.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let meme = nft as! &Meme.NFT
			return meme as &{ViewResolver.Resolver}
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
	
	/// The function to create a new empty collection.
	/// Please be aware that only the contract admin can create a new collection.
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		panic("Please use the admin resource to create a new collection")
	}
	
	/// The administrator resource that can create new collection.
	access(all)
	resource Administrator{ 
		
		/// Create a new empty collection.
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MemeCollection
		self.CollectionPublicPath = /public/MemeCollection
		self.CollectionAdminStoragePath = /storage/MemeCollectionAdmin
		
		// Create a administrator resource and save it to the admin account storage
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.CollectionAdminStoragePath)
		emit ContractInitialized()
	}
}
