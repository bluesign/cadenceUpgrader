// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MusicBlock: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let name: String
	
	access(all)
	let symbol: String
	
	access(all)
	let baseMetadataUri: String
	
	access(all)
	struct MusicBlockData{ 
		access(all)
		let creator: Address //creator 
		
		
		access(all)
		let cpower: UInt64 //computing power
		
		
		access(all)
		let cid: String //content id refers to ipfs's hash or general URI
		
		
		access(self)
		let precedences: [UInt64] // cocreated based on which tokens 
		
		
		access(all)
		let generation: UInt64 //generation, defered for the cocreated tokens
		
		
		access(all)
		let allowCocreate: Bool //false
		
		
		init(creator: Address, cid: String, cp: UInt64, precedences: [UInt64], allowCocreate: Bool){ 
			self.creator = creator
			self.cpower = cp
			self.cid = cid
			self.precedences = precedences
			self.allowCocreate = allowCocreate
			self.generation = 1 // TOOD: update according to the level of the token
		
		}
		
		access(all)
		fun getPrecedences(): [UInt64]{ 
			return self.precedences
		}
	}
	
	/**
		* We split metadata into two categories: those that are essential and immutable through life time and those that can be 
		* stored on an external storage. Metadata like desc., image, etc. will be stored off chain and publicly accessible via metadata uri.
		* For the first category, we explicitly define them as NFT fields and get accessed via public getters.
		*/
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(self)
		let data: MusicBlockData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// priv let supply: UInt64 // cap removed. make a single NFT unique by the standard interface.
		init(initID: UInt64, initCreator: Address, initCpower: UInt64, initCid: String, initPrecedences: [UInt64], initAllowCocreate: Bool){ 
			self.id = initID
			self.data = MusicBlockData(creator: initCreator, cid: initCid, cp: initCpower, precedences: initPrecedences, allowCocreate: initAllowCocreate)
		// self.supply = initSupply			
		}
		
		access(all)
		fun getMusicBlockData(): MusicBlockData{ 
			return self.data
		}
	}
	
	access(all)
	resource interface MusicBlockCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getMusicBlockData(id: UInt64): MusicBlockData
		
		access(all)
		fun getUri(id: UInt64): String
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: MusicBlockCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// pub var metadata: {UInt64: { String : String }}
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// self.metadata = {}
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
			let token <- token as! @MusicBlock.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			// let oldToken <- self.ownedNFTs[token.id] <-! token
			self.ownedNFTs[id] <-! token
			// self.metadata[id] = metadata
			emit Deposit(id: id, to: self.owner?.address)
		
		// destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(all)
		fun getMusicBlockData(id: UInt64): MusicBlockData{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let mref = ref as? &MusicBlock.NFT ?? panic("nonexist id")
			return mref.getMusicBlockData()
		}
		
		access(all)
		fun getUri(id: UInt64): String{ 
			return MusicBlock.baseMetadataUri.concat("/").concat(id.toString())
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, id: UInt64, creator: Address, cpower: UInt64, cid: String, precedences: [UInt64], allowCocreate: Bool){ 
			emit Minted(id: MusicBlock.totalSupply)
			// create a new NFT
			var newNFT <- create MusicBlock.NFT(initID: id, initCreator: creator, initCpower: cpower, initCid: cid, initPrecedences: precedences, initAllowCocreate: allowCocreate)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MusicBlock.totalSupply = MusicBlock.totalSupply + 1
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.name = "MELOS Music Token"
		self.symbol = "MELOSNFT"
		self.baseMetadataUri = "https://app.melos.studio/melosnft"
		self.CollectionStoragePath = /storage/MusicBlockCollection
		self.CollectionPublicPath = /public/MusicBlockCollection
		self.MinterStoragePath = /storage/MusicBlockMinter
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
