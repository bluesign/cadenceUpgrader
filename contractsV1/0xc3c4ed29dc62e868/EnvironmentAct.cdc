import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// EnvironmentAct
// NFT item
//
access(all)
contract EnvironmentAct: NonFungibleToken{ 
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
	event EnvironmentActCreated(id: UInt64, metadata:{ String: String})
	
	access(all)
	event supportAct(id: UInt64, address: Address)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let ProfileStoragePath: StoragePath
	
	access(all)
	let ProfilePublicPath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of EnvironmentActs that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var totalVerified: UInt64
	
	// feedback vault
	access(account)
	let vault: @FUSD.Vault
	
	// struct for supporters
	// we can add more properties later
	access(all)
	struct UserProfile{ 
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let address: Address
		
		init(wallet: Capability<&{FungibleToken.Receiver}>, address: Address){ 
			self.address = address
			self.wallet = wallet
		}
	}
	
	// user profile
	access(all)
	resource User{ 
		access(all)
		var verified: Bool
		
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		init(wallet: Capability<&{FungibleToken.Receiver}>){ 
			self.verified = false
			self.wallet = wallet
		}
		
		access(all)
		fun getProfile(address: Address): UserProfile{ 
			return UserProfile(wallet: self.wallet, address: address)
		}
	}
	
	// NFT
	// An EnvironmentAct Item as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// Stores all the metadata about the environment action as a string mapping
		// This is not the long term way NFT metadata will be stored. It's a temporary
		// construct while we figure out a better way to do metadata.
		//
		access(all)
		let metadata:{ String: String}
		
		access(all)
		let creator: Address
		
		access(all)
		let supporters:{ Address: UserProfile}
		
		access(all)
		let createdAt: UFix64
		
		// initializer
		//
		init(initID: UInt64, metadata:{ String: String}, creator: Address){ 
			pre{ 
				metadata.length != 0:
					"EnvironmentAct metadata cannot be empty"
			}
			self.id = initID
			self.metadata = metadata
			self.supporters ={} 
			self.createdAt = getCurrentBlock().timestamp
			self.creator = creator
			emit EnvironmentActCreated(id: initID, metadata: metadata)
		}
		
		access(all)
		fun getExternalURL(): String{ 
			if self.metadata["guid"] != nil{ 
				let guid = self.metadata["guid"]!
				return "https://app.nuuks.io/actions/".concat(guid)
			}
			return ""
		}
		
		access(all)
		fun assetPath(): String{ 
			if self.metadata["ipfs"] != nil{ 
				let ipfs = self.metadata["ipfs"]!
				return "https://content.nuuks.io/ipfs/".concat(ipfs)
			}
			return ""
		}
		
		// returns a url to display an medium sized image
		access(all)
		fun mediumimage(): String{ 
			let url = self.assetPath().concat("?width=512")
			return url
		}
		
		// returns a url to display a thumbnail sized image
		access(all)
		fun thumbnail(): String{ 
			let url = self.assetPath().concat("?width=256")
			return url
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Medias>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: self.metadata["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail()))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.getExternalURL())
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: EnvironmentAct.CollectionStoragePath, publicPath: EnvironmentAct.CollectionPublicPath, publicCollection: Type<&EnvironmentAct.Collection>(), publicLinkedType: Type<&EnvironmentAct.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-EnvironmentAct.createEmptyCollection(nftType: Type<@EnvironmentAct.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://app.nuuks.io/nuuksio_dapper_login_banner_400x150.svg"), mediaType: "image/svg+xml")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://app.nuuks.io/nuuksio_dapper_square_image_600x600.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "Nuuks.io", description: "Nuuks.io is the place where you can create digital collectables from your environmental actions.", externalURL: MetadataViews.ExternalURL("https://nuuks.io"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/nuuksio-io"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/nuuks.io")})
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.mediumimage()), mediaType: "image/png")])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their EnvironmentAct Collection as
	// to allow others to deposit EnvironmentAct into their Collection. It also allows for reading
	// the details of EnvironmentActs in the Collection.
	access(all)
	resource interface EnvironmentActCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowEnvironmentAct(id: UInt64): &EnvironmentAct.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow EnvironmentAct reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}?
		
		access(all)
		fun getSupporters(id: UInt64):{ Address: UserProfile}?
	}
	
	// deposit funds into EnvAct vault
	access(all)
	fun topup(vault: @FUSD.Vault){ 
		self.vault.deposit(from: <-vault)
	}
	
	// get vault balance
	access(all)
	fun getBalance(): UFix64{ 
		return self.vault.balance
	}
	
	// Collection
	// A collection of EnvironmentAct NFTs owned by an account
	//
	access(all)
	resource Collection: EnvironmentActCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- token as! @EnvironmentAct.NFT
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
		
		// borrowEnvironmentAct
		// Gets a reference to an NFT in the collection as an EnvironmentAct,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the EnvironmentAct.
		//
		access(all)
		fun borrowEnvironmentAct(id: UInt64): &EnvironmentAct.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &EnvironmentAct.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let environmentAct = nft as! &EnvironmentAct.NFT
			return environmentAct as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun getMetadata(id: UInt64):{ String: String}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let nft = ref as! &EnvironmentAct.NFT
				return nft.metadata
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun getSupporters(id: UInt64):{ Address: UserProfile}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				let nft = ref as! &EnvironmentAct.NFT
				return nft.supporters
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
	
	access(all)
	resource interface EnvironmentActVaultPublic{ 
		access(all)
		fun topup(envActVault: @Vault)
		
		access(all)
		fun getBalance(): UFix64
		
		access(all)
		fun topupFUSD(vault: @FUSD.Vault)
		
		access(all)
		fun withdraw(amount: UFix64): @Vault
		
		access(account)
		fun withdrawFUSD(amount: UFix64): @FUSD.Vault
		
		access(all)
		fun withdrawFunds(amount: UFix64, ref: &NFTMinter)
	}
	
	access(all)
	resource Vault: EnvironmentActVaultPublic{ 
		// vault for storing funds from purchasing the EnvAct tokens
		access(contract)
		let vault: @FUSD.Vault
		
		access(all)
		fun topup(envActVault: @Vault){ 
			let fusdVault <- envActVault.vault.withdraw(amount: envActVault.getBalance())
			self.vault.deposit(from: <-fusdVault)
			destroy envActVault
		}
		
		access(all)
		fun topupFUSD(vault: @FUSD.Vault){ 
			self.vault.deposit(from: <-vault)
		}
		
		access(all)
		fun withdraw(amount: UFix64): @Vault{ 
			let envActVault <- create Vault()
			envActVault.vault.deposit(from: <-self.vault.withdraw(amount: amount))
			return <-envActVault
		}
		
		access(account)
		fun withdrawFUSD(amount: UFix64): @FUSD.Vault{ 
			return <-(self.vault.withdraw(amount: amount) as! @FUSD.Vault)
		}
		
		access(all)
		fun withdrawFunds(amount: UFix64, ref: &NFTMinter){ 
			// assert(ref != nil, "Ref admin is bad")
			let vault <- self.vault.withdraw(amount: amount)
			EnvironmentAct.vault.deposit(from: <-vault)
		}
		
		access(all)
		fun getBalance(): UFix64{ 
			return self.vault.balance
		}
		
		// initializer
		//
		init(){ 
			self.vault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
		}
	// destructor
	}
	
	// createEmptyVault
	access(all)
	fun createEmptyVault(): @Vault{ 
		return <-create Vault()
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// create user
	access(all)
	fun createUser(wallet: Capability<&{FungibleToken.Receiver}>): @User{ 
		return <-create User(wallet: wallet)
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			emit Minted(id: EnvironmentAct.totalSupply, metadata: metadata)
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create EnvironmentAct.NFT(initID: EnvironmentAct.totalSupply, metadata: metadata, creator: (recipient.owner!).address))
			EnvironmentAct.totalSupply = EnvironmentAct.totalSupply + 1 as UInt64
		}
	}
	
	// fetch
	// Get a reference to a EnvironmentAct from an account's Collection, if available.
	// If an account does not have a EnvironmentAct.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &EnvironmentAct.NFT?{ 
		let collection = getAccount(from).capabilities.get<&EnvironmentAct.Collection>(EnvironmentAct.CollectionPublicPath).borrow<&EnvironmentAct.Collection>() ?? panic("Couldn't get collection")
		// We trust EnvironmentAct.Collection.borowEnvironmentAct to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowEnvironmentAct(id: itemID)
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/environmentActCollection
		self.CollectionPublicPath = /public/environmentActCollection
		self.ProfileStoragePath = /storage/environmentActProfile
		self.ProfilePublicPath = /public/environmentActProfile
		self.VaultStoragePath = /storage/environmentActVault
		self.VaultPublicPath = /public/environmentActVault
		self.MinterStoragePath = /storage/environmentActMinter
		// Initialize the total supply
		self.totalSupply = 0
		self.totalVerified = 0
		// initialize vault
		self.vault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
