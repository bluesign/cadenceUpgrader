access(all)
contract Random{ 
	access(all)
	fun generateWithNumberSeed(seed: Number, amount: UInt8): [UFix64]{ 
		let hash: [UInt8] = HashAlgorithm.SHA3_256.hash(seed.toBigEndianBytes())
		return Random.generateWithBytesSeed(seed: hash, amount: amount)
	}
	
	access(all)
	fun generateWithBytesSeed(seed: [UInt8], amount: UInt8): [UFix64]{ 
		let randoms: [UFix64] = []
		var i: UInt8 = 0
		while i < amount{ 
			randoms.append(Random.generate(seed: seed))
			seed[0] = seed[0] == 255 ? 0 : seed[0] + 1
			i = i + 1
		}
		return randoms
	}
	
	access(all)
	fun generate(seed: [UInt8]): UFix64{ 
		let hash: [UInt8] = HashAlgorithm.KECCAK_256.hash(seed)
		var value: UInt64 = 0
		var i: Int = 0
		while i < hash.length{ 
			value = value + UInt64(hash[i])
			value = value << 8
			i = i + 1
		}
		value = value + UInt64(hash[0])
		return UFix64(value % 100_000) / 100_000.0
	}
}
