//-------------- Mainnet -----------------------------
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import RedevNFT from "./RedevNFT.cdc"

// -------------------------------------------------
// LithokenNFT token contract
access(all)
contract LithokenNFT: NonFungibleToken, RedevNFT{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionPublicPath: PublicPath
	
	access(all)
	var collectionStoragePath: StoragePath
	
	access(all)
	var minterPublicPath: PublicPath
	
	access(all)
	var minterStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata: Metadata, royalties: [{RedevNFT.Royalty}])
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	struct Royalty{ 
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
		
		init(address: Address, fee: UFix64){ 
			self.address = address
			self.fee = fee
		}
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let artist: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let description: String
		
		access(all)
		let dedicace: String
		
		access(all)
		let type: String
		
		access(all)
		let ipfs: String
		
		access(all)
		let collection: String
		
		access(all)
		let nomSerie: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let nbrEdition: UInt64
		
		init(name: String, artist: String, creatorAddress: Address, description: String, dedicace: String, type: String, ipfs: String, collection: String, nomSerie: String, edition: UInt64, nbrEdition: UInt64){ 
			self.name = name
			self.artist = artist
			self.creatorAddress = creatorAddress
			self.description = description
			self.dedicace = dedicace
			self.type = type
			self.ipfs = ipfs
			self.collection = collection
			self.nomSerie = nomSerie
			self.edition = edition
			self.nbrEdition = nbrEdition
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata: Metadata
		
		access(self)
		let royalties: [{RedevNFT.Royalty}]
		
		init(id: UInt64, creator: Address, metadata: Metadata, royalties: [{RedevNFT.Royalty}]){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
			self.royalties = royalties
		}
		
		access(all)
		fun getMetadata(): Metadata{ 
			return self.metadata
		}
		
		access(all)
		fun getRoyalties(): [{RedevNFT.Royalty}]{ 
			return self.royalties
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface LithokenNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun getMetadata(id: UInt64): Metadata
		
		access(all)
		fun borrowLithokenItem(id: UInt64): &LithokenNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LithokenItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LithokenNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, RedevNFT.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @LithokenNFT.NFT
			let id: UInt64 = token.id
			let dummy <- self.ownedNFTs[id] <- token
			destroy dummy
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowLithokenItem(id: UInt64): &LithokenNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &LithokenNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun getMetadata(id: UInt64): Metadata{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &LithokenNFT.NFT).getMetadata()
		}
		
		access(all)
		fun getRoyalties(id: UInt64): [{RedevNFT.Royalty}]{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &{RedevNFT.NFT}).getRoyalties()
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mintTo(creator: Capability<&{NonFungibleToken.Receiver}>, name: String, artist: String, description: String, dedicace: String, type: String, ipfs: String, collection: String, nomSerie: String, edition: UInt64, nbrEdition: UInt64, royalties: [{RedevNFT.Royalty}]): &{NonFungibleToken.NFT}{ 
			let metadata = Metadata(name: name, artist: artist, creatorAddress: creator.address, description: description, dedicace: dedicace, type: type, ipfs: ipfs, collection: collection, nomSerie: nomSerie, edition: edition, nbrEdition: nbrEdition)
			let token <- create NFT(id: LithokenNFT.totalSupply, creator: creator.address, metadata: metadata, royalties: royalties)
			LithokenNFT.totalSupply = LithokenNFT.totalSupply + 1
			let tokenRef = &token as &{NonFungibleToken.NFT}
			emit Mint(id: token.id, creator: creator.address, metadata: metadata, royalties: royalties)
			(creator.borrow()!).deposit(token: <-token)
			return tokenRef
		}
	}
	
	access(all)
	fun minter(): Capability<&Minter>{ 
		return self.account.capabilities.get<&Minter>(self.minterPublicPath)!
	}
	
	init(){ 
		self.totalSupply = 0
		self.collectionPublicPath = /public/LithokenNFTCollection
		self.collectionStoragePath = /storage/LithokenNFTCollection
		self.minterPublicPath = /public/LithokenNFTMinter
		self.minterStoragePath = /storage/LithokenNFTMinter
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.minterStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Minter>(self.minterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.minterPublicPath)
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.collectionStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}>(self.collectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.collectionPublicPath)
		emit ContractInitialized()
	}
}
