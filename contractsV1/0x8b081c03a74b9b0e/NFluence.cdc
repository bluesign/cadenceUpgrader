/*
This is the main contract that manages data and behavior for minted NFTs on
the NFluence platform
 */

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFluence: NonFungibleToken{ 
	
	// Path variables
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// This variable controls the max number of editions of a single NFT you're allowed to mint
	// It's possible for this to change as scaling and transaction fees become less of an issue
	access(account)
	var maxEditionSize: UInt16
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, user: Address)
	
	access(all)
	event Destroyed(id: UInt64)
	
	// A data structure that contains matadata fields for a single NFT
	access(all)
	struct NFluenceNFTData{ 
		access(all)
		let nftId: UInt64
		
		// The IPFS cid for the file that will be minted into an NFT
		access(all)
		let cid: String
		
		// Currently either 0 (image) or 1 (video) or 2 (audio)
		access(all)
		let fileType: UInt8
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		var serial: UInt16
		
		// Number of NFTs in the edition
		access(all)
		let editionSize: UInt16
		
		init(nftId: UInt64, cid: String, fileType: UInt8, title: String, description: String, creatorAddress: Address, serial: UInt16, editionSize: UInt16){ 
			self.nftId = nftId
			assert(cid.length > 0, message: "NFT must contain an IPFS hash string")
			self.cid = cid
			assert(fileType == 0 || fileType == 1, message: "fileType must have an integer value of zero or one")
			self.fileType = fileType
			self.title = title
			self.description = description
			self.creatorAddress = creatorAddress
			self.serial = serial
			self.editionSize = editionSize
		}
	}
	
	// Publically available data and functions for the NFT
	access(all)
	resource interface NFluencePublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun getData(): NFluenceNFTData
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, NFluencePublic{ 
		access(self)
		let metadata: NFluenceNFTData
		
		access(all)
		let id: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(cid: String, fileType: UInt8, title: String, description: String, creatorAddress: Address, serial: UInt16, editionSize: UInt16){ 
			pre{ 
				editionSize <= NFluence.maxEditionSize:
					"You're trying to mint too many NFTs at once"
			}
			self.id = NFluence.totalSupply
			NFluence.totalSupply = NFluence.totalSupply + 1
			self.metadata = NFluenceNFTData(nftId: self.id, cid: cid, fileType: fileType, title: title, description: description, creatorAddress: creatorAddress, serial: serial, editionSize: editionSize)
			emit Created(id: self.id, user: creatorAddress)
		}
		
		// Getter function for the NFT metadata
		access(all)
		fun getData(): NFluenceNFTData{ 
			return self.metadata
		}
	}
	
	// Publically available data and functions for the NFT Collection
	access(all)
	resource interface NFluenceCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		// Get list of ids for all NFTs in the collection
		access(all)
		fun getIDs(): [UInt64]
		
		// Get metadata for a specific NFT
		access(all)
		fun getTokenData(id: UInt64): NFluenceNFTData{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result.nftId == id:
					"Cannot get token data: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getAllTokenData(): [NFluenceNFTData]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// Function that returns reference to the whole public facing NFluence Resource
		access(all)
		fun borrowNFluenceNFT(id: UInt64): &NFluence.NFT{ 
			post{ 
				result == nil || result.id == id:
					"Cannot borrow Moment reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NFluenceCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			pre{ 
				self.ownedNFTs[withdrawID] != nil:
					"NFT does not exist in the collection"
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			let item <- token as! @NFluence.NFT
			return <-item
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
		
		// deposit takes an NFT and adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFluence.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
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
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun getTokenData(id: UInt64): NFluenceNFTData{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection"
			}
			let token = self.borrowNFluenceNFT(id: id)
			return token.getData()
		}
		
		access(all)
		fun getAllTokenData(): [NFluenceNFTData]{ 
			var tokens: [NFluenceNFTData] = []
			for key in self.ownedNFTs.keys{ 
				tokens.append(self.getTokenData(id: key))
			}
			return tokens
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection"
			}
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowNFluenceNFT(id: UInt64): &NFluence.NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection"
			}
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &NFluence.NFT
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
	
	// Function creates a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create self.Collection()
	}
	
	// This function takes metadata arguments as well as an editionSize parameter
	// which will mint multiple NFTs with the same metadata and increasing serial numbers
	access(all)
	fun mintNFT(recipient: &NFluence.Collection, cid: String, fileType: UInt8, title: String, description: String, editionSize: UInt16){ 
		pre{ 
			editionSize <= NFluence.maxEditionSize:
				"You're trying to mint too many NFTs at once"
			recipient != nil:
				"Must have a valid NFluence Collection available in order to mint"
		}
		var a = editionSize
		let creatorAddress = (recipient.owner!).address
		while a > 0{ 
			var newNFT <- create NFT(cid: cid, fileType: fileType, title: title, description: description, creatorAddress: creatorAddress, serial: a, editionSize: editionSize)
			recipient.deposit(token: <-newNFT)
			a = a - 1
		}
	}
	
	// An admin resource that contains administrative functions for this contract
	access(all)
	resource NFluenceAdmin{ 
		// Allows the contract owner to update the maximum number of NFTs allowed to be minted at once
		access(all)
		fun updateMaxEditionSize(newSize: UInt16){ 
			pre{ 
				newSize > 0:
					"Must be a positive non zero integer"
			}
			NFluence.maxEditionSize = newSize
		}
	}
	
	init(){ 
		// Initialize the total supply and max edition size variables
		self.totalSupply = 0
		self.maxEditionSize = 1000
		// Initialize Collection paths
		self.CollectionPublicPath = /public/NFluenceCollectionPublic
		self.CollectionStoragePath = /storage/NFluenceCollectionStorage
		self.AdminStoragePath = /storage/NFluenceAdminStorage
		// Create the admin resource and store it in the account that deployed this contract
		let admin <- create NFluenceAdmin()
		self.account.storage.save(<-admin, to: NFluence.AdminStoragePath)
		// Create a Collection resource and save it to storage
		self.account.storage.save<@Collection>(<-create Collection(), to: NFluence.CollectionStoragePath)
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{NFluence.NFluenceCollectionPublic}>(NFluence.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: NFluence.CollectionPublicPath)
		emit ContractInitialized()
	}
}
