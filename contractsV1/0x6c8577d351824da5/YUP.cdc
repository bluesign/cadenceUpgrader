/**
* SPDX-License-Identifier: UNLICENSED
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract YUP: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, influencerID: UInt32, editionID: UInt32, serialNumber: UInt32, url: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let influencerID: UInt32
		
		access(all)
		let editionID: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let url: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, initInfluencerID: UInt32, initEditionID: UInt32, initSerialNumber: UInt32, initUrl: String){ 
			self.id = initID
			self.influencerID = initInfluencerID
			self.editionID = initEditionID
			self.serialNumber = initSerialNumber
			self.url = initUrl
		}
	}
	
	access(all)
	resource interface YUPCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowYUP(id: UInt64): &YUP.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow YUP reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: YUPCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @YUP.NFT
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
		fun borrowYUP(id: UInt64): &YUP.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &YUP.NFT
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
	resource NFTMinter{ 
		access(all)
		fun mintYUP(recipient: &{NonFungibleToken.CollectionPublic}, influencerID: UInt32, editionID: UInt32, serialNumber: UInt32, url: String){ 
			emit Minted(id: YUP.totalSupply, influencerID: influencerID, editionID: editionID, serialNumber: serialNumber, url: url)
			recipient.deposit(token: <-create YUP.NFT(initID: YUP.totalSupply, initInfluencerID: influencerID, initEditionID: editionID, initSerialNumber: serialNumber, initUrl: url))
			YUP.totalSupply = YUP.totalSupply + 1 as UInt64
		}
	}
	
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &YUP.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&YUP.Collection>(YUP.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		return collection.borrowYUP(id: itemID)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/YUPMobileAppCollection
		self.CollectionPublicPath = /public/YUPMobileAppCollection
		self.MinterStoragePath = /storage/YUPMobileAppMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
