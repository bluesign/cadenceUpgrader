import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Mynft: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, artist: String, description: String, arLink: String, ipfsLink: String, MD5Hash: String, type: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource interface NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
	}
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let artist: String
		
		access(all)
		let description: String
		
		access(all)
		let arLink: String
		
		access(all)
		let ipfsLink: String
		
		access(all)
		let MD5Hash: String
		
		access(all)
		let type: String
		
		init(name: String, artist: String, description: String, arLink: String, ipfsLink: String, MD5Hash: String, type: String){ 
			self.name = name
			self.artist = artist
			self.description = description
			//Stored in the arweave
			self.arLink = arLink
			//Stored in the ipfs
			self.ipfsLink = ipfsLink
			//MD5 hash of file
			self.MD5Hash = MD5Hash
			self.type = type
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata: Metadata){ 
			self.id = initID
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface MynftCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowArt(id: UInt64): &Mynft.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Mynft reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MynftCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Mynft.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowArt(id: UInt64): &Mynft.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Mynft.NFT
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	struct NftData{ 
		access(all)
		let metadata: Mynft.Metadata
		
		access(all)
		let id: UInt64
		
		init(metadata: Mynft.Metadata, id: UInt64){ 
			self.metadata = metadata
			self.id = id
		}
	}
	
	access(all)
	fun getNft(address: Address): [NftData]{ 
		var artData: [NftData] = []
		let account = getAccount(address)
		if let artCollection = account.capabilities.get<&{Mynft.MynftCollectionPublic}>(self.CollectionPublicPath).borrow<&{Mynft.MynftCollectionPublic}>(){ 
			for id in artCollection.getIDs(){ 
				var art = artCollection.borrowArt(id: id)
				artData.append(NftData(metadata: (art!).metadata, id: id))
			}
		}
		return artData
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, artist: String, description: String, arLink: String, ipfsLink: String, MD5Hash: String, type: String){ 
			emit Minted(id: Mynft.totalSupply, name: name, artist: artist, description: description, arLink: arLink, ipfsLink: ipfsLink, MD5Hash: MD5Hash, type: type)
			recipient.deposit(token: <-create Mynft.NFT(initID: Mynft.totalSupply, metadata: Metadata(name: name, artist: artist, description: description, arLink: arLink, ipfsLink: ipfsLink, MD5Hash: MD5Hash, type: type)))
			Mynft.totalSupply = Mynft.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/MynftCollection
		self.CollectionPublicPath = /public/MynftCollection
		self.MinterStoragePath = /storage/MynftMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
