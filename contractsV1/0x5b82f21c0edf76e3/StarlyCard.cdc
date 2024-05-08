import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyMetadata from "./StarlyMetadata.cdc"

import StarlyMetadataViews from "./StarlyMetadataViews.cdc"

access(all)
contract StarlyCard: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, starlyID: String)
	
	access(all)
	event Burned(id: UInt64, starlyID: String)
	
	access(all)
	event MinterCreated()
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterProxyStoragePath: StoragePath
	
	access(all)
	let MinterProxyPublicPath: PublicPath
	
	// totalSupply
	// The total number of StarlyCard that have been minted
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let starlyID: String
		
		init(initID: UInt64, initStarlyID: String){ 
			self.id = initID
			self.starlyID = initStarlyID
		}
		
		access(all)
		fun getMetadata(): StarlyMetadataViews.CardEdition?{ 
			return StarlyMetadata.getCardEdition(starlyID: self.starlyID)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return StarlyMetadata.getViews()
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: StarlyCard.CollectionStoragePath, publicPath: StarlyCard.CollectionPublicPath, publicCollection: Type<&StarlyCard.Collection>(), publicLinkedType: Type<&StarlyCard.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-StarlyCard.createEmptyCollection(nftType: Type<@StarlyCard.Collection>())
						})
				default:
					return StarlyMetadata.resolveView(starlyID: self.starlyID, view: view)
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their StarlyCard Collection as
	// to allow others to deposit StarlyCard into their Collection. It also allows for reading
	// the details of StarlyCard in the Collection.
	access(all)
	resource interface StarlyCardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? // from MetadataViews
		
		
		access(all)
		fun borrowStarlyCard(id: UInt64): &StarlyCard.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow StarlyCard reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, StarlyCardCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @StarlyCard.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let card = nft as! &StarlyCard.NFT
			return card as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowStarlyCard(id: UInt64): &StarlyCard.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &StarlyCard.NFT
			} else{ 
				return nil
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
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// fetch
	// Get a reference to a StarlyCard from an account's Collection, if available.
	// If an account does not have a StarlyCard.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &StarlyCard.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&StarlyCard.Collection>(StarlyCard.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		// We trust StarlyCard.Collection.borowStarlyCard to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowStarlyCard(id: itemID)
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, starlyID: String){ 
			emit Minted(id: StarlyCard.totalSupply, starlyID: starlyID)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create StarlyCard.NFT(initID: StarlyCard.totalSupply, initStarlyID: starlyID))
			StarlyCard.totalSupply = StarlyCard.totalSupply + 1 as UInt64
		}
	}
	
	access(all)
	resource interface MinterProxyPublic{ 
		access(all)
		fun setMinterCapability(capability: Capability<&NFTMinter>)
	}
	
	// MinterProxy
	//
	// Resource object holding a capability that can be used to mint new NFTs.
	// The resource that this capability represents can be deleted by the admin
	// in order to unilaterally revoke minting capability if needed.
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		access(self)
		var minterCapability: Capability<&NFTMinter>?
		
		access(all)
		fun setMinterCapability(capability: Capability<&NFTMinter>){ 
			self.minterCapability = capability
		}
		
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, starlyID: String){ 
			((self.minterCapability!).borrow()!).mintNFT(recipient: recipient, starlyID: starlyID)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	// createMinterProxy
	//
	// Function that creates a MinterProxy.
	// Anyone can call this, but the MinterProxy cannot mint without a NFTMinter capability,
	// and only the admin can provide that.
	//
	access(all)
	fun createMinterProxy(): @MinterProxy{ 
		return <-create MinterProxy()
	}
	
	// Administrator
	//
	// A resource that allows new minters to be created
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(): @NFTMinter{ 
			emit MinterCreated()
			return <-create NFTMinter()
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/starlyCardCollection
		self.CollectionPublicPath = /public/starlyCardCollection
		self.AdminStoragePath = /storage/starlyCardAdmin
		self.MinterStoragePath = /storage/starlyCardMinter
		self.MinterProxyPublicPath = /public/starlyCardMinterProxy
		self.MinterProxyStoragePath = /storage/starlyCardMinterProxy
		// Initialize the total supply
		self.totalSupply = 0
		let admin <- create Administrator()
		let minter <- admin.createNewMinter()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
