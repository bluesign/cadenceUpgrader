import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract PublishedNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event PublishedMinted(id: UInt64, name: String, ipfsLink: String, type: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterPublishedPath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var libraryPassTotalSupply: UInt64
	
	access(all)
	var willoTotalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let serialId: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let ipfsLink: String
		
		access(all)
		let type: UInt64
		
		init(serialId: UInt64, initID: UInt64, name: String, ipfsLink: String, type: UInt64){ 
			self.serialId = serialId
			self.id = initID
			self.name = name
			self.ipfsLink = ipfsLink
			self.type = type
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let url = "https://ipfs.io/ipfs/".concat(self.ipfsLink)
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: "Holders of the 10,000 limited edition Genesis Library Pass, gain access to all public released eBooks.", thumbnail: MetadataViews.IPFSFile(cid: "bafybeiab3347ikvu3lxm4xbybjzdiertllduvx5cpqokk6m7cri2fft6gq", path: nil))
				case Type<MetadataViews.Royalties>():
					var royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serialId)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(url)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PublishedNFT.CollectionStoragePath, publicPath: PublishedNFT.CollectionPublicPath, publicCollection: Type<&PublishedNFT.Collection>(), publicLinkedType: Type<&PublishedNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PublishedNFT.createEmptyCollection(nftType: Type<@PublishedNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://publishednft.io/logo-desktop.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Published NFT Collection", description: "Published NFT is a blockchain eBook publishing platform built on the Flow blockchain, where authors can publish eBooks, Lyrics, Comics, Magazines, Articles, Poems, Recipes, Movie Scripts, Computer Language, etc.", externalURL: MetadataViews.ExternalURL("https://publishednft.io/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/publishednft/"), "discord": MetadataViews.ExternalURL("https://discord.gg/ct5RPudqpG"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/publishednft/"), "telegram": MetadataViews.ExternalURL("https://t.me/published_nft"), "reddit": MetadataViews.ExternalURL("https://www.reddit.com/user/PublishedNFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface PublishedNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPublishedNFT(id: UInt64): &PublishedNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PublishedNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PublishedNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @PublishedNFT.NFT
			let id: UInt64 = token.id
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowPublishedNFT(id: UInt64): &PublishedNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PublishedNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let publishedNFT = nft as! &PublishedNFT.NFT
			return publishedNFT as &{ViewResolver.Resolver}
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
	resource PublishedMinter{ 
		access(all)
		fun mintLibraryPass(_name: String, _ipfsLink: String): @PublishedNFT.NFT?{ 
			if PublishedNFT.libraryPassTotalSupply == 9999{ 
				return nil
			}
			let libraryPassNft <- create PublishedNFT.NFT(serialId: PublishedNFT.libraryPassTotalSupply, initID: PublishedNFT.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 1)
			emit PublishedMinted(id: PublishedNFT.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 1)
			PublishedNFT.totalSupply = PublishedNFT.totalSupply + 1 as UInt64
			PublishedNFT.libraryPassTotalSupply = PublishedNFT.libraryPassTotalSupply + 1 as UInt64
			return <-libraryPassNft
		}
		
		access(all)
		fun mintWillo(_name: String, _ipfsLink: String): @PublishedNFT.NFT?{ 
			if PublishedNFT.willoTotalSupply == 100{ 
				return nil
			}
			let willoNft <- create PublishedNFT.NFT(serialId: PublishedNFT.willoTotalSupply, initID: PublishedNFT.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 1)
			emit PublishedMinted(id: PublishedNFT.totalSupply, name: _name, ipfsLink: _ipfsLink, type: 2)
			PublishedNFT.totalSupply = PublishedNFT.totalSupply + 1 as UInt64
			PublishedNFT.willoTotalSupply = PublishedNFT.willoTotalSupply + 1 as UInt64
			return <-willoNft
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/publishedNFTCollection
		self.CollectionPublicPath = /public/publishedNFTCollection
		self.MinterPublishedPath = /storage/minterPublishedPath
		self.totalSupply = 0
		self.libraryPassTotalSupply = 0
		self.willoTotalSupply = 0
		self.account.storage.save(<-create PublishedMinter(), to: self.MinterPublishedPath)
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&PublishedNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
