// SPDX-License-Identifier: MIT
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract InceptionCrystal: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var InceptionCrystalMetadata: InceptionCrystalTemplate
	
	access(all)
	resource interface InceptionCrystalCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowInceptionCrystal(id: UInt64): &InceptionCrystal.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow InceptionCrystal reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	struct InceptionCrystalTemplate{ 
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
					return MetadataViews.Display(name: InceptionCrystal.InceptionCrystalMetadata.name, description: InceptionCrystal.InceptionCrystalMetadata.description, thumbnail: MetadataViews.HTTPFile(url: (InceptionCrystal.InceptionCrystalMetadata.getMetadata()!)["uri"]!))
			}
			return nil
		}
		
		access(all)
		fun getNFTMetadata(): InceptionCrystalTemplate{ 
			return InceptionCrystal.InceptionCrystalMetadata
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
	resource Collection: InceptionCrystalCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @InceptionCrystal.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchWithdrawInceptionCrystals(amount: UInt64): @InceptionCrystal.Collection{ 
			pre{ 
				UInt64(self.getIDs().length) >= amount:
					"insufficient InceptionCrystal"
			}
			let keys = self.getIDs()
			let withdrawNFTVault <- InceptionCrystal.createEmptyCollection(nftType: Type<@InceptionCrystal.Collection>())
			var withdrawIndex = 0 as UInt64
			while withdrawIndex < amount{ 
				withdrawNFTVault.deposit(token: <-self.withdraw(withdrawID: keys[withdrawIndex]))
				withdrawIndex = withdrawIndex + 1
			}
			return <-(withdrawNFTVault as! @InceptionCrystal.Collection?)!
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
		fun borrowInceptionCrystal(id: UInt64): &InceptionCrystal.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &InceptionCrystal.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &InceptionCrystal.NFT
			return exampleNFT as &{ViewResolver.Resolver}
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
		fun mintInceptionCrystal(recipient: &{NonFungibleToken.CollectionPublic}){ 
			let newNFT: @NFT <- create InceptionCrystal.NFT(initID: InceptionCrystal.totalSupply, serialNumber: InceptionCrystal.totalSupply)
			emit Minted(id: newNFT.id)
			recipient.deposit(token: <-newNFT)
			InceptionCrystal.totalSupply = InceptionCrystal.totalSupply + 1
		}
		
		access(all)
		fun updateInceptionCrystalMetadata(newMetadata:{ String: String}){ 
			InceptionCrystal.InceptionCrystalMetadata.updateMetadata(newMetadata: newMetadata)
		}
	}
	
	access(all)
	fun getInceptionCrystalMetadata(): InceptionCrystal.InceptionCrystalTemplate{ 
		return InceptionCrystal.InceptionCrystalMetadata
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/InceptionCrystalCollection
		self.CollectionPublicPath = /public/InceptionCrystalCollection
		self.AdminStoragePath = /storage/InceptionCrystalAdmin
		self.totalSupply = 1
		self.InceptionCrystalMetadata = InceptionCrystalTemplate(name: "Inception Crystal", description: "Inception Crystal can be used as a currency in the Inception Animals universe", metadata:{} )
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
