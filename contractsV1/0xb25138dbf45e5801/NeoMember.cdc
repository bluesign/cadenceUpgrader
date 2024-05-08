import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NeoMotorcycle from "./NeoMotorcycle.cdc"

import NeoFounder from "./NeoFounder.cdc"

import NeoViews from "./NeoViews.cdc"

import NeoSticker from "./NeoSticker.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/// A NFT contract to store members of a Neo Team
access(all)
contract NeoMember: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Emitted when a NeoMember joins a Team
	access(all)
	event Team(memberId: UInt64, name: String, address: Address?, teamId: UInt64, role: String, edition: UInt64, maxEdition: UInt64)
	
	access(all)
	event AchievementAdded(teamId: UInt64, achievement: String)
	
	/// Emitted when a NeoMember is minted for the first time
	access(all)
	event Minted(memberId: UInt64, teamId: UInt64, role: String, edition: UInt64, maxEdition: UInt64, name: String)
	
	/// Set when a member sets the image
	access(all)
	event MemberImage(memberId: UInt64, name: String, address: Address?, teamId: UInt64, role: String, edition: UInt64, maxEdition: UInt64, mediaHash: String, mediaType: String, thumbnailHash: String)
	
	access(all)
	event MemberSticker(memberId: UInt64, name: String, address: Address?, teamId: UInt64, role: String, edition: UInt64, maxEdition: UInt64, stickerId: UInt64, stickerName: String, stickerDescription: String, stickerThumbnailHash: String)
	
	/// This struct is a view that is generated for the internally stored NeoMember NFT.
	/// Mutable state here does not matter since it is only returned as a view of the data, and it easier to work with this eay
	access(all)
	struct NeoMemberView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let teamId: UInt64
		
		access(all)
		let teamName: String
		
		access(all)
		let name: String
		
		access(all)
		let role: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
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
			self.role = nft.role
			self.name = nft.name
			self.edition = nft.edition
			self.maxEdition = nft.maxEdition
			self.description = nft.description
			self.mediaHash = nft.getMediaHash()
			self.mediaType = nft.getMediaType()
			self.thumbnailHash = nft.getThumbnailHash()
			self.physicalLink = motorcycle.physicalLink
			self.stickers = nft.getStickerViews()
			self.achievements = nft.getAchievements()
			self.teamAchievements = motorcycle.getAchievements()
			self.metadata = nft.getMetadata()
			self.royalties = motorcycle.getRoyalty()
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(account)
		let edition: UInt64
		
		access(account)
		let maxEdition: UInt64
		
		access(account)
		let role: String
		
		access(contract)
		let description: String
		
		access(contract)
		var metadata:{ String: String}
		
		access(contract)
		var mediaHash: String?
		
		access(contract)
		var mediaType: String?
		
		access(contract)
		var thumbnailHash: String?
		
		access(account)
		var name: String
		
		access(self)
		let achievements: [NeoMotorcycle.Achievement]
		
		access(self)
		let stickers: @NeoSticker.Collection
		
		access(contract)
		let motorcyclePointer: NeoMotorcycle.Pointer
		
		init(id: UInt64, edition: UInt64, maxEdition: UInt64, role: String, description: String, motorcyclePointer: NeoMotorcycle.Pointer, name: String){ 
			self.id = id
			self.edition = edition
			self.maxEdition = maxEdition
			self.role = role
			self.description = description
			self.mediaHash = nil
			self.motorcyclePointer = motorcyclePointer
			self.name = name
			self.thumbnailHash = nil
			self.mediaType = nil
			self.achievements = []
			self.metadata ={} 
			self.stickers <- NeoSticker.createEmptyCollection(nftType: Type<@NeoSticker.Collection>()) as! @NeoSticker.Collection
		}
		
		access(all)
		fun getAchievements(): [NeoMotorcycle.Achievement]{ 
			return self.achievements
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
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
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.IPFSFile>(), Type<NeoViews.Royalties>(), Type<NeoMemberView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.getMediaHash(), path: nil))
				case Type<String>():
					return self.name
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.getMediaHash(), path: nil)
				case Type<NeoMemberView>():
					return NeoMemberView(&self as &NeoMember.NFT)
				case Type<NeoViews.Royalties>():
					return (self.motorcyclePointer.resolve()!).getRoyalty()
			}
			return nil
		}
		
		access(all)
		fun getMediaHash(): String{ 
			if self.mediaHash != nil{ 
				return self.mediaHash!
			}
			let dummyHashes ={ "Team Member": "QmeM7CT9aLqakZUy51pBzf59NYe9yW7wS7Wa6rpDpo3aPN", "Pit Crew": "QmRNPLnph6L7XB232DHiSBMvtRthivz6M8cmYreyyUKyjj", "Crew Chief": "QmbpDjruX7dXw3Asy3FzvifwxjQuPcfVMfD5FEYEPtqHjJ", "Race Director": "Qmberb1s1AYafWSoq8JsRw3PydVZx9ffLU6h1gqZHtc9To"}
			return dummyHashes[self.role]!
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
					//TODO:fix event
					emit MemberSticker(memberId: self.id, name:self.name, address: self.owner?.address, teamId: self.getTeamId(), role:self.role, edition:self.edition, maxEdition:self.maxEdition, stickerId: sticker.id, stickerName:sticker.name, stickerDescription:sticker.description, stickerThumbnailHash:sticker.thumbnailHash)
					self.stickers.deposit(token: <-sticker)
				}
				*/
		
		access(all)
		fun addAchievement(_ achievement: NeoMotorcycle.Achievement){ 
			emit AchievementAdded(teamId: self.id, achievement: achievement.name)
			self.achievements.append(achievement)
		}
		
		access(all)
		fun getTeamId(): UInt64{ 
			return (self.motorcyclePointer.resolve()!).id
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	
	//TODO: detach sticker
	}
	
	access(all)
	resource interface CollectionPublic{ 
		//	access(account) fun addSticker(id:UInt64, sticker: @NeoSticker.NFT)
		access(account)
		fun addAchievement(id: UInt64, achievement: NeoMotorcycle.Achievement)
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
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
			let token <- token as! @NFT
			let id: UInt64 = token.id
			let motorcycle = token.motorcyclePointer.resolve()!
			emit Team(memberId: id, name: token.name, address: self.owner?.address, teamId: motorcycle.id, role: token.role, edition: token.edition, maxEdition: token.maxEdition)
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun setMedia(id: UInt64, mediaHash: String, mediaType: String, thumbnailHash: String){ 
			let item = self.borrow(id)
			item.setMedia(mediaHash: mediaHash, mediaType: mediaType, thumbnailHash: thumbnailHash)
			let motorcycleId = (item.motorcyclePointer.resolve()!).id
			emit MemberImage(memberId: id, name: item.name, address: self.owner?.address, teamId: motorcycleId, role: item.role, edition: item.edition, maxEdition: item.maxEdition, mediaHash: mediaHash, mediaType: mediaType, thumbnailHash: thumbnailHash)
		}
		
		/*
				access(account) fun addSticker(id:UInt64, sticker: @NeoSticker.NFT) {
					let item = self.borrow(id)
					item.addSticker(<- sticker)
				}
				*/
		
		access(account)
		fun addAchievement(id: UInt64, achievement: NeoMotorcycle.Achievement){ 
			let item = self.borrow(id)
			item.addAchievement(achievement)
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
			let exampleNFT = nft as! &NeoMember.NFT
			return exampleNFT
		}
		
		access(all)
		fun borrow(_ id: UInt64): &NeoMember.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &NeoMember.NFT
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
	
	//This method can only be called from another contract in the same account. In this case the Admin account
	access(account)
	fun mint(edition: UInt64, maxEdition: UInt64, role: String, description: String, motorcyclePointer: NeoMotorcycle.Pointer): @NFT{ 
		self.totalSupply = self.totalSupply + 1
		let name = role.concat(" for Neo ").concat((motorcyclePointer.resolve()!).getName())
		var newNFT <- create NFT(id: self.totalSupply, edition: edition, maxEdition: maxEdition, role: role, description: description, motorcyclePointer: motorcyclePointer, name: name)
		emit Minted(memberId: self.totalSupply, teamId: (motorcyclePointer.resolve()!).id, role: role, edition: edition, maxEdition: maxEdition, name: name)
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
		self.CollectionPublicPath = /public/neoMemberCollection
		self.CollectionStoragePath = /storage/neoMemberCollection
		emit ContractInitialized()
	}
}
