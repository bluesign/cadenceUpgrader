import SchmoesNFT from "./SchmoesNFT.cdc"

access(all)
contract SchmoesNFTAdmin{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(all)
		fun setIsSaleActive(_ newIsSaleActive: Bool){ 
			SchmoesNFT.setIsSaleActive(newIsSaleActive)
		}
		
		access(all)
		fun setPrice(_ newPrice: UFix64){ 
			SchmoesNFT.setPrice(newPrice)
		}
		
		access(all)
		fun setMaxMintAmount(_ newMaxMintAmount: UInt64){ 
			SchmoesNFT.setMaxMintAmount(newMaxMintAmount)
		}
		
		access(all)
		fun setIpfsBaseCID(_ ipfsBaseCID: String){ 
			SchmoesNFT.setIpfsBaseCID(ipfsBaseCID)
		}
		
		access(all)
		fun setProvenance(_ provenance: String){ 
			SchmoesNFT.setProvenance(provenance)
		}
		
		access(all)
		fun setProvenanceForEdition(_ edition: UInt64, _ provenance: String){ 
			SchmoesNFT.setProvenanceForEdition(edition, provenance)
		}
		
		access(all)
		fun setSchmoeAsset(
			_ assetType: SchmoesNFT.SchmoeTrait,
			_ assetName: String,
			_ content: String
		){ 
			SchmoesNFT.setSchmoeAsset(assetType, assetName, content)
		}
		
		access(all)
		fun batchUpdateSchmoeData(_ schmoeDataMap:{ UInt64: SchmoesNFT.SchmoeData}){ 
			SchmoesNFT.batchUpdateSchmoeData(schmoeDataMap)
		}
		
		access(all)
		fun setEarlyLaunchTime(_ earlyLaunchTime: UFix64){ 
			SchmoesNFT.setEarlyLaunchTime(earlyLaunchTime)
		}
		
		access(all)
		fun setLaunchTime(_ launchTime: UFix64){ 
			SchmoesNFT.setLaunchTime(launchTime)
		}
		
		access(all)
		fun setIdsPerIncrement(_ idsPerIncrement: UInt64){ 
			SchmoesNFT.setIdsPerIncrement(idsPerIncrement)
		}
		
		access(all)
		fun setTimePerIncrement(_ timePerIncrement: UInt64){ 
			SchmoesNFT.setTimePerIncrement(timePerIncrement)
		}
	}
	
	access(all)
	init(){ 
		self.AdminStoragePath = /storage/schmoesNFTAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
