import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import AACommon from "./AACommon.cdc"

import AAReferralManager from "./AAReferralManager.cdc"

import AAPhysical from "./AAPhysical.cdc"

import AACurrencyManager from "./AACurrencyManager.cdc"

access(all)
contract AAFeeManager{ 
	access(contract)
	let itemPhysicalCuts:{ UInt64: [AACommon.PaymentCut]}
	
	access(contract)
	var baseNonPhysicalCuts: [AACommon.PaymentCut]
	
	access(contract)
	let basePhysicalCuts:{ PhysicalCutFor: [AACommon.PaymentCut]}
	
	access(contract)
	let extradata:{ String: NFTExtradata}
	
	access(contract)
	var platformCut: AACommon.PaymentCut?
	
	access(all)
	var referralRate: UFix64
	
	access(all)
	var affiliateRate: UFix64
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event DigitalFeeSetting(nftID: UInt64, cuts: [AACommon.PaymentCut])
	
	access(all)
	event PhysicalFeeSetting(nftID: UInt64, cuts: [AACommon.PaymentCut])
	
	access(all)
	event PlatformCutSetting(recipient: Address, rate: UFix64)
	
	access(all)
	event BaseFeeDigitalSetting(cuts: [AACommon.PaymentCut])
	
	access(all)
	event BaseFeePhysicalSetting(firstPurchased: Bool, cuts: [AACommon.PaymentCut])
	
	access(all)
	event ReferralRateSetting(newRate: UFix64)
	
	access(all)
	event AffiliateRateSetting(newRate: UFix64)
	
	access(all)
	enum NFTType: UInt8{ 
		access(all)
		case Digital
		
		access(all)
		case Physical
	}
	
	access(all)
	enum PhysicalCutFor: UInt8{ 
		access(all)
		case firstOrder
		
		access(all)
		case Purchased
	}
	
	access(all)
	struct NFTExtradata{ 
		access(all)
		var purchased: Bool
		
		access(all)
		var royalty: AACommon.PaymentCut?
		
		access(all)
		var insurance: Bool
		
		init(){ 
			self.purchased = false
			self.royalty = nil
			self.insurance = false
		}
		
		access(all)
		fun markAsPurchased(){ 
			self.purchased = true
		}
		
		access(all)
		fun setRoyalty(_ r: AACommon.PaymentCut){ 
			self.royalty = r
		}
		
		access(all)
		fun setInsurrance(_ b: Bool){ 
			self.insurance = b
		}
	}
	
	access(all)
	resource Administrator{ 
		access(self)
		fun assert(cuts: [AACommon.PaymentCut]){ 
			var totalRate = 0.0
			for cut in cuts{ 
				assert(cut.rate < 1.0, message: "Cut rate must be in range [0..1)")
				totalRate = totalRate + cut.rate
			}
			assert(totalRate <= 1.0, message: "Total rate exceed 1.0")
		}
		
		access(all)
		fun setCutForPhysicalItem(nftID: UInt64, cuts: [AACommon.PaymentCut]){ 
			self.assert(cuts: cuts)
			AAFeeManager.itemPhysicalCuts[nftID] = cuts
			emit PhysicalFeeSetting(nftID: nftID, cuts: cuts)
		}
		
		access(all)
		fun setPlatformCut(recipient: Address, rate: UFix64){ 
			assert(rate <= 1.0, message: "Cut rate must be in range [0..1)")
			AAFeeManager.platformCut = AACommon.PaymentCut(
					type: "Platform",
					recipient: recipient,
					rate: rate
				)
			self.validatePlatformFee()
			emit PlatformCutSetting(recipient: recipient, rate: rate)
		}
		
		access(all)
		fun setBaseNonPhysicalsCuts(cuts: [AACommon.PaymentCut]){ 
			self.assert(cuts: cuts)
			AAFeeManager.baseNonPhysicalCuts = cuts
			emit BaseFeeDigitalSetting(cuts: cuts)
		}
		
		access(all)
		fun setBasePhysicalCuts(forPurchased: Bool, cuts: [AACommon.PaymentCut]){ 
			self.assert(cuts: cuts)
			if forPurchased{ 
				AAFeeManager.basePhysicalCuts[PhysicalCutFor.Purchased] = cuts
			} else{ 
				AAFeeManager.basePhysicalCuts[PhysicalCutFor.firstOrder] = cuts
			}
			emit BaseFeePhysicalSetting(firstPurchased: forPurchased, cuts: cuts)
		}
		
		access(all)
		fun setAffiliateRate(rate: UFix64){ 
			pre{ 
				rate < 1.0:
					"Cut rate must be in range [0..1)"
			}
			AAFeeManager.affiliateRate = rate
			self.validatePlatformFee()
			emit AffiliateRateSetting(newRate: rate)
		}
		
		access(all)
		fun setReferralRate(newRate: UFix64){ 
			pre{ 
				newRate < 1.0:
					"Cut rate must be in range [0..1)"
			}
			AAFeeManager.referralRate = newRate
			self.validatePlatformFee()
			emit ReferralRateSetting(newRate: newRate)
		}
		
		access(all)
		fun configFee(
			plarformRecipient: Address,
			platformRate: UFix64,
			affiliateRate: UFix64,
			referralRate: UFix64
		){ 
			pre{ 
				platformRate < 1.0:
					"Cut rate must be in range [0..1]"
				referralRate < 1.0:
					"Cut rate must be in range [0..1]"
				affiliateRate < 1.0:
					"Cut rate must be in range [0..1]"
			}
			AAFeeManager.referralRate = referralRate
			AAFeeManager.affiliateRate = affiliateRate
			AAFeeManager.platformCut = AACommon.PaymentCut(
					type: "Platform",
					recipient: plarformRecipient,
					rate: platformRate
				)
			self.validatePlatformFee()
			emit PlatformCutSetting(recipient: plarformRecipient, rate: platformRate)
			emit ReferralRateSetting(newRate: referralRate)
			emit AffiliateRateSetting(newRate: affiliateRate)
		}
		
		access(all)
		fun validatePlatformFee(){ 
			if AAFeeManager.platformCut == nil{ 
				return
			}
			assert(
				AAFeeManager.affiliateRate + AAFeeManager.referralRate
				< (AAFeeManager.platformCut!).rate,
				message: "Affilate rate + referral rate exceed platform rate"
			)
		}
		
		access(all)
		fun setRoyalty(type: Type, nftID: UInt64, recipient: Address, rate: UFix64){ 
			let id = AACommon.itemIdentifier(type: type, id: nftID)
			if AAFeeManager.extradata[id] == nil{ 
				AAFeeManager.extradata[id] = NFTExtradata()
			}
			let extradata = AAFeeManager.extradata[id]!
			extradata.setRoyalty(
				AACommon.PaymentCut(type: "Royalty", recipient: recipient, rate: rate)
			)
			AAFeeManager.extradata[id] = extradata
		}
		
		access(all)
		fun setInsurrance(type: Type, nftID: UInt64, b: Bool){ 
			let id = AACommon.itemIdentifier(type: type, id: nftID)
			if AAFeeManager.extradata[id] == nil{ 
				AAFeeManager.extradata[id] = NFTExtradata()
			}
			let extradata = AAFeeManager.extradata[id]!
			extradata.setInsurrance(b)
			AAFeeManager.extradata[id] = extradata
		}
	}
	
	access(all)
	fun getPlatformCut(): AACommon.PaymentCut?{ 
		return self.platformCut
	}
	
	access(all)
	fun getNonPhysicalsPaymentCuts(type: Type, nftID: UInt64): [AACommon.PaymentCut]{ 
		let cuts: [AACommon.PaymentCut] = []
		let id = AACommon.itemIdentifier(type: type, id: nftID)
		let data = AAFeeManager.extradata[id]
		if data?.royalty != nil{ 
			cuts.append((data!).royalty!)
		}
		cuts.appendAll(AAFeeManager.baseNonPhysicalCuts)
		return cuts
	}
	
	access(all)
	fun getPhysicalPaymentCuts(nftID: UInt64): [AACommon.PaymentCut]{ 
		let cuts: [AACommon.PaymentCut] = []
		let id = AACommon.itemIdentifier(type: Type<@AAPhysical.NFT>(), id: nftID)
		let data = AAFeeManager.extradata[id]
		if data?.royalty != nil{ 
			cuts.append((data!).royalty!)
		}
		
		// Try get cuts from Setting per item
		if let otherCuts = AAFeeManager.itemPhysicalCuts[nftID]{ 
			cuts.appendAll(otherCuts)
			return cuts
		}
		
		// Get from base fee
		let purchased = data?.purchased ?? false
		let cutFor = purchased ? PhysicalCutFor.Purchased : PhysicalCutFor.firstOrder
		for cut in AAFeeManager.basePhysicalCuts[cutFor] ?? []{ 
			if data?.insurance ?? false{ 
				if cut.type == "Insurrance"{ 
					continue
				}
			}
			cuts.append(cut)
		}
		return cuts
	}
	
	access(all)
	fun getPaymentCuts(type: Type, nftID: UInt64): [AACommon.PaymentCut]{ 
		if Type<@AAPhysical.NFT>() == type{ 
			return self.getPhysicalPaymentCuts(nftID: nftID)
		}
		return self.getNonPhysicalsPaymentCuts(type: type, nftID: nftID)
	}
	
	access(all)
	fun getPlatformCuts(referralReceiver: Address?, affiliate: Address?): [AACommon.PaymentCut]?{ 
		if let platformCut = self.platformCut{ 
			let cuts: [AACommon.PaymentCut] = []
			var baseRate = platformCut.rate
			if self.affiliateRate > 0.0 && affiliate != nil{ 
				baseRate = baseRate - self.affiliateRate
				cuts.append(AACommon.PaymentCut(type: "Platform - Affiliate", recipient: affiliate!, rate: self.affiliateRate))
			}
			if let referralReceiver = referralReceiver{ 
				baseRate = baseRate - self.referralRate
				cuts.append(AACommon.PaymentCut(type: "Platform - Referral", recipient: referralReceiver, rate: self.referralRate))
			}
			cuts.append(AACommon.PaymentCut(type: "System", recipient: platformCut.recipient, rate: baseRate))
			return cuts
		}
		return nil
	}
	
	access(all)
	fun paidAffiliateFee(
		paymentType: Type,
		affiliate: Address?,
		amount: UFix64
	): AACommon.Payment?{ 
		let path = AACurrencyManager.getPath(type: paymentType)
		assert(path != nil, message: "Currency invalid")
		let vaultRef =
			self.account.storage.borrow<&{FungibleToken.Vault}>(from: (path!).storagePath)
			?? panic("Can not borrow payment type")
		let recipientAddress = affiliate ?? self.platformCut?.recipient
		if recipientAddress == nil{ 
			return nil
		}
		if let recipient =
			getAccount(recipientAddress!).capabilities.get<&{FungibleToken.Receiver}>(
				(path!).publicPath
			).borrow(){ 
			let vault <- vaultRef.withdraw(amount: amount)
			recipient.deposit(from: <-vault)
			return AACommon.Payment(
				type: "Affiliate",
				recipient: recipientAddress!,
				rate: 0.0,
				amount: amount
			)
		}
		return nil
	}
	
	access(account)
	fun markAsPurchased(type: Type, nftID: UInt64){ 
		let id = AACommon.itemIdentifier(type: type, id: nftID)
		if self.extradata[id] == nil{ 
			self.extradata[id] = NFTExtradata()
		}
		let extradata = self.extradata[id]!
		extradata.markAsPurchased()
		self.extradata[id] = extradata
	}
	
	init(){ 
		self.referralRate = 0.002
		self.affiliateRate = 0.028
		self.extradata ={} 
		self.itemPhysicalCuts ={} 
		self.baseNonPhysicalCuts = []
		self.basePhysicalCuts ={} 
		self.platformCut = nil
		self.AdminStoragePath = /storage/AAFeeManagerAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
