import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract ATTANFT: NonFungibleToken{ 
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	access(all)
	event UserMinted(id: UInt64, price: UFix64)
	
	access(all)
	event PauseStateChanged(flag: Bool)
	
	access(all)
	event BaseURIChanged(uri: String)
	
	access(all)
	event MintPriceChanged(price: UFix64)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// totalSupply
	// The total number of ATTANFT that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var baseURI: String
	
	access(self)
	var pause: Bool
	
	access(self)
	var mintPrice: UFix64
	
	// NFT
	// A ATTA as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		// initializer
		//
		init(initID: UInt64, metadata:{ String: String}?){ 
			self.id = initID
			self.metadata = metadata ??{} 
		}
	}
	
	// The details of ATTA in the Collection.
	access(all)
	resource interface ATTACollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowATTA(id: UInt64): &ATTANFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow ATTA reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// A collection of ATTA NFTs owned by an account
	//
	access(all)
	resource Collection: ATTACollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ATTANFT.NFT
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
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
		
		// borrowATTA
		// Gets a reference to an NFT in the collection as a ATTANFT,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the ATTANFT.
		//
		access(all)
		fun borrowATTA(id: UInt64): &ATTANFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ATTANFT.NFT
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
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// buy ATTA NFT with FLOW token
	// public function that anyone can call to buy a ATTA NFT with set price
	//
	access(all)
	fun buyATTA(paymentVault: @{FungibleToken.Vault}): @ATTANFT.NFT{ 
		pre{ 
			self.pause == false:
				"Mint pause."
			self.mintPrice > 0.0:
				"Price not set yet."
		}
		// get user payment amount
		let paymentAmount = paymentVault.balance
		// check the amount enough or not
		if self.mintPrice > paymentAmount{ 
			panic("Not enough amount to mint a ATTA NFT")
		}
		// borrpw admin resource to receieve fund
		let admin = ATTANFT.account.storage.borrow<&ATTANFT.Admin>(from: ATTANFT.AdminStoragePath) ?? panic("Could not borrow admin client")
		// keep the fund with admin resource's vault 
		admin.depositVault(paymentVault: <-paymentVault)
		emit UserMinted(id: ATTANFT.totalSupply, price: ATTANFT.mintPrice)
		// mint NFT and return
		let nft <- create ATTANFT.NFT(initID: ATTANFT.totalSupply, metadata:{} )
		ATTANFT.totalSupply = ATTANFT.totalSupply + 1 as UInt64
		return <-nft
	}
	
	// admin resource store in the contract owner's account with private path
	// this is a private resource that keep the mint and vault function for the admin
	//
	access(all)
	resource Admin{ 
		// vault receieve FLOW token 
		access(self)
		var vault: @{FungibleToken.Vault}
		
		// mint NFT without pay any FLOW for admin only
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}?){ 
			emit Minted(id: ATTANFT.totalSupply, metadata: metadata ??{} )
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create ATTANFT.NFT(initID: ATTANFT.totalSupply, metadata: metadata))
			ATTANFT.totalSupply = ATTANFT.totalSupply + 1 as UInt64
		}
		
		// deposite FLOW when user buy NFT with `buyATTA` function
		access(all)
		fun depositVault(paymentVault: @{FungibleToken.Vault}){ 
			self.vault.deposit(from: <-paymentVault)
		}
		
		// global pause status, for emergency
		access(all)
		fun setPause(_ flag: Bool){ 
			ATTANFT.pause = flag
			emit PauseStateChanged(flag: flag)
		}
		
		// baseURI field for the NFT metadata ,maintenaed off-chain
		access(all)
		fun setBaseURI(_ uri: String){ 
			ATTANFT.baseURI = uri
			emit BaseURIChanged(uri: uri)
		}
		
		// set the NFT price to sell, user can buy nft by buyATTA function when price > 0 
		access(all)
		fun setPrice(_ price: UFix64){ 
			ATTANFT.mintPrice = price
			emit MintPriceChanged(price: price)
		}
		
		// query FLOW vault balance of admin vault
		access(all)
		fun getVaultBalance(): UFix64{ 
			pre{ 
				self.vault != nil:
					"Vault not init yet..."
			}
			return self.vault.balance
		}
		
		// withdraw FLOW from admin's flow vault
		access(all)
		fun withdrawVault(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				self.vault != nil:
					"Vault not init yet..."
			}
			let vaultRef = &self.vault as &{FungibleToken.Vault}
			return <-vaultRef.withdraw(amount: amount)
		}
		
		init(vault: @{FungibleToken.Vault}){ 
			self.vault <- vault
		}
	}
	
	// query price 
	access(all)
	fun getPrice(): UFix64{ 
		return self.mintPrice
	}
	
	// query pause status
	access(all)
	fun isPause(): Bool{ 
		return self.pause
	}
	
	// query the BaseURI 
	access(all)
	fun getBaseURI(): String{ 
		return self.baseURI
	}
	
	// query admin FLOW balance with pub function
	access(all)
	fun getVaultBalance(): UFix64{ 
		let admin = ATTANFT.account.storage.borrow<&ATTANFT.Admin>(from: ATTANFT.AdminStoragePath) ?? panic("Could not borrow admin client")
		return admin.getVaultBalance()
	}
	
	// fetch
	// Get a reference to a ATTA from an account's Collection, if available.
	// If an account does not have a ATTANFT.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &ATTANFT.NFT?{ 
		let collection = (getAccount(from).capabilities.get<&ATTANFT.Collection>(ATTANFT.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
		return collection.borrowATTA(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/ATTANFTCollection
		self.CollectionPublicPath = /public/ATTANFTCollection
		self.AdminStoragePath = /storage/ATTANFTAdmin
		// Initialize the total supply
		self.totalSupply = 0
		self.baseURI = ""
		self.pause = true
		self.mintPrice = 0.0
		// Create a Minter resource and save it to storage
		let admin <- create Admin(vault: <-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()))
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
