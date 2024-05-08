// EverSinceNFT.cdc
//
// This is a complete version of the EverSinceNFT contract
// that includes withdraw and deposit functionality, as well as a
// collection resource that can be used to bundle NFTs together.
//
// It also includes a definition for the Minter resource,
// which can be used by admins to mint new NFTs.
//
// Learn more about non-fungible tokens in this tutorial: https://docs.onflow.org/docs/non-fungible-tokens
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// import FungibleToken from "../"./FungibleToken.cdc"/FungibleToken.cdc"
// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews.cdc"/MetadataViews.cdc"
access(all)
contract EverSinceNFT: NonFungibleToken{ 
	
	// Declare Path constants so paths do not have to be hardcoded
	// in transactions and scripts
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event CreateNewEmptyCollection()
	
	access(all)
	event BorrowEverSinceNFT(id: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event UseBonus(id: UInt64)
	
	access(all)
	var totalSupply: UInt64
	
	// Declare the NFT resource type
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		// Initialize both fields in the init function
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun useBonus(minter: AuthAccount){ 
			let m = minter.address.toString()
			assert(self.metadata["minter"] == m, message: "only minter can approve bonus")
			assert(self.metadata["bonus"] != "0", message: "cannot use NFT if bonus is zero")
			self.metadata["bonus"] = "0"
			emit UseBonus(id: self.id)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			var sku = "\"undefined\""
			if self.metadata["sku"] != nil{ 
				sku = "\""
				sku = sku.concat(self.metadata["sku"]!)
				sku = sku.concat("\"")
			}
			var description = "{\"bonus\":"
			description = description.concat(self.metadata["bonus"]!)
			description = description.concat(",\"id\":")
			description = description.concat(self.id.toString())
			description = description.concat(",\"sku\":")
			description = description.concat(sku)
			description = description.concat("}")
			switch view{ 
				case Type<MetadataViews.Display>():
					if self.metadata["bonus"] != "0"{ 
						return MetadataViews.Display(name: self.metadata["experience"]!, description: description, thumbnail: MetadataViews.HTTPFile(url: self.metadata["uri"]!))
					} else{ 
						return MetadataViews.Display(name: self.metadata["experience"]!, description: description, thumbnail: MetadataViews.HTTPFile(url: self.metadata["usedUri"]!))
					}
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface EverSinceNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? // from MetadataViews
		
		
		access(all)
		fun borrowEverSinceNFT(id: UInt64): &EverSinceNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow EverSinceNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// The definition of the Collection resource that
	// holds the NFTs that a user owns
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, EverSinceNFTCollectionPublic{ 
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
			let token <- token as! @EverSinceNFT.NFT
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let card = nft as! &EverSinceNFT.NFT
			return card as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun borrowEverSinceNFT(id: UInt64): &EverSinceNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &EverSinceNFT.NFT
			} else{ 
				return nil
			}
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
	
	// creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		emit CreateNewEmptyCollection()
		return <-create Collection()
	}
	
	// NFTMinter
	//
	// Resource that would be owned by an admin or by a smart contract 
	// that allows them to mint new NFTs when needed
	access(all)
	resource interface EverSinceNFTMinterPublic{ 
		access(all)
		fun GetExperienceIds(sku: String): [UInt64]
	}
	
	access(all)
	resource NFTMinter: EverSinceNFTMinterPublic{ 
		// mintNFT 
		//
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		// mintNFT
		// Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		// 
		access(all)
		var NFTPool:{ String: [UInt64]}
		
		init(){ 
			self.NFTPool ={} 
		}
		
		access(all)
		fun GetExperienceIds(sku: String): [UInt64]{ 
			if self.NFTPool[sku] != nil{ 
				return self.NFTPool[sku]!
			} else{ 
				return []
			}
		}
		
		access(all)
		fun removeExperienceIds(sku: String, id: UInt64){ 
			let indexOfid = (self.NFTPool[sku]!).firstIndex(of: id)
			(self.NFTPool[sku]!).remove(at: indexOfid!)
		}
		
		access(all)
		fun AddExperienceIds(sku: String, id: UInt64){ 
			(self.NFTPool[sku]!).append(id)
		}
		
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			// deposit it in the recipient's account using their reference
			metadata["minter"] = (self.owner?.address!).toString()
			recipient.deposit(token: <-create EverSinceNFT.NFT(initID: EverSinceNFT.totalSupply, metadata: metadata))
			let sku = metadata["sku"]!
			if self.NFTPool[sku] != nil{ 
				(self.NFTPool[sku]!).append(EverSinceNFT.totalSupply)
			} else{ 
				self.NFTPool[sku] = [EverSinceNFT.totalSupply]
			}
			EverSinceNFT.totalSupply = EverSinceNFT.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/nftCollection
		self.CollectionPublicPath = /public/nftCollection
		self.MinterStoragePath = /storage/nftMinter
		self.MinterPublicPath = /public/nftMinter
		self.totalSupply = 0
		// store an empty NFT Collection in account storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&EverSinceNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&EverSinceNFT.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MinterPublicPath)
		emit ContractInitialized()
	}
}
