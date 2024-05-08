import BasicBeasts from "./BasicBeasts.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import HunterScore from "./HunterScore.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Pack: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// -----------------------------------------------------------------------
	// Pack Events
	// -----------------------------------------------------------------------
	access(all)
	event PackOpened(id: UInt64, packTemplateID: UInt32, beastID: UInt64, beastTemplateID: UInt32, serialNumber: UInt32, sex: String, firstOwner: Address?)
	
	access(all)
	event PackTemplateCreated(packTemplateID: UInt32, name: String)
	
	access(all)
	event PackMinted(id: UInt64, name: String)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let PackManagerStoragePath: StoragePath
	
	access(all)
	let PackManagerPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Fields
	// -----------------------------------------------------------------------
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// Pack Fields
	// -----------------------------------------------------------------------
	access(self)
	var packTemplates:{ UInt32: PackTemplate}
	
	access(self)
	var stockNumbers: [UInt64]
	
	access(self)
	var numberMintedPerPackTemplate:{ UInt32: UInt32}
	
	access(all)
	struct PackTemplate{ 
		access(all)
		let packTemplateID: UInt32
		
		access(all)
		let name: String
		
		access(all)
		let image: String
		
		access(all)
		let description: String
		
		init(packTemplateID: UInt32, name: String, image: String, description: String){ 
			pre{ 
				name != "":
					"Can't create PackTemplate: name can't be blank"
				image != "":
					"Can't create PackTemplate: image can't be blank"
				description != "":
					"Can't create PackTemplate: description can't be blank"
			}
			self.packTemplateID = packTemplateID
			self.name = name
			self.image = image
			self.description = description
		}
	}
	
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(all)
		let stockNumber: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let packTemplate: PackTemplate
		
		access(all)
		var opened: Bool
		
		access(all)
		view fun isOpened(): Bool
		
		access(all)
		view fun containsFungibleTokens(): Bool
		
		access(all)
		view fun containsBeast(): Bool
		
		access(all)
		fun getNumberOfFungibleTokenVaults(): Int
		
		access(all)
		fun getNumberOfBeasts(): Int
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let stockNumber: UInt64
		
		access(all)
		let serialNumber: UInt32
		
		access(all)
		let packTemplate: PackTemplate
		
		access(all)
		var opened: Bool
		
		access(contract)
		var fungibleTokens: @[{FungibleToken.Vault}]
		
		access(contract)
		var beast: @{UInt64: BasicBeasts.NFT}
		
		init(stockNumber: UInt64, packTemplateID: UInt32){ 
			pre{ 
				!Pack.stockNumbers.contains(stockNumber):
					"Can't mint Pack NFT: pack stock number has already been minted"
				Pack.packTemplates[packTemplateID] != nil:
					"Can't mint Pack NFT: packTemplate does not exist"
			}
			Pack.totalSupply = Pack.totalSupply + 1
			Pack.stockNumbers.append(stockNumber)
			Pack.numberMintedPerPackTemplate[packTemplateID] = Pack.numberMintedPerPackTemplate[packTemplateID]! + 1
			self.serialNumber = Pack.numberMintedPerPackTemplate[packTemplateID]!
			self.id = stockNumber
			self.stockNumber = stockNumber
			self.packTemplate = Pack.packTemplates[packTemplateID]!
			self.opened = false
			self.fungibleTokens <- []
			self.beast <-{} 
		}
		
		access(all)
		fun retrieveAllFungibleTokens(): @[{FungibleToken.Vault}]{ 
			pre{ 
				self.containsFungibleTokens():
					"Can't retrieve fungible token vaults: Pack does not contain vaults"
			}
			var tokens: @[{FungibleToken.Vault}] <- []
			self.fungibleTokens <-> tokens
			return <-tokens
		}
		
		access(contract)
		fun updateIsOpened(){ 
			if self.beast.keys.length == 0{ 
				self.opened = true
			}
		}
		
		access(contract)
		fun insertBeast(beast: @BasicBeasts.NFT){ 
			pre{ 
				self.beast.keys.length == 0:
					"Can't insert Beast into Pack: Pack already contain a Beast"
				!self.isOpened():
					"Can't insert Beast into Pack: Pack has already been opened"
			}
			let id = beast.id
			self.beast[id] <-! beast
		}
		
		access(contract)
		fun retrieveBeast(): @BasicBeasts.NFT?{ 
			if self.containsBeast(){ 
				let keys = self.beast.keys
				return <-self.beast.remove(key: keys[0])!
			}
			return nil
		}
		
		access(contract)
		fun insertFungible(vault: @{FungibleToken.Vault}){ 
			self.fungibleTokens.append(<-vault)
		}
		
		access(all)
		view fun isOpened(): Bool{ 
			return self.opened
		}
		
		access(all)
		view fun containsFungibleTokens(): Bool{ 
			return self.fungibleTokens.length > 0
		}
		
		access(all)
		view fun containsBeast(): Bool{ 
			return self.beast.keys.length > 0
		}
		
		access(all)
		fun getNumberOfFungibleTokenVaults(): Int{ 
			return self.fungibleTokens.length
		}
		
		access(all)
		fun getNumberOfBeasts(): Int{ 
			return self.beast.keys.length
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.packTemplate.name, description: self.packTemplate.description, thumbnail: MetadataViews.IPFSFile(cid: self.packTemplate.image, path: nil))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface PublicPackManager{ 
		access(all)
		let id: UInt64
	}
	
	// A Pack Manager resource allows the holder to retrieve a beast from a pack and destroy the pack NFT after it has been unpacked.
	access(all)
	resource PackManager: PublicPackManager{ 
		access(all)
		let id: UInt64
		
		init(){ 
			self.id = self.uuid
		}
		
		access(all)
		fun retrieveBeast(pack: @NFT): @BasicBeasts.Collection{ 
			pre{ 
				pack.containsBeast():
					"Can't retrieve beast: Pack does not contain a beast"
				self.owner != nil:
					"Can't retrieve beast: self.owner is nil"
			}
			let keys = pack.beast.keys
			let beastCollection <- BasicBeasts.createEmptyCollection(nftType: Type<@BasicBeasts.Collection>()) as! @BasicBeasts.Collection
			let beastRef: &BasicBeasts.NFT = (&pack.beast[keys[0]] as &BasicBeasts.NFT?)!
			let beast <- pack.retrieveBeast()!
			beast.setFirstOwner(firstOwner: (self.owner!).address)
			beastCollection.deposit(token: <-beast)
			let newBeastCollection <- HunterScore.increaseHunterScore(wallet: (self.owner!).address, beasts: <-beastCollection)
			pack.updateIsOpened()
			if pack.isOpened(){ 
				emit PackOpened(id: pack.id, packTemplateID: pack.packTemplate.packTemplateID, beastID: beastRef.id, beastTemplateID: beastRef.getBeastTemplate().beastTemplateID, serialNumber: beastRef.serialNumber, sex: beastRef.sex, firstOwner: beastRef.getFirstOwner())
			}
			destroy pack
			return <-newBeastCollection
		}
	}
	
	// -----------------------------------------------------------------------
	// Admin Resource Functions
	//
	// Admin is a special authorization resource that 
	// allows the owner to perform important NFT functions
	// -----------------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun createPackTemplate(packTemplateID: UInt32, name: String, image: String, description: String): UInt32{ 
			pre{ 
				Pack.packTemplates[packTemplateID] == nil:
					"Can't create PackTemplate: Pack Template ID already exist"
			}
			var newPackTemplate = PackTemplate(packTemplateID: packTemplateID, name: name, image: image, description: description)
			Pack.packTemplates[packTemplateID] = newPackTemplate
			Pack.numberMintedPerPackTemplate[packTemplateID] = 0
			emit PackTemplateCreated(packTemplateID: newPackTemplate.packTemplateID, name: newPackTemplate.name)
			return newPackTemplate.packTemplateID
		}
		
		access(all)
		fun mintPack(stockNumber: UInt64, packTemplateID: UInt32): @Pack.NFT{ 
			let newPack: @Pack.NFT <- Pack.mintPack(stockNumber: stockNumber, packTemplateID: packTemplateID)
			return <-newPack
		}
		
		access(all)
		fun insertBeast(pack: @Pack.NFT, beast: @BasicBeasts.NFT): @Pack.NFT{ 
			pre{ 
				pack.beast.keys.length == 0:
					"Can't insert Beast into Pack: Pack already contain a Beast"
				!pack.isOpened():
					"Can't insert Beast into Pack: Pack has already been opened"
			}
			let id = beast.id
			pack.insertBeast(beast: <-beast)
			return <-pack
		}
		
		access(all)
		fun insertFungible(pack: @Pack.NFT, vault: @{FungibleToken.Vault}): @Pack.NFT{ 
			pack.insertFungible(vault: <-vault)
			return <-pack
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource interface PackCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPack(id: UInt64): &Pack.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Pack reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PackCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: The Pack does not exist in the Collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Pack.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
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
		fun borrowPack(id: UInt64): &Pack.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &Pack.NFT?
		}
		
		access(all)
		fun borrowEntirePack(id: UInt64): &Pack.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &Pack.NFT?
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let packNFT = nft as! &Pack.NFT
			return packNFT
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
	
	// -----------------------------------------------------------------------
	// Access(Account) Functions
	// -----------------------------------------------------------------------
	access(account)
	fun mintPack(stockNumber: UInt64, packTemplateID: UInt32): @Pack.NFT{ 
		let newPack: @Pack.NFT <- create NFT(stockNumber: stockNumber, packTemplateID: packTemplateID)
		emit PackMinted(id: newPack.id, name: newPack.packTemplate.name)
		return <-newPack
	}
	
	// -----------------------------------------------------------------------
	// Public Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createNewPackManager(): @PackManager{ 
		return <-create PackManager()
	}
	
	access(all)
	fun getAllPackTemplates():{ UInt32: PackTemplate}{ 
		return self.packTemplates
	}
	
	access(all)
	fun getPackTemplate(packTemplateID: UInt32): PackTemplate?{ 
		return self.packTemplates[packTemplateID]
	}
	
	access(all)
	fun getAllstockNumbers(): [UInt64]{ 
		return self.stockNumbers
	}
	
	access(all)
	fun isMinted(stockNumber: UInt64): Bool{ 
		return self.stockNumbers.contains(stockNumber)
	}
	
	access(all)
	fun getAllNumberMintedPerPackTemplate():{ UInt32: UInt32}{ 
		return self.numberMintedPerPackTemplate
	}
	
	access(all)
	fun getNumberMintedPerPackTemplate(packTemplateID: UInt32): UInt32?{ 
		return self.numberMintedPerPackTemplate[packTemplateID]
	}
	
	// -----------------------------------------------------------------------
	// NonFungibleToken Standard Functions
	// -----------------------------------------------------------------------
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create self.Collection()
	}
	
	init(){ 
		// Set named paths
		self.PackManagerStoragePath = /storage/BasicBeastsPackManager
		self.PackManagerPublicPath = /public/BasicBeastsPackManager
		self.CollectionStoragePath = /storage/BasicBeastsPackCollection
		self.CollectionPublicPath = /public/BasicBeastsPackCollection
		self.AdminStoragePath = /storage/BasicBeastsPackAdmin
		self.AdminPrivatePath = /private/BasicBeastsPackAdminUpgrade
		
		// Initialize the fields
		self.totalSupply = 0
		self.packTemplates ={} 
		self.stockNumbers = []
		self.numberMintedPerPackTemplate ={} 
		
		// Put Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&BasicBeasts.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
// Thank you swt and raven for reviewing this pack contract with me. Jacob sucks...

