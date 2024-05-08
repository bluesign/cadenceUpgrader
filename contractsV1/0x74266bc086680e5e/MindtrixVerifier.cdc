/*
============================================================
Name: NFT Verifier Contract for Mindtrix
============================================================
This contract is inspired from FLOATVerifiers that comes from
Emerald City, Jacob Tucker.
It abstracts the verification logic out of the main contract.
Therefore, this contract is scalable with other forms of
conditions.
*/

import MindtrixViews from "./MindtrixViews.cdc"

access(all)
contract MindtrixVerifier{ 
	access(all)
	struct TimeLock: MindtrixViews.IVerifier{ 
		access(all)
		let startTime: UFix64
		
		access(all)
		let endTime: UFix64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}, _ isAssert: Bool):{ String: Bool}{ 
			let currentTime = getCurrentBlock().timestamp
			let isYetToStart = currentTime < self.startTime
			let isEnd = currentTime > self.endTime
			if isAssert{ 
				assert(!isYetToStart, message: "This Mindtrix NFT is yet to start.")
				assert(!isEnd, message: "Oops! The time has run out to mint this Mindtrix NFT.")
			}
			return{ "isYetToStart": isYetToStart, "isEnd": isEnd}
		}
		
		init(startTime: UFix64, endTime: UFix64){ 
			self.startTime = startTime
			self.endTime = endTime
		}
	}
	
	// deprecated, use LimitedQuantityV2 instead
	access(all)
	struct LimitedQuantity: MindtrixViews.IVerifier{ 
		access(all)
		var maxEdition: UInt64
		
		access(all)
		var maxMintTimesPerAddress: UInt64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}, _ isAssert: Bool):{ String: Bool}{ 
			let currentEdition = params["currentEdition"]! as! UInt64
			let recipientMintTimes = params["recipientMintQuantityPerTransaction"]! as! UInt64
			let isOverSupply = currentEdition >= self.maxEdition
			let isOverMintTimesPerAddress = recipientMintTimes >= self.maxMintTimesPerAddress
			if isAssert{ 
				assert(!isOverSupply, message: "Oops! Run out of the supply!")
				assert(!isOverMintTimesPerAddress, message: "The address has reached the max mint times.")
			}
			return{ "isOverSupply": isOverSupply, "isOverMintTimesPerAddress": isOverMintTimesPerAddress}
		}
		
		init(maxEdition: UInt64, maxMintTimesPerAddress: UInt64, maxQuantityPerTransaction: UInt64){ 
			self.maxEdition = maxEdition
			self.maxMintTimesPerAddress = maxMintTimesPerAddress
		}
	}
	
	access(all)
	struct LimitedQuantityV2: MindtrixViews.IVerifier{ 
		access(all)
		var intDic:{ String: UInt64}
		
		access(all)
		var fixDic:{ String: UFix64}
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}, _ isAssert: Bool):{ String: Bool}{ 
			let maxEdition = self.intDic["maxEdition"]!
			let maxSupplyPerRound = self.intDic["maxSupplyPerRound"] ?? nil
			let maxSupplyPerEntity = self.intDic["maxSupplyPerEntity"] ?? nil
			let maxMintTimesPerAddress = self.intDic["maxMintTimesPerAddress"]!
			let maxMintQuantityPerTransaction = self.intDic["maxMintQuantityPerTransaction"]!
			let maxMintTimesPerEntity = self.intDic["maxMintTimesPerEntity"]
			let currentEdition = params["currentEdition"]! as! UInt64
			let currentEntityEdition = params["currentEntityEdition"] as? UInt64
			let recipientMaxMintTimesPerAddress = params["recipientMaxMintTimesPerAddress"]! as! UInt64
			let recipientMintQuantityPerTransaction = params["recipientMintQuantityPerTransaction"]! as! UInt64
			let recipientMintQuantityPerEntity = params["recipientMintQuantityPerEntity"]! as! UInt64
			let isMaxEditionPerRoundExist = maxSupplyPerRound != nil && maxSupplyPerRound! > 0
			let isEntitySupplyLimitExist = maxSupplyPerEntity != nil && currentEntityEdition != nil
			// supply condition priority: maxSupplyPerRound -> maxSupplyPerEntity -> maxEdition
			let isOverSupply = isMaxEditionPerRoundExist ? currentEdition >= maxSupplyPerRound! : isEntitySupplyLimitExist ? currentEntityEdition! >= maxSupplyPerEntity! : currentEdition >= maxEdition
			let isOverMintTimesPerAddress = recipientMaxMintTimesPerAddress >= maxMintTimesPerAddress
			let isOverMintQuantityPerTransaction = recipientMintQuantityPerTransaction > maxMintQuantityPerTransaction
			let isOverMintTimesPerEntity = recipientMintQuantityPerEntity >= maxMintTimesPerEntity!
			if isAssert == true{ 
				assert(!isOverSupply, message: "Oops! Run out of the supply!")
				assert(!isOverMintTimesPerAddress, message: "The address has reached the max mint times.")
				assert(!isOverMintQuantityPerTransaction, message: "recipientMaxMintTimesPerAddress", "Cannot mint over ".concat(maxMintQuantityPerTransaction.toString()).concat(" per transaction!"))
				assert(!isOverMintTimesPerEntity, message: "Cannot mint over ".concat(recipientMintQuantityPerEntity.toString()).concat(" per entity!"))
			}
			return{ "isOverSupply": isOverSupply, "isOverMintTimesPerAddress": isOverMintTimesPerAddress, "isOverMintQuantityPerTransaction": isOverMintQuantityPerTransaction, "isOverMintTimesPerEntity": isOverMintTimesPerEntity}
		}
		
		init(intDic:{ String: UInt64}, fixDic:{ String: UFix64}){ 
			self.intDic = intDic
			self.fixDic = fixDic
		}
	}
	
	access(all)
	struct ClaimCode: MindtrixViews.IVerifier{ 
		access(all)
		let publicKey: String
		
		access(all)
		let randomstamp: UInt64
		
		access(all)
		fun verify(_ params:{ String: AnyStruct}, _ isAssert: Bool):{ String: Bool}{ 
			let randomstampStr = (params["claimCodeRandomstamp"]! as! UInt64).toString()
			let recipientAddressStr = (params["recipientAddress"]! as! Address).toString()
			let data: [UInt8] = recipientAddressStr.concat("-").concat(randomstampStr).utf8
			let sig: [UInt8] = (params["claimCodeSig"]! as! String).decodeHex()
			let publicKey = PublicKey(publicKey: self.publicKey.decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
			let valid = publicKey.verify(signature: sig, signedData: data, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
			if isAssert == true{ 
				assert(valid, message: "You did not input the correct claim code.")
			}
			return{ "isClaimCodePassed": valid}
		}
		
		init(publicKey: String, randomstamp: UInt64){ 
			self.publicKey = publicKey
			self.randomstamp = randomstamp
		}
	}
}
