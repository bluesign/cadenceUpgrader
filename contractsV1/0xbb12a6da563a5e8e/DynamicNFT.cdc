/* 
*
*  This is an example of how to implement Dynamic NFTs on Flow.
*  A Dynamic NFT is one that can be changed after minting. In 
*  this contract, a NFT's metadata can be changed by an Administrator.
*   
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TraderflowScores from "./TraderflowScores.cdc"

access(all)
contract DynamicNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, by: Address, name: String, description: String, thumbnail: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	struct NFTMetadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var thumbnail: String
		
		access(self)
		let metadata: TraderflowScores.TradeMetadata
		
		init(name: String, description: String, thumbnail: String, metadata: TraderflowScores.TradeMetadata){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let sequence: UInt64
		
		access(all)
		var metadata: NFTMetadata
		
		access(self)
		let trades: TraderflowScores.TradeScores
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let template: NFTMetadata = self.getMetadata()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: template.name, description: template.description, thumbnail: MetadataViews.HTTPFile(url: template.thumbnail))
			}
			return nil
		}
		
		access(all)
		fun getTrades(): TraderflowScores.TradeScores{ 
			return self.trades
		}
		
		access(all)
		fun getMetadata(): NFTMetadata{ 
			return NFTMetadata(name: self.metadata.name, description: self.metadata.description, thumbnail: self.metadata.thumbnail, metadata: self.trades.metadata())
		}
		
		access(contract)
		fun borrowTradesRef(): &TraderflowScores.TradeScores{ 
			return &self.trades as &TraderflowScores.TradeScores
		}
		
		access(contract)
		fun updateArtwork(ipfs: String){ 
			self.metadata.thumbnail = ipfs
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_name: String, _description: String, _thumbnail: String){ 
			self.id = self.uuid
			self.sequence = DynamicNFT.totalSupply
			self.trades = TraderflowScores.TradeScores()
			self.metadata = NFTMetadata(name: _name, description: _description, thumbnail: _thumbnail, metadata: self.trades.metadata())
			DynamicNFT.totalSupply = DynamicNFT.totalSupply + 1
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowAuthNFT(id: UInt64): &DynamicNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DynamicNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DynamicNFT.NFT
			emit Deposit(id: token.id, to: self.owner?.address)
			self.ownedNFTs[token.id] <-! token
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
		fun borrowAuthNFT(id: UInt64): &DynamicNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DynamicNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = token as! &DynamicNFT.NFT
			return nft as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	event rebuildNFT(id: UInt64, owner: Address, metadata: TraderflowScores.TradeMetadataRebuild)
	
	access(all)
	resource Administrator{ 
		access(all)
		fun mintNFT(recipient: &Collection, name: String, description: String, thumbnail: String){ 
			let nft <- create NFT(_name: name, _description: description, _thumbnail: thumbnail)
			emit Minted(id: nft.id, by: (self.owner!).address, name: name, description: description, thumbnail: thumbnail)
			recipient.deposit(token: <-nft)
		}
		
		access(all)
		fun pushTrade(id: UInt64, currentOwner: Address, trade: TraderflowScores.Trade){ 
			let ownerCollection = getAccount(currentOwner).capabilities.get<&Collection>(DynamicNFT.CollectionPublicPath).borrow<&Collection>() ?? panic("This person does not have a DynamicNFT Collection set up properly.")
			let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
			let tradeRef = nftRef.borrowTradesRef()
			let update = tradeRef.pushTrade(_trade: trade)
			emit rebuildNFT(id: id, owner: currentOwner, metadata: update)
		}
		
		access(all)
		fun pushEquity(id: UInt64, currentOwner: Address, equity: UFix64){ 
			let ownerCollection = getAccount(currentOwner).capabilities.get<&Collection>(DynamicNFT.CollectionPublicPath).borrow<&Collection>() ?? panic("This person does not have a DynamicNFT Collection set up properly.")
			let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
			let tradeRef = nftRef.borrowTradesRef()
			let update = tradeRef.pushEquity(_equity: equity)
			emit rebuildNFT(id: id, owner: currentOwner, metadata: update)
		}
		
		access(all)
		fun updateArtwork(id: UInt64, currentOwner: Address, ipfs: String){ 
			let ownerCollection = getAccount(currentOwner).capabilities.get<&Collection>(DynamicNFT.CollectionPublicPath).borrow<&Collection>() ?? panic("This person does not have a DynamicNFT Collection set up properly.")
			let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
			nftRef.metadata.thumbnail = ipfs
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/DynamicNFTCollection
		self.CollectionPublicPath = /public/DynamicNFTCollection
		self.MinterStoragePath = /storage/DynamicNFTMinter
		self.account.storage.save(<-create Administrator(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
