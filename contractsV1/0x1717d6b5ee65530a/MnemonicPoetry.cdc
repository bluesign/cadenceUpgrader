import BIP39WordList from "./BIP39WordList.cdc"

access(all)
contract MnemonicPoetry{ 
	access(all)
	event NewMnemonic(mnemonic: Mnemonic)
	
	access(all)
	event NewMnemonicPoem(mnemonicPoem: MnemonicPoem)
	
	access(all)
	struct Mnemonic{ 
		access(all)
		let words: [String]
		
		access(all)
		let blockID: [UInt8; 32]
		
		access(all)
		let blockHeight: UInt64
		
		access(all)
		let blockTimestamp: UFix64
		
		init(words: [String], blockID: [UInt8; 32], blockHeight: UInt64, blockTimestamp: UFix64){ 
			self.words = words
			self.blockID = blockID
			self.blockHeight = blockHeight
			self.blockTimestamp = blockTimestamp
		}
	}
	
	access(all)
	struct MnemonicPoem{ 
		access(all)
		let mnemonic: Mnemonic
		
		access(all)
		let poem: String
		
		init(mnemonic: Mnemonic, poem: String){ 
			self.mnemonic = mnemonic
			self.poem = poem
		}
	}
	
	access(all)
	resource interface PoetryCollectionPublic{ 
		access(all)
		var mnemonics: [Mnemonic]
		
		access(all)
		var poems: [MnemonicPoem]
	}
	
	access(all)
	resource PoetryCollection: PoetryCollectionPublic{ 
		access(all)
		var mnemonics: [Mnemonic]
		
		access(all)
		var poems: [MnemonicPoem]
		
		init(){ 
			self.mnemonics = []
			self.poems = []
		}
		
		access(all)
		fun findMnemonic(): Mnemonic{ 
			let block = getCurrentBlock()
			let entropyWithChecksum = self.blockIDToEntropyWithChecksum(blockID: block.id)
			let words = self.entropyWithChecksumToWords(entropyWithChecksum: entropyWithChecksum)
			let mnemonic = Mnemonic(words: words, blockID: block.id, blockHeight: block.height, blockTimestamp: block.timestamp)
			self.mnemonics.append(mnemonic)
			emit NewMnemonic(mnemonic: mnemonic)
			return mnemonic
		}
		
		access(self)
		fun blockIDToEntropyWithChecksum(blockID: [UInt8; 32]): [UInt8]{ 
			var entropy: [UInt8] = []
			var i = 0
			while i < 16{ 
				entropy.append(blockID[i] ^ blockID[i + 16])
				i = i + 1
			}
			let checksum = HashAlgorithm.SHA2_256.hash(entropy)[0]
			var entropyWithChecksum = entropy
			entropyWithChecksum.append(checksum)
			return entropyWithChecksum
		}
		
		access(self)
		fun entropyWithChecksumToWords(entropyWithChecksum: [UInt8]): [String]{ 
			var words: [String] = []
			var i = 0
			while i < 12{ 
				let index = self.extract11Bits(from: entropyWithChecksum, at: i * 11)
				words.append(BIP39WordList.ja[index])
				i = i + 1
			}
			return words
		}
		
		access(self)
		fun extract11Bits(from bytes: [UInt8], at bitPosition: Int): Int{ 
			let bytePosition = bitPosition / 8
			let bitOffset = bitPosition % 8
			var res: UInt32 = 0
			if bytePosition < bytes.length{ 
				res = UInt32(bytes[bytePosition]) << 16
			}
			if bytePosition + 1 < bytes.length{ 
				res = res | UInt32(bytes[bytePosition + 1]) << 8
			}
			if bitOffset > 5 && bytePosition + 2 < bytes.length{ 
				res = res | UInt32(bytes[bytePosition + 2])
			}
			res = res >> UInt32(24 - 11 - bitOffset)
			res = res & 0x7FF
			return Int(res)
		}
		
		access(all)
		fun writePoem(mnemonic: Mnemonic, poem: String){ 
			let mnemonicPoem = MnemonicPoem(mnemonic: mnemonic, poem: poem)
			self.poems.append(mnemonicPoem)
			emit NewMnemonicPoem(mnemonicPoem: mnemonicPoem)
		}
	}
	
	access(all)
	fun createEmptyPoetryCollection(): @PoetryCollection{ 
		return <-create PoetryCollection()
	}
}
