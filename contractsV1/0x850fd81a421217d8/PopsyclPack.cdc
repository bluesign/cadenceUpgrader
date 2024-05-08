// Popsycl NFT Marketplace
// PopsyclPack smart contract
// Version		 : 0.0.1
// Blockchain	  : Flow www.onFlow.org
// Developer :  RubiconFinTech.com
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Popsycl from "./Popsycl.cdc"

access(all)
contract PopsyclPack: NonFungibleToken{ 
	
	// Total number of pack token supply
	access(all)
	var totalSupply: UInt64
	
	// Path where the pack `Collection` is stored
	access(all)
	let PopsyclPackStoragePath: StoragePath
	
	// Path where the pack public capability for the `Collection` is
	access(all)
	let PopsyclPackPublicPath: PublicPath
	
	// Pack NFT Minter
	access(all)
	let PopsyclPackMinterPath: StoragePath
	
	// pack Contract Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event PopsyclNFTDeposit(id: UInt64)
	
	access(all)
	event PopsyclNFTWithdaw(id: UInt64)
	
	access(all)
	event PackMint(packTokenId: UInt64, packId: UInt64, name: String, royalty: UFix64, owner: Address?, influencer: Address?, tokens: [UInt64])
	
	// TOKEN RESOURCE
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// pack Unique identifier for NFT Token
		access(all)
		let id: UInt64
		
		// pack name
		access(all)
		let name: String
		
		// NFTs store 
		access(self)
		let packs: @{UInt64: Popsycl.NFT}
		
		// pack royalty
		access(all)
		let royalty: UFix64
		
		// pack NFT token creator address
		access(all)
		let creator: Address?
		
		//  pack nft influencer
		access(all)
		let influencer: Address?
		
		// In current store static dict in meta data
		init(id: UInt64, name: String, royalty: UFix64, creator: Address?, influencer: Address){ 
			self.id = id
			self.name = name
			self.packs <-{} 
			self.royalty = royalty
			self.creator = creator
			self.influencer = influencer
		}
		
		// old NFTS
		access(all)
		fun addPopsycNfts(token: @Popsycl.NFT){ 
			emit PopsyclNFTDeposit(id: token.id)
			let oldToken <- self.packs[token.id] <- token
			destroy oldToken
		}
		
		access(all)
		fun packMint(sellerRef: &Popsycl.Collection, packId: UInt64, tokens: [UInt64], name: String, recipient: &{PopsyclPackCollectionPublic}, influencerRecipient: Address, royalty: UFix64){ 
			pre{ 
				tokens.length > 1:
					"please provide atleat two NFTS for pack's"
			}
			let token <- create NFT(id: PopsyclPack.totalSupply, name: name, royalty: royalty, creator: recipient.owner?.address, influencer: influencerRecipient)
			emit PackMint(packTokenId: PopsyclPack.totalSupply, packId: packId, name: name, royalty: royalty, owner: recipient.owner?.address, influencer: influencerRecipient, tokens: tokens)
			recipient.deposit(token: <-token)
			PopsyclPack.totalSupply = PopsyclPack.totalSupply + 1 as UInt64
			for id in tokens{ 
				let token <- sellerRef.withdraw(withdrawID: id) as! @Popsycl.NFT
				self.addPopsycNfts(token: <-token)
			}
		}
		
		// old NFTS
		access(all)
		fun withdraw(id: UInt64): @Popsycl.NFT{ 
			// remove and return the token
			emit PopsyclNFTWithdaw(id: id)
			let token <- self.packs.remove(key: id) ?? panic("missing NFT")
			return <-token
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Account's pack public collection
	access(all)
	resource interface PopsyclPackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	// pack NFT Collection resource
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, PopsyclPackCollectionPublic{ 
		
		// Contains caller's list of pack NFTs
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @PopsyclPack.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// function returns token keys of owner
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// function returns token data of token id
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// function to check wether the owner have token or not
		access(all)
		fun tokenExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
	
	// This is used to create the empty pack collection. without this address cannot access our NFT token
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create PopsyclPack.Collection()
	}
	
	// Contract init
	init(){ 
		// total supply is zero at the time of contract deployment
		self.totalSupply = 0
		self.PopsyclPackStoragePath = /storage/PopsyclPackNFTCollection
		self.PopsyclPackPublicPath = /public/PopsyclPackNFTPublicCollection
		self.PopsyclPackMinterPath = /storage/PopsyclPackNFTMinter
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.PopsyclPackStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{PopsyclPackCollectionPublic}>(self.PopsyclPackStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PopsyclPackPublicPath)
		self.account.storage.save(<-create NFT(id: 1, name: "pack name", royalty: 10.0, creator: 0x850fd81a421217d8, influencer: 0x5dc999f0bb011052), to: self.PopsyclPackMinterPath)
		emit ContractInitialized()
	}
}
