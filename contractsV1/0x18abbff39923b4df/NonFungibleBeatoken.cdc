// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NonFungibleBeatoken: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let storageCollection: StoragePath
	
	access(all)
	let publicReceiver: PublicPath
	
	access(all)
	let storageMinter: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event CreatedNft(id: UInt64)
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let ipfs_hash: String
		
		access(all)
		let token_uri: String
		
		access(all)
		let description: String
		
		init(name: String, ipfs_hash: String, token_uri: String, description: String){ 
			self.name = name
			self.ipfs_hash = ipfs_hash
			self.token_uri = token_uri
			self.description = description
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
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
	resource interface BeatokenCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBeatokenNFT(id: UInt64): &NonFungibleBeatoken.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow BeatokenNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: BeatokenCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			emit Deposit(id: token.id, to: self.owner?.address)
			let oldToken <- self.ownedNFTs[token.id] <- token
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
		fun borrowBeatokenNFT(id: UInt64): &NonFungibleBeatoken.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &NonFungibleBeatoken.NFT
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
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, ipfs_hash: String, token_uri: String, description: String){ 
			NonFungibleBeatoken.totalSupply = NonFungibleBeatoken.totalSupply + 1 as UInt64
			let id = NonFungibleBeatoken.totalSupply
			let newNFT <- create NFT(initID: id, metadata: Metadata(name: name, ipfs_hash: ipfs_hash, token_uri: token_uri.concat(id.toString()), description: description))
			recipient.deposit(token: <-newNFT)
			emit CreatedNft(id: id)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		
		// Define paths
		self.storageCollection = /storage/beatokenNFTCollection
		self.publicReceiver = /public/beatokenNFTReceiver
		self.storageMinter = /storage/beatokenNFTMinter
		
		// Create, store and explose capability for collection
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.storageCollection)
		var capability_1 = self.account.capabilities.storage.issue<&NonFungibleBeatoken.Collection>(self.storageCollection)
		self.account.capabilities.publish(capability_1, at: self.publicReceiver)
		self.account.storage.save(<-create NFTMinter(), to: self.storageMinter)
		emit ContractInitialized()
	}
}
