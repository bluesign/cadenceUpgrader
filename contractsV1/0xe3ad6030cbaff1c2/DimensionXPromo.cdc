// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.
import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract DimensionXPromo: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(self)
	var metadataUrl: String
	
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
					return MetadataViews.ExternalURL(DimensionXPromo.metadataUrl.concat(self.id.toString()))
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "DimensionX #".concat(self.id.toString()), description: "A Promotional NFT for the DimensionX Game!", thumbnail: MetadataViews.HTTPFile(url: "https://dimensionxstorage.blob.core.windows.net/dmxgamepromos/dmx_placeholder_promo_image.png"))
				case Type<MetadataViews.Royalties>():
					return [MetadataViews.Royalty(receiver: DimensionXPromo.account.capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: UFix64(0.10), description: "Crypthulhu royalties")]
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DimensionXPromo.CollectionStoragePath, publicPath: DimensionXPromo.CollectionPublicPath, publicCollection: Type<&DimensionXPromo.Collection>(), publicLinkedType: Type<&DimensionXPromo.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DimensionXPromo.createEmptyCollection(nftType: Type<@DimensionXPromo.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Dimension X", description: "Dimension X is a Free-to-Play, Play-to-Earn strategic role playing game on the Flow blockchain set in the Dimension X comic book universe, where a pan-dimensional explosion created super powered humans, aliens and monsters with radical and terrifying superpowers!", externalURL: MetadataViews.ExternalURL("https://dimensionxnft.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionXPromo.metadataUrl.concat("collection_image.png")), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: DimensionXPromo.metadataUrl.concat("collection_banner.png")), mediaType: "image/png"), socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/BK5yAD6VQg"), "twitter": MetadataViews.ExternalURL("https://twitter.com/DimensionX_NFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface DimensionXPromoCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDimensionXPromo(id: UInt64): &DimensionXPromo.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DimensionXPromo reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: DimensionXPromoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @DimensionXPromo.NFT
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
		fun borrowDimensionXPromo(id: UInt64): &DimensionXPromo.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DimensionXPromo.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dimensionXPromo = nft as! &DimensionXPromo.NFT
			return dimensionXPromo as &{ViewResolver.Resolver}
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
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &Collection){ 
			
			// create a new NFT
			var newNFT <- create NFT(id: DimensionXPromo.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			DimensionXPromo.totalSupply = DimensionXPromo.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.metadataUrl = "https://www.dimensionx.com/promo/"
		
		// Set the named paths
		self.CollectionStoragePath = /storage/dimensionXPromoCollection
		self.CollectionPublicPath = /public/dimensionXPromoCollection
		self.MinterStoragePath = /storage/dimensionXMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&DimensionXPromo.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
