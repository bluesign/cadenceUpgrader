import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/**

A Metapier launchpad owner pass is an NFT that can be sent to
a project/token owner. The holder of this pass may execute 
functions designed for project owners in the corresponding 
launchpad pool.

For example, when the funding period is finished, the holder of
this pass may withdraw all the funds raised by the pool.

 */

access(all)
contract MetapierLaunchpadOwnerPass: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event PassMinted(id: UInt64, launchPoolId: String, _for: Address)
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let launchPoolId: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, launchPoolId: String){ 
			self.id = id
			self.launchPoolId = launchPoolId
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		fun getIdsByPoolId(poolId: String): [UInt64]
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// make sure the token has the right type
			let token <- token as! @MetapierLaunchpadOwnerPass.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary with a force assignment
			// if there is already a value at that key, it will fail and revert
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
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
		fun borrowPrivatePass(id: UInt64): &MetapierLaunchpadOwnerPass.NFT{ 
			let passRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return passRef as! &MetapierLaunchpadOwnerPass.NFT
		}
		
		access(all)
		fun getIdsByPoolId(poolId: String): [UInt64]{ 
			let ids: [UInt64] = []
			for key in self.ownedNFTs.keys{ 
				let passRef = self.borrowPrivatePass(id: key)
				if passRef.launchPoolId == poolId{ 
					ids.append(key)
				}
			}
			return ids
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
		fun mintNFT(recipient: Capability<&{NonFungibleToken.CollectionPublic}>, launchPoolId: String){ 
			// create a new NFT
			let newNFT <- create NFT(id: MetapierLaunchpadOwnerPass.totalSupply, launchPoolId: launchPoolId)
			emit PassMinted(id: newNFT.id, launchPoolId: launchPoolId, _for: recipient.address)
			(			 
			 // deposit it in the recipient's account using their reference
			 recipient.borrow()!).deposit(token: <-newNFT)
			MetapierLaunchpadOwnerPass.totalSupply = MetapierLaunchpadOwnerPass.totalSupply + 1
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/MetapierLaunchpadOwnerCollection
		self.CollectionPublicPath = /public/MetapierLaunchpadOwnerCollection
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: /storage/MetapierLaunchpadOwnerMinter)
		emit ContractInitialized()
	}
}
