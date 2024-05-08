import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract FanfareNFTContract: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, mediaURI: String)
	
	// Event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated()
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// The storage Path for minters' MinterProxy
	access(all)
	let MinterProxyStoragePath: StoragePath
	
	// The public path for minters' MinterProxy capability
	access(all)
	let MinterProxyPublicPath: PublicPath
	
	// The storage path for the admin resource
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		var mediaURI: String
		
		access(all)
		var creatorAddress: Address
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, mediaURI: String, creatorAddress: Address){ 
			self.id = initID
			self.mediaURI = mediaURI
			self.creatorAddress = creatorAddress
		}
	}
	
	access(all)
	resource interface FanfareNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTMetadata(id: UInt64): &FanfareNFTContract.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Card reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, FanfareNFTCollectionPublic{ 
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
			let token <- token as! @FanfareNFTContract.NFT
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
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowNFTMetadata gets a reference to an NFT in the collection
		// so that the caller can read its id and metadata
		access(all)
		fun borrowNFTMetadata(id: UInt64): &FanfareNFTContract.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &FanfareNFTContract.NFT
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
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(creator: Capability<&{NonFungibleToken.Receiver}>, mediaURI: String, creatorAddress: Address): &{NonFungibleToken.NFT}{ 
			let token <- create NFT(initID: FanfareNFTContract.totalSupply, mediaURI: mediaURI, creatorAddress: creatorAddress)
			FanfareNFTContract.totalSupply = FanfareNFTContract.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Minted(id: token.id, mediaURI: mediaURI)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	resource interface MinterProxyPublic{ 
		access(all)
		fun setMinterCapability(cap: Capability<&NFTMinter>)
	}
	
	// MinterProxy
	//
	// Resource object holding a capability that can be used to mint new tokens.
	// The resource that this capability represents can be deleted by the admin
	// in order to unilaterally revoke minting capability if needed.
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		access(self)
		var minterCapability: Capability<&NFTMinter>?
		
		access(all)
		fun setMinterCapability(cap: Capability<&NFTMinter>){ 
			self.minterCapability = cap
		}
		
		access(all)
		fun mintNFT(creator: Capability<&{NonFungibleToken.Receiver}>, mediaURI: String, creatorAddress: Address): &{NonFungibleToken.NFT}{ 
			return ((self.minterCapability!).borrow()!).mintNFT(creator: creator, mediaURI: mediaURI, creatorAddress: creatorAddress)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	access(all)
	fun createMinterProxy(): @MinterProxy{ 
		return <-create MinterProxy()
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun createNewMinter(): @NFTMinter{ 
			emit MinterCreated()
			return <-create NFTMinter()
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/FanfareNFTCollection
		self.CollectionPublicPath = /public/FanfareNFTCollection
		self.AdminStoragePath = /storage/FanfareAdmin
		self.MinterProxyPublicPath = /public/FanfareNFTMinterProxy
		self.MinterProxyStoragePath = /storage/FanfareNFTMinterProxy
		
		// Initialize the total supply
		self.totalSupply = 0
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(/storage/FanfareNFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/FanfareNFTReceiver)
		emit ContractInitialized()
	}
}
