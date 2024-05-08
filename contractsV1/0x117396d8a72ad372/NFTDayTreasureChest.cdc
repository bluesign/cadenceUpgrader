// Wealth, Fame, Power.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract NFTDayTreasureChest: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var retired: Bool
	
	access(self)
	var whitelist: [Address]
	
	access(self)
	var minted: [Address]
	
	access(self)
	var royalties: [MetadataViews.Royalty]
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(){ 
			self.id = NFTDayTreasureChest.totalSupply
			self.name = "NFT Day Treasure Chest"
			self.description = "This treasure chest has been inspected by an adventurous hunter."
			self.thumbnail = "https://basicbeasts.mypinata.cloud/ipfs/QmUYVdSE1CLdcL8Z7FZdH7ye8tMdGnkbyVPpeQFW6tcYHy"
			self.royalties = NFTDayTreasureChest.royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "NFT Day Treasure Chest Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://basicbeasts.io/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: NFTDayTreasureChest.CollectionStoragePath, publicPath: NFTDayTreasureChest.CollectionPublicPath, publicCollection: Type<&NFTDayTreasureChest.Collection>(), publicLinkedType: Type<&NFTDayTreasureChest.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-NFTDayTreasureChest.createEmptyCollection(nftType: Type<@NFTDayTreasureChest.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://basicbeasts.mypinata.cloud/ipfs/QmZLx5Tw7Fydm923kSkqcf5PuABtcwofuv6c2APc9iR41J"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The NFT Day Treasure Chest Collection", description: "This collection is used for the Basic Beasts Treasure Hunt to celebrate international #NFTDay.", externalURL: MetadataViews.ExternalURL("https://basicbeasts.io"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/basicbeastsnft")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface NFTDayTreasureChestCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTDayTreasureChest(id: UInt64): &NFTDayTreasureChest.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFTDayTreasureChest reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NFTDayTreasureChestCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFTDayTreasureChest.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
		fun borrowNFTDayTreasureChest(id: UInt64): &NFTDayTreasureChest.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFTDayTreasureChest.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let NFTDayTreasureChest = nft as! &NFTDayTreasureChest.NFT
			return NFTDayTreasureChest as &{ViewResolver.Resolver}
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
	
	access(all)
	fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
		pre{ 
			!self.retired:
				"Cannot mint Treasure Chest: NFT Day Treasure Chest is retired"
			self.whitelist.contains((recipient.owner!).address):
				"Cannot mint Treasure Chest: Address is not whitelisted"
			!self.minted.contains((recipient.owner!).address):
				"Cannot mint Treasure Chest: Address has already minted"
		}
		
		// create a new NFT
		var newNFT <- create NFT()
		
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newNFT)
		self.minted.append((recipient.owner!).address)
		NFTDayTreasureChest.totalSupply = NFTDayTreasureChest.totalSupply + UInt64(1)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun whitelistAddress(address: Address){ 
			if !NFTDayTreasureChest.whitelist.contains(address){ 
				NFTDayTreasureChest.whitelist.append(address)
			}
		}
		
		access(all)
		fun retire(){ 
			if !NFTDayTreasureChest.retired{ 
				NFTDayTreasureChest.retired = true
			}
		}
		
		access(all)
		fun addRoyalty(beneficiaryCapability: Capability<&{FungibleToken.Receiver}>, cut: UFix64, description: String){ 
			
			// Make sure the royalty capability is valid before minting the NFT
			if !beneficiaryCapability.check(){ 
				panic("Beneficiary capability is not valid!")
			}
			NFTDayTreasureChest.royalties.append(MetadataViews.Royalty(receiver: beneficiaryCapability, cut: cut, description: description))
		}
	}
	
	access(all)
	fun getWhitelist(): [Address]{ 
		return self.whitelist
	}
	
	access(all)
	fun getMinted(): [Address]{ 
		return self.minted
	}
	
	init(){ 
		// Initialize contract fields
		self.totalSupply = 0
		self.retired = false
		self.whitelist = []
		self.minted = []
		self.royalties = [MetadataViews.Royalty(receiver: self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.05, // 5% royalty on secondary sales																																				 
																																				 description: "Basic Beasts 5% royalty from secondary sales.")]
		
		// Set the named paths
		self.CollectionStoragePath = /storage/bbNFTDayTreasureChestCollection
		self.CollectionPublicPath = /public/bbNFTDayTreasureChestCollection
		self.AdminStoragePath = /storage/bbNFTDayTreasureChestAdmin
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&NFTDayTreasureChest.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Admin resource and save it to storage
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
