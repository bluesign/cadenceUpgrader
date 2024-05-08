import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import SwirlNametag from "./SwirlNametag.cdc"

access(all)
contract SwirlMoment: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextNonceForProofOfMeeting: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Log(str: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let ProviderPrivatePath: PrivatePath
	
	access(all)
	struct Coordinate{ 
		access(all)
		let lat: Fix64
		
		access(all)
		let lng: Fix64
		
		init(lat: Fix64, lng: Fix64){ 
			self.lat = lat
			self.lng = lng
		}
	}
	
	access(all)
	struct ProofOfMeeting{ 
		access(all)
		let account: &Account
		
		access(all)
		let location: Coordinate
		
		access(all)
		let nonce: UInt64
		
		access(all)
		let keyIndex: Int
		
		access(all)
		let signature: String
		
		init(account: &Account, location: Coordinate, nonce: UInt64, keyIndex: Int, signature: String){ 
			self.account = account
			self.location = location
			self.nonce = nonce
			self.keyIndex = keyIndex
			self.signature = signature
		}
		
		access(all)
		fun signedData(): [UInt8]{ 
			var json = "{"
			json = json.concat("\"address\":\"").concat(self.account.address.toString()).concat("\",")
			json = json.concat("\"lat\":").concat(self.location.lat.toString()).concat(",")
			json = json.concat("\"lng\":").concat(self.location.lng.toString()).concat(",")
			json = json.concat("\"nonce\":").concat(self.nonce.toString())
			json = json.concat("}")
			return json.utf8
		}
		
		access(all)
		fun signPubKey(): AccountKey{ 
			return self.account.keys.get(keyIndex: self.keyIndex) ?? panic("no key at given index")
		}
	}
	
	/// Mints a new NFT. Proof-of-Location is required to mint moment
	access(all)
	fun mint(proofs: [ProofOfMeeting]){ 
		// validate swirl participants' messages
		for proof in proofs{ 
			// 0. resolve profile from the participant's SwirlNametag.
			let collectionRef = proof.account.capabilities.get<&{SwirlNametag.SwirlNametagCollectionPublic}>(SwirlNametag.CollectionPublicPath).borrow<&{SwirlNametag.SwirlNametagCollectionPublic}>() ?? panic("no SwirlNametag.Collection found: ".concat(proof.account.address.toString()))
			let nametags = collectionRef.getIDs()
			if nametags.length == 0{ 
				panic("no nametag found: ".concat(proof.account.address.toString()))
			}
			let nametag = collectionRef.borrowSwirlNametag(id: nametags[0]) ?? panic("unable to borrow nametag")
			let profile = nametag.profile
			
			// 1. ensure that nonce is up to date (to prevent signature replay attack)
			if proof.nonce != SwirlMoment.nextNonceForProofOfMeeting{ 
				panic("nonce mismatch: ".concat(proof.account.address.toString()))
			}
			
			// 2. verify that the message is signed correctly
			let isValid = proof.signPubKey().publicKey.verify(signature: proof.signature.decodeHex(), signedData: proof.signedData(), domainSeparationTag: "", hashAlgorithm: HashAlgorithm.SHA2_256)
			if !isValid{ 
				panic("invalid signature: ".concat(proof.account.address.toString()))
			}
			
			// 3. make sure they're in a close location (<= 1km!)
			// since we can't correctly calculate harversine distance in cadence,
			// we use 0.00904372 degrees to approximate as 1km (without correcting the earth's curvature...)
			if self.abs(proofs[0].location.lat - proof.location.lat) > 0.00904372{ 
				panic("location too far: ".concat(proof.account.address.toString()))
			}
			if self.abs(proofs[0].location.lng - proof.location.lng) > 0.00904372{ 
				panic("location too far: ".concat(proof.account.address.toString()))
			}
			
			// 4. mint
			for p in proofs{ 
				if p.account.address == proof.account.address{ 
					continue
				}
				let recipient = p.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(SwirlMoment.CollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>() ?? panic("no SwirlMoment.Collection found: ".concat(proof.account.address.toString()))
				self.mintNFT(recipient: recipient, nametagID: nametag.id, location: proof.location)
			}
		}
		SwirlMoment.nextNonceForProofOfMeeting = SwirlMoment.nextNonceForProofOfMeeting + 1
	}
	
	access(self)
	fun abs(_ x: Fix64): Fix64{ 
		if x < 0.0{ 
			return -x
		}
		return x
	}
	
	access(self)
	fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, nametagID: UInt64, location: Coordinate){ 
		// create a new NFT
		var newNFT <- create NFT(id: SwirlMoment.totalSupply, nametagID: nametagID, location: location, mintedAt: getCurrentBlock().timestamp)
		recipient.deposit(token: <-newNFT)
		SwirlMoment.totalSupply = SwirlMoment.totalSupply + 1
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// the token ID
		access(all)
		let id: UInt64
		
		/// the token ID of the nametag, linked to the profile of the person you met
		access(all)
		let nametagID: UInt64
		
		/// where you met
		access(all)
		let location: Coordinate
		
		/// the time you met
		access(all)
		let mintedAt: UFix64
		
		init(id: UInt64, nametagID: UInt64, location: Coordinate, mintedAt: UFix64){ 
			self.id = id
			self.nametagID = nametagID
			self.location = location
			self.mintedAt = mintedAt
		}
		
		access(all)
		fun profile(): SwirlNametag.Profile{ 
			return SwirlNametag.getProfile(self.nametagID)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views: [Type] = [Type<MetadataViews.Display>(), Type<MetadataViews.Serial>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>()]
			return views
		}
		
		access(all)
		fun name(): String{ 
			return "Swirl Moment with ".concat(self.profile().nickname)
		}
		
		access(all)
		fun profileImageUrl(): String{ 
			let profile = self.profile()
			var url = "https://swirl.deno.dev/dnft/moment.svg?"
			url = url.concat("nickname=").concat(profile.nickname)
			url = url.concat("&profile_img=").concat(String.encodeHex(profile.profileImage.utf8))
			url = url.concat("&color=").concat(String.encodeHex(profile.color.utf8))
			url = url.concat("&met_at=").concat(self.mintedAt.toString())
			return url
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<SwirlNametag.Profile>():
					return self.profile()
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.", thumbnail: MetadataViews.HTTPFile(url: self.profileImageUrl()))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.profileImageUrl())
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SwirlMoment.CollectionStoragePath, publicPath: SwirlMoment.CollectionPublicPath, publicCollection: Type<&SwirlMoment.Collection>(), publicLinkedType: Type<&SwirlMoment.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SwirlMoment.createEmptyCollection(nftType: Type<@SwirlMoment.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.profileImageUrl()), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Swirl Moment", description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.", externalURL: MetadataViews.ExternalURL("https://hyphen.at/"), squareImage: media, bannerImage: media, socials:{} )
				case Type<MetadataViews.Traits>():
					let traits:{ String: AnyStruct} ={} 
					traits["locationLat"] = self.location.lat
					traits["locationLng"] = self.location.lng
					traits["mintedAt"] = self.mintedAt
					let traitsView = MetadataViews.dictToTraits(dict: traits, excludedNames: [])
					return traitsView
				default:
					return nil
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SwirlMomentCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowSwirlMoment(id: UInt64): &SwirlMoment.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow SwirlMoment reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: SwirlMomentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
			panic("soulbound; SBT is not transferable")
		}
		
		access(all)
		fun burn(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			destroy token
		}
		
		// deposit takes an NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SwirlMoment.NFT
			let id: UInt64 = token.id
			
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
		fun borrowSwirlMoment(id: UInt64): &SwirlMoment.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &SwirlMoment.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let SwirlMomentNFT = nft as! &SwirlMoment.NFT
			return SwirlMomentNFT as &{ViewResolver.Resolver}
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
	
	init(){ 
		self.totalSupply = 0
		self.nextNonceForProofOfMeeting = 0
		self.CollectionStoragePath = /storage/SwirlMomentCollection
		self.CollectionPublicPath = /public/SwirlMomentCollection
		self.ProviderPrivatePath = /private/SwirlNFTCollectionProvider
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SwirlMoment.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
