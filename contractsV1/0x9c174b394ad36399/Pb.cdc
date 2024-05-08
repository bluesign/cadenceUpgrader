access(all)
contract Pb{ 
	/// only support Varint and LengthDelim for now
	access(all)
	enum WireType: UInt8{ 
		access(all)
		case Varint
		
		access(all)
		case Fixed64
		
		access(all)
		case LengthDelim
		
		access(all)
		case StartGroup
		
		access(all)
		case EndGroup
		
		access(all)
		case Fixed32
	}
	
	access(all)
	struct TagType{ 
		access(all)
		let tag: UInt64
		
		access(all)
		let wt: WireType
		
		init(tag: UInt64, wt: UInt8){ 
			self.tag = tag
			self.wt = WireType(rawValue: wt)!
		}
	}
	
	access(all)
	struct Buffer{ 
		access(all)
		var idx: Int
		
		access(all)
		let b: [UInt8] // readonly of original pb msg
		
		
		init(raw: [UInt8]){ 
			self.idx = 0
			self.b = raw
		}
		
		// if idx >= b.length, means we're done
		access(all)
		fun hasMore(): Bool{ 
			return self.idx < self.b.length
		}
		
		// has to use struct as cadence can has only single return
		access(all)
		fun decKey(): TagType{ 
			let v = self.decVarint()
			return TagType(tag: v / 8, wt: UInt8(v % 8))
		}
		
		// modify self.idx
		access(all)
		fun decVarint(): UInt64{ 
			var ret: UInt64 = 0
			// zero-copy for lower gas cost even though it may not matter
			var i = 0
			while i < 10{ // varint max 10 bytes 
				
				let b = self.b[self.idx + i]
				ret = ret | UInt64(b & 0x7F) << UInt64(i * 7)
				if b < 0x80{ 
					self.idx = self.idx + i + 1
					return ret
				}
				i = i + 1
			}
			assert(i < 10, message: "invalid varint")
			return ret
		}
		
		// modify self.idx
		access(all)
		fun decBytes(): [UInt8]{ 
			let len = self.decVarint()
			let end = self.idx + Int(len)
			assert(end <= self.b.length, message: "invalid bytes length: ".concat(end.toString()))
			// array slice is https://github.com/onflow/cadence/pull/1315/files
			// return self.b.slice(from: self.Idx, upTo: end)
			var ret: [UInt8] = []
			while self.idx < end{ 
				ret.append(self.b[self.idx])
				self.idx = self.idx + 1
			}
			return ret
		}
	}
	
	// raw is UInt64 big endian, raw.length <= 8
	access(all)
	fun toUInt64(_ raw: [UInt8]): UInt64{ 
		let rawLen = raw.length
		assert(rawLen <= 8, message: "invalid raw length for UInt64")
		var ret: UInt64 = 0
		var i = 0
		while i < rawLen{ 
			let val = UInt64(raw[rawLen - 1 - i]) << UInt64(i * 8)
			ret = ret + val
			i = i + 1
		}
		return ret
	}
	
	// raw is UInt256 big endian, raw.length <= 32
	access(all)
	fun toUInt256(_ raw: [UInt8]): UInt256{ 
		let rawLen = raw.length
		assert(rawLen <= 32, message: "invalid raw length for UInt256")
		var ret: UInt256 = 0
		var i = 0
		while i < rawLen{ 
			let val = UInt256(raw[rawLen - 1 - i]) << UInt256(i * 8)
			ret = ret + val
			i = i + 1
		}
		return ret
	}
	
	access(all)
	fun toAddress(_ raw: [UInt8]): Address{ 
		return Address(self.toUInt64(raw))
	}
	
	access(all)
	fun toUFix64(_ raw: [UInt8]): UFix64{ 
		let val = self.toUInt64(raw)
		return UFix64(val / 100_000_000) + UFix64(val % 100_000_000) / 100_000_000.0
	}
	
	/// return hex string!
	access(all)
	fun toString(_ raw: [UInt8]): String{ 
		return String.encodeHex(raw)
	}
}
