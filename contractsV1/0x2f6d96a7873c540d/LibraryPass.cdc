// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract LibraryPass: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, ipfsLink: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
	}
	
	//you can extend these fields if you need
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let ipfsLink: String
		
		init(name: String, ipfsLink: String){ 
			self.name = name
			//Stored in the ipfs
			self.ipfsLink = ipfsLink
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let type: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, metadata: Metadata, type: UInt64){ 
			self.id = initID
			self.metadata = metadata
			self.type = type
		}
	}
	
	access(all)
	resource interface LibraryPassCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowArt(id: UInt64): &LibraryPass.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LibraryPass reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LibraryPassCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @LibraryPass.NFT
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
		fun borrowArt(id: UInt64): &LibraryPass.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &LibraryPass.NFT
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
		let metadata: LibraryPass.Metadata
		
		access(all)
		let id: UInt64
		
		access(all)
		let type: UInt64
		
		init(metadata: LibraryPass.Metadata, id: UInt64, type: UInt64){ 
			self.metadata = metadata
			self.id = id
			self.type = type
		}
	}
	
	access(all)
	fun getNft(address: Address): [NftData]{ 
		var artData: [NftData] = []
		let account = getAccount(address)
		if let artCollection = account.capabilities.get<&{LibraryPass.LibraryPassCollectionPublic}>(self.CollectionPublicPath).borrow<&{LibraryPass.LibraryPassCollectionPublic}>(){ 
			for id in artCollection.getIDs(){ 
				var art = artCollection.borrowArt(id: id)
				artData.append(NftData(metadata: (art!).metadata, id: id, type: (art!).type))
			}
		}
		return artData
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, ipfsLink: String, type: UInt64){ 
			emit Minted(id: LibraryPass.totalSupply, name: name, ipfsLink: ipfsLink)
			recipient.deposit(token: <-create LibraryPass.NFT(initID: LibraryPass.totalSupply, metadata: Metadata(name: name, ipfsLink: ipfsLink), type: type))
			LibraryPass.totalSupply = LibraryPass.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/LibraryPassCollection
		self.CollectionPublicPath = /public/LibraryPassCollection
		self.MinterStoragePath = /storage/LibraryPassMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let collection <- LibraryPass.createEmptyCollection(nftType: Type<@LibraryPass.Collection>())
		self.account.storage.save(<-collection, to: LibraryPass.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&LibraryPass.Collection>(LibraryPass.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LibraryPass.CollectionPublicPath)
		emit ContractInitialized()
	}
}
