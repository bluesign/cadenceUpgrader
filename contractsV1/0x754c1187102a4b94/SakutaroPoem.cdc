//
//  _____		 _			_
// /  ___|	   | |		  | |
// \ `--.   __ _ | | __ _   _ | |_   __ _  _ __   ___
//  `--. \ / _` || |/ /| | | || __| / _` || '__| / _ \
// /\__/ /| (_| ||   < | |_| || |_ | (_| || |   | (_) |
// \____/  \__,_||_|\_\ \__,_| \__| \__,_||_|	\___/
//
//
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import SakutaroPoemContent from "./SakutaroPoemContent.cdc"

access(all)
contract SakutaroPoem: NonFungibleToken{ 
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(self)
	var royalties: [MetadataViews.Royalty]
	
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
	struct SakutaroPoemMetadataView{ 
		access(all)
		let poemID: UInt32?
		
		access(all)
		let name: String?
		
		access(all)
		let description: String?
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let svg: String?
		
		access(all)
		let svgBase64: String?
		
		access(all)
		let license: String
		
		access(all)
		let creator: String
		
		init(poemID: UInt32?, name: String?, description: String?, thumbnail:{ MetadataViews.File}, svg: String?, svgBase64: String?, license: String, creator: String){ 
			self.poemID = poemID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.svg = svg
			self.svgBase64 = svgBase64
			self.license = license
			self.creator = creator
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
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<SakutaroPoemMetadataView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let poem = self.getPoem()
					return MetadataViews.Display(name: poem?.title ?? SakutaroPoemContent.name, description: SakutaroPoemContent.description, thumbnail: MetadataViews.IPFSFile(cid: poem?.ipfsCid ?? "", path: nil))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(SakutaroPoem.royalties)
				case Type<SakutaroPoemMetadataView>():
					let poem = self.getPoem()
					return SakutaroPoemMetadataView(poemID: self.getPoemID() ?? 0, name: poem?.title ?? SakutaroPoemContent.name, description: SakutaroPoemContent.description, thumbnail: MetadataViews.IPFSFile(cid: poem?.ipfsCid ?? "", path: nil), svg: poem?.getSvg(), svgBase64: poem?.getSvgBase64(), license: "CC-BY 4.0", creator: "Ara")
			}
			return nil
		}
		
		access(all)
		fun getPoemID(): UInt32?{ 
			if self.owner == nil{ 
				return nil
			}
			var num: UInt32 = 0
			var val = (self.owner!).address.toBytes()
			for v in val{ 
				num = num + UInt32(v)
			}
			return num % 39
		}
		
		access(all)
		fun getPoem(): SakutaroPoemContent.Poem?{ 
			let poemID = self.getPoemID()
			if poemID == nil{ 
				return nil
			}
			return SakutaroPoemContent.getPoem(poemID!)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SakutaroPoemCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPoem(id: UInt64): &SakutaroPoem.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Poem reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: SakutaroPoemCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @SakutaroPoem.NFT
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
		fun borrowPoem(id: UInt64): &SakutaroPoem.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &SakutaroPoem.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return nft as! &SakutaroPoem.NFT
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
	fun mintNFT(): @NFT{ 
		pre{ 
			SakutaroPoem.totalSupply < 39:
				"Can't mint any more"
		}
		SakutaroPoem.totalSupply = SakutaroPoem.totalSupply + 1
		let token <- create NFT(id: SakutaroPoem.totalSupply)
		emit Mint(id: token.id)
		return <-token
	}
	
	access(all)
	fun getRoyalties(): MetadataViews.Royalties{ 
		return MetadataViews.Royalties(SakutaroPoem.royalties)
	}
	
	init(){ 
		self.CollectionPublicPath = /public/SakutaroPoemCollection
		self.CollectionStoragePath = /storage/SakutaroPoemCollection
		self.totalSupply = 0
		let recepient = self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
		self.royalties = [MetadataViews.Royalty(receiver: recepient, cut: 0.1, description: "39")]
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SakutaroPoem.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
