import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"


pub contract PosterityFinal: NonFungibleToken, ViewResolver {

	// Collection Information
	access(self) let collectionInfo: {String: AnyStruct}

	// Contract Information
	pub var totalSupply: UInt64

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, recipient: Address, randomID: UInt64)
	pub event SVGSuccess(randomID: UInt64, userAddress: Address)
	pub event StringAdded(randomID: UInt64, stringPiece: String)


	// Paths
	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath
	pub let MetadataStoragePath: StoragePath
	pub let MetadataPublicPath: PublicPath

	access(account) let nftStorage: @{Address: {UInt64: NFT}}

	pub resource SVGStorage {
		// List of Creator 
		pub let randomID: UInt64
		pub var SVGArray: [String]

		init (_randomID: UInt64) {
			self.randomID = _randomID
			self.SVGArray = []
		}

		// As of right now, we don't have a way to limit how many
		// pieces are added to the SVG array, but a one-time lock 
		// can be easily implemented
		access(all) fun addToSVG(
			stringPiece: String,
		) {
			// There are ways to lock this function
			self.SVGArray.append(stringPiece)
		}
	}



	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		// The 'metadataId' is what maps this NFT to its 'SVG'
		pub let randomID: UInt64
		pub let originalMinter: Address
		pub let signature: String
		pub let SVGPointer: StoragePath
		pub let extra: {String: AnyStruct}

		pub fun getViews(): [Type] {
			return [
				Type<MetadataViews.Display>(),
				Type<MetadataViews.ExternalURL>(),
				Type<MetadataViews.NFTCollectionData>(),
				Type<MetadataViews.NFTCollectionDisplay>(),
				Type<MetadataViews.Royalties>(),
				Type<MetadataViews.Serial>(),
				Type<MetadataViews.NFTView>()
			]
		}

		pub fun resolveView(_ view: Type): AnyStruct? {
			switch view {
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(
						randomID: "metadata.creatorUsername",
						description: "Posterity description",
						thumbnail: MetadataViews.HTTPFile(
								url: " ",
							)
					)
				case Type<MetadataViews.Traits>():
					let metaCopy = self.extra
					metaCopy["Signature"] = self.signature
					return MetadataViews.dictToTraits(dict: metaCopy, excludedNames: nil)

				case Type<MetadataViews.NFTView>():
					return MetadataViews.NFTView(
						id: self.id,
						uuid: self.uuid,
						display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?,
						externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?,
						collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?,
						collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?,
						royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?,
						traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?
					)
				case Type<MetadataViews.NFTCollectionData>():
					return PosterityFinal.resolveView(view)
        		case Type<MetadataViews.ExternalURL>():
        			return PosterityFinal.getCollectionAttribute(key: "website") as! MetadataViews.ExternalURL
		        case Type<MetadataViews.NFTCollectionDisplay>():
					return PosterityFinal.resolveView(view)
        		case Type<MetadataViews.Royalties>():
          			return MetadataViews.Royalties([
            			MetadataViews.Royalty(
              				recepient: getAccount(self.originalMinter).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
              				cut: 0.10, // 10% royalty on secondary sales
              				description: "The creator of the original content gets 10% of every secondary sale."
            			)
          			])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(
						0
					)
			}
			return nil
		}

		init(
			_randomID: UInt64,
			_recipient: Address,
			_signature: String,
			_extra: {String: AnyStruct},
			_SVGPointer: StoragePath
			) {

			// Assign serial number to the NFT based on the number of minted NFTs
			self.id = self.uuid
			self.randomID = _randomID
			self.originalMinter = _recipient
			self.extra = _extra
			self.signature = _signature
			self.SVGPointer = _SVGPointer


			// Update PosterityFinal collection NFTs count 
			PosterityFinal.totalSupply = PosterityFinal.totalSupply + 1

			emit Minted(id: self.id, recipient: _recipient, randomID: _randomID)

		}
	}

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface PosterityFinalCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPosterityFinal(id: UInt64): &PosterityFinal.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow PosterityFinal NFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

	pub resource Collection: PosterityFinalCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		// Withdraw removes an NFT from the collection and moves it to the caller(for Trading)
		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

			emit Withdraw(id: token.id, from: self.owner?.address)

			return <-token
		}
		// Deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @NonFungibleToken.NFT) {
			let token <- token as! @NFT

			let id: UInt64 = token.id

			// Add the new token to the dictionary
			self.ownedNFTs[id] <-! token

			emit Deposit(id: id, to: self.owner?.address)
		}

		// GetIDs returns an array of the IDs that are in the collection
		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		// BorrowNFT gets a reference to an NFT in the collection
		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

        /// Gets a reference to an NFT in the collection so that 
        /// the caller can read its metadata and call its methods
        ///
        /// @param id: The ID of the wanted NFT
        /// @return A reference to the wanted NFT resource
        ///        
        pub fun borrowPosterityFinal(id: UInt64): &PosterityFinal.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &PosterityFinal.NFT
            }

            return nil
        }

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = token as! &NFT
			return nft
		}

		pub fun claim() {
			if let storage = &PosterityFinal.nftStorage[self.owner!.address] as &{UInt64: NFT}? {
				for id in storage.keys {
					self.deposit(token: <- storage.remove(key: id)!)
				}
			}
		}

		init () {
			self.ownedNFTs <- {}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	pub resource Administrator {
		// Function to upload the Metadata to the contract.
		pub fun createSVGPath(
			_randomID: UInt64,
			_userAddress: Address
		) {
			// Create a SVGStorage resource and store it inside the Admin account
			// at a unique path generated with the randomID
			let svg <- create SVGStorage(_randomID: _randomID)
			let identifier = "PosteritySVGStorage_".concat(_randomID.toString())
			let path = StoragePath(identifier: identifier)!
			PosterityFinal.account.save(<- svg, to: path)

			emit SVGSuccess(randomID: _randomID, userAddress: _userAddress)
		}

		// mintNFT mints a new NFT and deposits
		// it in the recipients collection
		pub fun mintNFT(
			recipient: Address,
			signature: String,
			traits: String,		
			randomNumber: UInt64	
			) {

			// Fetch StoragePath for this randomID and recipient	
			let identifier = "PosteritySVGStorage_".concat(randomNumber.toString())

			let nft <- create NFT(
				_randomID: randomNumber,
				 _recipient: recipient,
				_signature: signature,
				_extra: {
					"randomID": randomNumber,
					"traits": traits
				},
				_SVGPointer: StoragePath(identifier: identifier)!
				 )

			if let recipientCollection = getAccount(recipient).getCapability(PosterityFinal.CollectionPublicPath).borrow<&PosterityFinal.Collection{NonFungibleToken.CollectionPublic}>() {
				recipientCollection.deposit(token: <- nft)
			} else {
				if let storage = &PosterityFinal.nftStorage[recipient] as &{UInt64: NFT}? {
					storage[nft.id] <-! nft
				} else {
					PosterityFinal.nftStorage[recipient] <-! {nft.id: <- nft}
				}
			}
		}

		// Fun to add strings to an array(SVG) in pieces
		pub fun addToSVG(
			_randomID: UInt64,
			_stringPiece: String,
			) {
			let identifier = "PosteritySVGStorage_".concat(_randomID.toString())
			let path = StoragePath(identifier: identifier)!
			let SVGStorage = PosterityFinal.account.borrow<&PosterityFinal.SVGStorage>(from: path)!
			SVGStorage.addToSVG(stringPiece: _stringPiece)
			
			emit StringAdded(randomID: _randomID, stringPiece: _stringPiece)
		}
		// create a new Administrator resource
		pub fun createAdmin(): @Administrator {
			return <- create Administrator()
		}
		// fetch the Metadata Storage from the account
		
		// change PosterityFinal of collection info
		pub fun changeField(key: String, value: AnyStruct) {
			PosterityFinal.collectionInfo[key] = value
		}

	}


	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: PosterityFinal.CollectionStoragePath,
                    publicPath: PosterityFinal.CollectionPublicPath,
                    providerPath: PosterityFinal.CollectionPrivatePath,
                    publicCollection: Type<&PosterityFinal.Collection{PosterityFinal.PosterityFinalCollectionPublic}>(),
                    publicLinkedType: Type<&PosterityFinal.Collection{PosterityFinal.PosterityFinalCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&PosterityFinal.Collection{PosterityFinal.PosterityFinalCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-PosterityFinal.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
				let media = PosterityFinal.getCollectionAttribute(key: "image") as! MetadataViews.Media	
                return MetadataViews.NFTCollectionDisplay(
                        name: "PosterityFinal",
                        description: "Sell PosterityFinals of any Tweet in seconds.",
                        externalURL: MetadataViews.ExternalURL("https://PosterityFinal.gg/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/CreateAPosterityFinal")
                        }
                    )
        }
        return nil
    }

	// Get information about a SVG
