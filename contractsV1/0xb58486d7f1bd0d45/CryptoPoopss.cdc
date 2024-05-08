import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract CryptoPoopss: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(metadata:{ String: String}){ 
			self.id = CryptoPoopss.totalSupply
			CryptoPoopss.totalSupply = CryptoPoopss.totalSupply + 1 as UInt64
			self.metadata = metadata
		}
	}
	
	access(all)
	resource interface MyCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowEntireNFT(id: UInt64): &NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, MyCollectionPublic{ 
		// id of the NFT -> NFT with that id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let cryptoPoop <- token as! @NFT
			emit Deposit(id: cryptoPoop.id, to: (self.owner!).address)
			self.ownedNFTs[cryptoPoop.id] <-! cryptoPoop
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This collection doesn't cotain nft with that id")
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? ?? panic("nothing in this index")
		}
		
		access(all)
		fun borrowEntireNFT(id: UInt64): &NFT{ 
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? ?? panic("something")
			return refNFT as! &NFT
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
	resource NFTMinter{ 
		access(all)
		fun createNFT(metadata:{ String: String}): @NFT{ 
			let newNFT <- create NFT(metadata: metadata)
			return <-newNFT
		}
		
		init(){} 
	}
	
	init(){ 
		self.totalSupply = 0
		emit ContractInitialized()
		self.account.storage.save(<-create NFTMinter(), to: /storage/Mintere)
	}
}
