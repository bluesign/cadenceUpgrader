//
// 88		88			   88									 88		   
// 88		88			   88									 88		   
// 88		88			   88									 88		   
// 88		88  8b,dPPYba,   88   ,adPPYba,  ,adPPYYba,  ,adPPYba,  88,dPPYba,   
// 88		88  88P'   `"8a  88  a8P_____88  ""	 `Y8  I8[	""  88P'	"8a  
// 88		88  88	   88  88  8PP"""""""  ,adPPPPP88   `"Y8ba,   88	   88  
// Y8a.	.a8P  88	   88  88  "8b,   ,aa  88,	,88  aa	]8I  88	   88  
//  `"Y8888Y"'   88	   88  88   `"Ybbd8"'  `"8bbdP"Y8  `"YbbdP"'  88	   88  
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Base64Util from "./Base64Util.cdc"

access(all)
contract Unleash: NonFungibleToken{ 
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
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let imageIpfsCids: [String]
	
	access(all)
	var baseAnimationUrl: String
	
	access(all)
	var ipfsGatewayUrl: String
	
	access(all)
	var arweaveGatewayUrl: String
	
	access(all)
	resource interface NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		access(all)
		fun getMessage(): String
		
		access(all)
		fun getImageNumber(): UInt8
		
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(all)
	resource NFT: NFTPublic, NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata:{ String: AnyStruct}
		
		access(contract)
		var message: String
		
		access(contract)
		var imageNumber: UInt8
		
		access(contract)
		var stashes: @[{NonFungibleToken.NFT}]
		
		init(){ 
			Unleash.totalSupply = Unleash.totalSupply + 1
			self.id = Unleash.totalSupply
			self.message = ""
			self.imageNumber = 0
			let currentBlock = getCurrentBlock()
			self.metadata ={ "mintedBlock": currentBlock.height, "mintedTime": currentBlock.timestamp}
			self.stashes <- []
		}
		
		access(all)
		fun getMessage(): String{ 
			return self.message
		}
		
		access(all)
		fun setMessage(message: String){ 
			self.message = message
		}
		
		access(all)
		fun getImageNumber(): UInt8{ 
			return self.imageNumber
		}
		
		access(all)
		fun setImageNumber(imageNumber: UInt8){ 
			pre{ 
				Int(imageNumber) < Unleash.imageIpfsCids.length:
					"Invalid image number"
			}
			self.imageNumber = imageNumber
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Unleash", description: "Digital memorabilia for Mercari's 10th anniversary.", thumbnail: MetadataViews.HTTPFile(url: Unleash.ipfsGatewayUrl.concat(Unleash.imageIpfsCids[self.imageNumber])))
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: "Unleash NFT Edition", number: self.id, max: Unleash.totalSupply)])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return nil
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://about.mercari.com/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Unleash.CollectionStoragePath, publicPath: Unleash.CollectionPublicPath, publicCollection: Type<&Unleash.Collection>(), publicLinkedType: Type<&Unleash.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Unleash.createEmptyCollection(nftType: Type<@Unleash.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: Unleash.ipfsGatewayUrl.concat(Unleash.imageIpfsCids[0])), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Unleash", description: "Digital memorabilia for Mercari's 10th anniversary.", externalURL: MetadataViews.ExternalURL("https://about.mercari.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/mercari_inc")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					traitsView.addTrait(MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil))
					traitsView.addTrait(MetadataViews.Trait(name: "animationUrl", value: self.getAnimationUrl(), displayType: nil, rarity: nil))
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun stash(token: @{NonFungibleToken.NFT}){ 
			self.stashes.insert(at: 0, <-token)
		}
		
		access(all)
		fun unstash(): @{NonFungibleToken.NFT}{ 
			return <-self.stashes.removeFirst()
		}
		
		access(self)
		fun getAnimationUrl(): String{ 
			var url = Unleash.baseAnimationUrl.concat("?image=").concat(self.imageNumber.toString()).concat("&message=").concat(Base64Util.encode(self.message))
			if Unleash.arweaveGatewayUrl != ""{ 
				url = url.concat("&arHost=").concat(Unleash.arweaveGatewayUrl)
			}
			return url
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface UnleashCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowUnleashPublic(id: UInt64): &{Unleash.NFTPublic}?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Unleash reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: UnleashCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Unleash.NFT
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
		fun borrowUnleashPublic(id: UInt64): &{Unleash.NFTPublic}?{ 
			if self.ownedNFTs[id] != nil{ 
				return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? as! &{Unleash.NFTPublic}?
			}
			return nil
		}
		
		access(all)
		fun borrowUnleash(id: UInt64): &Unleash.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? as! &Unleash.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &Unleash.NFT
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
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mint(): @Unleash.NFT{ 
			return <-create NFT()
		}
		
		access(all)
		fun setBaseAnimationUrl(baseAnimationUrl: String){ 
			Unleash.baseAnimationUrl = baseAnimationUrl
		}
		
		access(all)
		fun setIpfsGatewayUrl(ipfsGatewayUrl: String){ 
			Unleash.ipfsGatewayUrl = ipfsGatewayUrl
		}
		
		access(all)
		fun setArweaveGatewayUrl(arweaveGatewayUrl: String){ 
			Unleash.arweaveGatewayUrl = arweaveGatewayUrl
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.imageIpfsCids = ["bafkreiecrru5wuz7fbaui3bjc3ywry2itor2pjqywjajtbrmithxgcnvzu", // Unleash Logo																							 
																							 "bafkreifj3peaxpqlhyt2plpep4rceulmx3dqajlxdeyvrra2djnorvod7m"] // Unleash Key Visual
		
		self.baseAnimationUrl = "https://arweave.net/gxvwaKEi_GtRlgxoGA0wT8g_IGZ8dYxKKiBgSGDThgY"
		self.ipfsGatewayUrl = "https://nftstorage.link/ipfs/"
		self.arweaveGatewayUrl = ""
		self.CollectionStoragePath = /storage/UnleashCollection
		self.CollectionPublicPath = /public/UnleashCollection
		self.CollectionPrivatePath = /private/UnleashCollection
		self.MinterStoragePath = /storage/UnleashMinter
		self.account.storage.save(<-create Minter(), to: self.MinterStoragePath)
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Unleash.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
