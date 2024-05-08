/*
	A NFT contract for the Goated Goats individual traits.
	
	Key Callouts: 
	* Unlimited supply of traits
	* Created via GoatedGoatsTrait only by admin on back-end
	* Store collection id from pack metadata
	* Store pack id that created this trait (specified by Admin at Trait creation time)
	* Main id for a trait is auto-increment
	* Collection-level metadata
	* Edition-level metadata (ipfs link, trait name, etc)
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GoatedGoatsTrait: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// GoatedGoatsTrait Events
	// -----------------------------------------------------------------------
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// GoatedGoatsTrait Fields
	// -----------------------------------------------------------------------
	access(all)
	var name: String
	
	access(self)
	var collectionMetadata:{ String: String}
	
	access(self)
	let idToTraitMetadata:{ UInt64: TraitMetadata}
	
	access(all)
	struct TraitMetadata{ 
		access(all)
		let metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let packID: UInt64
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata:{ String: String} = self.getMetadata()
			switch view{ 
				case Type<MetadataViews.Trait>():
					if let skinFileName: String = metadata["skinFilename"]{ 
						let skin: String = GoatedGoatsTrait.formatFileName(value: skinFileName, prefix: "skin")
						let skinRarity: String = metadata["skinRarity"]!
					}
					return MetadataViews.Trait(name: metadata["traitSlot"]!, value: GoatedGoatsTrait.formatFileName(value: metadata["fileName"]!, prefix: metadata["traitSlot"]!), displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: metadata["rarity"]!))
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits([MetadataViews.Trait(name: metadata["traitSlot"]!, value: GoatedGoatsTrait.formatFileName(value: metadata["fileName"]!, prefix: metadata["traitSlot"]!), displayType: "String", rarity: MetadataViews.Rarity(score: nil, max: nil, description: metadata["rarity"]!))])
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: GoatedGoatsTrait.CollectionStoragePath, publicPath: GoatedGoatsTrait.CollectionPublicPath, publicCollection: Type<&GoatedGoatsTrait.Collection>(), publicLinkedType: Type<&GoatedGoatsTrait.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-GoatedGoatsTrait.createEmptyCollection(nftType: Type<@GoatedGoatsTrait.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL: MetadataViews.ExternalURL = MetadataViews.ExternalURL("https://GoatedGoats.com")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://goatedgoats.com/_ipx/w_32,q_75/%2FLogo.png?url=%2FLogo.png&w=32&q=75"), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://goatedgoats.com/_ipx/w_32,q_75/%2FLogo.png?url=%2FLogo.png&w=32&q=75"), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/goatedgoats")}
					return MetadataViews.NFTCollectionDisplay(name: "Goated Goats Traits", description: "This is the collection of Traits that can be equipped onto Goated Goats", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://GoatedGoats.com")
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver = getAccount(0xd7081a5c66dc3e7f).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver!, cut: 0.05, description: "This is the royalty receiver for traits")])
				case Type<MetadataViews.Display>():
					var ipfsImage = MetadataViews.IPFSFile(cid: "No thumbnail cid set", path: "No thumbnail pat set")
					if self.getMetadata().containsKey("thumbnailCID"){ 
						ipfsImage = MetadataViews.IPFSFile(cid: self.getMetadata()["thumbnailCID"]!, path: self.getMetadata()["thumbnailPath"])
					}
					return MetadataViews.Display(name: self.getMetadata()["name"] ?? "Goated Goat Trait ".concat(self.id.toString()), description: self.getMetadata()["description"] ?? "No description set", thumbnail: ipfsImage)
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			if GoatedGoatsTrait.idToTraitMetadata[self.id] != nil{ 
				return (GoatedGoatsTrait.idToTraitMetadata[self.id]!).metadata
			} else{ 
				return{} 
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, packID: UInt64){ 
			self.id = id
			self.packID = packID
			emit Mint(id: self.id)
		}
	}
	
	access(all)
	resource interface TraitCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTrait(id: UInt64): &GoatedGoatsTrait.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow GoatedGoatsTrait reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: TraitCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GoatedGoatsTrait.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowTrait(id: UInt64): &GoatedGoatsTrait.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &GoatedGoatsTrait.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let trait = nft as! &GoatedGoatsTrait.NFT
			return trait as &{ViewResolver.Resolver}
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
	
	// -----------------------------------------------------------------------
	// Admin Functions
	// -----------------------------------------------------------------------
	access(account)
	fun setEditionMetadata(editionNumber: UInt64, metadata:{ String: String}){ 
		self.idToTraitMetadata[editionNumber] = TraitMetadata(metadata: metadata)
	}
	
	access(account)
	fun setCollectionMetadata(metadata:{ String: String}){ 
		self.collectionMetadata = metadata
	}
	
	access(account)
	fun mint(nftID: UInt64, packID: UInt64): @{NonFungibleToken.NFT}{ 
		self.totalSupply = self.totalSupply + 1
		return <-create NFT(id: nftID, packID: packID)
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	fun getTotalSupply(): UInt64{ 
		return self.totalSupply
	}
	
	access(all)
	fun getName(): String{ 
		return self.name
	}
	
	access(all)
	fun getCollectionMetadata():{ String: String}{ 
		return self.collectionMetadata
	}
	
	access(all)
	fun getEditionMetadata(_ edition: UInt64):{ String: String}{ 
		if self.idToTraitMetadata[edition] != nil{ 
			return (self.idToTraitMetadata[edition]!).metadata
		} else{ 
			return{} 
		}
	}
	
	access(contract)
	fun formatFileName(value: String, prefix: String): String{ 
		let length = value.length
		let start = prefix.length + 1
		let trimmed = value.slice(from: start, upTo: length - 4)
		return trimmed
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.name = "Goated Goats Traits"
		self.totalSupply = 0
		self.collectionMetadata ={} 
		self.idToTraitMetadata ={} 
		self.CollectionStoragePath = /storage/GoatTraitCollection
		self.CollectionPublicPath = /public/GoatTraitCollection
		emit ContractInitialized()
	}
}
