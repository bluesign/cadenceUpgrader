/* 
*   A contract that manages the creation and sale of packs, cards and tokens
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import HWGarageTokenV2 from "./HWGarageTokenV2.cdc"

import HWGarageCardV2 from "./HWGarageCardV2.cdc"

import HWGaragePackV2 from "./HWGaragePackV2.cdc"

access(all)
contract HWGaragePMV2{ 
	/* 
		*   Events
		*
		*   emitted when the contract is deployed
		*/
	
	access(all)
	event ContractInitialized()
	
	/*
		 * HWGarageCardV2 Airdrop
		 */
	
	// emitted when a new pack series is added
	access(all)
	event AdminAddNewTokenSeries(tokenSeriesID: UInt64)
	
	access(all)
	event AdminMintToken(uuid: UInt64, id: UInt64, metadata:{ String: String})
	
	// emitted when an admin airdrops a redeemable card to an address
	access(all)
	event AirdropRedeemable(
		WalletAddress: Address,
		TokenID: UInt64,
		TokenMintID: String,
		OriginalCardSerial: String,
		TokenSerial: String,
		SeriesName: String,
		Name: String,
		TokenImageHash: String,
		TokenReleaseDate: String,
		TokenExpireDate: String,
		CardID: String,
		TemplateID: String
	)
	
	// emitted when a user initiates a burn on a redeemable airdrop
	access(all)
	event AirdropBurn(WalletAddress: Address, TokenSerial: String, AirdropEditionId: UInt64)
	
	/* 
		*   HWGarageCardV2
		*
		*   emmited when an admin has initiated a mint of a HWGarageCardV2
		*/
	
	access(all)
	event AdminMintCard(
		uuid: UInt64,
		id: UInt64,
		metadata:{ 
			String: String
		},
		packHash: String,
		address: Address
	)
	
	// emitted when a new pack series is added
	access(all)
	event AdminAddNewCardSeries(cardSeriesID: UInt64)
	
	// emmited when the metadata for an HWGarageCardV2 collection is updated
	access(all)
	event UpdateCardCollectionMetadata()
	
	/* 
		*   HWGaragePackV2
		*
		*/
	
	// emitted when a new pack series is added
	access(all)
	event AdminAddNewPackSeries(packSeriesID: UInt64)
	
	// emitted when an admin has initiated a mint of a HWGarageCardV2
	access(all)
	event AdminMintPack(
		uuid: UInt64,
		packHash: String,
		packSeriesID: UInt64,
		packID: UInt64 // aka packEditionID					  
					  ,
		metadata:{ 
			String: String
		}
	)
	
	// emitted when someone redeems a HWGarageCardV2 for Tokens
	access(all)
	event RedeemPack(
		id: UInt64,
		packID: UInt64 // aka packEditionID					  
					  ,
		packSeriesID: UInt64,
		address: Address,
		packHash: String
	)
	
	// emitted when a user submits a packHash to claim a pack
	access(all)
	event PackClaimBegin(address: Address, packHash: String)
	
	// emitted when a user successfully claims a pack
	access(all)
	event PackClaimSuccess(
		address: Address,
		packHash: String,
		packID: UInt64,
		seriesPackMintID: String
	)
	
	// emitted when a user begins a migration from Wax to Flow
	access(all)
	event ClaimBridgeAsset(waxWallet: String, assetIds: [String], flowWallet: Address)
	
	/// End of events  
	/* 
		*   Named Paths
		*/
	
	access(all)
	let ManagerStoragePath: StoragePath
	
	/* 
		*   HWGaragePMV2 fields
		*/
	
	access(self)
	var HWGaragePMV2SeriesIdIsLive:{ UInt64: Bool}
	
	/* 
		*   HWGarageTokenV2
		*/
	
	access(self)
	var HWGarageTokenV2SeriesIdIsLive:{ UInt64: Bool}
	
	/* 
		*   HWGarageCardV2
		*/
	
	access(self)
	var HWGarageCardV2SeriesIdIsLive:{ UInt64: Bool}
	
	/* 
		*   HWGaragePackV2
		*/
	
	// We need a way to track if a series is live
	// This dictionary will be updated before each drop to insert the series that is to be released
	// For example, the contract launches with an empty dictionary of {}
	// In order to prepare for a drop we need to have an admin execute admin_add_packSeries.cdc
	// This transaction takes a UInt64 as a parameter
	// NOTE: Once a series is added, it is live and a valid pack hash will mint that a pack to a user wallet
	access(self)
	var HWGaragePackV2SeriesIdIsLive:{ UInt64: Bool}
	
	// Do we want to update when the pack Redeeming begins? because we can
	access(all)
	var packRedeemStartTime: UFix64
	
	// should we have a state variable to start/stop packClaim
	// should we have a state variable to start/stop packRedeem
	/* 
		*   Manager resource for all NFTs
		*/
	
	access(all)
	resource Manager{ 
		/*
				 *  HWGaragePMV2
				 */
		
		// One call to add a new seriesID for Packs and Card
		access(all)
		fun addNewSeriesID(seriesID: UInt64){ 
			HWGaragePMV2.addSeriesID(seriesID: seriesID)
			self.addPackSeriesID(packSeriesID: seriesID)
			self.addCardSeriesID(packSeriesID: seriesID)
			self.addTokenSeriesID(packSeriesID: seriesID)
		}
		
		/*
				 * HWGarageToken
				 */
		
		access(all)
		fun addTokenSeriesID(packSeriesID: UInt64){ 
			pre{ 
				packSeriesID >= 1:
					"Requested series does not exist in this scope."
			}
			HWGaragePMV2.addTokenSeriesID(tokenSeriesID: packSeriesID)
			emit AdminAddNewTokenSeries(tokenSeriesID: packSeriesID)
		}
		
		/// To accomodate any further changes to the metadata we can emit the entire 
		/// metadata payload for an airdropped token and avoid staically assigning 
		/// payload. All fields can get sent to the traits struct
		access(all)
		fun airdropRedeemable(
			airdropSeriesID: UInt64,
			address: Address,
			tokenMintID: String,
			originalCardSerial: String,
			tokenSerial: String,
			seriesName: String,
			carName: String,
			tokenImageHash: String,
			tokenReleaseDate: String,
			tokenExpireDate: String,
			card_ID: String,
			template_ID: String,
			metadata:{ 
				String: String
			}
		): @{NonFungibleToken.NFT}{ 
			let HWGarageAirdrop <-
				HWGaragePMV2.mintSequentialAirdrop(
					seriesIDAirdrop: airdropSeriesID,
					metadata: metadata
				)
			emit AdminMintToken(
				uuid: HWGarageAirdrop.uuid,
				id: HWGarageAirdrop.id,
				metadata: metadata
			)
			emit AirdropRedeemable(
				WalletAddress: address,
				TokenID: HWGarageAirdrop.id // tokenEditionID										   
										   ,
				TokenMintID: tokenMintID,
				OriginalCardSerial: originalCardSerial,
				TokenSerial: tokenSerial,
				SeriesName: seriesName,
				Name: carName,
				TokenImageHash: tokenImageHash,
				TokenReleaseDate: tokenReleaseDate,
				TokenExpireDate: tokenExpireDate,
				CardID: card_ID,
				TemplateID: template_ID
			)
			return <-HWGarageAirdrop
		}
		
		/* 
				*   HWGarageCardV2
				*/
		
		// Add a packSeries to the dictionary to support a new drop
		access(all)
		fun addCardSeriesID(packSeriesID: UInt64){ 
			pre{ 
				packSeriesID >= 1:
					"Requested series does not exist in this scope."
			}
			HWGaragePMV2.addCardSeriesID(cardSeriesID: packSeriesID)
			emit AdminAddNewCardSeries(cardSeriesID: packSeriesID)
		}
		
		access(all)
		fun mintSequentialHWGarageCardV2(
			address: Address,
			packHash: String,
			packSeriesID: UInt64,
			packEditionID: UInt64,
			redeemable: String,
			metadata:{ 
				String: String
			}
		): @{NonFungibleToken.NFT}{ 
			let HWGarageCardV2 <-
				HWGaragePMV2.mintSequentialCard(
					packHash: packHash,
					packSeriesID: packSeriesID,
					packEditionID: packEditionID,
					redeemable: redeemable,
					metadata: metadata
				)
			emit AdminMintCard(
				uuid: HWGarageCardV2.uuid,
				id: HWGarageCardV2.id,
				metadata: metadata,
				packHash: packHash,
				address: address
			)
			return <-HWGarageCardV2
		}
		
		/* 
				*   HWGaragePackV2
				*/
		
		// Add a packSeries to the dictionary to support a new drop
		access(all)
		fun addPackSeriesID(packSeriesID: UInt64){ 
			pre{ 
				packSeriesID >= 1:
					"Requested series does not exist in this scope."
			// HWGaragePMV2.HWGaragePackV2SeriesIdIsLive.containsKey(packSeriesID) == true: "Requested series already exists."
			}
			HWGaragePMV2.addPackSeriesID(packSeriesID: packSeriesID)
			emit AdminAddNewPackSeries(packSeriesID: packSeriesID)
		}
		
		access(all)
		fun mintSequentialHWGaragePackV2(
			address: Address,
			packHash: String,
			packSeriesID: UInt64,
			metadata:{ 
				String: String
			}
		)		 // , packName: String
		 // , packDescription: String
		 // , thumbnailCID: String
		 // , thumbnailPath: String
		 // , collectionName: String
		 // , collectionDescription: String
		 : @{NonFungibleToken.NFT}{ 
			let HWGaragePackV2 <-
				HWGaragePMV2.mintSequentialPack(
					packHash: packHash,
					packSeriesID: packSeriesID,
					metadata: metadata
				)
			// , packName: packName
			// , packDescription: packDescription
			// , thumbnailCID: thumbnailCID
			// , thumbnailPath: thumbnailPath
			// , collectionName: collectionName
			// , collectionDescription: collectionDescription
			emit AdminMintPack(
				uuid: HWGaragePackV2.uuid,
				packHash: packHash,
				packSeriesID: packSeriesID,
				packID: HWGaragePackV2.id // aka packEditionID										 
										 ,
				metadata: metadata
			)
			emit PackClaimSuccess(
				address: address,
				packHash: packHash,
				packID: HWGaragePackV2.id,
				seriesPackMintID: metadata["seriesPackMintID"] ?? ""
			)
			return <-HWGaragePackV2
		}
	} /// end admin block
	
	
	access(contract)
	fun addSeriesID(seriesID: UInt64){ 
		pre{ 
			seriesID >= 1:
				"Requested series does not exist in this scope."
		}
		self.HWGaragePMV2SeriesIdIsLive.insert(key: seriesID, true)
	}
	
	/* 
		*   HWGarageToken2
		*
		*   Mint a HWGarageTokenV2
		*/
	
	// Add a packSeries to the dictionary to support a new drop
	access(contract)
	fun addTokenSeriesID(tokenSeriesID: UInt64){ 
		pre{ 
			tokenSeriesID >= 1:
				"Requested series does not exist in this scope."
		}
		self.HWGarageTokenV2SeriesIdIsLive.insert(key: tokenSeriesID, true)
		HWGarageTokenV2.addNewSeries(newTokenSeriesID: tokenSeriesID)
	}
	
	/// useful fields to pass into metadata 
	// thumbnailCID: ipfs hash for thumbnail (default: "ThumbnailCID not set")
	// thumbnaiPath: path to ipfs thumbnail resource (default: "ThumbnailPath not set")
	// cardName: ie: Series X Airdrop
	// cardDescription: ie: This airdrop is redeemable for Y
	// url: url for the single product page for this token
	/// the remaining fields are optional
	// collectionName: (default value) collectionName not set
	// collectionDescription: (default value) collection description not set
	/// NOTE:
	//   - This is an admin function
	//   - by default all airdropped tokens are redeemable
	//   - require no packHash to be minted
	access(contract)
	fun mintSequentialAirdrop(seriesIDAirdrop: UInt64, metadata:{ String: String}): @{
		NonFungibleToken.NFT
	}{ 
		let currentAirdrop = HWGarageTokenV2.getTotalSupply() + 1
		let newAirdropToken <-
			HWGarageTokenV2.mint(
				nftID: currentAirdrop,
				packSeriesID: seriesIDAirdrop,
				metadata: metadata
			)
		return <-newAirdropToken
	}
	
	/* 
		*   HWGarageCardV2
		*
		*   Mint a HWGarageCardV2
		*/
	
	// Add a packSeries to the dictionary to support a new drop
	access(contract)
	fun addCardSeriesID(cardSeriesID: UInt64){ 
		pre{ 
			cardSeriesID >= 1:
				"Requested series does not exist in this scope."
		}
		self.HWGarageCardV2SeriesIdIsLive.insert(key: cardSeriesID, true)
		HWGarageCardV2.addNewSeries(newCardSeriesID: cardSeriesID)
	}
	
	// look for the next Card in the sequence, and mint there
	access(self)
	fun mintSequentialCard(
		packHash: String,
		packSeriesID: UInt64,
		packEditionID: UInt64,
		redeemable: String,
		metadata:{ 
			String: String
		}
	): @{NonFungibleToken.NFT}{ 
		pre{ 
			self.HWGaragePMV2SeriesIdIsLive.containsKey(packSeriesID) == true:
				"Requested pack series is not ready at this time."
		}
		var currentEditionNumber = HWGarageCardV2.getTotalSupply() + 1
		let newCard <-
			HWGarageCardV2.mint(
				nftID: currentEditionNumber,
				packSeriesID: packSeriesID,
				cardEditionID: currentEditionNumber,
				packHash: packHash,
				redeemable: redeemable,
				metadata: metadata
			)
		return <-newCard
	}
	
	/* 
		*   HWGaragePackV2
		*
		*   Mint a HWGaragePackV2
		*/
	
	// Add a packSeries to the dictionary to support a new drop
	access(contract)
	fun addPackSeriesID(packSeriesID: UInt64){ 
		pre{ 
			packSeriesID >= 1:
				"Requested series does not exist in this scope."
		// self.HWGaragePackV2SeriesIdIsLive.containsKey(packSeriesID) == true: "Requested series already exists."
		}
		self.HWGaragePackV2SeriesIdIsLive.insert(key: packSeriesID, true)
		HWGaragePackV2.addNewSeries(newPackSeriesID: packSeriesID)
	}
	
	// Look for the next available pack, and mint there
	access(self)
	fun mintSequentialPack(packHash: String, packSeriesID: UInt64, metadata:{ String: String})																							  // , packName: String
																							  // , packDescription: String
																							  // , thumbnailCID: String
																							  // , thumbnailPath: String
																							  // , collectionName: String
																							  // , collectionDescription: String
																							  : @{
		NonFungibleToken.NFT
	}{ 
		pre{ 
			packSeriesID >= 1:
				"Requested series does not exist in this scope."
			// check to verify if a valid series has been passed in
			self.HWGaragePMV2SeriesIdIsLive.containsKey(packSeriesID) == true:
				"Requested pack series is not ready at this time."
		}
		// Grab the packEditionID to mint 
		var currentPackEditionNumber = HWGaragePackV2.getTotalSupply() + 1
		let newPack <-
			HWGaragePackV2.mint(
				nftID: currentPackEditionNumber // pack X of Y											   
											   ,
				packEditionID: currentPackEditionNumber // pack X of Y													   
													   ,
				packSeriesID: packSeriesID // aka series										  
										  ,
				packHash: packHash,
				metadata: metadata
			)
		// , packName: packName
		// , packDescription: packDescription
		// , thumbnailCID: thumbnailCID
		// , thumbnailPath: thumbnailPath
		// , collectionName: collectionName
		// , collectionDescription: collectionDescription
		return <-newPack
	}
	
	/* 
		*   Public Functions
		*
		*   HWGaragePMV2
		*/
	
	access(all)
	fun getEnabledSeries():{ UInt64: Bool}{ 
		return HWGaragePMV2.HWGaragePMV2SeriesIdIsLive
	}
	
	access(all)
	fun getEnabledTokenSeries():{ UInt64: Bool}{ 
		return HWGaragePMV2.HWGarageTokenV2SeriesIdIsLive
	}
	
	access(all)
	fun getEnabledCardSeries():{ UInt64: Bool}{ 
		return HWGaragePMV2.HWGarageCardV2SeriesIdIsLive
	}
	
	access(all)
	fun getEnabledPackSeries():{ UInt64: Bool}{ 
		return HWGaragePMV2.HWGaragePackV2SeriesIdIsLive
	}
	
	/*
		 *  Public Pack Functions
		 */
	
	access(all)
	fun claimPack(address: Address, packHash: String){ 
		// this event is picked up by a web hook to verify packHash
		// if packHash is valid, the backend will mint the pack and
		// deposit to the recipient address
		emit PackClaimBegin(address: address, packHash: packHash)
	}
	
	access(all)
	fun publicRedeemPack(address: Address, pack: @{NonFungibleToken.NFT}, packHash: String){ 
		pre{ 
			getCurrentBlock().timestamp >= self.packRedeemStartTime:
				"Redemption has not yet started"
			pack.isInstance(Type<@HWGaragePackV2.NFT>())
		}
		let packInstance <- pack as! @HWGaragePackV2.NFT
		// emit event that our backend will read and mint pack contents to the associated address
		emit RedeemPack(
			id: packInstance.id,
			packID: packInstance.packEditionID, // aka packEditionID
			
			packSeriesID: packInstance.packSeriesID,
			address: address,
			packHash: packHash
		)
		// burn pack since it was redeemed for HWGarageCardV2(s)
		destroy packInstance
	}
	
	access(all)
	fun getPackEditionIdByPackSeriesId():{ UInt64: UInt64}{ 
		return HWGaragePackV2.currentPackEditionIdByPackSeriesId
	}
	
	access(all)
	fun getCardEditionIdByPackSeriesId():{ UInt64: UInt64}{ 
		return HWGarageCardV2.currentCardEditionIdByPackSeriesId
	}
	
	/* 
		 *  Public Airdrop functions
		 */
	
	access(all)
	fun burnAirdrop(
		walletAddress: Address,
		tokenSerial: String,
		airdropToken: @{NonFungibleToken.NFT}
	){ 
		pre{ 
			// check airdropIdEdition is the Type
			airdropToken.isInstance(Type<@HWGarageTokenV2.NFT>())
		}
		let airdropInstance <- airdropToken as! @HWGarageTokenV2.NFT
		// emit event signaling Airdrop is burned
		emit AirdropBurn(
			WalletAddress: walletAddress,
			TokenSerial: tokenSerial,
			AirdropEditionId: airdropInstance.id
		)
		destroy airdropInstance
	}
	
	/* 
		 *  Public Bridge functions
		 */
	
	access(all)
	fun migrateAsset(waxWallet: String, assetIds: [String], flowWallet: Address){ 
		// emit event to start asset migration
		emit ClaimBridgeAsset(waxWallet: waxWallet, assetIds: assetIds, flowWallet: flowWallet)
	}
	
	init(){ 
		/*
				*   State variables
				*   HWGaragePMV2
				*/
		
		// start with no existing series enabled
		// {1: true, 2: true} when series 1 and 2 are live
		self.HWGaragePMV2SeriesIdIsLive ={} 
		/*
				*   HWGarageTokenV2
				*/
		
		self.HWGarageTokenV2SeriesIdIsLive ={} 
		/*
				*   HWGarageCardV2
				*/
		
		self.HWGarageCardV2SeriesIdIsLive ={} 
		/* 
				*   HWGaragePackV2
				*/
		
		self.packRedeemStartTime = 1658361290.0
		self.HWGaragePackV2SeriesIdIsLive ={} 
		// manager resource is only saved to the deploying account's storage
		self.ManagerStoragePath = /storage/HWGaragePMV2
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		emit ContractInitialized()
	}
}
