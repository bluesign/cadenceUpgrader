import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import DimensionX from "./DimensionX.cdc"

access(all)
contract DimensionXComics: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalBurned: UInt64
	
	access(all)
	var metadataUrl: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	access(all)
	event TurnIn(id: UInt64, hero: UInt64)
	
	access(all)
	event MinterCreated()
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(DimensionXComics.metadataUrl.concat("comics/").concat(self.id.toString()))
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "DimensionXComics #".concat(self.id.toString()), description: "A Comics NFT Project with Utility in the Dimension-X Game!", thumbnail: MetadataViews.HTTPFile(url: DimensionXComics.metadataUrl.concat("comics/i/").concat(self.id.toString()).concat(".jpg")))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					royalties.append(MetadataViews.Royalty(receiver: DimensionXComics.account.capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: UFix64(0.10), description: "Crypthulhu royalties"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DimensionXComics.CollectionStoragePath, publicPath: DimensionXComics.CollectionPublicPath, publicCollection: Type<&DimensionXComics.Collection>(), publicLinkedType: Type<&DimensionXComics.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DimensionXComics.createEmptyCollection(nftType: Type<@DimensionXComics.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Dimension X", description: "Dimension X is a Free-to-Play, Play-to-Earn strategic role playing game on the Flow blockchain set in the Dimension X comic book universe, where a pan-dimensional explosion created super powered humans, aliens and monsters with radical and terrifying superpowers!", externalURL: MetadataViews.ExternalURL("https://dimensionxnft.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionXComics.metadataUrl.concat("comics/collection_image.png")), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionXComics.metadataUrl.concat("comics/collection_banner.png")), mediaType: "image/png"), socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/dimensionx"), "twitter": MetadataViews.ExternalURL("https://twitter.com/DimensionX_NFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDimensionXComics(id: UInt64): &DimensionXComics.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DimensionXComics reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
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
			let token <- token as! @DimensionXComics.NFT
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
		fun borrowDimensionXComics(id: UInt64): &DimensionXComics.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DimensionXComics.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dmxNft = nft as! &DimensionXComics.NFT
			return dmxNft as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun turnInComics(comic_ids: [UInt64], hero: &DimensionX.NFT){ 
			if comic_ids.length > 4{ 
				panic("Too many comics being burned")
			}
			if self.owner?.address != hero.owner?.address{ 
				panic("You must own the hero")
			}
			for id in comic_ids{ 
				let token <- self.withdraw(withdrawID: id)
				emit TurnIn(id: token.id, hero: hero.id)
				destroy token
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// range if possible
		
		// Determine the next available ID for the rest of NFTs and take into
		// account the custom NFTs that have been minted outside of the reserved
		// range
		access(all)
		fun getNextID(): UInt64{ 
			return DimensionXComics.totalSupply + UInt64(1)
		}
	/* 
			pub fun mintNFT(
				recipient: &Collection{NonFungibleToken.CollectionPublic},
			) {
				// Determine the next available ID
				var nextId = self.getNextID()
	
				// Update supply counters
				DimensionXComics.totalSupply = DimensionXComics.totalSupply + UInt64(1)
	
				self.mint(
					recipient: recipient,
					id: nextId
				)
			}
	
		   
	 
			priv fun mint(
				recipient: &Collection{NonFungibleToken.CollectionPublic},
				id: UInt64
			) {
				panic("Minting currently disabled")
				// create a new NFT
				var newNFT <- create NFT(id: id)
				emit Mint(id: id)
				  
				// deposit it in the recipient's account using their reference
				recipient.deposit(token: <-newNFT)
			}
			*/
	
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setMetadataUrl(url: String){ 
			DimensionXComics.metadataUrl = url
		}
		
		access(all)
		fun createNFTMinter(): @NFTMinter{ 
			emit MinterCreated()
			return <-create NFTMinter()
		}
	}
	
	init(){ 
		// Initialize supply counters
		self.totalSupply = 0
		
		// Initialize burned counters
		self.totalBurned = 0
		self.metadataUrl = "https://metadata.dimensionx.com/"
		
		// Set the named paths
		self.CollectionStoragePath = /storage/dmxComicsCollection
		self.CollectionPublicPath = /public/dmxComicsCollection
		self.AdminStoragePath = /storage/dmxComicsAdmin
		self.MinterStoragePath = /storage/dmxComicsMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&DimensionXComics.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		let admin <- create Admin()
		let minter <- admin.createNFTMinter()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
