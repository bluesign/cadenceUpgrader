import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Crypto

access(all)
contract GaiaPackNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event SeriesAdded(id: UInt64, name: String)
	
	access(all)
	event Mint(id: UInt64, commitHash: String, seriesID: UInt64)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event RequestedReveal(id: UInt64, shouldOpen: Bool)
	
	access(all)
	event Revealed(id: UInt64, contents: [String], salt: String)
	
	access(all)
	event RequestedOpen(id: UInt64)
	
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let OwnerStoragePath: StoragePath
	
	// Total supply for all Gaia Pack NFTs - regardless of series.
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var collectionDisplay: MetadataViews.NFTCollectionDisplay
	
	access(contract)
	fun setCollectionDisplay(collectionDisplay: MetadataViews.NFTCollectionDisplay){ 
		self.collectionDisplay = collectionDisplay
	}
	
	access(all)
	var royalties: MetadataViews.Royalties?
	
	access(contract)
	fun setRoyalties(_ royalties: MetadataViews.Royalties?){ 
		self.royalties = royalties
	}
	
	access(all)
	struct PackDisplay{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let altThumbnail:{ MetadataViews.File} // after pack was opened
		
		
		access(all)
		let video:{ MetadataViews.File}?
		
		init(name: String, description: String, thumbnail:{ MetadataViews.File}, altThumbnail:{ MetadataViews.File}, video:{ MetadataViews.File}?){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.altThumbnail = altThumbnail
			self.video = video
		}
	}
	
	// Similar to a set, a series is a grouping of Pack NFTs.
	access(all)
	struct Series{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(contract)
		fun setName(name: String){ 
			self.name = name
		}
		
		access(all)
		var description: String
		
		access(contract)
		fun setDescription(description: String){ 
			self.description = description
		}
		
		// MetadataViews Display for Pack NFT
		access(all)
		var packDisplay: GaiaPackNFT.PackDisplay
		
		access(contract)
		fun setPackDisplay(packDisplay: GaiaPackNFT.PackDisplay){ 
			self.packDisplay = packDisplay
		}
		
		// Current supply of NFTs in series
		access(all)
		var totalSupply: UInt64
		
		// Max supply of NFTs in series
		access(all)
		let maxSupply: UInt64?
		
		access(contract)
		fun mintNFT(id: UInt64, commitHash: String): @{NonFungibleToken.NFT}{ 
			if self.maxSupply != nil{ 
				assert(self.totalSupply < self.maxSupply!, message: "Max supply has already been reached.")
			}
			return <-GaiaPackNFT.mintNFT(id: id, commitHash: commitHash, seriesID: self.id)
		}
		
		init(id: UInt64, name: String, description: String, packDisplay: GaiaPackNFT.PackDisplay, maxSupply: UInt64?){ 
			self.id = id
			self.packDisplay = packDisplay
			self.name = name
			self.description = description
			self.totalSupply = 0
			self.maxSupply = maxSupply
		}
	}
	
	// Centralized mapping of unique id to series
	access(contract)
	let series:{ UInt64: Series}
	
	access(all)
	view fun getSeries(id: UInt64): &Series?{ 
		return &self.series[id] as &Series?
	}
	
	access(contract)
	fun addSeries(series: Series){ 
		pre{ 
			GaiaPackNFT.getSeries(id: series.id) == nil:
				"Series already exists with ID ".concat(series.id.toString())
		}
		GaiaPackNFT.series[series.id] = series
		emit GaiaPackNFT.SeriesAdded(id: series.id, name: series.name)
	}
	
	access(all)
	enum PackStatus: UInt8{ 
		access(all)
		case Sealed
		
		access(all)
		case RevealRequested
		
		access(all)
		case Revealed
		
		access(all)
		case OpenRequested
		
		access(all)
		case Opened
	}
	
	access(all)
	struct PackNFTView{ 
		access(all)
		let seriesID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		access(all)
		let altThumbnail:{ MetadataViews.File} // after pack was opened
		
		
		access(all)
		let video:{ MetadataViews.File}?
		
		init(seriesID: UInt64, name: String, description: String, thumbnail:{ MetadataViews.File}, altThumbnail:{ MetadataViews.File}, video:{ MetadataViews.File}?){ 
			self.seriesID = seriesID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.altThumbnail = altThumbnail
			self.video = video
		}
	}
	
	access(all)
	struct PackState{ 
		// SHA3_256 hash encoded pack contents and salt.
		access(all)
		let commitHash: String
		
		// ID of the series that the pack belongs to.
		access(all)
		let seriesID: UInt64
		
		// NFT identifiers comprising pack contents to be revealed as part of pack opening process.
		access(all)
		var contents: [String]?
		
		// Salt to be revealed as part of pack opening process.
		access(all)
		var salt: String?
		
		access(all)
		var status: GaiaPackNFT.PackStatus
		
		access(contract)
		fun setStatus(status: GaiaPackNFT.PackStatus){ 
			self.status = status
		}
		
		// Pack contents receiver capability, a collection to receive the NFTs when pack is opened.
		// Specified by the pack owner.
		access(self)
		var receiverCap: Capability<&{NonFungibleToken.Receiver}>?
		
		access(contract)
		fun setReceiverCap(cap: Capability<&{NonFungibleToken.Receiver}>){ 
			self.receiverCap = cap
		}
		
		// Hashing helper function.
		access(self)
		view fun h(_ s: [UInt8]): [UInt8]{ 
			return HashAlgorithm.SHA3_256.hash(s)
		}
		
		// Verify that commit hash matches token identifiers and salt.
		access(all)
		view fun verify(_ contents: [String], _ salt: String): Bool{ 
			var hash = self.h(salt.utf8)
			for i in contents{ 
				hash.appendAll(self.h(i.utf8))
			}
			hash = self.h(String.encodeHex(hash).utf8)
			return self.commitHash == String.encodeHex(hash)
		}
		
		// Once a reveal is requested, packs can be revealed by anyone with the correct nft identifiers and salt.
		access(all)
		fun reveal(id: UInt64, contents: [String], salt: String){ 
			pre{ 
				self.status == PackStatus.RevealRequested:
					"Pack status must be \"RevealRequested\""
			}
			self._reveal(id, contents, salt)
		}
		
		access(contract)
		fun _reveal(_ id: UInt64, _ contents: [String], _ salt: String){ 
			pre{ 
				self.contents == nil && self.salt == nil:
					"Contents and Salt already revealed."
				self.verify(contents, salt):
					"Invalid contents or salt."
			}
			self.contents = contents
			self.salt = salt
			self.setStatus(status: PackStatus.Revealed)
			emit Revealed(id: id, contents: contents, salt: salt)
		}
		
		access(self)
		fun getNFTIdentifier(_ nftRef: &{NonFungibleToken.NFT}): String{ 
			return nftRef.getType().identifier.concat(".").concat(nftRef.id.toString())
		}
		
		// Once a pack open is requested, it can be opened by anyone with the correct NFTs.
		// Packs will be revealed when opened if they aren't already.
		access(all)
		fun open(id: UInt64, nfts: @[{NonFungibleToken.NFT}], salt: String?){ 
			pre{ 
				self.status == PackStatus.OpenRequested:
					"Pack status must be \"OpenRequested\""
				self.receiverCap != nil:
					"Missing receiver capability."
			}
			let receiverRef = (self.receiverCap!).borrow() ?? panic("Invalid receiver capability")
			
			// deposit tokens into receiver and record nft identifiers
			let nftIdentifers: [String] = []
			while nfts.length > 0{ 
				let nft <- nfts.remove(at: 0)
				let nftIdentifier = self.getNFTIdentifier(&nft as &{NonFungibleToken.NFT})
				nftIdentifers.append(nftIdentifier)
				receiverRef.deposit(token: <-nft)
			}
			
			// reveal pack if needed
			if self.contents == nil || self.salt == nil{ 
				assert(salt != nil, message: "Missing salt")
				self._reveal(id, nftIdentifers, salt!)
			}
			
			// verify that correct nfts were distributed
			for nftIdentifier in nftIdentifers{ 
				assert((self.contents!).contains(nftIdentifier), message: nftIdentifier.concat(" not included in contents."))
			}
			destroy nfts
			self.setStatus(status: PackStatus.Opened)
			emit Opened(id: id)
		}
		
		init(commitHash: String, seriesID: UInt64){ 
			self.commitHash = commitHash
			self.status = PackStatus.Sealed
			self.salt = nil
			self.receiverCap = nil
			self.seriesID = seriesID
			self.contents = nil
		}
	}
	
	// Mapping of pack nft id to pack.
	access(contract)
	let packStates:{ UInt64: PackState}
	
	access(all)
	view fun getPackState(nftID: UInt64): &PackState?{ 
		return &self.packStates[nftID] as &PackState?
	}
	
	access(contract)
	fun addPackState(nftID: UInt64, commitHash: String, seriesID: UInt64){ 
		pre{ 
			GaiaPackNFT.getPackState(nftID: nftID) == nil:
				"Pack State already exists with ID ".concat(nftID.toString())
		}
		GaiaPackNFT.packStates[nftID] = PackState(commitHash: commitHash, seriesID: seriesID)
	}
	
	// Pack NFT publicly accessible fields/methods.
	access(all)
	resource interface PackNFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun state(): &GaiaPackNFT.PackState
	}
	
	// Exclusive owner accessible fields/methods.
	access(all)
	resource interface PackNFTOwner{ 
		access(all)
		fun requestReveal(shouldOpen: Bool, receiverCap: Capability<&{NonFungibleToken.Receiver}>?)
		
		access(all)
		fun requestOpen(receiverCap: Capability<&{NonFungibleToken.Receiver}>)
		
		access(all)
		fun setReceiverCap(receiverCap: Capability<&{NonFungibleToken.Receiver}>)
	}
	
	// NFT "packs" can be revealed and then redeemed in exchange for associated nfts.
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, PackNFTPublic, PackNFTOwner{ 
		access(all)
		let id: UInt64
		
		access(all)
		fun state(): &GaiaPackNFT.PackState{ 
			return GaiaPackNFT.getPackState(nftID: self.id)!
		}
		
		access(all)
		fun series(): &GaiaPackNFT.Series{ 
			return GaiaPackNFT.getSeries(id: self.state().seriesID)!
		}
		
		access(all)
		fun setReceiverCap(receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			GaiaPackNFT.setReceiverCap(nftID: self.id, receiverCap: receiverCap)
		}
		
		access(all)
		fun requestReveal(shouldOpen: Bool, receiverCap: Capability<&{NonFungibleToken.Receiver}>?){ 
			GaiaPackNFT.requestReveal(nftID: self.id, shouldOpen: shouldOpen, receiverCap: receiverCap)
		}
		
		// Request pack open. If a pack owner calls requestReveal() and shouldOpen is true, a transactor will
		// reveal and open the pack. Meaning, an existing reveal capability cannot be updated in this txn.
		access(all)
		fun requestOpen(receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			GaiaPackNFT.requestOpen(nftID: self.id, receiverCap: receiverCap)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<PackNFTView>(), Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let series = self.series()
			switch view{ 
				case Type<PackNFTView>():
					return PackNFTView(seriesID: series.id, name: series.packDisplay.name, description: series.packDisplay.description, thumbnail: *series.packDisplay.thumbnail, altThumbnail: *series.packDisplay.altThumbnail, video: *series.packDisplay.video)
				case Type<MetadataViews.NFTView>():
					let viewResolver = &self as &{ViewResolver.Resolver}
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
				case Type<MetadataViews.Display>():
					var thumbnail = series.packDisplay.thumbnail
					if self.state().status == GaiaPackNFT.PackStatus.Opened{ 
						thumbnail = series.packDisplay.altThumbnail
					}
					return MetadataViews.Display(name: series.packDisplay.name, description: series.packDisplay.description, thumbnail: *thumbnail)
				case Type<MetadataViews.ExternalURL>():
					return GaiaPackNFT.collectionDisplay.externalURL
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: GaiaPackNFT.CollectionStoragePath, publicPath: GaiaPackNFT.CollectionPublicPath, publicCollection: Type<@GaiaPackNFT.Collection>(), publicLinkedType: Type<&GaiaPackNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-GaiaPackNFT.createEmptyCollection(nftType: Type<@GaiaPackNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return GaiaPackNFT.collectionDisplay
				case Type<MetadataViews.Royalties>():
					return GaiaPackNFT.royalties
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64){ 
			self.id = id
		}
	}
	
	access(contract)
	fun mintNFT(id: UInt64, commitHash: String, seriesID: UInt64): @{NonFungibleToken.NFT}{ 
		// save pack state to contract
		GaiaPackNFT.addPackState(nftID: id, commitHash: commitHash, seriesID: seriesID)
		
		// mint new pack nft
		let mint <- create NFT(id: id)
		GaiaPackNFT.totalSupply = GaiaPackNFT.totalSupply + 1
		emit Mint(id: mint.id, commitHash: commitHash, seriesID: seriesID)
		return <-mint
	}
	
	access(contract)
	fun setReceiverCap(nftID: UInt64, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
		pre{ 
			receiverCap.check():
				"Invalid receiver capability."
		}
		let packState = self.getPackState(nftID: nftID)!
		packState.setReceiverCap(cap: receiverCap)
	}
	
	// If should open, pack status will be "OpenRequested"
	access(contract)
	fun requestReveal(nftID: UInt64, shouldOpen: Bool, receiverCap: Capability<&{NonFungibleToken.Receiver}>?){ 
		let packState = self.getPackState(nftID: nftID)!
		assert(packState.status == GaiaPackNFT.PackStatus.Sealed, message: "Status must be \"Sealed\"")
		
		// receiver cap is ignored if pack is not to be opened
		if shouldOpen{ 
			assert(receiverCap != nil, message: "Missing receiver capability")
			self._requestOpen(packState, receiverCap!)
			emit RequestedOpen(id: nftID)
			return
		}
		packState.setStatus(status: GaiaPackNFT.PackStatus.RevealRequested)
		emit RequestedReveal(id: nftID, shouldOpen: shouldOpen)
	}
	
	// Contract owner may reveal pack contents if absolutely necessary to do so.
	access(contract)
	fun ownerReveal(nftID: UInt64, contents: [String], salt: String){ 
		let packState = GaiaPackNFT.getPackState(nftID: nftID) ?? panic("Missing pack state")
		assert(packState.status == GaiaPackNFT.PackStatus.Sealed, message: "Status must be \"Sealed\"")
		packState._reveal(nftID, contents, salt)
	}
	
	access(contract)
	fun requestOpen(nftID: UInt64, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
		let packState = self.getPackState(nftID: nftID)!
		assert(packState.status == GaiaPackNFT.PackStatus.Revealed, message: "Status must be \"Revealed\"")
		self._requestOpen(packState, receiverCap)
		emit RequestedOpen(id: nftID)
	}
	
	access(contract)
	fun _requestOpen(_ packState: &GaiaPackNFT.PackState, _ receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
		pre{ 
			receiverCap.check():
				"Invalid receiver capability."
		}
		packState.setReceiverCap(cap: receiverCap)
		packState.setStatus(status: GaiaPackNFT.PackStatus.OpenRequested)
	}
	
	access(all)
	resource interface CollectionOwner{ 
		access(all)
		fun borrowGaiaPackNFT(id: UInt64): &GaiaPackNFT.NFT
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
		fun borrowGaiaPackNFTPublic(id: UInt64): &GaiaPackNFT.NFT
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let gaiaPackNFT = nft as! &GaiaPackNFT.NFT
			return gaiaPackNFT as &{ViewResolver.Resolver}
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT with ID ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GaiaPackNFT.NFT
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
		
		// Public references of NFT are restricted
		access(all)
		fun borrowGaiaPackNFTPublic(id: UInt64): &GaiaPackNFT.NFT{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"NFT does not exist in collection."
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &GaiaPackNFT.NFT
		}
		
		// Only collection owner can borrow an unrestricted reference to GaiaPackNFT
		access(all)
		fun borrowGaiaPackNFT(id: UInt64): &GaiaPackNFT.NFT{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"NFT does not exist in collection."
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &GaiaPackNFT.NFT
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Minter{ 
		access(all)
		fun mint(id: UInt64, commitHash: String, seriesID: UInt64): @{NonFungibleToken.NFT}{ 
			let series = GaiaPackNFT.getSeries(id: seriesID) ?? panic("Missing series with ID ".concat(seriesID.toString()))
			return <-series.mintNFT(id: id, commitHash: commitHash)
		}
	}
	
	access(all)
	resource interface Operator{ 
		access(all)
		fun createMinter(): @Minter
		
		access(all)
		fun addSeries(id: UInt64, name: String, description: String, packDisplay: GaiaPackNFT.PackDisplay, maxSupply: UInt64?)
		
		access(all)
		fun reveal(nftID: UInt64, contents: [String], salt: String)
	}
	
	access(all)
	resource Owner: Operator{ 
		access(all)
		fun createMinter(): @Minter{ 
			return <-create Minter()
		}
		
		access(all)
		fun addSeries(id: UInt64, name: String, description: String, packDisplay: GaiaPackNFT.PackDisplay, maxSupply: UInt64?){ 
			let series = GaiaPackNFT.Series(id: id, name: name, description: description, packDisplay: packDisplay, maxSupply: maxSupply)
			GaiaPackNFT.addSeries(series: series)
		}
		
		access(all)
		fun reveal(nftID: UInt64, contents: [String], salt: String){ 
			GaiaPackNFT.ownerReveal(nftID: nftID, contents: contents, salt: salt)
		}
		
		access(all)
		fun setCollectionDisplay(collectionDisplay: MetadataViews.NFTCollectionDisplay){ 
			GaiaPackNFT.collectionDisplay = collectionDisplay
		}
		
		access(all)
		fun setRoyalties(royalties: MetadataViews.Royalties?){ 
			GaiaPackNFT.royalties = royalties
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/GaiaPackNFTCollection002
		self.CollectionPublicPath = /public/GaiaPackNFTCollection002
		self.CollectionPrivatePath = /private/GaiaPackNFTCollection002
		self.OwnerStoragePath = /storage/GaiaPackNFTAuthorizer
		self.packStates ={} 
		self.series ={} 
		self.totalSupply = 0
		self.royalties = MetadataViews.Royalties([])
		self.collectionDisplay = MetadataViews.NFTCollectionDisplay(name: "Gaia Packs", description: "Gaia Pack NFTs on the Flow Blockchain", externalURL: MetadataViews.ExternalURL("https://ongaia.com/"), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmdV7UDXCjTj5hVxrLsETwBbp4cHQwUG1m6GfEpotW7wHf", path: "elements-icon.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "Qmdd43Z3AjLtirHnLk2XbE8XruBg2fCoHoyYpNWhAhGqMb", path: "elements-banner.png"), mediaType: "image/png"), socials:{} )
		let collection <- self.createEmptyCollection(nftType: Type<@Collection>())
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPrivatePath)
		let owner <- create Owner()
		self.account.storage.save(<-owner, to: self.OwnerStoragePath)
		emit ContractInitialized()
	}
}
