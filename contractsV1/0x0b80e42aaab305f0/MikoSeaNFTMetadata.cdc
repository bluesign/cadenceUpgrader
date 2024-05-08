
// this contract used to storage required NFT metadata
access(all)
contract MikoSeaNFTMetadata{ 
	// map nftType, NFT ID and required metadata
	// {nftType: {nftID: metadata}}
	access(self)
	var NFTMetadata:{ String:{ UInt64:{ String: String}}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(all)
		fun patchMetadata(nftType: String, nftID: UInt64, metadata:{ String: String}){ 
			if !MikoSeaNFTMetadata.NFTMetadata.containsKey(nftType){ 
				MikoSeaNFTMetadata.NFTMetadata[nftType] ={} 
			}
			if !(MikoSeaNFTMetadata.NFTMetadata[nftType]!).containsKey(nftID){ 
				(MikoSeaNFTMetadata.NFTMetadata[nftType]!).insert(key: nftID, metadata)
				return
			}
			metadata.forEachKey(fun (key: String): Bool{ 
					((MikoSeaNFTMetadata.NFTMetadata[nftType]!)[nftID]!).insert(key: key, metadata[key] ?? "")
					return true
				})
		}
		
		access(all)
		fun removeMetadataByKeys(nftType: String, nftID: UInt64, metadataKeys: [String]){ 
			if let nftTypeMetadata = MikoSeaNFTMetadata.NFTMetadata[nftType]{ 
				if let nftMetadata = nftTypeMetadata[nftID]{ 
					nftMetadata.forEachKey(fun (key: String): Bool{ 
							if metadataKeys.contains(key){ 
								nftMetadata.remove(key: key)
							}
							return true
						})
					nftTypeMetadata.insert(key: nftID, nftMetadata)
					MikoSeaNFTMetadata.NFTMetadata.insert(key: nftType, nftTypeMetadata)
				}
			}
		}
	}
	
	access(all)
	fun getNFTMetadata(nftType: String, nftID: UInt64):{ String: String}?{ 
		return (self.NFTMetadata[nftType] ??{} )[nftID]
	}
	
	init(){ 
		self.AdminStoragePath = /storage/MikoSeaNFTMetadataAdminStoragePath
		self.NFTMetadata ={} 
		
		// Put the Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
