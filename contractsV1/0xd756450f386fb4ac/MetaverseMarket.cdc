//SPDX-License-Identifier : CC-BY-NC-4.0
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

// Metaverse
// NFT for Metaverse
//
access(all)
contract MetaverseMarket: NonFungibleToken{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeID: UInt64, metadata:{ String: String})
	
	access(all)
	event BatchMinted(ids: [UInt64], typeID: [UInt64], metadata:{ String: String})
	
	access(all)
	event NFTBurned(id: UInt64)
	
	access(all)
	event NFTsBurned(ids: [UInt64])
	
	access(all)
	event CategoryCreated(categoryName: String)
	
	access(all)
	event SubCategoryCreated(subCategoryName: String)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of MetaverseMarkets that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// List with all categories and respective code
	access(self)
	var categoriesList:{ UInt64: String}
	
	// {CategoryName: [NFT To Sell ID]}
	access(self)
	var categoriesNFTsToSell:{ UInt64: [UInt64]}
	
	// Dictionary with NFT List Data
	access(self)
	var nftsToSell:{ UInt64: OzoneListToSellMetadata}
	
	access(all)
	struct OzoneListToSellMetadata{ 
		//List ID that will came from the backend, all NFTs from same list will have same listId
		access(all)
		let listId: UInt64
		
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var categoryId: UInt64
		
		access(all)
		let creator: Address?
		
		access(all)
		let creatorDapperAddress: Address?
		
		access(all)
		let fileName: String
		
		access(all)
		var previewImage: String
		
		access(all)
		let format: String
		
		access(all)
		let fileIPFS: String
		
		access(all)
		var price: UFix64
		
		access(all)
		let maxSupply: UInt64
		
		access(all)
		var minted: UInt64
		
		access(all)
		fun addMinted(){ 
			self.minted = self.minted + 1
		}
		
		access(all)
		fun changePrice(newPrice: UFix64){ 
			self.price = newPrice
		}
		
		access(all)
		fun updateList(newPreviewImage: String?, newName: String?, newDescription: String?, newCategoryId: UInt64?){ 
			if newPreviewImage != nil{ 
				self.previewImage = newPreviewImage!
			}
			if newName != nil{ 
				self.name = newName!
			}
			if newDescription != nil{ 
				self.description = newDescription!
			}
			if newCategoryId != nil{ 
				self.categoryId = newCategoryId!
			}
		}
		
		init(_listId: UInt64, _name: String, _description: String, _categoryId: UInt64, _creator: Address?, _creatorDapperAddress: Address?, _fileName: String, _previewImage: String, _format: String, _fileIPFS: String, _price: UFix64, _maxSupply: UInt64){ 
			self.listId = _listId
			self.name = _name
			self.description = _description
			self.categoryId = _categoryId
			self.creator = _creator
			self.creatorDapperAddress = _creatorDapperAddress
			self.fileName = _fileName
			self.previewImage = _previewImage
			self.format = _format
			self.fileIPFS = _fileIPFS
			self.price = _price
			self.maxSupply = _maxSupply
			self.minted = 0
		}
	}
	
	// NFT
	// MetaverseMarket as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		//NFT CONTRACT GLOBAL ID -> Current TotalSupply
		access(all)
		let id: UInt64
		
		//Current List minted(List TotalSupply)
		access(all)
		let uniqueListId: UInt64
		
		//List ID that will came from the backend, all NFTs from same list will have same listId
		access(all)
		let listId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let previewImage: String
		
		access(all)
		let categoryId: UInt64
		
		access(all)
		let creator: Address?
		
		access(all)
		let creatorDapperWallet: Address?
		
		access(all)
		let fileName: String
		
		access(all)
		let format: String
		
		access(all)
		let fileIPFS: String
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.fileIPFS))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://ozonemetaverse.io/")
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					royalties.append(MetadataViews.Royalty(receiver: getAccount(MetaverseMarket.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.03, description: "Ozone Marketplace Secondary Sale Royalty"))
					royalties.append(MetadataViews.Royalty(receiver: getAccount(self.creator!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.07, description: "NFT Creator Secondary Sale Royalty"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MetaverseMarket.CollectionStoragePath, publicPath: MetaverseMarket.CollectionPublicPath, publicCollection: Type<&MetaverseMarket.Collection>(), publicLinkedType: Type<&MetaverseMarket.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MetaverseMarket.createEmptyCollection(nftType: Type<@MetaverseMarket.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d19wottuqbmkwr.cloudfront.net/nft/banners1.jpg"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d19wottuqbmkwr.cloudfront.net/nft/banners2.jpg"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "Ozone Metaverse Marketplace", description: "The first ever virtual world building creator NFT marketplace on Flow. Made by creators, for creators. Instantly create listings of all media file types including 3D models which can be immediately used in virtual world building studio. Build the new metaverse economy today by becoming a creator or simply start to build worlds today. Built on Flow. Powered by Ozone.", externalURL: MetadataViews.ExternalURL("https://ozonemetaverse.io"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/ozonemetaverse"), "discord": MetadataViews.ExternalURL("https://discord.gg/ozonemetaverse")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// initializer
		//
		init(initID: UInt64, uniqueListId: UInt64, listId: UInt64, name: String, categoryId: UInt64, description: String, previewImage: String, creator: Address?, creatorDapperWallet: Address?, fileName: String, format: String, fileIPFS: String){ 
			self.id = initID
			self.uniqueListId = uniqueListId
			self.listId = listId
			self.name = name
			self.description = description
			self.previewImage = previewImage
			self.categoryId = categoryId
			self.creator = creator
			self.creatorDapperWallet = creatorDapperWallet
			self.fileName = fileName
			self.format = format
			self.fileIPFS = fileIPFS
		}
	
	// If the NFT is burned, emit an event to indicate
	// to outside observers that it has been destroyed
	}
	
	// This is the interface that users can cast their MetaverseMarket Collection as
	// to allow others to deposit MetaverseMarket into their Collection. It also allows for reading
	// the details of MetaverseMarket in the Collection.
	access(all)
	resource interface MetaverseMarketCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getNFTs(): &{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMetaverseMarket(id: UInt64): &MetaverseMarket.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MetaverseMarket reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of MetaverseMarket NFTs owned by an account
	//
	access(all)
	resource Collection: MetaverseMarketCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MetaverseMarket.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun getNFTs(): &{UInt64:{ NonFungibleToken.NFT}}{ 
			return &self.ownedNFTs as &{UInt64:{ NonFungibleToken.NFT}}
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowMetaverseMarket
		// Gets a reference to an NFT in the collection as a MetaverseMarket,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the MetaverseMarket.
		//
		access(all)
		fun borrowMetaverseMarket(id: UInt64): &MetaverseMarket.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MetaverseMarket.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowNFTSafe(id: UInt64): &NFT?{ 
			post{ 
				result == nil || (result!).id == id:
					"The returned reference's ID does not match the requested ID"
			}
			return self.ownedNFTs[id] != nil ? (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &MetaverseMarket.NFT : nil
		}
		
		// borrowViewResolver
		// Gets a reference to the MetadataViews resolver in the collection,
		// giving access to all metadata information made available.
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let metaverseNft = nft as! &MetaverseMarket.NFT
			return metaverseNft
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// NFTAdmin
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		access(all)
		fun createCategory(categoryId: UInt64, categoryName: String){ 
			if UInt64(MetaverseMarket.categoriesList.length + 1) != categoryId{ 
				panic("Category ID already exists")
			}
			MetaverseMarket.categoriesList[categoryId] = categoryName
			MetaverseMarket.categoriesNFTsToSell[categoryId] = []
			emit CategoryCreated(categoryName: categoryName)
		}
		
		access(all)
		fun createList(listId: UInt64, name: String, description: String, categoryId: UInt64, creator: Address?, creatorDapperAddress: Address?, fileName: String, previewImage: String, format: String, fileIPFS: String, price: UFix64, maxSupply: UInt64){ 
			var max = 0 as UInt64
			for element in MetaverseMarket.nftsToSell.keys{ 
				if element > max{ 
					max = element
				}
			}
			if listId != UInt64(max + 1){ 
				panic("NFT List ID already exists")
			}
			let list = OzoneListToSellMetadata(_listId: listId, _name: name, _description: description, _categoryId: categoryId, _creator: creator, _creatorDapperAddress: creatorDapperAddress, _fileName: fileName, _previewImage: previewImage, _format: format, _fileIPFS: fileIPFS, _price: price, _maxSupply: maxSupply)
			MetaverseMarket.nftsToSell[listId] = list
			(			 
			 //Add the list to the categoriesNFTsToSell
			 MetaverseMarket.categoriesNFTsToSell[categoryId]!).append(listId)
		}
		
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, payment: @{FungibleToken.Vault}, listedNftId: UInt64){ 
			pre{ 
				MetaverseMarket.nftsToSell[listedNftId] != nil:
					"Listed ID does not exists!"
				payment.balance == (MetaverseMarket.nftsToSell[listedNftId]!).price:
					"Incorrect price!"
				(MetaverseMarket.nftsToSell[listedNftId]!).maxSupply != (MetaverseMarket.nftsToSell[listedNftId]!).minted:
					"Max Supply reached!"
			}
			let list = MetaverseMarket.nftsToSell[listedNftId]!
			(MetaverseMarket.nftsToSell[listedNftId]!).addMinted()
			let royalty <- payment.withdraw(amount: payment.balance * 0.1)
			switch payment.getType(){ 
				case Type<@FlowToken.Vault>():
					// Get a reference to the recipient's Receiver
					let receiverRef = getAccount(list.creator!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
					
					// Get a reference to the recipient's Receiver
					let royaltyReceiver = getAccount(MetaverseMarket.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
					royaltyReceiver.deposit(from: <-royalty)
					receiverRef.deposit(from: <-payment)
					
					// deposit it in the recipient's account using their reference
					recipient.deposit(token: <-create MetaverseMarket.NFT(initID: MetaverseMarket.totalSupply, uniqueListId: list.minted, listId: list.listId, name: list.name, categoryId: list.categoryId, description: list.description, previewImage: list.previewImage, creator: list.creator, creatorDapperWallet: list.creatorDapperAddress, fileName: list.fileName, format: list.format, fileIPFS: list.fileIPFS))
				case Type<@FlowUtilityToken.Vault>():
					// Get a reference to the recipient's Receiver
					let receiverRef = getAccount(list.creatorDapperAddress!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the creator Dapper Address Vault")
					
					// Get a reference to the recipient's Receiver
					let royaltyReceiver = getAccount(0x43fbb5fb34ba8ef0).capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver).borrow<&{FungibleToken.Receiver}>() ?? panic("Could not borrow receiver reference to the recipient's Vault")
					royaltyReceiver.deposit(from: <-royalty)
					receiverRef.deposit(from: <-payment)
					
					// deposit it in the recipient's account using their reference
					recipient.deposit(token: <-create MetaverseMarket.NFT(initID: MetaverseMarket.totalSupply, uniqueListId: list.minted, listId: list.listId, name: list.name, categoryId: list.categoryId, description: list.description, previewImage: list.previewImage, creator: list.creatorDapperAddress, creatorDapperWallet: list.creatorDapperAddress, fileName: list.fileName, format: list.format, fileIPFS: list.fileIPFS))
				default:
					panic("Unsupported token type")
			}
			MetaverseMarket.totalSupply = MetaverseMarket.totalSupply + 1
		}
		
		//TransferNft, mint and transfer to Account NFT
		access(all)
		fun transferNFT(recipient: &{NonFungibleToken.CollectionPublic}, listedNftId: UInt64){ 
			pre{ 
				MetaverseMarket.nftsToSell[listedNftId] != nil:
					"Listed ID does not exists!"
				(MetaverseMarket.nftsToSell[listedNftId]!).maxSupply != (MetaverseMarket.nftsToSell[listedNftId]!).minted:
					"Max Supply reached!"
			}
			let list = MetaverseMarket.nftsToSell[listedNftId]!
			(MetaverseMarket.nftsToSell[listedNftId]!).addMinted()
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create MetaverseMarket.NFT(initID: MetaverseMarket.totalSupply, uniqueListId: list.minted, listId: list.listId, name: list.name, categoryId: list.categoryId, description: list.description, previewImage: list.previewImage, creator: list.creator, creatorDapperWallet: list.creatorDapperAddress, fileName: list.fileName, format: list.format, fileIPFS: list.fileIPFS))
			MetaverseMarket.totalSupply = MetaverseMarket.totalSupply + 1
		}
		
		//Delete Listing
		access(all)
		fun deleteListing(listedNftId: UInt64){ 
			pre{ 
				MetaverseMarket.nftsToSell[listedNftId] != nil:
					"Listed ID does not exists!"
			}
			let list = MetaverseMarket.nftsToSell[listedNftId]!
			MetaverseMarket.nftsToSell.remove(key: listedNftId)
		}
		
		//Change Price
		access(all)
		fun changePrice(listedNftId: UInt64, newPrice: UFix64){ 
			pre{ 
				MetaverseMarket.nftsToSell[listedNftId] != nil:
					"Listed ID does not exists!"
			}
			let list = MetaverseMarket.nftsToSell[listedNftId]!
			(MetaverseMarket.nftsToSell[listedNftId]!).changePrice(newPrice: newPrice)
		}
		
		access(all)
		fun updateList(listedNftId: UInt64, newPreviewImage: String?, newName: String?, newDescription: String?, newCategoryId: UInt64?){ 
			pre{ 
				MetaverseMarket.nftsToSell[listedNftId] != nil:
					"Listed ID does not exists!"
			}
			let list = MetaverseMarket.nftsToSell[listedNftId]!
			(MetaverseMarket.nftsToSell[listedNftId]!).updateList(newPreviewImage: newPreviewImage, newName: newName, newDescription: newDescription, newCategoryId: newCategoryId)
		}
	}
	
	// fetch
	// Get a reference to a MetaverseMarket from an account's Collection, if available.
	// If an account does not have a MetaverseMarket.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &MetaverseMarket.NFT?{ 
		let collection = getAccount(from).capabilities.get<&MetaverseMarket.Collection>(MetaverseMarket.CollectionPublicPath).borrow<&MetaverseMarket.Collection>() ?? panic("Couldn't get collection")
		// We trust MetaverseMarket.Collection.borowMetaverseMarket to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowMetaverseMarket(id: itemID)
	}
	
	access(all)
	fun getAllNftsFromAccount(_ from: Address): &{UInt64:{ NonFungibleToken.NFT}}?{ 
		let collection = getAccount(from).capabilities.get<&MetaverseMarket.Collection>(MetaverseMarket.CollectionPublicPath).borrow<&MetaverseMarket.Collection>() ?? panic("Couldn't get collection")
		return collection.getNFTs()
	}
	
	access(all)
	fun getCategories():{ UInt64: String}{ 
		return MetaverseMarket.categoriesList
	}
	
	access(all)
	fun getCategoriesIds(): [UInt64]{ 
		return MetaverseMarket.categoriesList.keys
	}
	
	access(all)
	fun getCategorieName(id: UInt64): String{ 
		return MetaverseMarket.categoriesList[id] ?? panic("Category does not exists")
	}
	
	access(all)
	fun getCategoriesListLength(): UInt64{ 
		return UInt64(MetaverseMarket.categoriesList.length)
	}
	
	access(all)
	fun getNftToSellListLength(): UInt64{ 
		var max = 0 as UInt64
		for element in MetaverseMarket.nftsToSell.keys{ 
			if element > max{ 
				max = element
			}
		}
		return max
	}
	
	access(all)
	fun getCategoriesNFTsToSell(categoryId: UInt64): [UInt64]?{ 
		return MetaverseMarket.categoriesNFTsToSell[categoryId]
	}
	
	access(all)
	fun getNftToSellData(listId: UInt64): OzoneListToSellMetadata?{ 
		return MetaverseMarket.nftsToSell[listId]
	}
	
	access(all)
	fun getAllListToSell(): [UInt64]{ 
		return MetaverseMarket.nftsToSell.keys
	}
	
	access(all)
	fun cleanListing(listId: UInt64){ 
		pre{ 
			(MetaverseMarket.nftsToSell[listId]!).minted != (MetaverseMarket.nftsToSell[listId]!).maxSupply:
				"Only Admin can deleted a not finished listing"
		}
		MetaverseMarket.nftsToSell.remove(key: listId)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/NftMetaverseMarketCollectionVersionTwo
		self.CollectionPublicPath = /public/NftMetaverseMarketCollectionVersionTwo
		self.AdminStoragePath = /storage/metaverseMarketV2Admin
		self.categoriesList ={} 
		self.categoriesNFTsToSell ={} 
		self.nftsToSell ={} 
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Create and link collection to this account
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&MetaverseMarket.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
