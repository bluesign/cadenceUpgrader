// The TheFabricantAccessPass NFT (AP) is a resource that can be used by holders to gain access to
// different parts of the platform, at all levels of the architecture (FE/BE/BC)
// The main principle behind the AP is it contains AccessUnits. These can be spent
// by the user. When spent, they produce an AccessUnitSpent event, an AccessToken
// resource, and a dictionary in the associated Promotion is updated to indicate
// that a unit was spent. Any of these three 'signals' can be used to confirm that
// an access unit has been spent.
// An access unit might be spent for any number of reasons - it might provide a 
// free mint, it might provide access to an area of the platform, or could 
// even be used to mint another access pass. The AccessUnits could also be used 
// to model open/closed (1/0), if for example the AccessPass were to represent an envelope.

// Central to the contract is the PublicMinter. This is created by the Promotions (admin)
// resource and is used to allow for user-initiated (pull) airdrops, where the user
// mints the AccessPass into their account. This is only possible if the user meets
// criteria defined within the PublicMinter, which are specified when the PublicMinter
// is created.

// All PublicMinters are associated with a Promotion (notice singular). A Promotion holds many
// of the properties that the PublicMinter passes to the AccessPass when one is minted.

// Metadata can be added to a promotion that can be used by AccessPass's.
// The metadata is stored under a UInt64, so there can be multiple dictionaries
// of metadata, each targetting a different group of APs.

// Campaign names must be unique; this makes pulling out campaign specific data easier
// You can have different minters for different variants with different extra metadata
// This is done by setting accessPassMetadatas in the promotion.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TheFabricantMetadataViews from "./TheFabricantMetadataViews.cdc"

