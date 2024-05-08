import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract BlockpartyNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	// addresses that should be used to store account's collection 
	// and for interactions with it within transactions
	// WARNING: only resources of type BlockpartyNFT.Collection 
	//		  should be stored by this paths.
	//		  Storing resources of other types can lead to undefined behavior
	access(all)
	var BNFTCollectionStoragePath: StoragePath
	
	access(all)
	var BNFTCollectionPublicPath: PublicPath
	
	access(all)
	var FullBNFTCollectionPublicPath: PublicPath
	
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
	// access(self) var NFTMetadataMap:  {UInt64:NFTMetadata}
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
	struct NFTMetadata{ 
		access(all)
		var values:{ String: String}
		
		init(values:{ String: String}){ 
			self.values = values
		}
		
		access(all)
		fun setMetadata(values:{ String: String}){ 
			self.values = values
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.values
		}
		
		access(all)
		fun setMetadataValue(key: String, value: String){ 
			self.values.insert(key: key, value)
		}
		
		access(all)
		fun getMetadataValue(key: String): String?{ 
			return self.values[key]
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let detailsURL: String
		
		init(id: UInt64, detailsURL: String){ 
			self.id = id
			self.detailsURL = detailsURL
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.IPFSFile>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		// Type<MetadataViews.Traits>()
		}
		
		/// Function that resolves a metadata viewmetadata.getMetadataValue("name") as Stringiew.
		/// @return A structure representing the requested view.
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadataStroge = BlockpartyNFT.account.storage.borrow<&NFTMetadataStorage>(from: /storage/NFTMetadata)!
			let metadata = metadataStroge.NFTMetadataMap[self.id] ?? BlockpartyNFT.NFTMetadata(values:{} )
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.getMetadataValue(key: "name") ?? "", description: metadata.getMetadataValue(key: "description") ?? "", thumbnail: MetadataViews.IPFSFile(cid: metadata.getMetadataValue(key: "thumbnail") ?? "", path: nil))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Blockparty NFT Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://blockparty.co")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BlockpartyNFT.BNFTCollectionStoragePath, publicPath: BlockpartyNFT.BNFTCollectionPublicPath, publicCollection: Type<&BlockpartyNFT.Collection>(), publicLinkedType: Type<&BlockpartyNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BlockpartyNFT.createEmptyCollection(nftType: Type<@BlockpartyNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmT1Vmi2aYbVvHN24M2yMTCVPK4NdmDW1XiBvmZWyW7TQd", path: nil), mediaType: "image/jpg")
					return MetadataViews.NFTCollectionDisplay(name: "The Blockparty Collection", description: "Blockparty NFT collection", externalURL: MetadataViews.ExternalURL("https://blockparty.co"), squareImage: media, bannerImage: media, socials:{} )
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface BNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowBNFT(id: UInt64): &BlockpartyNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, BNFTCollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @BlockpartyNFT.NFT
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
			let addrToIssueProvider = (self.owner!).capabilities.get<&TokenDAddressProvider>(BlockpartyNFT.TokenDAccountAddressProviderPublicPath).borrow()!
			emit TransferredToServiceAccount(id: id, from: (self.owner!).address, extSystemAddrToMint: addrToIssueProvider.tokenDAddress)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref!
		}
		
		access(all)
		fun borrowBNFT(id: UInt64): &BlockpartyNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &BlockpartyNFT.NFT?
			}
			return nil
		}
		
		/// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
		/// interface so that the caller can retrieve the views that the NFT
		/// is implementing and resolve them
		///
		/// @param id: The ID of the wanted NFT
		/// @return The resource reference conforming to the Resolver interface
		/// 
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let BlockpartyNFT = nft as! &BlockpartyNFT.NFT
			return BlockpartyNFT as &{ViewResolver.Resolver}
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
		var BNFTCollectionPublicPath: PublicPath
		
		init(collectionPublicPath: PublicPath){ 
			self.BNFTCollectionPublicPath = collectionPublicPath
		}
		
		access(all)
		fun mintNFTByIssuance(requests: [IssuanceMintMsg], metadatas: [{String: String}]){ 
			let minterOwner = self.owner ?? panic("could not get minter owner")
			let minterOwnerCollection = minterOwner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get reference to the service account's NFT Collection")
			var creationID = BlockpartyNFT.totalSupply + 1 as UInt64
			BlockpartyNFT.totalSupply = BlockpartyNFT.totalSupply + UInt64(requests.length)
			for i, req in requests{ 
				let token <- create NFT(id: creationID, detailsURL: req.detailsURL)
				let id = token.id
				
				// deposit it in the recipient's account using their reference
				minterOwnerCollection.deposit(token: <-token)
				let storage = BlockpartyNFT.account.storage.borrow<&BlockpartyNFT.NFTMetadataStorage>(from: BlockpartyNFT.NFTMetadataStoragePath()) ?? panic("Could not get NFTMetadataStorage")
				storage.setNFTMetadata(id: id, metadataMap: metadatas[i])
				emit MintedFromIssuance(id: id, issuanceRequestID: req.issuanceRequestID, to: self.owner?.address)
				creationID = creationID + 1 as UInt64
			}
		}
		
		// TODO redesign it it operate with tokens stored in a vault of the account which is owner of the Minter resource
		access(all)
		fun mintNFT(withdrawRequestID: UInt64, detailsURL: String, metadataMap:{ String: String}, receiver: Address){ 
			// Borrow the recipient's public NFT collection reference
			let recipientAccount = getAccount(receiver)
			let recipientCollection = recipientAccount.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
			
			// create token with provided name and data
			let token <- create NFT(id: BlockpartyNFT.totalSupply + 1 as UInt64, detailsURL: detailsURL)
			let id = token.id
			
			// deposit it in the recipient's account using their reference
			recipientCollection.deposit(token: <-token)
			BlockpartyNFT.totalSupply = BlockpartyNFT.totalSupply + 1 as UInt64
			let storage = BlockpartyNFT.account.storage.borrow<&BlockpartyNFT.NFTMetadataStorage>(from: BlockpartyNFT.NFTMetadataStoragePath()) ?? panic("Could not get NFTMetadataStorage")
			storage.setNFTMetadata(id: id, metadataMap: metadataMap)
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
	resource NFTMetadataStorage{ 
		access(account)
		var NFTMetadataMap:{ UInt64: NFTMetadata}
		
		access(all)
		fun setNFTMetadata(id: UInt64, metadataMap:{ String: String}){ 
			var metadata = self.NFTMetadataMap[id] ?? BlockpartyNFT.NFTMetadata(values:{} )
			metadata.setMetadata(values: metadataMap)
			self.NFTMetadataMap.insert(key: id, metadata)
		}
		
		access(all)
		fun getNFTMetadata(id: UInt64): NFTMetadata?{ 
			return self.NFTMetadataMap[id]
		}
		
		access(all)
		fun setMetadataMap(NFTMetadataMap:{ UInt64: BlockpartyNFT.NFTMetadata}){ 
			self.NFTMetadataMap = NFTMetadataMap
		}
		
		init(){ 
			self.NFTMetadataMap ={} 
		}
	}
	
	access(all)
	fun NFTMetadataStoragePath(): StoragePath{ 
		return /storage/NFTMetadata
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
		return <-create Collection(tokenDDepositerCap: self.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath)!)
	}
	
	// public function that anyone can call to create a burner to burn their oun tokens
	access(all)
	fun createBurner(): @NFTBurner{ 
		return <-create NFTBurner()
	}
	
	// public function that anyone can call to create a metadata storage
	access(all)
	fun createMetadataStorage(): @NFTMetadataStorage{ 
		return <-create NFTMetadataStorage()
	}
	
	init(){ 
		self.totalSupply = 1050
		self.BNFTCollectionStoragePath = /storage/NFTCollection
		self.BNFTCollectionPublicPath = /public/NFTCollection
		self.FullBNFTCollectionPublicPath = /public/BNFTCollection
		self.MinterStoragePath = /storage/NFTMinter
		self.TokenDAccountAddressProviderStoragePath = /storage/tokenDAccountAddr
		self.TokenDAccountAddressProviderPublicPath = /public/tokenDAccountAddr
		self.AccountPreparedProviderStoragePath = /storage/accountPrepared
		self.AccountPreparedProviderPublicPath = /public/accountPrepared
		self.IsStorageUpdatedToV1ProviderStoragePath = /storage/isStorageUpdatedToV1
		self.IsStorageUpdatedToV1ProviderPublicPath = /public/isStorageUpdatedToV1
		
		// self.NFTMetadataMap = {}
		
		// not linking it to public path to avoid unauthorized access attempts
		// TODO make minter internal and use in only within contract
		let existingMinter = self.account.storage.borrow<&NFTMinter>(from: self.MinterStoragePath)
		if existingMinter == nil{ 
			// in case when contract is being deployed after removal minter does already exist and no need to save it once more
			self.account.storage.save(<-create NFTMinter(collectionPublicPath: self.BNFTCollectionPublicPath), to: self.MinterStoragePath)
		}
		let adminCollectionExists = self.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(self.BNFTCollectionPublicPath).check()
		if !adminCollectionExists{ 
			self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.BNFTCollectionStoragePath)
		// adminCollection <-! self.createEmptyCollection() as @BlockpartyNFT.Collection?
		}
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>(self.BNFTCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.BNFTCollectionPublicPath)
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
		let existingMetadataStorage = self.account.storage.borrow<&NFTMetadataStorage>(from: self.NFTMetadataStoragePath())
		if existingMetadataStorage == nil{ 
			// in case when contract is being deployed after removal NFTMetadata does already exist and no need to save it once more
			self.account.storage.save(<-create NFTMetadataStorage(), to: self.NFTMetadataStoragePath())
		}
		emit ContractInitialized()
	}
}
