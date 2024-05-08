import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract UFCStrikeInfinity: NonFungibleToken, ViewResolver{ 
	access(all)
	var baseUri: String
	
	// Signer
	access(all)
	var signer: Address
	
	// Collection
	access(all)
	let collectionName: String
	
	access(all)
	let collectionDescription: String
	
	// External link to a URL to view more information about this collection.
	access(all)
	let collectionExternalURL: MetadataViews.ExternalURL
	
	// Square-sized image to represent this collection.
	access(all)
	let collectionSquareImage: MetadataViews.Media
	
	// Banner-sized image for this collection, recommended to have a size near 1200x630.
	access(all)
	let collectionBannerImage: MetadataViews.Media
	
	// Social links to reach this collection's social homepages.
	// Possible keys may be "instagram", "twitter", "discord", etc.
	access(all)
	let collectionSocials:{ String: MetadataViews.ExternalURL}
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, address: Address)
	
	access(all)
	event Claim(campaign_id: UInt256, verify_id: UInt256, minter: Address, owner: Address, nft_id: UInt64)
	
	access(all)
	event Transfer(id: UInt64, from: Address, to: Address)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let OwnerStoragePath: StoragePath
	
	/// Maps each token ID to its owner address
	access(self)
	let owners: [Address]
	
	/// Maps each verify ID to its minted status
	access(self)
	let minted:{ UInt256: Bool}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// The unique ID of each NFT
		access(all)
		let id: UInt64
		
		/// Metadata fields
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, metadata:{ String: String}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.metadata = metadata
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: self.name.concat(" NFT Edition"), number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(UFCStrikeInfinity.baseUri.concat(self.id.toString()).concat(".json"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: UFCStrikeInfinity.CollectionStoragePath, publicPath: UFCStrikeInfinity.CollectionPublicPath, publicCollection: Type<&UFCStrikeInfinity.Collection>(), publicLinkedType: Type<&UFCStrikeInfinity.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-UFCStrikeInfinity.createEmptyCollection(nftType: Type<@UFCStrikeInfinity.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: UFCStrikeInfinity.collectionName, description: UFCStrikeInfinity.collectionDescription, externalURL: UFCStrikeInfinity.collectionExternalURL, squareImage: UFCStrikeInfinity.collectionSquareImage, bannerImage: UFCStrikeInfinity.collectionBannerImage, socials: UFCStrikeInfinity.collectionSocials)
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface UFCStrikeInfinityCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowUFCStrikeInfinity(id: UInt64): &UFCStrikeInfinity.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow UFCStrikeInfinity reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: UFCStrikeInfinityCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Removes an NFT from the collection and moves it to the caller
		///
		/// @param withdrawID: The ID of the NFT that wants to be withdrawn
		/// @return The NFT resource that has been taken out of the collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Adds an NFT to the collections dictionary and adds the ID to the id array
		///
		/// @param token: The NFT resource to be included in the collection
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @UFCStrikeInfinity.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			UFCStrikeInfinity.owners[id] = (self.owner!).address
			emit Deposit(id: id, to: (self.owner!).address)
			destroy oldToken
		}
		
		// transfer takes an NFT ID and a reference to a recipient's collection
		// and transfers the NFT corresponding to that ID to the recipient
		access(all)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not transferred"
				recipient.borrowNFT(id) != nil:
					"Recipient did not receive the intended NFT"
			}
			let nft: @{NonFungibleToken.NFT} <- self.withdraw(withdrawID: id)
			emit Transfer(id: id, from: (recipient.owner!).address, to: (self.owner!).address)
			recipient.deposit(token: <-nft)
		}
		
		// burn destroys an NFT
		access(all)
		fun burn(id: UInt64){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not burned"
			}
			destroy <-self.withdraw(withdrawID: id)
		}
		
		/// Helper method for getting the collection IDs
		///
		/// @return An array containing the IDs of the NFTs in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Gets a reference to an NFT in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///
		access(all)
		fun borrowUFCStrikeInfinity(id: UInt64): &UFCStrikeInfinity.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &UFCStrikeInfinity.NFT
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
			let ufcNft = nft as! &UFCStrikeInfinity.NFT
			return ufcNft
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
	
	/// Allows anyone to create a new empty collection
	///
	/// @return The new Collection resource
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Allows anyone to claim an NFT with a valid claim signature from Galxe
	///
	access(all)
	fun claim(chain_id: String, campaign_id: UInt256, verify_id: UInt256, cap: UInt256, recipient: Address, signature: String, name: String, description: String, thumbnail: String, metadata:{ String: String}){ 
		// check if verify_id is already minted
		if UFCStrikeInfinity.minted[verify_id] != nil{ 
			panic("NFT already minted")
		}
		
		// turn metadata into a string to verify signature
		var metadataStr = "{"
		metadata.forEachKey(fun (key: String): Bool{ 
				metadataStr = metadataStr.concat(key).concat(":").concat(metadata[key]!).concat(",")
				return true
			})
		// Removing the trailing comma and space
		if metadataStr.length > 1{ 
			metadataStr = metadataStr.slice(from: 0, upTo: metadataStr.length - 1)
		}
		metadataStr = metadataStr.concat("}")
		
		// get current contract address
		let acct = self.account.address.toString()
		let contractAddr = "A.".concat(acct.slice(from: 2, upTo: acct.length)).concat(".UFCStrikeInfinity")
		let message = "NFT(chain_id:String,contract:String,campaign_id:u64,verify_id:u64,cap:u64,owner:u64,name:String,description:String,thumbnail:String:metadata:{String: String})".concat(chain_id).concat(contractAddr).concat(campaign_id.toString()).concat(verify_id.toString()).concat(cap.toString()).concat(recipient.toString()).concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(name.utf8))).concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(description.utf8))).concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(thumbnail.utf8))).concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(metadataStr.utf8)))
		log(message)
		if !self.verifyClaimSignature(address: self.signer, signature: signature, signedData: message.utf8){ 
			panic("Invalid signature")
		}
		
		// Increment the totalSupply for a new ID
		let id = UFCStrikeInfinity.totalSupply
		
		// Create the new NFT
		var newNFT <- create NFT(id: id, name: name, description: description, thumbnail: thumbnail, metadata: metadata)
		UFCStrikeInfinity.minted[verify_id] = true
		emit Minted(id: id, address: recipient)
		
		// Get the collection of the current account using a borrowed reference
		let receiver = getAccount(recipient).capabilities.get<&{NonFungibleToken.CollectionPublic}>(UFCStrikeInfinity.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("Could not get receiver reference to the NFT Collection")
		
		// Update the owners mapping
		UFCStrikeInfinity.owners.append(recipient)
		
		// Deposit the new NFT into the current account's collection
		receiver.deposit(token: <-newNFT)
		
		// Increment the total supply
		UFCStrikeInfinity.totalSupply = UFCStrikeInfinity.totalSupply + 1
		let minter = self.account.address
		emit Claim(campaign_id: campaign_id, verify_id: verify_id, minter: minter, owner: recipient, nft_id: id)
	}
	
	access(self)
	fun verifyClaimSignature(address: Address, signature: String, signedData: [UInt8]): Bool{ 
		let signatureBytes = signature.decodeHex()
		let account = getAccount(self.signer)
		let keys = account.keys
		var i = 0
		while true{ 
			if let key = keys.get(keyIndex: i){ 
				if key.isRevoked{ 
					// do not check revoked keys
					i = i + 1
					continue
				}
				let pk = PublicKey(publicKey: key.publicKey.publicKey, signatureAlgorithm: key.publicKey.signatureAlgorithm)
				if pk.verify(signature: signatureBytes, signedData: signedData, domainSeparationTag: "", hashAlgorithm: HashAlgorithm.SHA3_256){ 
					return true
				}
			} else{ 
				return false
			}
			i = i + 1
		}
		return false
	}
	
	/// Resource that an admin or something similar would own to have admin operations access
	///
	access(all)
	resource Owner{ 
		access(all)
		fun updateSigner(newSigner: Address){ 
			UFCStrikeInfinity.signer = newSigner
		}
		
		access(all)
		fun updateBaseUri(newBaseUri: String){ 
			UFCStrikeInfinity.baseUri = newBaseUri
		}
	}
	
	// Gets the owner of the given token ID
	access(all)
	fun ownerOf(tokenId: UInt64): Address?{ 
		if tokenId >= 0{ 
			return UFCStrikeInfinity.owners[tokenId]
		}
		return nil
	}
	
	init(){ 
		self.baseUri = "https://graphigo.prd.galaxy.eco/metadata/ufcstrikeinfinity/"
		
		// Initialize signer
		self.signer = self.account.address
		
		// Initialize collection metadatas
		self.collectionName = "UFC Strike Infinity"
		self.collectionDescription = "Introducing UFC Strike Infinity - Earn Stellar Rewards. This is a collection of the rewards you can earn via our inaugural campaign on the Galxe platform."
		self.collectionExternalURL = MetadataViews.ExternalURL("https://galxe.com/ufcstrike")
		self.collectionSquareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://cdn.galxe.com/galaxy/ufcstrike/ufcstrikeinfinity.jpeg"), mediaType: "image/jpeg")
		self.collectionBannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://cdn.galxe.com/galaxy/ufcstrike/ufcstrikeinfinity.jpeg"), mediaType: "image/jpeg")
		self.collectionSocials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/ufcstrike"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/ufcstrike"), "discord": MetadataViews.ExternalURL("https://discord.gg/UFCStrike")}
		
		// Initialize contract internal metadatas
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initalize mapping from ID to address
		self.owners = []
		
		// Initialize mapping from verify_id to bool
		self.minted ={} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/UFCStrikeInfinityCollection
		self.CollectionPublicPath = /public/UFCStrikeInfinityCollection
		self.OwnerStoragePath = /storage/UFCStrikeInfinityOwner
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&UFCStrikeInfinity.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
