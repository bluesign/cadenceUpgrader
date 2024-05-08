import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StringUtils from "./../../standardsV1/StringUtils.cdc"

access(all)
contract Utils{ 
	
	/// StorableNFTCollectionData
	/// This struct copies MetadataViews.NFTCollectionData without the createEmptyCollection reference to be storable.
	access(all)
	struct StorableNFTCollectionData{ 
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let providerPath: PrivatePath
		
		access(all)
		let publicCollection: Type
		
		access(all)
		let publicLinkedType: Type
		
		access(all)
		let providerLinkedType: Type
		
		init(_ collectionData: MetadataViews.NFTCollectionData){ 
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
	access(all)
	struct ContractMetadata{ 
		access(all)
		let type: Type
		
		access(all)
		let address: String
		
		access(all)
		let name: String
		
		access(all)
		let context:{ String: String}?
		
		init(type: Type, context:{ String: String}?){ 
			let parts = StringUtils.split(type.identifier, ".")
			self.type = type
			self.address = "0x".concat(parts[1])
			self.name = parts[2]
			self.context = context
		}
	}
	
	/// getIdentifierContractMetadata
	/// This helper function returns the contract metadata for a given type identifier.
	access(all)
	fun getIdentifierContractMetadata(identifier: String): ContractMetadata{ 
		return ContractMetadata(
			type: Utils.getIdentifierContractType(identifier: identifier),
			context: nil
		)
	}
	
	/// getIdentifierContractType
	/// This helper function returns the contract type for a given type identifier.
	access(all)
	fun getIdentifierContractType(identifier: String): Type{ 
		let parts = StringUtils.split(identifier, ".")
		assert(parts.length >= 4, message: "invalid identifier")
		let contractIdentifier = StringUtils.join(parts.slice(from: 0, upTo: 3), ".")
		return CompositeType(contractIdentifier)!
	}
	
	/// getCollectionPaths
	/// This function searches the specified account and returns a dictionary of NFTCollectionData structs by
	/// collectionIdentifier. If a collectionIdentifier is not found in the specified ownerAddress, or that collection
	/// does not provide a resolver for NFTCollectionData, the response value will be "nil".
	access(all)
	fun getNFTCollectionData(ownerAddress: Address, nftIdentifiers: [String]):{ 
		String: MetadataViews.NFTCollectionData
	}{ 
		let response:{ String: MetadataViews.NFTCollectionData} ={} 
		let account = getAccount(ownerAddress)
		let normalizedNftIdentifiers: [String] = []
		account.forEachPublic(fun (path: PublicPath, type: Type): Bool{ 
				let capability = account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(path)
				if !capability.check(){ 
					return true
				}
				let collectionPublic = capability.borrow()
				if collectionPublic == nil{ 
					return true
				}
				let contractType = Utils.getIdentifierContractType(identifier: (collectionPublic!).getType().identifier)
				let nftIdentifier = contractType.identifier.concat(".NFT")
				var nftId: UInt64? = nil
				for identifier in nftIdentifiers{ 
					if !StringUtils.hasPrefix(identifier, nftIdentifier){ 
						continue
					}
					normalizedNftIdentifiers.append(nftIdentifier)
					let parts = StringUtils.split(identifier, ".")
					if parts.length == 5{ 
						nftId = UInt64.fromString(parts[parts.length - 1])
					}
					break
				}
				if !normalizedNftIdentifiers.contains(nftIdentifier) || response.containsKey(nftIdentifier){ 
					return true
				}
				if nftId == nil{ 
					let nftIds = (collectionPublic!).getIDs()
					if nftIds.length < 1{ 
						return true
					}
					nftId = nftIds[0]
				}
				if nftId == nil{ 
					return true
				}
				let nftRef: &{NonFungibleToken.INFT} = (collectionPublic!).borrowNFT(id: nftId!) as &{NonFungibleToken.INFT}
				let collectionData = nftRef.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData? ?? panic("collection lookup failed")
				response.insert(key: nftIdentifier, collectionData)
				return true
			})
		return response
	}
}
