// DisruptArt NFT Marketplace
// NFT smart contract
// NFT Marketplace : www.disrupt.art
// Owner		   : Disrupt Art, INC.
// Developer	   : www.blaze.ws
// Version		 : 0.0.8
// Blockchain	  : Flow www.onFlow.org
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract DisruptArt: NonFungibleToken{ 
	
	// Total number of token supply
	access(all)
	var totalSupply: UInt64
	
	// NFT No of Editions(Multiple copies) limit
	access(all)
	var editionLimit: UInt
	
	/// Path where the `Collection` is stored
	access(all)
	let disruptArtStoragePath: StoragePath
	
	/// Path where the public capability for the `Collection` is
	access(all)
	let disruptArtPublicPath: PublicPath
	
	/// NFT Minter
	access(all)
	let disruptArtMinterPath: StoragePath
	
	// Contract Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, content: String, owner: Address?, name: String)
	
	access(all)
	event GroupMint(id: UInt64, content: String, owner: Address?, name: String, tokenGroupId: UInt64)
	
	// TOKEN RESOURCE
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Unique identifier for NFT Token
		access(all)
		let id: UInt64
		
		// Meta data to store token data (use dict for data)
		access(self)
		let metaData:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metaData
		}
		
		// NFT token name
		access(all)
		let name: String
		
		// NFT token creator address
		access(all)
		let creator: Address?
		
		// In current store static dict in meta data
		init(id: UInt64, content: String, name: String, description: String, creator: Address?, previewContent: String, mimeType: String){ 
			self.id = id
			self.metaData ={ "content": content, "description": description, "previewContent": previewContent, "mimeType": mimeType}
			self.creator = creator
			self.name = name
		}
		
		access(self)
		fun getFlowRoyaltyReceiverPublicPath(): PublicPath{ 
			return /public/flowTokenReceiver
		}
		
		// fn to get the royality details
		access(self)
		fun genRoyalities(): [MetadataViews.Royalty]{ 
			var royalties: [MetadataViews.Royalty] = []
			
			// Creator Royalty
			royalties.append(MetadataViews.Royalty(receiver: getAccount(self.creator!).capabilities.get<&{FungibleToken.Vault}>(self.getFlowRoyaltyReceiverPublicPath()), cut: UFix64(0.1), description: "Creator Royalty"))
			return royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.metaData["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.metaData["previewContent"]!))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.genRoyalities())
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://disrupt.art")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DisruptArt.disruptArtStoragePath, publicPath: DisruptArt.disruptArtPublicPath, publicCollection: Type<&DisruptArt.Collection>(), publicLinkedType: Type<&DisruptArt.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DisruptArt.createEmptyCollection(nftType: Type<@DisruptArt.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://disrupt.art/nft/assets/images/logoicon.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "DisruptArt Collection", description: "Discover amazing NFT collections from various disruptor creators. Disrupt.art Marketplace's featured and spotlight NFTs", externalURL: MetadataViews.ExternalURL("https://disrupt.art"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/DisruptArt"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/disrupt.art/"), "discord": MetadataViews.ExternalURL("https://discord.io/disruptart")})
				case Type<MetadataViews.Traits>():
					return []
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Account's public collection
	access(all)
	resource interface DisruptArtCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDisruptArt(id: UInt64): &DisruptArt.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CaaPass reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// NFT Collection resource
	access(all)
	resource Collection: DisruptArtCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Contains caller's list of NFTs
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DisruptArt.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// function returns token keys of owner
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// function returns token data of token id
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Gets a reference to an NFT in the collection as a DisruptArt
		access(all)
		fun borrowDisruptArt(id: UInt64): &DisruptArt.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DisruptArt.NFT
			} else{ 
				return nil
			}
		}
		
		// function to check wether the owner have token or not
		access(all)
		fun tokenExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let DisruptArtNFT = nft as! &DisruptArt.NFT
			return DisruptArtNFT as &{ViewResolver.Resolver}
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
	
	// NFT MINTER
	access(all)
	resource NFTMinter{ 
		
		// Function to mint group of tokens
		access(all)
		fun GroupMint(recipient: &{DisruptArtCollectionPublic}, content: String, description: String, name: String, edition: UInt, tokenGroupId: UInt64, previewContent: String, mimeType: String){ 
			pre{ 
				DisruptArt.editionLimit >= edition:
					"Edition count exceeds the limit"
				edition >= 2:
					"Edition count should be greater than or equal to 2"
			}
			var count = 0 as UInt
			while count < edition{ 
				let token <- create NFT(id: DisruptArt.totalSupply, content: content, name: name, description: description, creator: recipient.owner?.address, previewContent: previewContent, mimeType: mimeType)
				emit GroupMint(id: DisruptArt.totalSupply, content: content, owner: recipient.owner?.address, name: name, tokenGroupId: tokenGroupId)
				recipient.deposit(token: <-token)
				DisruptArt.totalSupply = DisruptArt.totalSupply + 1 as UInt64
				count = count + 1
			}
		}
		
		access(all)
		fun Mint(recipient: &{DisruptArtCollectionPublic}, content: String, name: String, description: String, previewContent: String, mimeType: String){ 
			let token <- create NFT(id: DisruptArt.totalSupply, content: content, name: name, description: description, creator: recipient.owner?.address, previewContent: previewContent, mimeType: mimeType)
			emit Mint(id: DisruptArt.totalSupply, content: content, owner: recipient.owner?.address, name: name)
			recipient.deposit(token: <-token)
			DisruptArt.totalSupply = DisruptArt.totalSupply + 1 as UInt64
		}
	}
	
	// This is used to create the empty collection. without this address cannot access our NFT token
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create DisruptArt.Collection()
	}
	
	// Admin can change the maximum supported group minting count limit for the platform. Currently it is 50
	access(all)
	resource Admin{ 
		access(all)
		fun changeLimit(limit: UInt){ 
			DisruptArt.editionLimit = limit
		}
	}
	
	// Contract init
	init(){ 
		
		// total supply is zero at the time of contract deployment
		self.totalSupply = 0
		self.editionLimit = 10000
		self.disruptArtStoragePath = /storage/DisruptArtNFTCollection
		self.disruptArtPublicPath = /public/DisruptArtNFTPublicCollection
		self.disruptArtMinterPath = /storage/DisruptArtNFTMinter
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.disruptArtStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{DisruptArtCollectionPublic}>(self.disruptArtStoragePath)
		self.account.capabilities.publish(capability_1, at: self.disruptArtPublicPath)
		self.account.storage.save(<-create self.Admin(), to: /storage/DirsuptArtAdmin)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.disruptArtMinterPath)
		emit ContractInitialized()
	}
}
