import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ByteNextMedalNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var CollectionPublicPath: PublicPath
	
	access(all)
	var CollectionStoragePath: StoragePath
	
	access(all)
	var MinterStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	let mintedNfts:{ UInt64: Bool}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		var metadata:{ String: String}
		
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["metaURI"] ?? ""))
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun borrow(id: UInt64): &NFT?
		
		access(all)
		fun borrowMedalNFT(id: UInt64): &ByteNextMedalNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow AADigital reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
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
			let token <- token as! @ByteNextMedalNFT.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let authRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ref = authRef as! &NFT
			return ref as! &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &ByteNextMedalNFT.NFT
		}
		
		access(all)
		fun borrowMedalNFT(id: UInt64): &ByteNextMedalNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ByteNextMedalNFT.NFT
			}
			return nil
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return (ref as! &ByteNextMedalNFT.NFT).getMetadata()
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
		fun mint(id: UInt64, metadata:{ String: String}): @{NonFungibleToken.NFT}{ 
			pre{ 
				ByteNextMedalNFT.mintedNfts[id] == nil || ByteNextMedalNFT.mintedNfts[id] == false:
					"This id has been minted before"
			}
			ByteNextMedalNFT.totalSupply = ByteNextMedalNFT.totalSupply + 1
			let token <- create NFT(id: id, metadata: metadata)
			ByteNextMedalNFT.mintedNfts[id] = true
			emit Mint(id: token.id, metadata: metadata)
			return <-token
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/ByteNextMedalNFTCollection
		self.CollectionStoragePath = /storage/ByteNextMedalNFTCollection
		self.MinterStoragePath = /storage/ByteNextMedalNFTMinter
		self.mintedNfts ={} 
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
