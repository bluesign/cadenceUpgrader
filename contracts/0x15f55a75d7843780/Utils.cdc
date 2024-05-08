import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import StringUtils from "../0xe52522745adf5c34/StringUtils.cdc"

access(all) contract Utils {

    /// StorableNFTCollectionData
    /// This struct copies MetadataViews.NFTCollectionData without the createEmptyCollection reference to be storable.
    access(all) struct StorableNFTCollectionData {
        pub let storagePath: StoragePath
        pub let publicPath: PublicPath
        pub let providerPath: PrivatePath
        pub let publicCollection: Type
        pub let publicLinkedType: Type
        pub let providerLinkedType: Type

        init(_ collectionData: MetadataViews.NFTCollectionData) {
            self.storagePath = collectionData.storagePath
            self.publicPath = collectionData.publicPath
            self.providerPath = collectionData.providerPath
            self.publicCollection = collectionData.publicCollection
            self.publicLinkedType = collectionData.publicLinkedType
            self.providerLinkedType = collectionData.providerLinkedType
        }
    }

    /// ContractMetadata
    /// This struct holds all relevant metadata for a given contract type.
    access(all) struct ContractMetadata {
        pub let type: Type
        pub let address: String
        pub let name: String
        pub let context: {String: String}?

        init(type: Type, context: {String: String}?) {
            let parts = StringUtils.split(type.identifier, ".")

            self.type = type
            self.address = "0x".concat(parts[1])
            self.name = parts[2]
            self.context = context
        }
    }

    /// getIdentifierContractMetadata
    /// This helper function returns the contract metadata for a given type identifier.
    access(all) fun getIdentifierContractMetadata(identifier: String): ContractMetadata {

        return ContractMetadata(type: Utils.getIdentifierContractType(identifier: identifier), context: nil)
    }

    /// getIdentifierContractType
    /// This helper function returns the contract type for a given type identifier.
    access(all) fun getIdentifierContractType(identifier: String): Type {

        let parts = StringUtils.split(identifier, ".")

        assert(parts.length >= 4, message: "invalid identifier")

        let contractIdentifier = StringUtils.join(parts.slice(from: 0, upTo: 3), ".")

        return CompositeType(contractIdentifier)!
    }

    /// getCollectionPaths
    /// This function searches the specified account and returns a dictionary of NFTCollectionData structs by
    /// collectionIdentifier. If a collectionIdentifier is not found in the specified ownerAddress, or that collection
    /// does not provide a resolver for NFTCollectionData, the response value will be "nil".
    access(all) fun getNFTCollectionData(ownerAddress: Address, nftIdentifiers: [String]): {String: MetadataViews.NFTCollectionData} {

        let response: {String: MetadataViews.NFTCollectionData} = { }
                
        let account = getAccount(ownerAddress)

        let normalizedNftIdentifiers: [String] = []
                
        account.forEachPublic(fun (path: PublicPath, type: Type): Bool {

			let capability = account.getCapability<&{NonFungibleToken.CollectionPublic}>(path)

			if (!capability.check()) {

				return true
			}

            let collectionPublic = capability.borrow()
            if (collectionPublic == nil) {

                return true
            }

            let contractType = Utils.getIdentifierContractType(identifier: collectionPublic!.getType().identifier)
            let nftIdentifier = contractType.identifier.concat(".NFT")

            var nftId: UInt64? = nil

            for identifier in nftIdentifiers {

                if (!StringUtils.hasPrefix(identifier, nftIdentifier)) {

                    continue
                }

                normalizedNftIdentifiers.append(nftIdentifier)

                let parts = StringUtils.split(identifier, ".")
                if (parts.length == 5) {

                    nftId = UInt64.fromString(parts[parts.length - 1])
                }

                break
            }

            if (!normalizedNftIdentifiers.contains(nftIdentifier) || response.containsKey(nftIdentifier)) {

                return true
            }

            if (nftId == nil) {

                let nftIds = collectionPublic!.getIDs()
                if (nftIds.length < 1) {

                    return true
                }

                nftId = nftIds[0]
            }

            if (nftId == nil) {

                return true
            }

            let nftRef: &{NonFungibleToken.INFT} = collectionPublic!.borrowNFT(id: nftId!) as &{NonFungibleToken.INFT}

            let collectionData = (nftRef.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?) ?? panic("collection lookup failed")

            response.insert(key: nftIdentifier, collectionData)
                
            return true
        })

        return response
    }
}
