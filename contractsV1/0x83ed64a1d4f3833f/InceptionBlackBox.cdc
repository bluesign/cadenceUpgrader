// SPDX-License-Identifier: MIT
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract InceptionBlackBox: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var crystalPrice: UInt64
	
	access(all)
	var mintLimit: UInt64
	
	access(all)
	var InceptionBlackBoxMetadata: InceptionBlackBoxTemplate
	
	access(all)
	resource interface InceptionBlackBoxCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowInceptionBlackBox(id: UInt64): &InceptionBlackBox.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow InceptionBlackBox reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct InceptionBlackBoxTemplate{ 
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(self)
		var metadata:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun updateMetadata(newMetadata:{ String: String}){ 
			pre{ 
				newMetadata.length != 0:
					"New Template metadata cannot be empty"
			}
			self.metadata = newMetadata
		}
		
		init(name: String, description: String, metadata:{ String: String}){ 
			self.name = name
			self.description = description
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: InceptionBlackBox.InceptionBlackBoxMetadata.name, description: InceptionBlackBox.InceptionBlackBoxMetadata.description, thumbnail: MetadataViews.HTTPFile(url: (InceptionBlackBox.InceptionBlackBoxMetadata.getMetadata()!)["uri"]!))
			}
			return nil
		}
		
		access(all)
		fun getNFTMetadata(): InceptionBlackBoxTemplate{ 
			return InceptionBlackBox.InceptionBlackBoxMetadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, serialNumber: UInt64){ 
			self.id = initID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource Collection: InceptionBlackBoxCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @InceptionBlackBox.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(collection: @Collection){ 
			let keys = collection.getIDs()
			for key in keys{ 
				self.deposit(token: <-collection.withdraw(withdrawID: key))
			}
			destroy collection
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
		fun borrowInceptionBlackBox(id: UInt64): &InceptionBlackBox.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &InceptionBlackBox.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &InceptionBlackBox.NFT
			return exampleNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun openBox(tokenID: UInt64){ 
			let token <- self.ownedNFTs.remove(key: tokenID) ?? panic("missing NFT")
			emit Opened(id: token.id)
			destroy <-token
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
	resource Admin{ 
		access(all)
		fun mintInceptionBlackBox(recipient: &{NonFungibleToken.CollectionPublic}){ 
			pre{ 
				InceptionBlackBox.mintLimit >= InceptionBlackBox.totalSupply:
					"InceptionBlackBox is out of stock"
			}
			let newNFT: @NFT <- create InceptionBlackBox.NFT(initID: InceptionBlackBox.totalSupply, serialNumber: InceptionBlackBox.totalSupply)
			emit Minted(id: newNFT.id)
			recipient.deposit(token: <-newNFT)
			InceptionBlackBox.totalSupply = InceptionBlackBox.totalSupply + 1
		}
		
		access(all)
		fun updateInceptionBlackBoxMetadata(newMetadata:{ String: String}){ 
			InceptionBlackBox.InceptionBlackBoxMetadata.updateMetadata(newMetadata: newMetadata)
		}
		
		access(all)
		fun updateInceptionBlackBoxCrystalPrice(newCrystalPrice: UInt64){ 
			InceptionBlackBox.crystalPrice = newCrystalPrice
		}
		
		access(all)
		fun increaseMintLimit(increment: UInt64){ 
			pre{ 
				increment > 0:
					"increment must be a positive number"
			}
			InceptionBlackBox.mintLimit = InceptionBlackBox.mintLimit + increment
		}
	}
	
	access(all)
	fun getInceptionBlackBoxMetadata(): InceptionBlackBox.InceptionBlackBoxTemplate{ 
		return InceptionBlackBox.InceptionBlackBoxMetadata
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/InceptionBlackBoxCollection
		self.CollectionPublicPath = /public/InceptionBlackBoxCollection
		self.AdminStoragePath = /storage/InceptionBlackBoxAdmin
		self.totalSupply = 1
		self.crystalPrice = 18446744073709551615
		self.mintLimit = 0
		self.InceptionBlackBoxMetadata = InceptionBlackBoxTemplate(name: "Inception Black Box", description: "Raffle Box that contains good things", metadata:{} )
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
