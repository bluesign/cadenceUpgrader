//ArleeScene NFT Contract
/*  This contract defines ArleeScene NFTs.
	Users can mint this NFT with FLOW
	Users owning the ArleePartner NFT can mint an Advanced One.
	The fund received will be deposited to the Admin wallet.

	Will be incorporated to Arlee Contract 
	** The Marketpalce Royalty need to be confirmed.
 */

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
contract ArleeScene: NonFungibleToken{ 
	// Total number of ArleeScene NFT in existance
	access(all)
	var totalSupply: UInt64
	
	// Controls whether the ArleePartnerNFT function
	// Stores all minted Scenes { ID : CID }
	access(account)
	var mintedScenes:{ UInt64: String}
	
	// Stores all ownedScenes { Owner : Scene IDs }
	access(account)
	var ownedScenes:{ Address: [UInt64]}
	
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
	event Created(id: UInt64, cid: String, royalties: [Royalty], creator: Address)
	
	access(all)
	event ArleeCIDUpdated(id: UInt64, oldCID: String, newCID: String)
	
	access(all)
	event MetadataUpdated(key: String, value: String, oldValue: String?)
	
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
	
	// ArleeScene NFT (includes the CID, creator, royalty)
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var cid: String
		
		access(all)
		let creator: Address
		
		access(all)
		let metadata:{ String: String}
		
		access(contract)
		let royalties: [Royalty]
		
		init(cid: String, creator: Address, royalties: [Royalty], metadata:{ String: String}){ 
			self.id = ArleeScene.totalSupply
			self.cid = cid
			self.creator = creator
			self.royalties = royalties
			self.metadata = metadata
			// update totalSupply
			ArleeScene.totalSupply = ArleeScene.totalSupply + 1
		}
		
		// function for upgrading Arlee by replacing CID
		access(account)
		fun updateCID(newCID: String){ 
			let oldCID = self.cid
			self.cid = newCID
			emit ArleeCIDUpdated(id: self.id, oldCID: oldCID, newCID: newCID)
		}
		
		access(account)
		fun updateMetadata(key: String, value: String){ 
			let oldValue = self.metadata[key]
			self.metadata[key] = value
			emit MetadataUpdated(key: key, value: value, oldValue: oldValue)
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
					let displayUrl = "https://painter.arlequin.gg/".concat(self.cid)
					return MetadataViews.Display(name: "Arlee Scene NFT", description: "This is the NFT created with Arlequin Painter.", thumbnail: MetadataViews.HTTPFile(url: displayUrl))
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
		fun borrowArleeScene(id: UInt64): &ArleeScene.NFT?{ 
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot find Alree Scene NFT in your Collection, id: ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			// update IDs for contract record
			if self.owner != nil{ 
				ArleeScene.ownedScenes[(self.owner!).address] = self.getIDs()
			}
			return <-token
		}
		
		access(all)
		fun batchWithdraw(withdrawIDs: [UInt64]): @{NonFungibleToken.Collection}{ 
			let collection <- ArleeScene.createEmptyCollection(nftType: Type<@ArleeScene.Collection>())
			for id in withdrawIDs{ 
				let nft <- self.ownedNFTs.remove(key: id) ?? panic("Cannot find Arlee Scene NFT in your Collection, id: ".concat(id.toString()))
				collection.deposit(token: <-nft)
			}
			return <-collection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ArleeScene.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			// update IDs for contract record
			if self.owner != nil{ 
				ArleeScene.ownedScenes[(self.owner!).address] = self.getIDs()
			}
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
		fun borrowArleeScene(id: UInt64): &ArleeScene.NFT?{ 
			if self.ownedNFTs[id] == nil{ 
				return nil
			}
			let nftRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ref = nftRef as! &ArleeScene.NFT?
			return ref
		}
		
		//MetadataViews Implementation
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nftRef = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let ArleeSceneRef = nftRef as! &ArleeScene.NFT
			return ArleeSceneRef as &{ViewResolver.Resolver}
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
	fun getArleeSceneIDs(addr: Address): [UInt64]?{ 
		let holderCap = getAccount(addr).capabilities.get<&ArleeScene.Collection>(ArleeScene.CollectionPublicPath)
		if holderCap.borrow() == nil{ 
			return nil
		}
		let holderRef = holderCap.borrow() ?? panic("Cannot borrow Arlee Scene Collection Reference")
		return holderRef.getIDs()
	}
	
	access(all)
	fun getRoyalty(): [Royalty]{ 
		return [Royalty(creditor: "Arlequin", wallet: ArleeScene.arlequinWallet, cut: ArleeScene.marketplaceCut)]
	}
	
	access(all)
	fun getArleeSceneCID(id: UInt64): String?{ 
		return ArleeScene.mintedScenes[id]
	}
	
	access(all)
	fun getAllArleeSceneCID():{ UInt64: String}{ 
		return ArleeScene.mintedScenes
	}
	
	access(all)
	fun getFreeMintAcct():{ Address: UInt64}{ 
		return ArleeScene.freeMintAcct
	}
	
	access(all)
	fun getFreeMintQuota(addr: Address): UInt64?{ 
		return ArleeScene.freeMintAcct[addr]
	}
	
	access(all)
	fun getOwner(id: UInt64): Address?{ 
		for addr in ArleeScene.ownedScenes.keys{ 
			if (ArleeScene.ownedScenes[addr]!).contains(id){ 
				return addr
			}
		}
		return nil
	}
	
	/* Admin Function */
	access(account)
	fun setMarketplaceCut(cut: UFix64){ 
		let oldCut = ArleeScene.marketplaceCut
		ArleeScene.marketplaceCut = cut
		emit MarketplaceCutUpdate(oldCut: oldCut, newCut: cut)
	}
	
	access(account)
	fun mintSceneNFT(recipient: &ArleeScene.Collection, cid: String, metadata:{ String: String}){ 
		pre{ 
			ArleeScene.mintable:
				"Public minting is not available at the moment."
		}
		// further checks
		assert(recipient.owner != nil, message: "Cannot pass in a Collection reference with no owner")
		let ownerAddr = (recipient.owner!).address
		let royalties = ArleeScene.getRoyalty()
		let newNFT <- create ArleeScene.NFT(cid: cid, creator: ownerAddr, royalties: royalties, metadata: metadata)
		ArleeScene.mintedScenes[newNFT.id] = cid
		emit Created(id: newNFT.id, cid: cid, royalties: royalties, creator: ownerAddr)
		recipient.deposit(token: <-newNFT)
	}
	
	access(account)
	fun addFreeMintAcct(addr: Address, mint: UInt64){ 
		pre{ 
			ArleeScene.freeMintAcct[addr] == nil:
				"This address is already registered in Free Mint list, please use other functions for altering"
		}
		ArleeScene.freeMintAcct[addr] = mint
		emit FreeMintListAcctUpdated(address: addr, mint: mint)
	}
	
	access(account)
	fun batchAddFreeMintAcct(list:{ Address: UInt64}){ 
		for addr in list.keys{ 
			if ArleeScene.freeMintAcct[addr] == nil{ 
				ArleeScene.addFreeMintAcct(addr: addr, mint: list[addr]!)
			} else{ 
				ArleeScene.addFreeMintAcctQuota(addr: addr, additionalMint: list[addr]!)
			}
		}
	}
	
	access(account)
	fun removeFreeMintAcct(addr: Address){ 
		pre{ 
			ArleeScene.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota."
		}
		ArleeScene.freeMintAcct.remove(key: addr)
		emit FreeMintListAcctRemoved(address: addr)
	}
	
	access(account)
	fun setFreeMintAcctQuota(addr: Address, mint: UInt64){ 
		pre{ 
			mint > 0:
				"Minting limit cannot be smaller than 1"
			ArleeScene.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota"
		}
		ArleeScene.freeMintAcct[addr] = mint
		emit FreeMintListAcctUpdated(address: addr, mint: mint)
	}
	
	access(account)
	fun addFreeMintAcctQuota(addr: Address, additionalMint: UInt64){ 
		pre{ 
			ArleeScene.freeMintAcct[addr] != nil:
				"This address is not given Free Mint Quota"
		}
		ArleeScene.freeMintAcct[addr] = additionalMint + ArleeScene.freeMintAcct[addr]!
		emit FreeMintListAcctUpdated(address: addr, mint: ArleeScene.freeMintAcct[addr]!)
	}
	
	access(account)
	fun setMintable(mintable: Bool){ 
		ArleeScene.mintable = mintable
	}
	
	/* Contract functions for updating NFT metadata */
	access(account)
	fun updateCID(arleeSceneNFT: @{NonFungibleToken.NFT}, newCID: String): @{NonFungibleToken.NFT}{ 
		let nftRef = &arleeSceneNFT as &{NonFungibleToken.NFT}
		let ref = nftRef as! &ArleeScene.NFT
		ref.updateCID(newCID: newCID)
		return <-arleeSceneNFT
	}
	
	access(account)
	fun updateMetadata(arleeSceneNFT: @{NonFungibleToken.NFT}, key: String, value: String): @{NonFungibleToken.NFT}{ 
		let nftRef = &arleeSceneNFT as &{NonFungibleToken.NFT}
		let ref = nftRef as! &ArleeScene.NFT
		ref.updateMetadata(key: key, value: value)
		return <-arleeSceneNFT
	}
	
	init(){ 
		self.totalSupply = 0
		self.mintedScenes ={} 
		self.ownedScenes ={} 
		self.mintable = false
		self.freeMintAcct ={} 
		// Paths
		self.CollectionStoragePath = /storage/ArleeScene
		self.CollectionPublicPath = /public/ArleeScene
		// Royalty
		self.marketplaceCut = 0.05
		self.arlequinWallet = self.account.address
		// Setup Account 
		self.account.storage.save(<-ArleeScene.createEmptyCollection(nftType: Type<@ArleeScene.Collection>()), to: ArleeScene.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&ArleeScene.Collection>(ArleeScene.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: ArleeScene.CollectionPublicPath)
	}
}
