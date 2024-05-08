import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import NFTCatalog from "../0x49a7cda3a1eecc29/NFTCatalog.cdc"
import NFTStorefront from "../0x4eb8a10cb9f87357/NFTStorefront.cdc"
import NFTStorefrontV2 from "../0x4eb8a10cb9f87357/NFTStorefrontV2.cdc"
import FlowtyStorefront from "../0x5425d4a12d3b88de/FlowtyStorefront.cdc"
import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all) contract NFTMetadataUtility {
    access(all) struct CollectionItem {
        pub let nftID: UInt64
        pub let nftUUID: UInt64
        pub let name: String
        pub let description: String
        pub let thumbnail: String
        pub let externalURL: String
        pub let owner: Address?
        pub let royalties: [MetadataViews.Royalty]
        pub let medias: [MetadataViews.Media]
        pub let editions: [MetadataViews.Edition]
        pub let serialNumber: UInt64?
        pub let traits: [MetadataViews.Trait]

        pub let publicLinkedType: Type
        pub let collectionName: String
        pub let collectionDescription: String
        pub let collectionSquareImage: String
        pub let collectionBannerImage: String
        pub let collectionSocials: {String: MetadataViews.ExternalURL}

        init(
            nftID: UInt64,
            nftUUID: UInt64,
            name: String,
            description: String,
            thumbnail: String,
            externalURL: String,
            owner: Address?,
            royalties: [MetadataViews.Royalty],
            medias: [MetadataViews.Media],
            editions: [MetadataViews.Edition],
            serialNumber: UInt64?,
            traits: [MetadataViews.Trait],
            publicLinkedType: Type,
            collectionName: String,
            collectionDescription: String,
            collectionSquareImage: String,
            collectionBannerImage: String,
            collectionSocials: {String: MetadataViews.ExternalURL}
        ) {
            self.nftID = nftID
            self.nftUUID = nftUUID
            self.name = name
            self.description = description
            self.thumbnail = thumbnail
            self.externalURL = externalURL
            self.owner = owner
            self.royalties = royalties
            self.medias = medias
            self.editions = editions
            self.serialNumber = serialNumber
            self.traits = traits
            self.publicLinkedType = publicLinkedType
            self.collectionName = collectionName
            self.collectionDescription = collectionDescription
            self.collectionSquareImage = collectionSquareImage
            self.collectionBannerImage = collectionBannerImage
            self.collectionSocials = collectionSocials
        }
    }
    
    pub struct StorefrontItem {
        pub let nft: CollectionItem

        // Storefront Item info
        pub let listingResourceID: UInt64
        pub let storefrontID: UInt64
        pub let purchased: Bool
        pub let nftType: Type
        pub let salePaymentVaultType: Type
        pub let salePrice: UFix64

        init(
            nft: CollectionItem,
            listingResourceID: UInt64,
            storefrontID: UInt64,
            purchased: Bool,
            nftType: Type,
            salePaymentVaultType: Type,
            salePrice: UFix64,
        ) {
            self.nft = nft
            self.listingResourceID = listingResourceID
            self.storefrontID = storefrontID
            self.purchased = purchased
            self.nftType = nftType
            self.salePaymentVaultType = salePaymentVaultType
            self.salePrice = salePrice
        }
    }

    access(self) fun getMetadataFromNFTRef(nftRef: &NonFungibleToken.NFT, owner: Address): CollectionItem {
        let displayView = nftRef.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
        let externalURLView = nftRef.resolveView(Type<MetadataViews.ExternalURL>())! as! MetadataViews.ExternalURL
        let collectionDataView = nftRef.resolveView(Type<MetadataViews.NFTCollectionData>())! as! MetadataViews.NFTCollectionData
        let collectionDisplayView = nftRef.resolveView(Type<MetadataViews.NFTCollectionDisplay>())! as! MetadataViews.NFTCollectionDisplay
        let royaltyView = nftRef.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties

        let mediasView = nftRef.resolveView(Type<MetadataViews.Medias>())
        let editionsView = nftRef.resolveView(Type<MetadataViews.Editions>())
        let serialView = nftRef.resolveView(Type<MetadataViews.Serial>())
        let traitsView = nftRef.resolveView(Type<MetadataViews.Traits>())

        if (displayView == nil || externalURLView == nil || collectionDataView == nil || collectionDisplayView == nil || royaltyView == nil) {
            panic("NFT does not have proper metadata views implemented.")
        }

        var medias: [MetadataViews.Media] = []
        if mediasView != nil {
            medias = (mediasView! as! MetadataViews.Medias).items
        }

        var editions: [MetadataViews.Edition] = []
        if editionsView != nil {
            editions = (editionsView! as! MetadataViews.Editions).infoList
        }

        var serialNumber: UInt64? = nil
        if serialView != nil {
            serialNumber = (serialView! as! MetadataViews.Serial).number
        }
        
        var traits: [MetadataViews.Trait] = []
        if traitsView != nil {
            traits = (traitsView! as! MetadataViews.Traits).traits
        }

        return CollectionItem(
            nftID: nftRef.id,
            nftUUID: nftRef.uuid,
            name: displayView!.name,
            description : displayView!.description,
            thumbnail : displayView!.thumbnail.uri(),
            externalURL : externalURLView!.url,
            owner: owner,
            royalties : royaltyView!.getRoyalties(),
            medias: medias,
            editions: editions,
            serialNumber: serialNumber,
            traits: traits,
            publicLinkedType : collectionDataView!.publicLinkedType,
            collectionName : collectionDisplayView!.name,
            collectionDescription : collectionDisplayView!.description,
            collectionSquareImage : collectionDisplayView!.squareImage.file.uri(),
            collectionBannerImage : collectionDisplayView!.bannerImage.file.uri(),
            collectionSocials: collectionDisplayView!.socials
        )
    }

    access(all) fun getStorefrontV2NFTRef(owner: Address, listingResourceID: UInt64): &NonFungibleToken.NFT? {
        let storefrontRef = getAccount(owner)
          .getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(
              NFTStorefrontV2.StorefrontPublicPath
          )
          .borrow()
          ?? panic("Could not borrow public storefront from address")
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No item with that ID")
        return listing.borrowNFT()
    }

    access(all) fun getStorefrontV2ListingMetadata(owner: Address, listingResourceID: UInt64): StorefrontItem {
        let storefrontRef = getAccount(owner)
          .getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(
              NFTStorefrontV2.StorefrontPublicPath
          )
          .borrow()
          ?? panic("Could not borrow public storefront from address")
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
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
            salePrice: listingDetails.salePrice
        )
    }
    
    access(all) fun getStorefrontV2FlowtyNFTRef(owner: Address, listingResourceID: UInt64): &NonFungibleToken.NFT? {
        let storefrontRef = FlowtyStorefront.getStorefrontRef(owner: owner)
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No item with that ID")
        return listing.borrowNFT()
    }

    access(all) fun getStorefrontV2FlowtyListingMetadata(owner: Address, listingResourceID: UInt64): StorefrontItem {
        let storefrontRef = FlowtyStorefront.getStorefrontRef(owner: owner)
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
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
            salePrice: listingDetails.salePrice
        )
    }

    access(all) fun getStorefrontV1NFTRef(owner: Address, listingResourceID: UInt64): &NonFungibleToken.NFT? {
        let storefrontRef = getAccount(owner)
          .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
              NFTStorefront.StorefrontPublicPath
          )
          .borrow()
          ?? panic("Could not borrow public storefront from address")
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No item with that ID")
        return listing.borrowNFT()
    }

    access(all) fun getStorefrontV1ListingMetadata(owner: Address, listingResourceID: UInt64): StorefrontItem {
        let storefrontRef = getAccount(owner)
          .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
              NFTStorefront.StorefrontPublicPath
          )
          .borrow()
          ?? panic("Could not borrow public storefront from address")
        let listing = storefrontRef.borrowListing(listingResourceID: listingResourceID)
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
            salePrice: listingDetails.salePrice
        )
    }

    access(all) fun getTopShotNFTRef(owner: Address, nftID: UInt64): &NonFungibleToken.NFT? {
        let collectionRef = getAccount(owner).getCapability(/public/MomentCollection)
        .borrow<&{TopShot.MomentCollectionPublic}>()
        ?? panic("Could not get reference to public TopShot collection")
        return collectionRef.borrowNFT(id: nftID)
    }

    access(all) fun getTopShotMetadata(owner: Address, nftID: UInt64): CollectionItem {
        let nftRef = NFTMetadataUtility.getTopShotNFTRef(owner: owner, nftID: nftID)
        return NFTMetadataUtility.getMetadataFromNFTRef(nftRef: nftRef!, owner: owner)
    }
}
