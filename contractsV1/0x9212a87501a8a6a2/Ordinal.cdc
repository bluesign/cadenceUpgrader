/*
	Ordinal.cdc

	Author: Brian Min brian@flowverse.co
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import OrdinalVendor from "./OrdinalVendor.cdc"

access(all)
contract Ordinal: NonFungibleToken{ 
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event OrdinalMinted(id: UInt64, nftUUID: UInt64, creator: Address, type: String)
	
	access(all)
	event OrdinalUpdated(id: UInt64, size: Int)
	
	access(all)
	event OrdinalDestroyed(id: UInt64)
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Incremented each time a new Ordinal is minted
	access(all)
	var totalSupply: UInt64
	
	// Custom metadata view for Ordinal Inscription Data
	access(all)
	struct InscriptionMetadataView{ 
		access(all)
		let type: String?
		
		access(all)
		let inscriptionData: String?
		
		init(type: String?, inscriptionData: String?){ 
			self.type = type
			self.inscriptionData = inscriptionData
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The inscription number
		access(all)
		let id: UInt64
		
		// The original creator
		access(all)
		let creator: Address
		
		// The type of ordinal (text, domain or image)
		access(all)
		let type: String
		
		// The inscription data
		access(all)
		var data: String
		
		init(creator: Address, type: String, data: String){ 
			self.id = Ordinal.totalSupply
			self.creator = creator
			self.type = type
			self.data = data
			emit OrdinalMinted(id: self.id, nftUUID: self.uuid, creator: self.creator, type: self.type)
		}
		
		access(contract)
		fun updateData(data: String){ 
			assert(self.data.length > 300000, message: "This ordinal inscription cannot be updated as it is less than 300KB")
			assert(self.type == "image", message: "Inscription data can only be updated for image ordinals")
			assert(data.length > 0 && data.length <= 300000, message: "Inscription data must be non-empty and less than 300KB")
			self.data = data
			emit OrdinalUpdated(id: self.id, size: data.length)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let supportedViews = [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Edition>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Rarity>(), Type<InscriptionMetadataView>()]
			return supportedViews
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var data = self.data
			let isOrdinalRestricted = OrdinalVendor.checkOrdinalRestricted(id: self.id)
			if isOrdinalRestricted{ 
				data = "Content restricted due to policy violation"
			}
			switch view{ 
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Ordinal.CollectionStoragePath, publicPath: Ordinal.CollectionPublicPath, publicCollection: Type<&Ordinal.Collection>(), publicLinkedType: Type<&Ordinal.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Ordinal.createEmptyCollection(nftType: Type<@Ordinal.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Ordinals", description: "Ordinals on the Flow blockchain", externalURL: MetadataViews.ExternalURL("https://twitter.com/flowverse_"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://flowverse.myfilebase.com/ipfs/QmQ45TvzGVTmoMCfGqxgbiMmR4rdmSHAhz661bPyUfFrAT"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://flowverse.myfilebase.com/ipfs/QmaTj276rAUFoFiik84xCx1PYZnqZHcGp78vG6xqHLfoXo"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/flowverse_"), "discord": MetadataViews.ExternalURL("https://discord.gg/flowverse"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/flowverseofficial")})
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Ordinal".concat(" #").concat(self.id.toString()), description: "Ordinals on the Flow blockchain", thumbnail: MetadataViews.HTTPFile(url: "https://flowverse.myfilebase.com/ipfs/QmQ45TvzGVTmoMCfGqxgbiMmR4rdmSHAhz661bPyUfFrAT"))
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: getAccount(0xc7c122b5b811de8e).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.01, description: "Platform Royalty Fee")]
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = [MetadataViews.Trait(name: "Inscription Number", value: self.id, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "Type", value: self.type, displayType: nil, rarity: nil), MetadataViews.Trait(name: "Size", value: self.data.length, displayType: "Number", rarity: nil), MetadataViews.Trait(name: "Creator", value: self.creator.toString(), displayType: nil, rarity: nil), MetadataViews.Trait(name: "UUID", value: self.uuid.toString(), displayType: nil, rarity: nil)]
					return MetadataViews.Traits(traits)
				case Type<InscriptionMetadataView>():
					return InscriptionMetadataView(type: self.type, inscriptionData: data)
				case Type<MetadataViews.Rarity>():
					var description = ""
					if self.id <= 100{ 
						description = "Sub 100"
					} else if self.id <= 1000{ 
						description = "Sub 1K"
					} else if self.id <= 5000{ 
						description = "Sub 5K"
					} else if self.id <= 10000{ 
						description = "Sub 10K"
					} else if self.id <= 25000{ 
						description = "Sub 25K"
					} else if self.id <= 50000{ 
						description = "Sub 50K"
					} else{ 
						description = "Sub 100K"
					}
					return MetadataViews.Rarity(score: nil, max: nil, description: description)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://nft.flowverse.co/ordinals/".concat(self.id.toString()))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(self)
	fun mint(creator: Address, type: String, data: String): @NFT{ 
		pre{ 
			type == "image" || type == "text" || type == "domain":
				"Invalid type (must be either image, text or domain)"
			data.length > 0:
				"Invalid data (must be non-empty)"
		}
		if type == "domain"{ 
			assert(OrdinalVendor.checkDomainAvailability(domain: data), message: "domain already exists")
		}
		
		// Increment the inscription number
		Ordinal.totalSupply = Ordinal.totalSupply + UInt64(1)
		
		// Mint the new NFT
		let nft: @NFT <- create NFT(creator: creator, type: type, data: data)
		return <-nft
	}
	
	access(all)
	resource Minter: OrdinalVendor.IMinter{ 
		init(){} 
		
		access(all)
		fun mint(creator: Address, type: String, data: String): @NFT{ 
			return <-Ordinal.mint(creator: creator, type: type, data: data)
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun createMinter(): @Minter{ 
			return <-create Minter()
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface CollectionUpdate{ 
		access(all)
		fun updateData(id: UInt64, data: String)
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
		fun borrowOrdinalNFT(id: UInt64): &Ordinal.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Ordinal reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: CollectionPublic, CollectionUpdate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let nft <- token as! @NFT
			emit Withdraw(id: withdrawID, from: self.owner?.address)
			return <-nft
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Ordinal.NFT
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
		fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			}
			return nil
		}
		
		access(all)
		fun borrowOrdinalNFT(id: UInt64): &Ordinal.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Ordinal.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &Ordinal.NFT
			return nftRef as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun updateData(id: UInt64, data: String){ 
			let nft = self.borrowOrdinalNFT(id: id)!
			nft.updateData(data: data)
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
	// Ordinal contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Ordinal.Collection()
	}
	
	// -----------------------------------------------------------------------
	// Ordinal initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.CollectionStoragePath = /storage/OrdinalCollection
		self.CollectionPublicPath = /public/OrdinalCollection
		self.AdminStoragePath = /storage/OrdinalAdmin
		
		// Initialize contract fields
		self.totalSupply = 0
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create and store Admin resource
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
