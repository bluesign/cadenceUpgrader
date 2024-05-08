/*
    Contract for Pinnacle NFTs and metadata
    Author: Loic Lesavre loic.lesavre@dapperlabs.com
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

/*
The Pinnacle contract introduces five entities that establish the requirements for minting Pinnacle Pin NFTs and
organizing their metadata: Edition Types, Series, Sets, Shapes, and Editions.

These entities are defined as struct types, created by the Admin, and stored in arrays in the contract state.
Edition Types and Series are independent from other entities. Sets, Shapes, and Editions are linked to a
parent entity: a Series, Set, or Shape, respectively. Sets are also linked to a parent Edition Type.

Pinnacle Pin NFTs are minted from Editions. Owners have the option to add an Inscription to their NFT. The NFTs
adhere to the Flow NFT standard. Any Flow account can create a Collection to store Pinnacle Pin NFTs, which
includes functionality for Inscriptions and XP balance.

An Admin resource is created in the contract's init function. It is meant to be saved in the Admin's account
and provides the following key abilities:

- Create new entities (Edition Types, Series, Sets, Shapes, and Editions).
- Lock Series and Sets, preventing the creation of new child Sets and Shapes, respectively.
- Close Shapes, preventing the creation of new child Editions, Open/Unlimited Editions, preventing the
minting of new NFTs from those Editions, and Edition Types, preventing the creation of new child Sets, Shapes,
and Editions.
- Unlock or reopen entities within the undo period.
- Update the name of Series, Sets, and Shapes, as well as the description of Editions.
- Increment the current printing of Shapes unless they are closed.
- Mint NFTs, subject to the conditions defined in the contract, and deposit them in any account.
- Update an Inscription's note with owner co-signing if the owner has added an Inscription to their NFT.
- Update an NFT's XP balance unless the owner has revoked this ability.
- Create new Admins.

Notes:

- All functions will fail if an invalid argument is provided or one of the pre- or post-conditions are not
met. For getter functions, calls to non-existing objects are considered valid and will return nil so that they
can be handled differently by the caller. The borrowNFT function in the Collection resource is an exception to
that pattern, the borrowNFTSafe or borrowPinNFT function can be used instead.
- All dates specified in the contract are Unix timestamps.
 */

