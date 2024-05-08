/**
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract DooverseItems: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Transfer(id: UInt64, mintedCardID: String?, from: Address?, to: Address?)
	
	access(all)
	event Minted(id: UInt64, initMeta:{ String: String})
	
	access(all)
	event Burned(id: UInt64, address: Address?)
	
	// Deprecated:
	access(all)
	event TrxMeta(trxMeta:{ String: String})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		init(initID: UInt64, initMeta:{ String: String}){ 
			self.id = initID
			self.metadata = initMeta
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Dooverse NFT", description: "Dooverse NFT #".concat(self.id.toString()), thumbnail: MetadataViews.HTTPFile(url: "https://ipfs.tenzingai.com/ipfs/QmbGZ97JuwLdqeew4HMG8HhQ5Vt5DMRU7pfe2SbTxMvm5S"))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					return MetadataViews.Editions([MetadataViews.Edition(name: "Dooverse NFT Edition", number: self.id, max: nil)])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://dooverse.io/store")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DooverseItems.CollectionStoragePath, publicPath: DooverseItems.CollectionPublicPath, publicCollection: Type<&DooverseItems.Collection>(), publicLinkedType: Type<&DooverseItems.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DooverseItems.createEmptyCollection(nftType: Type<@DooverseItems.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.tenzingai.com/ipfs/QmbGZ97JuwLdqeew4HMG8HhQ5Vt5DMRU7pfe2SbTxMvm5S"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Dooverse NFT Collection", description: "", externalURL: MetadataViews.ExternalURL("https://dooverse.io/store"), squareImage: media, bannerImage: media, socials:{} )
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface DooverseItemsCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowDooverseItem(id: UInt64): &DooverseItems.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DooverseItem reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: DooverseItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			panic("Cannot withdraw Dooverse NFTs")
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			panic("Cannot desposit Dooverse NFTs")
		}
		
		access(all)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			panic("Cannot transfer Dooverse NFTs")
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft
			}
			panic("NFT not found in collection.")
		}
		
		access(all)
		view fun borrowDooverseItem(id: UInt64): &DooverseItems.NFT?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &DooverseItems.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = self.borrowDooverseItem(id: id){ 
				return nft
			}
			panic("NFT not found in collection.")
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
	resource NFTMinter{ 
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, initMetadata:{ String: String}){ 
			panic("Cannot mint new Dooverse NFTs")
		}
	}
	
	// fetch
	// Get a reference to a DooverseItem from an account's Collection, if available.
	// If an account does not have a DooverseItems.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &DooverseItems.NFT?{ 
		let collection = getAccount(from).capabilities.get<&DooverseItems.Collection>(DooverseItems.CollectionPublicPath).borrow<&DooverseItems.Collection>() ?? panic("Couldn't get collection")
		
		// We trust DooverseItems.Collection.borowDooverseItem to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowDooverseItem(id: itemID)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DooverseItemsCollection
		self.CollectionPublicPath = /public/DooverseItemsCollection
		self.MinterStoragePath = /storage/DooverseItemsMinter
		self.totalSupply = 0
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
