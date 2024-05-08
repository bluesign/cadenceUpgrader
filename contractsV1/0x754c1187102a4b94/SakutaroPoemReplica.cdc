//
//  _____		 _			_
// /  ___|	   | |		  | |
// \ `--.   __ _ | | __ _   _ | |_   __ _  _ __   ___
//  `--. \ / _` || |/ /| | | || __| / _` || '__| / _ \
// /\__/ /| (_| ||   < | |_| || |_ | (_| || |   | (_) |
// \____/  \__,_||_|\_\ \__,_| \__| \__,_||_|	\___/
//
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import SakutaroPoemContent from "./SakutaroPoemContent.cdc"

access(all)
contract SakutaroPoemReplica: NonFungibleToken{ 
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let poem = self.getPoem()
					return MetadataViews.Display(name: (poem?.title ?? SakutaroPoemContent.name).concat(" [Replica]"), description: SakutaroPoemContent.description, thumbnail: MetadataViews.IPFSFile(cid: poem?.ipfsCid ?? "", path: nil))
			}
			return nil
		}
		
		access(all)
		fun getPoemID(): UInt32?{ 
			if self.owner == nil{ 
				return nil
			}
			var num: UInt32 = 0
			var val = (self.owner!).address.toBytes()
			for v in val{ 
				num = num + UInt32(v)
			}
			return num % 39
		}
		
		access(all)
		fun getPoem(): SakutaroPoemContent.Poem?{ 
			let poemID = self.getPoemID()
			if poemID == nil{ 
				return nil
			}
			return SakutaroPoemContent.getPoem(poemID!)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SakutaroPoemReplicaCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPoem(id: UInt64): &SakutaroPoemReplica.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Poem reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: SakutaroPoemReplicaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @SakutaroPoemReplica.NFT
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
		fun borrowPoem(id: UInt64): &SakutaroPoemReplica.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SakutaroPoemReplica.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return nft as! &SakutaroPoemReplica.NFT
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
	fun mintNFT(): @NFT{ 
		pre{ 
			SakutaroPoemReplica.totalSupply < 10000:
				"Can't mint any more"
		}
		SakutaroPoemReplica.totalSupply = SakutaroPoemReplica.totalSupply + 1
		let token <- create NFT(id: SakutaroPoemReplica.totalSupply)
		emit Mint(id: token.id)
		return <-token
	}
	
	init(){ 
		self.CollectionPublicPath = /public/SakutaroPoemReplicaCollection
		self.CollectionStoragePath = /storage/SakutaroPoemReplicaCollection
		self.totalSupply = 0
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SakutaroPoemReplica.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
