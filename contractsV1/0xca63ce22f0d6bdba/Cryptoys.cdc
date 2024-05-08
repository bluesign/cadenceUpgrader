import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import CryptoysMetadataView from "./CryptoysMetadataView.cdc"

import ICryptoys from "./ICryptoys.cdc"

// Cryptoys
// The jam.
//
access(all)
contract Cryptoys: NonFungibleToken, ICryptoys{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event AddedToBucket(owner: Address, key: String, id: UInt64, uuid: UInt64)
	
	access(all)
	event WithdrawnFromBucket(owner: Address, key: String, id: UInt64, uuid: UInt64)
	
	access(all)
	event Minted(id: UInt64, uuid: UInt64, metadata:{ String: String}, royalties: [Royalty])
	
	access(all)
	event RoyaltyUpserted(name: String, royalty: Royalty)
	
	access(all)
	event DisplayUpdated(id: UInt64, image: String, video: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of Cryptoys that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A Cryptoy as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, ICryptoys.INFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(account)
		let metadata:{ String: String}
		
		access(account)
		let royalties: [String]
		
		access(account)
		let bucket: @{String:{ UInt64:{ ICryptoys.INFT}}}
		
		init(id: UInt64, metadata:{ String: String}, royalties: [String]?){ 
			pre{ 
				metadata.length != 0:
					"Cryptoy failed to initialize: metadata cannot be empty"
			}
			self.id = id
			self.metadata = metadata
			self.royalties = royalties ?? []
			self.bucket <-{} 
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getDisplay(): Display{ 
			var image = ""
			var video = ""
			if Cryptoys.display[self.id] != nil{ 
				image = (Cryptoys.display[self.id]!).image
				video = (Cryptoys.display[self.id]!).video
			}
			if image == ""{ 
				image = self.metadata["image"] ?? ""
			}
			if video == ""{ 
				video = self.metadata["video"] ?? ""
			}
			return Cryptoys.Display(image: image, video: video)
		}
		
		access(all)
		fun getRoyalties(): [Royalty]{ 
			var nftRoyalties: [Royalty] = []
			for royalty in self.royalties{ 
				var nftRoyalty: Royalty? = Cryptoys.royalties[royalty]
				if nftRoyalty != nil{ 
					nftRoyalties.append(nftRoyalty!)
				}
			}
			return nftRoyalties
		}
		
		access(account)
		fun withdrawBucketItem(_ key: String, _ itemUuid: UInt64): @{ICryptoys.INFT}{ 
			let resources = self.borrowBucketResourcesByKey(key) ?? panic("withdrawBucketItem() failed to find resources by key: ".concat(key))
			let nft <- resources.remove(key: itemUuid) ?? panic("withdrawBucketItem() failed to find NFT in bucket with id: ".concat(itemUuid.toString()))
			emit WithdrawnFromBucket(owner: (self.owner!).address, key: key, id: self.id, uuid: itemUuid)
			return <-nft
		}
		
		access(all)
		fun addToBucket(_ key: String, _ nft: @{ICryptoys.INFT}){ 
			let nftUuid: UInt64 = nft.uuid
			let resources = self.borrowBucketResourcesByKey(key)
			if resources == nil{ 
				let bucket = self.borrowBucket()
				bucket[key] <-!{ nftUuid: <-nft}
			} else{ 
				let exitingBucket = resources!
				exitingBucket[nftUuid] <-! nft
			}
			emit AddedToBucket(owner: (self.owner!).address, key: key, id: self.id, uuid: nftUuid)
		}
		
		access(all)
		fun borrowBucketResourcesByKey(_ key: String): &{UInt64:{ ICryptoys.INFT}}?{ 
			return &self.bucket[key] as &{UInt64:{ ICryptoys.INFT}}?
		}
		
		access(all)
		fun borrowBucket(): &{String:{ UInt64:{ ICryptoys.INFT}}}{ 
			return &self.bucket as &{String:{ UInt64:{ ICryptoys.INFT}}}
		}
		
		access(all)
		fun getBucketKeys(): [String]{ 
			return *self.borrowBucket().keys
		}
		
		access(all)
		fun getBucketResourceIdsByKey(_ key: String): [UInt64]{ 
			let resources = self.borrowBucketResourcesByKey(key) ?? panic("getBucketResourceIdsByKey() failed to find resources by key: ".concat(key))
			return *resources.keys
		}
		
		access(all)
		fun borrowBucketItem(_ key: String, _ itemUuid: UInt64): &{ICryptoys.INFT}{ 
			let resources = self.borrowBucketResourcesByKey(key) ?? panic("borrowBucketItem() failed to find resources by key: ".concat(key))
			let bucketItem = resources[itemUuid] as &{ICryptoys.INFT}? ?? panic("borrowBucketItem() failed to borrow resource with id: ".concat(itemUuid.toString()))
			return bucketItem as! &Cryptoys.NFT
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<CryptoysMetadataView.Cryptoy>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var display = self.getDisplay()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["type"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: display.image))
				case Type<CryptoysMetadataView.Cryptoy>():
					return CryptoysMetadataView.Cryptoy(name: self.metadata["type"], description: self.metadata["description"], image: display.image, coreImage: self.metadata["coreImage"], video: display.video, platformId: self.metadata["platformId"], category: self.metadata["category"], type: self.metadata["type"], skin: self.metadata["skin"], tier: self.metadata["tier"], rarity: self.metadata["rarity"], edition: self.metadata["edition"], series: self.metadata["series"], legionId: self.metadata["legionId"], creator: self.metadata["creator"], packaging: self.metadata["packaging"], termsUrl: self.metadata["termsUrl"])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Collection
	// A collection of Cryptoy NFTs owned by an account
	//
	access(all)
	resource Collection: ICryptoys.CryptoysCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("withdraw() failed: missing NFT with id: ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Cryptoys.NFT
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
		
		access(all)
		fun borrowCryptoy(id: UInt64): &{ICryptoys.INFT}{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Cryptoys.NFT
			} else{ 
				return panic("borrowCryptoy() failed: cryptoy not found with id: ".concat(id.toString()))
			}
		}
		
		access(all)
		fun borrowBucketItem(_ id: UInt64, _ key: String, _ itemUuid: UInt64): &{ICryptoys.INFT}{ 
			if self.ownedNFTs[id] == nil{ 
				return panic("borrowBucketItem() failed: parent cryptoy not found with id: ".concat(id.toString()))
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let cryptoyRef = ref as! &Cryptoys.NFT
			return cryptoyRef.borrowBucketItem(key, itemUuid)
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let cryptoyNFT = nft as! &Cryptoys.NFT
			return cryptoyNFT
		}
		
		access(all)
		fun getRoyalties(id: UInt64): [Royalty]{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return (ref as! &NFT).getRoyalties()
		}
		
		access(all)
		fun withdrawBucketItem(parentId: UInt64, key: String, itemUuid: UInt64): @{ICryptoys.INFT}{ 
			if self.ownedNFTs[parentId] == nil{ 
				panic("withdrawBucketItem() failed: parent cryptoy not found with id: ".concat(parentId.toString()))
			}
			let nftRef = (&self.ownedNFTs[parentId] as &{NonFungibleToken.NFT}?)!
			let cryptoyRef = nftRef as! &Cryptoys.NFT
			return <-cryptoyRef.withdrawBucketItem(key, itemUuid)
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
	
	access(all)
	struct Royalty{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
		
		init(name: String, address: Address, fee: UFix64){ 
			self.name = name
			self.address = address
			self.fee = fee
		}
	}
	
	access(all)
	struct Display{ 
		access(all)
		let image: String
		
		access(all)
		let video: String
		
		init(image: String, video: String){ 
			self.image = image
			self.video = video
		}
	}
	
	// royalties
	// royalties for each INFT
	//
	access(account)
	let royalties:{ String: Royalty}
	
	// display for each composed NFTs
	//
	access(account)
	let display:{ UInt64: Display}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Admin
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs and update royalties
	//
	access(all)
	resource Admin{ 
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: Capability<&{NonFungibleToken.CollectionPublic}>, metadata:{ String: String}, royaltyNames: [String]?): UInt64{ 
			var nftRoyalties: [Royalty] = []
			if royaltyNames != nil{ 
				for royalty in royaltyNames!{ 
					var nftRoyalty = Cryptoys.royalties[royalty]
					if nftRoyalty == nil{ 
						panic("mintNFT() failed: royalty not found: ".concat(royalty))
					}
					nftRoyalties.append(nftRoyalty!)
				}
			}
			let nftId = Cryptoys.totalSupply
			
			// deposit it in the recipient's account using their reference
			var nft <- create Cryptoys.NFT(id: nftId, metadata: metadata, royalties: royaltyNames)
			emit Minted(id: nft.id, uuid: nft.uuid, metadata: nft.getMetadata(), royalties: nftRoyalties)
			Cryptoys.totalSupply = Cryptoys.totalSupply + 1
			(recipient.borrow()!).deposit(token: <-nft)
			return nftId
		}
		
		access(all)
		fun upsertRoyalty(royalty: Royalty){ 
			Cryptoys.royalties[royalty.name] = royalty
			emit RoyaltyUpserted(name: royalty.name, royalty: royalty)
		}
		
		access(all)
		fun updateDisplay(cryptoy: &{ICryptoys.INFT}, display: Display?){ 
			if display != nil{ 
				Cryptoys.display.insert(key: cryptoy.id, display!)
			} else{ 
				Cryptoys.display.remove(key: cryptoy.id)
			}
			var display = cryptoy.getDisplay()
			emit DisplayUpdated(id: cryptoy.id, image: display.image, video: display.video)
		}
		
		access(all)
		fun getRoyalties():{ String: Royalty}{ 
			return Cryptoys.royalties
		}
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.AdminStoragePath = /storage/cryptoysAdmin
		self.CollectionStoragePath = /storage/cryptoysCollection
		self.CollectionPublicPath = /public/cryptoysCollection
		
		// Initialize the total supply
		self.totalSupply = 0
		self.royalties ={} 
		self.display ={} 
		
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ICryptoys.CryptoysCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
