import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract ExampleNFT: NonFungibleToken, ViewResolver{ 
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
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let serial: UInt64
		
		access(all)
		let extraMetadata:{ String: AnyStruct}
		
		init(name: String, description: String, thumbnail: String, extraMetadata:{ String: AnyStruct}){ 
			self.id = self.uuid
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.serial = ExampleNFT.totalSupply
			self.extraMetadata = extraMetadata
			ExampleNFT.totalSupply = ExampleNFT.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: ExampleNFT.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05, description: "Royalty for creating the NFTs.")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://academy.ecdao.org/en/quickstarts/1-non-fungible-token-svelte")
				case Type<MetadataViews.NFTCollectionData>():
					return ExampleNFT.resolveView(view)
				case Type<MetadataViews.NFTCollectionDisplay>():
					return ExampleNFT.resolveView(view)
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits: [String] = ["mintedTime", "foo"]
					let traitsView: MetadataViews.Traits = MetadataViews.dictToTraits(dict: self.extraMetadata, excludedNames: excludedTraits)
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait: MetadataViews.Trait = MetadataViews.Trait(name: "mintedTime", value: self.extraMetadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
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
			let token: @NFT <- token as! @ExampleNFT.NFT
			let id: UInt64 = token.uuid
			// add the new token to the dictionary which removes the old one
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft: &{NonFungibleToken.NFT} = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT: &NFT = nft as! &ExampleNFT.NFT
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Minter{ 
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &ExampleNFT.Collection, name: String, description: String, thumbnail: String, extraMetadata:{ String: AnyStruct}){ 
			let currentBlock: Block = getCurrentBlock()
			extraMetadata["mintedBlock"] = currentBlock.height
			extraMetadata["mintedTime"] = currentBlock.timestamp
			extraMetadata["minter"] = (recipient.owner!).address
			// create a new NFT
			var newNFT: @NFT <- create NFT(name: name, description: description, thumbnail: thumbnail, extraMetadata: extraMetadata)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: ExampleNFT.CollectionStoragePath, publicPath: ExampleNFT.CollectionPublicPath, publicCollection: Type<&ExampleNFT.Collection>(), publicLinkedType: Type<&ExampleNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-ExampleNFT.createEmptyCollection(nftType: Type<@ExampleNFT.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "The Example Collection", description: "This collection is used as an example to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://academy.ecdao.org/en/quickstarts/1-non-fungible-token"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/emerald_dao")})
		}
		return nil
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		// Set the named paths
		self.CollectionStoragePath = /storage/EmeraldAcademyNonFungibleTokenCollection
		self.CollectionPublicPath = /public/EmeraldAcademyNonFungibleTokenCollection
		self.MinterStoragePath = /storage/EmeraldAcademyNonFungibleTokenMinter
		self.account.storage.save(<-create Minter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