/// The Pinnacle Pin NFTs and metadata contract
///
pub contract Pinnacle: NonFungibleToken, ViewResolver {
    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------

    // Contract Events
    //
    pub event ContractInitialized()

    // Series Events
    //
    /// Emitted when a new Series has been created, meaning new Sets can be created with the Series
    pub event SeriesCreated(id: Int, name: String)
    /// Emitted when a Series is locked, meaning new Sets cannot be created with the Series anymore
    pub event SeriesLocked(id: Int, name: String)
    /// Emitted when a Series's name is updated
    pub event SeriesNameUpdated(id: Int, name: String)

    // Set Events
    //
    /// Emitted when a new Set has been created, meaning new Shapes can be created with the Set
    pub event SetCreated(id: Int, renderID: String, name: String, seriesID: Int, editionType: String)
    /// Emitted when a Set is locked, meaning new Shapes cannot be created with the Set anymore
    pub event SetLocked(id: Int, renderID: String, name: String, seriesID: Int, editionType: String)
    /// Emitted when a Set's name is updated
    pub event SetNameUpdated(id: Int, renderID: String, name: String, seriesID: Int, editionType: String)

    // Shape Events
    //
    /// Emitted when a new Shape has been created, meaning new Editions can be created with the Shape
    pub event ShapeCreated(
        id: Int,
        renderID: String,
        setID: Int,
        name: String,
        editionType: String,
        metadata: {String: [String]}
    )
    /// Emitted when a Shape is closed, meaning new Editions cannot be created with the Shape anymore
    pub event ShapeClosed(
        id: Int,
        renderID: String,
        setID: Int,
        name: String,
        currentPrinting: UInt64,
        editionType: String
    )
    /// Emitted when a Shape's name is updated
    pub event ShapeNameUpdated(
        id: Int,
        renderID: String,
        setID: Int,
        name: String,
        currentPrinting: UInt64,
        editionType: String
    )
    /// Emitted when a Shape's current printing is incremented
    pub event ShapeCurrentPrintingIncremented(
        id: Int,
        renderID: String,
        setID: Int,
        name: String,
        currentPrinting: UInt64,
        editionType: String
    )

    // Edition Events
    //
    /// Emitted when a new Edition has been created, meaning new NFTs can be minted with the Edition
    pub event EditionCreated(
        id: Int,
        renderID: String,
        seriesID: Int,
        setID: Int,
        shapeID: Int,
        variant: String?,
        printing: UInt64,
        editionTypeID: Int,
        description: String,
        isChaser: Bool,
        maxMintSize: UInt64?,
        maturationPeriod: UInt64?,
        traits: {String: [String]}
    )
    /// Emitted when an Edition is either closed by the Admin or the maximum amount of pins have been minted
    pub event EditionClosed(
        id: Int,
        maxMintSize: UInt64
    )
    /// Emitted when an Edition's description is updated
    pub event EditionDescriptionUpdated(
        id: Int,
        description: String
    )

    /// Emitted when an Edition's renderID is updated
    pub event EditionRenderIDUpdated(
        id: Int,
        renderID: String
    )

    /// Emitted when an Edition has been removed from the contract by the Admin, this can only be done if the
    /// Edition is the last one that was created in the contract and no NFTs were minted from it
    pub event EditionRemoved(
        id: Int
    )

    // Edition Type Events
    //
    /// Emitted when a new Edition Type has been created
    pub event EditionTypeCreated(id: Int, name: String, isLimited: Bool, isMaturing: Bool)
    /// Emitted when an Edition Type has been closed, meaning new Editions cannot be created with the Edition
    /// Type anymore
    pub event EditionTypeClosed(id: Int, name: String, isLimited: Bool, isMaturing: Bool)

    // NFT Events
    //
    /// Emitted when a Pin NFT is withdrawn from the Collection
    pub event Withdraw(id: UInt64, from: Address?)
    /// Emitted when a Pin NFT is deposited into the Collection
    pub event Deposit(id: UInt64, to: Address?)
    /// Emitted when a Pin NFT is minted
    pub event PinNFTMinted(id: UInt64, renderID: String, editionID: Int, serialNumber: UInt64?, maturityDate: UInt64?)
    /// Emitted when a Pin NFT is destroyed
    pub event PinNFTBurned(id: UInt64, editionID: Int, serialNumber: UInt64?, xp: UInt64?)
    /// Emitted when a Pin NFT's XP is updated
    pub event NFTXPUpdated(id: UInt64, editionID: Int, xp: UInt64?)
    /// Emitted when an Inscription is added to a Pin NFT
    pub event NFTInscriptionAdded(
        id: Int,
        owner: Address,
        note: String?,
        nftID: UInt64,
        editionID: Int
    )
    /// Emitted when an NFT's Inscription is updated
    pub event NFTInscriptionUpdated(
        id: Int,
        owner: Address,
        note: String?,
        nftID: UInt64,
        editionID: Int
    )
    /// Emitted when an NFT's Inscription is removed by the owner. This can only be done during the undo
    /// period and if the Inscription is the last one that was added to the NFT - meaning the Inscription is
    /// permanent after the undo period has expired or if the NFT is transferred to another owner and the new
    /// owner adds a new Inscription to the NFT
    pub event NFTInscriptionRemoved(id: Int, owner: Address, nftID: UInt64, editionID: Int)

    // Other Events
    //
    /// Emitted when a Series, Set, Shape, or Edition Type is reopened or unlocked by the Admin during the
    /// undo period. Editions cannot be reopened even during the undo period.
    pub event EntityReactivated(entity: String, id: Int, name: String?)
    /// Emitted when a new Variant has been inserted
    pub event VariantInserted(name: String)
    /// Emitted when the wrapper emitPurchasedEvent Admin function is called
    pub event Purchased(
        purchaseIntentID: String,
        buyerAddress: Address,
        countPurchased: UInt64,
        totalSalePrice: UFix64
    )
    /// Emitted when an Open/Unlimited Edition NFT is destroyed by the Admin
    pub event OpenEditionNFTBurned(id: UInt64, editionID: Int)

    //------------------------------------------------------------
    // Named values
    //------------------------------------------------------------

    /// Named Paths
    ///
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath
    pub let MinterPrivatePath: PrivatePath

    //------------------------------------------------------------
    // Publicly readable contract state
    //------------------------------------------------------------

    /// The total supply of Pin NFTs in existence (those have been minted minus those that have been burned)
    pub var totalSupply: UInt64

    /// The period in seconds during which entities can be unlocked or reopened in case they are locked or
    /// closed by mistake. Entities become permanently locked or closed after the undo period has passed.
    pub let undoPeriod: UInt64

    /// The address returned by the Royalties MetadataView to indicate where royalties should be deposited
    pub var royaltyAddress: Address

    /// The end user license URL and statement, it gets added to every Shape's metadata dictionary
    pub var endUserLicenseURL: String

    //------------------------------------------------------------
    // Internal contract state
    //------------------------------------------------------------

    /// The arrays that store the entities in the contract state.
    ///
    /// Each array index corresponds to the entity's ID - 1. See how entities are added to the contract arrays
    /// in the entity creation functions defined in the Admin resource. The entities are stored in arrays
    /// rather than dictionaries so that they can be returned in slices at scale (no need to call the .keys
    /// built-in dictionary function that can cause a computation exceed limit error if the dictionary is too
    /// large).
    access(self) let series: [Series]
    access(self) let sets: [Set]
    access(self) let shapes: [Shape]
    access(self) let editions: [Edition]
    access(self) let editionTypes: [EditionType]

    /// The dictionaries that allow entities to be looked up by unique name
    access(self) let seriesIDsByName: {String: Int}
    access(self) let setIDsByName: {String: Int}
    access(self) let editionTypeIDsByName: {String: Int}

    /// The dictionary that stores the Variant strings that are allowed to be used when creating a new Edition
    ///
    /// Variants are defined as String dictionary entries rather than structs because they do not have any
    /// other properties than their name.
    access(self) let variants: {String: Bool}

    /// The dictionary that stores the maximum number of Inscriptions that can be added to each NFT. By
    /// default (no entry in the dictionary), an NFT can have up to 100 Inscriptions.
    access(self) let inscriptionsLimits: {UInt64: Int}

    /// The dictionary that stores any additional data that needs to be stored in the contract. This field
    /// has been added to accommodate potential future contract updates and facilitate new functionalities.
    /// It is not in use currently.
    access(self) let extension: {String: AnyStruct}

    //------------------------------------------------------------
    // Series
    //------------------------------------------------------------

    /// Struct that defines a Series
    ///
    /// Each Series is created independently of any other entity.
    ///
    pub struct Series {
        /// This Series' unique ID
        pub let id: Int

        /// This Series' unique name. It can be updated by the Admin.
        pub var name: String

        /// This field indicates whether the Series is currently unlocked (lockedDate is nil) or locked (has
        /// actual date).
        ///
        /// Initially, when a Series is created, it is in an unlocked state, allowing the creation of Sets.
        /// Once a Series is locked, it is no longer possible to create Sets linked to that Series. However,
        /// it is still possible to create Shapes and Editions within those Shapes using the Sets already
        /// created from the Series. Locking a Series takes immediate effect, but it can be undone during the
        /// undo period. The lockedDate field indicates the date when the Series is permanently locked,
        /// including the undo period.
        pub var lockedDate: UInt64?

        /// Struct initializer
        ///
        init(id: Int, name: String) {
            self.id = id
            self.name = name
            self.lockedDate = nil
        }

        /// Close this Series
        ///
        access(contract) fun lock() {
            pre {
                self.lockedDate == nil: "Series is already locked"
            }
            // Set the locked date to the current block timestamp plus the undo period
            self.lockedDate = UInt64(getCurrentBlock().timestamp) + Pinnacle.undoPeriod
            emit SeriesLocked(id: self.id, name: self.name)
        }

        /// Unlock this Series
        ///
        /// This will fail if the undo period has expired.
        ///
        access(contract) fun unlock() {
            pre {
                self.lockedDate != nil: "Series is already unlocked"
                self.lockedDate! >= UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Series is permanently locked"
            }
            self.lockedDate = nil
            emit EntityReactivated(entity: "Series", id: self.id, name: self.name)
        }

        /// Update this Series' name
        ///
        access(contract) fun updateName(_ name: String) {
            pre {
                name != "": "The name of a Series cannot be an empty string"
                Pinnacle.seriesIDsByName.containsKey(name) == false: "A Series with that name already exists"
            }
            Pinnacle.seriesIDsByName.remove(key: self.name)
            self.name = name
            Pinnacle.seriesIDsByName[name] = self.id
            emit SeriesNameUpdated(id: self.id, name: self.name)
        }
    }

    /// Return the ID of the latest Series created in the contract
    ///
    /// The ID is an incrementing integer equal to the length of the series array.
    ///
    pub fun getLatestSeriesID(): Int {
        return Pinnacle.series.length
    }

    /// Return a Series struct containing the data of the Series with the given ID, if it exists in the
    /// contract
    ///
    pub fun getSeries(id: Int): Series? {
        pre {
            id > 0: "The ID of a Series must be greater than 0"
        }
        return Pinnacle.getLatestSeriesID() >= id ? Pinnacle.series[id - 1] : nil
    }

    /// Return all Series in the contract
    ///
    pub fun getAllSeries(): [Series] {
        return Pinnacle.series
    }

    /// Return a Series struct containing the data of the Series with the given name, if it exists in the
    /// contract
    ///
    pub fun getSeriesByName(_ name: String): Series? {
        if let id = Pinnacle.seriesIDsByName[name] {
            return Pinnacle.getSeries(id: id)
        }
        return nil
    }

    /// Return the ID of the Series with the given name, if it exists in the contract
    ///
    pub fun getSeriesIDByName(_ name: String): Int? {
        return Pinnacle.seriesIDsByName[name]
    }

    /// Allow iterating over Series names in the contract without allocating an array
    ///
    pub fun forEachSeriesName(_ function: ((String): Bool)) {
        Pinnacle.seriesIDsByName.forEachKey(function)
    }

    /// Return the contract's seriesIDsByName dictionary
    ///
    pub fun getAllSeriesIDsByNames(): {String: Int} {
        return Pinnacle.seriesIDsByName
    }

    //------------------------------------------------------------
    // Set
    //------------------------------------------------------------

    /// Struct that defines a Set
    ///
    /// Each Set is linked to a parent Series and Edition Type.
    ///
    pub struct Set {
        /// This Set's unique ID
        pub let id: Int

        /// This Set's RenderID. The uniqueness of renderID is NOT required.
        pub var renderID: String

        /// This Set's unique name. It can be updated by the Admin.
        pub var name: String

        /// The ID of the Series that this Set belongs to
        pub let seriesID: Int

        /// This field indicates whether the Set is currently unlocked (lockedDate is nil) or locked (has
        /// actual date).
        ///
        /// Initially, when a Set is created, it is in an unlocked state, allowing the creation of Shapes.
        /// Once a Set is locked, it is no longer possible to create Shapes linked to that Set. However, it is
        /// still possible to create Editions using the Shapes already created from the Set. Locking a Set
        /// takes immediate effect, but it can be undone during the undo period. The lockedDate field
        /// indicates the date when the Set is permanently locked, including the undo period.
        pub var lockedDate: UInt64?

        /// The type of Editions that can be created from this Set's Shapes
        pub let editionType: String

        /// The dictionary that stores all the Shape names inside the Set to ensure there can be at most one
        /// Shape with a given name in a Set
        access(self) let shapeNames: {String: Bool}

        /// Struct initializer
        ///
        init(id: Int, renderID: String, name: String, editionType: String, seriesID: Int) {
            self.id = id
            self.renderID = renderID
            self.name = name
            self.seriesID = seriesID
            self.lockedDate = nil
            self.editionType = editionType
            self.shapeNames = {}
        }

        /// Insert a new Shape name to the shapeNames dictionary
        ///
        access(contract) fun insertShapeName(_ name: String) {
            self.shapeNames[name] = true
        }

        /// Remove a Shape name from the shapeNames dictionary
        ///
        access(contract) fun removeShapeName(_ name: String) {
            self.shapeNames.remove(key: name)
        }

        /// Check if the Set contains the given Shape name
        ///
        access(contract) fun shapeNameExistsInSet(_ name: String): Bool {
            return self.shapeNames.containsKey(name)
        }

        /// Lock the Set so that no more Editions can be created with it
        ///
        access(contract) fun lock() {
            pre {
                self.lockedDate == nil: "Set is already locked"
            }
            // Set the locked date to the current block timestamp plus the undo period
            self.lockedDate = UInt64(getCurrentBlock().timestamp) + Pinnacle.undoPeriod
            emit SetLocked(
                id: self.id,
                renderID: self.renderID,
                name: self.name,
                seriesID: self.seriesID,
                editionType: self.editionType
            )
        }

        /// Unlock this Set
        ///
        /// This will fail if the undo period has expired.
        ///
        access(contract) fun unlock() {
            pre {
                self.lockedDate != nil: "Set is already unlocked"
                self.lockedDate! >= UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Set is permanently locked"
            }
            self.lockedDate = nil
            emit EntityReactivated(entity: "Set", id: self.id, name: self.name)
        }

        /// Update this Set's name
        ///
        access(contract) fun updateName(_ name: String) {
            pre {
                name != "": "The name of a Set cannot be an empty string"
                Pinnacle.setIDsByName.containsKey(name) == false: "A Set with that name already exists"
            }
            Pinnacle.setIDsByName.remove(key: self.name)
            self.name = name
            Pinnacle.setIDsByName[name] = self.id
            emit SetNameUpdated(
                id: self.id,
                renderID: self.renderID,
                name: self.name,
                seriesID: self.seriesID,
                editionType: self.editionType
            )
        }

        /// Return this Set's shapeNames dictionary
        ///
        pub fun getShapeNames(): {String: Bool} {
            return self.shapeNames
        }
    }

    /// Return the ID of the latest Set created in the contract
    ///
    /// The ID is an incrementing integer equal to the length of the sets array.
    ///
    pub fun getLatestSetID(): Int {
        return Pinnacle.sets.length
    }

    /// Return a Set struct containing the data of the Set with the given ID, if it exists in the contract
    ///
    pub fun getSet(id: Int): Set? {
        pre {
            id > 0: "The ID of a Set must be greater than zero"
        }
        return Pinnacle.getLatestSetID() >= id ? Pinnacle.sets[id - 1] : nil
    }

    /// Return all Sets in the contract
    ///
    pub fun getAllSets(): [Set] {
        return Pinnacle.sets
    }

    /// Return a Set struct containing the data of the Set with the given name, if it exists in the contract
    ///
    pub fun getSetByName(_ name: String): Set? {
        if let id = Pinnacle.setIDsByName[name] {
            return Pinnacle.getSet(id: id)
        }
        return nil
    }

    /// Return the ID of the Set with the given name, if it exists in the contract
    ///
    pub fun getSetIDByName(_ name: String): Int? {
        return Pinnacle.setIDsByName[name]
    }

    /// Allow iterating over Set names in the contract without allocating an array
    ///
    pub fun forEachSetName(_ function: ((String): Bool)) {
        Pinnacle.setIDsByName.forEachKey(function)
    }

    /// Return the contract's setIDsByName dictionary
    ///
    pub fun getAllSetIDsByNames(): {String: Int} {
        return Pinnacle.setIDsByName
    }

    //------------------------------------------------------------
    // Shape
    //------------------------------------------------------------

    /// Struct that defines a Shape
    ///
    /// Each Shape is linked to a parent Set.
    ///
    pub struct Shape {
        /// This Shapes's unique ID
        pub let id: Int

        /// This Shape's renderID. The uniqueness of renderID is NOT required.
        pub let renderID: String

        /// The ID of the Set that this Shape belongs to
        pub let setID: Int

        /// This Shape's name, unique inside a Set. It can be updated by the Admin.
        pub var name: String

        /// This field indicates whether the Shape is currently open (closedDate is nil) or closed (has actual
        /// date).
        ///
        /// Initially, when a Shape is created, it is in an open state, allowing the creation of Editions.
        /// Once a Shape is closed, it is no longer possible to create Editions linked to that Shape or
        /// incrementing its current printing. However, it is still possible to mint NFTs using the Editions
        /// already created from the Shape. Locking a Shape takes immediate effect, but it can be undone
        /// during the undo period. The closedDate field indicates the date when the Shape is permanently
        /// closed, including the undo period.
        pub var closedDate: UInt64?

        /// The current printing of the Shape, determining the printing of the Editions linked to the Shape.
        /// It can be incremented by the Admin.
        pub var currentPrinting: UInt64

        /// The type of Editions that can be created from this Shape, it is determined by that of this Shape's
        /// parent Set (cached here to avoid repeated lookups when iterating over Shapes)
        pub let editionType: String

        /// This Shape's metadata dictionary, which stores agreed-upon fields and generally any additional
        /// data that needs to be stored in the Shape
        access(contract) let metadata: {String: AnyStruct}

        /// The dictionary that stores the Variant-Printing pairs inside Editions to ensure there can be
        /// at most one Edition with a given Variant-Printing pair
        access(self) let variantPrintingPairsInEditions: {String: UInt64}

        /// Struct initializer
        ///
        init(
            id: Int,
            renderID: String,
            setID: Int,
            name: String,
            metadata: {String: AnyStruct}
            ) {
            self.id = id
            self.renderID = renderID
            self.setID = setID
            self.name = name
            self.closedDate = nil
            // Initialize the currentPrinting to 1, this can be incremented by the Admin
            self.currentPrinting = 1
            // Get the Edition Type from the parent Set
            self.editionType = Pinnacle.getSet(id: setID)!.editionType
            self.metadata = metadata
            self.variantPrintingPairsInEditions = {}
        }

        /// Insert the given Variant for the current printing
        ///
        access(contract) fun insertVariantPrintingPair(_ variant: String) {
            self.variantPrintingPairsInEditions[variant] = self.currentPrinting
        }

        /// Remove the given Variant
        ///
        access(contract) fun removeVariantPrintingPair(_ variant: String) {
            self.variantPrintingPairsInEditions.remove(key: variant)
        }

        /// Check if an Edition exists with the given Variant for this Shape's current printing
        ///
        access(contract) fun variantPrintingPairExistsInEdition(_ variant: String): Bool {
            return self.variantPrintingPairsInEditions[variant] == self.currentPrinting
        }

        /// Close this Shape
        ///
        access(contract) fun close() {
            pre {
                self.closedDate == nil: "Shape is already closed"
            }
            // Set the closed date to the current block timestamp plus the undo period
            self.closedDate = UInt64(getCurrentBlock().timestamp) + Pinnacle.undoPeriod
            emit ShapeClosed(
                id: self.id,
                renderID: self.renderID,
                setID: self.setID,
                name: self.name,
                currentPrinting: self.currentPrinting,
                editionType: self.editionType
            )
        }

        /// Reopen this Shape
        ///
        /// This will fail if the undo period has expired.
        ///
        access(contract) fun reopen() {
            pre {
                self.closedDate != nil: "Shape is already open"
                self.closedDate! >= UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Shape is permanently closed"
            }
            self.closedDate = nil
            emit EntityReactivated(entity: "Shape", id: self.id, name: self.name)
        }

        /// Update this Shape's name
        ///
        access(contract) fun updateName(_ name: String, _ setRef: &Set) {
            pre {
                name != "": "The name of a Shape cannot be an empty string"
                Pinnacle.getSet(id: self.setID)!.shapeNameExistsInSet(name) == false:
                    "A Shape with that name already exists in the Set"
            }
            // Remove the old name from the parent Set's shapes dictionary
            setRef.removeShapeName(self.name)
            // Update the name
            self.name = name
            // Add the new name to the parent Set's shapes dictionary
            setRef.insertShapeName(self.name)
            emit ShapeNameUpdated(
                id: self.id,
                renderID: self.renderID,
                setID: self.setID,
                name: self.name,
                currentPrinting: self.currentPrinting,
                editionType: self.editionType
            )
        }

        /// Increment this Shape's current printing and return the new value
        ///
        access(contract) fun incrementCurrentPrinting(): UInt64 {
            pre {
                self.closedDate == nil: "Cannot increment the current printing of a closed Shape"
            }
            self.currentPrinting = self.currentPrinting + 1
            emit ShapeCurrentPrintingIncremented(
                id: self.id,
                renderID: self.renderID,
                setID: self.setID,
                name: self.name,
                currentPrinting: self.currentPrinting,
                editionType: self.editionType
            )
            return self.currentPrinting
        }

        /// Return this Shape's metadata dictionary
        ///
        pub fun getMetadata(): {String: AnyStruct} {
            return self.metadata
        }

        /// Return this Shape's variantPrintingPairsInEditions dictionary
        ///
        pub fun getVariantPrintingPairsInEditions(): {String: UInt64} {
            return self.variantPrintingPairsInEditions
        }
    }

    /// Return the ID of the latest Shape created in the contract
    ///
    /// The ID is an incrementing integer equal to the length of the shapes array.
    ///
    pub fun getLatestShapeID(): Int {
        return Pinnacle.shapes.length
    }

    /// Return a Shape struct containing the data of the Shape with the given ID, if it exists in the contract
    ///
    pub fun getShape(id: Int): Shape? {
        pre {
            id > 0: "The ID of a Shape must be greater than zero"
        }
        return Pinnacle.getLatestShapeID() >= id ? Pinnacle.shapes[id - 1] : nil
    }

    /// Return all Shapes in the contract
    ///
    pub fun getAllShapes(): [Shape] {
        return Pinnacle.shapes
    }

    //------------------------------------------------------------
    // Edition
    //------------------------------------------------------------

    /// Struct that defines an Edition
    ///
    /// Each Edition is linked to a parent Shape.
    ///
    pub struct Edition {
        /// This Edition's unique ID
        pub let id: Int

        /// This Edition's renderID. The uniqueness of renderID is NOT required.
        pub var renderID: String

        /// The ID of the Series that this Edition's is linked to, it is determined by that of this Edition's
        /// parent Set (cached here to avoid repeated lookups when iterating over Editions)
        pub let seriesID: Int

        /// The ID of the Set that this Edition's is linked to, it is determined by that of this Edition's
        /// parent Shape's (cached here to avoid repeated lookups when iterating over Editions)
        pub let setID: Int

        /// The ID of the Shape that this Edition belongs to
        pub let shapeID: Int

        /// This Edition's Variant
        pub let variant: String?

        /// This Edition's Printing, determined by the current printing value of the parent Shape when the
        /// Edition is created
        pub let printing: UInt64

        /// The ID of the Edition Type that this Edition's is linked to, it is determined by that of this
        /// Edition's parent Shape (cached here to avoid repeated lookups when iterating over Editions)
        pub let editionTypeID: Int

        /// This Edition's description. It can be updated by the Admin.
        pub var description: String

        /// Attribute to denote an alternative class of Editions
        pub let isChaser: Bool

        /// This Edition's traits dictionary, which stores agreed-upon fields and generally any additional
        /// data that needs to be stored in the Edition
        access(contract) let traits: {String: AnyStruct}

        /// If the Edition is a Limited Edition, this value is the maximum number of NFTs that can be minted
        /// in the Edition - otherwise, this value is nil
        pub var maxMintSize: UInt64?

        /// The number of NFTs that have been minted in the Edition, this value is incremented every time a
        /// new NFT is minted
        pub var numberMinted: UInt64

        /// If the Edition is a Maturing Edition, this value is the time period that must pass starting from
        /// the Edition's creation date before the NFTs minted in the Edition can be withdrawn from the
        /// collection - otherwise, this value is nil
        pub let maturationPeriod: UInt64?

        /// This field indicates the Edition's closed date. This value is nil when an Edition is created.
        /// 
        /// When an Open/Unlimited Edition is closed, it is no longer possible to mint NFTs from that Edition.
        /// Closing an Open/Unlimited Edition takes immediate effect, but it can be undone during the undo
        /// period. The closedDate field indicates the date when the Edition is permanently closed.
        ///
        /// In contrast, the ability to mint NFTs from a Limited Edition is determined by the Edition's number
        /// minted being less than the Edition's max mint size. Closing a Limited Edition is only a formality
        /// allowing the admin to set the Edition's closed date to the end of the primary release sales period,
        /// once the Edition's max mint size has been reached.
        pub var closedDate: UInt64?

        /// The date that the Edition was created (Unix timestamp)
        pub let creationDate: UInt64

        /// Struct initializer
        ///
        init(
            id: Int,
            renderID: String,
            shapeID: Int,
            variant: String?,
            description: String,
            isChaser: Bool,
            maxMintSize: UInt64?,
            maturationPeriod: UInt64?,
            traits: {String: AnyStruct}
        ) {
            self.id = id
            self.renderID = renderID
            self.shapeID = shapeID
            // Get setID from the parent Shape
            self.setID = Pinnacle.getShape(id: shapeID)!.setID
            // Get seriesID from the parent Set
            self.seriesID = Pinnacle.getSet(id: self.setID)!.seriesID
            self.variant = variant
            // Get the printing from the parent Shape
            self.printing = Pinnacle.getShape(id: shapeID)!.currentPrinting
            // Get editionTypeID from the parent Shape
            self.editionTypeID = Pinnacle.getEditionTypeByName(Pinnacle.getShape(id: shapeID)!.editionType)!.id
            self.description = description
            self.isChaser = isChaser
            self.traits = traits
            self.maxMintSize = maxMintSize
            self.numberMinted = 0
            self.maturationPeriod = maturationPeriod
            self.closedDate = nil
            self.creationDate = UInt64(getCurrentBlock().timestamp)
        }

        /// Check if this Edition's max mint size has been reached
        ///
        pub fun isMaxEditionMintSizeReached(): Bool {
            return self.numberMinted == self.maxMintSize
        }

        /// Close this Edition.
        ///
        /// For Open/Unlimited Editions, closing an Edition is necessary to set the Edition's max mint size
        /// to the number minted, so that no more pin NFTs can be minted from it.
        ///
        /// For a Limited Edition, closing an Edition is only a formality allowing the admin to set the
        /// Edition's closed date. A Limited Edition can be closed only once the Edition's max mint size has
        /// been reached.
        ///
        /// This will fail if the Edition is already closed.
        ///
        access(contract) fun close() {
            pre {
                self.closedDate == nil: "This Edition is already closed, number of pins minted: "
                    .concat(self.numberMinted!.toString())
                (Pinnacle.getEditionType(id: self.editionTypeID)!.isLimited == false ||
                    self.isMaxEditionMintSizeReached()):
                        "The Edition must be an Open/Unlimited Edition or a Limited Edition that has reached its max mint size"
            }
            // Set the max mint size to the number minted
            self.maxMintSize = self.numberMinted
            // Set the closed date to the current block timestamp plus the undo period
            self.closedDate = UInt64(getCurrentBlock().timestamp) + Pinnacle.undoPeriod
            emit EditionClosed(
                id: self.id,
                maxMintSize: self.maxMintSize!
            )
        }

        /// Reopen this Edition
        ///
        /// This will fail if the Edition if a Limited Edition or if the undo period has expired.
        ///
        access(contract) fun reopen() {
            pre {
                self.closedDate != nil: "Edition is already open"
                self.closedDate! >= UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Edition Type is permanently closed"
                Pinnacle.getEditionType(id: self.editionTypeID)!.isLimited == false:
                    "The Edition must be an Open/Unlimited Edition"
            }
            self.maxMintSize = nil
            self.closedDate = nil
            emit EntityReactivated(entity: "Edition", id: self.id, name: nil)
        }

        /// Increment this Edition's number minted
        ///
        /// This is only called when a Pin NFT is minted in the Edition.
        ///
        access(contract) fun incrementNumberMinted() {
            self.numberMinted = self.numberMinted + 1
        }

        /// Decrement this Edition's number minted
        ///
        /// This is only called from the burnOpenEditionNFT Admin function.
        ///
        access(contract) fun decrementNumberMinted() {
            pre {
                self.numberMinted != self.maxMintSize:
                    "This Edition must not have been closed"
                Pinnacle.getEditionType(id: self.editionTypeID)!.isLimited == false:
                    "The Edition must be an Open/Unlimited Edition"
            }
            self.numberMinted = self.numberMinted - 1
        }

        /// Return the serial number of the NFT to be minted, the Edition's number minted + 1 if the Edition
        /// is limited, nil otherwise.
        ///
        access(contract) fun getNextSerialNumber(): UInt64? {
            return Pinnacle.getEditionType(id: self.editionTypeID)!.isLimited ? self.numberMinted + 1 : nil
        }

        /// Update this Edition's description
        ///
        access(contract) fun updateDescription(_ description: String) {
            self.description = description
            emit EditionDescriptionUpdated(
                id: self.id,
                description: self.description
            )
        }

        /// Update this Edition's Render ID
        ///
        access(contract) fun updateRenderID(_ renderID: String) {
            self.renderID = renderID
            emit EditionRenderIDUpdated(
                id: self.id,
                renderID: self.renderID
            )
        }

        /// Return this Edition's traits dictionary
        ///
        pub fun getTraits(): {String: AnyStruct} {
            return self.traits
        }
    }

    /// Return the ID of the latest Edition created in the contract.
    ///
    /// The ID is an incrementing integer equal to the length of the editions array.
    ///
    pub fun getLatestEditionID(): Int {
        return Pinnacle.editions.length
    }

    /// Return an Edition struct containing the data of the Edition with the given ID, if it exists in the
    /// contract
    ///
    pub fun getEdition(id: Int): Edition? {
        pre {
            id > 0: "The ID of an Edition must be greater than 0"
        }
        return Pinnacle.getLatestEditionID() >= id ? Pinnacle.editions[id - 1] : nil
    }

    /// Return all Editions in the contract
    ///
    pub fun getAllEditions(): [Edition] {
        return Pinnacle.editions
    }

    //------------------------------------------------------------
    // Edition Type
    //------------------------------------------------------------

    /// Struct that defines an Edition Type
    ///
    /// Each Edition Type is created independently of any other entity.
    ///
    /// The contract creates the following default Edition Types during initialization: "Genesis Edition",
    /// "Unique Edition", "Limited Edition", "Open Edition", "Starter Edition", and "Event Edition".
    ///
    pub struct EditionType {
        /// This Edition Type's unique ID
        pub let id: Int

        /// This Edition Type's unique name
        pub let name: String

        /// Indicate if the Edition Type is Limited (true) or Open/Unlimited (false)
        pub let isLimited: Bool

        /// Indicate if the Edition Type is Maturing (true) or Non-Maturing (false)
        pub let isMaturing: Bool

        /// This field indicates whether the Edition Type is currently open (closedDate is nil) or closed (has
        /// actual date).
        ///
        /// Initially, when an Edition Type is created, it is in an open state, allowing the creation of Sets.
        /// Once an Edition Type is closed, it is no longer possible to create Sets linked to that Edition
        /// Type as well as Shapes linked to those Sets and Editions linked to those Shapes. However, it is
        /// still possible to mint NFTs using the Editions already created from any Shapes. Locking an Edition
        /// Type takes immediate effect, but it can be undone during the undo period. The closedDate field
        /// indicates the date when the Edition Type is permanently closed, including the undo period.
        pub var closedDate: UInt64?

        /// Struct initializer
        ///
        init(id: Int, name: String, isLimited: Bool, isMaturing: Bool) {
            self.id = id
            self.name = name
            self.isLimited = isLimited
            self.isMaturing = isMaturing
            self.closedDate = nil
        }

        /// Close this Edition Type
        ///
        access(contract) fun close() {
            pre {
                self.closedDate == nil: "Edition type is already closed"
            }
            // Set the closed date to the current block timestamp plus the undo period
            self.closedDate = UInt64(getCurrentBlock().timestamp) + Pinnacle.undoPeriod
            emit EditionTypeClosed(
                id: self.id,
                name: self.name,
                isLimited: self.isLimited,
                isMaturing: self.isMaturing
            )
        }

        /// Reopen this Edition Type
        ///
        /// This will fail if the undo period has expired.
        ///
        access(contract) fun reopen() {
            pre {
                self.closedDate != nil: "Edition Type is already open"
                self.closedDate! >= UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Edition Type is permanently closed"
            }
            self.closedDate = nil
            emit EntityReactivated(entity: "EditionType", id: self.id, name: self.name)
        }
    }

    /// Return the ID of the latest Edition Type created in the contract
    ///
    /// The ID is an incrementing integer equal to the length of the editionTypes array.
    ///
    pub fun getLatestEditionTypeID(): Int {
        return Pinnacle.editionTypes.length
    }

    /// Return an EditionType struct containing the data of the EditionType with the given ID, if it exists
    /// in the contract
    ///
    pub fun getEditionType(id: Int): EditionType? {
        pre {
            id > 0: "The ID of an Edition Type must be greater than 0"
        }
        return Pinnacle.getLatestEditionTypeID() >= id ? Pinnacle.editionTypes[id - 1] : nil
    }

    /// Return all Edition Types in the contract
    ///
    pub fun getAllEditionTypes(): [EditionType] {
        return Pinnacle.editionTypes
    }

    /// Return an EditionType struct containing the data of the EditionType with the given name, if it exists
    /// in the contract
    ///
    pub fun getEditionTypeByName(_ name: String): EditionType? {
        if let id = Pinnacle.editionTypeIDsByName[name] {
            return Pinnacle.getEditionType(id: id)
        }
        return nil
    }

    /// Return the ID of the Edition Type with the given name, if it exists in the contract
    ///
    pub fun getEditionTypeIDByName(_ name: String): Int? {
        return Pinnacle.editionTypeIDsByName[name]
    }

    //------------------------------------------------------------
    // Inscription
    //------------------------------------------------------------

    /// Struct that defines an Inscription
    ///
    /// Inscriptions are stored in NFTs.
    ///
    pub struct Inscription {
        /// This Inscription's ID, unique inside an NFT
        pub let id: Int

        /// The address of the account that added the Inscription, unique inside an NFT
        pub let thenOwner: Address

        /// The note that can be added to the Inscription
        pub var note: String?

        /// The date the Inscription was added to the NFT
        pub let dateAdded: UInt64

        /// This Inscription's extension dictionary, which stores any additional data that needs to be stored
        /// in the Inscription. This field has been added to accommodate potential future contract updates and
        /// facilitate new functionalities. It is not in use currently.
        access(self) let extension: {String: AnyStruct}

        /// Struct initializer
        ///
        init(
            id: Int,
            owner: Address,
            extension: {String: AnyStruct}?
        ) {
            self.id = id
            self.thenOwner = owner
            self.note = nil
            self.dateAdded = UInt64(getCurrentBlock().timestamp)
            self.extension = extension ?? {}
        }

        /// Set this Inscription's note
        ///
        access(contract) fun setNote(_ note: String?) {
            self.note = note
        }

        /// Return this Inscription's extension dictionary
        ///
        pub fun getExtension(): {String: AnyStruct} {
            return self.extension
        }
    }

    //------------------------------------------------------------
    // NFT
    //------------------------------------------------------------

    /// Resource that defines a Pin NFT
    ///
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        /// This NFT's unique ID
        pub let id: UInt64

        /// This NFT's unique renderID. The uniqueness of renderID is not required.
        pub let renderID: String

        /// The ID of the Edition that this NFT belongs to
        pub let editionID: Int

        /// This NFT' serial number - nil if the NFT has not been minted from a Limited Edition
        pub let serialNumber: UInt64?

        /// The date that this NFT was minted (Unix timestamp)
        pub let mintingDate: UInt64

        /// This NFT's experience points balance - nil if the NFT's owner has opted out
        pub var xp: UInt64?

        /// The array where this NFT's Inscriptions are stored
        access(self) let inscriptions: [Inscription]

        /// The dictionary that allows Inscriptions to be looked up by address
        access(self) let inscriptionIDsByAddress: {Address: Int}

        /// This NFT's extension dictionary, which stores any additional data that needs to be stored in the
        /// NFT. This field has been added to accommodate potential future contract updates and facilitate new
        /// functionalities. It is not in use currently.
        access(self) let extension: {String: AnyStruct}

        /// NFT initializer
        ///
        init(editionID: Int, extension: {String: AnyStruct}?) {
            pre {
                // Check that the Edition exists and has not reached its max mint size
                Pinnacle.getLatestEditionID() >= editionID: "editionID does not exist"
                Pinnacle.getEdition(id: editionID)!.isMaxEditionMintSizeReached() == false:
                    "Max mint size (".concat(Pinnacle.getEdition(id: editionID)!.maxMintSize!.toString())
                        .concat(") reached for Edition ID = ").concat(editionID.toString())
            }
            self.id = self.uuid
            self.renderID = Pinnacle.getEdition(id: editionID)!.renderID
            self.editionID = editionID
            self.serialNumber = Pinnacle.getEdition(id: editionID)!.getNextSerialNumber()
            self.mintingDate = UInt64(getCurrentBlock().timestamp)
            self.xp = 0
            self.inscriptions = []
            self.inscriptionIDsByAddress = {}
            self.extension = extension ?? {}
            Pinnacle.totalSupply = Pinnacle.totalSupply + 1
            emit PinNFTMinted(
                id: self.id,
                renderID: self.renderID,
                editionID: self.editionID,
                serialNumber: self.serialNumber,
                maturityDate: self.getMaturityDate()
            )
        }

        /// NFT destructor
        ///
        destroy() {
            Pinnacle.totalSupply = Pinnacle.totalSupply - 1
            emit PinNFTBurned(
                id: self.id,
                editionID: self.editionID,
                serialNumber: self.serialNumber,
                xp: self.xp
            )
        }

        /// Return this NFT's maturity date if it is a Maturing Edition NFT, nil otherwise
        ///
        pub fun getMaturityDate(): UInt64? {
            let edition = Pinnacle.getEdition(id: self.editionID)!
            return edition.maturationPeriod != nil ? edition.creationDate + edition.maturationPeriod! : nil
        }

        /// Return if this NFT's is locked by maturity date. 
        /// Return true if the current block timestamp is less than the lock expiry, false otherwise.
        pub fun isLocked(): Bool {
            if let maturityDate = self.getMaturityDate() {
                return maturityDate > UInt64(getCurrentBlock().timestamp)
            }
            return false
        }


        /// Return this NFT's inscriptions limit
        ///
        pub fun getInscriptionsLimit(): Int {
            return Pinnacle.inscriptionsLimits[self.id] ?? 100
        }

        /// Add an Inscription in this NFT tied to the current owner address and return its ID
        ///
        /// This function can only be called from the Collection resource that contains this NFT. It will
        /// fail if the Inscription was already added by the current owner or if the NFT has reached its
        /// max inscriptions size, which is 100 by default and can be set to a higher value by the Admin.
        ///
        access(contract) fun addCurrentOwnerInscription(_ currentOwner: Address): Int {
            pre {
                self.inscriptionIDsByAddress.containsKey(currentOwner) == false:
                    "The Inscription was already added by the current owner, date added: "
                        .concat(self.inscriptions[self.inscriptionIDsByAddress[currentOwner]!]!.dateAdded.toString())
                self.getLatestInscriptionID() < self.getInscriptionsLimit():
                    "Max Inscriptions size (".concat((self.getInscriptionsLimit()).toString())
                        .concat(") reached for NFT ID = ").concat(self.id.toString())
            }
            let inscription = Inscription(
                id: self.getLatestInscriptionID() + 1,
                owner: currentOwner,
                extension: nil
            )
            self.inscriptions.append(inscription)
            self.inscriptionIDsByAddress[currentOwner] = inscription.id
            emit NFTInscriptionAdded(
                id: inscription.id,
                owner: inscription.thenOwner,
                note: inscription.note,
                nftID: self.id,
                editionID: self.editionID
            )
            return inscription.id
        }

        /// Return a reference to the Inscription with the given ID, if it exists in the NFT
        ///
        access(contract) fun borrowInscription(id: Int): &Inscription? {
            pre {
                id > 0: "The ID of an Inscription must be greater than 0"
            }
            return self.getLatestInscriptionID() >= id ? &self.inscriptions[id - 1] as &Inscription : nil
        }

        /// Remove the current owner's Inscription from this NFT
        ///
        /// This will fail if the undo period has expired or if another Inscription has been added after the
        /// current owner's.
        ///
        access(contract) fun removeCurrentOwnerInscription(_ currentOwner: Address) {
            pre {
                self.inscriptionIDsByAddress.containsKey(currentOwner) == true:
                    "No Inscription added by the current owner"
                self.getInscriptionByAddress(currentOwner)!.id == self.getLatestInscriptionID():
                    "The Inscription to remove must be the last one added"
                self.getInscriptionByAddress(currentOwner)!.dateAdded + Pinnacle.undoPeriod >=
                    UInt64(getCurrentBlock().timestamp):
                    "Undo period has expired, Inscription is permanently added"
            }
            let inscriptionID = self.getInscriptionIDsByAddress(currentOwner)!
            self.inscriptions.removeLast()
            self.inscriptionIDsByAddress.remove(key: currentOwner)
            emit NFTInscriptionRemoved(
                id: inscriptionID,
                owner: currentOwner,
                nftID: self.id,
                editionID: self.editionID
            )
        }

        /// Update the current owner's Inscription note in this NFT
        ///
        /// This function can only be called from the Collection resource that contains this NFT and requires
        /// Admin co-signing.
        ///
        access(contract) fun updateCurrentOwnerInscriptionNote(currentOwner: Address, note: String) {
            pre {
                self.inscriptionIDsByAddress.containsKey(currentOwner) == true:
                    "Inscription must have been added by the current owner"
            }
            let inscriptionRef = self.borrowInscription(
                id: self.getInscriptionIDsByAddress(currentOwner)!
            )!
            inscriptionRef.setNote(note)
            emit NFTInscriptionUpdated(
                id: inscriptionRef.id,
                owner: currentOwner,
                note: inscriptionRef.note,
                nftID: self.id,
                editionID: self.editionID
            )
        }

        /// Toggle this NFT's ability to hold a XP balance (turned on by default) and return the XP's new value
        ///
        /// This function can only be called from the Collection resource that contains this NFT.
        ///
        /// This allows opting in or out of the NFT's ability to hold XP. If XP is nil, this will set it to 0.
        /// If XP is 0, this will set it to nil.
        ///
        access(contract) fun toggleXP(): UInt64? {
            self.xp = self.xp == nil ? 0 : nil
            emit NFTXPUpdated(id: self.id, editionID: self.editionID, xp: self.xp)
            return self.xp
        }

        /// Add experience points to this NFT and return the new XP balance
        ///
        /// This function can only be called from the Admin resource with the condition that the NFT owner
        /// has not opted out of the NFT's ability to hold XP with the toggleXP function.
        ///
        access(contract) fun addXP(_ value: UInt64): UInt64 {
            pre {
                self.xp != nil: "XP must have been previously set by the owner"
            }
            self.xp = self.xp! + value
            emit NFTXPUpdated(id: self.id, editionID: self.editionID, xp: self.xp)
            return self.xp!
        }

        /// Subtract experience points from this NFT and return the new XP balance
        ///
        /// This function can only be called from the Admin resource with the condition that the NFT owner
        /// has not opted out of the NFT's ability to hold XP with the toggleXP function.
        ///
        access(contract) fun subtractXP(_ value: UInt64): UInt64 {
            pre {
                self.xp != nil: "XP must have been previously set by the owner"
                self.xp! >= value:
                    "Cannot subtract below minimum XP of 0, current XP: ".concat(self.xp!.toString())
            }
            self.xp = self.xp! - value
            emit NFTXPUpdated(id: self.id, editionID: self.editionID, xp: self.xp)
            return self.xp!
        }

        /// Return the ID of the latest Inscription added in the NFT
        ///
        /// The ID is an incrementing integer equal to the length of the inscriptions array.
        ///
        pub fun getLatestInscriptionID(): Int {
            return self.inscriptions.length
        }

        /// Return an Inscription struct containing the data of the Inscription with the given ID, if it
        /// exists in the NFT
        ///
        pub fun getInscription(id: Int): Inscription? {
            pre {
                id > 0: "The ID of an Inscription must be greater than 0"
            }
            return self.getLatestInscriptionID() >= id ? self.inscriptions[id - 1] : nil
        }

        /// Return all Inscriptions in the NFT
        ///
        pub fun getAllInscriptions(): [Inscription] {
            return self.inscriptions
        }

        /// Return an Inscription struct containing the data of the Inscription with the given address if it
        /// exists in the NFT
        ///
        pub fun getInscriptionByAddress(_ address: Address): Inscription? {
            if let id = self.inscriptionIDsByAddress[address] {
                return self.getInscription(id: id)
            }
            return nil
        }

        /// Return the ID of the Inscription with the given address, if it exists in the NFT
        ///
        pub fun getInscriptionIDsByAddress(_ address: Address): Int? {
            return self.inscriptionIDsByAddress[address]
        }

        /// Return this NFT's inscriptionIDsByAddress dictionary
        ///
        pub fun getAllInscriptionIDsByAddresses(): {Address: Int} {
            return self.inscriptionIDsByAddress
        }

        /// Return this NFT's extension dictionary
        ///
        pub fun getExtension(): {String: AnyStruct} {
            return self.extension
        }

        /// Return the metadata view types available for this NFT
        ///
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Traits>(),
                Type<MetadataViews.Medias>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>()
            ]
        }

        /// Resolve this NFT's metadata views
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            post {
                result == nil || result!.getType() == view:
                    "The returned view must be of the given type or nil"
            }
            switch view {
                case Type<MetadataViews.Display>(): return self.resolveDisplayView()
                case Type<MetadataViews.ExternalURL>(): return self.resolveExternalURLView()
                case Type<MetadataViews.Traits>(): return self.resolveTraitsView()
                case Type<MetadataViews.Medias>(): return self.resolveMediasView()
                case Type<MetadataViews.Editions>(): return self.resolveEditionsView()
                case Type<MetadataViews.Serial>(): return self.resolveSerialView()
                case Type<MetadataViews.Royalties>(): return self.resolveRoyaltiesView()
                case Type<MetadataViews.NFTCollectionDisplay>(): return Pinnacle.resolveNFTCollectionDisplayView()
                case Type<MetadataViews.NFTCollectionData>(): return Pinnacle.resolveNFTCollectionDataView()
            }
            return nil
        }

        /// Resolve this NFT's Display view
        ///
        pub fun resolveDisplayView(): MetadataViews.Display {
            return MetadataViews.Display(
                name: self.getName(),
                description: self.getDescription(),
                thumbnail: self.getThumbnailPath()
            )
        }

        /// Resolve this NFT's ExternalURL view
        ///
        pub fun resolveExternalURLView(): MetadataViews.ExternalURL {
            return MetadataViews.ExternalURL("https://disneypinnacle.com")
        }

        /// Resolve this NFT's Traits view
        ///
        pub fun resolveTraitsView(): MetadataViews.Traits {
            // Retrieve this NFT's parent Edition, Shape, Set, and Series data
            let edition = Pinnacle.getEdition(id: self.editionID)!
            let shape = Pinnacle.getShape(id: edition.shapeID)!
            let set = Pinnacle.getSet(id: edition.setID)!
            let series = Pinnacle.getSeries(id: edition.seriesID)!
            // Create a dictionary of this NFT's traits with the default metadata entries
            let traits: {String: AnyStruct} = {
                "EditionType" : Pinnacle.getEditionType(id: edition.editionTypeID)!.name,
                "SeriesName" : series.name,
                "SetName" : set.name,
                "IsChaser" : edition.isChaser,
                "Printing": edition.printing,
                "MintingDate": self.mintingDate
            }
            // If the Edition has a Variant, add the Variant trait
            if edition.variant != nil {
                traits["Variant"] = edition.variant!
            }
            // If the NFT is a Limited Edition NFT, add the SerialNumber trait
            if self.serialNumber != nil {
                traits["SerialNumber"] = self.serialNumber!
            }
            // If the NFT's Edition is a Maturing Edition, add the MaturityDate trait
            if edition.maturationPeriod != nil {
                traits["MaturityDate"] = self.getMaturityDate()!
            }
            // Add the Shape's metadata entries
            for key in shape.metadata.keys {
                traits[key] = shape.metadata[key]
            }
            // Add the Edition's traits entries
            for key in edition.traits.keys {
                traits[key] = edition.traits[key]
            }
            // Return the traits dictionary
            return MetadataViews.dictToTraits(dict: traits, excludedNames: nil)
        }

        /// Resolve this NFT's Medias view
        ///
        pub fun resolveMediasView(): MetadataViews.Medias {
            return MetadataViews.Medias(
                items: [
                    MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: "https://assets.disneypinnacle.com/on-chain/pinnacle.jpg"),
                        mediaType: "image/jpg"
                    )
                ]
            )
        }

        /// Resolve this NFT's Editions view
        ///
        pub fun resolveEditionsView(): MetadataViews.Editions {
            let edition = Pinnacle.getEdition(id: self.editionID)!
            let shape = Pinnacle.getShape(id: edition.shapeID)!
            let set = Pinnacle.getSet(id: edition.setID)!
            // Assemble the name
            let editionName = shape.name.concat(" [").concat(set.name)
                .concat(edition.variant != nil ? ", ".concat(edition.variant!) : "")
                .concat(edition.printing > 1 ? ", Printing #".concat(edition.printing.toString()) : "")
                .concat("]")
            // Create and return the Editions view
            return MetadataViews.Editions(
                [MetadataViews.Edition(
                    name: editionName,
                    number: self.serialNumber ?? 0,
                    max: edition.maxMintSize
                    )
                ]
            )
        }

        /// Resolve this NFT's Serial view if it is a Limited Edition NFT - return nil otherwise
        ///
        pub fun resolveSerialView(): MetadataViews.Serial? {
            return Pinnacle.getEditionType(id: Pinnacle.getEdition(id: self.editionID)!.editionTypeID)!.isLimited ?
                MetadataViews.Serial(self.serialNumber!) : nil
        }

        /// Resolve this NFT's Royalties view
        ///
        pub fun resolveRoyaltiesView(): MetadataViews.Royalties {
            let royaltyReceiver: Capability<&AnyResource{FungibleToken.Receiver}> =
                getAccount(Pinnacle.royaltyAddress).getCapability<&AnyResource{FungibleToken.Receiver}>(
                    MetadataViews.getRoyaltyReceiverPublicPath())
            return MetadataViews.Royalties(
                royalties: [
                    MetadataViews.Royalty(
                        receiver: royaltyReceiver,
                        cut: 0.05,
                        description: "placeholder_royalty_description"
                    )
                ]
            )
        }

        /// Return this NFT's name
        ///
        pub fun getName(): String {
            // Retrieve this NFT's parent Edition, Shape, and Set data
            let edition = Pinnacle.getEdition(id: self.editionID)!
            let shape = Pinnacle.getShape(id: edition.shapeID)!
            let set = Pinnacle.getSet(id: edition.setID)!
            // Assemble and return the name
            return shape.name.concat(self.serialNumber != nil ? " [#".concat(self.serialNumber!.toString())
                .concat("/").concat(edition.maxMintSize!.toString()).concat("] [") : " [").concat(set.name)
                .concat(edition.variant != nil ? ", ".concat(edition.variant!) : "")
                .concat(edition.printing > 1 ? ", Printing #".concat(edition.printing.toString()) : "")
                .concat("]")
        }

        /// Return this NFT's description
        ///
        /// The description is composed of the end-user license URL, the description of this NFT's Edition,
        /// and this NFT's concatenated Inscription notes if there any, ordered by the date they have been
        /// added. It is generally intended that the Inscription notes are human-readable and that they are
        /// written in a way that makes sense when concatenated, avoiding escape chars and with each
        /// Inscription's details included as needed. Inscription notes require both the owner's and the
        /// Admin's approval to be updated (see the updateNFTInscriptionNote function in the Collection
        /// resource).
        ///
        pub fun getDescription(): String {
            var notes = ""
            for inscription in self.inscriptions {
                // If the Inscription is permanently added and has a note, add it to the notes string
                if inscription.dateAdded + Pinnacle.undoPeriod < UInt64(getCurrentBlock().timestamp) {
                    if let note = inscription.note {
                        notes.concat("\n\n").concat(note)
                    }
                }
            }
            var header = ""
            if let caption = Pinnacle.extension["EndUserLicenseCaption"] as! String? {
                header = header.concat(caption).concat(": ")
            }
            header = header.concat(Pinnacle.endUserLicenseURL)
            return header.concat("\n\n")
                .concat(Pinnacle.getEdition(id: self.editionID)!.description)
                .concat(notes != "" ? "\n\n".concat(notes) : "")
        }

        /// Return this NFT's thumbnail path
        ///
        pub fun getThumbnailPath(): MetadataViews.HTTPFile {
            return MetadataViews.HTTPFile(url:"https://assets.disneypinnacle.com/on-chain/pinnacle.jpg")
        }

        /// Return an asset path
        ///
        pub fun getAssetPath(): String {
            return "placeholder_pinnacle_base_asset_path"
        }

        /// Return an image path
        ///
        pub fun getImagePath(): String {
            return "placeholder_image_path"
        }

        /// Return a video path
        ///
        pub fun getVideoPath(): String {
            return "placeholder_video_path"
        }

        /// Return a Pin path
        ///
        pub fun getPinPath(): String {
            return "placeholder_pinnacle_pin_path"
        }
    }

    //------------------------------------------------------------
    // Collection
    //------------------------------------------------------------

    /// A public Collection interface that allows Pin NFTs to be borrowed
    ///
    pub resource interface PinNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT?
        pub fun borrowPinNFT(id: UInt64): &Pinnacle.NFT?
    }

    /// Resource that defines a Pinnacle NFT Collection
    ///
    pub resource Collection:
        NonFungibleToken.Provider,
        NonFungibleToken.Receiver,
        NonFungibleToken.CollectionPublic,
        MetadataViews.ResolverCollection,
        PinNFTCollectionPublic
    {
        /// Dictionary of NFT conforming tokens
        /// NFT is a resource type with a UInt64 ID field
        ///
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        /// Collection initializer
        ///
        init() {
            self.ownedNFTs <- {}
        }

        /// Collection destructor
        ///
        destroy() {
            destroy self.ownedNFTs
        }

        /// Remove an NFT from the Collection and move it to the caller
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("No NFT with such ID in the Collection")
            let nft <- token as! @NFT
            // If the NFT was minted from a Maturing Edition, check that the Edition's maturation period has
            // expired counting from the Edition's creation date - if not, the NFT cannot be withdrawn yet.
            // The Edition's maturation period is a parameter provided when creating the Edition that cannot
            // be changed later and the creation date is set to the timestamp of the block where the Edition
            // is created.
            if let maturityDate = nft.getMaturityDate() {
                assert(maturityDate <= UInt64(getCurrentBlock().timestamp),
                    message: "This is a Maturing Edition NFT for which the maturation period has not expired yet, maturity date: "
                        .concat(maturityDate.toString()).concat(", current timestamp: ")
                        .concat(UInt64(getCurrentBlock().timestamp).toString()))
            }
            emit Withdraw(id: nft.id, from: self.owner?.address)
            return <- nft
        }

        /// Withdraw the tokens with given IDs and returns them as a Collection
        ///
        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create an empty Collection
            var batchCollection <- create Collection()
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            // Return the withdrawn tokens
            return <- batchCollection
        }

        /// Deposit an NFT into this Collection
        ///
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Pinnacle.NFT
            let id: UInt64 = token.id
            // Add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        /// Deposit the NFTs from a Collection into this Collection
        ///
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {
            // Iterate through the NFT IDs in the Collection
            for id in tokens.ownedNFTs.keys {
                self.deposit(token: <- tokens.withdraw(withdrawID: id))
            }
            // Destroy the empty Collection
            destroy tokens
        }

        /// Add an Inscription in the NFT with the specified ID for the current owner and return the
        /// Inscription ID. The Inscription becomes permanent after the undo period has expired.
        ///
        pub fun addNFTInscription(id: UInt64): Int {
            pre {
                self.owner != nil: "Collection must be owned by an account"
            }
            return self.borrowPinNFT(id: id)!.addCurrentOwnerInscription(self.owner!.address)
        }

        /// Remove the current owner's Inscription from the NFT with the specified ID
        ///
        /// This will fail if the undo period has expired or if another Inscription has been added after the
        /// current owner's.
        ///
        pub fun removeNFTInscription(id: UInt64) {
            self.borrowPinNFT(id: id)!.removeCurrentOwnerInscription(self.owner!.address)
        }

        /// Update the note in the current owner's Inscription in the NFT with the specified ID. This requires
        /// Admin co-signing in the form of passing a reference to the Admin resource, and is generally
        /// intended to be called only when adding a note to the Inscription for the first time or appending
        /// to an existing note, with the content of the note being human-readable and sanitized off-chain.
        /// The note is part of the NFT's description returned in the Display view (see the getDescription
        /// function in the NFT resource).
        ///
        /// This will fail if the Inscription was not previously added by the current owner.
        ///
        pub fun updateNFTInscriptionNote(id: UInt64, note: String, adminRef: &Admin) {
            self.borrowPinNFT(id: id)!.updateCurrentOwnerInscriptionNote(
                currentOwner: self.owner!.address,
                note: note
            )
        }

        /// Toggle the XP of the NFT with the specified ID and return the new XP value.
        ///
        /// If this NFT's XP has been previously activated, this will deactivate it. It will remain possible
        /// to reactivate XP but XP will be reinitialized to 0.
        ///
        pub fun toggleNFTXP(id: UInt64): UInt64? {
            return self.borrowPinNFT(id: id)!.toggleXP()
        }

        /// Activate or deactivate the XP of all the NFTs in this Collection
        ///
        pub fun batchToggleXP(_ activateAll: Bool) {
            // Iterate through the NFT IDs in the Collection
            for id in self.ownedNFTs.keys {
                let nftRef = self.borrowPinNFT(id: id)!
                if activateAll && nftRef.xp == nil || !activateAll && nftRef.xp != nil {
                    nftRef.toggleXP()
                }
            }
        }

        /// Return an array of the NFT IDs that are in the Collection
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Return a reference to an NFT in the Collection
        ///
        /// This function panics if the NFT does not exist in this Collection.
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            let nftRef = self.borrowNFTSafe(id: id)
                ?? panic("Could not borrow a reference to the NFT with the specified ID")
            return nftRef
        }

        /// Return a reference to an NFT in the Collection
        ///
        /// This function returns nil if the NFT does not exist in this Collection.
        ///
        pub fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT?
        }

        /// Return a reference to an NFT in the Collection typed as Pinnacle.NFT
        ///
        /// This function returns nil if the NFT does not exist in this Collection.
        ///
        /// This function exposes all Pinnacle.NFT's fields and functions, though there are functions that
        /// modify the xp and inscriptions fields and those functions are declared with the access(contract)
        /// modifier so that they can only be called in the scope of this contract through the corresponding
        /// wrapper functions defined in the Collection and Admin resources.
        ///
        pub fun borrowPinNFT(id: UInt64): &Pinnacle.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let nftRef = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return nftRef as! &Pinnacle.NFT
            }
            return nil
        }

        /// Return a reference to an NFT in this Collection typed as MetadataViews.Resolver
        ///
        /// This function panics if the NFT does not exist in this Collection.
        ///
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nftRef = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            return nftRef as! &Pinnacle.NFT
        }
    }

    /// Create an empty Collection for Pinnacle NFTs and return it to the caller
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// Return a Collection Public reference to the Collection owned by the account with the specified address
    ///
    pub fun borrowCollectionPublic(
        owner: Address,
        _ publicPathID: String?
    ): &Pinnacle.Collection{Pinnacle.PinNFTCollectionPublic}? {
        return getAccount(owner).getCapability(
            publicPathID != nil ? PublicPath(identifier: publicPathID!)! : Pinnacle.CollectionPublicPath)
                .borrow<&Pinnacle.Collection{Pinnacle.PinNFTCollectionPublic}>()
    }

    //------------------------------------------------------------
    // Admin
    //------------------------------------------------------------

    /// Interface to mediate NFT minting from the Admin resource
    ///
    pub resource interface NFTMinter {
        pub fun mintNFT(editionID: Int, extension: {String: String}?): @Pinnacle.NFT
    }

    /// Resource that defines an Admin
    ///
    /// The Admin allows managing entities in the contract and minting Pinnacle NFTs.
    ///
    pub resource Admin: NFTMinter {
        /// Create a Series and return its ID
        ///
        /// This is irreversible, it will not be possible to remove the Series once it is created
        /// (no undo period).
        ///
        pub fun createSeries(name: String): Int {
            pre {
                name != "": "The name of a Series cannot be an empty string"
                Pinnacle.seriesIDsByName.containsKey(name) == false: "A Series with that name already exists"
            }
            let series = Series(id: Pinnacle.getLatestSeriesID() + 1, name: name)
            Pinnacle.series.append(series)
            Pinnacle.seriesIDsByName[name] = series.id
            emit SeriesCreated(id: series.id, name: series.name)
            return series.id
        }

        /// Return a reference to the Series with the given ID, if it exists in the contract
        ///
        access(self) fun borrowSeries(id: Int): &Series? {
            pre {
                id > 0: "The ID of a Series must be greater than 0"
            }
            return Pinnacle.getLatestSeriesID() >= id ? &Pinnacle.series[id - 1] as &Series : nil
        }

        /// Lock a Series
        ///
        /// This is irreversible after the undo period is over. It will not be possible to create new Sets in
        /// the Series.
        ///
        /// @param id: The ID of the Series to lock.
        /// @param undo: A boolean to indicate whether to unlock the Series within the undo period.
        ///
        pub fun lockSeries(id: Int, undo: Bool) {
            undo ? self.borrowSeries(id: id)!.unlock() : self.borrowSeries(id: id)!.lock()
        }

        /// Update a Series's name
        ///
        pub fun updateSeriesName(id: Int, name: String) {
            self.borrowSeries(id: id)!.updateName(name)
        }

        /// Create a Set and return its ID
        ///
        /// This is irreversible, it will not be possible to remove the Set once it is created
        /// (no undo period).
        ///
        pub fun createSet(renderID: String, name: String, editionType: String, seriesID: Int): Int {
            pre {
                // Check that renderID is valid
                (renderID != ""): "The renderID of a Set cannot be an empty string"
                // Check that name is valid
                name != "": "The name of a Set cannot be an empty string"
                Pinnacle.setIDsByName.containsKey(name) == false: "A Set with that name already exists"
                // Check that editionType is valid
                Pinnacle.editionTypeIDsByName.containsKey(editionType): "No such Edition Type"
                Pinnacle.getEditionTypeByName(editionType)!.closedDate == nil: "Edition Type is closed"
                // Check that seriesID is valid
                Pinnacle.getLatestSeriesID() >= seriesID: "seriesID does not exist"
                Pinnacle.getSeries(id: seriesID)!.lockedDate == nil:
                    "Cannot create a Set linked to a locked Series"
            }
            let set = Set(
                id: Pinnacle.getLatestSetID() + 1,
                renderID: renderID,
                name: name,
                editionType: editionType,
                seriesID: seriesID
            )

            emit SetCreated(id: set.id, renderID: set.renderID, name: set.name, seriesID: set.seriesID, editionType: set.editionType)
            Pinnacle.sets.append(set)
            Pinnacle.setIDsByName[name] = set.id
            emit SetCreated(id: set.id, renderID: set.renderID, name: set.name, seriesID: set.seriesID, editionType: set.editionType)
            return set.id
        }

        /// Return a reference to the Set with the given ID, if it exists in the contract
        ///
        access(self) fun borrowSet(id: Int): &Set? {
            pre {
                id > 0: "The ID of a Set must be greater than 0"
            }
            return Pinnacle.getLatestSetID() >= id ? &Pinnacle.sets[id - 1] as &Set : nil
        }

        /// Lock a Set
        ///
        /// This is irreversible after the undo period is over. It will not be possible to create new Shapes
        /// in the Set.
        ///
        /// @param id: The ID of the Set to lock.
        /// @param undo: A boolean to indicate whether to unlock the Set within the undo period.
        ///
        pub fun lockSet(id: Int, undo: Bool) {
            undo ? self.borrowSet(id: id)!.unlock() : self.borrowSet(id: id)!.lock()
        }

        /// Update a Set's name
        ///
        pub fun updateSetName(id: Int, name: String) {
            self.borrowSet(id: id)!.updateName(name)
        }

        /// Create a Shape and return its ID
        ///
        /// This is irreversible, it will not be possible to remove the Shape once it is created
        /// (no undo period).
        ///
        pub fun createShape(
            renderID: String,
            setID: Int,
            name: String,
            metadata: {String: AnyStruct}): Int {
            pre {
                // Check that renderID is valid
                (renderID != ""): "The renderID of a Shape cannot be an empty string"

                // Check that setID is valid
                (Pinnacle.getLatestSetID() >= setID): "setID does not exist"
                (Pinnacle.getSet(id: setID)!.lockedDate == nil): "Cannot create a Shape with a locked Set"
                (Pinnacle.getEditionTypeByName(Pinnacle.getSet(id: setID)!.editionType)!.closedDate == nil):
                    "Edition Type is closed"
                // Check that name is valid
                (name != ""): "The name of a Shape cannot be an empty string"
                (Pinnacle.getSet(id: setID)!.shapeNameExistsInSet(name) == false):
                    "A Shape with that name already exists in the Set"
                // Check that metadata is valid
                (metadata.containsKey("Franchises") == true
                    && metadata["Franchises"]!.isInstance(Type<[String]>())):
                    "Franchises is required and must be a string array"
                (metadata.containsKey("Studios") == true && metadata["Studios"]!.isInstance(Type<[String]>())):
                    "Studios is required and must be a string array"
                (metadata.containsKey("RoyaltyCodes") == true &&
                    metadata["RoyaltyCodes"]!.isInstance(Type<[String]>())):
                    "RoyaltyCodes is required and must be a string array"
                (metadata.containsKey("Characters") == false || metadata["Characters"]!.isInstance(Type<[String]>())):
                    "Characters must be a string array"
                (metadata.containsKey("Location") == false || metadata["Location"]!.isInstance(Type<String>())):
                    "Location must a string"
                (metadata.containsKey("EventName") == false || metadata["EventName"]!.isInstance(Type<String>())):
                    "EventName must a string"
            }
            // Check that metadata contains only strings or string arrays, that the keys are valid, and
            // convert strings to string arrays for the ShapeCreated event because events don't support
            // {String: AnyStruct} parameters
            let convertedMetadata: {String: [String]} = {}
            let defaultTraits = {"EditionType" : true, "SeriesName" : true, "SetName" : true,
                "SerialNumber" : true, "IsChaser" : true, "Variant": true, "Printing": true,
                "MintingDate": true, "MaturityDate": true}
            for key in metadata.keys {
                assert(metadata[key]!.isInstance(Type<String>()) || metadata[key]!.isInstance(Type<[String]>()),
                    message: "Metadata values must be strings or string arrays")
                assert(defaultTraits.containsKey(key) == false,
                    message: "Metadata key cannot already exist in the default traits dictionary")
                convertedMetadata[key] = metadata[key]!.isInstance(Type<String>()) == true ?
                    [metadata[key]! as! String] : metadata[key]! as! [String]
            }
            // Create the Shape
            let shape = Shape(
                id: Pinnacle.getLatestShapeID() + 1,
                renderID: renderID,
                setID: setID,
                name: name,
                metadata: metadata
            )
            Pinnacle.shapes.append(shape)
            // Insert the new Shape's name in the parent Set's shapeNames dictionary
            self.borrowSet(id: setID)!.insertShapeName(name)
            // Emit the ShapeCreated event with the converted metadata {String: [String]} dictionary
            emit ShapeCreated(
                id: shape.id,
                renderID: shape.renderID,
                setID: shape.setID,
                name: shape.name,
                editionType: shape.editionType,
                metadata: convertedMetadata
            )
            return shape.id
        }

        /// Return a reference to the Shape with the given ID, if it exists in the contract
        ///
        access(self) fun borrowShape(id: Int): &Shape? {
            pre {
                id > 0: "The ID of a Shape must be greater than 0"
            }
            return Pinnacle.getLatestShapeID() >= id ? &Pinnacle.shapes[id - 1] as &Shape : nil
        }

        /// Close a Shape
        ///
        /// This is irreversible after the undo period is over. It will not be possible to create new Editions
        /// in the Shape.
        ///
        /// @param id: The ID of the Shape to close.
        /// @param undo: A boolean to indicate whether to reopen the Shape within the undo period.
        ///
        pub fun closeShape(id: Int, undo: Bool) {
            undo ? self.borrowShape(id: id)!.reopen() : self.borrowShape(id: id)!.close()
        }

        /// Update a Series's name
        ///
        pub fun updateShapeName(id: Int, name: String) {
            let shapeRef = self.borrowShape(id: id)!
            shapeRef.updateName(name, self.borrowSet(id: shapeRef.setID)!)
        }

        /// Increment a Shape's current printing
        ///
        pub fun incrementShapeCurrentPrinting(id: Int): UInt64 {
            return self.borrowShape(id: id)!.incrementCurrentPrinting()
        }

        /// Create an Edition and return its ID
        ///
        /// This becomes irreversible once NFTs have been minted from the Edition or another Edition has been
        /// created in the contract.
        ///
        pub fun createEdition(
            renderID: String,
            shapeID: Int,
            variant: String?,
            description: String,
            isChaser: Bool,
            maxMintSize: UInt64?,
            maturationPeriod: UInt64?,
            traits: {String: AnyStruct}): Int {
            pre {
                // Check that renderID is valid
                (renderID != ""): "The renderID of a Shape cannot be an empty string"
                // Check that shapeID is valid
                (Pinnacle.getLatestShapeID() >= shapeID): "shapeID does not exist"
                (Pinnacle.getShape(id: shapeID)!.closedDate == nil):
                    "Cannot create an Edition with a closed Shape"
                (Pinnacle.getEditionTypeByName(Pinnacle.getShape(id: shapeID)!.editionType)!.closedDate == nil):
                    "Edition type is closed"
                // Check that description is valid
                (description != ""): "The description of an Edition cannot be an empty string"
                // Check that variant is valid
                (variant == nil || Pinnacle.variants.containsKey(variant!) == true):
                    "Variant does not exist"
                (Pinnacle.getShape(id: shapeID)!.variantPrintingPairExistsInEdition(
                    variant ?? "Standard") == false):
                    "Variant - printing pair already exists in an Edition"
                // Check that maxMintSize is not zero
                (maxMintSize != 0): "Max mint size cannot be equal to zero"
                // Check that traits is valid
                (traits.containsKey("Materials") == true && traits["Materials"]!.isInstance(Type<[String]>())):
                    "Materials is required and must be a string array"
                (traits.containsKey("Size") == true && traits["Size"]!.isInstance(Type<String>())):
                    "Size is required and must be a string"
                (traits.containsKey("Thickness") == true && traits["Thickness"]!.isInstance(Type<String>())):
                    "Thickness is required and must be a string"
                (traits.containsKey("Effects") == false || traits["Effects"]!.isInstance(Type<[String]>())):
                    "Effects must be a string array"
                (traits.containsKey("Color") == false || traits["Color"]!.isInstance(Type<String>())):
                    "Color must be a string"
            }
            let editionType = Pinnacle.getEditionTypeByName(
                Pinnacle.getShape(id: shapeID)!.editionType)!
            // Check that max mint size is valid
            if editionType.isLimited {
                assert(maxMintSize != nil,
                    message: "Only Limited Editions can be created in this Shape, maxMintSize cannot be nil")
            } else {
                assert(maxMintSize == nil,
                    message: "Limited Editions cannot be created in this Shape, maxMintSize must be nil")
            }
            // Check that the maturation period is not nil for Maturing Editions and nil otherwise. Note that
            // it may be set to zero, which is beneficial for creating Editions that don't undergo maturation
            // but still fall under the Maturing Edition category (for example, this might apply to certain
            // Event Editions).
            if editionType.isMaturing {
                assert(maturationPeriod != nil,
                    message: "Only Maturing Editions can be created in this Shape, maturationPeriod cannot be nil")
            } else {
                assert(maturationPeriod == nil,
                    message: "Maturing Editions cannot be created in this Shape, maturationPeriod must be nil")
            }
            // Check that traits contains only strings or string arrays, that the keys are valid, and convert
            // strings to string arrays for the EditionCreated event because events don't support
            // {String: AnyStruct} parameters
            let convertedTraits: {String: [String]} = {}
            let shapeMetadata = Pinnacle.getShape(id: shapeID)!.metadata
            let defaultTraits = {"EditionType" : true, "SeriesName" : true, "SetName" : true,
                "SerialNumber" : true, "IsChaser" : true, "Variant": true, "Printing": true,
                "MintingDate": true, "MaturityDate": true}
            for key in traits.keys {
                assert(traits[key]!.isInstance(Type<String>()) || traits[key]!.isInstance(Type<[String]>()),
                    message: "Trait values must be strings or string arrays")
                assert(defaultTraits.containsKey(key) == false,
                    message: "Trait key cannot already exist in the default traits dictionary")
                assert(shapeMetadata.containsKey(key) == false,
                    message: "Trait key cannot already exist in the Shape's metadata dictionary")
                convertedTraits[key] = traits[key]!.isInstance(Type<String>()) == true ?
                    [traits[key]! as! String] : traits[key]! as! [String]
            }
            // Create the Edition
            let edition = Edition(
                id: Pinnacle.getLatestEditionID() + 1,
                renderID: renderID,
                shapeID: shapeID,
                variant: variant,
                description: description,
                isChaser: isChaser,
                maxMintSize: maxMintSize,
                maturationPeriod: maturationPeriod,
                traits: traits,
            )
            Pinnacle.editions.append(edition)
            // Insert the Variant in the parent Shape for the current printing
            self.borrowShape(id: shapeID)!.insertVariantPrintingPair(variant ?? "Standard")
            // Emit the EditionCreated event with the converted traits {String: [String]} dictionary
            emit EditionCreated(
                id: edition.id,
                renderID: edition.renderID,
                seriesID: edition.seriesID,
                setID: edition.setID,
                shapeID: edition.shapeID,
                variant: edition.variant,
                printing: edition.printing,
                editionTypeID: edition.editionTypeID,
                description: edition.description,
                isChaser: edition.isChaser,
                maxMintSize: edition.maxMintSize,
                maturationPeriod: edition.maturationPeriod,
                traits: convertedTraits
            )
            return edition.id
        }

        /// Return a reference to the Edition with the given ID, if it exists in the contract
        ///
        access(self) fun borrowEdition(id: Int): &Edition? {
            pre {
                id > 0: "The ID of an Edition must be greater than zero"
            }
            return Pinnacle.getLatestEditionID() >= id ? &Pinnacle.editions[id - 1] as &Edition : nil
        }

        /// Close an Edition
        ///
        /// For Open/Unlimited Editions, this is irreversible after the undo period is over. It will no longer
        /// be possible to mint NFTs from the Edition.
        ///
        /// For Limited Editions, closing an Edition allows setting the Edition's closed date to the end of the
        /// primary release sales. The ability to mint NFTs from the Edition is determined by the Edition's
        /// number minted being less than the max mint size.
        ///
        pub fun closeEdition(id: Int) {
            self.borrowEdition(id: id)!.close()
        }

        /// Remove an Edition
        ///
        /// This will fail if NFTs have been minted from the Edition or the Edition is not the last one that
        /// was created in the contract.
        ///
        pub fun removeEdition(id: Int) {
            let editionRef = self.borrowEdition(id: id)!
            assert(editionRef.numberMinted == 0 && id == Pinnacle.getLatestEditionID(),
                message: "Cannot remove an Edition that has minted NFTs and is not the last one created")
            self.borrowShape(id: editionRef.shapeID)!
                .removeVariantPrintingPair(editionRef.variant ?? "Standard")
            emit EditionRemoved(
                id: id
            )
            Pinnacle.editions.removeLast()
        }

        /// Reopen an Open/Unlimited Edition
        ///
        /// This will fail if the Edition is a Limited Edition or if the undo period has expired.
        ///
        pub fun reopenEdition(id: Int) {
            self.borrowEdition(id: id)!.reopen()
        }

        /// Update an Edition's description
        ///
        pub fun updateEditionDescription(id: Int, description: String) {
            self.borrowEdition(id: id)!.updateDescription(description)
        }

        /// Update an Edition's renderID
        ///
        pub fun updateEditionRenderID(id: Int, renderID: String) {
            self.borrowEdition(id: id)!.updateRenderID(renderID)
        }

        /// Create an Edition Type and return its ID
        ///
        /// This is irreversible, it will not be possible to remove the Edition Type once it is created
        /// (no undo period).
        ///
        pub fun createEditionType(name: String, isLimited: Bool, isMaturing: Bool): Int {
            pre {
                name != "": "The name of an Edition Type cannot be an empty string"
                Pinnacle.editionTypeIDsByName.containsKey(name) == false:
                    "An Edition Type with that name already exists"
            }
            let editionType = EditionType(
                id: Pinnacle.getLatestEditionTypeID() + 1,
                name: name,
                isLimited: isLimited,
                isMaturing: isMaturing
            )
            Pinnacle.editionTypes.append(editionType)
            Pinnacle.editionTypeIDsByName[name] = editionType.id
            emit EditionTypeCreated(
                id: editionType.id,
                name: name,
                isLimited: isLimited,
                isMaturing: isMaturing
            )
            return editionType.id
        }

        /// Return a reference to the Edition Type with the given ID, if it exists in the contract
        ///
        access(self) fun borrowEditionType(id: Int): &EditionType? {
            pre {
                id > 0: "The ID of an Edition Type must be greater than zero"
            }
            return Pinnacle.getLatestEditionTypeID() >= id ? &Pinnacle.editionTypes[id - 1] as &EditionType : nil
        }

        /// Close an Edition Type
        ///
        /// This is irreversible after the undo period is over. It will not be possible to create new Shapes
        /// and Editions with the dependent Sets and Shapes, even if they are unlocked/open. The dependent
        /// Sets and Shapes should thus be locked/closed to avoid confusion. This can be done automatically
        /// by setting the proper flags to true when calling the closeEditionType function. All the Sets and
        /// Shapes stored in the contract are iterated over rather than just the dependent ones. This is
        /// because closing an Edition Type is a rare operation and it is anticipated that the decreased
        /// contract size and gas consumption of the more frequent create entity operations are preferable to
        /// maintaining separate Sets and Shapes arrays in each Edition Type. It is also possible to lock or
        /// close the dependent Sets and Shapes individually by calling the lock or close function on each of
        /// them after determining the IDs off-chain.
        ///
        /// @param id: The ID of the Edition Type to close.
        /// @param lockDependentSets: A boolean to indicate whether dependent Sets should be closed
        /// automatically.
        /// @param closeDependentShapes: Same purpose as the lockDependentSets param but for Shapes.
        ///
        pub fun closeEditionType(
            id: Int,
            lockDependentSets: Bool,
            closeDependentShapes: Bool
        ): {String: [Int]} {
            let editionTypeRef = self.borrowEditionType(id: id)!
            editionTypeRef.close()
            let setsLocked: [Int] = []
            if lockDependentSets {
                for index, set in Pinnacle.sets {
                let setRef = self.borrowSet(id: index + 1)!
                    if setRef.lockedDate == nil && setRef.editionType == editionTypeRef.name {
                        setRef.lock()
                        setsLocked.append(setRef.id)
                    }
                }
            }
            let shapesClosed: [Int] = []
            if closeDependentShapes {
                for index, shape in Pinnacle.shapes {
                    let shapeRef = self.borrowShape(id: index + 1)!
                    if shapeRef.closedDate == nil && shapeRef.editionType == editionTypeRef.name {
                        shapeRef.close()
                        shapesClosed.append(shapeRef.id)
                    }
                }
            }
            return {"DependentSetsLocked": setsLocked, "DependentShapesClosed": shapesClosed}
        }

        /// Reopen an Edition Type
        ///
        /// This will fail if the undo period has expired. This will not unlock dependent Sets or reopen
        /// dependent Shapes that may have been locked or closed when closing the Edition Type. This can be
        /// done separately using the lockSet and reopenShape functions with the undo flag set to true, if
        /// the undo period has not expired.
        ///
        pub fun reopenEditionType(id: Int) {
            self.borrowEditionType(id: id)!.reopen()
        }

        /// Insert a Variant in the variants dictionary
        ///
        /// This is irreversible, it will not be possible to remove the Variant once it is inserted
        /// (no undo period). Furthermore, Variants cannot be closed.
        ///
        pub fun insertVariant(name: String) {
            pre {
                name != "": "The name of a Variant cannot be an empty string"
                Pinnacle.variants.containsKey(name) == false: "A Variant with that name already exists"
            }
            Pinnacle.variants[name] = true
            emit VariantInserted(name: name)
        }

        /// Mint a Pin NFT in the Edition with the given ID and return it to the caller
        ///
        pub fun mintNFT(editionID: Int, extension: {String: String}?): @Pinnacle.NFT {
            let pinNFT <- create NFT(editionID: editionID, extension: extension)
            self.borrowEdition(id: editionID)!.incrementNumberMinted()
            return <- pinNFT
        }

        /// Burn an Open/Unlimited Edition Pin NFT and decrement the Edition's number minted
        ///
        /// Any account can burn an NFT it owns with the destroy keyword, the purpose of this function is to
        /// allow the Admin to decrement the Edition's number minted while burning an Open Edition NFT in an
        /// Edition that has not been closed.
        ///
        pub fun burnOpenEditionNFT(_ nft: @NonFungibleToken.NFT) {
            let nft <- nft as! @Pinnacle.NFT
            // Decrement the number minted in the Edition. This will fail if the Edition is a Limited Edition.
            self.borrowEdition(id: nft.editionID)!.decrementNumberMinted()
            emit OpenEditionNFTBurned(id: nft.id, editionID: nft.editionID)
            destroy nft
        }

        /// Set a limit on the number entries that can be added to the inscriptions of the NFT with the given
        /// ID (default is 100)
        ///
        pub fun setNFTInscriptionsLimit(
            nftID: UInt64,
            limit: Int,
            owner: Address,
            collectionPublicPathID: String?
        ) {
            pre {
                limit > 100: "The limit must be greater than the default value of 100"
            }
            let collectionPublicRef =  Pinnacle.borrowCollectionPublic(
                owner: owner,
                collectionPublicPathID
            )
            assert(collectionPublicRef!.borrowPinNFT(id: nftID) != nil,
                message: "No NFT with such ID in the Collection")
            Pinnacle.inscriptionsLimits[nftID] = limit
        }

        /// Add XP to an NFT and return the NFT's new XP balance
        ///
        pub fun addXPtoNFT(
            nftID: UInt64,
            owner: Address,
            collectionPublicPathID: String?,
            value: UInt64
        ): UInt64 {
            return Pinnacle.borrowCollectionPublic(owner: owner, collectionPublicPathID)!
                .borrowPinNFT(id: nftID)!
                .addXP(value)
        }

        /// Remove XP from an NFT and return the NFT's new XP balance
        ///
        pub fun subtractXPfromNFT(
            nftID: UInt64,
            owner: Address,
            collectionPublicPathID: String?,
            value: UInt64
        ): UInt64 {
            return Pinnacle.borrowCollectionPublic(owner: owner, collectionPublicPathID)!
                .borrowPinNFT(id: nftID)!
                .subtractXP(value)
        }

        /// When conducting primary release sales, emit a "Purchased" event to facilitate purchase tracking
        /// off-chain. The parameters are passed through to the event and are not used by the contract.
        ///
        pub fun emitPurchasedEvent(
            purchaseIntentID: String,
            buyerAddress: Address,
            countPurchased: UInt64,
            totalSalePrice: UFix64
        ) {
            emit Purchased(
                purchaseIntentID: purchaseIntentID,
                buyerAddress: buyerAddress,
                countPurchased: countPurchased,
                totalSalePrice: totalSalePrice
            )
        }

        /// Create an Admin resource and return it to the caller
        ///
        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }

        /// Set the contract's royalty address
        ///
        pub fun setRoyaltyAddress(_ address: Address) {
            Pinnacle.royaltyAddress = address
        }

        /// Set the contract's end user license URL
        ///
        pub fun setEndUserLicenseURL(_ url: String) {
            Pinnacle.endUserLicenseURL = url
        }

        /// Set an entry in the contract's extension dictionary
        ///
        pub fun setExtensionEntry(_ key: String, _ value: AnyStruct, _ overwrite: Bool) {
            pre {
                key != "": "The key cannot be an empty string"
                overwrite || !Pinnacle.extension.containsKey(key): "Overwrite is false and the key already exists"
                key != "EndUserLicenseCaption" || value.isInstance(Type<String>()): "EndUserLicenseCaption must be a string"
            }
            Pinnacle.extension[key] = value
        }
    }

    //------------------------------------------------------------
    // Variants, Path, and Utils Functions
    //------------------------------------------------------------

    /// Return the contract's variants dictionary
    ///
    pub fun getAllVariants(): {String: Bool} {
        return Pinnacle.variants
    }

    /// Allow iterating over Variants in the contract without allocating an array
    ///
    pub fun forEachVariant(_ function: ((String): Bool)) {
        Pinnacle.variants.forEachKey(function)
    }

    /// Return this contract's extension dictionary
    ///
    pub fun getExtension(): {String: AnyStruct} {
        return Pinnacle.extension
    }

    /// Return a public path that is scoped to this contract
    ///
    pub fun getPublicPath(suffix: String): PublicPath {
        return PublicPath(identifier: "Pinnacle".concat(suffix))!
    }

    /// Return a private path that is scoped to this contract
    ///
    pub fun getPrivatePath(suffix: String): PrivatePath {
        return PrivatePath(identifier: "Pinnacle".concat(suffix))!
    }

    /// Return a storage path that is scoped to this contract
    ///
    pub fun getStoragePath(suffix: String): StoragePath {
        return StoragePath(identifier: "Pinnacle".concat(suffix))!
    }

    /// Return a Collection name with an optional bucket suffix
    ///
    pub fun makeCollectionName(bucketName maybeBucketName: String?): String {
        if let bucketName = maybeBucketName {
            return "Collection_".concat(bucketName)
        }
        return "Collection"
    }

    /// Return a queue name with an optional bucket suffix
    ///
    pub fun makeQueueName(bucketName maybeBucketName: String?): String {
        if let bucketName = maybeBucketName {
            return "Queue_".concat(bucketName)
        }
        return "Queue"
    }

    /// Check if the contract is deployed to mainnet
    ///
    /// The function relies on checking the type of the imported NonFungibleToken contract.
    /// 0x1d7e57aa55817448 is the address of the known NonFungibleToken contract standard on mainnet.
    /// This is a workaround for the fact that there is no way to check the network ID in Cadence yet.
    ///
    pub fun isContractDeployedToMainnet(): Bool {
        return Type<NonFungibleToken>().identifier == "A.1d7e57aa55817448.NonFungibleToken"
    }

    //------------------------------------------------------------
    // Contract MetadataViews
    //------------------------------------------------------------

    /// Return the metadata view types available for this contract
    ///
    pub fun getViews(): [Type] {
        return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
    }

    /// Resolve this contract's metadata views
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        post {
            result == nil || result!.getType() == view: "The returned view must be of the given type or nil"
        }
        switch view {
            case Type<MetadataViews.NFTCollectionData>(): return Pinnacle.resolveNFTCollectionDataView()
            case Type<MetadataViews.NFTCollectionDisplay>(): return Pinnacle.resolveNFTCollectionDisplayView()
        }
        return nil
    }

    /// Resolve this contract's NFTCollectionData view
    ///
    pub fun resolveNFTCollectionDataView(): MetadataViews.NFTCollectionData {
        return MetadataViews.NFTCollectionData(
            storagePath: Pinnacle.CollectionStoragePath,
            publicPath: Pinnacle.CollectionPublicPath,
            providerPath: Pinnacle.CollectionPrivatePath,
            publicCollection: Type<&Pinnacle.Collection{Pinnacle.PinNFTCollectionPublic}>(),
            publicLinkedType: Type<&Pinnacle.Collection{Pinnacle.PinNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&Pinnacle.Collection{Pinnacle.PinNFTCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: (fun(): @NonFungibleToken.Collection {return <- Pinnacle.createEmptyCollection()})
        )
    }

    /// Resolve this contract's NFTCollectionDisplay view
    ///
    pub fun resolveNFTCollectionDisplayView(): MetadataViews.NFTCollectionDisplay {
        let squareImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(
                url: "https://assets.disneypinnacle.com/on-chain/pinnacle.jpg"
            ),
            mediaType: "image/jpg"
        )
        let bannerImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(
                url: "https://assets.disneypinnacle.com/on-chain/pinnacle-banner.jpeg"
            ),
            mediaType: "image/jpeg"
        )
        return MetadataViews.NFTCollectionDisplay(
            name: "Pinnacle",
            description: "placeholder_description",
            externalURL: MetadataViews.ExternalURL("https://disneypinnacle.com"),
            squareImage: squareImage,
            bannerImage: bannerImage,
            socials : {
                "instagram": MetadataViews.ExternalURL("https://www.instagram.com/disneypinnacle/"),
                "twitter": MetadataViews.ExternalURL("https://twitter.com/DisneyPinnacle"),
                "discord": MetadataViews.ExternalURL("https://discord.gg/DisneyPinnacle"),
                "facebook": MetadataViews.ExternalURL("https://www.facebook.com/groups/disneypinnacle/")
            }
        )
    }

    //------------------------------------------------------------
    // Contract lifecycle
    //------------------------------------------------------------

    /// Pinnacle contract initializer
    ///
    /// The undo period is specified as a parameter to facilitate automated tests.
    ///
    init(undoPeriod: UInt64) {
        pre {
            // Check that the contract is properly configured on mainnet as part of the contract's code
            Pinnacle.isContractDeployedToMainnet() == false || undoPeriod == 259200:
                "The undo period must be set to 259200 (3 days) if the contract is deployed to mainnet"
        }

        // Set the named paths
        self.CollectionStoragePath = Pinnacle.getStoragePath(suffix: "Collection")
        self.CollectionPublicPath = Pinnacle.getPublicPath(suffix: "Collection")
        self.CollectionPrivatePath = Pinnacle.getPrivatePath(suffix: "Collection")
        self.AdminStoragePath = Pinnacle.getStoragePath(suffix: "Admin")
        self.MinterPrivatePath = Pinnacle.getPrivatePath(suffix: "Minter")

        // Initialize the non-container fields
        self.totalSupply = 0
        self.undoPeriod = undoPeriod
        self.royaltyAddress = self.account.address
        self.endUserLicenseURL = "https://disneypinnacle.com/terms"

        // Initialize the entity arrays
        self.series = []
        self.sets = []
        self.shapes = []
        self.editions = []
        self.editionTypes = []

        // Initialize the dictionaries
        self.seriesIDsByName = {}
        self.setIDsByName = {}
        self.editionTypeIDsByName = {}
        self.variants = {}
        self.inscriptionsLimits = {}
        self.extension = {}

        // Create an Admin resource
        let admin <- create Admin()

        // Create the default Edition Types
        admin.createEditionType(name: "Genesis Edition", isLimited: true, isMaturing: false)
        admin.createEditionType(name: "Unique Edition", isLimited: true, isMaturing: false)
        admin.createEditionType(name: "Limited Edition", isLimited: true, isMaturing: false)
        admin.createEditionType(name: "Open Edition", isLimited: false, isMaturing: false)
        admin.createEditionType(name: "Starter Edition", isLimited: false, isMaturing: true)
        admin.createEditionType(name: "Event Edition", isLimited: false, isMaturing: true)

        // Save the Admin resource to storage and create Minter capability
        self.account.save(<- admin, to: self.AdminStoragePath)
        self.account.link<&Admin{NFTMinter}>(self.MinterPrivatePath, target: self.AdminStoragePath)

        // Let the world know we are here
        emit ContractInitialized()
    }
}
