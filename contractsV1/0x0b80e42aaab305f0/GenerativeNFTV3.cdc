import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract GenerativeNFTV3: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var maxSupply: UInt64
	
	access(all)
	let nftData:{ UInt64:{ String: String}}
	
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, initMeta:{ String: String})
	
	//------------------------------------------------------------
	// Storage Path
	//------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// idToAddress
	// Maps each item ID to its current owner
	access(self)
	let idToAddress:{ UInt64: Address}
	
	//------------------------------------------------------------
	// NFT Resource
	//------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		init(initID: UInt64, initMeta:{ String: String}){ 
			self.id = initID
			self.metadata = initMeta
		}
		
		access(all)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun getImage(): String{ 
			return self.getMetadata()["image"] ?? ""
		}
		
		access(all)
		fun getTitle(): String{ 
			return self.getMetadata()["title"] ?? ""
		}
		
		access(all)
		fun getDescription(): String{ 
			return self.getMetadata()["description"] ?? ""
		}
		
		// receiver: Capability<&AnyResource{FungibleToken.Receiver}>, cut: UFix64, description: String
		access(all)
		fun getRoyalties(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties([])
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getTitle(), description: self.getDescription(), thumbnail: MetadataViews.HTTPFile(url: self.getImage()))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return self.getRoyalties()
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://mikosea.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: GenerativeNFTV3.CollectionStoragePath, publicPath: GenerativeNFTV3.CollectionPublicPath, publicCollection: Type<&GenerativeNFTV3.Collection>(), publicLinkedType: Type<&GenerativeNFTV3.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-GenerativeNFTV3.createEmptyCollection(nftType: Type<@GenerativeNFTV3.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/studio-design-asset-files/projects/1pqD36e6Oj/s-300x50_aa59a692-741b-408b-aea3-bcd25d29c6bd.svg"), mediaType: "image/svg+xml")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://app.mikosea.io/mikosea_1.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "\u{3042}\u{3089}\u{3086}\u{308b}\u{4e8b}\u{696d}\u{8005}\u{306e}\u{601d}\u{3044}\u{3092}\u{8f09}\u{305b}\u{3066}\u{795e}\u{8f3f}\u{3092}\u{62c5}\u{3050}NFT\u{30af}\u{30e9}\u{30a6}\u{30c9}\u{30d5}\u{30a1}\u{30f3}\u{30c7}\u{30a3}\u{30f3}\u{30b0}\u{30de}\u{30fc}\u{30b1}\u{30c3}\u{30c8}", description: "MikoSea\u{306f}\u{30a2}\u{30fc}\u{30c6}\u{30a3}\u{30b9}\u{30c8}\u{3001}\u{4f01}\u{696d}\u{3001}\u{30a4}\u{30f3}\u{30d5}\u{30eb}\u{30a8}\u{30f3}\u{30b5}\u{30fc}\u{3068}\u{3044}\u{3063}\u{305f}\u{30af}\u{30ea}\u{30a8}\u{30a4}\u{30bf}\u{30fc}\u{3084}\u{3001}\u{3042}\u{305f}\u{3089}\u{3057}\u{304f}\u{4f55}\u{304b}\u{3092}\u{59cb}\u{3081}\u{305f}\u{3044}\u{4eba}\u{306e}\u{305f}\u{3081}\u{306e}\u{30af}\u{30e9}\u{30a6}\u{30c8}\u{3099}\u{30d5}\u{30a1}\u{30f3}\u{30c6}\u{3099}\u{30a3}\u{30f3}\u{30af}\u{3099}\u{30b5}\u{30fc}\u{30d2}\u{3099}\u{30b9}\u{3066}\u{3099}\u{3059}\u{3002}\u{30d7}\u{30ed}\u{30b8}\u{30a7}\u{30af}\u{30c8}\u{306e}\u{767a}\u{8d77}\u{4eba}\u{306f}\u{3001}NFT\u{3092}\u{8ca9}\u{58f2}\u{3059}\u{308b}\u{3053}\u{3068}\u{3067}\u{5546}\u{54c1}\u{3092}\u{8ca9}\u{58f2}\u{3059}\u{308b}\u{3068}\u{3044}\u{3046}\u{4e00}\u{65b9}\u{5411}\u{306e}\u{53d6}\u{5f15}\u{3092}\u{8d85}\u{3048}\u{3001}\u{30d7}\u{30ed}\u{30b8}\u{30a7}\u{30af}\u{30c8}\u{306e}\u{60f3}\u{3044}\u{306b}\u{5171}\u{611f}\u{3057}\u{305f}\u{201d}\u{71b1}\u{72c2}\u{7684}\u{306a}\u{30d5}\u{30a1}\u{30f3}\u{201d}\u{304b}\u{3089}\u{8cc7}\u{91d1}\u{3092}\u{8abf}\u{9054}\u{3057}\u{3001}\u{5922}\u{306e}\u{5b9f}\u{73fe}\u{3078}\u{3068}\u{8fd1}\u{3065}\u{3051}\u{307e}\u{3059}\u{3002}\u{30d7}\u{30ed}\u{30b8}\u{30a7}\u{30af}\u{30c8}\u{652f}\u{63f4}\u{8005}\u{306f}\u{3001}\u{30d7}\u{30ed}\u{30b8}\u{30a7}\u{30af}\u{30c8}\u{3092}\u{652f}\u{63f4}\u{3059}\u{308b}\u{76ee}\u{7684}\u{3067}NFT\u{3092}\u{8cfc}\u{5165}\u{3057}\u{3001}\u{5171}\u{5275}\u{ff65}\u{5354}\u{50cd}\u{306e}\u{30d7}\u{30ed}\u{30bb}\u{30b9}\u{306b}\u{53c2}\u{52a0}\u{3059}\u{308b}\u{3053}\u{3068}\u{3067}\u{3001}\u{30d7}\u{30ed}\u{30b8}\u{30a7}\u{30af}\u{30c8}\u{304b}\u{3089}\u{7279}\u{5225}\u{306a}\u{4f53}\u{9a13}\u{4fa1}\u{5024}\u{3084}\u{30e1}\u{30ea}\u{30c3}\u{30c8}\u{3092}\u{5f97}\u{308b}\u{3053}\u{3068}\u{304c}\u{3067}\u{304d}\u{307e}\u{3059}\u{3002}", externalURL: MetadataViews.ExternalURL("https://app.mikosea.io/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/MikoSea_io")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//------------------------------------------------------------
	// Collection Public Interface
	//------------------------------------------------------------
	access(all)
	resource interface GenerativeNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowItem(id: UInt64): &GenerativeNFTV3.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	//------------------------------------------------------------
	// Collection Resource
	//------------------------------------------------------------
	access(all)
	resource Collection: GenerativeNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: (self.owner!).address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @GenerativeNFTV3.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			// update owner
			if self.owner?.address != nil{ 
				GenerativeNFTV3.idToAddress[id] = (self.owner!).address
				emit Deposit(id: id, to: (self.owner!).address)
			}
			destroy oldToken
		}
		
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
		
		access(all)
		fun burn(id: UInt64){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not burned"
			}
			destroy <-self.withdraw(withdrawID: id)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			}
			panic("NFT not found in collection.")
		}
		
		access(all)
		fun borrowItem(id: UInt64): &GenerativeNFTV3.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				if ref != nil{ 
					return ref! as! &GenerativeNFTV3.NFT
				}
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mikoseaNFT = nft as! &GenerativeNFTV3.NFT
			return mikoseaNFT as &{ViewResolver.Resolver}
		}
		
		/// Safe way to borrow a reference to an NFT that does not panic
		///
		/// @param id: The ID of the NFT that want to be borrowed
		/// @return An optional reference to the desired NFT, will be nil if the passed id does not exist
		///
		access(all)
		fun borrowNFTSafe(id: UInt64): &GenerativeNFTV3.NFT?{ 
			return self.borrowItem(id: id)
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
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//------------------------------------------------------------
	// NFT Minter
	//------------------------------------------------------------
	access(all)
	resource NFTMinter{ 
		access(all)
		fun mintNFTs(initMetadata:{ String: String}): @GenerativeNFTV3.NFT{ 
			pre{ 
				GenerativeNFTV3.totalSupply < GenerativeNFTV3.maxSupply:
					"NFT Sold Out!!!"
			}
			GenerativeNFTV3.totalSupply = GenerativeNFTV3.totalSupply + 1
			let nftID = GenerativeNFTV3.totalSupply
			var newNFT <- create GenerativeNFTV3.NFT(initID: nftID, initMeta: initMetadata)
			GenerativeNFTV3.nftData[nftID] = initMetadata
			emit Minted(id: nftID, initMeta: initMetadata)
			return <-newNFT
		}
		
		access(all)
		fun mintNFT(initMetadata:{ String: String}, address: Address): @GenerativeNFTV3.NFT{ 
			let newNFT <- self.mintNFTs(initMetadata: initMetadata)
			GenerativeNFTV3.idToAddress[newNFT.id] = address
			return <-newNFT
		}
		
		access(all)
		fun addSuply(num: UInt64){ 
			GenerativeNFTV3.maxSupply = GenerativeNFTV3.maxSupply + num
		}
	}
	
	// getOwner
	// Gets the current owner of the given item
	//
	access(all)
	fun getOwner(itemID: UInt64): Address?{ 
		if itemID >= 0 && itemID < self.maxSupply{ 
			if itemID < GenerativeNFTV3.totalSupply{ 
				return GenerativeNFTV3.idToAddress[itemID]
			} else{ 
				return nil
			}
		}
		return nil
	}
	
	//------------------------------------------------------------
	// Initializer
	//------------------------------------------------------------
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/GenerativeNFTV3Collections
		self.CollectionPublicPath = /public/GenerativeNFTV3Collections
		self.MinterStoragePath = /storage/GenerativeNFTV3Minters
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize the max supply
		self.maxSupply = 10000
		
		// Initalize mapping from ID to address
		self.idToAddress ={} 
		self.nftData ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
