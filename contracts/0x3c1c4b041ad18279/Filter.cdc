import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Filter {
    pub let TraitsType: Type
    pub let EditionsType: Type

    pub struct interface NFTFilter {
        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool
        pub fun getDetails(): AnyStruct
    }

    pub struct FilterGroup {
        pub let filters: [{NFTFilter}]

        // TODO: Should a filter group be permitted to match multiple times?
        // e.g. "5 TS Moments from Set 3"

        // metadata cache so that we don't have to resolve views multiple times
        pub let cache: MetadataCache

        pub fun match(nft: &NonFungibleToken.NFT): Bool {
            for f in self.filters {
                if !f.match(nft: nft, cache: &self.cache as &MetadataCache) {
                    self.cache.clear()
                    return false
                }
            }

            self.cache.clear()
            return true
        }

        init(_ filters: [{NFTFilter}]) {
            self.filters = filters
            self.cache = MetadataCache()
        }
    }

    pub struct MetadataCache {
        // cache of uuid -> metadata views by type. This 
        // is used to prevent resolving metadata views over and over which
        // can be costly
        pub var cache: {UInt64: {Type: AnyStruct}}

        pub fun get(_ id: UInt64, _ type: Type, _ nft: &NonFungibleToken.NFT): AnyStruct? {
            if self.cache[id] == nil {
                self.cache[id] = {} 
            }

            if self.cache[id]![type] == nil {
                let tmp = &self.cache[id]! as &{Type: AnyStruct}
                tmp[type] = nft.resolveView(type)
            }

            return self.cache[id]![type]
        }

        pub fun clear() {
            self.cache = {}
        }

        init() {
            self.cache = {}
        }
    }

    pub struct UuidFilter: NFTFilter {
        pub let uuid: UInt64
        pub let type: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            return nft.uuid == self.uuid
        }

        init(_ uuid: UInt64) {
            self.uuid = uuid
            self.type = self.getType()
        }

        pub fun getDetails(): AnyStruct {
            return {
                "uuid": self.uuid,
                "filterType": self.getType()
            }
        }
    }

    pub struct TypeFilter: NFTFilter {
        pub let nftType: Type
        pub let filterType: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            return nft.getType() == self.nftType
        }

        init (_ type: Type) {
            self.nftType = type
            self.filterType = self.getType()
        }

        pub fun getDetails(): AnyStruct {
            return {
                "nftType": self.nftType,
                "filterType": self.getType()
            }
        }
    }

    pub struct EditionNameFilter: NFTFilter {
        pub let type: Type
        pub let name: String

        pub let filterType: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            if nft.getType() != self.type {
                return false
            }

            let c = cache.get(nft.uuid, Filter.EditionsType, nft) ?? panic("editions not found!!!!")
            if c == nil {
                return false
            }

            let editions = c! as! MetadataViews.Editions
            
            for e in editions.infoList {
                if e.name == nil {
                    continue
                }

                if e.name! == self.name {
                    return true
                }
            }

            return false
        }

        init (_ type: Type, name: String) {
            self.type = type
            self.name = name

            self.filterType = self.getType()
        }

        pub fun getDetails(): AnyStruct {
            return {
                "type": self.type,
                "name": self.name,
                "filterType": self.getType()
            }
        }
    }

    pub struct TypeAndIDFilter: NFTFilter {
        pub let nftType: Type
        pub let nftID: UInt64
        pub let filterType: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            return nft.id == self.nftID && self.nftType == nft.getType()
        }

        init (_ type: Type, _ id: UInt64) {
            self.nftType = type
            self.nftID = id
            self.filterType = self.getType()
        }

        pub fun getDetails(): AnyStruct {
            return {
                "nftType": self.nftType,
                "nftID": self.nftID,
                "filterType": self.getType()
            }
        }  
    }

    pub struct TypeAndIDsFilter: NFTFilter {
        pub let nftType: Type
        pub let ids: {UInt64: Bool}
        pub let filterType: Type

        init(_ type: Type, _ ids: [UInt64]) {
            self.nftType = type
            self.filterType = self.getType()

            self.ids = {}
            for id in ids {
                self.ids[id] = true
            }
        }

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            return self.ids[nft.id] == true && self.nftType == nft.getType()
        }

        pub fun getDetails(): AnyStruct {
            return {
                "nftType": self.nftType,
                "ids": self.ids,
                "filterType": self.getType()
            }
        }
    }

    pub struct TraitPartial {
        pub let value: AnyStruct?
        pub let rarity: MetadataViews.Rarity?
        pub let filterType: Type

        init(_ value: AnyStruct?, _ rarity: MetadataViews.Rarity?) {
            self.value = value
            self.rarity = rarity
            self.filterType = self.getType()
        }
    }

    pub struct TraitsFilter: NFTFilter {
        pub let traits: {String: TraitPartial}
        pub let nftType: Type
        pub let filterType: Type

        init(traits: {String: TraitPartial}, nftType: Type) {
            self.traits = traits
            self.nftType = nftType
            self.filterType = self.getType()
        }

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool {
            assert(nft.getType() == self.nftType, message: "mismatched nft type")
            let traits = cache.get(nft.uuid, Filter.TraitsType, nft)
            if traits == nil {
                return false
            }

            let countedTraits: {String: Bool} = {}

            for trait in (traits! as! MetadataViews.Traits).traits {
                if self.traits[trait.name] == nil || countedTraits[trait.name] != nil {
                    continue
                }

                let partial = self.traits[trait.name]!
                if partial.value != nil {
                    if Filter.equal(partial.value!, trait.value) {
                        countedTraits.insert(key: trait.name, true)
                    }
                }
            }

            return countedTraits.keys.length == self.traits.keys.length
        }

        pub fun getDetails(): AnyStruct {
            return {
                "traits": self.traits,
                "filterType": self.getType()
            }
        }
    }

    pub fun equal(_ val1: AnyStruct, _ val2: AnyStruct): Bool {
        if val1.getType() != val2.getType() {
            return false
        }

        switch(val1.getType()) {
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

    pub struct OrFilter: NFTFilter {
        pub let a: {NFTFilter}
        pub let b: {NFTFilter}
        pub let filterType: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool { 
            return self.a.match(nft: nft, cache: cache) || self.b.match(nft: nft, cache: cache)
        }

        pub fun getDetails(): AnyStruct {
            return {
                "a": self.a.getDetails(),
                "b": self.b.getDetails(),
                "filterType": self.filterType
            }
        }

        init(_ a: {NFTFilter}, b: {NFTFilter}) {
            self.a = a
            self.b = b
            self.filterType = self.getType()
        }
    }

    pub struct AndFilter: NFTFilter {
        pub let a: {NFTFilter}
        pub let b: {NFTFilter}
        pub let filterType: Type

        pub fun match(nft: &NonFungibleToken.NFT, cache: &MetadataCache): Bool { 
            return self.a.match(nft: nft, cache: cache) && self.b.match(nft: nft, cache: cache)
        }

        pub fun getDetails(): AnyStruct {
            return {
                "a": self.a.getDetails(),
                "b": self.b.getDetails(),
                "filterType": self.filterType
            }
        }

        init(_ a: {NFTFilter}, b: {NFTFilter}) {
            self.a = a
            self.b = b
            self.filterType = self.getType()
        }
    }

    init() {
        self.TraitsType = Type<MetadataViews.Traits>()
        self.EditionsType = Type<MetadataViews.Editions>()
    }
}