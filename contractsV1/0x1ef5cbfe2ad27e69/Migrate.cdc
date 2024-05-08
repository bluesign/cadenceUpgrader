import MonoCat from "../0x8529aaf64c168952/MonoCat.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Migrate{ 
	// save monocats owners address
	access(all)
	struct StroedMonoCats{ 
		access(all)
		let tokenId: UInt64
		
		access(all)
		let lastFlowOwner: Address
		
		access(all)
		let firstEthOwner: String
		
		access(all)
		let isSpecial: Bool
		
		init(tokenId: UInt64, lastFlowOwner: Address, firstEthOwner: String, isSpecial: Bool){ 
			self.tokenId = tokenId
			self.lastFlowOwner = lastFlowOwner
			self.firstEthOwner = firstEthOwner
			self.isSpecial = isSpecial
		}
	}
	
	access(self)
	let collection: @{NonFungibleToken.Collection}
	
	// store
	access(self)
	let storedMonoCats: [StroedMonoCats]
	
	access(all)
	event Migrated(tokenId: UInt64, lastFlowOwner: Address, firstEthOwner: String, isSpecial: Bool)
	
	access(all)
	event ContractInitialized()
	
	access(all)
	fun StringContains(forSearch: String, search: String): Bool{ 
		var ptrSearch = 0
		var i = 0
		while i < forSearch.length{ 
			if forSearch[i] == search[ptrSearch]{ 
				if ptrSearch == search.length - 1{ 
					return true
				}
				ptrSearch = ptrSearch + 1
				i = i + 1
				continue
			}
			ptrSearch = 0
			i = i + 1
		}
		return false
	}
	
	access(all)
	fun isCatSpecial(_ cat: &MonoCat.NFT): Bool{ 
		let metadata = cat.getRawMetadata()
		let attrs = metadata["attributes"]
		if attrs == nil{ 
			return false
		}
		return self.StringContains(forSearch: attrs!, search: "Oriental Monsters")
	}
	
	access(all)
	fun recycleMonoCats(tokenIds: [UInt64], acct: AuthAccount, ethAddress: String){ 
		// get user's collection
		let col = acct.borrow<&MonoCat.Collection>(from: MonoCat.CollectionStoragePath)
		assert(col != nil, message: "recycleMonoCats: You don't have a MonoCats collection.")
		let needSpecial = tokenIds.length % 5 != 0
		
		// special cats
		for id in tokenIds{ 
			let borrowed = (col!).borrowMonoCat(id: id)
			assert(borrowed != nil, message: "recycleMonoCats: missing MonoCats#".concat(id.toString()))
			assert(self.isCatSpecial(borrowed!) == needSpecial, message: "recycleMonoCats: only need ".concat(needSpecial ? "special" : "normal").concat(" cats, error at MonoCats#").concat(id.toString()))
			let nft <- (col!).withdraw(withdrawID: id)
			self.collection.deposit(token: <-nft)
			// save to store
			self.storedMonoCats.append(StroedMonoCats(tokenId: id, lastFlowOwner: acct.address, firstEthOwner: ethAddress, isSpecial: needSpecial))
			// emit event
			emit Migrated(tokenId: id, lastFlowOwner: acct.address, firstEthOwner: ethAddress, isSpecial: needSpecial)
		}
	}
	
	access(all)
	fun getAllRetrievableMonoCatsIds(ethAddress: String):{ UInt64: Bool}{ 
		let ret:{ UInt64: Bool} ={} 
		for cat in self.storedMonoCats{ 
			if cat.firstEthOwner == ethAddress{ 
				ret[cat.tokenId] = cat.isSpecial
			}
		}
		return ret
	}
	
	init(){ 
		self.collection <- MonoCat.createEmptyCollection(nftType: Type<@MonoCat.Collection>())
		self.storedMonoCats = []
		emit ContractInitialized()
	}
}
