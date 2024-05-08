import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

//BlockAnime
// NFT items for Anime!
//
access(all)
contract Blockanime: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, charName: String, animeName: String, thumbnail: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of Anime Characters that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Card as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let charName: String
		
		access(all)
		let animeName: String
		
		access(all)
		let thumbnail: String
		
		// initializer
		//
		init(initID: UInt64, initCharName: String, initAnimeName: String, initThumbnail: String){ 
			self.id = initID
			self.charName = initCharName
			self.animeName = initAnimeName
			self.thumbnail = initThumbnail
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.charName, description: self.animeName, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Anime Collection as
	// to allow others to deposit Anime into their Collection. It also allows for reading
	// the details of Anime in the Collection.
	access(all)
	resource interface BlockanimeCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBlockanime(id: UInt64): &Blockanime.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BlockAnime reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Anime NFTs owned by an account
	//
	access(all)
	resource Collection: BlockanimeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Blockanime.NFT
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
		
		// borrowSportsCard
		// Gets a reference to an NFT in the collection as a BlockAnime,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the BlockAnime.
		//
		access(all)
		fun borrowBlockanime(id: UInt64): &Blockanime.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Blockanime.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let blockanimeNFT = nft as! &Blockanime.NFT
			return blockanimeNFT as &{ViewResolver.Resolver}
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
	
	// NFTMinter aka Admin
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
		fun mintNFT(charName: String, animeName: String, thumbnail: String): @NFT{ 
			emit Minted(id: Blockanime.totalSupply, charName: charName, animeName: animeName, thumbnail: thumbnail)
			let newNFT: @NFT <- create Blockanime.NFT(initID: Blockanime.totalSupply, initCharName: charName, initAnimeName: animeName, initThumbnail: thumbnail)
			Blockanime.totalSupply = Blockanime.totalSupply + 1
			return <-newNFT
		}
		
		access(all)
		fun batchMint(charName: String, animeName: String, thumbnail: String, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(charName: charName, animeName: animeName, thumbnail: thumbnail))
				i = i + 1
			}
			return <-newCollection
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/BlockanimeCollection
		self.CollectionPublicPath = /public/BlockanimeCollection
		self.MinterStoragePath = /storage/BlockanimeMinter
		// Initialize the total supply
		self.totalSupply = 0
		// save it to the account
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Blockanime.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		// Put the Minter in storage
		self.account.storage.save<@NFTMinter>(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
