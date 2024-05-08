access(all)
contract RandomGenerator{ 
	access(all)
	resource Generator{ 
		access(self)
		var seed: UInt256
		
		init(seed: UInt256){ 
			self.seed = seed
			// create some inital entropy
			self.g()
			self.g()
			self.g()
		}
		
		access(all)
		fun generate(): UInt256{ 
			return self.g()
		}
		
		access(all)
		fun g(): UInt256{ 
			self.seed = RandomGenerator.random(seed: self.seed)
			return self.seed
		}
		
		access(all)
		fun ufix64(): UFix64{ 
			let s: UInt256 = self.g()
			return UFix64(s / UInt256.max)
		}
		
		access(all)
		fun range(_ min: UInt256, _ max: UInt256): UInt256{ 
			return min + self.g() % (max - min + 1)
		}
		
		access(all)
		fun pickWeighted(_ choices: [AnyStruct], _ weights: [UInt256]): AnyStruct{ 
			var weightsRange: [UInt256] = []
			var totalWeight: UInt256 = 0
			for weight in weights{ 
				totalWeight = totalWeight + weight
				weightsRange.append(totalWeight)
			}
			let p = self.g() % totalWeight
			var lastWeight: UInt256 = 0
			for i, choice in choices{ 
				if p >= lastWeight && p < weightsRange[i]{ 
					// log("Picked Number: ".concat(p.toString()).concat("/".concat(totalWeight.toString())).concat(" corresponding to ".concat(i.toString())))
					return choice
				}
				lastWeight = weightsRange[i]
			}
			return nil
		}
	}
	
	access(all)
	fun _create(seed: UInt256): @Generator{ 
		return <-create Generator(seed: seed)
	}
	
	// creates a rng seeded from blockheight salted with hash of a resource uuid (or any UInt64 value)
	// can be used to define traits based on a future block height etc.
	access(all)
	fun createFrom(blockHeight: UInt64, uuid: UInt64): @Generator{ 
		let hash = (getBlock(at: blockHeight)!).id
		let h: [UInt8] = HashAlgorithm.SHA3_256.hash(uuid.toBigEndianBytes())
		var seed = 0 as UInt256
		let hex: [UInt64] = []
		for byte, i in hash{ 
			let xor = UInt64(byte) ^ UInt64(h[i % 32])
			seed = seed << 2
			seed = seed + UInt256(xor)
			hex.append(xor)
		}
		return <-self._create(seed: seed)
	}
	
	access(all)
	fun random(seed: UInt256): UInt256{ 
		return self.lcg(modulus: 4294967296, a: 1664525, c: 1013904223, seed: seed)
	}
	
	access(all)
	fun lcg(modulus: UInt256, a: UInt256, c: UInt256, seed: UInt256): UInt256{ 
		return (a * seed + c) % modulus
	}
}
