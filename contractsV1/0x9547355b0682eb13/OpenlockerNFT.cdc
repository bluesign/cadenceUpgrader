import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract OpenlockerNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// addresses that should be used to store account's collection 
	// and for interactions with it within transactions
	// WARNING: only resources of type OpenlockerNFT.Collection 
	//		  should be stored by this paths.
	//		  Storing resources of other types can lead to undefined behavior
	access(all)
	var ONFTCollectionStoragePath: StoragePath
	
	access(all)
	var ONFTCollectionPublicPath: PublicPath
	
	access(all)
	var FullONFTCollectionPublicPath: PublicPath
	
	// addresses that should be used use to store tokenD account's address. 
	// Only one tokenD address can be stored at a time. 
	// Address stored by this path is allowed to be overriden but 
	// be careful that after you override it new address will 
	// be used to all TokenD interactions 
	access(all)
	var TokenDAccountAddressProviderStoragePath: StoragePath
	
	access(all)
	var TokenDAccountAddressProviderPublicPath: PublicPath
	
	access(all)
	var AccountPreparedProviderStoragePath: StoragePath
	
	access(all)
	var AccountPreparedProviderPublicPath: PublicPath
	
	access(all)
	var IsStorageUpdatedToV1ProviderStoragePath: StoragePath
	
	access(all)
	var IsStorageUpdatedToV1ProviderPublicPath: PublicPath
	
	access(all)
	var MinterStoragePath: StoragePath
	
	// pub var adminPublicCollection: &AnyResource{NonFungibleToken.CollectionPublic}
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Including `id` and addresses here to avoid complex event parsing logic
	access(all)
	event TransferredToServiceAccount(id: UInt64, from: Address, extSystemAddrToMint: String)
	
	access(all)
	event MintedFromWithdraw(id: UInt64, withdrawRequestID: UInt64, to: Address?)
	
	access(all)
	event MintedFromIssuance(id: UInt64, issuanceRequestID: UInt64, to: Address?)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	struct IssuanceMintMsg{ 
		access(all)
		let issuanceRequestID: UInt64
		
		access(all)
		let detailsURL: String
		
		init(id: UInt64, detailsURL: String){ 
			self.issuanceRequestID = id
			self.detailsURL = detailsURL
		}
	}
	
	access(all)
	struct TokenDAddressProvider{ 
		access(all)
		let tokenDAddress: String
		
		access(all)
		init(tokenDAddress: String){ 
			self.tokenDAddress = tokenDAddress
		}
	}
	
	access(all)
	struct AccountPreparedProvider{ // TODO move to separate proxy contract 
		
		access(all)
		var isPrepared: Bool
		
		access(all)
		init(isPrepared: Bool){ 
			self.isPrepared = isPrepared
		}
		
		access(all)
		fun setPrepared(isPrepared: Bool){ 
			self.isPrepared = isPrepared
		}
	}
	
	access(all)
	struct IsStorageUpdatedToV1Provider{ // TODO move to separate proxy contract 
		
		access(all)
		var isUpdated: Bool
		
		access(all)
		init(isUpdated: Bool){ 
			self.isUpdated = isUpdated
		}
		
		access(all)
		fun setUpdated(isUpdated: Bool){ 
			self.isUpdated = isUpdated
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let detailsURL: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(id: UInt64, detailsURL: String){ 
			self.id = id
			self.detailsURL = detailsURL
		}
	}
	
	access(all)
	resource interface ONFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowONFT(id: UInt64): &OpenlockerNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ONFTCollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var tokenDDepositerCap: Capability<&{NonFungibleToken.CollectionPublic}>
		
		init(tokenDDepositerCap: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			self.tokenDDepositerCap = tokenDDepositerCap
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("no token found with provided withdrawID")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @OpenlockerNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun depositToTokenD(id: UInt64){ 
			if !self.tokenDDepositerCap.check(){ 
				panic("TokenD depositer cap not found. You either trying to deposit from admin account or something wrong with collection initialization")
			}
			let token <- self.withdraw(withdrawID: id)
			(self.tokenDDepositerCap.borrow()!).deposit(token: <-token)
			let addrToIssueProvider = (self.owner!).capabilities.get<&TokenDAddressProvider>(OpenlockerNFT.TokenDAccountAddressProviderPublicPath).borrow()!
			emit TransferredToServiceAccount(id: id, from: (self.owner!).address, extSystemAddrToMint: addrToIssueProvider.tokenDAddress)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowONFT(id: UInt64): &OpenlockerNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &OpenlockerNFT.NFT
			}
			return nil
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
	resource NFTMinter{ 
		access(self)
		var ONFTCollectionPublicPath: PublicPath
		
		init(collectionPublicPath: PublicPath){ 
			self.ONFTCollectionPublicPath = collectionPublicPath
		}
		
		access(all)
		fun mintNFTByIssuance(requests: [IssuanceMintMsg]){ 
			let minterOwner = self.owner ?? panic("could not get minter owner")
			let minterOwnerCollection = minterOwner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.ONFTCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get reference to the service account's NFT Collection")
			var creationID = OpenlockerNFT.totalSupply + 1 as UInt64
			OpenlockerNFT.totalSupply = OpenlockerNFT.totalSupply + UInt64(requests.length)
			for req in requests{ 
				let token <- create NFT(id: creationID, detailsURL: req.detailsURL)
				let id = token.id
				
				// deposit it in the recipient's account using their reference
				minterOwnerCollection.deposit(token: <-token)
				emit MintedFromIssuance(id: id, issuanceRequestID: req.issuanceRequestID, to: self.owner?.address)
				creationID = creationID + 1 as UInt64
			}
		}
		
		// TODO redesign it it operate with tokens stored in a vault of the account which is owner of the Minter resource
		access(all)
		fun mintNFT(withdrawRequestID: UInt64, detailsURL: String, receiver: Address){ 
			// Borrow the recipient's public NFT collection reference
			let recipientAccount = getAccount(receiver)
			let recipientCollection = recipientAccount.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.ONFTCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			
			// create token with provided name and data
			let token <- create NFT(id: OpenlockerNFT.totalSupply + 1 as UInt64, detailsURL: detailsURL)
			let id = token.id
			
			// deposit it in the recipient's account using their reference
			recipientCollection.deposit(token: <-token)
			OpenlockerNFT.totalSupply = OpenlockerNFT.totalSupply + 1 as UInt64
			emit MintedFromWithdraw(id: id, withdrawRequestID: withdrawRequestID, to: receiver)
		}
	}
	
	access(all)
	resource NFTBurner{ 
		access(all)
		fun burnNFT(token: @{NonFungibleToken.NFT}){ 
			let id = token.id
			destroy token
			emit Burned(id: id)
		}
	}
	
	access(all)
	fun createAccountPreparedProvider(isPrepared: Bool): AccountPreparedProvider{ 
		return AccountPreparedProvider(isPrepared: isPrepared)
	}
	
	access(all)
	fun createIsStorageUpdatedToV1Provider(isUpdated: Bool): IsStorageUpdatedToV1Provider{ 
		return IsStorageUpdatedToV1Provider(isUpdated: isUpdated)
	}
	
	access(all)
	fun createTokenDAddressProvider(tokenDAddress: String): TokenDAddressProvider{ 
		return TokenDAddressProvider(tokenDAddress: tokenDAddress)
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection(tokenDDepositerCap: self.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.ONFTCollectionPublicPath)!)
	}
	
	// public function that anyone can call to create a burner to burn their oun tokens
	access(all)
	fun createBurner(): @NFTBurner{ 
		return <-create NFTBurner()
	}
	
	init(){ 
		self.totalSupply = 0
		self.ONFTCollectionStoragePath = /storage/openlockerNFTCollection
		self.ONFTCollectionPublicPath = /public/openlockerNFTCollection
		self.FullONFTCollectionPublicPath = /public/openlockerONFTCollection
		self.MinterStoragePath = /storage/openlockerNFTMinter
		self.TokenDAccountAddressProviderStoragePath = /storage/openlockerTokenDAccountAddr
		self.TokenDAccountAddressProviderPublicPath = /public/openlockerTokenDAccountAddr
		self.AccountPreparedProviderStoragePath = /storage/openlockerAccountPrepared
		self.AccountPreparedProviderPublicPath = /public/openlockerAccountPrepared
		self.IsStorageUpdatedToV1ProviderStoragePath = /storage/openlockerIsStorageUpdatedToV1
		self.IsStorageUpdatedToV1ProviderPublicPath = /public/openlockerIsStorageUpdatedToV1
		
		// not linking it to public path to avoid unauthorized access attempts
		// TODO make minter internal and use in only within contract
		let existingMinter = self.account.storage.borrow<&NFTMinter>(from: self.MinterStoragePath)
		if existingMinter == nil{ 
			// in case when contract is being deployed after removal minter does already exist and no need to save it once more
			self.account.storage.save(<-create NFTMinter(collectionPublicPath: self.ONFTCollectionPublicPath), to: self.MinterStoragePath)
		}
		let adminCollectionExists = self.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.ONFTCollectionPublicPath).check()
		if !adminCollectionExists{ 
			self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.ONFTCollectionStoragePath)
		}
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(self.ONFTCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ONFTCollectionPublicPath)
		let accountPrepared = self.account.storage.copy<&AccountPreparedProvider>(from: self.AccountPreparedProviderStoragePath)
		if accountPrepared != nil && !(accountPrepared!).isPrepared{ 
			self.account.storage.save(AccountPreparedProvider(isPrepared: true), to: self.AccountPreparedProviderStoragePath)
			var capability_2 = self.account.capabilities.storage.issue<&AccountPreparedProvider>(self.AccountPreparedProviderStoragePath)
			self.account.capabilities.publish(capability_2, at: self.AccountPreparedProviderPublicPath)
		}
		let isStorageUpdatedToV1 = self.account.storage.copy<&IsStorageUpdatedToV1Provider>(from: self.IsStorageUpdatedToV1ProviderStoragePath)
		if isStorageUpdatedToV1 != nil && !(isStorageUpdatedToV1!).isUpdated{ 
			self.account.storage.save(IsStorageUpdatedToV1Provider(isUpdated: true), to: self.IsStorageUpdatedToV1ProviderStoragePath)
			var capability_3 = self.account.capabilities.storage.issue<&IsStorageUpdatedToV1Provider>(self.IsStorageUpdatedToV1ProviderStoragePath)
			self.account.capabilities.publish(capability_3, at: self.IsStorageUpdatedToV1ProviderPublicPath)
		}
		emit ContractInitialized()
	}
}
