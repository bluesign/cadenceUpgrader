import Crypto

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import IPackNFT from "../0x18ddf0823a55a0ee/IPackNFT.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract PackNFT: NonFungibleToken, IPackNFT{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let version: String
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionIPackNFTPublicPath: PublicPath
	
	access(all)
	let OperatorStoragePath: StoragePath
	
	access(all)
	let OperatorPrivPath: PrivatePath
	
	// representation of the NFT in this contract to keep track of states
	access(contract)
	let packs: @{UInt64: Pack}
	
	access(all)
	event RevealRequest(id: UInt64, openRequest: Bool)
	
	access(all)
	event OpenRequest(id: UInt64)
	
	access(all)
	event Revealed(id: UInt64, salt: [UInt8], nfts: String)
	
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	event Minted(id: UInt64, hash: [UInt8], distId: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	enum Status: UInt8{ 
		access(all)
		case Sealed
		
		access(all)
		case Revealed
		
		access(all)
		case Opened
	}
	
	access(all)
	resource PackNFTOperator: IPackNFT.IOperator{ 
		access(all)
		fun mint(distId: UInt64, commitHash: String, issuer: Address): @NFT{ 
			let nft <- create NFT(commitHash: commitHash, issuer: issuer)
			PackNFT.totalSupply = PackNFT.totalSupply + 1
			let p <- create Pack(commitHash: commitHash, issuer: issuer)
			PackNFT.packs[nft.id] <-! p
			emit Minted(id: nft.id, hash: commitHash.decodeHex(), distId: distId)
			return <-nft
		}
		
		access(all)
		fun reveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String){ 
			let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
			p.reveal(id: id, nfts: nfts, salt: salt)
			PackNFT.packs[id] <-! p
		}
		
		access(all)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}]){ 
			let p <- PackNFT.packs.remove(key: id) ?? panic("no such pack")
			p.open(id: id, nfts: nfts)
			PackNFT.packs[id] <-! p
		}
		
		init(){} 
	}
	
	access(all)
	resource Pack{ 
		access(all)
		let hash: [UInt8]
		
		access(all)
		let issuer: Address
		
		access(all)
		var status: PackNFT.Status
		
		access(all)
		var salt: [UInt8]?
		
		access(all)
		fun verify(nftString: String): Bool{ 
			assert(self.status != PackNFT.Status.Sealed, message: "Pack not revealed yet")
			var hashString = String.encodeHex(self.salt!)
			hashString = hashString.concat(",").concat(nftString)
			let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
			assert(String.encodeHex(self.hash) == String.encodeHex(hash), message: "CommitHash was not verified")
			return true
		}
		
		access(self)
		fun _verify(nfts: [{IPackNFT.Collectible}], salt: String, commitHash: String): String{ 
			var hashString = salt
			var nftString = nfts[0].hashString()
			var i = 1
			while i < nfts.length{ 
				let s = nfts[i].hashString()
				nftString = nftString.concat(",").concat(s)
				i = i + 1
			}
			hashString = hashString.concat(",").concat(nftString)
			let hash = HashAlgorithm.SHA2_256.hash(hashString.utf8)
			assert(String.encodeHex(self.hash) == String.encodeHex(hash), message: "CommitHash was not verified")
			return nftString
		}
		
		access(contract)
		fun reveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String){ 
			assert(self.status == PackNFT.Status.Sealed, message: "Pack status is not Sealed")
			let v = self._verify(nfts: nfts, salt: salt, commitHash: String.encodeHex(self.hash))
			self.salt = salt.decodeHex()
			self.status = PackNFT.Status.Revealed
			emit Revealed(id: id, salt: salt.decodeHex(), nfts: v)
		}
		
		access(contract)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}]){ 
			assert(self.status == PackNFT.Status.Revealed, message: "Pack status is not Revealed")
			self._verify(nfts: nfts, salt: String.encodeHex(self.salt!), commitHash: String.encodeHex(self.hash))
			self.status = PackNFT.Status.Opened
			emit Opened(id: id)
		}
		
		init(commitHash: String, issuer: Address){ 
			self.hash = commitHash.decodeHex()
			self.issuer = issuer
			self.status = PackNFT.Status.Sealed
			self.salt = nil
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, IPackNFT.IPackNFTToken, IPackNFT.IPackNFTOwnerOperator, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let hash: [UInt8]
		
		access(all)
		let issuer: Address
		
		access(all)
		fun reveal(openRequest: Bool){ 
			PackNFT.revealRequest(id: self.id, openRequest: openRequest)
		}
		
		access(all)
		fun open(){ 
			PackNFT.openRequest(id: self.id)
		}
		
		init(commitHash: String, issuer: Address){ 
			self.id = self.uuid
			self.hash = commitHash.decodeHex()
			self.issuer = issuer
		}
		
		// All supported metadata views for the Moment including the Core NFT Views
		//
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "NBA Top Shot Pack", description: "Reveals official NBA Top Shot Moments when opened", thumbnail: MetadataViews.HTTPFile(url: self.getImage(imageType: "image", format: "jpeg", width: 256)))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://nbatopshot.com/packnfts/".concat(self.id.toString())) // might have to make a URL that redirects to packs page based on packNFT id -> distribution id
				
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.getImage(imageType: "image", format: "jpeg", width: 512)), mediaType: "image/jpeg")])
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PackNFT.CollectionStoragePath, publicPath: PackNFT.CollectionPublicPath, publicCollection: Type<&PackNFT.Collection>(), publicLinkedType: Type<&PackNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PackNFT.createEmptyCollection(nftType: Type<@PackNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nbatopshot.com/static/img/top-shot-logo-horizontal-white.svg"), mediaType: "image/svg+xml")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://nbatopshot.com/static/img/og/og.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "NBA-Top-Shot-Packs", description: "NBA Top Shot is your chance to own, sell, and trade official digital collectibles of the NBA and WNBA's greatest plays and players", externalURL: MetadataViews.ExternalURL("https://nbatopshot.com/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/nbatopshot"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/nbatopshot"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/nbatopshot")})
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver: Capability<&{FungibleToken.Receiver}> = getAccount(0xfaf0cc52c6e3acaf).capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver, cut: 0.05, description: "NBA Top Shot marketplace royalty")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
			}
			return nil
		}
		
		access(all)
		fun assetPath(): String{ 
			// this path is normative -> it does not yet have pack related assets here
			return "https://media.nbatopshot.com/packnfts/".concat(self.id.toString()).concat("/media/")
		}
		
		access(all)
		fun getImage(imageType: String, format: String, width: Int): String{ 
			return self.assetPath().concat(imageType).concat("?format=").concat(format).concat("&width=").concat(width.toString())
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, IPackNFT.IPackNFTCollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @PackNFT.NFT
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
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &PackNFT.NFT
			return packNFT as &{ViewResolver.Resolver}
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowPackNFT(id: UInt64): &{IPackNFT.NFT}?{ 
			let nft <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
			let token <- nft as! @PackNFT.NFT
			let ref = &token as &PackNFT.NFT
			self.ownedNFTs[id] <-! token as! @PackNFT.NFT
			return ref
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
	
	access(contract)
	fun revealRequest(id: UInt64, openRequest: Bool){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		assert(p.status == PackNFT.Status.Sealed, message: "Pack status must be Sealed for reveal request")
		emit RevealRequest(id: id, openRequest: openRequest)
	}
	
	access(contract)
	fun openRequest(id: UInt64){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		assert(p.status == PackNFT.Status.Revealed, message: "Pack status must be Revealed for open request")
		emit OpenRequest(id: id)
	}
	
	access(all)
	fun publicReveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String){ 
		let p = PackNFT.borrowPackRepresentation(id: id) ?? panic("No such pack")
		p.reveal(id: id, nfts: nfts, salt: salt)
	}
	
	access(all)
	fun borrowPackRepresentation(id: UInt64): &Pack?{ 
		return (&self.packs[id] as &Pack?)!
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(CollectionStoragePath: StoragePath, CollectionPublicPath: PublicPath, CollectionIPackNFTPublicPath: PublicPath, OperatorStoragePath: StoragePath, OperatorPrivPath: PrivatePath, version: String){ 
		self.totalSupply = 0
		self.packs <-{} 
		self.CollectionStoragePath = CollectionStoragePath
		self.CollectionPublicPath = CollectionPublicPath
		self.CollectionIPackNFTPublicPath = CollectionIPackNFTPublicPath
		self.OperatorStoragePath = OperatorStoragePath
		self.OperatorPrivPath = OperatorPrivPath
		self.version = version
		
		// Create a collection to receive Pack NFTs
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionIPackNFTPublicPath)
		
		// Create a operator to share mint capability with proxy
		let operator <- create PackNFTOperator()
		self.account.storage.save(<-operator, to: self.OperatorStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&PackNFTOperator>(self.OperatorStoragePath)
		self.account.capabilities.publish(capability_3, at: self.OperatorPrivPath)
	}
}
