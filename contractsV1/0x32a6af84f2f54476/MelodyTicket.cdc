import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MelodyError from "./MelodyError.cdc"

access(all)
contract MelodyTicket: NonFungibleToken{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event TicketCreated(id: UInt64, creator: Address?)
	
	access(all)
	event TicketDestoryed(id: UInt64, owner: Address?)
	
	access(all)
	event TicketTransfered(paymentId: UInt64, from: Address?, to: Address?)
	
	access(all)
	event MetadataUpdated(id: UInt64, key: String)
	
	access(all)
	event MetadataInited(id: UInt64)
	
	access(all)
	event BaseURIUpdated(before: String, after: String)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var baseURI: String
	
	// metadata 
	access(contract)
	var predefinedMetadata:{ UInt64:{ String: AnyStruct}}
	
	// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			if MelodyTicket.baseURI != ""{ 
				self.thumbnail = MelodyTicket.baseURI.concat(id.toString())
			} else{ 
				self.thumbnail = "https://testnet.melody.im/api/data/payment/".concat(self.id.toString()).concat("&width=600&height=400")
			}
			self.royalties = []
			self.metadata = metadata
		}
		
		access(all)
		view fun getMetadata():{ String: AnyStruct}{ 
			let metadata = MelodyTicket.predefinedMetadata[self.id] ??{} 
			metadata["metadata"] = self.metadata
			return metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = MelodyTicket.predefinedMetadata[self.id] ??{} 
			let transferable = (metadata["transferable"] as? Bool?)! ?? true
			let paymentType = (metadata["paymentType"] as? UInt8?)!
			let revocable = paymentType == 0 || paymentType == 0
			switch view{ 
				case Type<MetadataViews.Display>():
					var desc = "\n"
					if transferable{ 
						desc = desc.concat("Transferable \n")
					} else{ 
						desc = desc.concat("Cannot transfer \n")
					}
					if revocable{ 
						desc = desc.concat("Revocable \n")
					} else{ 
						desc = desc.concat("Cannot revoke \n")
					}
					return MetadataViews.Display(name: self.name, description: self.description.concat(desc), thumbnail: MetadataViews.HTTPFile(url: "https://testnet.melody.im/api/data/payment/".concat(self.id.toString()).concat("?width=600&height=400")))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Melody ticket NFT", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let receieverCap = MelodyTicket.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					let royalty = MetadataViews.Royalty(receiver: receieverCap!, cut: 0.03, description: "LyricLabs will take 3% as second trade royalty fee")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>(): // todo
					
					return MetadataViews.ExternalURL("https://melody.im/payment/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MelodyTicket.CollectionStoragePath, publicPath: MelodyTicket.CollectionPublicPath, publicCollection: Type<&MelodyTicket.Collection>(), publicLinkedType: Type<&MelodyTicket.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MelodyTicket.createEmptyCollection(nftType: Type<@MelodyTicket.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "The Melody ticket NFT", description: "This collection is Melody ticket NFT.", externalURL: MetadataViews.ExternalURL(""), // todo																																															   
																																															   squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62dd12a167854020143ccd01/attachments/631422356f0fe60111e1ed3c/previews/631422366f0fe60111e1ed43/download/image.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trello.com/1/cards/62dd12a167854020143ccd01/attachments/631423e7c7e6b800d710f2a1/download/image.png") // todo																																																																																																																																																							  
																																																																																																																																																							  , mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/lyric_labs"), "website": MetadataViews.ExternalURL("https://lyriclabs.xyz")})
				case Type<MetadataViews.Traits>():
					let metadata = MelodyTicket.predefinedMetadata[self.id]!
					let traitsView = MetadataViews.dictToTraits(dict: metadata, excludedNames: [])
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					return traitsView
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
		fun borrowNFTResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource interface CollectionPrivate{ 
		access(all)
		fun borrowMelodyTicket(id: UInt64): &MelodyTicket.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow MelodyTicket reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, CollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			pre{ 
				self.checkTransferable(token.id, address: self.owner?.address) == true:
					MelodyError.errorEncode(msg: "Ticket is not transferable", err: MelodyError.ErrorCode.NOT_TRANSFERABLE)
			}
			let id: UInt64 = token.id
			let token <- token as! @MelodyTicket.NFT
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// update owner
			let owner = self.owner?.address
			let metadata = MelodyTicket.getMetadata(id)!
			let currentOwner = (metadata["owner"] as? Address?)!
			emit TicketTransfered(paymentId: id, from: currentOwner, to: owner)
			MelodyTicket.updateMetadata(id: id, key: "owner", value: owner)
			emit Deposit(id: id, to: owner)
			destroy oldToken
		}
		
		access(all)
		view fun checkTransferable(_ id: UInt64, address: Address?): Bool{ 
			let metadata = MelodyTicket.getMetadata(id)!
			let receievr = (metadata["receiver"] as? Address?)!
			if address != nil && receievr == address{ 
				return true
			}
			let transferable = (metadata["transferable"] as? Bool?)! ?? true
			return transferable
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
		fun borrowNFTResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MelodyTicket.NFT
			}
			return nil
		}
		
		access(all)
		fun borrowMelodyTicket(id: UInt64): &MelodyTicket.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MelodyTicket.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let MelodyTicket = nft as! &MelodyTicket.NFT
			return MelodyTicket as &{ViewResolver.Resolver}
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
		access(account)
		fun mintNFT(name: String, description: String, metadata:{ String: AnyStruct}): @MelodyTicket.NFT{ 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			let nftId = MelodyTicket.totalSupply + UInt64(1)
			// create a new NFT
			var newNFT <- create NFT(id: nftId, name: name, description: description, metadata: metadata)
			// deposit it in the recipient's account using their reference
			// recipient.deposit(token: <- newNFT)
			let creator = (metadata["creator"] as? Address?)!
			emit TicketCreated(id: nftId, creator: creator)
			MelodyTicket.totalSupply = nftId
			return <-newNFT
		}
		
		access(all)
		fun setBaseURI(_ uri: String){ 
			emit BaseURIUpdated(before: MelodyTicket.baseURI, after: uri)
			MelodyTicket.baseURI = uri
		}
	}
	
	access(account)
	fun setMetadata(id: UInt64, metadata:{ String: AnyStruct}){ 
		MelodyTicket.predefinedMetadata[id] = metadata
		// emit
		emit MetadataInited(id: id)
	}
	
	access(account)
	fun updateMetadata(id: UInt64, key: String, value: AnyStruct){ 
		pre{ 
			MelodyTicket.predefinedMetadata[id] != nil:
				MelodyError.errorEncode(msg: "Metadata not found", err: MelodyError.ErrorCode.NOT_EXIST)
		}
		let metadata = MelodyTicket.predefinedMetadata[id]!
		emit MetadataUpdated(id: id, key: key)
		metadata[key] = value
		MelodyTicket.predefinedMetadata[id] = metadata
	}
	
	// public funcs
	access(all)
	fun getTotalSupply(): UInt64{ 
		return MelodyTicket.totalSupply
	}
	
	access(all)
	view fun getMetadata(_ id: UInt64):{ String: AnyStruct}?{ 
		return MelodyTicket.predefinedMetadata[id]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MelodyTicketCollection
		self.CollectionPublicPath = /public/MelodyTicketCollection
		self.CollectionPrivatePath = /private/MelodyTicketCollection
		self.MinterStoragePath = /storage/MelodyTicketMinter
		self._reservedFields ={} 
		self.predefinedMetadata ={} 
		self.baseURI = ""
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&MelodyTicket.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// create a public capability for the collection
		var capability_2 = self.account.capabilities.storage.issue<&MelodyTicket.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPrivatePath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
