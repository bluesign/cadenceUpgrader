import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Epix NFT Smart contract 
//
access(all)
contract Epix: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata: String, claimsSize: Int)
	
	access(all)
	event Claimed(id: UInt64)
	
	// The total number of tokens of this type in existence
	access(all)
	var totalSupply: UInt64
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// Composite data structure to represents, packs and upgrades functionality
	access(all)
	struct NFTData{ 
		access(all)
		let metadata: String
		
		access(all)
		let claims: [NFTData]
		
		init(metadata: String, claims: [NFTData]){ 
			self.metadata = metadata
			self.claims = claims
		}
	}
	
	// NFT
	// A Epix NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// NFT's ID
		access(all)
		let id: UInt64
		
		// NFT's data
		access(all)
		let data: NFTData
		
		// initializer
		//
		init(initID: UInt64, initData: NFTData){ 
			self.id = initID
			self.data = initData
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.data.metadata, description: "", thumbnail: MetadataViews.HTTPFile(url: "https://api.thisisepix.com/api/v1/nfts/thumbnail?metadata_hash=".concat(self.data.metadata)))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface EpixCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowEpixNFT(id: UInt64): &Epix.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result != nil && result?.id == id:
					"Cannot borrow EpixNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of Epix NFTs owned by an account
	//
	access(all)
	resource Collection: EpixCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
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
			let token <- token as! @Epix.NFT
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
		
		// borrowEpixNFT
		// Gets a reference to an NFT in the collection as a EpixCard,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the Epix.
		//
		access(all)
		fun borrowEpixNFT(id: UInt64): &Epix.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Epix.NFT
			} else{ 
				return nil
			}
		}
		
		// claim
		// resource owners when claiming, Mint new NFTs and burn the claimID resource.
		access(all)
		fun claim(claimID: UInt64){ 
			pre{ 
				self.ownedNFTs[claimID] != nil:
					"missing claim NFT"
			}
			let claimTokenRef = self.borrowEpixNFT(id: claimID)!
			if claimTokenRef.data.claims.length == 0{ 
				panic("Claim NFT has empty claims")
			}
			for claim in claimTokenRef.data.claims{ 
				Epix.totalSupply = Epix.totalSupply + 1 as UInt64
				emit Minted(id: Epix.totalSupply, metadata: claim.metadata, claimsSize: claim.claims.length)
				// deposit it in the recipient's account using their reference
				self.deposit(token: <-create Epix.NFT(initID: Epix.totalSupply, initData: *claim))
			}
			let claimToken <- self.ownedNFTs.remove(key: claimID) ?? panic("missing claim NFT")
			destroy claimToken
			emit Claimed(id: claimID)
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
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, data: NFTData){ 
			Epix.totalSupply = Epix.totalSupply + 1 as UInt64
			emit Minted(id: Epix.totalSupply, metadata: data.metadata, claimsSize: data.claims.length)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Epix.NFT(initID: Epix.totalSupply, initData: data))
		}
	}
	
	// initializer
	//
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/EpixCollection
		self.CollectionPublicPath = /public/EpixCollection
		self.MinterStoragePath = /storage/EpixMinter
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
