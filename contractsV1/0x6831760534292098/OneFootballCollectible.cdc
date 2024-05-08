/**

OneFootballCollectible.cdc

This smart contract is part of the NFT platform
created by OneFootball.

Author: Louis Guitton
	- email: louis.guitton@onefootball.com
	- discord: laguitte#6016

References:
- OneFootballCollectible relies for the most part on a simple onflow/freshmint NFT contract
  Ref: https://github.com/onflow/freshmint/blob/v2.2.0-alpha.0/src/templates/cadence/contracts/NFT.cdc
- It differs in how metadata is handled: we store media on IPFS and metadata on-chain
  We draw inspiration from what Animoca did for MotoGP: they use a separate contract MotoGPCardMetadata.cdc to make metadata explicit,
  the NFT then stores on a cardID that points to the central MotoGPCardMetadata smart contract, where metadata can be fetched from
  Ref: https://flow-view-source.com/mainnet/account/0xa49cc0ee46c54bfb/contract/MotoGPCardMetadata
- We use a separate contract NFTAirDrop.cdc (taken from onflow/freshmint) to unlock claimable drops
  Ref: https://github.com/onflow/freshmint/blob/v2.2.0-alpha.0/src/templates/cadence/contracts/NFTAirDrop.cdc
- We also referred to VIV3's Collectible contract (with Series/Set/Collectible/Item) but in the end we only
  kept the event emission when an NFT is destroyed from it
  Ref: https://flow-view-source.com/mainnet/account/0x34ba81b8b761306e/contract/Collectible
- We referred to prior art for the metadata naming:
	- Alchemy API NFT metadata view https://github.com/alchemyplatform/alchemy-flow-contracts/blob/main/src/cadence/scripts/getNFTs.cdc#L45
	- NFT Metadata FLIP https://github.com/onflow/flow/blob/master/flips/20210916-nft-metadata.md

**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract OneFootballCollectible: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, templateID: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	access(all)
	event TemplateEdited(templateID: UInt64)
	
	access(all)
	event TemplateRemoved(templateID: UInt64)
	
	// Named Paths
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/* totalSupply
		The total number of OneFootballCollectible that have been minted. */
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Template{ 
		// the id of the template that holds the metadata and to which NFTs will be pointing
		access(all)
		let templateID: UInt64
		
		// name of the series this template belongs to, e.g.: '2021-xmas-jerseys', 'onefootballerz', or '2022-stars-drop'
		access(all)
		let seriesName: String
		
		// title of the NFT Template
		access(all)
		let name: String
		
		// description of the NFT Template
		access(all)
		let description: String
		
		// IPFS CID of the preview image of the NFT Template
		access(all)
		let preview: String
		
		// IPFS CID of the media file (.jpg, .mp4, .glb or any IPFS supported format)
		access(all)
		let media: String
		
		// data contains all 'other' metadata fields, e.g. team, position, etc
		access(all)
		let data:{ String: String}
		
		init(templateID: UInt64, seriesName: String, name: String, description: String, preview: String, media: String, data:{ String: String}){ 
			pre{ 
				!data.containsKey("name"):
					"data dictionary contains 'name' key"
				!data.containsKey("description"):
					"data dictionary contains 'description' key"
				!data.containsKey("media"):
					"data dictionary contains 'media' key"
			}
			self.templateID = templateID
			self.seriesName = seriesName
			self.name = name
			self.description = description
			self.preview = preview
			self.media = media
			self.data = data
		}
	}
	
	// Dictionary to hold all metadata with templateID as key
	access(self)
	let templates:{ UInt64: Template}
	
	access(all)
	fun getTemplates():{ UInt64: Template}{ 
		return self.templates
	}
	
	// Get metadata for a specific templateID
	access(all)
	fun getTemplate(templateID: UInt64): Template?{ 
		return self.templates[templateID]
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let templateID: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(templateID: UInt64){ 
			OneFootballCollectible.totalSupply = OneFootballCollectible.totalSupply + 1
			self.id = OneFootballCollectible.totalSupply
			self.templateID = templateID
			emit Minted(id: self.id, templateID: self.templateID)
		}
		
		access(all)
		fun getTemplate(): Template?{ 
			return OneFootballCollectible.getTemplate(templateID: self.templateID)
		}
	}
	
	/* Custom public interface for our collection capability.
		NonFungibleToken.CollectionPublic has borrowNFT but not borrowOneFootballCollectible. */
	
	access(all)
	resource interface OneFootballCollectibleCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowOneFootballCollectible(id: UInt64): &OneFootballCollectible.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow OneFootballCollectible reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	/* Collection
		Mostly vanilla Collection resource from the NFT Tutorials.
		Added borrowOneFootballCollectible, pop and size methods following freshmint's NFT contract. */
	
	access(all)
	resource Collection: OneFootballCollectibleCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		/* dictionary of NFTs
				Each NFT is uniquely identified by its `NFT.id: UInt64` field.
		
				Dictionary definitions don't usually have the @ symbol in the type specification,
				but because the ownedNFTs mapping stores resources, the whole field also has to
				become a resource type, which is why the field has the @ symbol indicating that it is a resource type.
				*/
		
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/* withdraw
				Remove an NFT from the collection and returns it. */
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/* deposit
				Deposit an NFT to the collection. */
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @OneFootballCollectible.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		/* borrowOneFootballCollectible
				Gets a reference to an NFT in the collection as a OneFootballCollectible. */
		
		access(all)
		fun borrowOneFootballCollectible(id: UInt64): &OneFootballCollectible.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &OneFootballCollectible.NFT
			} else{ 
				return nil
			}
		}
		
		/* pop
				Removes and returns the next NFT from the collection.*/
		
		access(all)
		fun pop(): @{NonFungibleToken.NFT}{ 
			let nextID = self.ownedNFTs.keys[0]
			return <-self.withdraw(withdrawID: nextID)
		}
		
		/* size
				Returns the current size of the collection. */
		
		access(all)
		fun size(): Int{ 
			return self.ownedNFTs.length
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
	resource interface Minter{ 
		access(all)
		fun mintNFT(templateID: UInt64): @OneFootballCollectible.NFT
	}
	
	access(all)
	resource interface TemplateEditor{ 
		access(all)
		fun setTemplate(templateID: UInt64, seriesName: String, name: String, description: String, preview: String, media: String, data:{ String: String})
		
		access(all)
		fun removeTemplate(templateID: UInt64)
	}
	
	access(all)
	resource Admin: Minter, TemplateEditor{ 
		access(all)
		fun mintNFT(templateID: UInt64): @OneFootballCollectible.NFT{ 
			let nft <- create OneFootballCollectible.NFT(templateID: templateID)
			return <-nft
		}
		
		access(all)
		fun setTemplate(templateID: UInt64, seriesName: String, name: String, description: String, preview: String, media: String, data:{ String: String}){ 
			let metadata = OneFootballCollectible.Template(templateID: templateID, seriesName: seriesName, name: name, description: description, preview: preview, media: media, data: data)
			OneFootballCollectible.templates[templateID] = metadata
			emit TemplateEdited(templateID: templateID)
		}
		
		access(all)
		fun removeTemplate(templateID: UInt64){ 
			OneFootballCollectible.templates.remove(key: templateID)
			emit TemplateRemoved(templateID: templateID)
		}
	}
	
	access(all)
	fun check(_ address: Address): Bool{ 
		return getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(OneFootballCollectible.CollectionPublicPath).check()
	// else "Collection Reference was not created correctly"
	}
	
	// fetch
	// Get a reference to a OneFootballCollectible from an account's Collection, if available.
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &OneFootballCollectible.NFT?{ 
		let collection = getAccount(from).capabilities.get<&{OneFootballCollectible.OneFootballCollectibleCollectionPublic}>(OneFootballCollectible.CollectionPublicPath).borrow<&{OneFootballCollectible.OneFootballCollectibleCollectionPublic}>() ?? panic("Couldn't get collection")
		let nft = collection.borrowOneFootballCollectible(id: itemID)
		return nft
	}
	
	init(){ 
		self.templates ={} 
		
		// set named paths
		self.CollectionPublicPath = /public/OneFootballCollectibleCollection
		self.CollectionStoragePath = /storage/OneFootballCollectibleCollection
		self.CollectionPrivatePath = /private/OneFootballCollectibleCollection
		self.AdminStoragePath = /storage/OneFootballCollectibleAdmin
		self.totalSupply = 0
		self.account.storage.save(<-OneFootballCollectible.createEmptyCollection(nftType: Type<@OneFootballCollectible.Collection>()), to: OneFootballCollectible.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&OneFootballCollectible.Collection>(OneFootballCollectible.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: OneFootballCollectible.CollectionPrivatePath)
		var capability_2 = self.account.capabilities.storage.issue<&OneFootballCollectible.Collection>(OneFootballCollectible.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: OneFootballCollectible.CollectionPublicPath)
		self.account.storage.save(<-create Admin(), to: OneFootballCollectible.AdminStoragePath)
		emit ContractInitialized()
	}
}
