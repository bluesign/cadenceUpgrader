// SPDX-License-Identifier: MIT
/*
*  This is a 5,000 supply based NFT collection named Jolly Jokers with minimal metadata.
*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract JollyJokers: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var maxSupply: UInt64
	
	access(all)
	var baseURI: String
	
	access(all)
	var price: UFix64
	
	access(all)
	var name: String
	
	access(all)
	var description: String
	
	access(all)
	var thumbnails:{ UInt64: String}
	
	access(contract)
	var metadatas:{ UInt64:{ String: AnyStruct}}
	
	access(contract)
	var traits:{ UInt64:{ String: String}}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event BaseURISet(newBaseURI: String)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = JollyJokers.name.concat(" #").concat(id.toString())
			self.description = JollyJokers.description
			self.metadata = metadata
		}
		
		access(all)
		fun getThumbnail(): String{ 
			return JollyJokers.thumbnails[self.id] ?? JollyJokers.baseURI.concat(self.id.toString()).concat(".png")
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.getThumbnail()))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Jolly Jokers Edition", number: self.id, max: JollyJokers.maxSupply)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://otmnft-jj.s3.amazonaws.com/Jolly_Jokers.png")
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://otmnft-jj.s3.amazonaws.com/Jolly_Jokers.png"), mediaType: "image/png")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://otmnft-jj.s3.amazonaws.com/Joker-Banner.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Jolly Jokers", description: "The Jolly Joker Sports Society is a collection of 5,000 Jolly Jokers living on the Flow blockchain. Owning a Jolly Joker gets you access to the Own the Moment ecosystem, including analytics tools for NBA Top Shot and NFL ALL DAY, token-gated fantasy sports and poker competitions, and so much more. If you are a fan of sports, leaderboards, and fun \u{2013} then the Jolly Jokers is the perfect community for you!", externalURL: MetadataViews.ExternalURL("https://otmnft.com/"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/jollyjokersnft")})
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: JollyJokers.traits[self.id] ??{} , excludedNames: [])
				case Type<MetadataViews.Royalties>():
					// note: Royalties are not aware of the token being used with, so the path is not useful right now
					// eventually the FungibleTokenSwitchboard might be an option
					// https://github.com/onflow/flow-ft/blob/master/contracts/FungibleTokenSwitchboard.cdc
					let cut = MetadataViews.Royalty(receiver: JollyJokers.account.capabilities.get<&{FungibleToken.Receiver}>(/public/somePath)!, cut: 0.05, // 5% royalty																																							 
																																							 description: "Creator Royalty")
					var royalties: [MetadataViews.Royalty] = [cut]
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: JollyJokers.CollectionStoragePath, publicPath: JollyJokers.CollectionPublicPath, publicCollection: Type<&JollyJokers.Collection>(), publicLinkedType: Type<&JollyJokers.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-JollyJokers.createEmptyCollection(nftType: Type<@JollyJokers.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface JollyJokersCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowJollyJokers(id: UInt64): &JollyJokers.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow JollyJokers reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: JollyJokersCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @JollyJokers.NFT
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
		fun borrowJollyJokers(id: UInt64): &JollyJokers.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &JollyJokers.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let jokersNFT = nft as! &JollyJokers.NFT
			return jokersNFT as &{ViewResolver.Resolver}
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
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
			pre{ 
				JollyJokers.totalSupply < JollyJokers.maxSupply:
					"Total supply reached maximum limit"
			}
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedAt"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			
			// create a new NFT
			JollyJokers.totalSupply = JollyJokers.totalSupply + UInt64(1)
			var newNFT <- create NFT(id: JollyJokers.totalSupply, metadata: metadata)
			emit Mint(id: JollyJokers.totalSupply, to: recipient.owner?.address)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	// Admin is a special authorization resource that allows the owner
	// to create or update SKUs and to manage baseURI
	//
	access(all)
	resource Admin{ 
		access(all)
		fun setBaseURI(newBaseURI: String){ 
			JollyJokers.baseURI = newBaseURI
			emit BaseURISet(newBaseURI: newBaseURI)
		}
		
		access(all)
		fun setMaxSupply(newMaxSupply: UInt64){ 
			JollyJokers.maxSupply = newMaxSupply
		}
		
		access(all)
		fun setPrice(newPrice: UFix64){ 
			JollyJokers.price = newPrice
		}
		
		access(all)
		fun setMetadata(name: String, description: String){ 
			JollyJokers.name = name
			JollyJokers.description = description
		}
		
		access(all)
		fun setThumbnail(id: UInt64, thumbnail: String){ 
			JollyJokers.thumbnails[id] = thumbnail
		}
		
		access(all)
		fun updateTraits(id: UInt64, traits:{ String: String}){ 
			JollyJokers.traits[id] = traits
		}
	}
	
	// fetch
	// Get a reference to a JollyJokers from an account's Collection, if available.
	// If an account does not have a JollyJokers.Collection, panic.
	// If it has a collection but does not contain the jokerId, return nil.
	// If it has a collection and that collection contains the jokerId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, jokerId: UInt64): &JollyJokers.NFT?{ 
		let collection = getAccount(from).capabilities.get<&JollyJokers.Collection>(JollyJokers.CollectionPublicPath).borrow<&JollyJokers.Collection>() ?? panic("Couldn't get collection")
		// We trust JollyJokers.Collection.borowJollyJokers to get the correct jokerId
		// (it checks it before returning it).
		return collection.borrowJollyJokers(id: jokerId)
	}
	
	init(){ 
		// Initialize the total, max supply and base uri
		self.totalSupply = 0
		self.maxSupply = 0
		self.baseURI = ""
		self.price = 0.0
		self.name = ""
		self.description = ""
		self.thumbnails ={} 
		self.metadatas ={} 
		self.traits ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/JollyJokersCollection
		self.CollectionPublicPath = /public/JollyJokersCollection
		self.MinterStoragePath = /storage/JollyJokersMinter
		self.AdminStoragePath = /storage/JollyJokersAdmin
		self.AdminPrivatePath = /private/JollyJokersAdmin
		
		// Create resources and save it to storage
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&JollyJokers.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// create a public capability for the admin
		var capability_2 = self.account.capabilities.storage.issue<&JollyJokers.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_2, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
