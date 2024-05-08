/**
> Author: FIXeS World <https://fixes.world/>

# FRC20SemiNFT

TODO: Add description

*/

// Third party imports
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// Fixes Import
import Fixes from "./Fixes.cdc"

import FRC20FTShared from "./FRC20FTShared.cdc"

access(all)
contract FRC20SemiNFT: NonFungibleToken, ViewResolver{ 
	/* --- Events --- */
	
	/// Total supply of FRC20SemiNFTs in existence
	access(all)
	var totalSupply: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an NFT is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// The event that is emitted when an NFT is wrapped
	access(all)
	event Wrapped(id: UInt64, pool: Address, tick: String, balance: UFix64)
	
	/// The event that is emitted when an NFT is unwrapped
	access(all)
	event Unwrapped(id: UInt64, pool: Address, tick: String, balance: UFix64)
	
	/// The event that is emitted when an NFT is merged
	access(all)
	event Merged(id: UInt64, mergedId: UInt64, pool: Address, tick: String, mergedBalance: UFix64)
	
	/// The event that is emitted when an NFT is splitted
	access(all)
	event Split(id: UInt64, splittedId: UInt64, pool: Address, tick: String, splitBalance: UFix64)
	
	/// The event that is emitted when the claiming record is updated
	access(all)
	event ClaimingRecordUpdated(id: UInt64, tick: String, pool: Address, strategy: String, time: UInt64, globalYieldRate: UFix64, totalClaimedAmount: UFix64)
	
	/* --- Variable, Enums and Structs --- */
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	/* --- Interfaces & Resources --- */
	/// Reward Claiming Record Struct, stored in SemiNFT
	///
	access(all)
	struct RewardClaimRecord{ 
		// The pool address
		access(all)
		let poolAddress: Address
		
		// The reward strategy name
		access(all)
		let rewardTick: String
		
		// The last claimed time
		access(all)
		var lastClaimedTime: UInt64
		
		// The last global yield rate
		access(all)
		var lastGlobalYieldRate: UFix64
		
		// The total claimed amount by this record
		access(all)
		var totalClaimedAmount: UFix64
		
		init(address: Address, rewardTick: String){ 
			self.poolAddress = address
			self.rewardTick = rewardTick
			self.lastClaimedTime = 0
			self.lastGlobalYieldRate = 0.0
			self.totalClaimedAmount = 0.0
		}
		
		/// Update the claiming record
		///
		access(contract)
		fun updateClaiming(currentGlobalYieldRate: UFix64, time: UInt64?){ 
			self.lastClaimedTime = time ?? UInt64(getCurrentBlock().timestamp)
			self.lastGlobalYieldRate = currentGlobalYieldRate
		}
		
		access(contract)
		fun addClaimedAmount(amount: UFix64){ 
			self.totalClaimedAmount = self.totalClaimedAmount.saturatingAdd(amount)
		}
		
		access(contract)
		fun subtractClaimedAmount(amount: UFix64){ 
			self.totalClaimedAmount = self.totalClaimedAmount.saturatingSubtract(amount)
		}
	}
	
	/// Public Interface of the FRC20SemiNFT
	access(all)
	resource interface IFRC20SemiNFT{ 
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		access(all)
		view fun getOriginalTick(): String
		
		access(all)
		view fun getTickerName(): String
		
		access(all)
		view fun isStakedTick(): Bool
		
		access(all)
		view fun isBackedByVault(): Bool
		
		access(all)
		view fun getVaultType(): Type?
		
		access(all)
		view fun getFromAddress(): Address
		
		access(all)
		view fun getBalance(): UFix64
		
		access(all)
		view fun getRewardStrategies(): [String]
		
		access(all)
		view fun getClaimingRecord(_ uniqueName: String): RewardClaimRecord?
		
		access(all)
		view fun buildUniqueName(_ addr: Address, _ strategy: String): String
	}
	
	/// The core resource that represents a Non Fungible Token.
	/// New instances will be created using the NFTMinter resource
	/// and stored in the Collection resource
	///
	access(all)
	resource NFT: IFRC20SemiNFT, NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		/// Wrapped FRC20FTShared.Change
		access(self)
		var wrappedChange: @FRC20FTShared.Change
		
		/// Claiming Records for staked FRC20FTShared.Change
		/// Unique Name => Reward Claim Record
		access(self)
		let claimingRecords:{ String: RewardClaimRecord}
		
		init(_ change: @FRC20FTShared.Change, initialYieldRates:{ String: UFix64}){ 
			pre{ 
				change.isBackedByVault() == false:
					"Cannot wrap a vault backed FRC20 change"
			}
			self.id = self.uuid
			self.wrappedChange <- change
			self.claimingRecords ={} 
			
			// initialize the claiming records
			if self.wrappedChange.isStakedTick(){ 
				let strategies = initialYieldRates.keys
				for name in strategies{ 
					let recordRef = self._borrowOrCreateClaimingRecord(poolAddress: self.wrappedChange.from, rewardTick: name)
					let yieldRate = initialYieldRates[name]!
					// update the initial record
					recordRef.updateClaiming(currentGlobalYieldRate: yieldRate, time: nil)
					log("Updated the initial claiming record for ".concat(name).concat(" with yield rate ").concat(yieldRate.toString()))
				}
			} // end if
			
			FRC20SemiNFT.totalSupply = FRC20SemiNFT.totalSupply + 1
			
			// emit the event
			emit Wrapped(id: self.id, pool: self.wrappedChange.from, tick: self.wrappedChange.tick, balance: self.wrappedChange.getBalance())
		}
		
		/// @deprecated after Cadence 1.0
		/** ----- MetadataViews.Resolver ----- */
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			var nftViews: [Type] = [									// collection data
									Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(),																																							// nft view data
																																							Type<MetadataViews.Display>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Royalties>()]
			return nftViews
		}
		
		/// Function that resolves a metadata view for this token.
		///
		/// @param view: The Type of the desired view.
		/// @return A structure representing the requested view.
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let colViews = [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
			if colViews.contains(view){ 
				return FRC20SemiNFT.resolveView(view)
			} else{ 
				switch view{ 
					case Type<MetadataViews.Display>():
						let tick = self.getOriginalTick()
						let isStaked = self.isStakedTick()
						let fullName = (isStaked ? "Staked " : "").concat(tick)
						let balance = self.getBalance()
						let tickNameSizeIcon = 80 + (10 - tick.length > 0 ? 10 - tick.length : 0) * 12
						let tickNameSizeTitle = 245 + (10 - tick.length > 0 ? 10 - tick.length : 0) * 15
						var balanceStr = UInt64(balance).toString()
						if balanceStr.length > 8{ 
							balanceStr = balanceStr.slice(from: 0, upTo: 7).concat("+")
						}
						var svgStr = "data:image/svg+xml;utf8,".concat("%3Csvg%20width%3D'512'%20height%3D'512'%20viewBox%3D'0%200%202048%202048'%20style%3D'shape-rendering%3A%20crispedges%3B'%20xmlns%3D'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg'%3E").concat("%3Cdefs%3E%3ClinearGradient%20gradientUnits%3D'userSpaceOnUse'%20x1%3D'0'%20y1%3D'-240'%20x2%3D'0'%20y2%3D'240'%20id%3D'gradient-0'%20gradientTransform%3D'matrix(0.908427%2C%20-0.41805%2C%200.320369%2C%200.696163%2C%20-855.753265%2C%20312.982639)'%3E%3Cstop%20offset%3D'0'%20style%3D'stop-color%3A%20rgb(244%2C%20246%2C%20246)%3B'%3E%3C%2Fstop%3E%3Cstop%20offset%3D'1'%20style%3D'stop-color%3A%20rgb(35%2C%20133%2C%2091)%3B'%3E%3C%2Fstop%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E").concat("%3Cg%20transform%3D'matrix(1%2C%200%2C%200%2C%201%2C%200%2C%200)'%3E%3Cpath%20d%3D'M%20842%201104%20L%20944%20525%20L%20232%20930%20Z'%20style%3D'fill%3A%20rgb(74%2C145%2C122)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20944%20525%20L%20199%20444%20L%20232%20930%20Z'%20style%3D'fill%3A%20rgb(56%2C130%2C100)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20199%20444%20L%200%20576.1824817518248%20L%200%20700.2671009771987%20L%20232%20930%20Z'%20style%3D'fill%3A%20rgb(63%2C116%2C106)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%200%20700.2671009771987%20L%200%201020.8865979381443%20L%20232%20930%20Z'%20style%3D'fill%3A%20rgb(74%2C118%2C119)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20232%20930%20L%20384%201616%20L%20842%201104%20Z'%20style%3D'fill%3A%20rgb(92%2C152%2C118)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%200%201020.8865979381443%20L%200%201236.2666666666667%20L%20384%201616%20L%20232%20930%20Z'%20style%3D'fill%3A%20rgb(95%2C137%2C121)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20384%201616%20L%20825%201732%20L%20842%201104%20Z'%20style%3D'fill%3A%20rgb(120%2C171%2C120)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201646%201114%20L%201540%20198%20L%20944%20525%20Z'%20style%3D'fill%3A%20rgb(109%2C164%2C119)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201540%20198%20L%201292.8235294117646%200%20L%201121.4881516587677%200%20L%20944%20525%20Z'%20style%3D'fill%3A%20rgb(95%2C140%2C121)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20944%20525%20L%20483.8322147651007%200%20L%20260.51807228915663%200%20L%20199%20444%20Z'%20style%3D'fill%3A%20rgb(55%2C115%2C96)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201121.4881516587677%200%20L%20483.8322147651007%200%20L%20944%20525%20Z'%20style%3D'fill%3A%20rgb(70%2C118%2C114)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%200%20576.1824817518249%20L%20199%20444%20L%200%20190.04738562091504%20Z'%20style%3D'fill%3A%20rgb(60%2C95%2C100)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201646%201114%20L%20944%20525%20L%20842%201104%20Z'%20style%3D'fill%3A%20rgb(104%2C164%2C143)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201590%201475%20L%201646%201114%20L%20842%201104%20Z'%20style%3D'fill%3A%20rgb(143%2C186%2C139)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20825%201732%20L%201590%201475%20L%20842%201104%20Z'%20style%3D'fill%3A%20rgb(138%2C183%2C141)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%200%201236.2666666666667%20L%200%201755.6363636363637%20L%20384%201616%20Z'%20style%3D'fill%3A%20rgb(117%2C144%2C115)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20384%201616%20L%20327.74624373956595%202048%20L%20485.4472049689441%202048%20L%20825%201732%20Z'%20style%3D'fill%3A%20rgb(129%2C165%2C110)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%201084.9638854296388%20L%202048%20639.9035294117647%20L%202024%20615%20L%201646%201114%20Z'%20style%3D'fill%3A%20rgb(156%2C179%2C136)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201646%201114%20L%202024%20615%20L%201540%20198%20Z'%20style%3D'fill%3A%20rgb(130%2C171%2C117)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202024%2018%20L%201989.1464968152866%200%20L%201645.7566765578636%200%20L%201540%20198%20Z'%20style%3D'fill%3A%20rgb(128%2C144%2C115)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201292.8235294117646%200%20L%201540%20198%20L%201645.7566765578636%200%20Z'%20style%3D'fill%3A%20rgb(115%2C141%2C116)%3B'%3E%3C%2Fpath%3E%3Cpath%20%20d%3D'M%200%201755.6363636363635%20L%200%201907.5323741007194%20L%20139.79713603818618%202048%20L%20327.74624373956595%202048%20L%20384%201616%20Z'%20style%3D'fill%3A%20rgb(132%2C151%2C114)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20825%201732%20L%201186.9410609037327%202048%20L%201453.8563968668407%202048%20L%201590%201475%20Z'%20style%3D'fill%3A%20rgb(169%2C194%2C133)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20485.4472049689441%202048%20L%20921.2605042016806%202048%20L%20825%201732%20Z'%20style%3D'fill%3A%20rgb(145%2C171%2C122)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20260.51807228915663%200%20L%200%200%20L%200%20190.04738562091507%20L%20199%20444%20Z'%20style%3D'fill%3A%20rgb(61%2C86%2C102)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202024%20615%20L%202024%2018%20L%201540%20198%20Z'%20style%3D'fill%3A%20rgb(131%2C155%2C113)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20139.79713603818618%202048%20L%200%201907.5323741007194%20L%200%202048%20Z'%20style%3D'fill%3A%20rgb(138%2C141%2C116)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%20921.2605042016806%202048%20L%201186.9410609037327%202048%20L%20825%201732%20Z'%20style%3D'fill%3A%20rgb(164%2C184%2C140)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201590%201475%20L%202048%201663.6997929606625%20L%202048%201641.2131147540983%20L%201646%201114%20Z'%20style%3D'fill%3A%20rgb(177%2C201%2C129)%3B'%3E%3C%2Fpath%3E%3Cpath%20%20d%3D'M%201453.8563968668407%202048%20L%201634.358024691358%202048%20L%202048%201695.3157894736842%20L%202048%201663.6997929606625%20L%201590%201475%20Z'%20style%3D'fill%3A%20rgb(191%2C205%2C126)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%2023.50859453993933%20L%202048%206.199445983379519%20L%202024%2018%20Z'%20style%3D'fill%3A%20rgb(138%2C141%2C116)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%201641.2131147540983%20L%202048%201084.9638854296388%20L%201646%201114%20Z'%20style%3D'fill%3A%20rgb(178%2C194%2C134)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%201989.1464968152866%200%20L%202024%2018%20L%202027.8046647230321%200%20Z'%20style%3D'fill%3A%20rgb(136%2C141%2C116)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%206.199445983379501%20L%202048%200%20L%202027.8046647230321%200%20L%202024%2018%20Z'%20style%3D'fill%3A%20rgb(138%2C141%2C116)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%20606.0212335692619%20L%202048%2023.508594539939338%20L%202024%2018%20L%202024%20615%20Z'%20style%3D'fill%3A%20rgb(137%2C155%2C113)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%20606.0212335692619%20L%202024%20615%20L%202048%20639.9035294117647%20Z'%20style%3D'fill%3A%20rgb(142%2C169%2C118)%3B'%3E%3C%2Fpath%3E%3Cpath%20d%3D'M%202048%202048%20L%202048%201695.3157894736842%20L%201634.358024691358%202048%20Z'%20style%3D'fill%3A%20rgb(207%2C203%2C127)%3B'%3E%3C%2Fpath%3E%3C%2Fg%3E").concat("%3Cg%20transform%3D'matrix(1%2C%200%2C%200%2C%201%2C%201200%2C%20320)'%3E%3Cellipse%20style%3D'fill%3A%20rgb(149%2C%20225%2C%20192)%3B%20stroke-width%3A%201rem%3B%20paint-order%3A%20fill%3B%20stroke%3A%20url(%23gradient-0)%3B'%20ry%3D'240'%20rx%3D'240'%20cx%3D'-800'%20cy%3D'400'%3E%3C%2Fellipse%3E%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(80%2C%20213%2C%20155)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20text-anchor%3A%20middle%3B%20white-space%3A%20pre%3B%20font-size%3A%20420px%3B'%20fill-opacity%3D'0.2'%20y%3D'400'%20font-size%3D'420'%20x%3D'-800'%3E%F0%9D%94%89%3C%2Ftext%3E").concat("%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(244%2C%20246%2C%20246)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20text-anchor%3A%20middle%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%20white-space%3A%20pre%3B'%20x%3D'-800'%20y%3D'400'%20font-size%3D'").concat(tickNameSizeIcon.toString()).concat("'%3E").concat(tick).concat("%3C%2Ftext%3E%3C%2Fg%3E").concat("%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(244%2C%20246%2C%20246)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%20paint-order%3A%20fill%3B%20text-anchor%3A%20middle%3B%20white-space%3A%20pre%3B'%20x%3D'1300'%20y%3D'720'%20font-size%3D'").concat(tickNameSizeTitle.toString()).concat("'%3E").concat(tick).concat("%3C%2Ftext%3E").concat("%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(244%2C%20246%2C%20246)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%20paint-order%3A%20fill%3B%20text-anchor%3A%20middle%3B%20white-space%3A%20pre%3B'%20x%3D'1024'%20y%3D'1500'%20font-size%3D'360'%3E").concat(balanceStr).concat("%3C%2Ftext%3E")
						// add staked tag
						if isStaked{ 
							svgStr = svgStr.concat("%3Cg%20transform%3D'matrix(1%2C%200%2C%200%2C%201%2C%20128%2C%20192)'%3E%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(244%2C%20246%2C%20246)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20font-size%3A%20160px%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%20letter-spacing%3A%204px%3B%20paint-order%3A%20fill%3B%20white-space%3A%20pre%3B'%20x%3D'0'%20y%3D'0'%3EStaked%20%F0%9D%94%89rc20%3C%2Ftext%3E%3Ctext%20style%3D'dominant-baseline%3A%20middle%3B%20fill%3A%20rgb(242%2C%20201%2C%20125)%3B%20font-family%3A%20system-ui%2C%20sans-serif%3B%20font-size%3A%20160px%3B%20font-style%3A%20italic%3B%20font-weight%3A%20700%3B%20letter-spacing%3A%204px%3B%20paint-order%3A%20fill%3B%20white-space%3A%20pre%3B'%20x%3D'-4'%20y%3D'-6'%3EStaked%20%F0%9D%94%89rc20%3C%2Ftext%3E%3C%2Fg%3E")
						}
						// end of svg
						svgStr = svgStr.concat("%3C%2Fsvg%3E")
						return MetadataViews.Display(name: "\u{1d509}rc20 - ".concat(fullName), description: "This is a \u{1d509}rc20 Semi-NFT that contains a certain number of ".concat(fullName).concat(" tokens. \n").concat("The balance of this Semi-NFT is ").concat(balance.toString()).concat(". \n"), thumbnail: MetadataViews.HTTPFile(url: svgStr))
					case Type<MetadataViews.Traits>():
						let traits = MetadataViews.Traits([])
						let changeRef: &FRC20FTShared.Change = self.borrowChange()
						traits.addTrait(MetadataViews.Trait(name: "originTick", value: changeRef.getOriginalTick(), displayType: nil, rarity: nil))
						traits.addTrait(MetadataViews.Trait(name: "tick", value: changeRef.tick, displayType: nil, rarity: nil))
						traits.addTrait(MetadataViews.Trait(name: "balance", value: changeRef.getBalance(), displayType: nil, rarity: nil))
						let isVault = changeRef.isBackedByVault()
						traits.addTrait(MetadataViews.Trait(name: "isFlowFT", value: isVault, displayType: nil, rarity: nil))
						if isVault{ 
							traits.addTrait(MetadataViews.Trait(name: "ftType", value: (changeRef.getVaultType()!).identifier, displayType: nil, rarity: nil))
						}
						return traits
					case Type<MetadataViews.Royalties>():
						// Royalties for FRC20SemiNFT is 5% to Deployer account
						let deployerAddr = FRC20SemiNFT.account.address
						let flowCap = getAccount(deployerAddr).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
						return MetadataViews.Royalties([MetadataViews.Royalty(receiver: flowCap!, cut: 0.05, description: "5% of the sale price of this NFT goes to the FIXeS platform account")])
				}
				return nil
			}
		}
		
		/** ----- Semi-NFT Methods ----- */
		access(all)
		view fun getOriginalTick(): String{ 
			return self.wrappedChange.getOriginalTick()
		}
		
		access(all)
		view fun getTickerName(): String{ 
			return self.wrappedChange.tick
		}
		
		access(all)
		view fun isStakedTick(): Bool{ 
			return self.wrappedChange.isStakedTick()
		}
		
		access(all)
		view fun isBackedByVault(): Bool{ 
			return self.wrappedChange.isBackedByVault()
		}
		
		access(all)
		view fun getVaultType(): Type?{ 
			return self.wrappedChange.getVaultType()
		}
		
		access(all)
		view fun getFromAddress(): Address{ 
			return self.wrappedChange.from
		}
		
		access(all)
		view fun getBalance(): UFix64{ 
			return self.wrappedChange.getBalance()
		}
		
		/// Get the reward strategies
		///
		access(all)
		view fun getRewardStrategies(): [String]{ 
			return self.claimingRecords.keys
		}
		
		/// Get the the claiming record(copy) by the unique name
		///
		access(all)
		view fun getClaimingRecord(_ uniqueName: String): RewardClaimRecord?{ 
			pre{ 
				self.isStakedTick():
					"The tick must be a staked \u{1d509}rc20 token"
			}
			return self.claimingRecords[uniqueName]
		}
		
		// Merge the NFT
		//
		access(all)
		fun merge(_ other: @FRC20SemiNFT.NFT){ 
			pre{ 
				self.getOriginalTick() == other.getOriginalTick():
					"The tick must be the same"
				self.isBackedByVault() == other.isBackedByVault():
					"The vault type must be the same"
			}
			// check tick and pool address
			let otherChangeRef = other.borrowChange()
			assert(self.wrappedChange.from == otherChangeRef.from, message: "The pool address must be the same")
			let otherId = other.id
			let otherBalance = otherChangeRef.getBalance()
			
			// calculate the new balance
			let newBalance = self.getBalance() + otherChangeRef.getBalance()
			
			// merge the claiming records
			if self.isStakedTick() && other.isStakedTick(){ 
				let strategies = self.getRewardStrategies()
				// merge each strategy
				for name in strategies{ 
					if let otherRecordRef = other._borrowClaimingRecord(name){ 
						// update claiming record
						let recordRef = self._borrowOrCreateClaimingRecord(poolAddress: otherRecordRef.poolAddress, rewardTick: otherRecordRef.rewardTick)
						// calculate the new claiming record
						var newGlobalYieldRate = 0.0
						// Weighted average
						if newBalance > 0.0{ 
							newGlobalYieldRate = (recordRef.lastGlobalYieldRate * self.getBalance() + otherRecordRef.lastGlobalYieldRate * otherChangeRef.getBalance()) / newBalance
						}
						let newLastClaimedTime = recordRef.lastClaimedTime > otherRecordRef.lastClaimedTime ? recordRef.lastClaimedTime : otherRecordRef.lastClaimedTime
						
						// update the record
						self._updateClaimingRecord(poolAddress: otherRecordRef.poolAddress, rewardTick: otherRecordRef.rewardTick, currentGlobalYieldRate: newGlobalYieldRate, currentTime: newLastClaimedTime, amount: otherRecordRef.totalClaimedAmount, isSubtract: false)
					}
				}
			}
			
			// unwrap and merge the wrapped change
			let unwrappedChange <- FRC20SemiNFT.unwrapStakedFRC20(nftToUnwrap: <-other)
			self.wrappedChange.merge(from: <-unwrappedChange)
			assert(newBalance == self.getBalance(), message: "The merged balance must be correct")
			
			// emit event
			emit Merged(id: self.id, mergedId: otherId, pool: self.wrappedChange.from, tick: self.wrappedChange.tick, mergedBalance: otherBalance)
		}
		
		// Split the NFT
		access(all)
		fun split(_ percent: UFix64): @FRC20SemiNFT.NFT{ 
			pre{ 
				percent > 0.0:
					"The split percent must be greater than 0"
				percent < 1.0:
					"The split percent must be less than 1"
			}
			let oldBalance = self.getBalance()
			// calculate the new balance
			let splitBalance = oldBalance * percent
			
			// split the wrapped change
			let splitChange <- self.wrappedChange.withdrawAsChange(amount: splitBalance)
			
			// create a new NFT
			let newNFT <- create NFT(<-splitChange, initialYieldRates:{} )
			
			// check balance of the new NFT and the old NFT
			assert(self.getBalance() + newNFT.getBalance() == oldBalance, message: "The splitted balance must be correct")
			
			// split the claiming records
			if self.isStakedTick(){ 
				let strategies = self.getRewardStrategies()
				// split each strategy
				for name in strategies{ 
					if let recordRef = self._borrowClaimingRecord(name){ 
						let splitAmount = recordRef.totalClaimedAmount * percent
						// update the record for current NFT
						self._updateClaimingRecord(poolAddress: recordRef.poolAddress, rewardTick: recordRef.rewardTick, currentGlobalYieldRate: recordRef.lastGlobalYieldRate, currentTime: recordRef.lastClaimedTime, amount: splitAmount, isSubtract: true)
						// update the record for new NFT
						newNFT._updateClaimingRecord(poolAddress: recordRef.poolAddress, rewardTick: recordRef.rewardTick, currentGlobalYieldRate: recordRef.lastGlobalYieldRate, currentTime: recordRef.lastClaimedTime, amount: splitAmount, isSubtract: false)
					}
				}
			}
			
			// emit event
			emit Split(id: self.id, splittedId: newNFT.id, pool: self.wrappedChange.from, tick: self.wrappedChange.tick, splitBalance: splitBalance)
			return <-newNFT
		}
		
		/** ---- Account level methods ---- */
		/// Get the unique name of the reward strategy
		///
		access(all)
		view fun buildUniqueName(_ addr: Address, _ strategy: String): String{ 
			let ref = self.borrowChange()
			return addr.toString().concat("_").concat(ref.getOriginalTick()).concat("_").concat(strategy)
		}
		
		/// Hook method: Update the claiming record
		///
		access(account)
		fun onClaimingReward(poolAddress: Address, rewardTick: String, amount: UFix64, currentGlobalYieldRate: UFix64){ 
			self._updateClaimingRecord(poolAddress: poolAddress, rewardTick: rewardTick, currentGlobalYieldRate: currentGlobalYieldRate, currentTime: nil, amount: amount, isSubtract: false)
		}
		
		/** Internal Method */
		/// Update the claiming record
		///
		access(contract)
		fun _updateClaimingRecord(poolAddress: Address, rewardTick: String, currentGlobalYieldRate: UFix64, currentTime: UInt64?, amount: UFix64, isSubtract: Bool){ 
			pre{ 
				self.isStakedTick():
					"The tick must be a staked \u{1d509}rc20 token"
			}
			// update claiming record
			let recordRef = self._borrowOrCreateClaimingRecord(poolAddress: poolAddress, rewardTick: rewardTick)
			recordRef.updateClaiming(currentGlobalYieldRate: currentGlobalYieldRate, time: currentTime)
			if isSubtract{ 
				recordRef.subtractClaimedAmount(amount: amount)
			} else{ 
				recordRef.addClaimedAmount(amount: amount)
			}
			
			// emit event
			emit ClaimingRecordUpdated(id: self.id, tick: self.getOriginalTick(), pool: poolAddress, strategy: rewardTick, time: recordRef.lastClaimedTime, globalYieldRate: recordRef.lastGlobalYieldRate, totalClaimedAmount: recordRef.totalClaimedAmount)
		}
		
		/// Borrow the wrapped FRC20FTShared.Change
		///
		access(contract)
		view fun borrowChange(): &FRC20FTShared.Change{ 
			return &self.wrappedChange as &FRC20FTShared.Change
		}
		
		/// Borrow or create the claiming record(writeable reference) by the unique name
		///
		access(self)
		fun _borrowOrCreateClaimingRecord(poolAddress: Address, rewardTick: String): &RewardClaimRecord{ 
			let uniqueName = self.buildUniqueName(poolAddress, rewardTick)
			if self.claimingRecords[uniqueName] == nil{ 
				self.claimingRecords[uniqueName] = RewardClaimRecord(address: self.wrappedChange.from, rewardTick: rewardTick)
			}
			return self._borrowClaimingRecord(uniqueName) ?? panic("Claiming record must exist")
		}
		
		/// Borrow the claiming record(writeable reference) by the unique name
		///
		access(self)
		fun _borrowClaimingRecord(_ uniqueName: String): &RewardClaimRecord?{ 
			return &self.claimingRecords[uniqueName] as &RewardClaimRecord?
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the public methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface FRC20SemiNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}?
		
		/** ----- Specific Methods For SemiNFT ----- */
		access(all)
		view fun getIDsByTick(tick: String): [UInt64]
		
		/// Gets the staked balance of the tick
		access(all)
		view fun getStakedBalance(tick: String): UFix64
		
		/// Borrow the FRC20SemiNFT reference by the ID
		access(all)
		fun borrowFRC20SemiNFTPublic(id: UInt64): &FRC20SemiNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FRC20SemiNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// Defines the private methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface FRC20SemiNFTBorrowable{ 
		/** ----- Specific Methods For SemiNFT ----- */
		access(all)
		view fun getIDsByTick(tick: String): [UInt64]
		
		access(all)
		view fun borrowFRC20SemiNFT(id: UInt64): &FRC20SemiNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow FRC20SemiNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: FRC20SemiNFTCollectionPublic, FRC20SemiNFTBorrowable, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Tick => NFT ID Array
		access(self)
		let tickIDsMapping:{ String: [UInt64]}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.tickIDsMapping ={} 
		}
		
		/// @deprecated after Cadence 1.0
		/// Removes an NFT from the collection and moves it to the caller
		///
		/// @param withdrawID: The ID of the NFT that wants to be withdrawn
		/// @return The NFT resource that has been taken out of the collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- (self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")) as! @FRC20SemiNFT.NFT
			
			// remove from tickIDsMapping
			let tick = token.getOriginalTick()
			let tickIDs = self._borrowTickIDs(tick) ?? panic("Tick IDs must exist")
			let index = tickIDs.firstIndex(of: token.id) ?? panic("Token ID must exist in tickIDs")
			tickIDs.remove(at: index)
			
			// emit the event
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Adds an NFT to the collections dictionary and adds the ID to the id array
		///
		/// @param token: The NFT resource to be included in the collection
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FRC20SemiNFT.NFT
			let id: UInt64 = token.id
			let tick = token.getOriginalTick()
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// add to tickIDsMapping
			let tickIDs = self._borrowOrCreateTickIDs(tick)
			tickIDs.append(id)
			
			// emit the event
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Helper method for getting the collection IDs
		///
		/// @return An array containing the IDs of the NFTs in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return self.borrowNFTSafe(id: id)!
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		view fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		/// Gets an array of NFT IDs in the collection by the tick
		///
		access(all)
		view fun getIDsByTick(tick: String): [UInt64]{ 
			if let ids = self.tickIDsMapping[tick]{ 
				return ids
			}
			return []
		}
		
		/// Gets the staked balance of the tick
		///
		access(all)
		view fun getStakedBalance(tick: String): UFix64{ 
			let tickIds = self.getIDsByTick(tick: tick)
			if tickIds.length > 0{ 
				var totalBalance = 0.0
				for id in tickIds{ 
					if let nft = self.borrowFRC20SemiNFT(id: id){ 
						if nft.getOriginalTick() != tick{ 
							continue
						}
						if !nft.isStakedTick(){ 
							continue
						}
						totalBalance = totalBalance + nft.getBalance()
					}
				}
				return totalBalance
			}
			return 0.0
		}
		
		/// Gets a reference to an NFT in the collection with the public interface
		///
		access(all)
		fun borrowFRC20SemiNFTPublic(id: UInt64): &FRC20SemiNFT.NFT?{ 
			return self.borrowFRC20SemiNFT(id: id)
		}
		
		/// Gets a reference to an NFT in the collection for detailed operations
		///
		access(all)
		view fun borrowFRC20SemiNFT(id: UInt64): &FRC20SemiNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &FRC20SemiNFT.NFT
			}
			return nil
		}
		
		/** ----- ViewResolver ----- */
		/// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
		/// interface so that the caller can retrieve the views that the NFT
		/// is implementing and resolve them
		///
		/// @param id: The ID of the wanted NFT
		/// @return The resource reference conforming to the Resolver interface
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let FRC20SemiNFT = nft as! &FRC20SemiNFT.NFT
			return FRC20SemiNFT as &{ViewResolver.Resolver}
		}
		
		/** ------ Internal Methods ------ */
		/// Borrow the tick IDs mapping
		///
		access(self)
		fun _borrowTickIDs(_ tick: String): &[UInt64]?{ 
			return &self.tickIDsMapping[tick] as &[UInt64]?
		}
		
		/// Borrow or create the tick IDs mapping
		///
		access(self)
		fun _borrowOrCreateTickIDs(_ tick: String): &[UInt64]{ 
			if self.tickIDsMapping[tick] == nil{ 
				self.tickIDsMapping[tick] = []
			}
			return self._borrowTickIDs(tick) ?? panic("Tick IDs must exist")
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
	
	/// Allows anyone to create a new empty collection
	///
	/// @return The new Collection resource
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Mints a new NFT with a new ID and deposit it in the
	/// recipients collection using their collection reference
	/// -- recipient, the collection of FRC20SemiNFT
	///
	access(account)
	fun wrap(recipient: &FRC20SemiNFT.Collection, change: @FRC20FTShared.Change, initialYieldRates:{ String: UFix64}): UInt64{ 
		pre{ 
			change.isBackedByVault() == false:
				"Cannot wrap a vault backed FRC20 change"
		}
		let poolAddress = change.from
		let tick = change.tick
		let balance = change.getBalance()
		
		// create a new NFT
		// Set the initial Global yield rate to the current one, so that users cannot obtain previous profits.
		var newNFT <- create NFT(<-change, initialYieldRates: initialYieldRates)
		let nftId = newNFT.id
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newNFT)
		return nftId
	}
	
	/// Unwraps an NFT and deposits it in the recipients collection
	/// using their collection reference
	///
	access(account)
	fun unwrapFRC20(nftToUnwrap: @FRC20SemiNFT.NFT): @FRC20FTShared.Change{ 
		pre{ 
			nftToUnwrap.isStakedTick() == false:
				"Cannot unwrap a staked \u{1d509}rc20 token by this method."
		}
		return <-self._unwrap(<-nftToUnwrap)
	}
	
	/// Unwraps the SemiNFT and returns the wrapped FRC20FTShared.Change
	/// Account level method
	///
	access(account)
	fun unwrapStakedFRC20(nftToUnwrap: @FRC20SemiNFT.NFT): @FRC20FTShared.Change{ 
		pre{ 
			nftToUnwrap.isStakedTick() == true:
				"Cannot unwrap a non-staked \u{1d509}rc20 token by this method."
		}
		return <-self._unwrap(<-nftToUnwrap)
	}
	
	/// Unwraps the SemiNFT and returns the wrapped FRC20FTShared.Change
	/// Contract level method
	///
	access(contract)
	fun _unwrap(_ nftToUnwrap: @FRC20SemiNFT.NFT): @FRC20FTShared.Change{ 
		let nftId = nftToUnwrap.id
		let changeRef = nftToUnwrap.borrowChange()
		let poolAddr = changeRef.from
		let tick = changeRef.tick
		let allBalance = changeRef.getBalance()
		// withdraw all balance from the wrapped change
		let newChange <- changeRef.withdrawAsChange(amount: allBalance)
		
		// destroy the FRC20SemiNFT
		destroy nftToUnwrap
		
		// decrease the total supply
		FRC20SemiNFT.totalSupply = FRC20SemiNFT.totalSupply - 1
		
		// emit the event
		emit Unwrapped(id: nftId, pool: poolAddr, tick: tick, balance: allBalance)
		// return the inscription
		return <-newChange
	}
	
	/// Function that resolves a metadata view for this contract.
	///
	/// @param view: The Type of the desired view.
	/// @return A structure representing the requested view.
	///
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.ExternalURL>():
				return MetadataViews.ExternalURL("https://fixes.world/")
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: FRC20SemiNFT.CollectionStoragePath, publicPath: FRC20SemiNFT.CollectionPublicPath, publicCollection: Type<&FRC20SemiNFT.Collection>(), publicLinkedType: Type<&FRC20SemiNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-FRC20SemiNFT.createEmptyCollection(nftType: Type<@FRC20SemiNFT.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/Wdy3GG7.jpg"), mediaType: "image/jpeg")
				let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/hs3U5CY.png"), mediaType: "image/png")
				return MetadataViews.NFTCollectionDisplay(name: "FIXeS \u{1d509}rc20 Semi-NFT", description: "This collection is used to wrap \u{1d509}rc20 token as semi-NFTs.", externalURL: MetadataViews.ExternalURL("https://fixes.world/"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/fixesWorld")})
		}
		return nil
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(all)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		let identifier = "FRC20SemiNFT_".concat(self.account.address.toString())
		self.CollectionStoragePath = StoragePath(identifier: identifier.concat("collection"))!
		self.CollectionPublicPath = PublicPath(identifier: identifier.concat("collection"))!
		self.CollectionPrivatePath = PrivatePath(identifier: identifier.concat("collection"))!
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&FRC20SemiNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
