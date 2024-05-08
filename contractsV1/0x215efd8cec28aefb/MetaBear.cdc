// SPDX-License-Identifier: MIT
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

// MetaBear
//
// This contract is a boilerplate we will be using
// to generate collections on the MetaGood (Metagood) platform.
access(all)
contract MetaBear: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, recipientAddress: Address?, metadata:{ String: String})
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	let CollectionDataPath: StoragePath
	
	access(all)
	let CollectionDataPublicPath: PublicPath
	
	// totalSupply
	// The total number of MetaBear that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// NFT
	// A MetaBear Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// Metadata
		access(contract)
		let metadata:{ String: AnyStruct}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		// initializer
		//
		init(initID: UInt64, metadata:{ String: AnyStruct}){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	// This is the interface that users can cast their MetaBear Collection as
	// to allow others to deposit MetaBear into their Collection. It also allows for reading
	// the details of MetaBear in the Collection.
	access(all)
	resource interface MetaBearCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMetaBear(id: UInt64): &MetaBear.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MetaBear reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of MetaBear NFTs owned by an account
	//
	access(all)
	resource Collection: MetaBearCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MetaBear.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowMetaBear
		// Gets a reference to an NFT in the collection as a MetaBear,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the MetaBear.
		//
		access(all)
		fun borrowMetaBear(id: UInt64): &MetaBear.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &MetaBear.NFT
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
		access(all)
		let mintPrice: UFix64 // Cost of minting
		
		
		access(all)
		let maxSupply: UInt64 // Maximum supply
		
		
		access(all)
		let collectionDataCap: Capability<&{MetaBear.CollectionDataPublic}>
		
		access(all)
		let collectionAddress: Address
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, communityFeeVault: @{FungibleToken.Vault}, creatorFeeVault: @{FungibleToken.Vault}, platformFeeVault: @{FungibleToken.Vault}){ 
			pre{ 
				MetaBear.totalSupply < self.maxSupply:
					"Max supply reached"
			}
			let collectionData = self.collectionDataCap.borrow()!
			let imageUrl: String = collectionData.getCollectionImageURL(id: MetaBear.totalSupply)
			let community = collectionData.getCollectionSetting("community") as! Address
			let communityFee2ndPercentage = collectionData.getCollectionSetting("communityFee2ndPercentage") as! UFix64
			let creator = collectionData.getCollectionSetting("creator") as! Address
			let creatorFeeMintPercentage = collectionData.getCollectionSetting("creatorFeeMintPercentage") as! UFix64
			let creatorFee2ndPercentage = collectionData.getCollectionSetting("creatorFee2ndPercentage") as! UFix64
			let platform = collectionData.getCollectionSetting("platform") as! Address
			let platformFeeMintPercentage = collectionData.getCollectionSetting("platformFeeMintPercentage") as! UFix64
			let platformFee2ndPercentage = collectionData.getCollectionSetting("platformFee2ndPercentage") as! UFix64
			let price = self.mintPrice
			let creatorFee = price * creatorFeeMintPercentage as! UFix64
			let platformFee = price * platformFeeMintPercentage as! UFix64
			if communityFeeVault.balance != price - creatorFee - platformFee{ 
				panic("Incorrect community fee.")
			}
			if creatorFeeVault.balance != creatorFee{ 
				panic("Incorrect creator fee.")
			}
			if platformFeeVault.balance != platformFee{ 
				panic("Incorrect platform fee.")
			}
			let metadataString:{ String: String} ={ "collection": self.collectionAddress.toString(), "imageUrl": imageUrl}
			let metadata:{ String: AnyStruct} ={ "collection": self.collectionAddress.toString(), "imageUrl": imageUrl, "community": community, "communityFee2ndPercentage": communityFee2ndPercentage, "creator": creator, "creatorFeeMintPercentage": creatorFeeMintPercentage, "creatorFee2ndPercentage": creatorFee2ndPercentage, "platform": platform, "platformFeeMintPercentage": platformFeeMintPercentage, "platformFee2ndPercentage": platformFee2ndPercentage}
			
			// Deposit Mint Price
			// Get a reference to the owner's Receiver
			let ownerRef = getAccount(community).capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow<&FUSD.Vault>() ?? panic("Could not borrow receiver reference to the owner's Vault")
			let creatorRef = getAccount(creator).capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow<&FUSD.Vault>() ?? panic("Could not borrow receiver reference to the creator's Vault")
			let platformRef = getAccount(platform).capabilities.get<&FUSD.Vault>(/public/fusdReceiver).borrow<&FUSD.Vault>() ?? panic("Could not borrow receiver reference to the platform's Vault")
			emit Minted(id: MetaBear.totalSupply, recipientAddress: (recipient.owner!).address, metadata: metadataString)
			
			// Deposit the withdrawn tokens in the recipient's receiver
			ownerRef.deposit(from: <-communityFeeVault)
			creatorRef.deposit(from: <-creatorFeeVault)
			platformRef.deposit(from: <-platformFeeVault)
			
			// Deposit MetaBear to Recipient
			recipient.deposit(token: <-create MetaBear.NFT(initID: MetaBear.totalSupply, metadata: metadata))
			MetaBear.totalSupply = MetaBear.totalSupply + 1 as UInt64
		}
		
		init(collectionAddress: Address, maxSupply: UInt64, mintPrice: UFix64, collectionDataCap: Capability<&{MetaBear.CollectionDataPublic}>){ 
			self.mintPrice = mintPrice
			self.collectionAddress = collectionAddress
			self.collectionDataCap = collectionDataCap
			self.maxSupply = maxSupply
		}
	}
	
	// fetch
	// Get a reference to a MetaBear from an account's Collection, if available.
	// If an account does not have a MetaBear.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &MetaBear.NFT?{ 
		let collection = getAccount(from).capabilities.get<&MetaBear.Collection>(MetaBear.CollectionPublicPath).borrow<&MetaBear.Collection>() ?? panic("Couldn't get collection")
		// We trust MetaBear.Collection.borrowMetaBear to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowMetaBear(id: itemID)
	}
	
	access(all)
	resource interface CollectionDataPublic{ 
		access(all)
		fun getCollectionImageURL(id: UInt64): String
		
		access(all)
		fun getCollectionSetting(_ setting: String): AnyStruct
	}
	
	access(all)
	resource CollectionData: CollectionDataPublic{ 
		// Collection Data
		// The image URLs that each NFT should hold
		
		// The dictionary of all minting platform fees. The default value is 5%
		access(self)
		var metadata: [{String: String}]
		
		access(self)
		var settings:{ String: AnyStruct}
		
		access(all)
		fun getCollectionImageURL(id: UInt64): String{ 
			let data = self.metadata[id]
			return data["imageUrl"] != nil ? data["imageUrl"]! : ""
		}
		
		access(all)
		fun getCollectionSetting(_ setting: String): AnyStruct{ 
			let attribute = self.settings[setting]!
			return attribute
		}
		
		access(all)
		fun setCollectionMetadata(metadata: [{String: String}]){ 
			self.metadata = metadata
		}
		
		access(all)
		fun setCollectionSettings(settings:{ String: AnyStruct}){ 
			self.settings = settings
		}
		
		// constructor
		//
		init(){ 
			self.metadata = []
			self.settings ={ "community": 0x2f5e4d202bf9e66d as Address, "communityFee2ndPercentage": 0.03, "creator": 0x2f5e4d202bf9e66d as Address, "creatorFeeMintPercentage": 0.08, "creatorFee2ndPercentage": 0.02, "platform": 0xd3069a346a93affc as Address, "platformFeeMintPercentage": 0.05, "platformFee2ndPercentage": 0.025}
		}
	}
	
	// initializer
	//
	init(){ 
		let mintPrice = 1.0
		let maxSupply: UInt64 = 10000
		
		// Set our named paths
		self.CollectionStoragePath = /storage/MetaBearCollection004
		self.CollectionPublicPath = /public/MetaBearCollection004
		self.MinterStoragePath = /storage/MetaBearMinter004
		self.MinterPublicPath = /public/MetaBearMinter004
		// Stores the image urls
		self.CollectionDataPath = /storage/MetaBearCollectionData004
		self.CollectionDataPublicPath = /public/MetaBearCollectionData004
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Collection Data
		let oldCollectionData <- self.account.storage.load<@CollectionData>(from: self.CollectionDataPath)
		destroy oldCollectionData
		let collectionData <- create CollectionData()
		var capability_1 = self.account.capabilities.storage.issue<&{MetaBear.CollectionDataPublic}>(self.CollectionDataPath)
		self.account.capabilities.publish(capability_1, at: self.CollectionDataPublicPath)
		self.account.storage.save(<-collectionData, to: self.CollectionDataPath)
		let collectionDataCap = self.account.capabilities.get<&{MetaBear.CollectionDataPublic}>(self.CollectionDataPublicPath) as Capability<&{MetaBear.CollectionDataPublic}>
		
		// Minter
		let oldMinter <- self.account.storage.load<@NFTMinter>(from: self.MinterStoragePath)
		destroy oldMinter
		let minter <- create NFTMinter(collectionAddress: self.account.address, maxSupply: maxSupply, mintPrice: mintPrice, collectionDataCap: collectionDataCap)
		var capability_2 = self.account.capabilities.storage.issue<&MetaBear.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
