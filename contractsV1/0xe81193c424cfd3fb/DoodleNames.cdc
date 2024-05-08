import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FIND from "../0x097bafa4e0b48eef/FIND.cdc"

import Templates from "./Templates.cdc"

access(all)
contract DoodleNames: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	//J: What fields do we want here
	access(all)
	event Minted(id: UInt64, address: Address, name: String, context:{ String: String})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	var royalties: [Templates.Royalty]
	
	access(all)
	let registry:{ String: NamePointer}
	
	access(all)
	struct NamePointer{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let address: Address?
		
		access(all)
		let characterId: UInt64?
		
		init(id: UInt64, name: String, address: Address?, characterId: UInt64?){ 
			self.id = id
			self.name = name
			self.address = address
			self.characterId = characterId
		}
		
		access(all)
		fun equipped(): Bool{ 
			return self.characterId != nil
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		var nounce: UInt64
		
		access(all)
		let royalties: MetadataViews.Royalties
		
		access(all)
		let tag:{ String: String}
		
		access(all)
		let scalar:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(name: String){ 
			self.nounce = 0
			self.id = self.uuid
			self.name = name
			self.royalties = MetadataViews.Royalties(DoodleNames.getRoyalties())
			self.tag ={} 
			self.scalar ={} 
			self.extra ={} 
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: "Every Doodle name is unique and reserved by its owner.", thumbnail: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://doodles.app")
				case Type<MetadataViews.Royalties>():
					return self.royalties
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://doodles.app")
					let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVpAiutpnzp3zR4q2cUedMxsZd8h5HDeyxs9x3HibsnJb", path: nil), mediaType: "image/png")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://res.cloudinary.com/hxn7xk7oa/image/upload/v1675121458/doodles2_banner_ee7a035d05.jpg"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "DoodleNames", description: "Every Doodle name is unique and reserved by its owner.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "discord": MetadataViews.ExternalURL("https://discord.gg/doodles"), "twitter": MetadataViews.ExternalURL("https://twitter.com/doodles")})
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DoodleNames.CollectionStoragePath, publicPath: DoodleNames.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DoodleNames.createEmptyCollection(nftType: Type<@DoodleNames.Collection>())
						})
			}
			return nil
		}
		
		access(all)
		fun increaseNounce(){ 
			self.nounce = self.nounce + 1
		}
		
		access(account)
		fun withdrawn(){ 
			DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name, address: self.owner?.address, characterId: nil)
		}
		
		access(account)
		fun deposited(owner: Address?, characterId: UInt64?){ 
			if let o = owner{ 
				DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name, address: owner, characterId: characterId)
			}
			DoodleNames.registry[self.name] = NamePointer(id: self.id, name: self.name, address: self.owner?.address, characterId: characterId)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			let typedToken <- token as! @DoodleNames.NFT
			typedToken.withdrawn()
			emit Withdraw(id: typedToken.id, from: self.owner?.address)
			return <-typedToken
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			token.increaseNounce()
			token.deposited(owner: self.owner?.address, characterId: nil)
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let wearable = nft as! &NFT
			//return wearable as &AnyResource{MetadataViews.Resolver}
			return wearable
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
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	//TODO: this needs to be access account
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, name: String, context:{ String: String}){ 
		pre{ 
			recipient.owner != nil:
				"Recipients NFT collection is not owned"
			!self.registry.containsKey(name):
				"Name already exist. Name : ".concat(name)
			FIND.validateFindName(name):
				"This name is not valid for registering"
		}
		DoodleNames.totalSupply = DoodleNames.totalSupply + 1
		
		// create a new NFT
		var newNFT <- create NFT(name: name)
		
		//Always emit events on state changes! always contain human readable and machine readable information
		//J: discuss that fields we want in this event. Or do we prefer to use the richer deposit event, since this is really done in the backend
		emit Minted(id: newNFT.id, address: (recipient.owner!).address, name: name, context: context)
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newNFT)
	}
	
	access(account)
	fun mintName(name: String, context:{ String: String}, address: Address): @NFT{ 
		pre{ 
			!self.registry.containsKey(name):
				"Name already exist. Name : ".concat(name)
			FIND.validateFindName(name):
				"This name is not valid for registering"
		}
		DoodleNames.totalSupply = DoodleNames.totalSupply + 1
		
		// create a new NFT
		var newNFT <- create NFT(name: name)
		emit Minted(id: newNFT.id, address: address, name: name, context: context)
		return <-newNFT
	}
	
	access(all)
	fun isNameFree(_ name: String): Bool{ 
		return !self.registry.containsKey(name)
	}
	
	access(all)
	fun getRoyalties(): [MetadataViews.Royalty]{ 
		let royalties: [MetadataViews.Royalty] = []
		for r in DoodleNames.royalties{ 
			royalties.append(r.getRoyalty())
		}
		return royalties
	}
	
	access(all)
	fun setRoyalties(_ r: [Templates.Royalty]){ 
		self.royalties = r
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.royalties = []
		self.registry ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/doodleNames
		self.CollectionPublicPath = /public/doodleNames
		self.CollectionPrivatePath = /private/doodleNames
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-DoodleNames.createEmptyCollection(nftType: Type<@DoodleNames.Collection>()), to: DoodleNames.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&DoodleNames.Collection>(DoodleNames.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: DoodleNames.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&DoodleNames.Collection>(DoodleNames.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: DoodleNames.CollectionPrivatePath)
		emit ContractInitialized()
	}
}
