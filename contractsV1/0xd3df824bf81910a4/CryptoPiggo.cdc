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
contract CryptoPiggo: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let maxSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, initMeta:{ String: String})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// idToAddress
	// Maps each item ID to its current owner
	//
	access(self)
	let idToAddress: [Address]
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		init(initID: UInt64, initMeta:{ String: String}){ 
			self.id = initID
			self.metadata = initMeta
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Crypto Piggo NFT", description: "Crypto Piggo NFT #".concat(self.id.toString()), thumbnail: MetadataViews.HTTPFile(url: "https://s3.us-west-2.amazonaws.com/crypto-piggo.nft/piggo-".concat(self.id.toString()).concat(".png")))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					return MetadataViews.Editions([MetadataViews.Edition(name: "Crypto Piggo NFT Edition", number: self.id, max: nil)])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://s3.us-west-2.amazonaws.com/crypto-piggo.nft/piggo-".concat(self.id.toString()).concat(".png"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: CryptoPiggo.CollectionStoragePath, publicPath: CryptoPiggo.CollectionPublicPath, publicCollection: Type<&CryptoPiggo.Collection>(), publicLinkedType: Type<&CryptoPiggo.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-CryptoPiggo.createEmptyCollection(nftType: Type<@CryptoPiggo.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://ipfs.tenzingai.com/ipfs/QmUk3s7BoVSS56V2U4rxd1syVp8USUEygu7NmARppH183U"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Crypto Piggo NFT Collection", description: "", externalURL: MetadataViews.ExternalURL("https://www.rareworx.com/"), squareImage: media, bannerImage: media, socials:{} )
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
	resource interface CryptoPiggoCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowItem(id: UInt64): &CryptoPiggo.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CryptoPiggoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			emit Withdraw(id: token.id, from: (self.owner!).address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @CryptoPiggo.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// update owner
			CryptoPiggo.idToAddress[id] = (self.owner!).address
			emit Deposit(id: id, to: (self.owner!).address)
			destroy oldToken
		}
		
		// transfer takes an NFT ID and a reference to a recipient's collection
		// and transfers the NFT corresponding to that ID to the recipient
		access(all)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not transferred"
				recipient.borrowNFT(id) != nil:
					"Recipient did not receive the intended NFT"
			}
			let nft <- self.withdraw(withdrawID: id)
			recipient.deposit(token: <-nft)
		}
		
		// burn destroys an NFT
		access(all)
		fun burn(id: UInt64){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not burned"
			}
			destroy <-self.withdraw(withdrawID: id)
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
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft
			}
			panic("NFT not found in collection.")
		}
		
		// borrowItem gets a reference to an NFT in the collection as a CryptoPiggo,
		// exposing all of its fields. This is safe as there are no functions that 
		// can be called on the CryptoPiggo.
		access(all)
		fun borrowItem(id: UInt64): &CryptoPiggo.NFT?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &CryptoPiggo.NFT
			}
			panic("NFT not found in collection.")
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &CryptoPiggo.NFT
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
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// getMetadataCID
	// public function that anyone can call to get the IPFS CID of the JSON file with 
	// all the NFT metadata of this collection. The file will not contain any of the 
	// NFTs burned by the admin account.
	//
	access(all)
	fun getMetadataCID(): MetadataViews.IPFSFile{ 
		return MetadataViews.IPFSFile(cid: "QmTd2TspsYLNLsg7HrGcmHhCAJcSkQbLKGWJKPwsLGQuvq", path: nil)
	}
	
	// getMetadataURL
	// public function that anyone can call to get the IPFS URL of the JSON file with 
	// all the NFT metadata of this collection. The file will not contain any of the 
	// NFTs burned by the admin account.
	//
	access(all)
	fun getMetadataURL(): String{ 
		return "https://ipfs.tenzingai.com/ipfs/QmTd2TspsYLNLsg7HrGcmHhCAJcSkQbLKGWJKPwsLGQuvq"
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: Address, initMetadata:{ String: String}){ 
			let nftID = CryptoPiggo.totalSupply
			if nftID < CryptoPiggo.maxSupply{ 
				let receiver = getAccount(recipient).capabilities.get<&{NonFungibleToken.CollectionPublic}>(CryptoPiggo.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
				emit Minted(id: nftID, initMeta: initMetadata)
				CryptoPiggo.idToAddress.append(recipient)
				CryptoPiggo.totalSupply = nftID + 1
				receiver.deposit(token: <-create CryptoPiggo.NFT(initID: nftID, initMeta: initMetadata))
			} else{ 
				panic("No more piggos can be minted")
			}
		}
	}
	
	// getOwner
	// Gets the current owner of the given item
	//
	access(all)
	fun getOwner(itemID: UInt64): Address?{ 
		if itemID >= 0 && itemID < self.maxSupply{ 
			if itemID < CryptoPiggo.totalSupply{ 
				return CryptoPiggo.idToAddress[itemID]
			} else{ 
				return nil
			}
		}
		return nil
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/CryptoPiggoCollection
		self.CollectionPublicPath = /public/CryptoPiggoCollection
		self.MinterStoragePath = /storage/CryptoPiggoMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the max supply
		self.maxSupply = 10000
		
		// Initalize mapping from ID to address
		self.idToAddress = []
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
