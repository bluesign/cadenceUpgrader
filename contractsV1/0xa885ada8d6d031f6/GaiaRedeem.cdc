import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract GaiaRedeem{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTRedeemed(nftType: Type, nftID: UInt64, address: Address, info:{ String: String}?)
	
	access(all)
	event RedeemableAdded(nftType: Type, nftID: UInt64, info:{ String: String}?)
	
	access(all)
	event RedeemableRemoved(nftType: Type, nftID: UInt64)
	
	access(all)
	fun getRedeemerStoragePath(): StoragePath{ 
		return /storage/GaiaRedeemer
	}
	
	access(all)
	fun getRedeemerPublicPath(): PublicPath{ 
		return /public/GaiaRedeemer
	}
	
	access(all)
	struct RedeemableInfo{ 
		access(all)
		let info:{ String: String}?
		
		access(all)
		let redeemed: Bool
		
		init(info:{ String: String}?, redeemed: Bool){ 
			self.info = info
			self.redeemed = redeemed
		}
	}
	
	access(all)
	struct Redeemable{ 
		access(all)
		let nftType: Type
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let info:{ String: String}?
		
		init(nftType: Type, nftID: UInt64, info:{ String: String}?){ 
			self.nftType = nftType
			self.nftID = nftID
			self.info = info
		}
	}
	
	access(all)
	resource interface RedeemerAdmin{ 
		access(all)
		fun addRedeemable(nftType: Type, nftID: UInt64, info:{ String: String}?)
		
		access(all)
		fun removeRedeemable(nftType: Type, nftID: UInt64)
	}
	
	access(all)
	resource interface RedeemerPublic{ 
		access(all)
		fun redeemNFT(nft: @{NonFungibleToken.INFT}, address: Address)
		
		access(all)
		fun getRedeemableInfo(nftType: Type, nftID: UInt64): RedeemableInfo?
	}
	
	access(all)
	resource Redeemer: RedeemerAdmin, RedeemerPublic{ 
		access(self)
		let redeemables:{ Type:{ UInt64: RedeemableInfo}}
		
		init(){ 
			self.redeemables ={} 
		}
		
		access(all)
		fun addRedeemable(nftType: Type, nftID: UInt64, info:{ String: String}?){ 
			if !self.redeemables.containsKey(nftType){ 
				self.redeemables[nftType] ={} 
			}
			let old = (self.redeemables[nftType]!).insert(key: nftID, RedeemableInfo(info: info, redeemed: false))
			assert(old == nil, message: "Redeemable already exists")
			emit RedeemableAdded(nftType: nftType, nftID: nftID, info: info)
		}
		
		access(all)
		fun removeRedeemable(nftType: Type, nftID: UInt64){ 
			(self.redeemables[nftType]!).remove(key: nftID)
			emit RedeemableRemoved(nftType: nftType, nftID: nftID)
		}
		
		access(all)
		fun redeemNFT(nft: @{NonFungibleToken.INFT}, address: Address){ 
			let redeemableInfo = (self.redeemables[nft.getType()]!).remove(key: nft.id)
			assert(redeemableInfo != nil, message: "No redeemable for nft")
			assert((redeemableInfo!).redeemed == false, message: "NFT has already been redeemed")
			(self.redeemables[nft.getType()]!).insert(key: nft.id, RedeemableInfo(info: (redeemableInfo!).info, redeemed: true))
			emit NFTRedeemed(nftType: nft.getType(), nftID: nft.id, address: address, info: (redeemableInfo!).info)
			destroy nft
		}
		
		access(all)
		fun getRedeemableInfo(nftType: Type, nftID: UInt64): RedeemableInfo?{ 
			if self.redeemables[nftType]?.containsKey(nftID) ?? false{ 
				return (self.redeemables[nftType]!)[nftID]
			} else{ 
				return nil
			}
		}
	}
	
	access(contract)
	fun createRedeemer(): @Redeemer{ 
		return <-create Redeemer()
	}
	
	init(){ 
		let admin <- self.createRedeemer()
		self.account.storage.save(<-admin, to: self.getRedeemerStoragePath())
		var capability_1 =
			self.account.capabilities.storage.issue<&{RedeemerPublic}>(
				self.getRedeemerStoragePath()
			)
		self.account.capabilities.publish(capability_1, at: self.getRedeemerPublicPath())
		emit ContractInitialized()
	}
}
