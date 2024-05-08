import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract TatumMultiNFT: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, type: String, to: Address)
	
	access(all)
	event MinterAdded(address: Address, type: String)
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminMinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let type: String
		
		access(all)
		let metadata: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, url: String, type: String){ 
			self.id = initID
			self.metadata = url
			self.type = type
		}
	}
	
	access(all)
	resource interface TatumMultiNftCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun getIDsByType(type: String): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowTatumNFT(id: UInt64, type: String): &TatumMultiNFT.NFT
	}
	
	access(all)
	resource Collection: TatumMultiNftCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var types:{ String: Int}
		
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.types ={} 
		}
		
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
			let token <- token as! @TatumMultiNFT.NFT
			let id: UInt64 = token.id
			let type: String = token.type
			
			// find if there is already existing token type
			var x = self.types[type] ?? self.ownedNFTs.length
			if self.types[type] == nil{ 
				// there is no token of this type, we need to store the index for the later easy access
				self.types[type] = self.ownedNFTs.length
			}
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
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		fun getIDsByType(type: String): [UInt64]{ 
			if self.types[type] != nil{ 
				let x = self.types[type] ?? panic("No such type")
				let res: [UInt64] = []
				for e in self.ownedNFTs.keys{ 
					let t = self.borrowTatumNFT(id: e, type: type)
					if t.type == type{ 
						res.append(e)
					}
				}
				return res
			} else{ 
				return []
			}
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		fun borrowTatumNFT(id: UInt64, type: String): &TatumMultiNFT.NFT{ 
			let x = self.types[type] ?? panic("No such token type.")
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &TatumMultiNFT.NFT
			if token.type != type{ 
				panic("Token doesnt have correct type.")
			}
			return token
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
	
	access(all)
	resource AdminMinter{ 
		access(self)
		var minters:{ Address: Int}
		
		init(){ 
			self.minters ={} 
		}
		
		access(all)
		fun addMinter(minterAccount: AuthAccount, type: String){ 
			if self.minters[minterAccount.address] == 1{ 
				panic("Unable to add minter, already present as a minter for another token type.")
			}
			let minter <- create NFTMinter(type: type)
			emit MinterAdded(address: minterAccount.address, type: type)
			minterAccount.save(<-minter, to: TatumMultiNFT.MinterStoragePath)
			self.minters[minterAccount.address] = 1
		}
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// This minter is allowed to mint only tokens of this type
		access(all)
		let type: String
		
		init(type: String){ 
			self.type = type
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{TatumMultiNftCollectionPublic}, type: String, url: String, address: Address){ 
			if self.type != type{ 
				panic("Unable to mint token for type, where this account is not a minter")
			}
			
			// create a new NFT
			var newNFT <- create NFT(initID: TatumMultiNFT.totalSupply, url: url, type: type)
			emit Minted(id: TatumMultiNFT.totalSupply, type: type, to: address)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			TatumMultiNFT.totalSupply = TatumMultiNFT.totalSupply + 1 as UInt64
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionStoragePath = /storage/TatumNFTCollection
		self.CollectionPublicPath = /public/TatumNFTCollection
		self.MinterStoragePath = /storage/TatumNFTMinter
		self.AdminMinterStoragePath = /storage/TatumNFTAdminMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{TatumMultiNftCollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a default admin Minter resource and save it to storage
		// Admin minter cannot mint new tokens, it can only add new minters with for new token types
		let minter <- create AdminMinter()
		self.account.storage.save(<-minter, to: self.AdminMinterStoragePath)
		emit ContractInitialized()
	}
}
