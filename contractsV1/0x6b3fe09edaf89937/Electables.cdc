/*
  Electables.cdc

  Description: Central Smart Contract for Electables

  This contract defines the Electables NFT, adds functionality for minting an Electable and defines the public Electables Collection. There are transactions in this repository's transactions directory that can be used to
  - Set up an account to receive Electables, i.e. create a public Electable Collection path in an account
  - Mint a new Electable
  - Transfer an Electable from on account's collection to another account's collection

  There are also scripts that can:
  - Get a the count of Electables in an account's collection
  - Get the total supply of Electables
  - Get an Electable by id and account address
  - Get an Electable's metadata by id and account address

  This contract was based on KittyItems.cdc and ExampleNFT.cdc: https://github.com/onflow/kitty-items and https://github.com/onflow/flow-nft/blob/master/contracts/ExampleNFT.cdc, respectively.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Electables: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, timestamp: UFix64)
	
	// Named Paths
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
		let electableType: String
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		var attributes:{ String: String}
		
		access(self)
		var data:{ String: String}
		
		init(initID: UInt64, electableType: String, name: String, description: String, thumbnail: String, attributes:{ String: String}, data:{ String: String}){ 
			self.id = initID
			self.electableType = electableType
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.attributes = attributes
			self.data = data
		}
		
		access(all)
		fun getAttributes():{ String: String}{ 
			return self.attributes
		}
		
		access(all)
		fun getData():{ String: String}{ 
			return self.data
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnail, path: nil))
			}
			return nil
		}
		
		access(contract)
		fun overwriteAttributes(attributes:{ String: String}){ 
			self.attributes = attributes
		}
		
		access(contract)
		fun overwriteData(data:{ String: String}){ 
			self.data = data
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface ElectablesPublicCollection{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		// borrowNFT will return a NonFungibleToken.NFT which only allows for accessing the id field.
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// borrowElectable will return a Electables.NFT which exposes the public fields defined in this file on Electables.NFT. Right now
		// Electables.NFT only has an id field, but will later include the electable attributes as well.
		access(all)
		fun borrowElectable(id: UInt64): &Electables.NFT?
	}
	
	access(all)
	resource Collection: ElectablesPublicCollection, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Provider Interface
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Receiver and CollectionPublic Interfaces
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// CollectionPublic Interface
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowElectable(id: UInt64): &Electables.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Electable reference: The ID of the returned reference is incorrect"
			}
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Electables.NFT?
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let electable = nft as! &Electables.NFT
			return electable as &{ViewResolver.Resolver}
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, electableType: String, name: String, description: String, thumbnail: String, attributes:{ String: String}, data:{ String: String}){ 
			emit Minted(id: Electables.totalSupply, timestamp: getCurrentBlock().timestamp)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Electables.NFT(initID: Electables.totalSupply, electableType: electableType, name: name, description: description, thumbnail: thumbnail, attributes: attributes, data: data))
			Electables.totalSupply = Electables.totalSupply + 1 as UInt64
		}
		
		access(all)
		fun overwriteNFTAttributes(nftReference: &NFT, attributes:{ String: String}){ 
			nftReference.overwriteAttributes(attributes: attributes)
		}
		
		access(all)
		fun overwriteNFTData(nftReference: &NFT, data:{ String: String}){ 
			nftReference.overwriteData(data: data)
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/electablesCollection
		self.CollectionPublicPath = /public/electablesCollection
		self.MinterStoragePath = /storage/electableMinter
		self.totalSupply = 0
		
		// Create the Minter and put it in Storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
