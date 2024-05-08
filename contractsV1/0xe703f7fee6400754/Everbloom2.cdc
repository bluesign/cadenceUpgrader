// SPDX-License-Identifier: MIT
/*
	Description: Central Smart Contract for Everbloom2
	Authors: Shehryar Shoukat shehryar@everbloom.app

	This contract contains the core functionality of Everbloom2 DApp

	The contract manages the data associated with all the galleries, and
	artworks that are used as templates for the Print NFTs.

	First, the user will create a "User" resource instance and will store
	it in user storage. User resource needs minter resource capability to
	mint an NFT. Users can request minting capability from admin.

	User resource can create multiple gallery resources and store in user
	resource object. Gallery resource allows users to create multiple Artworks

	NFTs are grouped by artworks. Artwork contains metadata related to prints.
	Artwork can be marked as locked, which will prevent further minting of
	NFTs under the artwork.

	Admin resource can create a new admin and minter resource. The minter
	resource will be saved in admin storage to share private capability.
	Only minter resources can mint an NFT.

	The user resource can mint an NFT if it has a minting capability.
	Minting a "print" requires gallery, and artwork.

	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import EverbloomMetadata from "./EverbloomMetadata.cdc"

access(all)
contract Everbloom2: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// Everbloom2 contract Events
	// -----------------------------------------------------------------------
	// Emitted when the Everbloom2 contract is created
	access(all)
	event ContractInitialized()
	
	// --- NFT Standard Events ---
	// Emitted on Everbloom2 NFT Withdrawal
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emitted on Everbloom2 NFT transfer
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	// Emitted on Everbloom2 NFT deposit
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// --- Everbloom2 Event ---
	// Emitted when an NFT (print) is minted
	access(all)
	event PrintNFTMinted(nftID: UInt64, artworkID: UInt32, galleryID: UInt32, serialNumber: UInt32, externalPrintID: String, signature: String?, metadata:{ String: String})
	
	// Emitted when an NFT (print) is detroyed
	access(all)
	event PrintNFTDestroyed(nftID: UInt64)
	
	// Emitted when an Artwork is created
	access(all)
	event ArtworkCreated(artworkID: UInt32, galleryID: UInt32, externalPostID: String, metadata:{ String: String})
	
	// Emitted when a Gallery is created
	access(all)
	event GalleryCreated(galleryID: UInt32, name: String)
	
	// Emitted when an artwork is marked as completed
	access(all)
	event ArtworkCompleted(artworkID: UInt32, numOfArtworks: UInt32)
	
	// Emitted when a user is created
	access(all)
	event UserCreated(userID: UInt64)
	
	// -----------------------------------------------------------------------
	// Everbloom2 contract-level fields
	// -----------------------------------------------------------------------
	// Storage Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	access(all)
	let UserStoragePath: StoragePath
	
	access(all)
	let UserPublicPath: PublicPath
	
	// Variable size dictionary of artworkDatas structs
	access(self)
	var artworkDatas:{ UInt32: Artwork}
	
	// Variable size dictionary for externalPostID to artworkID map
	access(self)
	var externalPostIDMap:{ String: UInt32}
	
	// artworkCompleted is a dictionary that stores artwork completion data
	access(self)
	let artworkCompleted:{ UInt32: Bool}
	
	// Variable size dictionary for externalPrintIDMap to nft map
	access(self)
	var externalPrintIDMap:{ String: UInt64}
	
	// numberMintedPerArtwork holds number of prints minted against artworkID
	access(self)
	let numberMintedPerArtwork:{ UInt32: UInt32}
	
	// validPerks stores information of perk validity
	access(self)
	let validPerks:{ UInt32: Bool}
	
	// Maximum Limit Constants
	// Maximum number of Arts that can be added in a Gallery
	access(all)
	let maxArtLimit: UInt16
	
	// Maximum number of NFTs that can be mint in a batch
	access(all)
	let maxBatchMintSize: UInt16
	
	// Maximum number of NFTs that can be deposited in a batch
	access(all)
	let maxBatchDepositSize: UInt16
	
	// Maximum number of NFTs that can be withdrawn in a batch
	access(all)
	let maxBatchWithdrawalSize: UInt16
	
	// Maximum number of Perks stored in an Artwork
	access(all)
	let maxPerkLimit: UInt16
	
	// Every time an Artwork is created, artworkID is assigned
	// to the new Artwork's artworkID and then is incremented by 1.
	access(all)
	var nextArtworkID: UInt32
	
	// Every time a Gallery is created, galleryID is assigned
	// to the new Gallery's galleryID and then is incremented by 1.
	access(all)
	var nextGalleryID: UInt32
	
	// Every time a User is created, userID is assigned
	// to the new User's userID and then is incremented by 1.
	access(all)
	var nextUserID: UInt64
	
	// Every time a Perk is created, perkID is assigned
	// to the new Perk's perkID and then is incremented by 1.
	access(all)
	var nextPerkID: UInt32
	
	/* The total number of Print NFTs that have been created
		Because NFTs can be destroyed, it doesn't necessarily mean that this
		reflects the total number of NFTs in existence, just the number that
		have been minted to date. Also used as global Print IDs for minting. */
	
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Everbloom2 contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// PrintData is a Struct that holds metadata associated with Print NFT
	access(all)
	struct PrintData{ 
		access(all)
		let artworkID: UInt32
		
		access(all)
		let galleryID: UInt32
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let externalPrintID: String
		
		access(all)
		let signature: String?
		
		access(all)
		let metadata:{ String: String}
		
		init(galleryID: UInt32, artworkID: UInt32, serialNumber: UInt32, externalPrintID: String, signature: String?, metadata:{ String: String}){ 
			self.galleryID = galleryID
			self.artworkID = artworkID
			self.serialNumber = serialNumber
			self.externalPrintID = externalPrintID
			self.signature = signature
			self.metadata = metadata
		}
	}
	
	// The resource that represents the Print NFTs
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// Global unique Artwork ID
		access(all)
		let id: UInt64
		
		// Struct of ArtworkData metadata
		access(self)
		let data: PrintData
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(galleryID: UInt32, artworkID: UInt32, serialNumber: UInt32, externalPrintID: String, signature: String?, metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			Everbloom2.totalSupply = Everbloom2.totalSupply + UInt64(1)
			self.id = Everbloom2.totalSupply
			self.data = PrintData(galleryID: galleryID, artworkID: artworkID, serialNumber: serialNumber, externalPrintID: externalPrintID, signature: signature, metadata: metadata)
			self.royalties = royalties
			Everbloom2.externalPrintIDMap[externalPrintID] = self.id
			emit PrintNFTMinted(nftID: self.id, artworkID: self.data.artworkID, galleryID: self.data.galleryID, serialNumber: self.data.serialNumber, externalPrintID: self.data.externalPrintID, signature: signature, metadata: metadata)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<EverbloomMetadata.EverbloomMetadataView>(), Type<EverbloomMetadata.PerksView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return Everbloom2.getDisplayView(data: self.data)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<EverbloomMetadata.EverbloomMetadataView>():
					return Everbloom2.getPrintView(data: self.data)
				case Type<EverbloomMetadata.PerksView>():
					return Everbloom2.getPerksView(data: self.data)
			}
			return nil
		}
		
		access(all)
		fun getMetadata(): PrintData{ 
			return self.data
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	fun getDisplayView(data: PrintData): MetadataViews.Display?{ 
		let artwork = Everbloom2.getArtwork(artworkID: data.artworkID)
		if artwork != nil{ 
			let metadata = (artwork!).getMetadata()
			return MetadataViews.Display(name: metadata["name"] ?? metadata["creatorName"]?.concat(" on Everbloom") ?? "", description: metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: metadata["thumbnail"] ?? metadata["image"] ?? ""))
		}
		return nil
	}
	
	access(all)
	fun getPrintView(data: PrintData): EverbloomMetadata.EverbloomMetadataView?{ 
		let artwork = Everbloom2.getArtwork(artworkID: data.artworkID)!
		if artwork != nil{ 
			let metadata = artwork.getMetadata()
			return EverbloomMetadata.EverbloomMetadataView(name: metadata["name"] ?? metadata["creatorName"]?.concat(" on Everbloom") ?? "", description: metadata["description"], image: MetadataViews.HTTPFile(url: metadata["image"] ?? ""), thumbnail: MetadataViews.HTTPFile(url: metadata["thumbnail"] ?? metadata["image"] ?? ""), video: MetadataViews.HTTPFile(url: metadata["video"] ?? ""), signature: MetadataViews.HTTPFile(url: data.signature ?? ""), previewUrl: metadata["previewUrl"], creatorName: metadata["creatorName"], creatorUrl: metadata["creatorUrl"], creatorDescription: metadata["creatorDescription"], creatorAddress: metadata["creatorAddress"], externalPostId: artwork.externalPostID, externalPrintId: data.externalPrintID, rarity: metadata["rarity"], serialNumber: data.serialNumber, totalPrintMinted: Everbloom2.getArtworkNftCount(artworkID: data.artworkID))
		}
		return nil
	}
	
	access(all)
	fun getPerksView(data: PrintData): EverbloomMetadata.PerksView?{ 
		let artwork = Everbloom2.getArtwork(artworkID: data.artworkID)
		if artwork != nil{ 
			var perks: [EverbloomMetadata.Perk] = []
			for perk in (artwork!).getPerks(){ 
				perks.append(EverbloomMetadata.Perk(perkID: perk.perkID, type: perk.type, title: perk.title, description: perk.description, url: perk.url, isValid: Everbloom2.validPerks[perk.perkID]))
			}
			return EverbloomMetadata.PerksView(perks)
		}
		return nil
	}
	
	/* Representation of Artwork struct. Artwork groups prints
	
			Artwork struct contains metadata of the artwork
	
		   A Post on Everbloom2 platform represent an Artwork
		*/
	
	access(all)
	struct Artwork{ 
		access(all)
		let galleryID: UInt32
		
		access(all)
		let artworkID: UInt32
		
		// externalPostID is the ID of a post in Everbloom2 Platform
		access(all)
		let externalPostID: String
		
		// traits provided by the artwork creator and Everbloom2
		access(self)
		let perks: [EverbloomMetadata.Perk]
		
		// Additional Metadata
		access(self)
		let metadata:{ String: String}
		
		// ids of NFTs in Buildin Block Contract
		access(self)
		let buildingBlockIds: [UInt64]
		
		init(galleryID: UInt32, externalPostID: String, perks: [EverbloomMetadata.Perk], metadata:{ String: String}, buildingBlockIds: [UInt64]){ 
			pre{ 
				metadata.length != 0:
					"Artwork metadata cannot be empty"
			}
			self.galleryID = galleryID
			self.artworkID = Everbloom2.nextArtworkID
			self.perks = perks
			self.metadata = metadata
			self.externalPostID = externalPostID
			self.buildingBlockIds = buildingBlockIds
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getPerks(): [EverbloomMetadata.Perk]{ 
			return self.perks
		}
	}
	
	// GalleryPublic Interface is the public interface of Gallery
	// Any user can borrow the public reference of gallery resource
	access(all)
	resource interface GalleryPublic{ 
		access(all)
		fun getAllArtworks(): [UInt32]
		
		access(all)
		fun isArtworkLocked(artworkID: UInt32): Bool
	}
	
	/* Representation of Gallery resource. Gallery resource contains Artworks information.
	
			gallery resource contains methods for addition of new artworks, borrowing of artworks,
			enabling, and disabling of Gallery
	
		   A gallery on Everbloom2 platform represent an Gallery resource
		*/
	
	access(all)
	resource Gallery: GalleryPublic{ 
		access(all)
		let galleryID: UInt32
		
		// artworks stores artwork resources against artworkID
		access(self)
		let artworks: [UInt32]
		
		// artworksLocked stores the locked status for artwork
		access(self)
		let artworksLocked:{ UInt32: Bool}
		
		// name of the gallery
		access(all)
		var name: String
		
		init(name: String){ 
			self.galleryID = Everbloom2.nextGalleryID
			self.artworks = []
			self.artworksLocked ={} 
			self.name = name
		}
		
		access(all)
		fun getAllArtworks(): [UInt32]{ 
			return self.artworks
		}
		
		/* This method creates and add new artwork
		
					parameter:
					  externalPostID: Everbloom2 post id
					  metadata: metadata of the artwork
		
					Pre-Conditions:
					Gallery arworks should not increase froma  threshold value
		
					return artworkID: id of the artwork
				*/
		
		access(all)
		fun createArtwork(externalPostID: String, perkDatas: [EverbloomMetadata.PerkData], metadata:{ String: String}, buildingBlockIds: [UInt64]): UInt32{ 
			pre{ 
				self.artworks.length < Int(Everbloom2.maxArtLimit):
					"Cannot create artwork. Maximum number of artworks in gallery is ".concat(Everbloom2.maxArtLimit.toString())
				perkDatas.length < Int(Everbloom2.maxPerkLimit):
					"Cannot create artwork. Maximum number of perks in an artwork is ".concat(Everbloom2.maxPerkLimit.toString())
			}
			//compile perkdata
			var perks: [EverbloomMetadata.Perk] = []
			for perkData in perkDatas{ 
				perks.append(EverbloomMetadata.Perk(perkID: Everbloom2.nextPerkID, type: perkData.type, title: perkData.title, description: perkData.description, url: perkData.url, isValid: nil))
				Everbloom2.validPerks[Everbloom2.nextPerkID] = true
				Everbloom2.nextPerkID = Everbloom2.nextPerkID + UInt32(1)
			}
			// Create the new Artwork
			var newArtwork: Artwork = Artwork(galleryID: self.galleryID, externalPostID: externalPostID, perks: perks as! [EverbloomMetadata.Perk], metadata: metadata, buildingBlockIds: buildingBlockIds)
			// Increment the ID so that it isn't used again
			Everbloom2.nextArtworkID = Everbloom2.nextArtworkID + UInt32(1)
			emit ArtworkCreated(artworkID: newArtwork.artworkID, galleryID: self.galleryID, externalPostID: externalPostID, metadata: metadata)
			let newID = newArtwork.artworkID
			// Store it in the contract storage
			self.artworks.append(newID)
			self.artworksLocked[newID] = false
			// update contract level data
			Everbloom2.artworkDatas[newID] = newArtwork
			Everbloom2.externalPostIDMap[externalPostID] = newID
			Everbloom2.numberMintedPerArtwork[newID] = 0
			Everbloom2.artworkCompleted[newID] = false
			return newID
		}
		
		/* This method mark artwork as locked to prevent further minting of prints
		
					parameter:  artworkID
				*/
		
		access(contract)
		fun setArtworkLocked(artworkID: UInt32){ 
			pre{ 
				self.artworksLocked[artworkID] != nil:
					"Artwork doesn't exist"
			}
			if !self.artworksLocked[artworkID]!{ 
				self.artworksLocked[artworkID] = true
				Everbloom2.artworkCompleted[artworkID] = true
				emit ArtworkCompleted(artworkID: artworkID, numOfArtworks: Everbloom2.numberMintedPerArtwork[artworkID]!)
			}
		}
		
		access(all)
		fun isArtworkLocked(artworkID: UInt32): Bool{ 
			pre{ 
				self.artworksLocked[artworkID] != nil:
					"Artwork doesn't exist"
			}
			return self.artworksLocked[artworkID]!
		}
	}
	
	// UserPublic Interface is the public interface of User
	// Any user can borrow the public reference of other user resource
	access(all)
	resource interface UserPublic{ 
		access(all)
		fun getUserID(): UInt64
		
		access(all)
		fun getAllGalleries(): [UInt32]
		
		access(all)
		fun borrowGallery(galleryID: UInt32): &Gallery?
		
		access(all)
		fun setMinterCapability(minterCapability: Capability<&Minter>)
	}
	
	/*  Representation of User resource. User resource contains Galleries information and
			User minting capability.
	
			User resource contains methods for addition of new galleries, borrowing of galleries,
			and minting of prints.
	
		   A profile on Everbloom2 platform represent a User resource
		*/
	
	access(all)
	resource User: UserPublic{ 
		access(all)
		let userID: UInt64
		
		// galleries dictionary stores gallery resource against galleryID
		access(self)
		let galleries: @{UInt32: Gallery}
		
		// Minting resource capability. it can be request from admin
		access(self)
		var minterCapability: Capability<&Minter>?
		
		init(){ 
			self.userID = Everbloom2.nextUserID
			self.galleries <-{} 
			self.minterCapability = nil
			Everbloom2.nextUserID = Everbloom2.nextUserID + UInt64(1)
			emit UserCreated(userID: self.userID)
		}
		
		access(all)
		fun getUserID(): UInt64{ 
			return self.userID
		}
		
		access(all)
		fun getAllGalleries(): [UInt32]{ 
			return self.galleries.keys
		}
		
		/* This method update minting capability of the user
		
					parameters: minterCapability: capability of minting resource
				*/
		
		access(all)
		fun setMinterCapability(minterCapability: Capability<&Minter>){ 
			self.minterCapability = minterCapability
		}
		
		/* This method returns a reference to a gallery resource
		
					parameters: galleryID: id of the gallery
		
					return reference to the gallery resource or nil if no gallery is found
				*/
		
		access(all)
		fun borrowGallery(galleryID: UInt32): &Gallery?{ 
			pre{ 
				self.galleries[galleryID] != nil:
					"Cannot borrow Gallery: The Gallery doesn't exist"
			}
			// Get a reference to the Gallery and return it
			// use `&` to indicate the reference to the object and type
			return &self.galleries[galleryID] as &Gallery?
		}
		
		/* This method creates a gallery resource and will store it in galleries dictionary
		
					parameters: name: name of the gallery
		
					return galleryID
				*/
		
		access(all)
		fun createGallery(name: String): UInt32{ 
			pre{ 
				self.minterCapability != nil:
					"Unable to create gallery: Minting capability not found"
			}
			// Create the new Gallery
			var newGallery <- create Everbloom2.Gallery(name: name)
			let newGalleryID = newGallery.galleryID
			// Store it in the galleries mapping field
			self.galleries[newGalleryID] <-! newGallery
			Everbloom2.nextGalleryID = Everbloom2.nextGalleryID + UInt32(1)
			emit GalleryCreated(galleryID: newGalleryID, name: name)
			return newGalleryID
		}
		
		/* This method mints an Print NFT under a artwork
		
					parameters:
					 galleryID: id of the gallery
					 artworkID: id of the artwork
					 signature: url of the signature for the NFT
		
					return @NFT: minted NFT resource
				*/
		
		access(all)
		fun mintPrint(galleryID: UInt32, artworkID: UInt32, externalPrintID: String, signature: String?, metadata:{ String: String}, royalties: [MetadataViews.Royalty]): @NFT{ 
			let gallery: &Gallery = self.borrowGallery(galleryID: galleryID) ?? panic("Cannot mint the print: unable to borrow gallery")
			if gallery.isArtworkLocked(artworkID: artworkID){ 
				panic("Cannot mint the print from this artwork: This artwork has been marked as completed.")
			}
			let numOfArtworks = Everbloom2.getArtworkNftCount(artworkID: artworkID)!
			var minterCapability: Capability<&Minter> = self.minterCapability ?? panic("Minting capability not found")
			let minterRef: &Everbloom2.Minter = minterCapability.borrow() ?? panic("Cannot borrow minting resource")
			let newPrint: @NFT <- minterRef.mintNFT(galleryID: galleryID, artworkID: artworkID, serialNumber: numOfArtworks + UInt32(1), externalPrintID: externalPrintID, signature: signature, metadata: metadata, royalties: royalties)
			Everbloom2.numberMintedPerArtwork[artworkID] = Everbloom2.numberMintedPerArtwork[artworkID]! + UInt32(1)
			return <-newPrint
		}
		
		/* This method mints NFTs in batch
		
					return  @NonFungibleToken.Collection: collection of minted NFTs
				*/
		
		access(all)
		fun batchMintPrint(galleryID: UInt32, artworkID: UInt32, externalPrintIDs: [String], signatures: [String?], metadata:{ String: String}, royalties: [MetadataViews.Royalty]): @Collection{ 
			pre{ 
				externalPrintIDs.length < Int(Everbloom2.maxBatchMintSize):
					"Maximum number of NFT that can be minted in a batch is ".concat(Everbloom2.maxBatchMintSize.toString())
			}
			let newCollection <- create Collection()
			for index, externalPrintID in externalPrintIDs{ 
				newCollection.deposit(token: <-self.mintPrint(galleryID: galleryID, artworkID: artworkID, externalPrintID: externalPrintID, signature: signatures[index], metadata: metadata, royalties: royalties))
			}
			return <-newCollection
		}
	}
	
	/*  Representation of Minter resource. It is can created by Admin resource. User needs
			minter resource capability to mint an NFT.
			Only minter resource can mint an NFT Print
		*/
	
	access(all)
	resource Minter{ 
		access(all)
		fun mintNFT(galleryID: UInt32, artworkID: UInt32, serialNumber: UInt32, externalPrintID: String, signature: String?, metadata:{ String: String}, royalties: [MetadataViews.Royalty]): @Everbloom2.NFT{ 
			let newPrint: @NFT <- create NFT(galleryID: galleryID, artworkID: artworkID, serialNumber: serialNumber, externalPrintID: externalPrintID, signature: signature, metadata: metadata, royalties: royalties)
			return <-newPrint
		}
	}
	
	/*  Representation of Admin resource. It can create new Admin and Minter resource.
		*/
	
	access(all)
	resource Admin{ 
		/* This method creates new Admin resource
		
					return @Admin: admin resource
				*/
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		/* This method creates new Minter resource
		
					return @Minter: minter reource
				*/
		
		access(all)
		fun createNewMinter(): @Minter{ 
			return <-create Minter()
		}
		
		access(all)
		fun invalidatePerk(perkID: UInt32){ 
			Everbloom2.validPerks[perkID] = false
		}
	}
	
	// -----------------------------------------------------------------------
	// Everbloom2 Collection Logic
	// -----------------------------------------------------------------------
	// PrintCollectionPublic Interface is the public interface of Collection
	// Any user can borrow the public reference of collection resource
	access(all)
	resource interface PrintCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPrint(id: UInt64): &Everbloom2.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Print reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PrintCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/*  withdraw removes an Print from the Collection and moves it to the caller
		
					Parameters: withdrawID: The ID of the NFT
					that is to be removed from the Collection
		
					returns: @NonFungibleToken.NFT the token that was withdrawn
				*/
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Artwork Piece does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			// Return the withdrawn token
			return <-token
		}
		
		/*  batchWithdraw withdraws multiple tokens and returns them as a Collection
		
					Parameters: ids: An array of IDs to withdraw
		
					Returns: @NonFungibleToken.Collection: A collection that contains the withdrawn print
				*/
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			pre{ 
				ids.length < Int(Everbloom2.maxBatchWithdrawalSize):
					"Maximum number of NFT that can be withdraw in a batch is ".concat(Everbloom2.maxBatchWithdrawalSize.toString())
			}
			// Create a new empty Collection
			var batchCollection <- create Collection()
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		/*  deposit takes a Print and adds it to the Collections dictionary
		
					Parameters: token: the NFT to be deposited in the collection
				*/
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Cast the deposited token as a Everbloom2 NFT to make sure
			// it is the correct type
			let token <- token as! @Everbloom2.NFT
			// Get the token's ID
			let id = token.id
			// Add the new token to the dictionary
			let oldToken <- self.ownedNFTs[id] <- token
			// Only emit a deposit event if the Collection
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			// Destroy the empty old token that was "removed"
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			pre{ 
				tokens.getIDs().length < Int(Everbloom2.maxBatchDepositSize):
					"Maximum number of NFT that can be deposited in a batch is ".concat(Everbloom2.maxBatchDepositSize.toString())
			}
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			// Destroy the empty Collection
			destroy tokens
		}
		
		/*  Transfer the NFT
		
					Parameters:
					 withdrawID: id of the NFT to be transferred
					 target: NFT receiver capability of the receiver
				*/
		
		access(all)
		fun transfer(withdrawID: UInt64, target: Capability<&{NonFungibleToken.Receiver}>){ 
			let token <- self.withdraw(withdrawID: withdrawID)
			emit Transfer(id: token.uuid, from: self.owner?.address, to: target.address)
			(target.borrow()!).deposit(token: <-token)
		}
		
		// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/*  borrowNFT Returns a borrowed reference to a Print in the Collection
					so that the caller can read its ID
		
					Parameters: id: The ID of the NFT to get the reference for
		
					Returns: A reference to the NFT
				*/
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/*  borrowPrint returns a borrowed reference to a Print
					so that the caller can read data and call methods from it.
					They can use this to read its Printdata associated with it.
		
					Parameters: id: The ID of the NFT to get the reference for
		
					Returns: A reference to the NFT
				*/
		
		access(all)
		fun borrowPrint(id: UInt64): &Everbloom2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Everbloom2.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let print = nft as! &Everbloom2.NFT
			return print as &{ViewResolver.Resolver}
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
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed!
	}
	
	// -----------------------------------------------------------------------
	// Everbloom2 contract-level function definitions
	// -----------------------------------------------------------------------
	/* This method creates new User resource
	
			return @User: user resource
		*/
	
	access(all)
	fun createUser(): @User{ 
		return <-create User()
	}
	
	/* This method creates new Collection resource
	
			return @NonFungibleToken.Collection: collection resource
		*/
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Everbloom2.Collection()
	}
	
	access(all)
	fun getArtworkIdByExternalPostId(externalPostID: String): UInt32?{ 
		return Everbloom2.externalPostIDMap[externalPostID]
	}
	
	access(all)
	fun getNftIDByExternalPrintID(externalPrintID: String): UInt64?{ 
		return Everbloom2.externalPrintIDMap[externalPrintID]
	}
	
	access(all)
	fun getArtwork(artworkID: UInt32): Artwork?{ 
		if Everbloom2.artworkDatas[artworkID] != nil{ 
			let artwork = Everbloom2.artworkDatas[artworkID] as Artwork?
			return artwork
		} else{ 
			return nil
		}
	}
	
	/* This method returns an Artwork using the id of the post in Everbloom2 platform
	
			parameters: externalPostID: id of the post in Everbloom2 platform
	
			return artwork or nil if no artwork is found
		*/
	
	access(all)
	fun getArtworkByPostID(externalPostID: String): Artwork?{ 
		let artworkID: UInt32? = Everbloom2.externalPostIDMap[externalPostID]
		if artworkID != nil{ 
			return Everbloom2.getArtwork(artworkID: artworkID!) as Artwork?
		} else{ 
			return nil
		}
	}
	
	access(all)
	fun getArtworkNftCount(artworkID: UInt32): UInt32{ 
		pre{ 
			Everbloom2.numberMintedPerArtwork[artworkID] != nil:
				"Artwork does not exist"
		}
		return Everbloom2.numberMintedPerArtwork[artworkID]!
	}
	
	access(all)
	fun isArtworkCompleted(artworkID: UInt32): Bool{ 
		pre{ 
			Everbloom2.artworkCompleted[artworkID] != nil:
				"Artwork doesn't exist."
		}
		return Everbloom2.artworkCompleted[artworkID]!
	}
	
	// -----------------------------------------------------------------------
	// Everbloom2 initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		// Initialize contract fields
		self.totalSupply = 0
		self.nextArtworkID = 1
		self.nextGalleryID = 1
		self.nextUserID = 1
		self.nextPerkID = 1
		self.maxPerkLimit = 50
		self.maxArtLimit = 10_000
		self.maxBatchMintSize = 10_000
		self.maxBatchDepositSize = 10_000
		self.maxBatchWithdrawalSize = 10_000
		self.artworkDatas ={} 
		self.externalPostIDMap ={} 
		self.artworkCompleted ={} 
		self.externalPrintIDMap ={} 
		self.numberMintedPerArtwork ={} 
		self.validPerks ={} 
		// set contract paths
		self.CollectionStoragePath = /storage/Everbloom2Collection
		self.CollectionPublicPath = /public/Everbloom2Collection
		self.AdminStoragePath = /storage/Everbloom2Admin
		self.UserStoragePath = /storage/Everbloom2User
		self.UserPublicPath = /public/Everbloom2User
		self.MinterStoragePath = /storage/Everbloom2Minter
		self.MinterPrivatePath = /private/Everbloom2Minter
		// store admin resource in admin account
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
