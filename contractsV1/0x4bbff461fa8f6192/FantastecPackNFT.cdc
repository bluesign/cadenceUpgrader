import Crypto

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FantastecNFT, IFantastecPackNFT from 0x4bbff461fa8f6192

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FantastecPackNFT: NonFungibleToken, IFantastecPackNFT{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionIFantastecPackNFTPublicPath: PublicPath
	
	access(all)
	let OperatorStoragePath: StoragePath
	
	access(all)
	let OperatorPrivPath: PrivatePath
	
	access(contract)
	let packs: @{UInt64: Pack}
	
	// from IFantastecPackNFT
	access(all)
	event Burned(id: UInt64)
	
	// from NonFungibleToken
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// contract specific
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	resource FantastecPackNFTOperator: IFantastecPackNFT.IOperator{ 
		access(all)
		fun mint(packId: UInt64, productId: UInt64): @NFT{ 
			let packNFT <- create NFT(packId: packId, productId: productId)
			FantastecPackNFT.totalSupply = FantastecPackNFT.totalSupply + 1
			emit Minted(id: packNFT.id)
			let pack <- create Pack()
			FantastecPackNFT.packs[packNFT.id] <-! pack
			return <-packNFT
		}
		
		access(all)
		fun open(id: UInt64, recipient: Address){ 
			let pack <- FantastecPackNFT.packs.remove(key: id) ?? panic("cannot find pack with ID ".concat(id.toString()))
			pack.open(recipient: recipient)
			FantastecPackNFT.packs[id] <-! pack
		}
		
		access(all)
		fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT){ 
			let pack <- FantastecPackNFT.packs.remove(key: id) ?? panic("cannot find pack with ID ".concat(id.toString()))
			pack.addFantastecNFT(nft: <-nft)
			FantastecPackNFT.packs[id] <-! pack
		}
		
		init(){} 
	}
	
	access(all)
	resource Pack: IFantastecPackNFT.IFantastecPack{ 
		access(all)
		var ownedNFTs: @{UInt64: FantastecNFT.NFT}
		
		access(all)
		fun open(recipient: Address){ 
			let receiver = getAccount(recipient).capabilities.get<&{NonFungibleToken.CollectionPublic}>(FantastecNFT.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection - ".concat(recipient.toString()))
			for key in self.ownedNFTs.keys{ 
				let nft <-! self.ownedNFTs.remove(key: key)
				receiver.deposit(token: <-nft!)
			}
		}
		
		access(all)
		fun addFantastecNFT(nft: @FantastecNFT.NFT){ 
			let id = nft.id
			self.ownedNFTs[id] <-! nft
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let productId: UInt64
		
		init(packId: UInt64, productId: UInt64){ 
			self.id = packId
			self.productId = productId
		}
		
		// from MetadataViews.Resolver
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		// Type<MetadataViews.ExternalURL>(),
		// Type<MetadataViews.Medias>(),
		// Type<MetadataViews.NFTCollectionData>(),
		// Type<MetadataViews.NFTCollectionDisplay>(),
		// Type<MetadataViews.Royalties>(),
		// Type<MetadataViews.Serial>(),
		// Type<MetadataViews.Traits>()
		}
		
		// from MetadataViews.Resolver
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Fantastec Pack", description: "Reveals Fantstec NFTs when opened", thumbnail: MetadataViews.HTTPFile(url: self.getThumbnailPath()))
			}
			return nil
		}
		
		access(all)
		fun getThumbnailPath(): String{ 
			return "path/to/thumbnail/".concat(self.id.toString())
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, IFantastecPackNFT.IFantastecPackNFTCollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @FantastecPackNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
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
	
	init(){ 
		self.totalSupply = 0
		self.packs <-{} 
		// Set our named paths
		self.CollectionStoragePath = /storage/FantastecPackNFTCollection
		self.CollectionPublicPath = /public/FantastecPackNFTCollection
		self.CollectionIFantastecPackNFTPublicPath = /public/FantastecPackNFTCollection
		self.OperatorStoragePath = /storage/FantastecPackNFTOperatorCollection
		self.OperatorPrivPath = /private/FantastecPackNFTOperatorCollection
		
		// Create a collection to receive Pack NFTs
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionIFantastecPackNFTPublicPath)
		
		// Create a operator to share mint capability with proxy
		let operator <- create FantastecPackNFTOperator()
		self.account.storage.save(<-operator, to: self.OperatorStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&FantastecPackNFTOperator>(self.OperatorStoragePath)
		self.account.capabilities.publish(capability_3, at: self.OperatorPrivPath)
	}
}
