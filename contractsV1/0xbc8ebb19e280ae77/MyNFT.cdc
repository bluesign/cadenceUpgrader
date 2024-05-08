import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MyNFT: NonFungibleToken{ 
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
		let ipfsHash: String
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_ipfsHash: String, _metadata:{ String: String}){ 
			self.id = MyNFT.totalSupply
			MyNFT.totalSupply = MyNFT.totalSupply + 1
			self.ipfsHash = _ipfsHash
			self.metadata = _metadata
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowEntireNFT(id: UInt64): &MyNFT.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		// the id of the NFT --> the NFT with that id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let myToken <- token as! @MyNFT.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
		fun borrowEntireNFT(id: UInt64): &MyNFT.NFT{ 
			let reference = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return reference as! &MyNFT.NFT
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
	fun createToken(ipfsHash: String, metadata:{ String: String}): @MyNFT.NFT{ 
		return <-create NFT(_ipfsHash: ipfsHash, _metadata: metadata)
	}
	
	init(){ 
		self.totalSupply = 0
	}
}
