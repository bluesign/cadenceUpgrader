import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract Bakesale_NFT_V3: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64)
    pub event Claimed(id: UInt64, to: Address?)
    pub event SetCreated(setId: UInt32)
    pub event SetAdded(setId: UInt32)
    pub event SetRemoved(setId: UInt32)

	pub event UpdatedClaimQuantityLimit(setId: UInt32, oldLimit: UInt32, newLimit: UInt32)
	pub event UpdatedClaimTimeDelay(setId: UInt32, oldLimit: UFix64, newLimit: UFix64)

	pub event CheckedClaim(value1: UFix64, value2: UFix64, value3: UFix64)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath

    // totalSupply
    // The total number of Bakesale_NFT_V3 that have been minted
    //
    pub var totalSupply: UInt64

    // Array of NFTSets that belong to this contract
    access(self) var setIds: [UInt32]

    // Variable size dictionary of SetData structs
    access(self) var setData: {UInt32: NFTSetData}

    // Current number of editions minted per Set
    access(self) var numberEditionsMintedPerSet: {UInt32: UInt32}

    pub resource NFT: NonFungibleToken.INFT {

        pub let id: UInt64

        // The IPFS CID of the metadata file.
        pub let metadata: String

         // The Set id references this NFT belongs to
        pub let setId: UInt32

        // The specific edition number for this NFT
        pub let editionNum: UInt32

        init(id: UInt64, metadata: String, setId: UInt32, editionNum: UInt32) {
            self.id = id
            self.metadata = metadata
            self.setId = setId
            self.editionNum = editionNum
        }
    }


    pub struct NFTSetData {

        // Unique ID for the Set
        pub let setId: UInt32

        // Max number of editions that can be minted in this set
        pub let maxEditions: UInt32
                  
        // The JSON metadata for each NFT edition can be stored off-chain on IPFS.
        // This is an optional dictionary of IPFS hashes, which will allow marketplaces
        // to pull the metadata for each NFT edition
        pub var ipfsMetadataHash: String

        // The ipfs hash for the media
        pub var ipfsMediaHash: String


		// boolean isActiveForClaim
		// UInt32 quantityClaimLimit
		// UInt32 timeWaitedClaimLimit
		// Set a limit on how many of this token someone can claim
		pub(set) var quantityClaimLimit: UInt32

		// Set a limit on how often someone can claim a token
		pub(set) var timeWaitedClaimLimit: UFix64

		// pub fun update
        
        init(
            setId: UInt32,
            maxEditions: UInt32,
            ipfsMetadataHash: String,
            ipfsMediaHash: String,
			quantityClaimLimit: UInt32,
			timeWaitedClaimLimit: UFix64
        ) {

            self.setId = setId
            self.maxEditions = maxEditions
            self.ipfsMetadataHash = ipfsMetadataHash
            self.ipfsMediaHash = ipfsMediaHash
			self.quantityClaimLimit = quantityClaimLimit
			self.timeWaitedClaimLimit = timeWaitedClaimLimit
        }
        
    }

    pub resource interface Bakesale_NFT_V3CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBakesale_NFT_V3(id: UInt64): &Bakesale_NFT_V3.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Bakesale_NFT_V3 reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: Bakesale_NFT_V3CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        
        // dictionary of NFTs
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
		

		// private dictionary of set IDs to claimed quantity

		priv var claimQuantities: {UInt32: UInt32}
		// private dictionary of set IDS to last claimed time
		priv var claimTimes: {UInt32: UFix64}

		pub fun hasNotExceededClaimQuantity(setId: UInt32): Bool {

			// Track quantity we find
			var quantity: UInt32 = self.claimQuantities[setId] ?? 0

			// And grab the limit
			let setData = Bakesale_NFT_V3.setData[setId]

			if setData == nil {
				return false
			}

			let limit: UInt32 = setData!.quantityClaimLimit

			return quantity < limit
		}


		pub fun doesUserPassTimeWaitedCheck(setId: UInt32): Bool {

			let block = getCurrentBlock()
			let blockTimestamp: UFix64 = block.timestamp

			let setData = Bakesale_NFT_V3.setData[setId]

			if setData == nil {
				return false
			}

			let requiredTimeElapsed: UFix64 = setData!.timeWaitedClaimLimit

			let mostRecentClaimTime = self.claimTimes[setId] ?? 0.00

			if mostRecentClaimTime == 0.00 {
				self.claimTimes[setId] = blockTimestamp
				return true
			}

			let differenceInTime = blockTimestamp - mostRecentClaimTime

			if differenceInTime <= requiredTimeElapsed {
				return false
			} else {
				self.claimTimes[setId] = blockTimestamp
				return true
			}

		}

		// claimMint mints a token into a user's wallet
		pub fun claimMint(setId: UInt32) {
			pre {
				self.doesUserPassTimeWaitedCheck(setId: setId) == true: "You have claimed a token too recently."
				self.hasNotExceededClaimQuantity(setId: setId) == true: "You have reached the claim quantity limit for this token."
				Bakesale_NFT_V3.numberEditionsMintedPerSet[setId] != nil: "The set does not exist."
                Bakesale_NFT_V3.numberEditionsMintedPerSet[setId]! < Bakesale_NFT_V3.getSetMaxEditions(setId: setId)!:
                    "This set has minted the maximum number of editions."
                Bakesale_NFT_V3.getIpfsMetadataHashBySet(setId: setId) != nil: "The set doesn't have any metadata." 
			}

			// Gets the number of editions that have been minted so far in 
            // this set
            let editionNum: UInt32 = Bakesale_NFT_V3.numberEditionsMintedPerSet[setId]! + (1 as UInt32)

            //get the metadata ipfs hash
            let metadata: String = Bakesale_NFT_V3.getIpfsMetadataHashBySet(setId: setId)!

            // deposit it in the recipient's account using their reference
            self.deposit(token: <- create Bakesale_NFT_V3.NFT(
                id: Bakesale_NFT_V3.totalSupply, 
                metadata: metadata,
                setId: setId,
                editionNum: editionNum 
            ))

			// Update claim quantity for this token
			self.claimQuantities[setId] = (self.claimQuantities[setId] as? UInt32 ?? 0) + 1
            
            // Emit a Minted event with the overall NFT id
            emit Claimed(id: Bakesale_NFT_V3.totalSupply, to: self.owner?.address)

            // Update the total count of NFTs
            Bakesale_NFT_V3.totalSupply = Bakesale_NFT_V3.totalSupply + (1 as UInt64)

            // Update the count of Editions minted in the set
            Bakesale_NFT_V3.numberEditionsMintedPerSet[setId] = editionNum

		}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Bakesale_NFT_V3.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowBakesale_NFT_V3
        // Gets a reference to an NFT in the collection as a Bakesale_NFT_V3.
        //
        pub fun borrowBakesale_NFT_V3(id: UInt64): &Bakesale_NFT_V3.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Bakesale_NFT_V3.NFT
            } else {
                return nil
            }
        }

        // pop
        // Removes and returns the next NFT from the collection.
        //
        pub fun pop(): @NonFungibleToken.NFT {
            let nextID = self.ownedNFTs.keys[0]
            return <- self.withdraw(withdrawID: nextID)
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
			self.claimQuantities = {}
			self.claimTimes = {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Admin
    // Resource that an admin can use to add sets and mint NFTs.
    //
    pub resource Admin {

		// Update NFT set claim quantity limit
		pub fun updateNFTSetClaimQuantityLimit(setId: UInt32, newLimit: UInt32) {
			pre {
				Bakesale_NFT_V3.setIds.contains(setId) == true: "This set does not exist."
			}

			let oldNFTSet = Bakesale_NFT_V3.setData[setId]!

			if oldNFTSet == nil || newLimit < 0 {
				return
			}

			var newNFTSet = NFTSetData(
				setId: oldNFTSet.setId,
				maxEditions: oldNFTSet.maxEditions,
				ipfsMetadataHash: oldNFTSet.ipfsMetadataHash,
				ipfsMediaHash: oldNFTSet.ipfsMediaHash,
				quantityClaimLimit: newLimit,
				timeWaitedClaimLimit: oldNFTSet.timeWaitedClaimLimit
			)

			Bakesale_NFT_V3.setData[setId] = newNFTSet

			emit UpdatedClaimQuantityLimit(setId: setId, oldLimit: oldNFTSet.quantityClaimLimit, newLimit: newLimit)
		}

		// Update NFT set claim time waited limit
		pub fun updateNFTSetTimeWaitedLimit(setId: UInt32, newLimit: UFix64) {

			pre {
				Bakesale_NFT_V3.setIds.contains(setId) == true: "This set does not exist."
			}

			let oldNFTSet = Bakesale_NFT_V3.setData[setId]!

			if oldNFTSet == nil || newLimit < 0.0 {
				return
			}

			var newNFTSet = NFTSetData(
				setId: oldNFTSet.setId,
				maxEditions: oldNFTSet.maxEditions,
				ipfsMetadataHash: oldNFTSet.ipfsMetadataHash,
				ipfsMediaHash: oldNFTSet.ipfsMediaHash,
				quantityClaimLimit: oldNFTSet.quantityClaimLimit,
				timeWaitedClaimLimit: newLimit
			)

			Bakesale_NFT_V3.setData[setId] = newNFTSet

			emit UpdatedClaimTimeDelay(setId: setId, oldLimit: oldNFTSet.timeWaitedClaimLimit, newLimit: newLimit)

		}

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        //
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, setId: UInt32) {

            pre {
                Bakesale_NFT_V3.numberEditionsMintedPerSet[setId] != nil: "The set does not exist."
                Bakesale_NFT_V3.numberEditionsMintedPerSet[setId]! < Bakesale_NFT_V3.getSetMaxEditions(setId: setId)!:
                    "This set has minted the maximum number of editions."
                Bakesale_NFT_V3.getIpfsMetadataHashBySet(setId: setId) != nil: "The set doesn't have any metadata." 
            }
            
            // Gets the number of editions that have been minted so far in 
            // this set
            let editionNum: UInt32 = Bakesale_NFT_V3.numberEditionsMintedPerSet[setId]! + (1 as UInt32)

            //get the metadata ipfs hash
            let metadata: String = Bakesale_NFT_V3.getIpfsMetadataHashBySet(setId: setId)!

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <- create Bakesale_NFT_V3.NFT(
                id: Bakesale_NFT_V3.totalSupply, 
                metadata: metadata,
                setId: setId,
                editionNum: editionNum 
            ))
            
            // Emit a Minted event with the overall NFT id
            emit Minted(id: Bakesale_NFT_V3.totalSupply)

            // Update the total count of NFTs
            Bakesale_NFT_V3.totalSupply = Bakesale_NFT_V3.totalSupply + (1 as UInt64)

            // Update the count of Editions minted in the set
            Bakesale_NFT_V3.numberEditionsMintedPerSet[setId] = editionNum
        }
        
        // batchMintNFT
        // Mints multiple new NFTs given and deposits the NFTs
        // into the recipients collection using their collection reference
		pub fun batchMintNFT(
            recipient: &{NonFungibleToken.CollectionPublic},
            setId: UInt32,
            quantity: UInt64) {

            pre {
                quantity > 0:
                    "Quantity must be > 0"
            }

            var i: UInt64 = 0
            while i < quantity {
                self.mintNFT(
                    recipient: recipient,
                    setId: setId
                )
                i = i + UInt64(1)
            }
		}

        // adds an NFT Set to this contract
        pub fun addNftSet(
            setId: UInt32,
            maxEditions: UInt32,
            ipfsMetadataHash: String,
            ipfsMediaHash: String,
			quantityClaimLimit: UInt32,
			timeWaitedClaimLimit: UFix64

		) {
            pre {
                Bakesale_NFT_V3.setIds.contains(setId) == false: "The set has already been added."
            }

            // Create the new Set struct
            var newNFTSet = NFTSetData(
                setId: setId,
                maxEditions: maxEditions,
                ipfsMetadataHash: ipfsMetadataHash,
                ipfsMediaHash: ipfsMediaHash,
				quantityClaimLimit: quantityClaimLimit,
				timeWaitedClaimLimit: timeWaitedClaimLimit
            )

            // Add the NFTSet to the array of Sets
            Bakesale_NFT_V3.setIds.append(setId)

            // Initialize the NFT edition count to zero if it the setId doesn't already exist as a key in the dictionary
            if (!Bakesale_NFT_V3.numberEditionsMintedPerSet.containsKey(setId) ){
                Bakesale_NFT_V3.numberEditionsMintedPerSet[setId] = 0
            }

            // Store it in the sets mapping field
            Bakesale_NFT_V3.setData[setId] = newNFTSet

            emit SetAdded(setId: setId)
        }

        pub fun removeNftSet(setId: UInt32) {

            pre {
                Bakesale_NFT_V3.setIds.contains(setId) : "Could not borrow set: set does not exist."
            }

            var indexOfSetId: Int = 0

            var i = 0

            while i < Bakesale_NFT_V3.setIds.length {
                if Bakesale_NFT_V3.setIds[i] == setId {
                    indexOfSetId = i
                    break
                }
                i = i + 1
            }

            Bakesale_NFT_V3.setIds.remove(at: indexOfSetId)
            Bakesale_NFT_V3.setData.remove(key: setId)
            emit SetRemoved(setId: setId)
        }
    }

    // fetch
    // Get a reference to a Bakesale_NFT_V3 from an account's Collection, if available.
    // If an account does not have a Bakesale_NFT_V3.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Bakesale_NFT_V3.NFT? {
        let collection = getAccount(from)
            .getCapability(Bakesale_NFT_V3.CollectionPublicPath)
            .borrow<&{ Bakesale_NFT_V3.Bakesale_NFT_V3CollectionPublic }>()
            ?? panic("Couldn't get collection")

        // We trust Bakesale_NFT_V3.Collection.borowBakesale_NFT_V3 to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowBakesale_NFT_V3(id: itemID)
    }

    // listSetData returns the dictionary of set data
    pub fun listSetData(): {UInt32: NFTSetData} {
        return self.setData
    }

    // getAllSets returns all the sets
    //
    // Returns: An array of all the sets that have been created
    pub fun getAllSets(): [Bakesale_NFT_V3.NFTSetData] {
        return Bakesale_NFT_V3.setData.values
    }

    // getSetData returns the NFTSetData for a set.
    // 
    // Parameters: setId: The id of the Set that is being queried
    //
    // Returns: The NFTSetData for this Set
    pub fun getSetData(setId: UInt32): Bakesale_NFT_V3.NFTSetData? {
        return Bakesale_NFT_V3.setData[setId]
    }

    // getSetMaxEditions returns the maximum number of NFT editions that can
    //        be minted in this Set.
    // 
    // Parameters: setId: The id of the Set that is being queried
    //
    // Returns: The max number of NFT editions in this Set
    pub fun getSetMaxEditions(setId: UInt32): UInt32? {
        return Bakesale_NFT_V3.setData[setId]?.maxEditions
    }

    // getNumberEditionsMintedPerSet fetches the number of editions 
    //        minted for a set.
    //
    // Parameters: setId: The id of the Set that is being queried
    //
    // Returns: The number of NFT editions minted in this Set
    pub fun getNumberEditionsMintedPerSet(setId: UInt32): UInt32? {
        return Bakesale_NFT_V3.numberEditionsMintedPerSet[setId]
    }

    // getIpfsMetadataHashBySet returns the ipfs hash for each nft set.
    // 
    // Parameters: setId: The id of the Set that is being queried
    //
    // Returns: The ipfs hash of nft for the set
    pub fun getIpfsMetadataHashBySet(setId: UInt32): String? {
        // Don't force a revert if the setId or field is invalid
        if let set = Bakesale_NFT_V3.setData[setId] {
            return set.ipfsMetadataHash
        } else {
            return nil
        }
    }

    // getIpfsMediaHashBySet returns the ipfs hash for each nft set.
    // 
    // Parameters: setId: The id of the Set that is being queried
    //
    // Returns: The ipfs hash of the media for the nft for the set
    pub fun getIpfsMediaHashBySet(setId: UInt32): String? {
        // Don't force a revert if the setId or field is invalid
        if let set = Bakesale_NFT_V3.setData[setId] {
            return set.ipfsMediaHash
        } else {
            return nil
        }
    }

    // initializer
    //
    init() {

        self.setIds = []
        self.setData = {}
        self.numberEditionsMintedPerSet = {}

        // Set our named paths
        self.CollectionStoragePath = /storage/Bakesale_NFT_V3Collection
        self.CollectionPublicPath = /public/Bakesale_NFT_V3Collection
        self.CollectionPrivatePath = /private/Bakesale_NFT_V3Collection
        self.AdminStoragePath = /storage/Bakesale_NFT_V3Admin

        // Initialize the total supply
        self.totalSupply = 0

        let collection <- Bakesale_NFT_V3.createEmptyCollection()
        
        self.account.save(<- collection, to: Bakesale_NFT_V3.CollectionStoragePath)

        self.account.link<&Bakesale_NFT_V3.Collection>(Bakesale_NFT_V3.CollectionPrivatePath, target: Bakesale_NFT_V3.CollectionStoragePath)

        self.account.link<&Bakesale_NFT_V3.Collection{NonFungibleToken.CollectionPublic, Bakesale_NFT_V3.Bakesale_NFT_V3CollectionPublic}>(Bakesale_NFT_V3.CollectionPublicPath, target: Bakesale_NFT_V3.CollectionStoragePath)
        
        // Create an admin resource and save it to storage
        let admin <- create Admin()
        self.account.save(<- admin, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}