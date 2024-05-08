import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ArleePartner from "./ArleePartner.cdc"

import ArleeScene from "./ArleeScene.cdc"

access(all)
contract Arlequin{ 
	access(all)
	var arleepartnerNFTPrice: UFix64
	
	access(all)
	var sceneNFTPrice: UFix64
	
	// This is the ratio to partners in arleepartnerNFT sales, ratio to Arlequin will be (1 - partnerSplitRatio)
	access(all)
	var partnerSplitRatio: UFix64
	
	// Paths
	access(all)
	let ArleePartnerAdminStoragePath: StoragePath
	
	access(all)
	let ArleeSceneAdminStoragePath: StoragePath
	
	// Query Functions
	/* For ArleePartner */
	access(all)
	fun checkArleePartnerNFT(addr: Address): Bool{ 
		return ArleePartner.checkArleePartnerNFT(addr: addr)
	}
	
	access(all)
	fun getArleePartnerNFTIDs(addr: Address): [UInt64]?{ 
		return ArleePartner.getArleePartnerNFTIDs(addr: addr)
	}
	
	access(all)
	fun getArleePartnerNFTName(id: UInt64): String?{ 
		return ArleePartner.getArleePartnerNFTName(id: id)
	}
	
	access(all)
	fun getArleePartnerNFTNames(addr: Address): [String]?{ 
		return ArleePartner.getArleePartnerNFTNames(addr: addr)
	}
	
	access(all)
	fun getArleePartnerAllNFTNames():{ UInt64: String}{ 
		return ArleePartner.getAllArleePartnerNFTNames()
	}
	
	access(all)
	fun getArleePartnerRoyalties():{ String: ArleePartner.Royalty}{ 
		return ArleePartner.getRoyalties()
	}
	
	access(all)
	fun getArleePartnerRoyaltiesByPartner(partner: String): ArleePartner.Royalty?{ 
		return ArleePartner.getPartnerRoyalty(partner: partner)
	}
	
	access(all)
	fun getArleePartnerOwner(id: UInt64): Address?{ 
		return ArleePartner.getOwner(id: id)
	}
	
	access(all)
	fun getArleePartnerMintable():{ String: Bool}{ 
		return ArleePartner.getMintable()
	}
	
	access(all)
	fun getArleePartnerTotalSupply(): UInt64{ 
		return ArleePartner.totalSupply
	}
	
	// For Minting 
	access(all)
	fun getArleePartnerMintPrice(): UFix64{ 
		return Arlequin.arleepartnerNFTPrice
	}
	
	access(all)
	fun getArleePartnerSplitRatio(): UFix64{ 
		return Arlequin.partnerSplitRatio
	}
	
	/* For ArleeScene */
	access(all)
	fun getArleeSceneNFTIDs(addr: Address): [UInt64]?{ 
		return ArleeScene.getArleeSceneIDs(addr: addr)
	}
	
	access(all)
	fun getArleeSceneRoyalties(): [ArleeScene.Royalty]{ 
		return ArleeScene.getRoyalty()
	}
	
	access(all)
	fun getArleeSceneCID(id: UInt64): String?{ 
		return ArleeScene.getArleeSceneCID(id: id)
	}
	
	access(all)
	fun getAllArleeSceneCID():{ UInt64: String}{ 
		return ArleeScene.getAllArleeSceneCID()
	}
	
	access(all)
	fun getArleeSceneFreeMintAcct():{ Address: UInt64}{ 
		return ArleeScene.getFreeMintAcct()
	}
	
	access(all)
	view fun getArleeSceneFreeMintQuota(addr: Address): UInt64?{ 
		return ArleeScene.getFreeMintQuota(addr: addr)
	}
	
	access(all)
	fun getArleeSceneOwner(id: UInt64): Address?{ 
		return ArleeScene.getOwner(id: id)
	}
	
	access(all)
	fun getArleeSceneMintable(): Bool{ 
		return ArleeScene.mintable
	}
	
	access(all)
	fun getArleeSceneTotalSupply(): UInt64{ 
		return ArleeScene.totalSupply
	}
	
	// For Minting 
	access(all)
	fun getArleeSceneMintPrice(): UFix64{ 
		return Arlequin.sceneNFTPrice
	}
	
	access(all)
	resource ArleePartnerAdmin{ 
		// ArleePartner NFT Admin Functinos
		access(all)
		fun addPartner(creditor: String, addr: Address, cut: UFix64){ 
			ArleePartner.addPartner(creditor: creditor, addr: addr, cut: cut)
		}
		
		access(all)
		fun removePartner(creditor: String){ 
			ArleePartner.removePartner(creditor: creditor)
		}
		
		access(all)
		fun setMarketplaceCut(cut: UFix64){ 
			ArleePartner.setMarketplaceCut(cut: cut)
		}
		
		access(all)
		fun setPartnerCut(partner: String, cut: UFix64){ 
			ArleePartner.setPartnerCut(partner: partner, cut: cut)
		}
		
		access(all)
		fun setMintable(mintable: Bool){ 
			ArleePartner.setMintable(mintable: mintable)
		}
		
		access(all)
		fun setSpecificPartnerNFTMintable(partner: String, mintable: Bool){ 
			ArleePartner.setSpecificPartnerNFTMintable(partner: partner, mintable: mintable)
		}
		
		// for Minting
		access(all)
		fun setArleePartnerMintPrice(price: UFix64){ 
			Arlequin.arleepartnerNFTPrice = price
		}
		
		access(all)
		fun setArleePartnerSplitRatio(ratio: UFix64){ 
			pre{ 
				ratio <= 1.0:
					"The spliting ratio cannot be greater than 1.0"
			}
			Arlequin.partnerSplitRatio = ratio
		}
		
		// Add flexibility to giveaway : an Admin mint function.
		access(all)
		fun adminMintArleePartnerNFT(partner: String){ 
			// get all merchant receiving vault references 
			let recipientCap =
				getAccount(Arlequin.account.address).capabilities.get<&ArleePartner.Collection>(
					ArleePartner.CollectionPublicPath
				)
			let recipient =
				recipientCap.borrow() ?? panic("Cannot borrow Arlequin's Collection Public")
			// deposit
			ArleePartner.adminMintArleePartnerNFT(recipient: recipient, partner: partner)
		}
	}
	
	access(all)
	resource ArleeSceneAdmin{ 
		// Arlee Scene NFT Admin Functinos
		access(all)
		fun setMarketplaceCut(cut: UFix64){ 
			ArleeScene.setMarketplaceCut(cut: cut)
		}
		
		access(all)
		fun addFreeMintAcct(addr: Address, mint: UInt64){ 
			ArleeScene.addFreeMintAcct(addr: addr, mint: mint)
		}
		
		access(all)
		fun batchAddFreeMintAcct(list:{ Address: UInt64}){ 
			ArleeScene.batchAddFreeMintAcct(list: list)
		}
		
		access(all)
		fun removeFreeMintAcct(addr: Address){ 
			ArleeScene.removeFreeMintAcct(addr: addr)
		}
		
		// set an acct's free minting limit
		access(all)
		fun setFreeMintAcctQuota(addr: Address, mint: UInt64){ 
			ArleeScene.setFreeMintAcctQuota(addr: addr, mint: mint)
		}
		
		// add to an acct's free minting limit
		access(all)
		fun addFreeMintAcctQuota(addr: Address, additionalMint: UInt64){ 
			ArleeScene.addFreeMintAcctQuota(addr: addr, additionalMint: additionalMint)
		}
		
		access(all)
		fun setMintable(mintable: Bool){ 
			ArleeScene.setMintable(mintable: mintable)
		}
		
		// for minting
		access(all)
		fun setArleeSceneMintPrice(price: UFix64){ 
			Arlequin.sceneNFTPrice = price
		}
	}
	
	/* Public Minting for ArleePartnerNFT */
	access(all)
	fun mintArleePartnerNFT(buyer: Address, partner: String, paymentVault: @{FungibleToken.Vault}){ 
		pre{ 
			paymentVault.balance >= Arlequin.arleepartnerNFTPrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"payment type not in FlowToken.Vault."
		}
		// get all merchant receiving vault references 
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receiving vault reference")
		let partnerRoyalty =
			self.getArleePartnerRoyaltiesByPartner(partner: partner)
			?? panic("Cannot find partner : ".concat(partner))
		let partnerAddr = partnerRoyalty.wallet
		let partnerVaultCap =
			getAccount(partnerAddr).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
		let partnerVault =
			partnerVaultCap.borrow() ?? panic("Cannot borrow partner's receiving vault reference")
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleePartner.Collection>(
				ArleePartner.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		// splitting vaults for partner and arlequin
		let toPartnerVault <-
			paymentVault.withdraw(amount: paymentVault.balance * Arlequin.partnerSplitRatio)
		// deposit
		arlequinVault.deposit(from: <-paymentVault)
		partnerVault.deposit(from: <-toPartnerVault)
		ArleePartner.mintArleePartnerNFT(recipient: recipient, partner: partner)
	}
	
	/* Public Minting for ArleeSceneNFT */
	access(all)
	fun mintSceneNFT(
		buyer: Address,
		cid: String,
		description: String,
		paymentVault: @{FungibleToken.Vault}
	){ 
		pre{ 
			paymentVault.balance >= Arlequin.sceneNFTPrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"payment type not in FlowToken.Vault."
		}
		// get all merchant receiving vault references 
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receiving vault reference")
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
				ArleeScene.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		// deposit
		arlequinVault.deposit(from: <-paymentVault)
		ArleeScene.mintSceneNFT(recipient: recipient, cid: cid, description: description)
	}
	
	/* Free Minting for ArleeSceneNFT */
	access(all)
	fun mintSceneFreeMintNFT(buyer: Address, cid: String, description: String){ 
		pre{ 
			Arlequin.getArleeSceneFreeMintQuota(addr: buyer) != nil:
				"You are not given free mint quotas"
			Arlequin.getArleeSceneFreeMintQuota(addr: buyer)! > 0:
				"You ran out of free mint quotas"
		}
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
				ArleeScene.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		ArleeScene.freeMintAcct[buyer] = ArleeScene.freeMintAcct[buyer]! - 1
		// deposit
		ArleeScene.mintSceneNFT(recipient: recipient, cid: cid, description: description)
	}
	
	init(){ 
		self.arleepartnerNFTPrice = 10.0
		self.sceneNFTPrice = 10.0
		self.partnerSplitRatio = 1.0
		self.ArleePartnerAdminStoragePath = /storage/ArleePartnerAdmin
		self.ArleeSceneAdminStoragePath = /storage/ArleeSceneAdmin
		self.account.storage.save(
			<-create ArleePartnerAdmin(),
			to: Arlequin.ArleePartnerAdminStoragePath
		)
		self.account.storage.save(
			<-create ArleeSceneAdmin(),
			to: Arlequin.ArleeSceneAdminStoragePath
		)
	}
}
