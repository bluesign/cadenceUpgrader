import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ThaSup: NonFungibleToken{ 
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
	
	// Our NFT resource conforms to the INFT interface
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
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
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
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface ThaSupCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	// Same goes for our Collection, it conforms to multiple interfaces 
	access(all)
	resource Collection: ThaSupCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ThaSup.NFT
			let id: UInt64 = token.id
			let oldToken: @{NonFungibleToken.NFT}? <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This collection doesn't contain an NFT with that ID")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ThaSup = nft as! &ThaSup.NFT
			return ThaSup as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
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
		
		// Mints a new NFT with a new ID and deposits it 
		// in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, metadata:{ String: AnyStruct}){ 
			
			// create a new NFT
			var newNFT <- create NFT(id: ThaSup.totalSupply, name: name, description: description, thumbnail: thumbnail, metadata: metadata)
			
			// Deposit it in the recipient's account using their collection ref
			recipient.deposit(token: <-newNFT)
			ThaSup.totalSupply = ThaSup.totalSupply + 1
		}
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: ThaSup.CollectionStoragePath, publicPath: ThaSup.CollectionPublicPath, publicCollection: Type<&ThaSup.Collection>(), publicLinkedType: Type<&ThaSup.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-ThaSup.createEmptyCollection(nftType: Type<@ThaSup.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "ipfs://bafybeie4bchvcflip2wf57wn63y3wqphsdgm24nichzi3nfpaertaqbgwq/ThaSup.jpg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "ThaSup", description: "The collection of Tha Supreme", externalURL: MetadataViews.ExternalURL("https://www.thasup.com"), squareImage: media, bannerImage: media, socials:{ "Instagram": MetadataViews.ExternalURL("www.instagram.com"), "Twitter": MetadataViews.ExternalURL("www.twitter.com")})
		}
		return nil
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/ThaSupCollection
		self.CollectionPublicPath = /public/ThaSupCollection
		self.MinterStoragePath = /storage/ThaSupMinter
		
		// Create a Collection for the deployer
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&ThaSup.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
