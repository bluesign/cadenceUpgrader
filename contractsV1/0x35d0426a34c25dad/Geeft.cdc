import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Geeft: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// Paths
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	// Standard Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Geeft Events
	access(all)
	event GeeftCreated(id: UInt64, message: String?, from: Address, to: Address)
	
	access(all)
	struct GeeftInfo{ 
		access(all)
		let id: UInt64
		
		access(all)
		let message: String?
		
		access(all)
		let nfts:{ String: Int}
		
		access(all)
		let tokens: [String]
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(id: UInt64, message: String?, nfts:{ String: Int}, tokens: [String], extra:{ String: AnyStruct}){ 
			self.id = id
			self.message = message
			self.nfts = nfts
			self.tokens = tokens
			self.extra = extra
		}
	}
	
	// This represents a Geeft
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let from: Address
		
		access(all)
		let message: String?
		
		// Maps NFT collection type (ex. String<@FLOAT.Collection>()) -> array of NFTs
		access(all)
		var storedNFTs: @{String: [{NonFungibleToken.NFT}]}
		
		// Maps token type (ex. String<@FlowToken.Vault>()) -> vault
		access(all)
		var storedTokens: @{String:{ FungibleToken.Vault}}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		access(all)
		fun getGeeftInfo(): GeeftInfo{ 
			let nfts:{ String: Int} ={} 
			for nftString in self.storedNFTs.keys{ 
				nfts[nftString] = self.storedNFTs[nftString]?.length
			}
			let tokens: [String] = self.storedTokens.keys
			return GeeftInfo(id: self.id, message: self.message, nfts: nfts, tokens: tokens, extra: self.extra)
		}
		
		access(all)
		fun openNFTs(): @{String: [{NonFungibleToken.NFT}]}{ 
			var storedNFTs: @{String: [{NonFungibleToken.NFT}]} <-{} 
			self.storedNFTs <-> storedNFTs
			return <-storedNFTs
		}
		
		access(all)
		fun openTokens(): @{String:{ FungibleToken.Vault}}{ 
			var storedTokens: @{String:{ FungibleToken.Vault}} <-{} 
			self.storedTokens <-> storedTokens
			return <-storedTokens
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Geeft #".concat(self.id.toString()), description: self.message ?? "This is a Geeft from ".concat(self.from.toString()).concat("."), thumbnail: MetadataViews.HTTPFile(url: "https://i.imgur.com/dZxbOEa.png"))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(from: Address, message: String?, nfts: @{String: [{NonFungibleToken.NFT}]}, tokens: @{String:{ FungibleToken.Vault}}, extra:{ String: AnyStruct}){ 
			self.id = self.uuid
			self.from = from
			self.message = message
			self.storedNFTs <- nfts
			self.storedTokens <- tokens
			self.extra = extra
			Geeft.totalSupply = Geeft.totalSupply + 1
		}
	}
	
	access(all)
	fun sendGeeft(from: Address, message: String?, nfts: @{String: [{NonFungibleToken.NFT}]}, tokens: @{String:{ FungibleToken.Vault}}, extra:{ String: AnyStruct}, recipient: Address){ 
		let geeft <- create NFT(from: from, message: message, nfts: <-nfts, tokens: <-tokens, extra: extra)
		let collection = getAccount(recipient).capabilities.get<&Collection>(Geeft.CollectionPublicPath).borrow<&Collection>() ?? panic("The recipient does not have a Geeft Collection")
		emit GeeftCreated(id: geeft.id, message: message, from: from, to: recipient)
		collection.deposit(token: <-geeft)
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
		fun getGeeftInfo(geeftId: UInt64): GeeftInfo
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let geeft <- token as! @NFT
			emit Deposit(id: geeft.id, to: self.owner?.address)
			self.ownedNFTs[geeft.id] <-! geeft
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let geeft <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This Geeft does not exist in this collection.")
			emit Withdraw(id: geeft.id, from: self.owner?.address)
			return <-geeft
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
		fun borrowGeeft(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			}
			return nil
		}
		
		access(all)
		fun getGeeftInfo(geeftId: UInt64): GeeftInfo{ 
			let nft = (&self.ownedNFTs[geeftId] as &{NonFungibleToken.NFT}?)!
			let geeft = nft as! &NFT
			return geeft.getGeeftInfo()
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let geeft = nft as! &NFT
			return geeft as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/GeeftCollection
		self.CollectionPublicPath = /public/GeeftCollection
		self.totalSupply = 0
		emit ContractInitialized()
	}
}
