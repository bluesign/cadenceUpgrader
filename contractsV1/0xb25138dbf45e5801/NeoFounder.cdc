import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NeoMotorcycle from "./NeoMotorcycle.cdc"

import NeoViews from "./NeoViews.cdc"

import NeoSticker from "./NeoSticker.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/// A NFT contract to store founder motorcycle collectibles
access(all)
contract NeoFounder: NonFungibleToken{ 
	
	///Paths to resources and links
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivateSalePath: PrivatePath
	
	/// the total supply of founder nfts
	access(all)
	var totalSupply: UInt64
	
	/// Event that is emitted when contract is initizlized
	access(all)
	event ContractInitialized()
	
	/// Event that is emitted when a NFT is withdrawn
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// Event that is emitted when a NFT is depositeted
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Emitted when a NeoMember is minted for the first time
	access(all)
	event Minted(founderId: UInt64, teamId: UInt64, name: String)
	
	/// Emitted whan a founder joins a new team
	access(all)
	event Team(founderId: UInt64, name: String, address: Address?, teamId: UInt64)
	
	access(all)
	event AchievementAdded(teamId: UInt64, achievement: String)
	
	/// Set when a member sets the image
	access(all)
	event FounderImage(founderId: UInt64, name: String, address: Address?, teamId: UInt64, mediaHash: String, mediaType: String, thumbnailHash: String)
	
	access(all)
	event FounderSticker(founderId: UInt64, name: String, address: Address?, teamId: UInt64, stickerId: UInt64, stickerName: String, stickerDescription: String, stickerThumbnailHash: String)
	
	/// A view of the founder NFT as a standalone struct, only used to generate a read only model of the state
	access(all)
	struct NeoFounderView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let teamId: UInt64
		
		access(all)
		let teamName: String
		
		access(all)
		let description: String
		
		access(all)
		let mediaHash: String
		
		access(all)
		let mediaType: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let stickers: [NeoViews.StickerView]
		
		access(all)
		let achievements: [NeoMotorcycle.Achievement]
		
		access(all)
		let teamAchievements: [NeoMotorcycle.Achievement]
		
		access(all)
		let physicalLink: String?
		
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let royalties: NeoViews.Royalties
		
		init(_ nft: &NFT){ 
			let motorcycle = nft.motorcyclePointer.resolve()!
			self.id = nft.id
			self.teamId = motorcycle.id
			self.teamName = motorcycle.getName()
			self.description = nft.description
			self.mediaHash = nft.getMediaHash()
			self.mediaType = nft.getMediaType()
			self.thumbnailHash = nft.getThumbnailHash()
			self.physicalLink = motorcycle.physicalLink
			self.stickers = nft.getStickerViews()
			self.teamAchievements = motorcycle.getAchievements()
			self.achievements = nft.getAchievements()
			self.metadata = nft.getMetadata()
			self.royalties = motorcycle.getRoyalty()
		}
	}
	
	//An NFT representing a founder bike, has a pointer to an motorcycle
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let motorcyclePointer: NeoMotorcycle.Pointer
		
		access(all)
		let name: String
		
		access(contract)
		var metadata:{ String: String}
		
		access(contract)
		var description: String
		
		access(contract)
		var mediaHash: String?
		
		access(contract)
		var mediaType: String?
		
		access(contract)
		var thumbnailHash: String?
		
		access(self)
		let achievements: [NeoMotorcycle.Achievement]
		
		access(self)
		let stickers: @NeoSticker.Collection
		
		init(id: UInt64, motorcyclePointer: NeoMotorcycle.Pointer, name: String, description: String){ 
			self.id = id
			self.motorcyclePointer = motorcyclePointer
			self.name = name
			self.mediaType = nil
			self.mediaHash = nil
			self.metadata ={} 
			self.description = description
			self.thumbnailHash = nil
			self.stickers <- NeoSticker.createEmptyCollection(nftType: Type<@NeoSticker.Collection>()) as! @NeoSticker.Collection
			self.achievements = []
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.IPFSFile>(), Type<NeoFounderView>(), Type<NeoViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let motorcycle = self.motorcyclePointer.resolve()!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.getThumbnailHash(), path: nil))
				case Type<String>():
					return self.name
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.getThumbnailHash(), path: nil)
				case Type<NeoFounderView>():
					return NeoFounderView(&self as &NFT)
				case Type<NeoViews.Royalties>():
					return (self.motorcyclePointer.resolve()!).getRoyalty()
			}
			return nil
		}
		
		access(all)
		fun getStickerViews(): [NeoViews.StickerView]{ 
			let displays: [NeoViews.StickerView] = []
			for id in self.stickers.getIDs(){ 
				let item = self.stickers.borrowViewResolver(id: id)!
				let display = item.resolveView(Type<NeoViews.StickerView>())! as! NeoViews.StickerView
				displays.append(display)
			}
			return displays
		}
		
		access(all)
		fun getAchievements(): [NeoMotorcycle.Achievement]{ 
			return self.achievements
		}
		
		access(all)
		fun getMediaHash(): String{ 
			//TODO: Add dummy hash
			return self.mediaHash ?? "DUMMY HASH"
		}
		
		access(all)
		fun getMediaType(): String{ 
			return self.mediaType ?? "image"
		}
		
		access(all)
		fun getThumbnailHash(): String{ 
			return self.thumbnailHash ?? self.getMediaHash()
		}
		
		access(all)
		fun setMedia(mediaHash: String, mediaType: String, thumbnailHash: String){ 
			if self.mediaHash != nil{ 
				panic("already set")
			}
			self.mediaHash = mediaHash
			self.mediaType = mediaType
			self.thumbnailHash = thumbnailHash
		}
		
		/*
				pub fun addSticker(_ sticker:@NeoSticker.NFT) {
		
					let motorcycleId=self.motorcyclePointer.resolve()!.id
					emit FounderSticker(founderId: self.id, name:self.name, address: self.owner?.address, teamId: motorcycleId, stickerId: sticker.id, stickerName:sticker.name, stickerDescription:sticker.description, stickerThumbnailHash:sticker.thumbnailHash)
					self.stickers.deposit(token: <-sticker)
				}
				*/
		
		access(all)
		fun addAchievement(_ achievement: NeoMotorcycle.Achievement){ 
			emit AchievementAdded(teamId: self.id, achievement: achievement.name)
			self.achievements.append(achievement)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		//access(account) fun addSticker(id:UInt64, sticker: @NeoSticker.NFT)
		access(account)
		fun addAchievement(id: UInt64, achievement: NeoMotorcycle.Achievement)
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		
		// dictionary of NFT conforming tokens NFT is a resource type with an `UInt64` ID field 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun setMedia(id: UInt64, mediaHash: String, mediaType: String, thumbnailHash: String){ 
			let item = self.borrow(id)
			item.setMedia(mediaHash: mediaHash, mediaType: mediaType, thumbnailHash: thumbnailHash)
			let motorcycleId = (item.motorcyclePointer.resolve()!).id
			emit FounderImage(founderId: id, name: item.name, address: self.owner?.address, teamId: motorcycleId, mediaHash: mediaHash, mediaType: mediaType, thumbnailHash: thumbnailHash)
		}
		
		access(account)
		fun addAchievement(id: UInt64, achievement: NeoMotorcycle.Achievement){ 
			let item = self.borrow(id)
			item.addAchievement(achievement)
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
			let token <- token as! @NeoFounder.NFT
			
			//update the owner of the founder in the motorcycle so that royalty is correct when edition is sold later
			let founderWallet = (self.owner!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			(token.motorcyclePointer.resolve()!).setNeoFounderWallet(founderWallet!)
			let id: UInt64 = token.id
			emit Team(founderId: id, name: token.name, address: self.owner?.address, teamId: (token.motorcyclePointer.resolve()!).id)
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &NFT
			return exampleNFT
		}
		
		access(all)
		fun borrow(_ id: UInt64): &NeoFounder.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &NeoFounder.NFT
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
	/*
			pub fun addSticker(id:UInt64, sticker: @NeoSticker.NFT) {
				let item = self.borrow(id)
				item.addSticker(<- sticker)
			}
			*/
	
	}
	
	access(account)
	fun mint(motorcyclePointer: NeoMotorcycle.Pointer, description: String): @NFT{ 
		NeoFounder.totalSupply = NeoFounder.totalSupply + 1
		let name = "Founder for Neo ".concat((motorcyclePointer.resolve()!).getName())
		var newNFT <- create NFT(id: NeoFounder.totalSupply, motorcyclePointer: motorcyclePointer, name: name, description: description)
		emit Minted(founderId: newNFT.id, teamId: (motorcyclePointer.resolve()!).id, name: name)
		return <-newNFT
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.CollectionPublicPath = /public/neoFounderCollection
		self.CollectionStoragePath = /storage/neoFounderCollection
		self.CollectionPrivateSalePath = /private/neoFounderSaleCollection
		emit ContractInitialized()
	}
}
