/* SPDX-License-Identifier: UNLICENSED */
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DimeCollectibleV3: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	// The total number of NFTs minted using this contract. Doubles as the most recent
	// id to be created.
	access(all)
	var totalSupply: UInt64
	
	access(all)
	enum NFTType: UInt8{ 
		access(all)
		case standard
		
		access(all)
		case royalty
		
		access(all)
		case release
	}
	
	access(all)
	struct Royalties{ 
		access(self)
		let allotments:{ Address: UFix64}
		
		init(allotments:{ Address: UFix64}){ 
			var total = 0.0
			for allotment in allotments.values{ 
				assert(allotment > 0.0, message: "Each recipient must receive an allotment > 0")
				total = total + allotment
			}
			assert(total <= 0.5, message: "Total royalties cannot be more than 50%")
			self.allotments = allotments
		}
		
		access(all)
		fun getShares():{ Address: UFix64}{ 
			return self.allotments
		}
	}
	
	access(all)
	struct Transaction{ 
		access(all)
		let seller: Address
		
		access(all)
		let buyer: Address
		
		access(all)
		let price: UFix64
		
		access(all)
		let time: UFix64
		
		init(seller: Address, buyer: Address, price: UFix64, time: UFix64){ 
			self.seller = seller
			self.buyer = buyer
			self.price = price
			self.time = time
		}
	}
	
	// DimeCollectible NFT, representing three distinct NFTTypes
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let type: NFTType
		
		access(self)
		let creators: [Address]
		
		access(all)
		fun getCreators(): [Address]{ 
			return self.creators
		}
		
		access(all)
		let content: String
		
		access(all)
		let hiddenContent: String?
		
		access(all)
		fun hasHiddenContent(): Bool{ 
			return self.hiddenContent != nil
		}
		
		access(all)
		let blueprintId: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(self)
		var history: [Transaction]
		
		access(all)
		fun getHistory(): [Transaction]{ 
			return self.history
		}
		
		access(self)
		let previousHistory: [Transaction]?
		
		access(all)
		fun getPreviousHistory(): [Transaction]?{ 
			return self.previousHistory
		}
		
		access(self)
		let royalties: Royalties?
		
		access(all)
		fun getRoyalties(): Royalties?{ 
			return self.royalties
		}
		
		access(all)
		let tradeable: Bool
		
		access(all)
		let creationTime: UFix64
		
		init(id: UInt64, type: NFTType, creators: [Address], content: String, hiddenContent: String?, blueprintId: UInt64, serialNumber: UInt64, tradeable: Bool, history: [Transaction], previousHistory: [Transaction]?, royalties: Royalties?){ 
			if type == NFTType.standard || type == NFTType.release{ 
				assert(royalties != nil, message: "Royalties must be provided for standard and release NFTs")
			}
			self.id = id
			self.type = type
			self.creators = creators
			self.content = content
			self.hiddenContent = hiddenContent
			self.blueprintId = blueprintId
			self.serialNumber = serialNumber
			self.history = history
			self.previousHistory = previousHistory
			self.royalties = royalties
			self.tradeable = tradeable
			self.creationTime = getCurrentBlock().timestamp
		}
		
		access(all)
		fun addSale(toUser: Address, atPrice: UFix64){ 
			self.history.append(Transaction(seller: (self.owner!).address, buyer: toUser, price: atPrice, time: getCurrentBlock().timestamp))
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Collection as
	// to allow others to deposit into it. It also allows for
	// reading the details of items in the Collection.
	access(all)
	resource interface DimeCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrowCollectible(id: UInt64): &DimeCollectibleV3.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	// Collection
	// A collection of NFTs owned by an account
	//
	access(all)
	resource Collection: DimeCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// Dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Takes a NFT and adds it to the collection dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DimeCollectibleV3.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// We don't use this function (we use our own version, borrowCollectible),
		// but it's required by the NonFungibleToken.CollcetionPublic interface
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Gets a reference to an NFT in the collection as a DimeCollectibleV3.
		access(all)
		fun borrowCollectible(id: UInt64): &DimeCollectibleV3.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			}
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &DimeCollectibleV3.NFT?
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
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		// Mint a standard DimeCollectible NFT
		access(all)
		fun mintNFTs(collection: &{NonFungibleToken.CollectionPublic}, blueprintId: UInt64, numCopies: UInt64, creators: [Address], content: String, hiddenContent: String?, tradeable: Bool, previousHistory: [Transaction]?, royalties: Royalties, initialSale: Transaction?){ 
			let history: [Transaction] = initialSale != nil ? [initialSale!] : []
			var counter = 1 as UInt64
			while counter <= numCopies{ 
				let tokenId = DimeCollectibleV3.totalSupply + counter
				collection.deposit(token: <-create DimeCollectibleV3.NFT(id: tokenId, type: NFTType.standard, creators: creators, content: content, hiddenContent: hiddenContent, blueprintId: blueprintId, serialNumber: counter, tradeable: tradeable, history: history, previousHistory: previousHistory, royalties: royalties))
				emit Minted(id: tokenId)
				counter = counter + 1
			}
			DimeCollectibleV3.totalSupply = DimeCollectibleV3.totalSupply + numCopies
		}
		
		access(all)
		fun mintRoyaltyNFTs(collection: &{NonFungibleToken.CollectionPublic}, blueprintId: UInt64, numCopies: UInt64, creators: [Address], content: String, tradeable: Bool, royalties: Royalties, initialSale: Transaction?): [UInt64]{ 
			let history: [Transaction] = initialSale != nil ? [initialSale!] : []
			var counter = 1 as UInt64
			let idsUsed: [UInt64] = []
			while counter <= numCopies{ 
				let tokenId = DimeCollectibleV3.totalSupply + counter
				collection.deposit(token: <-create DimeCollectibleV3.NFT(id: tokenId, type: NFTType.royalty, creators: creators, content: content, hiddenContent: nil, blueprintId: blueprintId, serialNumber: counter, tradeable: tradeable, history: history, previousHistory: nil, royalties: royalties))
				emit Minted(id: tokenId)
				idsUsed.append(tokenId)
				counter = counter + 1
			}
			DimeCollectibleV3.totalSupply = DimeCollectibleV3.totalSupply + numCopies
			return idsUsed
		}
		
		access(all)
		fun mintReleaseNFTs(collection: &{NonFungibleToken.CollectionPublic}, blueprintId: UInt64, numCopies: UInt64, creators: [Address], content: String, hiddenContent: String?, tradeable: Bool, previousHistory: [Transaction]?, royalties: Royalties, initialSale: Transaction?){ 
			let history: [Transaction] = initialSale != nil ? [initialSale!] : []
			var counter = 1 as UInt64
			while counter <= numCopies{ 
				let tokenId = DimeCollectibleV3.totalSupply + counter
				collection.deposit(token: <-create DimeCollectibleV3.NFT(id: tokenId, type: NFTType.release, creators: creators, content: content, hiddenContent: hiddenContent, blueprintId: blueprintId, serialNumber: counter, tradeable: tradeable, history: history, previousHistory: previousHistory, royalties: royalties))
				emit Minted(id: tokenId)
				counter = counter + 1
			}
			DimeCollectibleV3.totalSupply = DimeCollectibleV3.totalSupply + numCopies
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/DimeCollectionV3
		self.CollectionPrivatePath = /private/DimeCollectionV3
		self.CollectionPublicPath = /public/DimeCollectionV3
		self.MinterStoragePath = /storage/DimeMinterV3
		self.MinterPublicPath = /public/DimeMinterV3
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Minter resource and save it to storage.
		// Create a public link so all users can use the same global one
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
