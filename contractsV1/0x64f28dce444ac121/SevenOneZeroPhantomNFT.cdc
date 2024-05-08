/*
	Description: Central Smart Contract for 710 Phantom

	author: Bilal Shahid bilal@zay.codes
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract SevenOneZeroPhantomNFT: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// 710 Phantom Events
	// -----------------------------------------------------------------------
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event PhantomDataUpdated(nftID: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// SevenOneZeroPhantomNFT Fields
	// -----------------------------------------------------------------------
	// NFT level metadata
	access(self)
	var name: String
	
	access(self)
	var externalURL: String
	
	access(self)
	var maxAmount: UInt64
	
	// Variable size dictonary of PhantomData structs
	access(self)
	var phantomData:{ UInt64: PhantomData}
	
	access(all)
	enum PhantomTrait: UInt8{ 
		access(all)
		case cloak
		
		access(all)
		case background
		
		access(all)
		case faceCovering
		
		access(all)
		case eyeCovering
		
		access(all)
		case necklace
		
		access(all)
		case headCovering
		
		access(all)
		case mouthPiece
		
		access(all)
		case earring
		
		access(all)
		case poster
	}
	
	// -----------------------------------------------------------------------
	// SevenOneZeroPhantomNFT Struct Fields
	// -----------------------------------------------------------------------
	access(all)
	struct PhantomData{ 
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let ipfsMetadataHash: String
		
		access(self)
		let traits:{ PhantomTrait: String}
		
		init(metadata:{ String: String}, ipfsMetadataHash: String, traits:{ PhantomTrait: String}){ 
			self.metadata = metadata
			self.ipfsMetadataHash = ipfsMetadataHash
			self.traits = traits
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getIpfsMetadataHash(): String{ 
			return self.ipfsMetadataHash
		}
		
		access(all)
		fun getTraits():{ PhantomTrait: String}{ 
			return self.traits
		}
	}
	
	// -----------------------------------------------------------------------
	// SevenOneZeroPhantomNFT Resource Interfaces
	// -----------------------------------------------------------------------
	access(all)
	resource interface SevenOneZeroPhantomNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSevenOneZeroPhantomNFT(id: UInt64): &SevenOneZeroPhantomNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SevenOneZeroPhantomNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Resources
	// -----------------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64){ 
			self.id = id
			emit Minted(id: self.id)
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, SevenOneZeroPhantomNFTCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Currently entire doesn't fail if one fails
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SevenOneZeroPhantomNFT.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Currently entire doesn't fail if one fails
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowSevenOneZeroPhantomNFT(id: UInt64): &SevenOneZeroPhantomNFT.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SevenOneZeroPhantomNFT.NFT
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
	
	// -----------------------------------------------------------------------
	// SevenOneZeroPhantomNFT Resources
	// -----------------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun mint(recipient: &{SevenOneZeroPhantomNFT.SevenOneZeroPhantomNFTCollectionPublic}): UInt64{ 
			pre{ 
				SevenOneZeroPhantomNFT.totalSupply <= SevenOneZeroPhantomNFT.maxAmount:
					"NFT max amount reached"
			}
			let id = SevenOneZeroPhantomNFT.totalSupply + 1 as UInt64
			let newNFT: @SevenOneZeroPhantomNFT.NFT <- create SevenOneZeroPhantomNFT.NFT(id: id)
			recipient.deposit(token: <-newNFT)
			SevenOneZeroPhantomNFT.totalSupply = id
			return id
		}
		
		access(all)
		fun batchMint(recipient: &{SevenOneZeroPhantomNFT.SevenOneZeroPhantomNFTCollectionPublic}, amount: UInt64): [UInt64]{ 
			pre{ 
				amount > 0:
					"Dataset cannot be empty"
				SevenOneZeroPhantomNFT.totalSupply + amount <= SevenOneZeroPhantomNFT.maxAmount:
					"Input data has too many values"
			}
			var nftIDs: [UInt64] = []
			var i: UInt64 = 0
			while i < amount{ 
				nftIDs.append(self.mint(recipient: recipient))
				i = i + 1
			}
			return nftIDs
		}
		
		access(self)
		fun updatePhantomData(nftID: UInt64, ipfsMetadataHash: String, metadata:{ String: String}, traits:{ SevenOneZeroPhantomNFT.PhantomTrait: String}){ 
			let newPhantomData = PhantomData(metadata: metadata, ipfsMetadataHash: ipfsMetadataHash, traits: traits)
			SevenOneZeroPhantomNFT.phantomData[nftID] = newPhantomData
			emit PhantomDataUpdated(nftID: nftID)
		}
		
		access(all)
		fun batchUpdatePhantomData(nftIDs: [UInt64], ipfsMetadataHashes: [String], metadata: [{String: String}], traits: [{SevenOneZeroPhantomNFT.PhantomTrait: String}]){ 
			var i = 0
			while i < nftIDs.length{ 
				self.updatePhantomData(nftID: nftIDs[i], ipfsMetadataHash: ipfsMetadataHashes[i], metadata: metadata[i], traits: traits[i])
				i = i + 1
			}
		}
	}
	
	// -----------------------------------------------------------------------
	// SevenOneZeroPhantomNFT Functions
	// -----------------------------------------------------------------------
	access(all)
	fun getName(): String{ 
		return self.name
	}
	
	access(all)
	fun getExternalURL(): String{ 
		return self.externalURL
	}
	
	access(all)
	fun getMaxAmount(): UInt64{ 
		return self.maxAmount
	}
	
	access(all)
	fun getAllPhantomData():{ UInt64: PhantomData}{ 
		return self.phantomData
	}
	
	access(all)
	fun getPhantomData(id: UInt64): PhantomData{ 
		return SevenOneZeroPhantomNFT.phantomData[id]!
	}
	
	access(all)
	fun getPhantomMetadata(id: UInt64):{ String: String}{ 
		return (SevenOneZeroPhantomNFT.phantomData[id]!).getMetadata()
	}
	
	access(all)
	fun getPhantomIpfsHash(id: UInt64): String{ 
		return (SevenOneZeroPhantomNFT.phantomData[id]!).getIpfsMetadataHash()
	}
	
	access(all)
	fun getPhantomTraits(id: UInt64):{ PhantomTrait: String}{ 
		return (SevenOneZeroPhantomNFT.phantomData[id]!).getTraits()
	}
	
	access(all)
	fun getPhantomHasTrait(id: UInt64, lookupTrait: PhantomTrait, lookupValue: String): Bool{ 
		let nftTrait = (SevenOneZeroPhantomNFT.phantomData[id]!).getTraits()[lookupTrait]
		if nftTrait != nil && nftTrait == lookupValue{ 
			return true
		}
		return false
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/sevenOneZeroPhantomCollection
		self.CollectionPublicPath = /public/sevenOneZeroPhantomCollection
		self.AdminStoragePath = /storage/sevenOneZeroAdmin
		self.totalSupply = 0
		self.name = "710 Phantom"
		self.externalURL = "https://710phantom.com/" // TODO: Change to point to NFT Site URL
		
		self.maxAmount = 7100
		self.phantomData ={} 
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
