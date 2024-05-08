/* 
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*   
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract FlowtyTestNFT: NonFungibleToken, ViewResolver{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event CollectionCreated(id: UInt64)
	
	access(all)
	event CollectionDestroyed(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let data:{ String: AnyStruct}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty]){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.data ={ "name": name, "createdOn": getCurrentBlock().timestamp}
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionName = self.id % 2 == 0 ? "Evens" : "Odds"
					let editionInfo = MetadataViews.Edition(name: editionName, number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://flowty.io/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: FlowtyTestNFT.CollectionStoragePath, publicPath: FlowtyTestNFT.CollectionPublicPath, publicCollection: Type<&FlowtyTestNFT.Collection>(), publicLinkedType: Type<&FlowtyTestNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-FlowtyTestNFT.createEmptyCollection(nftType: Type<@FlowtyTestNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Flowty Test NFT Collection", description: "This collection is used for testing things out on flowty.", externalURL: MetadataViews.ExternalURL("https://flowty.io/"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flowty-images/flowty-logo.jpeg"), mediaType: "image/jpeg"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flowty-images/flowty-banner.jpeg"), mediaType: "image/jpeg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")})
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.data, excludedNames: [])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface FlowtyTestNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowFlowtyTestNFT(id: UInt64): &FlowtyTestNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FlowtyTestNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: FlowtyTestNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
			emit CollectionCreated(id: self.uuid)
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FlowtyTestNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowFlowtyTestNFT(id: UInt64): &FlowtyTestNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FlowtyTestNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let FlowtyTestNFT = nft as! &FlowtyTestNFT.NFT
			return FlowtyTestNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-(create Collection() as! @FlowtyTestNFT.Collection)
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
			let royaltyRecipient = getAccount(FlowtyTestNFT.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/placeholder)
			let cutInfo = MetadataViews.Royalty(receiver: royaltyRecipient!, cut: 0.0, description: "")
			FlowtyTestNFT.totalSupply = FlowtyTestNFT.totalSupply + 1
			let thumbnail = "https://storage.googleapis.com/flowty-images/flowty-logo.jpeg"
			let name = "Flowty Test NFT #".concat(FlowtyTestNFT.totalSupply.toString())
			let description = "This nft is used for testing things out on flowty."
			
			// create a new NFT
			var newNFT <- create NFT(id: FlowtyTestNFT.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: [cutInfo])
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://flowty.io/")
			case Type<MetadataViews.NFTCollectionDisplay>():
				return MetadataViews.NFTCollectionDisplay(name: "Flowty Test NFT Collection", description: "This collection is used for testing things out on flowty.", externalURL: MetadataViews.ExternalURL("https://flowty.io/"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flowty-images/flowty-logo.jpeg"), mediaType: "image/jpeg"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/flowty-images/flowty-banner.jpeg"), mediaType: "image/jpeg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flowty_io")})
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: FlowtyTestNFT.CollectionStoragePath, publicPath: FlowtyTestNFT.CollectionPublicPath, publicCollection: Type<&FlowtyTestNFT.Collection>(), publicLinkedType: Type<&FlowtyTestNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FlowtyTestNFT.createEmptyCollection(nftType: Type<@FlowtyTestNFT.Collection>())
					})
		}
		return nil
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/FlowtyTestNFTCollection
		self.CollectionPublicPath = /public/FlowtyTestNFTCollection
		self.MinterStoragePath = /storage/FlowtyTestNFTMinter
		self.MinterPublicPath = /public/FlowtyTestNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&FlowtyTestNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&FlowtyTestNFT.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
