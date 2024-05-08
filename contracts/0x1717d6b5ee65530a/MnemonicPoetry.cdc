import BIP39WordList from "./BIP39WordList.cdc"

pub contract MnemonicPoetry {

    pub event NewMnemonic(mnemonic: Mnemonic)
    pub event NewMnemonicPoem(mnemonicPoem: MnemonicPoem)

    pub struct Mnemonic {
        pub let words: [String]
        pub let blockID: [UInt8; 32]
        pub let blockHeight: UInt64
        pub let blockTimestamp: UFix64

        init(
            words: [String],
            blockID: [UInt8; 32],
            blockHeight: UInt64,
            blockTimestamp: UFix64
        ) {
            self.words = words
            self.blockID = blockID
            self.blockHeight = blockHeight
            self.blockTimestamp = blockTimestamp
        }
    }

    pub struct MnemonicPoem {
        pub let mnemonic: Mnemonic
        pub let poem: String

        init(
            mnemonic: Mnemonic,
            poem: String
        ) {
            self.mnemonic = mnemonic
            self.poem = poem
        }
    }

    pub resource interface PoetryCollectionPublic {
        pub var mnemonics: [Mnemonic]
        pub var poems: [MnemonicPoem]
    }

    pub resource PoetryCollection: PoetryCollectionPublic {
        pub var mnemonics: [Mnemonic]
        pub var poems: [MnemonicPoem]

        init() {
            self.mnemonics = []
            self.poems = []
        }

        pub fun findMnemonic(): Mnemonic {
            let block = getCurrentBlock()
            let entropyWithChecksum = self.blockIDToEntropyWithChecksum(blockID: block.id)
            let words = self.entropyWithChecksumToWords(entropyWithChecksum: entropyWithChecksum)
            let mnemonic = Mnemonic(
                words: words,
                blockID: block.id,
                blockHeight: block.height,
                blockTimestamp: block.timestamp
            )
            self.mnemonics.append(mnemonic)
            emit NewMnemonic(mnemonic: mnemonic)
            return mnemonic
        }

        priv fun blockIDToEntropyWithChecksum(blockID: [UInt8; 32]): [UInt8] {
            var entropy: [UInt8] = []
            var i = 0
            while i < 16 {
                entropy.append(blockID[i] ^ blockID[i + 16])
                i = i + 1
            }
            let checksum = HashAlgorithm.SHA2_256.hash(entropy)[0]
            var entropyWithChecksum = entropy
            entropyWithChecksum.append(checksum)
            return entropyWithChecksum
        }

        priv fun entropyWithChecksumToWords(entropyWithChecksum: [UInt8]): [String] {
            var words: [String] = []
            var i = 0
            while i < 12 {
                let index = self.extract11Bits(from: entropyWithChecksum, at: i * 11)
                words.append(BIP39WordList.ja[index])
                i = i + 1
            }
            return words
        }

        priv fun extract11Bits(from bytes: [UInt8], at bitPosition: Int): Int {
            let bytePosition = bitPosition / 8
            let bitOffset = bitPosition % 8

            var res: UInt32 = 0
            if bytePosition < bytes.length {
                res = UInt32(bytes[bytePosition]) << 16
            }
            if bytePosition + 1 < bytes.length {
                res = res | (UInt32(bytes[bytePosition + 1]) << 8)
            }
            if bitOffset > 5 && bytePosition + 2 < bytes.length {
                res = res | UInt32(bytes[bytePosition + 2])
            }

            res = res >> UInt32(24 - 11 - bitOffset)
            res = res & 0x7FF
            return Int(res)
        }

        pub fun writePoem(mnemonic: Mnemonic, poem: String) {
            let mnemonicPoem = MnemonicPoem(
                mnemonic: mnemonic,
                poem: poem
            )
            self.poems.append(mnemonicPoem)
            emit NewMnemonicPoem(mnemonicPoem: mnemonicPoem)
        }
    }

    pub fun createEmptyPoetryCollection(): @PoetryCollection {
        return <- create PoetryCollection()
    }
}