/* 	pub fun getSVG(_ randomID: UInt64,_ userAddress: Address): PosterityFinal.SVG? {
		let publicAccount = self.account
		let metadataCapability: Capability<&AnyResource{PosterityFinal.MetadataStoragePublic}> = publicAccount.getCapability<&{MetadataStoragePublic}>(self.MetadataPublicPath)
		let metadatasRef: &AnyResource{PosterityFinal.MetadataStoragePublic} = metadataCapability.borrow()!
		let metadatas: PosterityFinal.SVG? = metadatasRef.findMetadata(randomID, userAddress)

		return metadatas
	} */

	pub fun getCollectionInfo(): {String: AnyStruct} {
		let collectionInfo = self.collectionInfo
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["version"] = 1
		return collectionInfo
	}

	pub fun getCollectionAttribute(key: String): AnyStruct {
		return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
	}


	init() {
		// Collection Info
		self.collectionInfo = {}
		self.collectionInfo["name"] = "PosterityFinal"
		self.collectionInfo["description"] = "Sell PosterityFinals of any Tweet in seconds."
		self.collectionInfo["image"] = MetadataViews.Media(
            			file: MetadataViews.HTTPFile(
            				url: "https://media.discordapp.net/attachments/1075564743152107530/1149417271597473913/PosterityFinal_collection_image.png?width=1422&height=1422"
            			),
            			mediaType: "image/jpeg"
          			)			
    	self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
    	self.collectionInfo["website"] = MetadataViews.ExternalURL("https://www.PosterityFinal.gg/")
		self.collectionInfo["socials"] = {"Twitter": MetadataViews.ExternalURL("https://frontend-react-git-testing-PosterityFinal.vercel.app/")}
		self.totalSupply = 0
		self.nftStorage <- {}

		let identifier = "PosterityFinal_Collection".concat(self.account.address.toString())

		// Set the named paths
		self.CollectionStoragePath = StoragePath(identifier: identifier)!
		self.CollectionPublicPath = PublicPath(identifier: identifier)!
		self.CollectionPrivatePath = PrivatePath(identifier: identifier)!
		self.AdministratorStoragePath = StoragePath(identifier: identifier.concat("_Administrator"))!
		self.MetadataStoragePath = StoragePath(identifier: identifier.concat("_Metadata"))!
		self.MetadataPublicPath = PublicPath(identifier: identifier.concat("_Metadata"))!

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<- collection, to: self.CollectionStoragePath)

		// Create a public capability for the collection
		self.account.link<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)

		// Create a Administrator resource and save it to PosterityFinal account storage
		let administrator <- create Administrator()
		self.account.save(<- administrator, to: self.AdministratorStoragePath)

		emit ContractInitialized()
	}
}