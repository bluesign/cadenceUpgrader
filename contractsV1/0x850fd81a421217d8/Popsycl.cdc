// Popsycl NFT Marketplace
// NFT smart contract
// Version		 : 0.0.1
// Blockchain	  : Flow www.onFlow.org
// Owner		   : Popsycl.com
// Developer	   : RubiconFinTech.com
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import PopsyclRates from "./PopsyclRates.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Popsycl: NonFungibleToken{ 
	
	// Total number of token supply
	access(all)
	var totalSupply: UInt64
	
	// NFT No of Editions(Multiple copies) limit
	access(all)
	var editionLimit: UInt
	
	/// Path where the `Collection` is stored
	access(all)
	let PopsyclStoragePath: StoragePath
	
	/// Path where the public capability for the `Collection` is
	access(all)
	let PopsyclPublicPath: PublicPath
	
	/// NFT Minter
	access(all)
	let PopsyclMinterPath: StoragePath
	
	// Contract Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, content: String, royality: UFix64, owner: Address?, influencer: Address?)
	
	access(all)
	event GroupMint(id: UInt64, content: String, royality: UFix64, owner: Address?, influencer: Address?, tokenGroupId: UInt64)
	
	// TOKEN RESOURCE
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Unique identifier for NFT Token
		access(all)
		let id: UInt64
		
		// Meta data to store token data (use dict for data)
		access(self)
		let metaData:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metaData
		}
		
		access(all)
		let royality: UFix64
		
		// NFT token creator address
		access(all)
		let creator: Address?
		
		access(all)
		let influencer: Address?
		
		// In current store static dict in meta data
		init(id: UInt64, content: String, royality: UFix64, creator: Address?, influencer: Address, name: String, description: String, previewContent: String, mimeType: String){ 
			self.id = id
			self.metaData ={ "content": content, "title": name, "description": description, "PreviewContent": previewContent, "mimeType": mimeType}
			self.royality = royality
			self.creator = creator
			self.influencer = influencer
		}
		
		access(self)
		fun getFlowRoyaltyReceiverPublicPath(): PublicPath{ 
			return /public/flowTokenReceiver
		}
		
		access(self)
		fun genRoyalities(): [MetadataViews.Royalty]{ 
			var royalties: [MetadataViews.Royalty] = []
			
			// Creator Royalty
			royalties.append(MetadataViews.Royalty(receiver: getAccount(self.creator!).capabilities.get<&{FungibleToken.Vault}>(self.getFlowRoyaltyReceiverPublicPath()), cut: UFix64(self.royality / 100.0), description: "Creator Royalty"))
			
			// DisruptArt Market Fee
			royalties.append(MetadataViews.Royalty(receiver: getAccount(PopsyclRates.PopsyclMarketAddress).capabilities.get<&{FungibleToken.Vault}>(self.getFlowRoyaltyReceiverPublicPath()), cut: UFix64(PopsyclRates.PopsyclMarketplaceFees), description: "Popsycl Market Fee"))
			return royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metaData["title"]!, description: self.metaData["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.metaData["PreviewContent"]!))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.genRoyalities())
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Account's public collection
	access(all)
	resource interface PopsyclCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPopsycl(id: UInt64): &Popsycl.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow CaaPass reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// NFT Collection resource
	access(all)
	resource Collection: PopsyclCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Contains caller's list of NFTs
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Popsycl.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
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
		
		// exposing all of its fields.
		access(all)
		fun borrowPopsycl(id: UInt64): &Popsycl.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Popsycl.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let Popsycl = nft as! &Popsycl.NFT
			return Popsycl as &{ViewResolver.Resolver}
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
	
	// NFT MINTER
	access(all)
	resource NFTMinter{ 
		
		// Function to mint group of tokens
		access(all)
		fun GroupMint(recipient: &{PopsyclCollectionPublic}, influencerRecipient: Address, content: String, edition: UInt, tokenGroupId: UInt64, royality: UFix64, name: String, description: String, previewContent: String, mimeType: String){ 
			pre{ 
				Popsycl.editionLimit >= edition:
					"Edition count exceeds the limit"
				edition >= 2:
					"Edition count should be greater than or equal to 2"
			}
			var count = 0 as UInt
			while count < edition{ 
				let token <- create NFT(id: Popsycl.totalSupply, content: content, royality: royality, creator: recipient.owner?.address, influencer: influencerRecipient, name: name, description: description, previewContent: previewContent, mimeType: mimeType)
				emit GroupMint(id: Popsycl.totalSupply, content: content, royality: royality, owner: recipient.owner?.address, influencer: influencerRecipient, tokenGroupId: tokenGroupId)
				recipient.deposit(token: <-token)
				Popsycl.totalSupply = Popsycl.totalSupply + 1 as UInt64
				count = count + 1
			}
		}
		
		access(all)
		fun Mint(recipient: &{PopsyclCollectionPublic}, influencerRecipient: Address, content: String, royality: UFix64, name: String, description: String, previewContent: String, mimeType: String){ 
			let token <- create NFT(id: Popsycl.totalSupply, content: content, royality: royality, creator: recipient.owner?.address, influencer: influencerRecipient, name: name, description: description, previewContent: previewContent, mimeType: mimeType)
			emit Mint(id: Popsycl.totalSupply, content: content, royality: royality, owner: recipient.owner?.address, influencer: influencerRecipient)
			recipient.deposit(token: <-token)
			Popsycl.totalSupply = Popsycl.totalSupply + 1 as UInt64
		}
	}
	
	// This is used to create the empty collection. without this address cannot access our NFT token
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Popsycl.Collection()
	}
	
	// Admin can change the maximum supported group minting count limit for the platform. Currently it is 50
	access(all)
	resource Admin{ 
		access(all)
		fun changeLimit(limit: UInt){ 
			Popsycl.editionLimit = limit
		}
	}
	
	// Contract init
	init(){ 
		
		// total supply is zero at the time of contract deployment
		self.totalSupply = 0
		self.editionLimit = 1000
		self.PopsyclStoragePath = /storage/PopsyclNFTCollection
		self.PopsyclPublicPath = /public/PopsyclNFTPublicCollection
		self.PopsyclMinterPath = /storage/PopsyclNFTMinter
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.PopsyclStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{PopsyclCollectionPublic}>(self.PopsyclStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PopsyclPublicPath)
		self.account.storage.save(<-create self.Admin(), to: /storage/PopsyclAdmin)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.PopsyclMinterPath)
		emit ContractInitialized()
	}
}
