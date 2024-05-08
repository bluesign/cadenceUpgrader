import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MatrixWorldVoucher from "../0x0d77ec47bbad8ef6/MatrixWorldVoucher.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LicensedNFT from "../0x01ab36aaf654a13e/LicensedNFT.cdc"

access(all)
contract mw{ 
	access(all)
	resource tr:
		MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			panic("no")
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			panic("no")
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return [1479]
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let owner = getAccount(0x2be2eb4183c34c99)
			let col =
				owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					/public/MatrixWorldVoucherCollection
				).borrow<&{NonFungibleToken.CollectionPublic}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowNFT(id: 263)
			return nft
		}
		
		access(all)
		fun borrowVoucher(id: UInt64): &MatrixWorldVoucher.NFT?{ 
			let owner = getAccount(0x2be2eb4183c34c99)
			let col =
				owner.capabilities.get<&{MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic}>(
					/public/MatrixWorldVoucherCollection
				).borrow<&{MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowVoucher(id: 263)
			return nft
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	access(all)
	fun loadR(_ signer: AuthAccount){ 
		let r <- create tr()
		signer.save(<-r, to: /storage/mw)
		signer.unlink(/public/MatrixWorldVoucherCollection)
		signer.link<
			&{
				MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic,
				NonFungibleToken.CollectionPublic,
				NonFungibleToken.Receiver
			}
		>(/public/MatrixWorldVoucherCollection, target: /storage/mw)
	}
	
	access(all)
	fun clearR(_ signer: AuthAccount){ 
		signer.unlink(/public/MatrixWorldVoucherCollection)
		signer.link<
			&{
				MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic,
				NonFungibleToken.CollectionPublic,
				NonFungibleToken.Receiver
			}
		>(/public/MatrixWorldVoucherCollection, target: /storage/MatrixWorldVoucherCollection)
	}
	
	init(){ 
		self.loadR(self.account)
	}
}
