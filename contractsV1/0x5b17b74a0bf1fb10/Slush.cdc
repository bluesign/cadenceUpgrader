import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Slush: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
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
	let MinterStoragePath: StoragePath
	
	init(){ 
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/SlushCollection
		self.CollectionPublicPath = /public/SlushCollection
		self.MinterStoragePath = /storage/SlushMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Slush.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
	
	access(all)
	struct SlushDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let videoURI: String
		
		access(all)
		let ipfsVideo: MetadataViews.IPFSFile
		
		init(name: String, description: String, thumbnail:{ MetadataViews.File}, videoURI: String, ipfsVideo: MetadataViews.IPFSFile){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.videoURI = videoURI
			self.ipfsVideo = ipfsVideo
		}
	}
	
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
		
		access(all)
		let videoURI: String
		
		access(all)
		let videoCID: String
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(name: String, description: String, thumbnail: String, videoURI: String, videoCID: String, metadata:{ String: AnyStruct}){ 
			self.id = Slush.totalSupply
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.videoURI = videoURI
			self.videoCID = videoCID
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<Slush.SlushDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<Slush.SlushDisplay>():
					return Slush.SlushDisplay(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail), videoURI: self.videoURI, ipfsVideo: MetadataViews.IPFSFile(cid: self.videoCID, path: nil))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.slush.org/web3")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Slush.CollectionStoragePath, publicPath: Slush.CollectionPublicPath, publicCollection: Type<&Slush.Collection>(), publicLinkedType: Type<&Slush.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Slush.createEmptyCollection(nftType: Type<@Slush.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareImageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://mint.slush.org/media/slush-icon.png"), mediaType: "image/png")
					let bannerImageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://mint.slush.org/media/slush-logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Slush Ticket NFTs", description: "Slush is bringing the global startup ecosystem under one roof. A curated group of speakers from across the globe, showcases, and unique networking opportunities will all be in Helsinki.", externalURL: MetadataViews.ExternalURL("https://www.slush.org/"), squareImage: squareImageMedia, bannerImage: bannerImageMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/SlushHQ")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, videoURI: String, videoCID: String){ 
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			var newNFT <- create NFT(name: name, description: description, thumbnail: thumbnail, videoURI: videoURI, videoCID: videoCID, metadata: metadata)
			recipient.deposit(token: <-newNFT)
			Slush.totalSupply = Slush.totalSupply + 1
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Slush.NFT
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
		fun borrowSlushNFT(id: UInt64): &Slush.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Slush.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let Slush = nft as! &Slush.NFT
			return Slush as &{ViewResolver.Resolver}
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
}
