import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Filter{ 
	access(all)
	let TraitsType: Type
	
	access(all)
	let EditionsType: Type
	
	access(all)
	struct interface NFTFilter{ 
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool
		
		access(all)
		fun getDetails(): AnyStruct
	}
	
	access(all)
	struct FilterGroup{ 
		access(all)
		let filters: [{NFTFilter}]
		
		// TODO: Should a filter group be permitted to match multiple times?
		// e.g. "5 TS Moments from Set 3"
		// metadata cache so that we don't have to resolve views multiple times
		access(all)
		let cache: MetadataCache
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}): Bool{ 
			for f in self.filters{ 
				if !f.match(nft: nft, cache: &self.cache as &MetadataCache){ 
					self.cache.clear()
					return false
				}
			}
			self.cache.clear()
			return true
		}
		
		init(_ filters: [{NFTFilter}]){ 
			self.filters = filters
			self.cache = MetadataCache()
		}
	}
	
	access(all)
	struct MetadataCache{ 
		// cache of uuid -> metadata views by type. This 
		// is used to prevent resolving metadata views over and over which
		// can be costly
		access(all)
		var cache:{ UInt64:{ Type: AnyStruct}}
		
		access(all)
		fun get(_ id: UInt64, _ type: Type, _ nft: &{NonFungibleToken.NFT}): AnyStruct?{ 
			if self.cache[id] == nil{ 
				self.cache[id] ={} 
			}
			if (self.cache[id]!)[type] == nil{ 
				let tmp = &self.cache[id]! as auth(Mutate) &{Type: AnyStruct}
				tmp[type] = nft.resolveView(type)
			}
			return (self.cache[id]!)[type]
		}
		
		access(all)
		fun clear(){ 
			self.cache ={} 
		}
		
		init(){ 
			self.cache ={} 
		}
	}
	
	access(all)
	struct UuidFilter: NFTFilter{ 
		access(all)
		let uuid: UInt64
		
		access(all)
		let type: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return nft.uuid == self.uuid
		}
		
		init(_ uuid: UInt64){ 
			self.uuid = uuid
			self.type = self.getType()
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "uuid": self.uuid, "filterType": self.getType()}
		}
	}
	
	access(all)
	struct TypeFilter: NFTFilter{ 
		access(all)
		let nftType: Type
		
		access(all)
		let filterType: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return nft.getType() == self.nftType
		}
		
		init(_ type: Type){ 
			self.nftType = type
			self.filterType = self.getType()
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "nftType": self.nftType, "filterType": self.getType()}
		}
	}
	
	access(all)
	struct EditionNameFilter: NFTFilter{ 
		access(all)
		let type: Type
		
		access(all)
		let name: String
		
		access(all)
		let filterType: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			if nft.getType() != self.type{ 
				return false
			}
			let c = cache.get(nft.uuid, Filter.EditionsType, nft) ?? panic("editions not found!!!!")
			if c == nil{ 
				return false
			}
			let editions = c! as! MetadataViews.Editions
			for e in editions.infoList{ 
				if e.name == nil{ 
					continue
				}
				if e.name! == self.name{ 
					return true
				}
			}
			return false
		}
		
		init(_ type: Type, name: String){ 
			self.type = type
			self.name = name
			self.filterType = self.getType()
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "type": self.type, "name": self.name, "filterType": self.getType()}
		}
	}
	
	access(all)
	struct TypeAndIDFilter: NFTFilter{ 
		access(all)
		let nftType: Type
		
		access(all)
		let nftID: UInt64
		
		access(all)
		let filterType: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return nft.id == self.nftID && self.nftType == nft.getType()
		}
		
		init(_ type: Type, _ id: UInt64){ 
			self.nftType = type
			self.nftID = id
			self.filterType = self.getType()
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "nftType": self.nftType, "nftID": self.nftID, "filterType": self.getType()}
		}
	}
	
	access(all)
	struct TypeAndIDsFilter: NFTFilter{ 
		access(all)
		let nftType: Type
		
		access(all)
		let ids:{ UInt64: Bool}
		
		access(all)
		let filterType: Type
		
		init(_ type: Type, _ ids: [UInt64]){ 
			self.nftType = type
			self.filterType = self.getType()
			self.ids ={} 
			for id in ids{ 
				self.ids[id] = true
			}
		}
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return self.ids[nft.id] == true && self.nftType == nft.getType()
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "nftType": self.nftType, "ids": self.ids, "filterType": self.getType()}
		}
	}
	
	access(all)
	struct TraitPartial{ 
		access(all)
		let value: AnyStruct?
		
		access(all)
		let rarity: MetadataViews.Rarity?
		
		access(all)
		let filterType: Type
		
		init(_ value: AnyStruct?, _ rarity: MetadataViews.Rarity?){ 
			self.value = value
			self.rarity = rarity
			self.filterType = self.getType()
		}
	}
	
	access(all)
	struct TraitsFilter: NFTFilter{ 
		access(all)
		let traits:{ String: TraitPartial}
		
		access(all)
		let nftType: Type
		
		access(all)
		let filterType: Type
		
		init(traits:{ String: TraitPartial}, nftType: Type){ 
			self.traits = traits
			self.nftType = nftType
			self.filterType = self.getType()
		}
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			assert(nft.getType() == self.nftType, message: "mismatched nft type")
			let traits = cache.get(nft.uuid, Filter.TraitsType, nft)
			if traits == nil{ 
				return false
			}
			let countedTraits:{ String: Bool} ={} 
			for trait in (traits! as! MetadataViews.Traits).traits{ 
				if self.traits[trait.name] == nil || countedTraits[trait.name] != nil{ 
					continue
				}
				let partial = self.traits[trait.name]!
				if partial.value != nil{ 
					if Filter.equal(partial.value!, trait.value){ 
						countedTraits.insert(key: trait.name, true)
					}
				}
			}
			return countedTraits.keys.length == self.traits.keys.length
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "traits": self.traits, "filterType": self.getType()}
		}
	}
	
	access(all)
	fun equal(_ val1: AnyStruct, _ val2: AnyStruct): Bool{ 
		if val1.getType() != val2.getType(){ 
			return false
		}
		switch val1.getType(){ 
			case Type<String>():
				return val1 as! String == val2 as! String
			case Type<UInt64>():
				return val1 as! UInt64 == val2 as! UInt64
			case Type<UFix64>():
				return val1 as! UFix64 == val2 as! UFix64
			case Type<Bool>():
				return val1 as! Bool == val2 as! Bool
			case Type<Fix64>():
				return val1 as! Fix64 == val2 as! Fix64
			case Type<Int>():
				return val1 as! Int == val2 as! Int
			case Type<Address>():
				return val1 as! Address == val2 as! Address
			case Type<Int8>():
				return val1 as! Int8 == val2 as! Int8
			case Type<Int16>():
				return val1 as! Int16 == val2 as! Int16
			case Type<Int32>():
				return val1 as! Int32 == val2 as! Int32
			case Type<Int64>():
				return val1 as! Int64 == val2 as! Int64
			case Type<Int128>():
				return val1 as! Int128 == val2 as! Int128
			case Type<Int256>():
				return val1 as! Int256 == val2 as! Int256
			case Type<UInt8>():
				return val1 as! UInt8 == val2 as! UInt8
			case Type<UInt16>():
				return val1 as! UInt16 == val2 as! UInt16
			case Type<UInt32>():
				return val1 as! UInt32 == val2 as! UInt32
			case Type<UInt128>():
				return val1 as! UInt128 == val2 as! UInt128
			case Type<UInt256>():
				return val1 as! UInt256 == val2 as! UInt256
			case Type<Word8>():
				return val1 as! Word8 == val2 as! Word8
			case Type<Word16>():
				return val1 as! Word16 == val2 as! Word16
			case Type<Word32>():
				return val1 as! Word32 == val2 as! Word32
			case Type<Word64>():
				return val1 as! Word64 == val2 as! Word64
		}
		return false
	}
	
	access(all)
	struct OrFilter: NFTFilter{ 
		access(all)
		let a:{ NFTFilter}
		
		access(all)
		let b:{ NFTFilter}
		
		access(all)
		let filterType: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return self.a.match(nft: nft, cache: cache) || self.b.match(nft: nft, cache: cache)
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "a": self.a.getDetails(), "b": self.b.getDetails(), "filterType": self.filterType}
		}
		
		init(_ a:{ NFTFilter}, b:{ NFTFilter}){ 
			self.a = a
			self.b = b
			self.filterType = self.getType()
		}
	}
	
	access(all)
	struct AndFilter: NFTFilter{ 
		access(all)
		let a:{ NFTFilter}
		
		access(all)
		let b:{ NFTFilter}
		
		access(all)
		let filterType: Type
		
		access(all)
		fun match(nft: &{NonFungibleToken.NFT}, cache: &MetadataCache): Bool{ 
			return self.a.match(nft: nft, cache: cache) && self.b.match(nft: nft, cache: cache)
		}
		
		access(all)
		fun getDetails(): AnyStruct{ 
			return{ "a": self.a.getDetails(), "b": self.b.getDetails(), "filterType": self.filterType}
		}
		
		init(_ a:{ NFTFilter}, b:{ NFTFilter}){ 
			self.a = a
			self.b = b
			self.filterType = self.getType()
		}
	}
	
	init(){ 
		self.TraitsType = Type<MetadataViews.Traits>()
		self.EditionsType = Type<MetadataViews.Editions>()
	}
}
