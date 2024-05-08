import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import NFTStorefrontV2 from "./../../standardsV1/NFTStorefrontV2.cdc"

import FlowtyStorefront from "./FlowtyStorefront.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all)
contract NFTMetadataUtility{ 
	access(all)
	struct CollectionItem{ 
		access(all)
		let nftID: UInt64
		
		access(all)
		let nftUUID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let externalURL: String
		
		access(all)
		let ownerAddress: Address?
		
		access(all)
		let royalties: [MetadataViews.Royalty]
		
		access(all)
		let medias: [MetadataViews.Media]
		
		access(all)
		let editions: [MetadataViews.Edition]
		
		access(all)
		let serialNumber: UInt64?
		
		access(all)
		let traits: [MetadataViews.Trait]
		
		access(all)
		let rarity: MetadataViews.Rarity?
		
		access(all)
		let license: MetadataViews.License?
		
		access(all)
		let publicLinkedType: Type
		
		access(all)
		let collectionName: String
		
		access(all)
		let collectionDescription: String
		
		access(all)
		let collectionSquareImage: String
		
		access(all)
		let collectionBannerImage: String
		
		access(all)
		let collectionSocials:{ String: MetadataViews.ExternalURL}
		
		init(
			nftID: UInt64,
			nftUUID: UInt64,
			name: String,
			description: String,
			thumbnail: String,
			externalURL: String,
			ownerAddress: Address?,
			royalties: [
				MetadataViews.Royalty
			],
			medias: [
				MetadataViews.Media
			],
			editions: [
				MetadataViews.Edition
			],
			serialNumber: UInt64?,
			traits: [
				MetadataViews.Trait
			],
			rarity: MetadataViews.Rarity?,
			license: MetadataViews.License?,
			publicLinkedType: Type,
			collectionName: String,
			collectionDescription: String,
			collectionSquareImage: String,
			collectionBannerImage: String,
			collectionSocials:{ 
				String: MetadataViews.ExternalURL
			}
		){ 
			self.nftID = nftID
			self.nftUUID = nftUUID
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.externalURL = externalURL
			self.ownerAddress = ownerAddress
			self.royalties = royalties
			self.medias = medias
			self.editions = editions
			self.serialNumber = serialNumber
			self.traits = traits
			self.rarity = rarity
			self.license = license
			self.publicLinkedType = publicLinkedType
			self.collectionName = collectionName
			self.collectionDescription = collectionDescription
			self.collectionSquareImage = collectionSquareImage
			self.collectionBannerImage = collectionBannerImage
			self.collectionSocials = collectionSocials
		}
	}
	
	access(all)
	struct StorefrontItem{ 
		access(all)
		let nft: CollectionItem
		
		// Storefront Item info
		access(all)
		let listingResourceID: UInt64
		
		access(all)
		let storefrontID: UInt64
		
		access(all)
		let purchased: Bool
		
		access(all)
		let nftType: Type
		
		access(all)
		let salePaymentVaultType: Type
		
		access(all)
		let salePrice: UFix64
		
		access(all)
		let saleCuts: [NFTStorefrontV2.SaleCut]
		
		access(all)
		let saleCutsV1: [NFTStorefront.SaleCut]
		
		access(all)
		let customID: String?
		
		access(all)
		let commissionAmount: UFix64?
		
		access(all)
		let expiry: UInt64?
		
		init(
			nft: CollectionItem,
			listingResourceID: UInt64,
			storefrontID: UInt64,
			purchased: Bool,
			nftType: Type,
			salePaymentVaultType: Type,
			salePrice: UFix64,
			saleCuts: [
				NFTStorefrontV2.SaleCut
			],
			saleCutsV1: [
				NFTStorefront.SaleCut
			],
			customID: String?,
			commissionAmount: UFix64?,
			expiry: UInt64?
		){ 
			self.nft = nft
			self.listingResourceID = listingResourceID
			self.storefrontID = storefrontID
			self.purchased = purchased
			self.nftType = nftType
			self.salePaymentVaultType = salePaymentVaultType
			self.salePrice = salePrice
			self.saleCuts = saleCuts
			self.saleCutsV1 = saleCutsV1
			self.customID = customID
			self.commissionAmount = commissionAmount
			self.expiry = expiry
		}
	}
	
	access(all)
	fun getMetadataFromNFTRef(nftRef: &{NonFungibleToken.NFT}, owner: Address): CollectionItem{ 
		let displayView =
			nftRef.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		let externalURLView =
			nftRef.resolveView(Type<MetadataViews.ExternalURL>())! as! MetadataViews.ExternalURL
		let collectionDataView =
			nftRef.resolveView(Type<MetadataViews.NFTCollectionData>())!
			as!
			MetadataViews.NFTCollectionData
		let collectionDisplayView =
			nftRef.resolveView(Type<MetadataViews.NFTCollectionDisplay>())!
			as!
			MetadataViews.NFTCollectionDisplay
		let royaltyView =
			nftRef.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties
		if displayView == nil || externalURLView == nil || collectionDataView == nil
		|| collectionDisplayView == nil
		|| royaltyView == nil{ 
			panic("NFT does not have proper metadata views implemented.")
		}
		
		// Optional metadata views
		let mediasView = nftRef.resolveView(Type<MetadataViews.Medias>())
		let editionsView = nftRef.resolveView(Type<MetadataViews.Editions>())
		let serialView = nftRef.resolveView(Type<MetadataViews.Serial>())
		let traitsView = nftRef.resolveView(Type<MetadataViews.Traits>())
		let rarityView = nftRef.resolveView(Type<MetadataViews.Rarity>())
		let licenseView = nftRef.resolveView(Type<MetadataViews.License>())
		var medias: [MetadataViews.Media] = []
		if mediasView != nil{ 
			medias = (mediasView! as! MetadataViews.Medias).items
		}
		var editions: [MetadataViews.Edition] = []
		if editionsView != nil{ 
			editions = (editionsView! as! MetadataViews.Editions).infoList
		}
		var serialNumber: UInt64? = nil
		if serialView != nil{ 
			serialNumber = (serialView! as! MetadataViews.Serial).number
		}
		var traits: [MetadataViews.Trait] = []
		if traitsView != nil{ 
			traits = (traitsView! as! MetadataViews.Traits).traits
		}
		var rarity: MetadataViews.Rarity? = nil
		if rarityView != nil{ 
			rarity = rarityView! as! MetadataViews.Rarity
		}
		var license: MetadataViews.License? = nil
		if licenseView != nil{ 
			license = licenseView! as! MetadataViews.License
		}
		return CollectionItem(
			nftID: nftRef.id,
			nftUUID: nftRef.uuid,
			name: (displayView!).name,
			description: (displayView!).description,
			thumbnail: (displayView!).thumbnail.uri(),
			externalURL: (externalURLView!).url,
			ownerAddress: owner,
			royalties: (royaltyView!).getRoyalties(),
			medias: medias,
			editions: editions,
			serialNumber: serialNumber,
			traits: traits,
			rarity: rarity,
			license: license,
			publicLinkedType: (collectionDataView!).publicLinkedType,
			collectionName: (collectionDisplayView!).name,
			collectionDescription: (collectionDisplayView!).description,
			collectionSquareImage: (collectionDisplayView!).squareImage.file.uri(),
			collectionBannerImage: (collectionDisplayView!).bannerImage.file.uri(),
			collectionSocials: (collectionDisplayView!).socials
		)
	}
	
	access(all)
	fun getStorefrontV2NFTRef(owner: Address, listingResourceID: UInt64): &{NonFungibleToken.NFT}?{ 
		let storefrontRef =
			getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
				NFTStorefrontV2.StorefrontPublicPath
			).borrow()
			?? panic("Could not borrow public storefront from address")
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		return listing.borrowNFT()
	}
	
	access(all)
	fun getStorefrontV2ListingMetadata(owner: Address, listingResourceID: UInt64): StorefrontItem{ 
		let storefrontRef =
			getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
				NFTStorefrontV2.StorefrontPublicPath
			).borrow()
			?? panic("Could not borrow public storefront from address")
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		let listingDetails = listing.getDetails()
		let nftRef = listing.borrowNFT()
		let collectionItem = NFTMetadataUtility.getMetadataFromNFTRef(nftRef: nftRef!, owner: owner)
		return StorefrontItem(
			nft: collectionItem,
			listingResourceID: listingResourceID,
			storefrontID: listingDetails.storefrontID,
			purchased: listingDetails.purchased,
			nftType: listingDetails.nftType,
			salePaymentVaultType: listingDetails.salePaymentVaultType,
			salePrice: listingDetails.salePrice,
			saleCuts: listingDetails.saleCuts,
			saleCutsV1: [],
			customID: listingDetails.customID,
			commissionAmount: listingDetails.commissionAmount,
			expiry: listingDetails.expiry
		)
	}
	
	access(all)
	fun getStorefrontV2FlowtyNFTRef(owner: Address, listingResourceID: UInt64): &{
		NonFungibleToken.NFT
	}?{ 
		let storefrontRef = FlowtyStorefront.getStorefrontRef(owner: owner)
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		return listing.borrowNFT()
	}
	
	access(all)
	fun getStorefrontV2FlowtyListingMetadata(
		owner: Address,
		listingResourceID: UInt64
	): StorefrontItem{ 
		let storefrontRef = FlowtyStorefront.getStorefrontRef(owner: owner)
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		let listingDetails = listing.getDetails()
		let nftRef = listing.borrowNFT()
		let collectionItem = NFTMetadataUtility.getMetadataFromNFTRef(nftRef: nftRef!, owner: owner)
		return StorefrontItem(
			nft: collectionItem,
			listingResourceID: listingResourceID,
			storefrontID: listingDetails.storefrontID,
			purchased: listingDetails.purchased,
			nftType: listingDetails.nftType,
			salePaymentVaultType: listingDetails.salePaymentVaultType,
			salePrice: listingDetails.salePrice,
			saleCuts: [],
			saleCutsV1: [],
			customID: listingDetails.customID,
			commissionAmount: listingDetails.commissionAmount,
			expiry: listingDetails.expiry
		)
	}
	
	access(all)
	fun getStorefrontV1NFTRef(owner: Address, listingResourceID: UInt64): &{NonFungibleToken.NFT}?{ 
		let storefrontRef =
			getAccount(owner).capabilities.get<&NFTStorefront.Storefront>(
				NFTStorefront.StorefrontPublicPath
			).borrow()
			?? panic("Could not borrow public storefront from address")
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		return listing.borrowNFT()
	}
	
	access(all)
	fun getStorefrontV1ListingMetadata(owner: Address, listingResourceID: UInt64): StorefrontItem{ 
		let storefrontRef =
			getAccount(owner).capabilities.get<&NFTStorefront.Storefront>(
				NFTStorefront.StorefrontPublicPath
			).borrow()
			?? panic("Could not borrow public storefront from address")
		let listing =
			storefrontRef.borrowListing(listingResourceID: listingResourceID)
			?? panic("No item with that ID")
		let listingDetails = listing.getDetails()
		let nftRef = listing.borrowNFT()
		let collectionItem = NFTMetadataUtility.getMetadataFromNFTRef(nftRef: nftRef!, owner: owner)
		return StorefrontItem(
			nft: collectionItem,
			listingResourceID: listingResourceID,
			storefrontID: listingDetails.storefrontID,
			purchased: listingDetails.purchased,
			nftType: listingDetails.nftType,
			salePaymentVaultType: listingDetails.salePaymentVaultType,
			salePrice: listingDetails.salePrice,
			saleCuts: [],
			saleCutsV1: listingDetails.saleCuts,
			customID: nil,
			commissionAmount: nil,
			expiry: nil
		)
	}
	
	access(all)
	fun getTopShotNFTRef(owner: Address, nftID: UInt64): &{NonFungibleToken.NFT}?{ 
		let collectionRef =
			getAccount(owner).capabilities.get<&{TopShot.MomentCollectionPublic}>(
				/public/MomentCollection
			).borrow<&{TopShot.MomentCollectionPublic}>()
			?? panic("Could not get reference to public TopShot collection")
		return collectionRef.borrowNFT(id: nftID)
	}
	
	access(all)
	fun getTopShotMetadata(owner: Address, nftID: UInt64): CollectionItem{ 
		let nftRef = NFTMetadataUtility.getTopShotNFTRef(owner: owner, nftID: nftID)
		return NFTMetadataUtility.getMetadataFromNFTRef(nftRef: nftRef!, owner: owner)
	}
}
