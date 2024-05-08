import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import CoCreatableV2 from "./CoCreatableV2.cdc"

access(all)
contract TheFabricantMetadataViewsV2{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantNFT Contract Views
	// -----------------------------------------------------------------------
	// These are the standard views for TF NFTs that they should implement
	
	// NOTE: TODO: There is a metadata view for original recipient
	// currently in discussion: https://github.com/onflow/flow-nft/issues/119
	access(all)
	struct TFNFTIdentifierV1{ 
		access(all)
		let uuid: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let collection: String
		
		access(all)
		let editions: MetadataViews.Editions
		
		access(all)
		let address: Address
		
		access(all)
		let originalRecipient: Address
		
		init(
			uuid: UInt64,
			id: UInt64,
			name: String,
			collection: String,
			editions: MetadataViews.Editions,
			address: Address,
			originalRecipient: Address
		){ 
			self.uuid = uuid
			self.id = id
			self.name = name
			self.collection = collection
			self.editions = editions
			self.address = address
			self.originalRecipient = originalRecipient
		}
	}
	
	access(all)
	struct TFNFTSimpleView{ 
		access(all)
		let uuid: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let collection: String
		
		access(all)
		let collectionId: String
		
		access(all)
		let metadata:{ String: AnyStruct}?
		
		access(all)
		let media: MetadataViews.Medias
		
		access(all)
		let images:{ String: String}
		
		access(all)
		let videos:{ String: String}
		
		access(all)
		let externalURL: MetadataViews.ExternalURL
		
		access(all)
		let rarity: MetadataViews.Rarity?
		
		access(all)
		let traits: MetadataViews.Traits?
		
		access(all)
		let characteristics:{ String:{ CoCreatableV2.Characteristic}}?
		
		access(all)
		let coCreatable: Bool
		
		access(all)
		let coCreator: Address
		
		access(all)
		let isRevealed: Bool?
		
		access(all)
		let editions: MetadataViews.Editions
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let royalties: MetadataViews.Royalties
		
		access(all)
		let royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties
		
		access(all)
		let revealableTraits:{ String: Bool}?
		
		access(all)
		let address: Address
		
		init(
			uuid: UInt64,
			id: UInt64,
			name: String,
			description: String,
			collection: String,
			collectionId: String,
			metadata:{ 
				String: AnyStruct
			}?,
			media: MetadataViews.Medias,
			images:{ 
				String: String
			},
			videos:{ 
				String: String
			},
			externalURL: MetadataViews.ExternalURL,
			rarity: MetadataViews.Rarity?,
			traits: MetadataViews.Traits?,
			characteristics:{ 
				String:{ CoCreatableV2.Characteristic}
			}?,
			coCreatable: Bool,
			coCreator: Address,
			isRevealed: Bool?,
			editions: MetadataViews.Editions,
			originalRecipient: Address,
			royalties: MetadataViews.Royalties,
			royaltiesTFMarketplace: TheFabricantMetadataViewsV2.Royalties,
			revealableTraits:{ 
				String: Bool
			}?,
			address: Address
		){ 
			self.uuid = uuid
			self.id = id
			self.name = name
			self.description = description
			self.collection = collection
			self.collectionId = collectionId
			self.metadata = metadata
			self.media = media
			self.images = images
			self.videos = videos
			self.externalURL = externalURL
			self.rarity = rarity
			self.traits = traits
			self.characteristics = characteristics
			self.coCreatable = coCreatable
			self.coCreator = coCreator
			self.isRevealed = isRevealed
			self.editions = editions
			self.originalRecipient = originalRecipient
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
			self.revealableTraits = revealableTraits
			self.address = address
		}
	}
	
	// -----------------------------------------------------------------------
	// AccessPass Contract Views
	// -----------------------------------------------------------------------
	access(all)
	struct AccessPassMetadataViewV2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		// The id of the NFT within the promotion
		access(all)
		let edition: UInt64
		
		access(all)
		let variant: String
		
		access(all)
		let description: String
		
		access(all)
		let file: String
		
		access(all)
		let dateReceived: UFix64
		
		// Points to a promotion
		access(all)
		let promotionId: UInt64
		
		access(all)
		let promotionHost: Address
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let accessUnits: UInt8
		
		access(all)
		let initialAccessUnits: UInt8
		
		access(all)
		let metadataId: UInt64?
		
		access(all)
		let metadata:{ String: String}?
		
		access(all)
		let extraMetadata:{ String: String}?
		
		access(all)
		let royalties: [MetadataViews.Royalty]
		
		access(all)
		let royaltiesTFMarketplace: [TheFabricantMetadataViewsV2.Royalty]
		
		access(all)
		let owner: Address
		
		init(
			id: UInt64,
			season: String,
			campaignName: String,
			promotionName: String,
			edition: UInt64,
			variant: String,
			description: String,
			file: String,
			dateReceived: UFix64,
			promotionId: UInt64,
			promotionHost: Address,
			originalRecipient: Address,
			accessUnits: UInt8,
			initialAccessUnits: UInt8,
			metadataId: UInt64?,
			metadata:{ 
				String: String
			}?,
			extraMetadata:{ 
				String: String
			}?,
			royalties: [
				MetadataViews.Royalty
			],
			royaltiesTFMarketplace: [
				TheFabricantMetadataViewsV2.Royalty
			],
			owner: Address
		){ 
			self.id = id
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.edition = edition
			self.variant = variant
			self.description = description
			self.file = file
			self.dateReceived = dateReceived
			self.promotionId = promotionId
			self.promotionHost = promotionHost
			self.metadataId = metadataId
			self.metadata = metadata
			self.originalRecipient = originalRecipient
			self.accessUnits = accessUnits
			self.initialAccessUnits = initialAccessUnits
			self.extraMetadata = extraMetadata
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
			self.owner = owner
		}
	}
	
	access(all)
	struct IdentifierV2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		access(all)
		let promotionId: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let variant: String
		
		access(all)
		let address: Address
		
		access(all)
		let dateReceived: UFix64
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let accessUnits: UInt8
		
		access(all)
		let initialAccessUnits: UInt8
		
		access(all)
		let metadataId: UInt64?
		
		init(
			season: String,
			campaignName: String,
			promotionName: String,
			promotionId: UInt64,
			edition: UInt64,
			variant: String,
			id: UInt64,
			address: Address,
			dateReceived: UFix64,
			originalRecipient: Address,
			accessUnits: UInt8,
			initialAccessUnits: UInt8,
			metadataId: UInt64?
		){ 
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.promotionId = promotionId
			self.edition = edition
			self.variant = variant
			self.id = id
			self.address = address
			self.dateReceived = dateReceived
			self.originalRecipient = originalRecipient
			self.accessUnits = accessUnits
			self.initialAccessUnits = initialAccessUnits
			self.metadataId = metadataId
		}
	}
	
	access(all)
	struct PromotionMetadataViewV2{ 
		access(all)
		var active: Bool
		
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String?
		
		access(all)
		var isAccessListUsed: Bool
		
		access(all)
		var onlyUseAccessList: Bool
		
		access(all)
		var isOpenAccess: Bool
		
		access(all)
		let typeRestrictions: [Type]?
		
		access(all)
		var promotionAccessIds: [UInt64]?
		
		access(all)
		var nftsUsedForClaim:{ UInt64: TheFabricantMetadataViewsV2.IdentifierV2}
		
		access(all)
		var addressesClaimed:{ Address: [TheFabricantMetadataViewsV2.IdentifierV2]}
		
		access(all)
		let dateCreated: UFix64
		
		access(all)
		let description: String
		
		access(all)
		let maxMintsPerAddress: Int?
		
		access(all)
		let host: Address
		
		access(all)
		let image: String?
		
		access(all)
		let accessPassMetadatas:{ UInt64:{ String: String}}?
		
		access(all)
		let publicMinterPaths: [String]
		
		access(all)
		let totalSupply: UInt64
		
		access(all)
		let url: String?
		
		access(all)
		let spentAccessUnits:{ UInt64: [TheFabricantMetadataViewsV2.SpentAccessUnitView]}
		
		// Options
		access(all)
		let capacity: UInt64?
		
		access(all)
		let startTime: UFix64?
		
		access(all)
		let endTime: UFix64?
		
		access(all)
		let isOpen: Bool
		
		init(
			active: Bool,
			id: UInt64,
			season: String,
			campaignName: String,
			promotionName: String?,
			isAccessListUsed: Bool,
			onlyUseAccessList: Bool,
			isOpenAccess: Bool,
			typeRestrictions: [
				Type
			]?,
			promotionAccessIds: [
				UInt64
			]?,
			nftsUsedForClaim:{ 
				UInt64: TheFabricantMetadataViewsV2.IdentifierV2
			},
			addressesClaimed:{ 
				Address: [
					TheFabricantMetadataViewsV2.IdentifierV2
				]
			},
			dateCreated: UFix64,
			description: String,
			maxMintsPerAddress: Int?,
			host: Address,
			image: String?,
			accessPassMetadatas:{ 
				UInt64:{ 
					String: String
				}
			}?,
			publicMinterPaths: [
				String
			],
			totalSupply: UInt64,
			url: String?,
			spentAccessUnits:{ 
				UInt64: [
					TheFabricantMetadataViewsV2.SpentAccessUnitView
				]
			},
			capacity: UInt64?,
			startTime: UFix64?,
			endTime: UFix64?,
			isOpen: Bool
		){ 
			self.active = active
			self.id = id
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.isAccessListUsed = isAccessListUsed
			self.onlyUseAccessList = onlyUseAccessList
			self.isOpenAccess = isOpenAccess
			self.typeRestrictions = typeRestrictions
			self.promotionAccessIds = promotionAccessIds
			self.nftsUsedForClaim = nftsUsedForClaim
			self.addressesClaimed = addressesClaimed
			self.dateCreated = dateCreated
			self.description = description
			self.maxMintsPerAddress = maxMintsPerAddress
			self.host = host
			self.image = image
			self.accessPassMetadatas = accessPassMetadatas
			self.publicMinterPaths = publicMinterPaths
			self.totalSupply = totalSupply
			self.url = url
			self.spentAccessUnits = spentAccessUnits
			self.capacity = capacity
			self.startTime = startTime
			self.endTime = endTime
			self.isOpen = isOpen
		}
	}
	
	access(all)
	struct PromotionAccessPassHoldersV2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let currentHolders:{ UInt64: TheFabricantMetadataViewsV2.IdentifierV2}
		
		init(
			id: UInt64,
			host: Address,
			currentHolders:{ 
				UInt64: TheFabricantMetadataViewsV2.IdentifierV2
			}
		){ 
			self.id = id
			self.host = host
			self.currentHolders = currentHolders
		}
	}
	
	access(all)
	struct PromotionAccessPassClaimsV2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let claims:{ Address: [IdentifierV2]}
		
		init(
			id: UInt64,
			host: Address,
			claimed:{ 
				Address: [
					TheFabricantMetadataViewsV2.IdentifierV2
				]
			}
		){ 
			self.id = id
			self.host = host
			self.claims = claimed
		}
	}
	
	access(all)
	struct PromotionAccessList{ 
		access(all)
		let id: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let accessList: [Address]?
		
		access(all)
		var isAccessListUsed: Bool
		
		access(all)
		var onlyUseAccessList: Bool
		
		init(
			id: UInt64,
			host: Address,
			accessList: [
				Address
			]?,
			isAccessListUsed: Bool,
			onlyUseAccessList: Bool
		){ 
			self.id = id
			self.host = host
			self.accessList = accessList
			self.isAccessListUsed = isAccessListUsed
			self.onlyUseAccessList = onlyUseAccessList
		}
	}
	
	access(all)
	struct SpentAccessUnitView{ 
		access(all)
		let spender: Address
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		access(all)
		let promotionId: UInt64
		
		access(all)
		let variant: String?
		
		access(all)
		let accessPassId: UInt64
		
		access(all)
		let accessPassSerial: UInt64
		
		access(all)
		let accessTokenId: UInt64
		
		init(
			spender: Address,
			season: String,
			campaignName: String,
			promotionName: String,
			promotionId: UInt64,
			variant: String?,
			accessPassId: UInt64,
			accessPassSerial: UInt64,
			accessTokenId: UInt64
		){ 
			self.spender = spender
			self.season = season
			self.promotionId = promotionId
			self.promotionName = promotionName
			self.campaignName = campaignName
			self.variant = variant
			self.accessPassId = accessPassId
			self.accessPassSerial = accessPassSerial
			self.accessTokenId = accessTokenId
		}
	}
	
	access(all)
	struct PublicMinterView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		access(all)
		let promotionId: UInt64
		
		access(all)
		let variant: String
		
		access(all)
		let nftFile: String
		
		access(all)
		let nftMetadataId: UInt64?
		
		access(all)
		let nftNumberOfAccessUnits: UInt8
		
		access(all)
		var numberOfMints: UInt64
		
		init(
			id: UInt64,
			season: String,
			campaignName: String,
			promotionName: String,
			promotionId: UInt64,
			nftFile: String,
			nftMetadataId: UInt64?,
			nftNumberOfAccessUnits: UInt8,
			variant: String,
			numberOfMints: UInt64
		){ 
			self.id = id
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.promotionId = promotionId
			self.nftFile = nftFile
			self.nftMetadataId = nftMetadataId
			self.nftNumberOfAccessUnits = nftNumberOfAccessUnits
			self.variant = variant
			self.numberOfMints = numberOfMints
		}
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let initialCut: UFix64
		
		access(all)
		let cut: UFix64
		
		access(all)
		let description: String
		
		/// @param wallet : The wallet to send royalty too
		init(
			receiver: Capability<&{FungibleToken.Receiver}>,
			initialCut: UFix64,
			cut: UFix64,
			description: String
		){ 
			self.receiver = receiver
			self.initialCut = initialCut
			self.cut = cut
			self.description = description
		}
	}
	
	access(all)
	struct Royalties{ 
		
		/// Array that tracks the individual royalties
		access(self)
		let cutInfos: [Royalty]
		
		access(all)
		init(_ cutInfos: [Royalty]){ 
			// Validate that sum of all cut multipliers should not be greater than 1.0
			var totalCut = 0.0
			for royalty in cutInfos{ 
				totalCut = totalCut + royalty.cut
			}
			assert(
				totalCut <= 1.0,
				message: "Sum of cutInfos multipliers should not be greater than 1.0"
			)
			// Assign the cutInfos
			self.cutInfos = cutInfos
		}
		
		/// Return the cutInfos list
		access(all)
		fun getRoyalties(): [Royalty]{ 
			return self.cutInfos
		}
	}
	
	// -----------------------------------------------------------------------
	// OLD IMPLEMENTATIONS
	// -----------------------------------------------------------------------
	access(all)
	struct AccessPassMetadataView{ 
		access(all)
		let id: UInt64
		
		// The id of the NFT within the promotion
		access(all)
		let serial: UInt64
		
		access(all)
		let campaignName: String
		
		access(all)
		let variant: String
		
		access(all)
		let description: String
		
		access(all)
		let file: String
		
		access(all)
		let dateReceived: UFix64
		
		// Points to a promotion
		access(all)
		let promotionId: UInt64
		
		access(all)
		let promotionHost: Address
		
		access(all)
		let metadataId: UInt64?
		
		access(all)
		let metadata:{ String: String}?
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let accessUnits: UInt8
		
		access(all)
		let initialAccessUnits: UInt8
		
		access(all)
		let extraMetadata:{ String: String}?
		
		access(all)
		let owner: Address
		
		init(
			id: UInt64,
			serial: UInt64,
			campaignName: String,
			variant: String,
			description: String,
			file: String,
			dateReceived: UFix64,
			promotionId: UInt64,
			promotionHost: Address,
			metadataId: UInt64?,
			metadata:{ 
				String: String
			}?,
			originalRecipient: Address,
			accessUnits: UInt8,
			initialAccessUnits: UInt8,
			extraMetadata:{ 
				String: String
			}?,
			owner: Address
		){ 
			self.id = id
			self.serial = serial
			self.campaignName = campaignName
			self.variant = variant
			self.description = description
			self.file = file
			self.dateReceived = dateReceived
			self.promotionId = promotionId
			self.promotionHost = promotionHost
			self.metadataId = metadataId
			self.metadata = metadata
			self.originalRecipient = originalRecipient
			self.accessUnits = accessUnits
			self.initialAccessUnits = initialAccessUnits
			self.extraMetadata = extraMetadata
			self.owner = owner
		}
	}
	
	access(all)
	struct Identifier{ 
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		access(all)
		let promotionId: UInt64
		
		access(all)
		let variant: String
		
		access(all)
		let id: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let address: Address
		
		access(all)
		let dateReceived: UFix64
		
		access(all)
		let originalRecipient: Address
		
		access(all)
		let accessUnits: UInt8
		
		access(all)
		let initialAccessUnits: UInt8
		
		access(all)
		let metadataId: UInt64?
		
		init(
			season: String,
			campaignName: String,
			promotionName: String,
			promotionId: UInt64,
			variant: String,
			id: UInt64,
			serial: UInt64,
			address: Address,
			dateReceived: UFix64,
			originalRecipient: Address,
			accessUnits: UInt8,
			initialAccessUnits: UInt8,
			metadataId: UInt64?
		){ 
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.promotionId = promotionId
			self.variant = variant
			self.id = id
			self.serial = serial
			self.address = address
			self.dateReceived = dateReceived
			self.originalRecipient = originalRecipient
			self.accessUnits = accessUnits
			self.initialAccessUnits = initialAccessUnits
			self.metadataId = metadataId
		}
	}
	
	access(all)
	struct PromotionMetadataView{ 
		access(all)
		var active: Bool
		
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String?
		
		access(all)
		var isAccessListUsed: Bool
		
		access(all)
		var onlyUseAccessList: Bool
		
		access(all)
		var isOpenAccess: Bool
		
		access(all)
		let typeRestrictions: [Type]?
		
		access(all)
		var promotionAccessIds: [UInt64]?
		
		access(all)
		var nftsUsedForClaim:{ UInt64: TheFabricantMetadataViewsV2.Identifier}
		
		access(all)
		var addressesClaimed:{ Address: [TheFabricantMetadataViewsV2.Identifier]}
		
		access(all)
		let dateCreated: UFix64
		
		access(all)
		let description: String
		
		access(all)
		let maxMintsPerAddress: Int?
		
		access(all)
		let host: Address
		
		access(all)
		let image: String?
		
		access(all)
		let accessPassMetadatas:{ UInt64:{ String: String}}?
		
		access(all)
		let publicMinterPaths: [String]
		
		access(all)
		let totalSupply: UInt64
		
		access(all)
		let url: String?
		
		access(all)
		let spentAccessUnits:{ UInt64: [TheFabricantMetadataViewsV2.SpentAccessUnitView]}
		
		// Options
		access(all)
		let capacity: UInt64?
		
		access(all)
		let startTime: UFix64?
		
		access(all)
		let endTime: UFix64?
		
		access(all)
		let isOpen: Bool
		
		init(
			active: Bool,
			id: UInt64,
			season: String,
			campaignName: String,
			promotionName: String?,
			isAccessListUsed: Bool,
			onlyUseAccessList: Bool,
			isOpenAccess: Bool,
			typeRestrictions: [
				Type
			]?,
			promotionAccessIds: [
				UInt64
			]?,
			nftsUsedForClaim:{ 
				UInt64: TheFabricantMetadataViewsV2.Identifier
			},
			addressesClaimed:{ 
				Address: [
					TheFabricantMetadataViewsV2.Identifier
				]
			},
			dateCreated: UFix64,
			description: String,
			maxMintsPerAddress: Int?,
			host: Address,
			image: String?,
			accessPassMetadatas:{ 
				UInt64:{ 
					String: String
				}
			}?,
			publicMinterPaths: [
				String
			],
			totalSupply: UInt64,
			url: String?,
			spentAccessUnits:{ 
				UInt64: [
					TheFabricantMetadataViewsV2.SpentAccessUnitView
				]
			},
			capacity: UInt64?,
			startTime: UFix64?,
			endTime: UFix64?,
			isOpen: Bool
		){ 
			self.active = active
			self.id = id
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.isAccessListUsed = isAccessListUsed
			self.onlyUseAccessList = onlyUseAccessList
			self.isOpenAccess = isOpenAccess
			self.typeRestrictions = typeRestrictions
			self.promotionAccessIds = promotionAccessIds
			self.nftsUsedForClaim = nftsUsedForClaim
			self.addressesClaimed = addressesClaimed
			self.dateCreated = dateCreated
			self.description = description
			self.maxMintsPerAddress = maxMintsPerAddress
			self.host = host
			self.image = image
			self.accessPassMetadatas = accessPassMetadatas
			self.publicMinterPaths = publicMinterPaths
			self.totalSupply = totalSupply
			self.url = url
			self.spentAccessUnits = spentAccessUnits
			self.capacity = capacity
			self.startTime = startTime
			self.endTime = endTime
			self.isOpen = isOpen
		}
	}
	
	access(all)
	struct PromotionAccessPassHolders{ 
		access(all)
		let id: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let currentHolders:{ UInt64: TheFabricantMetadataViewsV2.Identifier}
		
		init(
			id: UInt64,
			host: Address,
			currentHolders:{ 
				UInt64: TheFabricantMetadataViewsV2.Identifier
			}
		){ 
			self.id = id
			self.host = host
			self.currentHolders = currentHolders
		}
	}
	
	access(all)
	struct PromotionAccessPassClaims{ 
		access(all)
		let id: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let claims:{ Address: [Identifier]}
		
		init(
			id: UInt64,
			host: Address,
			claimed:{ 
				Address: [
					TheFabricantMetadataViewsV2.Identifier
				]
			}
		){ 
			self.id = id
			self.host = host
			self.claims = claimed
		}
	}
}
