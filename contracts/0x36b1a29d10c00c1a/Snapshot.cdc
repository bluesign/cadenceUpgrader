//     _____                        __          __ 
//    / ___/____  ____ _____  _____/ /_  ____  / /_
//    \__ \/ __ \/ __ `/ __ \/ ___/ __ \/ __ \/ __/
//   ___/ / / / / /_/ / /_/ (__  ) / / / /_/ / /_  
//  /____/_/ /_/\__,_/ .___/____/_/ /_/\____/\__/  
//                  /_/                            
//
// The `Snapshot` contract provides the following features:
//  - Records all NFT information owned by an address at the time of execution (this is called a snapshot).
//  - Proves that an address owned a particular NFT for a specified time range (if it did, it returns its snapshot information).
//  - Displays a specific snapshot in a format of your choice.
//
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Snapshot {

    // Paths to `Album` resource that store snapshots and path to `Admin` resource.
    pub let AlbumPublicPath: PublicPath
    pub let AlbumStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    // Only allowed logic may be used when taking snapshots. This can be updated by `Admin`.
    pub var allowedLogicTypes: [Type]

    // `NFTInfo` is the unit of measure recorded in the snapshot.
    // `MetadataViews.Display` metadata, if any, will be stored.
    //  Depending on the logic, some may record whatever values they like in `extraMetadata`.
    pub struct NFTInfo {
        pub let collectionPublicPath: String
        pub let nftType: Type
        pub let nftID: UInt64
        pub let metadata: MetadataViews.Display?
        pub let extraMetadata: {String: AnyStruct}?

        init(
            collectionPublicPath: String,
            nftType: Type,
            nftID: UInt64,
            metadata: MetadataViews.Display?,
            extraMetadata: {String: AnyStruct}?
        ) {
            self.collectionPublicPath = collectionPublicPath
            self.nftType = nftType
            self.nftID = nftID
            self.metadata = metadata
            self.extraMetadata = extraMetadata
        }
    }

    // `ILogic` is the interface for the logic used to take snapshots.
    //  It returns `NFTInfo` instances held by a given address, keyed by the PublicPath of the respective Collection and the ID of the NFT.
    //  The primary implementation is provided in the `SnapshotLogic` contract, but it can be extended in the future.
    //  While anyone can define this implementation, it must be approved by the `Admin` to be used.
    pub struct interface ILogic {
        pub fun getOwnedNFTs(address: Address): {String: {UInt64: NFTInfo}}
    }

    // `IViewer` is the interface for generating arbitrary images, etc., based on snapshots.
    //  For instance, the `SnapshotViewer` contract offers an implementation that produces HTML.
    //  Anybody can create this implementation, and it doesn't require permission to use.
    pub struct interface IViewer {
        pub fun getView(snap: &Snap): AnyStruct
    }

    // `Snap` is a resource that aggregates `NFTInfo` instances,
    //  along with details like the time and logic when they were captured.
    pub resource Snap {
        pub let time: UFix64
        pub let ownerAddress: Address
        pub let ownedNFTs: {String: {UInt64: NFTInfo}}
        pub let logicType: Type

        init(
            time: UFix64,
            ownerAddress: Address,
            ownedNFTs: {String: {UInt64: NFTInfo}},
            logicType: Type
        ) {
            self.time = time
            self.ownerAddress = ownerAddress
            self.ownedNFTs = ownedNFTs
            self.logicType = logicType
        }
    }

    // `AlbumPublic` is an interface for publishing `Album` resources.
    //  Anyone can access the snapshot information, but cannot add or remove snapshots without permission.
    pub resource interface AlbumPublic {
        pub var snaps: @{UFix64: Snap}

        pub fun proofOfOwnership(
            startTime: UFix64,
            endTime: UFix64,
            collectionPublicPath: String,
            nftType: Type, nftID: UInt64, ownerAddress: Address
        ): &Snap?

        pub fun view(time: UFix64, viewer: {IViewer}): AnyStruct
    }

    // `Album` is a Collection-like resource for storing multiple snapshots (`Snap`).
    //  The key features of this contract are defined in this resource.
    pub resource Album: AlbumPublic {

        // Variable to store snapshots. Each snapshot is indexed by the block time at which it was taken.
        pub var snaps: @{UFix64: Snap}

        // Function to capture a snapshot.
        // The arguments include the address and the desired logic struct. The logic must be authorized.
        pub fun snapshot(address: Address, logic: {ILogic}) {
            pre {
                Snapshot.allowedLogicTypes.contains(logic.getType()): "Not allowed logic"
            }
            let time = getCurrentBlock().timestamp
            self.snaps[time] <-! create Snap(
                time: time,
                ownerAddress: address,
                ownedNFTs: logic.getOwnedNFTs(address: address),
                logicType: logic.getType()
            )
        }

        // This function enables you to verify if a specific address owned a particular NFT
        // within a specified start and end time range.
        // If a provable snapshot exists, it will be returned. Otherwise, nil is returned.
        pub fun proofOfOwnership(
            startTime: UFix64,
            endTime: UFix64,
            collectionPublicPath: String,
            nftType: Type,
            nftID: UInt64,
            ownerAddress: Address
        ): &Snap? {
            for time in self.snaps.keys {
                if (startTime > time || time > endTime) {
                    continue
                }
                let snap = &self.snaps[time] as? &Snap?
                if (
                    snap != nil &&
                    snap!.ownerAddress == ownerAddress &&
                    snap!.ownedNFTs[collectionPublicPath] != nil &&
                    snap!.ownedNFTs[collectionPublicPath]![nftID] != nil &&
                    snap!.ownedNFTs[collectionPublicPath]![nftID]!.nftType == nftType
                ) {
                    return snap
                }
            }
            return nil
        }

        // Function to display the contents of a snapshot.
        // For instance, it can be used to generate something akin to a family photo.
        pub fun view(time: UFix64, viewer: {IViewer}): AnyStruct {
            let snap = &self.snaps[time] as? &Snap?
            return viewer.getView(snap: snap!)
        }

        // Function to import a snapshot.
        pub fun import(snap: @Snap) {
            let time = snap.time
            self.snaps[time] <-! snap
        }

        // Function to export a snapshot.
        pub fun export(time: UFix64): @Snap {
            return <- self.snaps.remove(key: time)!
        }

        init() {
            self.snaps <- {}
        }

        destroy() {
            destroy self.snaps
        }
    }

    // `Admin` is a resource held by the administrator of this contract. It is used for maintaining logic.
    pub resource Admin {
        pub fun addLogic(logic: {ILogic}) {
            pre {
                !Snapshot.allowedLogicTypes.contains(logic.getType()): "Already exists"
            }
            Snapshot.allowedLogicTypes.append(logic.getType())
        }

        pub fun removeLogic(index: Int) {
            Snapshot.allowedLogicTypes.remove(at: index)
        }

        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }
    }

    pub fun createEmptyAlbum(): @Album {
        return <- create Album()
    }

    init() {
        self.AlbumPublicPath = /public/SnapshotAlbum
        self.AlbumStoragePath = /storage/SnapshotAlbum
        self.AdminStoragePath = /storage/SnapshotAdmin
        self.allowedLogicTypes = []

        // The deployer of the contract will possess the `Admin` resource.
        self.account.save(<- create Admin(), to: self.AdminStoragePath)

        self.account.save(<- create Album(), to: self.AlbumStoragePath)
        self.account.link<&Album{AlbumPublic}>(self.AlbumPublicPath, target: self.AlbumStoragePath)
    }
}
