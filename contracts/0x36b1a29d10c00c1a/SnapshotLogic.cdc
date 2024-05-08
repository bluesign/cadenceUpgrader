import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Snapshot from "./Snapshot.cdc"
import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

// The `SnapshotLogic` contract is a basic implementation of the `ILogic` struct interface.
//
pub contract SnapshotLogic {

    pub struct BasicLogic: Snapshot.ILogic {

        // This logic retrieves NFT information for
        // the Public Capability of `NonFungibleToken.CollectionPublic` and
        // the Public Capability of `TopShot.MomentCollectionPublic`.
        //
        pub fun getOwnedNFTs(address: Address): {String: {UInt64: Snapshot.NFTInfo}} {
            var nfts: {String: {UInt64: Snapshot.NFTInfo}} = {}
            let account = getAccount(address)
            account.forEachPublic(fun (path: PublicPath, type: Type): Bool {

                let collection = account.getCapability(path).borrow<&AnyResource{NonFungibleToken.CollectionPublic}>()
                if (collection != nil) {
                    for index, id in collection!.getIDs() {
                        if index == 0 {
                            nfts[path.toString()] = {}
                        }
                        let nft = collection!.borrowNFT(id: id)
                        nfts[path.toString()]!.insert(key: nft.id, self.makeNFTInfo(nft: nft, path: path))
                    }
                    return true
                }

                let topshotCollection = account.getCapability(path).borrow<&AnyResource{TopShot.MomentCollectionPublic}>()
                if (topshotCollection != nil) {
                    for index, id in topshotCollection!.getIDs() {
                        if index == 0 {
                            nfts[path.toString()] = {}
                        }
                        let nft = topshotCollection!.borrowNFT(id: id)
                        nfts[path.toString()]!.insert(key: nft.id, self.makeNFTInfo(nft: nft, path: path))
                    }
                    return true
                }

                return true
            })
            return nfts
        }

        priv fun makeNFTInfo(nft: &NonFungibleToken.NFT, path: PublicPath): Snapshot.NFTInfo {
            var metadata: MetadataViews.Display? = nil
            if nft.getViews().contains(Type<MetadataViews.Display>()) {
                metadata = nft.resolveView(Type<MetadataViews.Display>())! as? MetadataViews.Display
            }
            return Snapshot.NFTInfo(
                collectionPublicPath: path.toString(),
                nftType: nft.getType(),
                nftID: nft.id,
                metadata: metadata,
                extraMetadata: nil
            )
        }
    }
}
