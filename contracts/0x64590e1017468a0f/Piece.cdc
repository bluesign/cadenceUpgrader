import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract Piece: NonFungibleToken, ViewResolver {

	// Collection Information
	access(self) let collectionInfo: {String: AnyStruct}

	// Contract Information
	pub var totalSupply: UInt64

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)
	pub event Minted(id: UInt64, recipient: Address, creatorID: UInt64)
	pub event MetadataSuccess(creatorID: UInt64, textContent: String)
	pub event MetadataError(error: String)

	// Paths
	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath

	// Maps metadataId of NFT to NFTMetadata
	pub let creatorIDs: {UInt64: [NFTMetadata]}

	// You can get a list of purchased NFTs
	// by doing `buyersList.keys`
	access(account) let buyersList: {Address: {UInt64: [UInt64]}}

	access(account) let nftStorage: @{Address: {UInt64: NFT}}

	pub struct NFTMetadata {
		pub let creatorID: UInt64
		pub let creatorAddress: Address
		pub let description: String
		pub let image: MetadataViews.HTTPFile
		pub let purchasers: {UInt64: Address}
		pub let metadataId: UInt64
		pub var minted: UInt64
		pub var extra: {String: AnyStruct}
		pub var timer: UInt64
		pub let creationTime: UFix64
		pub let embededHTML: String

		access(account) fun purchased(serial: UInt64, buyer: Address) {
			self.purchasers[serial] = buyer
		}

		access(account) fun updateMinted() {
			self.minted = self.minted + 1
		}

		init(
			_creatorID: UInt64,
			_creatorAddress: Address,
			_description: String,
			_image: MetadataViews.HTTPFile,
			_extra: {String: AnyStruct},
			_currentTime: UFix64,
			_embededHTML: String,
			) {

			self.metadataId = _creatorID
			self.creatorID = _creatorID
			self.creatorAddress = _creatorAddress
			self.description = _description
			self.image = _image
			self.extra = _extra
			self.minted = 0
			self.purchasers = {}
			self.timer = 0
			self.creationTime = _currentTime
			self.embededHTML = _embededHTML
		}
	}

	pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
		pub let id: UInt64
		// The 'metadataId' is what maps this NFT to its 'NFTMetadata'
		pub let creatorID: UInt64
		pub let serial: UInt64
		pub let indexNumber: Int
		pub let originalMinter: Address

		pub fun getMetadata(): NFTMetadata {
			return Piece.getNFTMetadata(self.creatorID, self.indexNumber )!
		}

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
			let metadata = self.getMetadata()
			switch view {
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(
						creatorID: metadata.creatorID.toString(),
						description: metadata.description,
						thumbnail: metadata.image
					)
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.getMetadata().extra, excludedNames: nil)

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
					return Piece.resolveView(view)
        		case Type<MetadataViews.ExternalURL>():
        			return Piece.getCollectionAttribute(key: "website") as! MetadataViews.ExternalURL
		        case Type<MetadataViews.NFTCollectionDisplay>():
					return Piece.resolveView(view)
				case Type<MetadataViews.Medias>():
					if metadata.embededHTML != nil {
						return MetadataViews.Medias(
							items: [
								MetadataViews.Media(
									file: MetadataViews.HTTPFile(
										url: metadata.embededHTML!
									),
									mediaType: "html"
								)
							]
						)
					}
        		case Type<MetadataViews.Royalties>():
          			return MetadataViews.Royalties([
            			MetadataViews.Royalty(
              				recepient: getAccount(metadata.creatorAddress).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
              				cut: 0.10, // 10% royalty on secondary sales
              				description: "The creator of the original content get's 10% of every secondary sale."
            			)
          			])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(
						self.serial
					)

			}
			return nil
		}

		init(_creatorID: UInt64, _indexNumber: Int, _recipient: Address) {
			pre {
				Piece.creatorIDs[_creatorID] != nil:
					"This NFT does not exist in this collection."
			}
			// Assign serial number to the NFT based on the number of minted NFTs
			let _serial = Piece.getNFTMetadata(_creatorID, _indexNumber)!.minted
			self.id = self.uuid
			self.creatorID = _creatorID
			self.serial = _serial
			self.indexNumber = _indexNumber
			self.originalMinter = _recipient

			// Update the buyers list so we keep track of who is purchasing
			if let buyersRef = &Piece.buyersList[_recipient] as &{UInt64: [UInt64]}? {
				if let metadataIdMap = &buyersRef[_creatorID] as &[UInt64]? {
					metadataIdMap.append(_serial)
				} else {
					buyersRef[_creatorID] = [_serial]
				}
			} else {
				Piece.buyersList[_recipient] = {_creatorID: [_serial]}
			}

			let metadataRef = (&Piece.creatorIDs[_creatorID]![_indexNumber] as &NFTMetadata)
			// Update who bought this serial inside NFTMetadata
			metadataRef.purchased(serial: _serial, buyer: _recipient)
			// Update the total supply of this MetadataId by 1
			metadataRef.updateMinted()
			// Update Piece collection NFTs count
			Piece.totalSupply = Piece.totalSupply + 1

			emit Minted(id: self.id, recipient: _recipient, creatorID: _creatorID)
		}
	}

    /// Defines the methods that are particular to this NFT contract collection
    ///
    pub resource interface PieceCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowPiece(id: UInt64): &Piece.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Piece NFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

	pub resource Collection: PieceCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

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
        pub fun borrowPiece(id: UInt64): &Piece.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Piece.NFT
            }

            return nil
        }

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = token as! &NFT
			return nft as &AnyResource{MetadataViews.Resolver}
		}

		pub fun claim() {
			if let storage = &Piece.nftStorage[self.owner!.address] as &{UInt64: NFT}? {
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
		pub fun createNFTMetadata(
			channel: String,
			creatorID: UInt64,
			creatorAddress: Address,
			sourceURL: String,
			textContent: String,
			pieceCreationDate: String,
			contentCreationDate: String,
			imgUrl: String,
			embededHTML: String,
		) {
			// Check if a record for this ID Exist, if not
			// create am empty one for it
			if Piece.creatorIDs[creatorID] == nil {
				Piece.creatorIDs[creatorID] = []
			}
				
			// Check if that creatorID has uploaded any NFTs
			// If not, then stop and return error Event
			if let account_NFTs = &Piece.creatorIDs[creatorID] as &[Piece.NFTMetadata]? {
				if (self.isMetadataUploaded(_metadatasArray: account_NFTs, _textContent: textContent)) {
					emit MetadataError(error: "A Metadata for this Event already exist")
				} else {
					Piece.creatorIDs[creatorID]?.append(NFTMetadata(
						_creatorID: creatorID,
						_creatorAddress: creatorAddress,
						_description: textContent,
						_image: MetadataViews.HTTPFile(
							url: imgUrl,
						),
						_extra: {
							"Channel": channel,
							"Creator": creatorID,
							"Source": sourceURL,
							"Text content": textContent,
							"Piece creation date": pieceCreationDate,
							"Content creation date": contentCreationDate
							},
						_currentTime: getCurrentBlock().timestamp,
						_embededHTML: embededHTML,
					))

					emit MetadataSuccess(creatorID: creatorID, textContent: textContent)
				}


  			}	
		}

		// mintNFT mints a new NFT and deposits
		// it in the recipients collection
		pub fun mintNFT(creatorID: UInt64, indexNumber: Int, recipient: Address) {
			pre {
				self.isMintingAvailable(_creatorID: creatorID, _indexNumber: indexNumber): "Minting for this NFT has ended."
			}

			let nft <- create NFT(_creatorID: creatorID, _indexNumber: indexNumber, _recipient: recipient)

			if let recipientCollection = getAccount(recipient).getCapability(Piece.CollectionPublicPath).borrow<&Piece.Collection{NonFungibleToken.CollectionPublic}>() {
				recipientCollection.deposit(token: <- nft)
			} else {
				if let storage = &Piece.nftStorage[recipient] as &{UInt64: NFT}? {
					storage[nft.id] <-! nft
				} else {
					Piece.nftStorage[recipient] <-! {nft.id: <- nft}
				}
			}
		}

		// create a new Administrator resource
		pub fun createAdmin(): @Administrator {
			return <- create Administrator()
		}

		// change piece of collection info
		pub fun changeField(key: String, value: AnyStruct) {
			Piece.collectionInfo[key] = value
		}

		access(account) fun isMintingAvailable(_creatorID: UInt64, _indexNumber: Int): Bool {
			let metadata = Piece.getNFTMetadata(_creatorID, _indexNumber)!
			let answer = getCurrentBlock().timestamp <= (metadata.creationTime + 86400.0)

			return answer
		}

		access(account) fun isMetadataUploaded(_metadatasArray: &[Piece.NFTMetadata], _textContent: String): Bool {
			var i = 0
    		while i < _metadatasArray.length {
			    if (_metadatasArray[i].description == _textContent) {
					return true
				 }
    		i = i + 1
    		}
			return false
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
                    storagePath: Piece.CollectionStoragePath,
                    publicPath: Piece.CollectionPublicPath,
                    providerPath: Piece.CollectionPrivatePath,
                    publicCollection: Type<&Piece.Collection{Piece.PieceCollectionPublic}>(),
                    publicLinkedType: Type<&Piece.Collection{Piece.PieceCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&Piece.Collection{Piece.PieceCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-Piece.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
				let media = Piece.getCollectionAttribute(key: "image") as! MetadataViews.Media	
                return MetadataViews.NFTCollectionDisplay(
                        name: "Piece",
                        description: "Sell Pieces of any Tweet in seconds.",
                        externalURL: MetadataViews.ExternalURL("https://piece.gg/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/CreateAPiece")
                        }
                    )
        }
        return nil
    }

	//Get all the recorded creatorIDs 
	pub fun getAllcreatorIDs():[UInt64] {
		return self.creatorIDs.keys
	}

	// Get information about a NFTMetadata
	pub fun getNFTMetadata(_ creatorID: UInt64,_ indexNumber: Int): NFTMetadata? {
		return self.creatorIDs[creatorID]![indexNumber]
	}

	pub fun getOnecreatorIdMetadatas(creatorID: UInt64): [NFTMetadata]? {
		return self.creatorIDs[creatorID]
	}

	pub fun getTimeRemaining(_creatorID: UInt64,_indexNumber: Int): UFix64? {
		let metadata = Piece.getNFTMetadata(_creatorID, _indexNumber)!
		let answer = (metadata.creationTime + 86400.0) - getCurrentBlock().timestamp
		return answer
	}

	pub fun getbuyersList(): {Address: {UInt64: [UInt64]}} {
		return self.buyersList
	}

	pub fun getCollectionInfo(): {String: AnyStruct} {
		let collectionInfo = self.collectionInfo
		collectionInfo["creatorIDs"] = self.creatorIDs
		collectionInfo["buyersList"] = self.buyersList
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
		self.collectionInfo["name"] = "Piece"
		self.collectionInfo["description"] = "Sell Pieces of any Tweet in seconds."
		self.collectionInfo["image"] = MetadataViews.Media(
            			file: MetadataViews.HTTPFile(
            				url: "https://media.discordapp.net/attachments/1075564743152107530/1149417271597473913/Piece_collection_image.png?width=1422&height=1422"
            			),
            			mediaType: "image/jpeg"
          			)			
    	self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
    	self.collectionInfo["website"] = MetadataViews.ExternalURL("https://www.piece.gg/")
		self.collectionInfo["socials"] = {"Twitter": MetadataViews.ExternalURL("https://frontend-react-git-testing-piece.vercel.app/")}
		self.totalSupply = 0
		self.creatorIDs = {}
		self.buyersList = {}
		self.nftStorage <- {}

		// Set the named paths
		self.CollectionStoragePath = /storage/PieceCollection
		self.CollectionPublicPath = /public/PieceCollection
		self.CollectionPrivatePath = /private/PieceCollection
		self.AdministratorStoragePath = /storage/PieceAdministrator

		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.save(<- collection, to: self.CollectionStoragePath)

		// Create a public capability for the collection
		self.account.link<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)

		// Create a Administrator resource and save it to storage
		let administrator <- create Administrator()
		self.account.save(<- administrator, to: self.AdministratorStoragePath)

		emit ContractInitialized()
	}
}
