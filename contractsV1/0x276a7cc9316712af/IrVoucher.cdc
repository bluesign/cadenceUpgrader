import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract IrVoucher: NonFungibleToken{ 
	
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	
	// Contract Events
	//
	access(all)
	event ContractInitialized()
	
	// NFT Collection Events (inherited from NonFungibleToken)
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// NFT Events
	//
	access(all)
	event NFTMinted(id: UInt64, dropID: UInt32, serial: UInt32)
	
	access(all)
	event NFTBurned(id: UInt64)
	
	//------------------------------------------------------------
	// Named Values
	//------------------------------------------------------------
	// Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	//------------------------------------------------------------
	// Public Contract State
	//------------------------------------------------------------
	// Entity Counts
	//
	access(all)
	var totalSupply: UInt64 // (inherited from NonFungibleToken)
	
	
	//------------------------------------------------------------
	// IN|RIFT NFT
	//------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let dropID: UInt32
		
		access(all)
		let serial: UInt32
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, dropID: UInt32, serial: UInt32){ 
			self.id = initID
			self.dropID = dropID
			self.serial = serial
		}
	}
	
	//------------------------------------------------------------
	// (Drop) Voucher NFT Collection
	//------------------------------------------------------------
	// A public collection interface that allows IN|RIFT Voucher NFTs to be borrowed
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		fun idExists(id: UInt64): Bool
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowVoucher(id: UInt64): &NFT?
	}
	
	// The definition of the Collection resource that
	// holds the Drops (NFTs) that a user owns
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Initialize the NFTs field to an empty collection
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw
		//
		// Function that removes an NFT from the collection
		// and moves it to the calling context
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			// If the NFT isn't found, the transaction panics and reverts
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT to withdraw")
			return <-token
		}
		
		// deposit
		//
		// Function that takes a NFT as an argument and
		// adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @IrVoucher.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			destroy oldToken
		}
		
		// idExists checks to see if a NFT
		// with the given ID exists in the collection
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowVoucher
		access(all)
		fun borrowVoucher(id: UInt64): &IrVoucher.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &IrVoucher.NFT?
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
	}
	
	// Allow everyone to create a empty IN|RIFT Voucher Collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// mintVoucher
	// allows us to create Vouchers from another contract
	// in this account. This is helpful for 
	// allowing AdminContract to mint Vouchers.
	//
	access(account)
	fun mintVoucher(dropID: UInt32, serial: UInt32): @NFT{ 
		let minter <- create NFTMinter()
		let voucher <- minter.mintNFT(dropID: dropID, serial: serial)
		destroy minter
		return <-voucher
	}
	
	//------------------------------------------------------------
	// NFT Minter
	//------------------------------------------------------------
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		//
		// Function that mints a new NFT with a new ID
		// and returns it to the caller
		access(all)
		fun mintNFT(dropID: UInt32, serial: UInt32): @IrVoucher.NFT{ 
			
			// Create a new NFT
			var newNFT <- create IrVoucher.NFT(initID: IrVoucher.totalSupply, dropID: dropID, serial: serial)
			
			// Increase Total Supply
			IrVoucher.totalSupply = IrVoucher.totalSupply + 1
			emit NFTMinted(id: newNFT.id, dropID: newNFT.dropID, serial: newNFT.serial)
			return <-newNFT
		}
	}
	
	init(){ 
		// Set the named paths 
		self.CollectionStoragePath = /storage/irDropVoucherCollectionV1
		self.CollectionPublicPath = /public/irDropVoucherCollectionV1
		self.MinterStoragePath = /storage/irDropVoucherMinterV1
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Store an empty Voucher Collection in account storage
		// & publish a public reference to the Voucher Collection in storage
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&IrVoucher.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Store minter resources in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
