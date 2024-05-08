import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	//pub var CollectionPrivatePath: PrivatePath
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	// We use dict to store raw metadata
	access(all)
	resource interface RawMetadata{ 
		access(all)
		fun getRawMetadata():{ String: String}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, RawMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, creator: Address, metadata:{ String: String}){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: self.metadata["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.metadata["thumbnail"]!))
			}
			return nil
		}
		
		access(all)
		fun getRawMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30(id: UInt64): &Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.NFT
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
		fun borrowHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30(id: UInt64): &Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mlNFT = nft as! &Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.NFT
			return mlNFT
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			let creator = (self.owner!).address
			// create a new NFT
			var newNFT <- create NFT(id: Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.totalSupply, creator: creator, metadata: metadata)
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.totalSupply = Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.totalSupply + 1
			emit Mint(id: tokenRef.id, creator: creator, metadata: metadata)
			return tokenRef
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MatrixMarketHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30Collection
		self.CollectionPublicPath = /public/MatrixMarketHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30Collection
		self.MinterStoragePath = /storage/MatrixMarketHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30Minter
		self.MinterPublicPath = /public/MatrixMarketHexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30Minter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Hexi_Coll_062d47cc_3800_11ed_9978_4851c5d34c30.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