access(all)
contract TheFabricantAccessPass: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// Paths
	// -----------------------------------------------------------------------
	access(all)
	let TheFabricantAccessPassCollectionStoragePath: StoragePath
	
	access(all)
	let TheFabricantAccessPassCollectionPublicPath: PublicPath
	
	access(all)
	let PromotionStoragePath: StoragePath
	
	access(all)
	let PromotionPublicPath: PublicPath
	
	access(all)
	let PromotionsStoragePath: StoragePath
	
	access(all)
	let PromotionsPublicPath: PublicPath
	
	access(all)
	let PromotionsPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// TheFabricantAccessPassNFT contract Events
	// -----------------------------------------------------------------------
	// -----------------------------------------------------------------------
	// Contract
	// Emitted when the contract is deployed
	access(all)
	event ContractInitialized()
	
	// -----------------------------------------------------------------------
	// NFT/TheFabricantAccessPass
	// Emitted when an NFT is minted
	access(all)
	event TheFabricantAccessPassMinted(id: UInt64, season: String, campaignName: String, promotionName: String, variant: String, description: String, file: String, dateReceived: UFix64, promotionId: UInt64, promotionHost: Address, metadataId: UInt64?, originalRecipient: Address, serial: UInt64, noOfAccessUnits: UInt8, extraMetadata:{ String: String}?)
	
	// Emitted when an NFT is destroyed
	access(all)
	event TheFabricantAccessPassDestroyed(id: UInt64, campaignName: String, variant: String, description: String, file: String, dateReceived: UFix64, promotionId: UInt64, promotionHost: Address, metadataId: UInt64?, originalRecipient: Address, serial: UInt64, noOfAccessUnits: UInt8, extraMetadata:{ String: String}?)
	
	access(all)
	event TheFabricantAccessPassClaimed(id: UInt64, campaignName: String, variant: String, description: String, file: String, dateReceived: UFix64, promotionId: UInt64, promotionHost: Address, metadataId: UInt64?, originalRecipient: Address, serial: UInt64, noOfAccessUnits: UInt8, extraMetadata:{ String: String}?, claimNftUuid: UInt64?)
	
	// Emitted when a TheFabricantAccessPass start date is set
	access(all)
	event TheFabricantAccessPassStartDateSet(id: UInt64, startDate: UFix64)
	
	// Emitted when a TheFabricantAccessPass end date is set
	access(all)
	event TheFabricantAccessPassEndDateSet(id: UInt64, endDate: UFix64)
	
	// Emitted when the AccessList is updated.
	access(all)
	event TheFabricantAccessPassAccessListUpdated(id: UInt64, addresses: [Address])
	
	// Emitted when an Access Unit is spent
	access(all)
	event AccessUnitSpent(promotionId: UInt64, accessPassId: UInt64, accessTokenId: UInt64, serial: UInt64, accessUnitsLeft: UInt8, owner: Address, metadataId: UInt64)
	
	access(all)
	event TheFabricantAccessPassTransferred(season: String, campaignName: String, promotionName: String, promotionId: UInt64, metadataId: UInt64?, variant: String, id: UInt64, serial: UInt64, from: Address, to: Address)
	
	// -----------------------------------------------------------------------
	// NFT Collection
	// Emitted when NFT is withdrawn
	access(all)
	event TheFabricantAccessPassWithdraw(id: UInt64, from: Address, promotionId: UInt64, serial: UInt64, accessUnits: UInt64, metadataId: UInt64)
	
	// Emitted when NFT is deposited
	access(all)
	event TheFabricantAccessPassDeposit(id: UInt64, to: Address, promotionId: UInt64, serial: UInt64, accessUnits: UInt8, metadataId: UInt64?)
	
	// -----------------------------------------------------------------------
	// Promotion
	access(all)
	event PromotionCreated(id: UInt64, season: String, campaignName: String, promotionName: String?, host: Address, promotionAccessIds: [UInt64]?, typeRestrictions: [Type]?, active: Bool, dateCreated: UFix64, description: String, image: String?, limited: Limited?, timelock: Timelock?, url: String?)
	
	access(all)
	event PromotionDestroyed(id: UInt64, host: Address, campaignName: String)
	
	access(all)
	event PromotionActiveChanged(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool)
	
	access(all)
	event PromotionIsAccessListUsedChanged(promotionId: UInt64, promotionHost: Address, campaignName: String, isAccessListUsed: Bool)
	
	access(all)
	event PromotionIsOpenAccessChanged(promotionId: UInt64, promotionHost: Address, campaignName: String, isOpenAccess: Bool)
	
	access(all)
	event PromotionOnlyUseAccessListChanged(promotionId: UInt64, promotionHost: Address, campaignName: String, onlyUseAccessList: Bool)
	
	access(all)
	event PromotionMetadataAdded(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool, metadata:{ UInt64:{ String: String}})
	
	access(all)
	event UpdatedAccessList(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool, newAddresses: [Address])
	
	access(all)
	event AddressRemovedFromAccessList(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool, addressRemoved: Address)
	
	access(all)
	event AccessListEmptied(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool)
	
	access(all)
	event UpdatedPromotionAccessIds(promotionId: UInt64, promotionHost: Address, campaignName: String, active: Bool, promotionAccessIds: [UInt64])
	
	// -----------------------------------------------------------------------
	// Promotions
	access(all)
	event PublicMinterCreated(id: UInt64, promotionId: UInt64, promotionHost: Address, campaignName: String, variant: String, nftMetadataId: UInt64?, typeRestrictions: [Type]?, promotionAccessIds: [UInt64]?, pathString: String)
	
	access(all)
	event PublicMinterDestroyed(path: String)
	
	// -----------------------------------------------------------------------
	// NFT Standard events throwaway
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// State
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalPromotions: UInt64
	
	// -----------------------------------------------------------------------
	// Access Pass Resource
	// -----------------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let season: String
		
		// Name of the campaign that the TheFabricantAccessPass is for eg StephyFung, WoW
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String
		
		// The id of the NFT within the promotion
		access(all)
		let serial: UInt64
		
		// The variant of the TheFabricantAccessPass within the campaign eg Rat_Poster, Pink_Purse
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
		
		// Use this to look in the associated metadata of the promotion
		// to find out what metadata it has been assigned.
		access(all)
		let metadataId: UInt64?
		
		access(all)
		let originalRecipient: Address
		
		// Used to provide access to promotions. Decremented when used.
		access(all)
		var accessUnits: UInt8
		
		access(all)
		let initialAccessUnits: UInt8
		
		// Allows additional String based metadata to be added outside of that associated with the PublicMinter
		access(self)
		var extraMetadata:{ String: String}?
		
		// In order for the AP NFT to be compatible with the TF MP and 
		// external MP's, we need two royalty structures. 
		// `royalties` is used by external MPs and
		// `royaltiesTFMarketplace` is used by TF MP.
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let royaltiesTFMarketplace: [TheFabricantMetadataViews.Royalty]
		
		// Used to access the details of the Promotion that this AP is assocaited with
		access(all)
		let promotionsCap: Capability<&Promotions>
		
		// Returns an AccessToken 
		access(all)
		fun spendAccessUnit(): @AccessToken{ 
			pre{ 
				self.accessUnits > 0:
					"Must have more than 0 access units to spend"
				self.promotionsCap.check():
					"The promotion this TheFabricantAccessPass came from has been deleted!"
			}
			post{ 
				before(self.accessUnits) == self.accessUnits + 1:
					"Access units must be decremented"
			}
			let promotions = self.promotionsCap.borrow()!
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("No promotion with id exists")
			
			// Some gated areas/activities may require an AccessToken for entry.
			// If no AccessToken is needed, it should be destroyed.
			// If an AccessToken is needed for entry, it should be stored
			// and then for record keeping purposes or for limiting access
			// further.
			let accessToken <- create AccessToken(spender: (self.owner!).address, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, promotionId: self.promotionId, accessPassId: self.id, accessPassSerial: self.serial, accessPassVariant: self.variant)
			emit AccessUnitSpent(promotionId: self.promotionId, accessPassId: self.id, accessTokenId: accessToken.id, serial: accessToken.id, accessUnitsLeft: self.accessUnits - 1, owner: self.owner?.address!, metadataId: self.serial)
			self.accessUnits = self.accessUnits - 1
			return <-accessToken
		}
		
		access(all)
		fun getExtraMetadata():{ String: String}?{ 
			return self.extraMetadata
		}
		
		access(all)
		fun getTFRoyalties(): [TheFabricantMetadataViews.Royalty]{ 
			return self.royaltiesTFMarketplace
		}
		
		access(all)
		fun getStandardRoyalties(): [MetadataViews.Royalty]{ 
			return self.royalties
		}
		
		// An AccessPass might have metadata associated with it that is provided
		// by the Promotion
		access(all)
		fun getPromotionMetadata():{ String: String}?{ 
			pre{ 
				self.promotionsCap.check():
					"promotions capability invalid"
			}
			if let promotions = self.promotionsCap.borrow(){ 
				let promotion: &Promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("promotion with id doesn't exist")
				if let metadataId = self.metadataId{ 
					if let metadatas = promotion.accessPassMetadatas{ 
						return *metadatas[metadataId]
					}
				}
				return nil
			}
			return nil
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<TheFabricantMetadataViews.AccessPassMetadataViewV2>(), Type<TheFabricantMetadataViews.IdentifierV2>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.campaignName.concat("_".concat(self.variant)), description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.file))
				case Type<TheFabricantMetadataViews.AccessPassMetadataViewV2>():
					return TheFabricantMetadataViews.AccessPassMetadataViewV2(id: self.id, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, edition: self.serial, variant: self.variant, description: self.description, file: self.file, dateReceived: self.dateReceived, promotionId: self.promotionId, promotionHost: self.promotionHost, originalRecipient: self.originalRecipient, accessUnits: self.accessUnits, initialAccessUnits: self.initialAccessUnits, metadataId: self.metadataId, metadata: self.getPromotionMetadata(), extraMetadata: self.extraMetadata, royalties: self.royalties, royaltiesTFMarketplace: self.royaltiesTFMarketplace, owner: (self.owner!).address)
				case Type<TheFabricantMetadataViews.IdentifierV2>():
					return TheFabricantMetadataViews.IdentifierV2(season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, promotionId: self.promotionId, edition: self.serial, variant: self.variant, id: self.id, address: (self.owner!).address, dateReceived: self.dateReceived, originalRecipient: self.originalRecipient, accessUnits: self.accessUnits, initialAccessUnits: self.initialAccessUnits, metadataId: self.metadataId)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(season: String, campaignName: String, promotionName: String, variant: String, description: String, file: String, promotionId: UInt64, promotionHost: Address, metadataId: UInt64?, originalRecipient: Address, serial: UInt64, accessUnits: UInt8, extraMetadata:{ String: String}?, royalties: [MetadataViews.Royalty], royaltiesTFMarketplace: [TheFabricantMetadataViews.Royalty]){ 
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.variant = variant
			self.description = description
			self.file = file
			self.promotionId = promotionId
			self.promotionHost = promotionHost
			self.metadataId = metadataId
			self.serial = serial
			self.accessUnits = accessUnits
			self.initialAccessUnits = accessUnits
			self.extraMetadata = extraMetadata
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
			self.promotionsCap = getAccount(promotionHost).capabilities.get<&TheFabricantAccessPass.Promotions>(TheFabricantAccessPass.PromotionsPublicPath)!
			TheFabricantAccessPass.totalSupply = TheFabricantAccessPass.totalSupply + 1
			self.id = self.uuid
			self.dateReceived = getCurrentBlock().timestamp
			self.originalRecipient = originalRecipient
			emit TheFabricantAccessPassMinted(id: self.id, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, variant: self.variant, description: self.description, file: self.file, dateReceived: self.dateReceived, promotionId: self.promotionId, promotionHost: self.promotionHost, metadataId: self.metadataId, originalRecipient: self.originalRecipient, serial: self.serial, noOfAccessUnits: self.accessUnits, extraMetadata: self.extraMetadata)
		}
	}
	
	// -----------------------------------------------------------------------
	// AccessToken Resource
	// -----------------------------------------------------------------------
	// Resource that is returned when an AccessUnit is spent.
	// It can be used to allow access at the contract level.
	// The promotionId can be checked to ensure that it is being
	// used for the correct promotion (see Verify in PublicMinter)
	// Its id should be checked to ensure that it is not being 
	// used multiple times.
	// Could also be stored as a sort of receipt.
	access(all)
	resource AccessToken{ 
		access(all)
		let spender: Address
		
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
		let accessPassId: UInt64
		
		access(all)
		let accessPassSerial: UInt64
		
		access(all)
		let accessPassVariant: String?
		
		init(spender: Address, season: String, campaignName: String, promotionName: String, promotionId: UInt64, accessPassId: UInt64, accessPassSerial: UInt64, accessPassVariant: String?){ 
			self.id = self.uuid
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.promotionId = promotionId
			self.spender = spender
			self.accessPassId = accessPassId
			self.accessPassSerial = accessPassSerial
			self.accessPassVariant = accessPassVariant
		}
	}
	
	// -----------------------------------------------------------------------
	// Collection Resource
	// -----------------------------------------------------------------------
	access(all)
	resource interface TheFabricantAccessPassCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTheFabricantAccessPass(id: UInt64): &NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Item reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getTheFabricantAccessPassIdsUsingPromoId(promoId: UInt64): [UInt64]?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: TheFabricantAccessPassCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var promotionIdsToTheFabricantAccessPassIds:{ UInt64: [UInt64]}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let accessPass <- token as! @NFT
			let promotionId = accessPass.promotionId
			if self.promotionIdsToTheFabricantAccessPassIds[promotionId] == nil{ 
				self.promotionIdsToTheFabricantAccessPassIds[promotionId] = []
			}
			(self.promotionIdsToTheFabricantAccessPassIds[promotionId]!).append(accessPass.id)
			let promotions: &Promotions = accessPass.promotionsCap.borrow() ?? panic("The Promotions Collection this TheFabricantAccessPass came from has been deleted")
			let promotion: &Promotion = promotions.getPromotionRef(id: promotionId) ?? panic("No promotion with id")
			promotion.transferred(season: accessPass.season, campaignName: accessPass.campaignName, promotionName: accessPass.promotionName, promotionId: promotionId, variant: accessPass.variant, id: accessPass.id, serial: accessPass.serial, to: (self.owner!).address, dateReceived: accessPass.dateReceived, originalRecipient: accessPass.originalRecipient, accessUnits: accessPass.accessUnits, initialAccessUnits: accessPass.initialAccessUnits, metadataId: accessPass.metadataId)
			log((self.owner!).address)
			emit TheFabricantAccessPassDeposit(id: accessPass.id, to: (self.owner!).address, promotionId: accessPass.promotionId, serial: accessPass.serial, accessUnits: accessPass.accessUnits, metadataId: accessPass.metadataId)
			let nft <- accessPass
			self.ownedNFTs[nft.id] <-! nft
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let accessPass <- token as! @NFT
			let promotionId = accessPass.promotionId
			// Unfortuntately firstIndexOf is not yet implemented so need to loop through to remove 
			// TheFabricantAccessPass id
			// self.promotionIdsToTheFabricantAccessPassIds[promotionId]!.firstIndex(of: withdrawID)
			let accessPassIds = self.promotionIdsToTheFabricantAccessPassIds[promotionId]!
			var indexOfTheFabricantAccessPassId: Int? = nil
			var i = 0
			while i < accessPassIds.length{ 
				if accessPassIds[i] == accessPass.id{ 
					indexOfTheFabricantAccessPassId = i
					break
				}
			}
			(self.promotionIdsToTheFabricantAccessPassIds[promotionId]!).remove(at: indexOfTheFabricantAccessPassId!)
			emit Withdraw(id: accessPass.id, from: self.owner?.address)
			let nft <- accessPass
			return <-nft
		}
		
		// Only returns IDs for TheFabricantAccessPass's whose promoCap is still in tact.
		// This ensures that you can only get the IDs of nfts from which you
		// can get the associated promo metadata
		access(all)
		view fun getIDs(): [UInt64]{ 
			let ids: [UInt64] = self.ownedNFTs.keys
			let response: [UInt64] = []
			for id in ids{ 
				let tokenRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let nftRef = tokenRef as! &NFT
				if nftRef.promotionsCap.check(){ 
					response.append(id)
				}
			}
			return response
		}
		
		access(all)
		fun getTheFabricantAccessPassIdsUsingPromoId(promoId: UInt64): [UInt64]?{ 
			return self.promotionIdsToTheFabricantAccessPassIds[promoId]
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowTheFabricantAccessPass(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let tokenRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = tokenRef as! &NFT
			return nftRef as &{ViewResolver.Resolver}
		}
		
		// Since TheFabricantAccessPass's can't be withdrawn, they can be deleted
		access(all)
		fun destroyTheFabricantAccessPass(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("You do not own this TheFabricantAccessPass")
			let nft <- token as! @NFT
			destroy nft
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
			self.promotionIdsToTheFabricantAccessPassIds ={} 
		}
	}
	
	// -----------------------------------------------------------------------
	// Promotion Resource 
	// -----------------------------------------------------------------------
	// This resource is created by the Promotions (admin) resource. It defines
	// many of the traits that are passed from the PublicMinter to the 
	// AccessPass's
	access(all)
	resource interface PromotionPublic{ 
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
		
		// Added because of bug in BC that prevents PromotionMetadataView from being populated in scripts
		access(all)
		fun getNftsUsedForClaim():{ UInt64: TheFabricantMetadataViews.Identifier}
	}
	
	// AccessList is separate to PromotionPublic interface as it may be so large
	// that it can use the max gas limit for scripts - thus it should be fetched
	// separately
	access(all)
	resource interface PromotionPublicAccessList{ 
		access(all)
		fun getAccessList(): [Address]
		
		access(all)
		fun accessListContains(address: Address): Bool?
	}
	
	access(all)
	resource interface PromotionAdminAccess{ 
		access(all)
		view fun isOpen(): Bool
		
		access(all)
		fun changeIsAccessListUsed(useAccessList: Bool)
		
		access(all)
		fun changeOnlyUseAccessList(onlyUseAccessList: Bool)
		
		access(all)
		fun changeIsOpenAccess(isOpenAccess: Bool)
		
		access(all)
		fun toggleActive(): Bool
		
		access(all)
		fun addMetadataForTheFabricantAccessPasses(metadatas: [{String: String}])
		
		access(all)
		fun addToAccessList(addresses: [Address])
		
		access(all)
		fun removeFromAccessList(address: Address)
		
		access(all)
		fun accessListContains(address: Address): Bool?
		
		access(all)
		fun emptyAccessList()
		
		access(all)
		fun addPromotionAccessIds(promotionIds: [UInt64])
		
		access(all)
		fun getSpentAccessUnits():{ UInt64: [TheFabricantMetadataViews.SpentAccessUnitView]}
	}
	
	access(all)
	resource Promotion: PromotionAdminAccess, PromotionPublic, PromotionPublicAccessList, ViewResolver.Resolver{ 
		// Toggle to turn the promo on or off manually (master switch)
		access(all)
		var active: Bool
		
		// This is a list of addresses that are allowed to access this promotion
		access(self)
		var accessList: [Address]
		
		// Used to determing if the AL should be used or not
		access(all)
		var isAccessListUsed: Bool
		
		// Used to restrict minting to the AL only. Useful for live tests
		access(all)
		var onlyUseAccessList: Bool
		
		// Anyone can mint if this is true
		access(all)
		var isOpenAccess: Bool
		
		// This is an array of resource types (eg NFTs) that the user must possess
		// in order to access this promotion. This allows minting to be restricted
		// to users that own particular NFTs or other resources.
		access(self)
		var typeRestrictions: [Type]?
		
		// A promotion can be restricted by an array of promotionIds.
		// This allows it to be accessed via an AccessToken.
		// If the accessToken is from a promotion that has a matching
		// promotionId, then access will be granted to minting.
		// For example, Admin creates Promotion A. Users mint APs
		// for Promotion A. Admin then creates a second Promotion,
		// Promotion B. Admin passes in the promotionId of Promotion A
		// to the promotionAccessIds property of Promotion B. Now holders
		// of AccessPass's from Promotion A can spend an AccessUnit to
		//  mint AccessPass's from Promotion B.
		access(self)
		var promotionAccessIds: [UInt64]?
		
		// Maps the uuid of the nft used for claiming to identifiers of the AP
		/*
					{uuid of nft used for claim: {
							id: uuid of AP
							serial: id of AP in promo
							address: original recipient of AP
							...
						}
					} 
				*/
		
		access(self)
		var nftsUsedForClaim:{ UInt64: TheFabricantMetadataViews.Identifier}
		
		// Maps the clamiant address to identifiers of the AP
		/*
					{Address: [{
							id: uuid of AP
							serial: id of AP in promo
							address: original recipient of AP
							...
						}]
					} 
				*/
		
		access(self)
		var addressesClaimed:{ Address: [TheFabricantMetadataViews.Identifier]}
		
		// Maps the serial number to the identifiers of the AP
		/*
					{serial: [{
							id: uuid of AP
							serial: id of AP in promo
							address: current holder of AP
							...
						}]
					} 
				*/
		
		access(self)
		var currentHolders:{ UInt64: TheFabricantMetadataViews.Identifier}
		
		access(all)
		let id: UInt64
		
		access(all)
		let season: String // Season is a string and not an int to give more flexibility JIC...
		
		
		access(all)
		let campaignName: String
		
		access(all)
		let promotionName: String // A promotion within a campaign eg Red Envelope in Stephy Fung  
		
		
		access(all)
		let dateCreated: UFix64
		
		access(all)
		let maxMintsPerAddress: Int?
		
		access(all)
		let description: String
		
		access(all)
		let host: Address
		
		access(all)
		let image: String?
		
		access(all)
		var totalSupply: UInt64
		
		access(all)
		let url: String?
		
		// A record of the AccessUnits that have been spent within promotion.
		// Everytime a user spends an AccessUnit of an AccessPass that was minted
		// from this Promotion, this dictionary updates.
		access(self)
		let spentAccessUnits:{ UInt64: [TheFabricantMetadataViews.SpentAccessUnitView]}
		
		// Two types of royalties are needed - those for in the TF MP, and those
		// in external MPs. All APs inherit their royalties from the Promotion
		// on initialisation. They cannot be modified once the AP is created.
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let royaltiesTFMarketplace: [TheFabricantMetadataViews.Royalty]
		
		// A single promotion can encapsulate multiple AccessPass variants.
		// For example, you might have a variant called "Rat". Assuming
		// that the metadata for Rat is the first one added to the 
		// accessPassMetadatas property, then metadataId = 0 should be used
		// to assign this metadata to the TheFabricantAccessPass.
		access(self)
		var nextMetadataId: UInt64
		
		access(all)
		var accessPassMetadatas:{ UInt64:{ String: String}}?
		
		// An array of the paths that the PublicMinter's for this promotion
		// are stored at
		access(self)
		var publicMinterPaths: [String]
		
		// Options
		access(all)
		let timelock: Timelock?
		
		access(all)
		let limited: Limited?
		
		access(all)
		view fun isOpen(): Bool{ 
			var open: Bool = true
			if let timelock = self.timelock{ 
				let currentTime = getCurrentBlock().timestamp
				if currentTime < timelock.dateStart || currentTime > timelock.dateEnding{ 
					open = false
				}
			}
			if let limited = self.limited{ 
				if self.totalSupply >= limited.capacity{ 
					open = false
				}
			}
			return self.active && open
		}
		
		access(all)
		fun changeIsOpenAccess(isOpenAccess: Bool){ 
			self.isOpenAccess = isOpenAccess
			emit PromotionIsOpenAccessChanged(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, isOpenAccess: self.isOpenAccess)
		}
		
		access(all)
		fun changeIsAccessListUsed(useAccessList: Bool){ 
			self.isAccessListUsed = useAccessList
			emit PromotionIsAccessListUsedChanged(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, isAccessListUsed: self.isAccessListUsed)
		}
		
		access(all)
		fun changeOnlyUseAccessList(onlyUseAccessList: Bool){ 
			self.onlyUseAccessList = onlyUseAccessList
			emit PromotionOnlyUseAccessListChanged(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, onlyUseAccessList: self.onlyUseAccessList)
		}
		
		// Toggle master switch
		access(all)
		fun toggleActive(): Bool{ 
			self.active = !self.active
			emit PromotionActiveChanged(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active)
			return self.active
		}
		
		access(all)
		fun addMetadataForTheFabricantAccessPasses(metadatas: [{String: String}]){ 
			self.accessPassMetadatas ={} 
			var i = 0
			while i < metadatas.length{ 
				(self.accessPassMetadatas!).insert(key: self.nextMetadataId, metadatas[i])
				self.nextMetadataId = self.nextMetadataId + 1
				i = i + 1
				emit PromotionMetadataAdded(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active, metadata: self.accessPassMetadatas!)
			}
		}
		
		access(all)
		fun getAccessList(): [Address]{ 
			return self.accessList
		}
		
		access(all)
		fun getTypeRestrictions(): [Type]?{ 
			return self.typeRestrictions
		}
		
		access(all)
		fun getPromotionAccessIds(): [UInt64]?{ 
			return self.promotionAccessIds
		}
		
		access(all)
		view fun getAddressesClaimed():{ Address: [TheFabricantMetadataViews.Identifier]}{ 
			return self.addressesClaimed
		}
		
		access(all)
		fun getNftsUsedForClaim():{ UInt64: TheFabricantMetadataViews.Identifier}{ 
			return self.nftsUsedForClaim
		}
		
		access(all)
		fun getCurrentHolders():{ UInt64: TheFabricantMetadataViews.Identifier}{ 
			return self.currentHolders
		}
		
		access(all)
		fun getSpentAccessUnits():{ UInt64: [TheFabricantMetadataViews.SpentAccessUnitView]}{ 
			return self.spentAccessUnits
		}
		
		access(all)
		fun getTFRoyalties(): [TheFabricantMetadataViews.Royalty]{ 
			return self.royaltiesTFMarketplace
		}
		
		access(all)
		fun getStandardRoyalties(): [MetadataViews.Royalty]{ 
			return self.royalties
		}
		
		access(account)
		fun updateAddressesClaimed(key: Address, _ value: TheFabricantMetadataViews.Identifier){ 
			if self.addressesClaimed[key] == nil{ 
				self.addressesClaimed[key] = []
			}
			(self.addressesClaimed[key]!).append(value)
		}
		
		access(account)
		fun addToPublicMinterPaths(path: String){ 
			self.publicMinterPaths.append(path)
		}
		
		access(all)
		fun addToAccessList(addresses: [Address]){ 
			if self.accessList == nil{ 
				self.accessList = []
			}
			let addressesAdded: [Address] = []
			for address in addresses{ 
				if !(self.accessList!).contains(address){ 
					(self.accessList!).append(address)
					addressesAdded.append(address)
				}
			}
			emit UpdatedAccessList(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active, newAddresses: addressesAdded)
		}
		
		access(all)
		fun removeFromAccessList(address: Address){ 
			var count = 0
			if !(self.accessList!).contains(address){ 
				panic("address is not in accessList")
			}
			for addr in self.accessList!{ 
				if addr == address{ 
					(self.accessList!).remove(at: count)
					emit AddressRemovedFromAccessList(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active, addressRemoved: address)
				}
				count = count + 1
			}
		}
		
		access(all)
		fun accessListContains(address: Address): Bool?{ 
			return self.accessList.contains(address)
		}
		
		access(all)
		fun emptyAccessList(){ 
			self.accessList = []
			emit AccessListEmptied(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active)
		}
		
		access(all)
		fun addPromotionAccessIds(promotionIds: [UInt64]){ 
			if self.promotionAccessIds == nil{ 
				self.promotionAccessIds = []
			}
			(self.promotionAccessIds!).concat(promotionIds)
			emit UpdatedPromotionAccessIds(promotionId: self.id, promotionHost: self.host, campaignName: self.campaignName, active: self.active, promotionAccessIds: self.promotionAccessIds!)
		}
		
		access(account)
		fun transferred(season: String, campaignName: String, promotionName: String, promotionId: UInt64, variant: String, id: UInt64, serial: UInt64, to: Address, dateReceived: UFix64, originalRecipient: Address, accessUnits: UInt8, initialAccessUnits: UInt8, metadataId: UInt64?){ 
			let identifier = TheFabricantMetadataViews.Identifier(season: season, campaignName: campaignName, promotionName: promotionName, promotionId: promotionId, variant: variant, id: id, serial: serial, address: to, dateReceived: dateReceived, originalRecipient: originalRecipient, accessUnits: accessUnits, initialAccessUnits: initialAccessUnits, metadataId: metadataId)
			self.currentHolders[serial] = identifier
			emit TheFabricantAccessPassTransferred(season: season, campaignName: campaignName, promotionName: promotionName, promotionId: promotionId, metadataId: metadataId, variant: variant, id: id, serial: serial, from: (self.owner!).address, to: to)
		}
		
		access(account)
		fun accountDeletedTheFabricantAccessPass(serial: UInt64){ 
			self.currentHolders.remove(key: serial)
		}
		
		// Used when a user pays for a public mint using an AccessToken. 
		// It doesn't save the AccessToken resource, instead it keeps a record of
		// it and the AT is destroyed in the mintTheFabricantAccessPass function 
		access(account)
		fun acceptAccessUnit(from: Address, season: String, campaignName: String, promotionName: String, promotionId: UInt64, variant: String?, accessPassId: UInt64, accessPassSerial: UInt64, accessTokenId: UInt64){ 
			let spentAccessUnit = TheFabricantMetadataViews.SpentAccessUnitView(spender: from, season: season, campaignName: campaignName, promotionName: promotionName, promotionId: promotionId, variant: variant, accessPassId: accessPassId, accessPassSerial: accessPassSerial, accessTokenId: accessTokenId)
			if self.spentAccessUnits[accessPassId] == nil{ 
				self.spentAccessUnits[accessPassId] = []
			}
			(self.spentAccessUnits[accessPassId]!).append(spentAccessUnit)
		}
		
		access(account)
		fun mint(recipient: Address, variant: String, numberOfAccessUnits: UInt8, file: String, metadataId: UInt64?, claimNftUuid: UInt64?): @NFT{ 
			pre{ 
				self.isOpen():
					"Promotion is not open"
			}
			post{ 
				self.totalSupply == before(self.totalSupply) + 1
			}
			self.totalSupply = self.totalSupply + 1
			let supply = self.totalSupply
			var metadata:{ String: String}? = nil
			if let _metadatas = self.accessPassMetadatas{ 
				// If there is accessPassMetadata provided, then the nft must have one
				if let _metadataId = metadataId{ 
					metadata = _metadatas[metadataId!]
				}
			}
			let nft <- create TheFabricantAccessPass.NFT(season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, variant: variant, description: self.description, file: file, promotionId: self.id, promotionHost: self.host, metadataId: metadataId, originalRecipient: recipient, serial: supply, accessUnits: numberOfAccessUnits, extraMetadata: metadata, royalties: self.royalties, royaltiesTFMarketplace: self.royaltiesTFMarketplace)
			let identifier = TheFabricantMetadataViews.Identifier(season: nft.season, campaignName: nft.campaignName, promotionName: nft.promotionName, promotionId: nft.promotionId, variant: nft.variant, id: nft.uuid, serial: nft.serial, address: recipient, dateReceived: nft.dateReceived, originalRecipient: nft.originalRecipient, accessUnits: nft.accessUnits, initialAccessUnits: nft.initialAccessUnits, metadataId: nft.metadataId)
			if let _claimNftUuid = claimNftUuid{ 
				self.nftsUsedForClaim.insert(key: _claimNftUuid, identifier)
			}
			return <-nft
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<TheFabricantMetadataViews.PromotionMetadataView>(), Type<TheFabricantMetadataViews.PromotionAccessPassClaims>(), Type<TheFabricantMetadataViews.PromotionAccessPassHolders>(), Type<TheFabricantMetadataViews.PromotionAccessList>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<TheFabricantMetadataViews.PromotionMetadataView>():
					return TheFabricantMetadataViews.PromotionMetadataView(active: self.active, id: self.id, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, isAccessListUsed: self.isAccessListUsed, onlyUseAccessList: self.onlyUseAccessList, isOpenAccess: self.isOpenAccess, typeRestrictions: self.typeRestrictions, promotionAccessIds: self.promotionAccessIds, nftsUsedForClaim: self.nftsUsedForClaim, addressesClaimed: self.addressesClaimed, dateCreated: self.dateCreated, description: self.description, maxMintsPerAddress: self.maxMintsPerAddress, host: self.host, image: self.image, accessPassMetadatas: self.accessPassMetadatas, publicMinterPaths: self.publicMinterPaths, totalSupply: self.totalSupply, url: self.url, spentAccessUnits: self.spentAccessUnits, capacity: self.limited?.capacity, startTime: self.timelock?.dateStart, endTime: self.timelock?.dateEnding, isOpen: self.isOpen())
				case Type<TheFabricantMetadataViews.PromotionAccessPassClaims>():
					return TheFabricantMetadataViews.PromotionAccessPassClaims(id: self.id, host: self.host, claimed: self.addressesClaimed)
				case Type<TheFabricantMetadataViews.PromotionAccessPassHolders>():
					return TheFabricantMetadataViews.PromotionAccessPassHolders(id: self.id, host: self.host, currentHolders: self.currentHolders)
				case Type<TheFabricantMetadataViews.PromotionAccessList>():
					return TheFabricantMetadataViews.PromotionAccessList(id: self.id, host: self.host, accessList: self.accessList, isAccessListUsed: self.isAccessListUsed, onlyUseAccessList: self.onlyUseAccessList)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.getStandardRoyalties())
				case Type<TheFabricantMetadataViews.Royalties>():
					return TheFabricantMetadataViews.Royalties(self.getTFRoyalties())
			}
			return nil
		}
		
		init(typeRestrictions: [Type]?, season: String, campaignName: String, promotionName: String, promotionAccessIds: [UInt64]?, description: String, maxMintsPerAddress: Int?, accessPassMetadatas:{ UInt64:{ String: String}}?, host: Address, image: String, limited: Limited?, timelock: Timelock?, url: String, royalties: [MetadataViews.Royalty], royaltiesTFMarketplace: [TheFabricantMetadataViews.Royalty]){ 
			self.season = season
			self.campaignName = campaignName
			self.promotionName = promotionName
			self.promotionAccessIds = promotionAccessIds
			self.active = true
			self.isAccessListUsed = true
			self.onlyUseAccessList = false
			self.isOpenAccess = false
			self.nftsUsedForClaim ={} 
			self.addressesClaimed ={} 
			self.currentHolders ={} 
			self.dateCreated = getCurrentBlock().timestamp
			self.description = description
			self.maxMintsPerAddress = maxMintsPerAddress
			self.host = host
			self.id = self.uuid
			self.image = image
			self.accessPassMetadatas = accessPassMetadatas
			self.totalSupply = 0
			self.url = url
			self.royalties = royalties
			self.royaltiesTFMarketplace = royaltiesTFMarketplace
			self.spentAccessUnits ={} 
			self.accessList = []
			self.typeRestrictions = typeRestrictions
			self.nextMetadataId = 0
			self.accessPassMetadatas ={} 
			self.publicMinterPaths = []
			self.timelock = timelock
			self.limited = limited
			TheFabricantAccessPass.totalPromotions = TheFabricantAccessPass.totalPromotions + 1
			emit PromotionCreated(id: self.id, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, host: self.host, promotionAccessIds: self.promotionAccessIds, typeRestrictions: self.typeRestrictions, active: self.active, dateCreated: self.dateCreated, description: self.description, image: self.image, limited: self.limited, timelock: self.timelock, url: self.url)
		}
	}
	
	access(all)
	struct Timelock{ 
		access(all)
		let dateStart: UFix64
		
		access(all)
		let dateEnding: UFix64
		
		access(account)
		fun verify(){ 
			assert(getCurrentBlock().timestamp >= self.dateStart, message: "Promotion hasn't started yet")
			assert(getCurrentBlock().timestamp <= self.dateEnding, message: "Promotion has ended")
		}
		
		init(dateStart: UFix64, dateEnding: UFix64){ 
			self.dateStart = dateStart
			self.dateEnding = dateEnding
		}
	}
	
	access(all)
	struct Limited{ 
		access(all)
		var capacity: UInt64
		
		access(account)
		fun verify(currentCapacity: UInt64){ 
			assert(currentCapacity < self.capacity, message: "This promotion is at max capacity")
		}
		
		init(capacity: UInt64){ 
			self.capacity = capacity
		}
	}
	
	// -----------------------------------------------------------------------
	// Promotions Resource
	// -----------------------------------------------------------------------
	// This is the admin resource, and is used to create a Promotion and the 
	// associated PublicMinter.
	access(all)
	resource interface PromotionsPublic{ 
		access(all)
		fun getAllPromotionsByName():{ String: UInt64}
		
		access(all)
		fun getPromotionsToPublicPath():{ UInt64: [String]}
		
		access(all)
		fun getPromotionPublic(id: UInt64): &TheFabricantAccessPass.Promotion?
	}
	
	access(all)
	resource interface PromotionsAccountAccess{ 
		access(account)
		view fun getPromotionRef(id: UInt64): &TheFabricantAccessPass.Promotion?
	}
	
	access(all)
	resource Promotions: PromotionsPublic, PromotionsAccountAccess, ViewResolver.ResolverCollection{ 
		// Campaign names must be unique; this makes pulling out campaign specific data easier
		// There might be multiple 'parts' to a campaign. For example, in StephyFung, we have the 
		// Red_Envelope promotion of the campaign, and then we have the Posters after this.
		access(account)
		var nameToId:{ String: UInt64}
		
		access(account)
		var promotions: @{UInt64: Promotion}
		
		access(account)
		var promotionsToPublicMinterPath:{ UInt64: [String]}
		
		access(all)
		fun createPromotion(typeRestrictions: [Type]?, season: String, campaignName: String, promotionName: String, promotionAccessIds: [UInt64]?, description: String, maxMintsPerAddress: Int, accessPassMetadatas:{ UInt64:{ String: String}}?, image: String, limited: Limited?, timelock: Timelock?, url: String, royalties: [MetadataViews.Royalty], royaltiesTFMarketplace: [TheFabricantMetadataViews.Royalty]){ 
			pre{ 
				self.nameToId[campaignName] == nil:
					"A promotion with this name already exists"
			}
			let promotion <- create Promotion(typeRestrictions: typeRestrictions, season: season, campaignName: campaignName, promotionName: promotionName, promotionAccessIds: promotionAccessIds, description: description, maxMintsPerAddress: maxMintsPerAddress, accessPassMetadatas: accessPassMetadatas, host: (self.owner!).address, image: image, limited: limited, timelock: timelock, url: url, royalties: royalties, royaltiesTFMarketplace: royaltiesTFMarketplace)
			self.nameToId[promotion.campaignName] = promotion.id
			self.promotions[promotion.id] <-! promotion
		}
		
		// You can only delete a promotion if 0 people are currently holding associated 
		// TheFabricantAccessPass's.
		access(all)
		fun deletePromotion(id: UInt64){ 
			let ref: &Promotion = self.getPromotionRef(id: id) ?? panic("Can't delete promotion, it doesn't exist!")
			let name: String = ref.campaignName
			self.nameToId.remove(key: name)
			let promotion <- self.promotions.remove(key: id)
			destroy promotion
		}
		
		// Used to access promotions internally
		access(account)
		view fun getPromotionRef(id: UInt64): &TheFabricantAccessPass.Promotion?{ 
			return &self.promotions[id] as &TheFabricantAccessPass.Promotion?
		}
		
		access(all)
		fun getAllPromotionsByName():{ String: UInt64}{ 
			return self.nameToId
		}
		
		access(all)
		fun getPromotionsToPublicPath():{ UInt64: [String]}{ 
			return self.promotionsToPublicMinterPath
		}
		
		access(all)
		fun getPromotionPublic(id: UInt64): &TheFabricantAccessPass.Promotion?{ 
			return &self.promotions[id] as &TheFabricantAccessPass.Promotion?
		}
		
		// Used by admin in txs to access Promotion level functions
		access(all)
		fun borrowAdminPromotion(id: UInt64): &TheFabricantAccessPass.Promotion?{ 
			return &self.promotions[id] as &TheFabricantAccessPass.Promotion?
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.promotions.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let promoRef = self.getPromotionRef(id: id) ?? panic("Can't borrow view resolver, no promo with that ID!")
			return promoRef as &{ViewResolver.Resolver}
		}
		
		/*************************************** CLAIMING ***************************************/
		// NOTE:
		// The Public Minter is linked to public path of the admin after being initialised with 
		// access criteria, if any. It allows anyone to mint an AccessPass, so long as they have 
		// the public path and are either in the AccessList, in possession of the required NFTs, 
		// or can provide an AccessToken from an accepted Promotion.
		// The metadataId can be provided if this minter should be restricted to 
		// only a particular variant in the promotion (eg 20% discount). By setting
		// the metadataId, any nfts minted using this minter will use the associated metadata.
		// 
		// The minter is saved in storage and linked publicly at:
		// SSeason_CampaignName_PromotionName_PromotionId_MetadataId <- we must prepend 'S' as path can't start with number or special characters, and Season is likely number
		// S2_StephyFung_RedEnvelope_123_456
		// If metadataId is not provided, then it is not included. 
		access(all)
		fun createPublicMinter(nftFile: String, nftNumberOfAccessUnits: UInt8, promotionId: UInt64, metadataId: UInt64?, variant: String){ 
			// This is passed into the PublicMinter
			let promotionsCap = getAccount((self.owner!).address).capabilities.get<&Promotions>(TheFabricantAccessPass.PromotionsPublicPath)
			let promotion = self.getPromotionRef(id: promotionId) ?? panic("No promotion with this Id exists")
			let season = promotion.season
			let campaignName = promotion.campaignName
			let promotionName = promotion.promotionName
			let accessList = promotion.getAccessList()
			let typeRestrictions = promotion.getTypeRestrictions()
			let promotionAccessIds = promotion.getPromotionAccessIds()
			var pathString = "S".concat(season).concat("_").concat(campaignName).concat("_").concat(promotionName).concat("_").concat(promotionId.toString())
			if let _metadataId = metadataId{ 
				pathString = pathString.concat("_").concat(_metadataId.toString())
			}
			promotion.addToPublicMinterPaths(path: pathString)
			let publicMinterStoragePath = StoragePath(identifier: pathString)
			let publicMinterPublicPath = PublicPath(identifier: pathString)
			let publicMinter <- create PublicMinter(nftFile: nftFile, nftNumberOfAccessUnits: nftNumberOfAccessUnits, promotionId: promotionId, variant: variant, nftMetadataId: metadataId, promoCap: promotionsCap!)
			log("***PathString")
			log(pathString)
			log("***Public")
			log(publicMinterPublicPath)
			log("***Storage")
			log(publicMinterStoragePath)
			if self.promotionsToPublicMinterPath[promotionId] == nil{ 
				self.promotionsToPublicMinterPath.insert(key: promotionId, [pathString])
			} else{ 
				(self.promotionsToPublicMinterPath[promotionId]!).append(pathString)
			}
			emit PublicMinterCreated(id: publicMinter.id, promotionId: publicMinter.promotionId, promotionHost: promotion.host, campaignName: publicMinter.campaignName, variant: publicMinter.variant, nftMetadataId: publicMinter.nftMetadataId, typeRestrictions: promotion.getTypeRestrictions(), promotionAccessIds: promotion.getPromotionAccessIds(), pathString: pathString)
			
			// Link the Public Minter to a Public Path of the admin account
			TheFabricantAccessPass.account.storage.save(<-publicMinter, to: publicMinterStoragePath!)
			TheFabricantAccessPass.account.link<&PublicMinter>(publicMinterPublicPath!, target: publicMinterStoragePath!)
		}
		
		access(all)
		fun destroyPublicMinter(publicMinterPath: String){ 
			let storagePath = StoragePath(identifier: publicMinterPath) ?? panic("Couldn't construct storage path from string")
			let minter <- TheFabricantAccessPass.account.storage.load<@PublicMinter>(from: storagePath)
			destroy minter
			emit PublicMinterDestroyed(path: publicMinterPath)
		}
		
		access(all)
		fun distributeDirectly(promotionId: UInt64, variant: String, recipient: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, numberOfAccessUnits: UInt8, file: String, metadataId: UInt64?){ 
			let promo = self.getPromotionRef(id: promotionId) ?? panic("This promotion doesn't exist")
			let nft <- promo.mint(recipient: (recipient.owner!).address, variant: variant, numberOfAccessUnits: numberOfAccessUnits, file: file, metadataId: metadataId, claimNftUuid: nil)
			let token <- nft
			recipient.deposit(token: <-token)
		}
		
		/******************************************************************************/
		init(){ 
			self.nameToId ={} 
			self.promotionsToPublicMinterPath ={} 
			self.promotions <-{} 
		}
	}
	
	// -----------------------------------------------------------------------
	// PublicMinter Resource
	// -----------------------------------------------------------------------
	// PublicMinter is created by the Promotions resource. It allows users to
	// to mint an AccessPass so long as they have the public path for where it is stored
	// and meet the criteria (AccessList, resource ownership restrictions)
	access(all)
	resource interface IPublicMinter{ 
		access(all)
		fun getMinterData(): TheFabricantMetadataViews.PublicMinterView
		
		access(all)
		view fun isAccessListOnly(): Bool
		
		access(all)
		view fun promotionIsOpen(): Bool
		
		access(all)
		view fun getAddressesClaimed():{ Address: [TheFabricantMetadataViews.Identifier]}
		
		access(all)
		fun getnftsUsedForClaim():{ UInt64: TheFabricantMetadataViews.Identifier}
		
		access(all)
		fun mintUsingAccessList(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic})
		
		access(all)
		fun mintUsingNftRefs(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, refs: [&{NonFungibleToken.INFT}]?)
		
		access(all)
		fun mintUsingAccessToken(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, accessToken: @AccessToken)
	}
	
	access(all)
	resource PublicMinter: IPublicMinter{ 
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
		
		// This is the number of access units that the minted NFT gets (and can therefore spend)
		access(all)
		let nftNumberOfAccessUnits: UInt8
		
		access(self)
		var numberOfMints: UInt64
		
		// Used to pull all the metadata down from the promotion
		access(self)
		let promotionsCap: Capability<&Promotions>
		
		access(all)
		fun getMinterData(): TheFabricantMetadataViews.PublicMinterView{ 
			return TheFabricantMetadataViews.PublicMinterView(id: self.id, season: self.season, campaignName: self.campaignName, promotionName: self.promotionName, promotionId: self.promotionId, nftFile: self.nftFile, nftMetadataId: self.nftMetadataId, nftNumberOfAccessUnits: self.nftNumberOfAccessUnits, variant: self.variant, numberOfMints: self.numberOfMints)
		}
		
		access(self)
		fun nftHasBeenUsedForClaim(uuid: UInt64): Bool{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if nft has been used for claim")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if nft has been used for claim")
			let nftsUsedForClaim = promotion.getNftsUsedForClaim()
			return nftsUsedForClaim.keys.contains(uuid)
		}
		
		access(all)
		fun getnftsUsedForClaim():{ UInt64: TheFabricantMetadataViews.Identifier}{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if address in access list")
			return promotion.getNftsUsedForClaim()
		}
		
		access(self)
		fun nftsCanBeUsedForMint(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, refs: [&{NonFungibleToken.INFT}], promotion: &Promotion): Bool{ 
			let refTypes = promotion.getTypeRestrictions() ?? panic("There are no type restrictions for this promotion")
			assert(refTypes != nil, message: "There are no type restrictions for this promotion")
			var i = 0
			while i < refs.length{ 
				if refTypes.contains(refs[i].getType()) && !self.nftHasBeenUsedForClaim(uuid: refs[i].uuid) && (receiver.owner!).address == (refs[i].owner!).address{ 
					self.claimingNftUuid = refs[i].uuid
					return true
				}
				i = i + 1
			}
			return false
		}
		
		access(all)
		view fun getAddressesClaimed():{ Address: [TheFabricantMetadataViews.Identifier]}{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if address in access list")
			return promotion.getAddressesClaimed()
		}
		
		access(self)
		view fun addressHasClaimedMaxTheFabricantAccessPassLimit(address: Address): Bool{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address has been used for claim")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if address has been used for claim")
			let addressesClaimed = promotion.getAddressesClaimed()
			log("addresses claimed")
			log(addressesClaimed)
			log("maxMints")
			log(promotion.maxMintsPerAddress)
			if addressesClaimed.keys.contains(address){ 
				log("addressMints")
				log((addressesClaimed[address]!).length)
				if (addressesClaimed[address]!).length == promotion.maxMintsPerAddress{ 
					log("User has minted max number of access passes")
					return true
				}
			}
			return false
		}
		
		access(self)
		fun accessTokenIsValid(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, accessTokenOwner: Address, accessTokenPromoId: UInt64, promotion: &Promotion): Bool{ 
			if (promotion.getPromotionAccessIds()!).contains(accessTokenPromoId) && (receiver.owner!).address == accessTokenOwner{ 
				return true
			}
			return false
		}
		
		access(all)
		view fun promotionIsOpen(): Bool{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if address in access list")
			return promotion.isOpen()
		}
		
		access(all)
		view fun isAccessListOnly(): Bool{ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef to check if address in access list")
			return promotion.onlyUseAccessList
		}
		
		// mint not:
		// maxMint for this address has been hit √
		// maxCapacity has been hit √
		// promotion isn't open √
		// timelock has expired √
		// mint if:
		// openAccess √
		// OR address on access list AND accessListIsUsed √
		// If open access or access list only, use this function
		access(all)
		fun mintUsingAccessList(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}){ 
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef for mintTheFabricantAccessPass")
			self.claimingNftUuid = nil
			// If the promotion is not open access...
			if !promotion.isOpenAccess{ 
				assert(promotion.accessListContains(address: (receiver.owner!).address)! && promotion.isAccessListUsed, message: "Address isn't on the access list or the access list isn't used for this promotion")
			}
			self.mintAccessPass(receiver: receiver)
		}
		
		// This variable keeps track of the nftId that was used for the claim so that we can save it
		// It is saved during the mint() call in Promotion
		access(self)
		var claimingNftUuid: UInt64?
		
		// mint not:
		// accessListOnly √
		// maxMint for this address has been hit √
		// maxCapacity has been hit √
		// timelock has expired √
		// promotion isn't open √
		// no nft refs are provided √
		// mint if:
		// openAccess 
		// OR nft is of correct Type AND hasn't been used for claim before √
		access(all)
		fun mintUsingNftRefs(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, refs: [&{NonFungibleToken.INFT}]?){ 
			pre{ 
				!self.isAccessListOnly():
					"Only Access List can be used for this promotion"
				refs != nil || refs?.length != 0:
					"Please provide some nft references to check access"
			}
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef for mintTheFabricantAccessPass")
			self.claimingNftUuid = nil
			// If the promotion is not open access...
			if !promotion.isOpenAccess{ 
				assert(self.nftsCanBeUsedForMint(receiver: receiver, refs: refs!, promotion: promotion), message: "nft has been used for claim or is not correct Type")
			}
			self.mintAccessPass(receiver: receiver)
		}
		
		// mint not:
		// accessListOnly √
		// maxMint for this address has been hit √
		// maxCapacity has been hit √
		// timelock has expired √
		// promotion isn't open √
		// no promotionAccessIds provided √
		// mint if:
		// accessToken is valid
		access(all)
		fun mintUsingAccessToken(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}, accessToken: @AccessToken){ 
			pre{ 
				!self.isAccessListOnly():
					"Only Access List can be used for this promotion"
			}
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef for mintTheFabricantAccessPass")
			assert(!promotion.isOpenAccess, message: "Promotion is open access, please use mintUsingAccessList function")
			assert(promotion.getPromotionAccessIds() != nil || promotion.getPromotionAccessIds()?.length != 0, message: "No promotion access ids provided for this promotion")
			
			// We can't pass the access token resource into different 'if' statements 
			// as it is a resource, so we must extract the data here.
			var accessTokenOwner: Address = accessToken.spender
			var accessTokenPromoId: UInt64 = accessToken.promotionId
			self.claimingNftUuid = nil
			assert(self.accessTokenIsValid(receiver: receiver, accessTokenOwner: accessTokenOwner, accessTokenPromoId: accessTokenPromoId, promotion: promotion), message: "Access token is not valid")
			
			// If an accessToken was used to mint, save the details of the AT 
			let accessTokenPromotion = promotions.getPromotionRef(id: accessTokenPromoId!) ?? panic("Couldn't get promotionRef for AccessToken")
			promotion.acceptAccessUnit(from: accessToken.spender, season: accessTokenPromotion.season, campaignName: accessTokenPromotion.campaignName, promotionName: accessTokenPromotion.promotionName, promotionId: accessTokenPromoId, variant: accessToken.accessPassVariant, accessPassId: accessToken.uuid, accessPassSerial: accessToken.accessPassSerial, accessTokenId: accessToken.id)
			self.mintAccessPass(receiver: receiver)
			destroy accessToken
		}
		
		access(self)
		fun mintAccessPass(receiver: &{TheFabricantAccessPass.TheFabricantAccessPassCollectionPublic}){ 
			pre{ 
				!self.addressHasClaimedMaxTheFabricantAccessPassLimit(address: (receiver.owner!).address):
					"User has minted max number of access pass's"
				self.promotionIsOpen():
					"Promotion is not open yet"
			}
			log("tests passed, minting AP")
			let promotions = self.promotionsCap.borrow() ?? panic("Couldn't get promotions capability to check if address in access list")
			let promotion = promotions.getPromotionRef(id: self.promotionId) ?? panic("Couldn't get promotionRef for mintTheFabricantAccessPass")
			let nft <- promotion.mint(recipient: (receiver.owner!).address, variant: self.variant, numberOfAccessUnits: self.nftNumberOfAccessUnits, file: self.nftFile, metadataId: self.nftMetadataId, claimNftUuid: self.claimingNftUuid)
			promotion.updateAddressesClaimed(key: (receiver.owner!).address, TheFabricantMetadataViews.Identifier(season: nft.campaignName, campaignName: nft.season, promotionName: nft.promotionName, promotionId: nft.promotionId, variant: nft.variant, id: nft.id, serial: nft.serial, address: (receiver.owner!).address, dateReceived: nft.dateReceived, originalRecipient: nft.originalRecipient, accessUnits: nft.accessUnits, initialAccessUnits: nft.initialAccessUnits, metadataId: nft.metadataId))
			emit TheFabricantAccessPassClaimed(id: nft.id, campaignName: nft.campaignName, variant: nft.variant, description: nft.description, file: nft.file, dateReceived: getCurrentBlock().timestamp, promotionId: nft.promotionId, promotionHost: nft.promotionHost, metadataId: nft.metadataId, originalRecipient: (receiver.owner!).address, serial: nft.serial, noOfAccessUnits: nft.accessUnits, extraMetadata: nft.getExtraMetadata(), claimNftUuid: self.claimingNftUuid)
			receiver.deposit(token: <-nft)
		}
		
		init(nftFile: String, nftNumberOfAccessUnits: UInt8, promotionId: UInt64, variant: String, nftMetadataId: UInt64?, promoCap: Capability<&Promotions>){ 
			self.id = self.uuid
			self.nftFile = nftFile
			self.nftMetadataId = nftMetadataId
			self.nftNumberOfAccessUnits = nftNumberOfAccessUnits
			self.claimingNftUuid = nil
			self.promotionId = promotionId
			self.variant = variant
			self.promotionsCap = promoCap
			self.numberOfMints = 0
			let promotions = promoCap.borrow() ?? panic("No promo cap provided for public minter init")
			let promotion = promotions.getPromotionRef(id: promotionId) ?? panic("No promotion with that promotionId")
			self.season = promotion.season
			self.campaignName = promotion.campaignName
			self.promotionName = promotion.promotionName
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createEmptyPromotionsCollection(): @Promotions{ 
		return <-create Promotions()
	}
	
	init(){ 
		self.totalSupply = 0
		self.totalPromotions = 0
		emit ContractInitialized()
		self.TheFabricantAccessPassCollectionStoragePath = /storage/TheFabricantTheFabricantAccessPassCollection001
		self.TheFabricantAccessPassCollectionPublicPath = /public/TheFabricantTheFabricantAccessPassCollection001
		self.PromotionStoragePath = /storage/TheFabricantPromotionStoragePath001
		self.PromotionPublicPath = /public/TheFabricantPromotionPublicPath001
		self.PromotionsStoragePath = /storage/TheFabricantPromotionStoragePath001
		self.PromotionsPublicPath = /public/TheFabricantPromotionPublicPath001
		self.PromotionsPrivatePath = /private/TheFabricantPromotionPublicPath001
		
		// The Admin (Promotions) resource needs to be publicly linked
		// using {PromotionsAccountAccess, PromotionsPublic, MetadataViews.ResolverCollection}
		// for contract to function properly.
		self.account.storage.save(<-create Promotions(), to: self.PromotionsStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Promotions>(self.PromotionsStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PromotionsPublicPath)
	}
}
