import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MIKOSEANFT: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ItemCreated(id: UInt64, metadata:{ String: String}, itemSupply: UInt64)
	
	access(all)
	event UpdateItemMetadata(id: UInt64, metadata:{ String: String}, itemSupply: UInt64)
	
	access(all)
	event ItemDeleted(itemId: UInt64)
	
	access(all)
	event ProjectCreated(projectId: UInt64, name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64)
	
	access(all)
	event ProjectUpdated(projectId: UInt64, name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64)
	
	access(all)
	event ItemAddedToProject(projectId: UInt64, itemId: UInt64)
	
	access(all)
	event ItemLock(projectId: UInt64, itemId: UInt64, numberOfNFTs: UInt64)
	
	access(all)
	event ProjectLocked(projectId: UInt64)
	
	access(all)
	event Minted(id: UInt64, projectId: UInt64, itemId: UInt64, tx_uiid: String, mintNumber: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event NFTTransferred(nftID: UInt64, nftData: NFTData, from: Address, to: Address)
	
	// Path
	access(all)
	var CollectionPublicPath: PublicPath
	
	access(all)
	var CollectionStoragePath: StoragePath
	
	access(all)
	var MikoSeaAdmin: StoragePath
	
	// Entity Counts
	access(all)
	var nextItemId: UInt64
	
	access(all)
	var nextProjectId: UInt64
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextCommentId: UInt64
	
	// Dictionaries
	access(all)
	var itemData:{ UInt64: Item}
	
	access(all)
	var projectsData:{ UInt64: ProjectData}
	
	access(all)
	var projects: @{UInt64: Project}
	
	access(all)
	var commentData:{ UInt64: Comment}
	
	//------------------------------------------------------------
	// Comment Struct
	//------------------------------------------------------------
	access(all)
	struct Comment{ 
		access(all)
		var commentId: UInt64
		
		access(all)
		var projectId: UInt64
		
		access(all)
		var itemId: UInt64
		
		access(all)
		var userAddress: Address
		
		access(all)
		var nftId: UInt64
		
		access(all)
		var comment: String
		
		init(projectId: UInt64, itemId: UInt64, userAddress: Address, nftId: UInt64, comment: String){ 
			pre{ 
				comment.length != 0:
					"Comment can not be empty"
			}
			self.commentId = MIKOSEANFT.nextCommentId
			self.projectId = projectId
			self.itemId = itemId
			self.userAddress = userAddress
			self.nftId = nftId
			self.comment = comment
			MIKOSEANFT.nextCommentId = MIKOSEANFT.nextCommentId + 1
		}
	}
	
	//------------------------------------------------------------
	// Item Struct hold Metadata associated with NFT
	//------------------------------------------------------------
	access(all)
	struct Item{ 
		access(all)
		let itemId: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		var itemSupply: UInt64
		
		init(metadata:{ String: String}, itemSupply: UInt64){ 
			pre{ 
				metadata.length != 0:
					"New Item metadata cannot be empty"
			}
			self.itemId = MIKOSEANFT.nextItemId
			self.metadata = metadata
			self.itemSupply = itemSupply
			MIKOSEANFT.nextItemId = MIKOSEANFT.nextItemId + 1
			emit ItemCreated(id: self.itemId, metadata: metadata, itemSupply: itemSupply)
		}
	}
	
	//------------------------------------------------------------
	// Project
	//------------------------------------------------------------
	access(all)
	struct ProjectData{ 
		access(all)
		let projectId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let creatorFee: UFix64
		
		access(all)
		let platformFee: UFix64
		
		init(name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64){ 
			pre{ 
				name.length > 0:
					"New Project name cannot be empty"
				description.length > 0:
					"New Project description cannot be empty"
				creatorAddress != nil:
					"Creator address cannot be nil"
				creatorFee != nil:
					"Creator fee cannot be empty"
				platformFee > 0.0:
					"Platform fee is > 0"
			}
			self.projectId = MIKOSEANFT.nextProjectId
			self.name = name
			self.description = description
			self.creatorAddress = creatorAddress
			self.creatorFee = creatorFee
			self.platformFee = platformFee
			MIKOSEANFT.nextProjectId = MIKOSEANFT.nextProjectId + 1
			emit ProjectCreated(projectId: self.projectId, name: self.name, description: self.description, creatorAddress: self.creatorAddress, creatorFee: self.creatorFee, platformFee: self.platformFee, mintPrice: mintPrice)
		}
	}
	
	access(all)
	resource Project{ 
		access(all)
		let projectId: UInt64
		
		access(all)
		var items: [UInt64]
		
		access(all)
		var lockItems:{ UInt64: Bool}
		
		access(all)
		var locked: Bool
		
		access(all)
		var numberMintedPerItem:{ UInt64: UInt64}
		
		init(name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64){ 
			self.projectId = MIKOSEANFT.nextProjectId
			self.lockItems ={} 
			self.locked = false
			self.items = []
			self.numberMintedPerItem ={} 
			MIKOSEANFT.projectsData[self.projectId] = ProjectData(name: name, description: description, creatorAddress: creatorAddress, creatorFee: creatorFee, platformFee: platformFee, mintPrice: mintPrice)
		}
		
		access(all)
		fun addItem(id: UInt64){ 
			pre{ 
				self.numberMintedPerItem[id] == nil:
					"The item is already to project"
				!self.locked:
					"cannot add item to project, after project is lock"
				MIKOSEANFT.itemData[id] != nil:
					"cannot add item to project, item doesn't exist"
			}
			self.items.append(id)
			self.lockItems[id] = false
			self.numberMintedPerItem[id] = 0
			emit ItemAddedToProject(projectId: self.projectId, itemId: id)
		}
		
		access(all)
		fun addItems(ids: [UInt64]){ 
			for i in ids{ 
				self.addItem(id: i)
			}
		}
		
		access(all)
		fun lockItem(id: UInt64){ 
			pre{ 
				self.lockItems[id] != nil:
					"Cannot lock the item: Item doesn't exist in this project!"
			}
			if !self.lockItems[id]!{ 
				self.lockItems[id] = true
				emit ItemLock(projectId: self.projectId, itemId: id, numberOfNFTs: self.numberMintedPerItem[id]!)
			}
		}
		
		access(all)
		fun lockAllItems(){ 
			for item in self.items{ 
				self.lockItem(id: item)
			}
		}
		
		access(all)
		fun projectLock(){ 
			if !self.locked{ 
				self.locked = true
				emit ProjectLocked(projectId: self.projectId)
			}
		}
		
		access(contract)
		fun mintNFT(itemId: UInt64, tx_uiid: String): @NFT{ 
			pre{ 
				self.lockItems[itemId] != nil:
					"cannot mint the nft, this item does't not exist in project"
				!self.lockItems[itemId]!:
					"Cannot mint the nft from this item, item has been lock"
			}
			let numInItems = self.numberMintedPerItem[itemId]!
			let itemSupply = MIKOSEANFT.getItemSupply(itemId: itemId) ?? 0
			if numInItems >= itemSupply{ 
				panic("This item is sold out!")
			}
			let newNFT: @NFT <- create NFT(projectId: self.projectId, itemId: itemId, tx_uiid: tx_uiid, mintNumber: numInItems + 1)
			self.numberMintedPerItem[itemId] = numInItems + 1
			return <-newNFT
		}
		
		// todo: access(contract)
		access(contract)
		fun batchMintNFT(itemId: UInt64, quantity: UInt64, tx_uiid: String): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintNFT(itemId: itemId, tx_uiid: tx_uiid))
				i = i + 1
			}
			return <-newCollection
		}
	}
	
	//------------------------------------------------------------
	// NFT
	//------------------------------------------------------------
	access(all)
	struct NFTData{ 
		access(all)
		let projectId: UInt64
		
		access(all)
		let itemId: UInt64
		
		// mintNumber is serial number
		access(all)
		let mintNumber: UInt64
		
		init(projectId: UInt64, itemId: UInt64, mintNumber: UInt64){ 
			self.projectId = projectId
			self.itemId = itemId
			self.mintNumber = mintNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let tx_uiid: String
		
		access(all)
		var data: NFTData
		
		init(projectId: UInt64, itemId: UInt64, tx_uiid: String, mintNumber: UInt64){ 
			MIKOSEANFT.totalSupply = MIKOSEANFT.totalSupply + 1
			self.id = MIKOSEANFT.totalSupply
			self.tx_uiid = tx_uiid
			self.data = NFTData(projectId: projectId, itemId: itemId, mintNumber: mintNumber)
			emit Minted(id: self.id, projectId: self.data.projectId, itemId: self.data.itemId, tx_uiid: self.tx_uiid, mintNumber: self.data.mintNumber)
		}
		
		access(all)
		fun getImage(): String{ 
			let defaultValue = "https://mikosea.s3.ap-northeast-1.amazonaws.com/mikosea-project/mikoseanft_200.png"
			return MIKOSEANFT.getItemMetaDataByField(itemId: self.data.itemId, field: "image") ?? MIKOSEANFT.getItemMetaDataByField(itemId: self.data.itemId, field: "imageURL") ?? defaultValue
		}
		
		access(all)
		fun getTitle(): String{ 
			let defaultValue = MIKOSEANFT.getProjectName(projectId: self.data.projectId) ?? "MikoSea 1st Membership NFT"
			let totalSupply = MIKOSEANFT.getProjectTotalSupply(self.data.projectId)
			return defaultValue.concat(" #").concat(self.data.mintNumber.toString())
		}
		
		access(all)
		fun getDescription(): String{ 
			let defaultValue = "MikoSea 1st Membership NFT \u{306f}MikoSea\u{3067}\u{6700}\u{521d}\u{306b}\u{767a}\u{884c}\u{3055}\u{308c}\u{308b}NFT\u{306b}\u{306a}\u{308a}\u{307e}\u{3059}\u{3002}\u{540c}\u{3058}\u{4fa1}\u{5024}\u{89b3}\u{30fb}\u{611f}\u{6027}\u{3092}\u{3082}\u{3063}\u{305f}\u{4ef2}\u{9593}\u{3068}\u{5171}\u{540c}\u{610f}\u{8b58}\u{3092}\u{6301}\u{3061}\u{306a}\u{304c}\u{3089}\u{5922}\u{3092}\u{5b9f}\u{73fe}\u{3055}\u{305b}\u{308b}\u{624b}\u{6bb5}\u{3068}\u{3057}\u{3066}\u{767a}\u{884c}\u{3057}\u{307e}\u{3059}\u{3002}"
			return MIKOSEANFT.getProjectDescription(projectId: self.data.projectId) ?? defaultValue
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getTitle(), description: self.getDescription(), thumbnail: MetadataViews.HTTPFile(url: self.getImage()))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.data.mintNumber)
				case Type<MetadataViews.Royalties>():
					let projectId = self.data.projectId
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0x0b80e42aaab305f0).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: MIKOSEANFT.getProjectPlatformFee(projectId: projectId) ?? 0.05, description: "Platform fee"), MetadataViews.Royalty(receiver: getAccount(MIKOSEANFT.getProjectCreatorAddress(projectId: projectId)!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: MIKOSEANFT.getProjectCreatorFee(projectId: projectId) ?? 0.1, description: "Creater fee")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://mikosea.io/fund/project/".concat(self.data.projectId.toString()).concat("/").concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MIKOSEANFT.CollectionStoragePath, publicPath: MIKOSEANFT.CollectionPublicPath, publicCollection: Type<&MIKOSEANFT.Collection>(), publicLinkedType: Type<&MIKOSEANFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MIKOSEANFT.createEmptyCollection(nftType: Type<@MIKOSEANFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/studio-design-asset-files/projects/1pqD36e6Oj/s-300x50_aa59a692-741b-408b-aea3-bcd25d29c6bd.svg"), mediaType: "image/svg+xml")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://mikosea.io/mikosea_1.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "MikoSea", description: "\u{3042}\u{3089}\u{3086}\u{308b}\u{4e8b}\u{696d}\u{8005}\u{306e}\u{601d}\u{3044}\u{3092}\u{8f09}\u{305b}\u{3066}\u{795e}\u{8f3f}\u{3092}\u{62c5}\u{3050}\u{3002}NFT\u{578b}\u{30af}\u{30e9}\u{30a6}\u{30c9}\u{30d5}\u{30a1}\u{30f3}\u{30c7}\u{30a3}\u{30f3}\u{30b0}\u{30de}\u{30fc}\u{30b1}\u{30c3}\u{30c8}\u{300c}MikoSea\u{300d}", externalURL: MetadataViews.ExternalURL("https://mikosea.io/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/MikoSea_io")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["payment_uuid", "fileExt", "fileType"]
					let traitsView = MetadataViews.dictToTraits(dict: MIKOSEANFT.getItemMetaData(itemId: self.data.itemId) ??{} , excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun createItem(metadata:{ String: String}, itemSupply: UInt64): UInt64{ 
			var newItem = Item(metadata: metadata, itemSupply: itemSupply)
			let id = newItem.itemId
			MIKOSEANFT.itemData[id] = newItem
			return id
		}
		
		access(all)
		fun createItems(items: [{String: String}], projectId: UInt64, itemSupply: UInt64){ 
			var itemIds: [UInt64] = []
			for metadata in items{ 
				var Id = self.createItem(metadata: metadata, itemSupply: itemSupply)
				itemIds.append(Id)
			}
			self.borrowProject(projectId: projectId).addItems(ids: itemIds)
		}
		
		access(all)
		fun updateItemMetadata(itemId: UInt64, newData:{ String: String}, itemSupply: UInt64){ 
			let latestItemId = MIKOSEANFT.nextItemId
			MIKOSEANFT.nextItemId = itemId
			MIKOSEANFT.itemData[itemId] = Item(metadata: newData, itemSupply: itemSupply)
			MIKOSEANFT.nextItemId = latestItemId
			emit UpdateItemMetadata(id: itemId, metadata: newData, itemSupply: itemSupply)
		}
		
		access(all)
		fun createProject(name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64){ 
			var newProject <- create Project(name: name, description: description, creatorAddress: creatorAddress, creatorFee: creatorFee, platformFee: platformFee, mintPrice: mintPrice)
			MIKOSEANFT.projects[newProject.projectId] <-! newProject
		}
		
		access(all)
		fun borrowProject(projectId: UInt64): &Project{ 
			pre{ 
				MIKOSEANFT.projects[projectId] != nil:
					"Cannot borrow Project: The Project doesn't exist"
			}
			return (&MIKOSEANFT.projects[projectId] as &Project?)!
		}
		
		access(all)
		fun deleteItem(id: UInt64){ 
			pre{ 
				MIKOSEANFT.itemData[id] != nil:
					"Could not delete Item, Item does not exist"
			}
			MIKOSEANFT.itemData.remove(key: id)
			emit ItemDeleted(itemId: id)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(all)
		fun updateProject(projectId: UInt64, name: String, description: String, creatorAddress: Address, creatorFee: UFix64, platformFee: UFix64, mintPrice: UFix64){ 
			if MIKOSEANFT.projectsData[projectId] == nil{ 
				panic("not found project")
			}
			let oldLatestProjectId = MIKOSEANFT.nextProjectId
			MIKOSEANFT.nextProjectId = projectId
			MIKOSEANFT.projectsData[projectId] = ProjectData(name: name, description: description, creatorAddress: creatorAddress, creatorFee: creatorFee, platformFee: platformFee, mintPrice: mintPrice)
			MIKOSEANFT.nextProjectId = oldLatestProjectId
			emit ProjectUpdated(projectId: projectId, name: name, description: description, creatorAddress: creatorAddress, creatorFee: creatorFee, platformFee: platformFee, mintPrice: mintPrice)
		}
		
		access(all)
		fun batchPurchaseNFT(projectId: UInt64, itemId: UInt64, quantity: UInt64, tx_uiid: String): @Collection{ 
			let project = &MIKOSEANFT.projects[projectId] as &Project? ?? panic("project not found")
			let numInItems = project.numberMintedPerItem[itemId] ?? 0
			let itemSupply = MIKOSEANFT.getItemSupply(itemId: itemId) ?? 0
			if numInItems >= itemSupply{ 
				panic("This item is sold out!")
			}
			return <-project.batchMintNFT(itemId: itemId, quantity: quantity, tx_uiid: tx_uiid)
		}
	}
	
	//------------------------------------------------------------
	// Collection Resource
	//------------------------------------------------------------
	access(all)
	resource interface MikoSeaCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun destroyNFT(id: UInt64)
		
		access(all)
		fun borrowMiKoSeaNFT(id: UInt64): &MIKOSEANFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MiKoSeaAsset reference: The Id of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MikoSeaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing nft")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MIKOSEANFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
			
			// remove old comment
			MIKOSEANFT.removeAllCommentByNftId(id)
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Cannot borrow NFT, no such id"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mikoseaNFT = nft as! &MIKOSEANFT.NFT
			return mikoseaNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowMiKoSeaNFT(id: UInt64): &MIKOSEANFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MIKOSEANFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowNFTSafe(id: UInt64): &MIKOSEANFT.NFT?{ 
			return self.borrowMiKoSeaNFT(id: id)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun destroyNFT(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
			destroy token
			emit Destroyed(id: id)
		}
		
		access(all)
		fun transfer(nftID: UInt64, recipient: &{MIKOSEANFT.MikoSeaCollectionPublic}){ 
			post{ 
				self.ownedNFTs[nftID] == nil:
					"The specified NFT was not transferred"
			}
			let nft <- self.withdraw(withdrawID: nftID)
			recipient.deposit(token: <-nft)
			let nftRes = recipient.borrowMiKoSeaNFT(id: nftID)!
			emit NFTTransferred(nftID: nftID, nftData: *nftRes.data, from: (self.owner!).address, to: (recipient.owner!).address)
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
	
	//------------------------------------------------------------
	// Public function
	//------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun checkCollection(_ address: Address): Bool{ 
		return getAccount(address).capabilities.get<&{MIKOSEANFT.MikoSeaCollectionPublic}>(MIKOSEANFT.CollectionPublicPath).check()
	}
	
	//------------------------------------------------------------
	// Comment Public function
	//------------------------------------------------------------
	access(all)
	fun createComment(projectId: UInt64, itemId: UInt64, userAddress: Address, nftId: UInt64, comment: String): UInt64{ 
		var newComment = Comment(projectId: projectId, itemId: itemId, userAddress: userAddress, nftId: nftId, comment: comment)
		var newId = newComment.commentId
		MIKOSEANFT.commentData[newId] = newComment
		return newId
	}
	
	access(all)
	fun deleteComment(commentId: UInt64){ 
		MIKOSEANFT.commentData.remove(key: commentId)
	}
	
	access(all)
	fun editComment(commentId: UInt64, projectId: UInt64, itemId: UInt64, userAddress: Address, nftId: UInt64, newComment: String): UInt64{ 
		MIKOSEANFT.commentData[commentId] = Comment(projectId: projectId, itemId: itemId, userAddress: userAddress, nftId: nftId, comment: newComment)
		return commentId
	}
	
	access(all)
	fun getCommentById(id: UInt64): String?{ 
		return MIKOSEANFT.commentData[id]?.comment
	}
	
	access(all)
	fun getCommentAddressById(id: UInt64): Address?{ 
		return MIKOSEANFT.commentData[id]?.userAddress
	}
	
	access(all)
	fun getCommentProjectIdById(id: UInt64): UInt64?{ 
		return MIKOSEANFT.commentData[id]?.projectId
	}
	
	access(all)
	fun getCommentItemIdById(id: UInt64): UInt64?{ 
		return MIKOSEANFT.commentData[id]?.itemId
	}
	
	access(all)
	fun getCommentNFTIdById(id: UInt64): UInt64?{ 
		return MIKOSEANFT.commentData[id]?.nftId
	}
	
	access(all)
	fun getAllComments(): [MIKOSEANFT.Comment]{ 
		return self.commentData.values
	}
	
	access(all)
	fun removeAllCommentByNftId(_ nftId: UInt64){ 
		for commentId in MIKOSEANFT.commentData.keys{ 
			let commentNftId = MIKOSEANFT.getCommentNFTIdById(id: commentId)
			if nftId == commentNftId{ 
				MIKOSEANFT.deleteComment(commentId: commentId)
			}
		}
	}
	
	//------------------------------------------------------------
	// Item Public function
	//------------------------------------------------------------
	access(all)
	fun getAllItems(): [MIKOSEANFT.Item]{ 
		return self.itemData.values
	}
	
	access(all)
	fun getItemMetaData(itemId: UInt64):{ String: String}?{ 
		return self.itemData[itemId]?.metadata
	}
	
	access(all)
	fun getItemsInProject(projectId: UInt64): [UInt64]?{ 
		return MIKOSEANFT.projects[projectId]?.items
	}
	
	access(all)
	fun getItemMetaDataByField(itemId: UInt64, field: String): String?{ 
		if let item = self.itemData[itemId]{ 
			return item.metadata[field]
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getItemSupply(itemId: UInt64): UInt64?{ 
		let item = self.itemData[itemId]
		return item?.itemSupply
	}
	
	access(all)
	fun isProjectItemLocked(projectId: UInt64, itemId: UInt64): Bool?{ 
		if let projectToRead <- self.projects.remove(key: projectId){ 
			let locked = projectToRead.lockItems[itemId]
			self.projects[projectId] <-! projectToRead
			return locked
		} else{ 
			return nil
		}
	}
	
	//------------------------------------------------------------
	// Project Public function
	//------------------------------------------------------------
	access(all)
	fun getAllProjects(): [MIKOSEANFT.ProjectData]{ 
		return self.projectsData.values
	}
	
	access(all)
	fun getProjectName(projectId: UInt64): String?{ 
		return self.projectsData[projectId]?.name
	}
	
	access(all)
	fun getProjectDescription(projectId: UInt64): String?{ 
		return self.projectsData[projectId]?.description
	}
	
	access(all)
	fun getProjectCreatorAddress(projectId: UInt64): Address?{ 
		return self.projectsData[projectId]?.creatorAddress
	}
	
	access(all)
	fun getProjectCreatorFee(projectId: UInt64): UFix64?{ 
		return self.projectsData[projectId]?.creatorFee
	}
	
	access(all)
	fun getProjectPlatformFee(projectId: UInt64): UFix64?{ 
		return self.projectsData[projectId]?.platformFee
	}
	
	access(all)
	fun isProjectLocked(projectId: UInt64): Bool?{ 
		return self.projects[projectId]?.locked
	}
	
	access(all)
	fun getProjectIdByName(projectName: String): [UInt64]?{ 
		var projectIds: [UInt64] = []
		for projectDatas in self.projectsData.values{ 
			if projectName == projectDatas.name{ 
				projectIds.append(projectDatas.projectId)
			}
		}
		if projectIds.length == 0{ 
			return nil
		} else{ 
			return projectIds
		}
	}
	
	// fetch the nft from user collection
	access(all)
	fun fetch(_from: Address, itemId: UInt64): &MIKOSEANFT.NFT?{ 
		let collection = getAccount(_from).capabilities.get<&{MIKOSEANFT.MikoSeaCollectionPublic}>(MIKOSEANFT.CollectionPublicPath).borrow<&{MIKOSEANFT.MikoSeaCollectionPublic}>() ?? panic("does't not collection")
		return collection.borrowMiKoSeaNFT(id: itemId)
	}
	
	// get total count of minted nft from project item
	access(all)
	fun getTotalMintedNFTFromProjectItem(projectId: UInt64, itemId: UInt64): UInt64?{ 
		if let projectToRead <- self.projects.remove(key: projectId){ 
			let value = projectToRead.numberMintedPerItem[itemId]
			self.projects[projectId] <-! projectToRead
			return value
		} else{ 
			return nil
		}
	}
	
	// get total itemSupply in project
	access(all)
	fun getProjectTotalSupply(_ projectId: UInt64): UInt64{ 
		let items = MIKOSEANFT.getItemsInProject(projectId: projectId) ?? []
		var res: UInt64 = 0
		for item in items{ 
			let itemSupply = MIKOSEANFT.getItemSupply(itemId: item) ?? 0
			res = res + itemSupply
		}
		return res
	}
	
	//------------------------------------------------------------
	// Initializer
	//------------------------------------------------------------
	init(){ 
		// Initialize contract paths
		self.CollectionStoragePath = /storage/MikoSeaCollection
		self.CollectionPublicPath = /public/MikoSeaCollection
		self.MikoSeaAdmin = /storage/MiKoSeaNFTAdmin
		
		// Initialize contract fields
		self.nextItemId = 1
		self.nextProjectId = 1
		self.nextCommentId = 1
		self.totalSupply = 0
		self.itemData ={} 
		self.projectsData ={} 
		self.projects <-{} 
		self.commentData ={} 
		
		// Put the new Collection into the account storage
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		// Put the Admin in storage
		self.account.storage.save(<-create Admin(), to: self.MikoSeaAdmin)
		// Creating public capability of the Collection resource
		var capability_1 = self.account.capabilities.storage.issue<&{MikoSeaCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
