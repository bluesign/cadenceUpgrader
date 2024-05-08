import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import DimensionXComics from "../0xe3ad6030cbaff1c2/DimensionXComics.cdc"

access(all)
contract DimensionXComicsPrimarySaleMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event MinterCreated(maxMints: Int)
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	resource interface MinterCapSetter{ 
		access(all)
		fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>)
	}
	
	access(all)
	resource Minter: GaiaPrimarySale.IMinter, MinterCapSetter{ 
		access(contract)
		var dmxComicsMinterCap: Capability<&DimensionXComics.NFTMinter>?
		
		access(contract)
		let escrowCollection: @DimensionXComics.Collection
		
		access(all)
		let maxMints: Int
		
		access(all)
		var currentMints: Int
		
		access(all)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.currentMints < self.maxMints:
					"mints exhausted: ".concat(self.currentMints.toString()).concat("/").concat(self.maxMints.toString())
			}
			let minter = (self.dmxComicsMinterCap!).borrow() ?? panic("Unable to borrow minter")
			minter.mintNFT(recipient: &self.escrowCollection as &DimensionXComics.Collection)
			let ids = self.escrowCollection.getIDs()
			assert(ids.length == 1, message: "Escrow collection count invalid")
			let nft <- self.escrowCollection.withdraw(withdrawID: ids[0])
			self.currentMints = self.currentMints + 1
			return <-nft
		}
		
		access(all)
		fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>){ 
			self.dmxComicsMinterCap = minterCap
		}
		
		access(all)
		fun hasValidMinterCap(): Bool{ 
			return self.dmxComicsMinterCap != nil && (self.dmxComicsMinterCap!).check()
		}
		
		init(maxMints: Int){ 
			self.maxMints = maxMints
			self.currentMints = 0
			self.escrowCollection <- DimensionXComics.createEmptyCollection(nftType: Type<@DimensionXComics.Collection>()) as! @DimensionXComics.Collection
			self.dmxComicsMinterCap = nil
			emit MinterCreated(maxMints: self.maxMints)
		}
	}
	
	access(all)
	fun createMinter(maxMints: Int): @Minter{ 
		return <-create Minter(maxMints: maxMints)
	}
	
	init(){ 
		self.MinterPrivatePath = /private/DimensionXComicsPrimarySaleMinterPrivatePath001
		self.MinterStoragePath = /storage/DimensionXComicsPrimarySaleMinterStoragePath001
		self.MinterPublicPath = /public/DimensionXComicsPrimarySaleMinterPublicPath001
		emit ContractInitialized()
	}
}
