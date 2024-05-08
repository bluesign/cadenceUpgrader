import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

// Mainnet: aaaaaaaaaaaaaaaa
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ChainIDEShieldNFT: NonFungibleToken{ 
	
	/// Total supply of ChainIDEShieldNFT in existence
	access(all)
	var totalSupply: UInt64
	
	/// Max supply of ChainIDEShieldNFT in existence
	access(all)
	var maxSupply: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an NFT is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Collection name
	access(all)
	let CollectionName: String
	
	// Collection description
	access(all)
	let CollectionDesc: String
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// The core resource that represents a Non Fungible Token.
	/// New instances will be created using the NFTMinter resource
	/// and stored in the Collection resource
	///
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		access(all)
		let type: String
		
		/// Metadata fields
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, type: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.type = type
			self.metadata = metadata
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		/// Function that resolves a metadata view for this token.
		///
		/// @param view: The Type of the desired view.
		/// @return A structure representing the requested view.
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "ChainIDE shield NFT #".concat(self.id.toString()), description: "ChainIDE is a cloud-based IDE for creating decentralized applications.", thumbnail: MetadataViews.IPFSFile(cid: "bafybeify7ul3fvtewfk6rkxqje4ofwm7enekgiy7hc5qpjcrqcj653tg54", path: self.type.concat(".jpg")))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "ChainIDE Shield NFT Edition", number: self.id, max: ChainIDEShieldNFT.maxSupply)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://chainide.com/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ChainIDEShieldNFT.CollectionStoragePath, publicPath: ChainIDEShieldNFT.CollectionPublicPath, publicCollection: Type<&ChainIDEShieldNFT.Collection>(), publicLinkedType: Type<&ChainIDEShieldNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ChainIDEShieldNFT.createEmptyCollection(nftType: Type<@ChainIDEShieldNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.io/ipfs/bafkreietoyammygl7liiqboujde5fle4tz4ts6fhwljdnwnaj36bv4kly4"), mediaType: "image/jpg")
					return MetadataViews.NFTCollectionDisplay(name: ChainIDEShieldNFT.CollectionName, description: ChainIDEShieldNFT.CollectionDesc, externalURL: MetadataViews.ExternalURL("https://chainide.com"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/ChainIDE")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and type to show other uses of Traits
					let excludedTraits = ["mintedTime"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface ChainIDEShieldNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowChainIDEShieldNFT(id: UInt64): &ChainIDEShieldNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ChainIDEShieldNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: ChainIDEShieldNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Removes an NFT from the collection and moves it to the caller
		///
		/// @param withdrawID: The ID of the NFT that wants to be withdrawn
		/// @return The NFT resource that has been taken out of the collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Adds an NFT to the collections dictionary and adds the ID to the id array
		///
		/// @param token: The NFT resource to be included in the collection
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ChainIDEShieldNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Helper method for getting the collection IDs
		///
		/// @return An array containing the IDs of the NFTs in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		fun borrowChainIDEShieldNFT(id: UInt64): &ChainIDEShieldNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ChainIDEShieldNFT.NFT
			}
			return nil
		}
		
		/// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
		/// interface so that the caller can retrieve the views that the NFT
		/// is implementing and resolve them
		///
		/// @param id: The ID of the wanted NFT
		/// @return The resource reference conforming to the Resolver interface
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ChainIDEShieldNFT = nft as! &ChainIDEShieldNFT.NFT
			return ChainIDEShieldNFT as &{ViewResolver.Resolver}
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
	
	/// Allows anyone to create a new empty collection
	///
	/// @return The new Collection resource
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Resource that an admin or something similar would own to be
	/// able to mint new NFTs
	///
	access(all)
	resource NFTMinter{ 
		
		/// Mints a new NFT with a new ID and deposit it in the
		/// recipients collection using their collection reference
		///
		/// @param recipient: A capability to the collection where the new NFT will be deposited
		/// @param type: The type for the NFT metadata
		/// @param royalties: An array of Royalty structs, see MetadataViews docs
		///
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, type: String){ 
			pre{ 
				ChainIDEShieldNFT.totalSupply < ChainIDEShieldNFT.maxSupply:
					"ChainIDEShieldNFT: soldout."
			}
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			metadata["type"] = type
			
			// create a new NFT
			var newNFT <- create NFT(id: ChainIDEShieldNFT.totalSupply, type: type, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			ChainIDEShieldNFT.totalSupply = ChainIDEShieldNFT.totalSupply + UInt64(1)
		}
	}
	
	init(_maxSupply: UInt64){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.maxSupply = _maxSupply
		
		// Set collection name and description
		self.CollectionName = "ChainIDE Shield NFT"
		self.CollectionDesc = "ChainIDE is a cloud-based IDE for creating decentralized applications to deploy on blockchains."
		
		// Set the named paths
		self.CollectionStoragePath = /storage/ChainIDEShieldNFTCollection
		self.CollectionPublicPath = /public/ChainIDEShieldNFTCollection
		self.MinterStoragePath = /storage/ChainIDEShieldNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&ChainIDEShieldNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
