/*
	Description: The official Schmoes NFT Contract
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import SchmoesPreLaunchToken from "./SchmoesPreLaunchToken.cdc"

access(all)
contract SchmoesNFT: NonFungibleToken{ 
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
	// SchmoesNFT Events
	// -----------------------------------------------------------------------
	access(all)
	event Mint(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var maxSupply: UInt64
	
	// -----------------------------------------------------------------------
	// SchmoesNFT Fields
	// -----------------------------------------------------------------------
	access(all)
	var name: String
	
	access(all)
	var isSaleActive: Bool
	
	access(all)
	var price: UFix64
	
	access(all)
	var maxMintAmount: UInt64
	
	access(all)
	var provenance: String
	
	// launch parameters
	access(all)
	var earlyLaunchTime: UFix64
	
	access(all)
	var launchTime: UFix64
	
	access(all)
	var idsPerIncrement: UInt64
	
	access(all)
	var timePerIncrement: UInt64
	
	access(self)
	let editionToSchmoeData:{ UInt64: SchmoeData}
	
	access(self)
	let editionToProvenance:{ UInt64: String}
	
	access(self)
	let editionToNftId:{ UInt64: UInt64}
	
	access(self)
	let nftIdToEdition:{ UInt64: UInt64}
	
	// maps assetType to a dict of assetNames to base64 encoded images of assets
	access(self)
	let schmoeAssets:{ SchmoeTrait:{ String: String}}
	
	// CID for the IPFS folder
	access(all)
	var ipfsBaseCID: String
	
	access(all)
	enum SchmoeTrait: UInt8{ 
		access(all)
		case hair
		
		access(all)
		case background
		
		access(all)
		case face
		
		access(all)
		case eyes
		
		access(all)
		case mouth
		
		access(all)
		case clothes
		
		access(all)
		case props
		
		access(all)
		case ears
	}
	
	access(all)
	struct SchmoeData{ 
		access(all)
		let traits:{ SchmoeTrait: String}
		
		init(traits:{ SchmoeTrait: String}){ 
			self.traits = traits
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(edition: UInt64){ 
			self.id = self.uuid
			self.edition = edition
			SchmoesNFT.editionToNftId[self.edition] = self.id
			SchmoesNFT.nftIdToEdition[self.id] = self.edition
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface SchmoesNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun getEditionsInCollection(): [UInt64]
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, SchmoesNFTCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SchmoesNFT.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun getEditionsInCollection(): [UInt64]{ 
			let editions: [UInt64] = []
			let ids: [UInt64] = self.ownedNFTs.keys
			var i = 0
			while i < ids.length{ 
				editions.append(SchmoesNFT.nftIdToEdition[ids[i]]!)
				i = i + 1
			}
			return editions
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
	// Admin Functions
	// -----------------------------------------------------------------------
	access(account)
	fun setIsSaleActive(_ newIsSaleActive: Bool){ 
		self.isSaleActive = newIsSaleActive
	}
	
	access(account)
	fun setPrice(_ newPrice: UFix64){ 
		self.price = newPrice
	}
	
	access(account)
	fun setMaxMintAmount(_ newMaxMintAmount: UInt64){ 
		self.maxMintAmount = newMaxMintAmount
	}
	
	access(account)
	fun setIpfsBaseCID(_ ipfsBaseCID: String){ 
		self.ipfsBaseCID = ipfsBaseCID
	}
	
	access(account)
	fun setProvenance(_ provenance: String){ 
		self.provenance = provenance
	}
	
	access(account)
	fun setProvenanceForEdition(_ edition: UInt64, _ provenance: String){ 
		self.editionToProvenance[edition] = provenance
	}
	
	access(account)
	fun setSchmoeAsset(_ assetType: SchmoeTrait, _ assetName: String, _ content: String){ 
		if self.schmoeAssets[assetType] == nil{ 
			let assetNameToContent:{ String: String} ={ assetName: content}
			self.schmoeAssets[assetType] = assetNameToContent
		} else{ 
			let ref = self.schmoeAssets[assetType]!
			ref[assetName] = content
			self.schmoeAssets[assetType] = ref
		}
	}
	
	access(account)
	fun batchUpdateSchmoeData(_ schmoeDataMap:{ UInt64: SchmoeData}){ 
		for edition in schmoeDataMap.keys{ 
			self.editionToSchmoeData[edition] = schmoeDataMap[edition]
		}
	}
	
	access(account)
	fun setEarlyLaunchTime(_ earlyLaunchTime: UFix64){ 
		self.earlyLaunchTime = earlyLaunchTime
	}
	
	access(account)
	fun setLaunchTime(_ launchTime: UFix64){ 
		self.launchTime = launchTime
	}
	
	access(account)
	fun setIdsPerIncrement(_ idsPerIncrement: UInt64){ 
		self.idsPerIncrement = idsPerIncrement
	}
	
	access(account)
	fun setTimePerIncrement(_ timePerIncrement: UInt64){ 
		self.timePerIncrement = timePerIncrement
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	fun getSchmoeDataForEdition(_ edition: UInt64): SchmoeData{ 
		return self.editionToSchmoeData[edition]!
	}
	
	access(all)
	fun getAllSchmoeData():{ UInt64: SchmoeData}{ 
		return self.editionToSchmoeData
	}
	
	access(all)
	fun getProvenanceForEdition(_ edition: UInt64): String{ 
		return self.editionToProvenance[edition]!
	}
	
	access(all)
	fun getAllProvenances():{ UInt64: String}{ 
		return self.editionToProvenance
	}
	
	access(all)
	fun getNftIdForEdition(_ edition: UInt64): UInt64{ 
		return self.editionToNftId[edition]!
	}
	
	access(all)
	fun getEditionToNftIdMap():{ UInt64: UInt64}{ 
		return self.editionToNftId
	}
	
	access(all)
	fun getEditionForNftId(_ nftId: UInt64): UInt64{ 
		return self.nftIdToEdition[nftId]!
	}
	
	access(all)
	fun getNftIdToEditionMap():{ UInt64: UInt64}{ 
		return self.nftIdToEdition
	}
	
	access(all)
	fun getSchmoeAsset(_ assetType: SchmoeTrait, _ assetName: String): String{ 
		return (self.schmoeAssets[assetType]!)[assetName]!
	}
	
	access(all)
	fun mintWithPreLaunchToken(buyVault: @{FungibleToken.Vault}, mintAmount: UInt64, preLaunchToken: @SchmoesPreLaunchToken.NFT): @{NonFungibleToken.Collection}{ 
		let schmoes: @{NonFungibleToken.Collection} <- self.maybeMint(<-buyVault, mintAmount, preLaunchToken.id)
		destroy preLaunchToken
		return <-schmoes
	}
	
	access(all)
	fun mint(buyVault: @{FungibleToken.Vault}, mintAmount: UInt64): @{NonFungibleToken.Collection}{ 
		return <-self.maybeMint(<-buyVault, mintAmount, nil)
	}
	
	access(all)
	fun getAvailableMintTime(_ preLaunchTokenId: UInt64?): UFix64{ 
		if preLaunchTokenId == nil{ 
			return self.launchTime
		} else{ 
			let increments = preLaunchTokenId! / self.idsPerIncrement
			let timeAfterLaunch = increments * self.timePerIncrement
			return UFix64(timeAfterLaunch) + self.earlyLaunchTime
		}
	}
	
	// -----------------------------------------------------------------------
	// Helper Functions
	// -----------------------------------------------------------------------
	access(contract)
	fun maybeMint(_ buyVault: @{FungibleToken.Vault}, _ mintAmount: UInt64, _ preLaunchTokenId: UInt64?): @{NonFungibleToken.Collection}{ 
		pre{ 
			self.isSaleActive:
				"Sale is not active"
			mintAmount <= self.maxMintAmount:
				"Attempting to mint too many Schmoes"
			self.totalSupply + mintAmount <= self.maxSupply:
				"Not enough supply to mint that many Schmoes"
			buyVault.balance >= self.price * UFix64(mintAmount):
				"Insufficient funds"
		}
		
		// epoch time in seconds
		let currTime = getCurrentBlock().timestamp
		if currTime > self.launchTime{ 
			return <-self.batchMint(<-buyVault, mintAmount)
		}
		if currTime > self.earlyLaunchTime{ 
			let id = preLaunchTokenId ?? panic("A Pre-Launch Token is required to mint")
			let availableMintTime = self.getAvailableMintTime(id)
			if currTime >= availableMintTime{ 
				return <-self.batchMint(<-buyVault, mintAmount)
			} else{ 
				panic("This Pre-Launch Token is not eligble to mint yet.")
			}
		}
		panic("Minting has not started yet.")
	}
	
	access(contract)
	fun batchMint(_ buyVault: @{FungibleToken.Vault}, _ mintAmount: UInt64): @{NonFungibleToken.Collection}{ 
		pre{ 
			buyVault.isInstance((self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!).getType()):
				"Minting requires a FlowToken.Vault"
		}
		let adminVaultRef = self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
		adminVaultRef.deposit(from: <-buyVault)
		var schmoesCollection <- self.createEmptyCollection(nftType: Type<@Collection>())
		var i: UInt64 = 0
		while i < mintAmount{ 
			let edition = SchmoesNFT.totalSupply + 1 as UInt64
			let schmoe: @SchmoesNFT.NFT <- create SchmoesNFT.NFT(edition: edition)
			SchmoesNFT.totalSupply = edition
			schmoesCollection.deposit(token: <-schmoe)
			i = i + 1
		}
		return <-schmoesCollection
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.name = "SchmoesNFT"
		self.isSaleActive = false
		self.totalSupply = 0
		self.maxSupply = 10000
		self.price = 1.0
		self.maxMintAmount = 1
		self.provenance = ""
		self.editionToSchmoeData ={} 
		self.editionToProvenance ={} 
		self.editionToNftId ={} 
		self.nftIdToEdition ={} 
		self.schmoeAssets ={} 
		self.ipfsBaseCID = ""
		self.CollectionStoragePath = /storage/SchmoesNFTCollection
		self.CollectionPublicPath = /public/SchmoesNFTCollection
		self.earlyLaunchTime = 4791048813.0
		self.launchTime = 4791048813.0
		self.idsPerIncrement = 0
		self.timePerIncrement = 0
		emit ContractInitialized()
	}
}
