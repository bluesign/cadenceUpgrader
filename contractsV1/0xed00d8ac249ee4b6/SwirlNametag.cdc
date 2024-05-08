import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SwirlNametag: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(self)
	let profiles:{ UInt64: Profile}
	
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
	let ProviderPrivatePath: PrivatePath
	
	access(all)
	struct SocialHandle{ 
		access(all)
		let channel: String
		
		access(all)
		let handle: String
		
		init(channel: String, handle: String){ 
			self.channel = channel
			self.handle = handle
		}
	}
	
	access(all)
	struct Profile{ 
		access(all)
		let nickname: String
		
		access(all)
		let profileImage: String
		
		access(all)
		let keywords: [String]
		
		access(all)
		let color: String
		
		access(all)
		let socialHandles: [SocialHandle]
		
		init(nickname: String, profileImage: String, keywords: [String], color: String, socialHandles: [SocialHandle]){ 
			self.nickname = nickname
			self.profileImage = profileImage
			self.keywords = keywords
			self.color = color
			self.socialHandles = socialHandles
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views: [Type] = [Type<Profile>(), Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
			return views
		}
		
		access(all)
		fun name(): String{ 
			return "Swirl Nametag: ".concat(self.profile().nickname)
		}
		
		access(all)
		fun profile(): Profile{ 
			return SwirlNametag.getProfile(self.id)
		}
		
		access(all)
		fun profileImageUrl(): String{ 
			let profile = self.profile()
			var url = "https://swirl.deno.dev/dnft/nametag.svg?"
			url = url.concat("nickname=").concat(profile.nickname)
			url = url.concat("&profile_img=").concat(String.encodeHex(profile.profileImage.utf8))
			url = url.concat("&color=").concat(String.encodeHex(profile.color.utf8))
			return url
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<Profile>():
					return self.profile()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.", thumbnail: MetadataViews.HTTPFile(url: self.profileImageUrl()))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SwirlNametag.CollectionStoragePath, publicPath: SwirlNametag.CollectionPublicPath, publicCollection: Type<&SwirlNametag.Collection>(), publicLinkedType: Type<&SwirlNametag.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SwirlNametag.createEmptyCollection(nftType: Type<@SwirlNametag.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.profileImageUrl()), mediaType: "image/svg+xml")
					let socials:{ String: MetadataViews.ExternalURL} ={} 
					for handle in self.profile().socialHandles{ 
						socials[handle.channel] = MetadataViews.ExternalURL(handle.handle)
					}
					return MetadataViews.NFTCollectionDisplay(name: "Swirl Nametag", description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.", externalURL: MetadataViews.ExternalURL("https://hyphen.at/"), squareImage: media, bannerImage: media, socials: socials)
				case Type<MetadataViews.Traits>():
					let profile = self.profile()
					let traits:{ String: AnyStruct} ={} 
					traits["nickname"] = profile.nickname
					traits["keywords"] = profile.keywords
					traits["color"] = profile.color
					for handle in profile.socialHandles{ 
						traits[handle.channel] = handle.handle
					}
					let traitsView = MetadataViews.dictToTraits(dict: traits, excludedNames: [])
					return traitsView
				default:
					return nil
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SwirlNametagCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSwirlNametag(id: UInt64): &SwirlNametag.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SwirlNametag reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: SwirlNametagCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			panic("soulbound; SBT is not transferable")
		}
		
		// deposit takes an NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SwirlNametag.NFT
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
		fun borrowSwirlNametag(id: UInt64): &SwirlNametag.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &SwirlNametag.NFT
			}
			return nil
		}
		
		access(all)
		fun updateSwirlNametag(profile: Profile){ 
			let tokenIDs = self.getIDs()
			if tokenIDs.length == 0{ 
				panic("no nametags")
			}
			SwirlNametag.setProfile(tokenID: tokenIDs[0], profile: profile)
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let SwirlNametagNFT = nft as! &SwirlNametag.NFT
			return SwirlNametagNFT as &{ViewResolver.Resolver}
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
	fun getProfile(_ tokenID: UInt64): Profile{ 
		return self.profiles[tokenID] ?? panic("no profile for token ID")
	}
	
	access(contract)
	fun setProfile(tokenID: UInt64, profile: Profile){ 
		self.profiles[tokenID] = profile
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, profile: Profile){ 
		// create a new NFT
		var newNFT <- create NFT(id: SwirlNametag.totalSupply + 1)
		SwirlNametag.setProfile(tokenID: newNFT.id, profile: profile)
		recipient.deposit(token: <-newNFT)
		SwirlNametag.totalSupply = SwirlNametag.totalSupply + 1
	}
	
	init(){ 
		self.totalSupply = 0
		self.profiles ={} 
		self.CollectionStoragePath = /storage/SwirlNametagCollection
		self.CollectionPublicPath = /public/SwirlNametagCollection
		self.ProviderPrivatePath = /private/SwirlNFTCollectionProvider
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SwirlNametag.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
