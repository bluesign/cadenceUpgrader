// mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// testnet
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"
// local
//  import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
//  import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"
access(all)
contract ArleeSceneVoucher: NonFungibleToken{ 
	// Total number of ArleeSceneVoucher NFT in existence
	access(all)
	var totalSupply: UInt64
	
	// Active Status
	access(all)
	var mintable: Bool
	
	// Free Mint List and quota
	access(account)
	var freeMintAcct:{ Address: UInt64}
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Created(id: UInt64, species: String, royalties: [Royalty], creator: Address)
	
	access(all)
	event FreeMintListAcctUpdated(address: Address, mint: UInt64)
	
	access(all)
	event FreeMintListAcctRemoved(address: Address)
	
	access(all)
	event MarketplaceCutUpdate(oldCut: UFix64, newCut: UFix64)
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Royalty
	access(all)
	var marketplaceCut: UFix64
	
	access(all)
	let arlequinWallet: Address
	
	// Royalty Struct (For later royalty and marketplace implementation)
	access(all)
	struct Royalty{ 
		access(all)
		let creditor: String
		
		access(all)
		let wallet: Address
		
		access(all)
		let cut: UFix64
		
		init(creditor: String, wallet: Address, cut: UFix64){ 
			self.creditor = creditor
			self.wallet = wallet
			self.cut = cut
		}
	}
	
	// ArleeSceneVoucher NFT (includes the species, metadata)
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let species: String
		
		access(contract)
		let royalties: [Royalty]
		
		init(species: String, royalties: [Royalty]){ 
			self.id = ArleeSceneVoucher.totalSupply
			self.species = species
			self.royalties = royalties
			// update totalSupply
			ArleeSceneVoucher.totalSupply = ArleeSceneVoucher.totalSupply + 1
		}
		
		// Function to return royalty
		access(all)
		fun getRoyalties(): [Royalty]{ 
			return self.royalties
		}
		
		// MetadataViews Implementation
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<[Royalty]>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Arlee Scene NFT Voucher", description: "This voucher entitles the owner to claim a ".concat(self.species).concat(" Arlequin NFT."), thumbnail: MetadataViews.HTTPFile(url: "https://painter.arlequin.gg/voucher/".concat(self.species)))
				case Type<[Royalty]>():
					return self.royalties
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Collection Interfaces Needed for borrowing NFTs
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(collection: @{NonFungibleToken.Collection})
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		fun borrowArleeSceneVoucher(id: UInt64): &ArleeSceneVoucher.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Component reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection that implements NonFungible Token Standard with Collection Public and MetaDataViews
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot find Alree Scene Voucher NFT in your Collection, id: ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(withdrawIDs: [UInt64]): @{NonFungibleToken.Collection}{ 
			let collection <- ArleeSceneVoucher.createEmptyCollection(nftType: Type<@ArleeSceneVoucher.Collection>())
			for id in withdrawIDs{ 
				let nft <- self.ownedNFTs.remove(key: id) ?? panic("Cannot find Arlee Scene Voucher NFT in your Collection, id: ".concat(id.toString()))
				collection.deposit(token: <-nft)
			}
			return <-collection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ArleeSceneVoucher.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(collection: @{NonFungibleToken.Collection}){ 
			for id in collection.getIDs(){ 
				let token <- collection.withdraw(withdrawID: id)
				self.deposit(token: <-token)
			}
			destroy collection
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowArleeSceneVoucher(id: UInt64): &ArleeSceneVoucher.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			}
			let nftRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ref = nftRef as! &ArleeSceneVoucher.NFT
			return ref
		}
		
		//MetadataViews Implementation
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nftRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ArleeSceneVoucherRef = nftRef as! &ArleeSceneVoucher.NFT
			return ArleeSceneVoucherRef as &{ViewResolver.Resolver}
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/* Query Function (Can also be done in Arlee Contract) */
	// return true if the address holds the Scene NFT
	access(all)
	fun getArleeSceneVoucherIDs(addr: Address): [UInt64]?{ 
		let holderCap = getAccount(addr).capabilities.get<&ArleeSceneVoucher.Collection>(ArleeSceneVoucher.CollectionPublicPath)
		if holderCap.borrow() == nil{ 
			return nil
		}
		let holderRef = holderCap.borrow() ?? panic("Cannot borrow Arlee Scene Voucher Collection Reference")
		return holderRef.getIDs()
	}
	
	access(all)
	fun getRoyalty(): [Royalty]{ 
		return [Royalty(creditor: "Arlequin", wallet: ArleeSceneVoucher.arlequinWallet, cut: ArleeSceneVoucher.marketplaceCut)]
	}
	
	access(all)
	fun getFreeMintAcct():{ Address: UInt64}{ 
		return ArleeSceneVoucher.freeMintAcct
	}
	
	access(all)
	fun getFreeMintQuota(addr: Address): UInt64?{ 
		return ArleeSceneVoucher.freeMintAcct[addr]
	}
	
	/* Admin Function */
	access(account)
	fun setMarketplaceCut(cut: UFix64){ 
		let oldCut = ArleeSceneVoucher.marketplaceCut
		ArleeSceneVoucher.marketplaceCut = cut
		emit MarketplaceCutUpdate(oldCut: oldCut, newCut: cut)
	}
	
	access(account)
	fun mintVoucherNFT(recipient: &ArleeSceneVoucher.Collection, species: String){ 
		pre{ 
			ArleeSceneVoucher.mintable:
				"Public minting is not available at the moment."
		}
		// further checks
		assert(recipient.owner != nil, message: "Cannot pass in a Collection reference with no owner")
		let ownerAddr = (recipient.owner!).address
		let royalties = ArleeSceneVoucher.getRoyalty()
		let newNFT <- create ArleeSceneVoucher.NFT(species: species, royalties: royalties)
		emit Created(id: newNFT.id, species: species, royalties: royalties, creator: ownerAddr)
		recipient.deposit(token: <-newNFT)
	}
	
	access(account)
	fun addFreeMintAcct(addr: Address, mint: UInt64){ 
		pre{ 
			ArleeSceneVoucher.freeMintAcct[addr] == nil:
				"This address is already registered in Free Mint list, please use other functions for altering"
		}
		ArleeSceneVoucher.freeMintAcct[addr] = mint
		emit FreeMintListAcctUpdated(address: addr, mint: mint)
	}
	
	access(account)
	fun batchAddFreeMintAcct(list:{ Address: UInt64}){ 
		for addr in list.keys{ 
			if ArleeSceneVoucher.freeMintAcct[addr] == nil{ 
				ArleeSceneVoucher.addFreeMintAcct(addr: addr, mint: list[addr]!)
			} else{ 
				ArleeSceneVoucher.addFreeMintAcctQuota(addr: addr, additionalMint: list[addr]!)
			}
		}
	}
	
	access(account)
	fun removeFreeMintAcct(addr: Address){ 
		pre{ 
			ArleeSceneVoucher.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota."
		}
		ArleeSceneVoucher.freeMintAcct.remove(key: addr)
		emit FreeMintListAcctRemoved(address: addr)
	}
	
	access(account)
	fun setFreeMintAcctQuota(addr: Address, mint: UInt64){ 
		pre{ 
			mint > 0:
				"Minting limit cannot be smaller than 1"
			ArleeSceneVoucher.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota"
		}
		ArleeSceneVoucher.freeMintAcct[addr] = mint
		emit FreeMintListAcctUpdated(address: addr, mint: mint)
	}
	
	access(account)
	fun addFreeMintAcctQuota(addr: Address, additionalMint: UInt64){ 
		pre{ 
			ArleeSceneVoucher.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota"
		}
		ArleeSceneVoucher.freeMintAcct[addr] = additionalMint + ArleeSceneVoucher.freeMintAcct[addr]!
		emit FreeMintListAcctUpdated(address: addr, mint: ArleeSceneVoucher.freeMintAcct[addr]!)
	}
	
	access(account)
	fun setMintable(mintable: Bool){ 
		ArleeSceneVoucher.mintable = mintable
	}
	
	init(){ 
		self.totalSupply = 0
		self.mintable = false
		self.freeMintAcct ={} 
		// Paths
		self.CollectionStoragePath = /storage/ArleeSceneVoucher
		self.CollectionPublicPath = /public/ArleeSceneVoucher
		// Royalty
		self.marketplaceCut = 0.05
		self.arlequinWallet = self.account.address
		// Setup Account 
		self.account.storage.save(<-ArleeSceneVoucher.createEmptyCollection(nftType: Type<@ArleeSceneVoucher.Collection>()), to: ArleeSceneVoucher.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&ArleeSceneVoucher.Collection>(ArleeSceneVoucher.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: ArleeSceneVoucher.CollectionPublicPath)
	}
}
