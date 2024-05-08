import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Veolet: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// Token ID
		access(all)
		let id: UInt64
		
		// URL to the media file represented by the NFT 
		access(all)
		let originalMediaURL: String
		
		// Flow address of the NFT creator
		access(all)
		let creatorAddress: Address
		
		// Name of the NFT creator
		access(all)
		let creatorName: String
		
		// Date of creation
		access(all)
		let createdDate: UInt64
		
		// Short description of the NFT
		access(all)
		let caption: String
		
		// SHA256 hash of the media file for verification
		access(all)
		let hash: String
		
		// How many NFTs with this hash (e.g. same media file) are minted
		access(all)
		let edition: UInt16
		
		// A mutable version of the media URL. The holder can change the URL in case the original URL is not available anymore. Through the hash variable it can be
		// verified whether the file is actually the correct one. 
		access(all)
		var currentMediaURL: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer of the token
		init(initID: UInt64, initMediaURL: String, initCreatorName: String, initCreatorAddress: Address, initCreatedDate: UInt64, initCaption: String, initHash: String, initEdition: UInt16){ 
			self.id = initID
			self.originalMediaURL = initMediaURL
			self.creatorAddress = initCreatorAddress
			self.creatorName = initCreatorName
			self.createdDate = initCreatedDate
			self.caption = initCaption
			self.hash = initHash
			self.edition = initEdition
			
			// the mutable URL variable is also set to the originalMediaURL value initially
			self.currentMediaURL = initMediaURL
		}
	}
	
	// Interface to receive NFT references and deposit NFT (implemented by collection)
	access(all)
	resource interface VeoletGetter{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowVeoletRef(id: UInt64): &Veolet.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: VeoletGetter, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initializer
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun setNFTMediaURL(id: UInt64, newMediaURL: String){ 
			// change the currentMediaURL field of token. This can only be done by the holder
			// Please note that the originalMediaURL will still be the same (it is immutable)
			let changetoken <- self.ownedNFTs.remove(key: id)! as! @Veolet.NFT
			changetoken.currentMediaURL = newMediaURL
			self.deposit(token: <-changetoken)
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
			let token <- token as! @Veolet.NFT
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
		
		// Takes a NFT id as input and returns a reference to the token. Used to obtain token fields
		access(all)
		fun borrowVeoletRef(id: UInt64): &Veolet.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Veolet.NFT
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
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, initMediaURL: String, initCreatorName: String, initCreatorAddress: Address, initCreatedDate: UInt64, initCaption: String, initHash: String, initEdition: UInt16){ 
			
			// create a new NFT
			var newNFT <- create NFT(initID: Veolet.totalSupply, initMediaURL: initMediaURL, initCreatorName: initCreatorName, initCreatorAddress: initCreatorAddress, initCreatedDate: initCreatedDate, initCaption: initCaption, initHash: initHash, initEdition: initEdition)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Veolet.totalSupply = Veolet.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: /storage/VeoletCollection)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Veolet.Collection>(/storage/VeoletCollection)
		self.account.capabilities.publish(capability_1, at: /public/VeoletCollection)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: /storage/NFTMinter)
		emit ContractInitialized()
	}
}
