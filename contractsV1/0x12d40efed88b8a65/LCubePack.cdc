import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LCubeComponent from "./LCubeComponent.cdc"

import LCubeExtension from "./LCubeExtension.cdc"

//Wow! You are viewing LimitlessCube Pack contract.
access(all)
contract LCubePack: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event GameCreated(gameID: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event PackCreated(creatorAddress: Address, gameID: UInt64, id: UInt64, metadata:{ String: String})
	
	access(all)
	event PackOpened(id: UInt64, accountAddress: Address?, items: [UInt64])
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	fun createGameMinter(creator: Address, metadata:{ String: String}): @PackMinter{ 
		assert(metadata.containsKey("gameName"), message: "gameName property is required for LCubePack!")
		assert(metadata.containsKey("thumbnail"), message: "thumbnail property is required for LCubePack!")
		var gameName = LCubeExtension.clearSpaceLetter(text: metadata["gameName"]!)
		assert(gameName.length > 2, message: "gameName property is not empty or minimum 3 characters!")
		let storagePath = "Game_".concat(gameName)
		let candidate <- self.account.storage.load<@Game>(from: StoragePath(identifier: storagePath)!)
		if candidate != nil{ 
			panic(gameName.concat(" Game already created before!"))
		}
		destroy candidate
		var newGame <- create Game(creatorAddress: creator, metadata: metadata)
		var gameID: UInt64 = newGame.uuid
		emit GameCreated(gameID: gameID, creator: creator, metadata: metadata)
		self.account.storage.save(<-newGame, to: StoragePath(identifier: storagePath)!)
		return <-create PackMinter(gameID: gameID)
	}
	
	access(all)
	resource Game{ 
		access(all)
		let creatorAddress: Address
		
		access(all)
		let metadata:{ String: String}
		
		init(creatorAddress: Address, metadata:{ String: String}){ 
			self.creatorAddress = creatorAddress
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let gameID: UInt64
		
		access(all)
		let startOfUse: UFix64
		
		access(all)
		let itemCount: UInt8
		
		access(all)
		let metadata:{ String: String}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(creatorAddress: Address, gameID: UInt64, startOfUse: UFix64, metadata:{ String: String}, royalties: [MetadataViews.Royalty], itemCount: UInt8){ 
			LCubePack.totalSupply = LCubePack.totalSupply + 1
			self.id = LCubePack.totalSupply
			self.creatorAddress = creatorAddress
			self.gameID = gameID
			self.startOfUse = startOfUse
			self.metadata = metadata
			self.royalties = royalties
			self.itemCount = itemCount
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"] ?? ""))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "LimitlessCube Pack Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://limitlesscube.com/flow/pack/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: LCubePack.CollectionStoragePath, publicPath: LCubePack.CollectionPublicPath, publicCollection: Type<&LCubePack.Collection>(), publicLinkedType: Type<&LCubePack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-LCubePack.createEmptyCollection(nftType: Type<@LCubePack.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://limitlesscube.com/images/logo.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The LimitlessCube Pack Collection", description: "This collection is used as an LimitlessCube to help you develop your next Flow NFT.", externalURL: MetadataViews.ExternalURL("https://limitlesscube.com/flow/MetadataViews"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/limitlesscube")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits = ["name", "description", "thumbnail", "image", "nftType"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getRoyalties(): [MetadataViews.Royalty]{ 
			return self.royalties
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface LCubePackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowLCubePack(id: UInt64): &LCubePack.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow LimitlessCube reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: LCubePackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let nft = (&self.ownedNFTs[withdrawID] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &LCubePack.NFT
			if packNFT.startOfUse > getCurrentBlock().timestamp{ 
				panic("Cannot withdraw: Pack is locked")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing Pack")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @LCubePack.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun openPack(id: UInt64, receiverAccount: AuthAccount){ 
			let recipient = getAccount(receiverAccount.address)
			let recipientCap = recipient.capabilities.get<&{LCubeComponent.LCubeComponentCollectionPublic}>(LCubeComponent.CollectionPublicPath)
			let _auth = recipientCap.borrow()!
			let pack <- self.withdraw(withdrawID: id) as! @LCubePack.NFT
			let minter = LCubePack.getComponentMinter().borrow() ?? panic("Could not borrow receiver capability (maybe receiver not configured?)")
			let collectionRef = receiverAccount.borrow<&LCubeComponent.Collection>(from: LCubeComponent.CollectionStoragePath) ?? panic("Could not borrow a reference to the owner's collection")
			let depositRef = recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(LCubeComponent.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
			let beneficiaryCapability = recipient.capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())
			if !beneficiaryCapability.check(){ 
				panic("Beneficiary capability is not valid!")
			}
			var royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: beneficiaryCapability!, cut: 0.05, description: "LimitlessCubePack Royalty")]
			let componentMetadata = pack.getMetadata()
			componentMetadata.insert(key: "gameID", pack.gameID.toString())
			componentMetadata.insert(key: "creatorAddress", receiverAccount.address.toString())
			let components <- minter.batchCreateComponents(gameID: pack.gameID, metadata: pack.getMetadata(), royalties: royalties, quantity: pack.itemCount)
			let keys = components.getIDs()
			for key in keys{ 
				depositRef.deposit(token: <-components.withdraw(withdrawID: key))
			}
			destroy components
			emit PackOpened(id: pack.id, accountAddress: receiverAccount.address, items: keys)
			destroy pack
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &LCubePack.NFT
			return packNFT
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &LCubePack.NFT
			return packNFT.getMetadata()
		}
		
		access(all)
		fun borrowLCubePack(id: UInt64): &LCubePack.NFT?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &LCubePack.NFT
			return packNFT
		}
		
		access(all)
		fun getRoyalties(id: UInt64): [MetadataViews.Royalty]{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &LCubePack.NFT
			return packNFT.getRoyalties()
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
	fun getPacks(address: Address): [UInt64]?{ 
		let account = getAccount(address)
		if let packCollection = account.capabilities.get<&{LCubePack.LCubePackCollectionPublic}>(self.CollectionPublicPath).borrow<&{LCubePack.LCubePackCollectionPublic}>(){ 
			return packCollection.getIDs()
		}
		return nil
	}
	
	access(all)
	fun minter(): Capability<&PackMinter>{ 
		return self.account.capabilities.get<&PackMinter>(self.MinterPublicPath)!
	}
	
	access(self)
	fun getComponentMinter(): Capability<&LCubeComponent.ComponentMinter>{ 
		return self.account.capabilities.get<&LCubeComponent.ComponentMinter>(/public/LCubeComponentMinter)!
	}
	
	access(all)
	resource PackMinter{ 
		access(self)
		let gameID: UInt64
		
		init(gameID: UInt64){ 
			self.gameID = gameID
		}
		
		access(self)
		fun createPack(creatorAddress: Address, startOfUse: UFix64, metadata:{ String: String}, royalties: [MetadataViews.Royalty], itemCount: UInt8): @LCubePack.NFT{ 
			var newPack <- create NFT(creatorAddress: creatorAddress, gameID: self.gameID, startOfUse: startOfUse, metadata: metadata, royalties: royalties, itemCount: itemCount)
			emit PackCreated(creatorAddress: creatorAddress, gameID: self.gameID, id: newPack.id, metadata: metadata)
			return <-newPack
		}
		
		access(all)
		fun batchCreatePacks(creator: Capability<&{NonFungibleToken.Receiver}>, startOfUse: UFix64, metadata:{ String: String}, royalties: [MetadataViews.Royalty], itemCount: UInt8, quantity: UInt8): @Collection{ 
			assert(metadata.containsKey("name"), message: "name property is required for LCubePack!")
			assert(metadata.containsKey("description"), message: "description property is required for LCubePack!")
			assert(metadata.containsKey("image"), message: "image property is required for LCubePack!")
			let packCollection <- create Collection()
			var i: UInt8 = 0
			while i < quantity{ 
				packCollection.deposit(token: <-self.createPack(creatorAddress: creator.address, startOfUse: startOfUse, metadata: metadata, royalties: royalties, itemCount: itemCount))
				i = i + 1
			}
			return <-packCollection
		}
	}
	
	init(){ 
		self.CollectionPublicPath = /public/LCubePackCollection
		self.CollectionStoragePath = /storage/LCubePackCollection
		self.MinterPublicPath = /public/LCubePackMinter
		self.MinterStoragePath = /storage/LCubePackMinter
		self.totalSupply = 0
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&LCubePack.Collection>(LCubePack.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: LCubePack.CollectionPublicPath)
		emit ContractInitialized()
	}
}
