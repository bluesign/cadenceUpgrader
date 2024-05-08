// What makes an NFT an NFT?
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TheNFT: NonFungibleToken{ 
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var baseUrl: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	struct TextPlain{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		fun data(): String{ 
			return "data:text/plain,%23".concat(self.id.toString())
		}
	}
	
	access(all)
	struct TextHtml{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		fun data(): String{ 
			return "data:text/html,%3C%21DOCTYPE%20html%3E%3Chtml%3E%3Cdiv%20style%3D%22display%3A%20flex%3B%20justify-content%3A%20center%3B%20align-items%3A%20center%3B%20height%3A%20100vh%3B%22%3E%3Ch1%3E%23".concat(self.id.toString()).concat("%3C%2Fh1%3E%3C%2Fdiv%3E%3C%2Fhtml%3E")
		}
	}
	
	access(all)
	struct ImageSvg{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		fun data(): String{ 
			return "data:image/svg+xml;charset=utf8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20100%22%3E%0D%0A%3Crect%20x%3D%220%22%20y%3D%220%22%20width%3D%22100%22%20height%3D%22100%22%20fill%3D%22%23000000%22%20%2F%3E%0D%0A%3Ctext%20x%3D%2250%25%22%20y%3D%2250%25%22%20text-anchor%3D%22middle%22%20dominant-baseline%3D%22central%22%20fill%3D%22%23ffffff%22%3E%0D%0A%23".concat(self.id.toString()).concat("%0D%0A%3C%2Ftext%3E%3C%2Fsvg%3E%0D%0A")
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(id: UInt64){ 
			self.id = id
		}
		
		access(all)
		fun whatAreYou(): String{ 
			return self.id.toString()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<TextPlain>(), Type<TextHtml>(), Type<ImageSvg>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "#".concat(self.id.toString()), description: "The NFT", thumbnail: MetadataViews.HTTPFile(url: TheNFT.baseUrl.concat(self.id.toString())))
				case Type<TextPlain>():
					return TextPlain(id: self.id).data()
				case Type<TextHtml>():
					return TextHtml(id: self.id).data()
				case Type<ImageSvg>():
					return ImageSvg(id: self.id).data()
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface TheNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTheNFT(id: UInt64): &TheNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow TheNFT reference"
			}
		}
	}
	
	access(all)
	resource Collection: TheNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TheNFT.NFT
			let id: UInt64 = token.id
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
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
		fun borrowTheNFT(id: UInt64): &TheNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &TheNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &TheNFT.NFT
			return nft as &{ViewResolver.Resolver}
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
	resource Maintainer{ 
		access(all)
		fun setBaseUrl(url: String){ 
			TheNFT.baseUrl = url
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun mintNFT(): @NFT{ 
		TheNFT.totalSupply = TheNFT.totalSupply + 1
		emit Mint(id: TheNFT.totalSupply)
		return <-create NFT(id: TheNFT.totalSupply)
	}
	
	init(){ 
		self.CollectionPublicPath = /public/TheNFTCollection
		self.CollectionStoragePath = /storage/TheNFTCollection
		self.totalSupply = 0
		self.baseUrl = ""
		self.account.storage.save(<-create Maintainer(), to: /storage/TheNFTMaintainer)
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&TheNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
