// Description: Smart Contract for Sharks Virtual Commemorative Tickets
// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Sharks: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var link: String
		
		access(all)
		var batch: UInt32
		
		access(all)
		var sequence: UInt16
		
		access(all)
		var limit: UInt16
		
		init(initID: UInt64, initlink: String, initbatch: UInt32, initsequence: UInt16, initlimit: UInt16){ 
			self.id = initID
			self.link = initlink
			self.batch = initbatch
			self.sequence = initsequence
			self.limit = initlimit
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Sharks.CollectionStoragePath, publicPath: Sharks.CollectionPublicPath, publicCollection: Type<&Sharks.Collection>(), publicLinkedType: Type<&Sharks.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Sharks.createEmptyCollection(nftType: Type<@Sharks.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SharksCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSharks(id: UInt64): &Sharks.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Sharks reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: SharksCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Sharks.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let sharksNFT = nft as! &Sharks.NFT
			return sharksNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowSharks(id: UInt64): &Sharks.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			} else{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Sharks.NFT
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		var minterID: UInt64
		
		init(){ 
			self.minterID = 0
		}
		
		access(all)
		fun mintNFT(glink: String, gbatch: UInt32, glimit: UInt16, gsequence: UInt16): @NFT{ 
			let tokenID = UInt64(gbatch) << 32 | UInt64(glimit) << 16 | UInt64(gsequence)
			var newNFT <- create NFT(initID: tokenID, initlink: glink, initbatch: gbatch, initsequence: gsequence, initlimit: glimit)
			self.minterID = tokenID
			Sharks.totalSupply = Sharks.totalSupply + UInt64(1)
			return <-newNFT
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/SharksCollection
		self.CollectionPublicPath = /public/SharksCollection
		self.MinterStoragePath = /storage/SharksMinter
		self.totalSupply = 0
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{Sharks.SharksCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
