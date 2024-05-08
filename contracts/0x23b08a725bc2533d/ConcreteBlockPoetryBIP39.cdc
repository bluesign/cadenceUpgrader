import BIP39WordList from "./BIP39WordList.cdc"
import ConcreteAlphabets from "./ConcreteAlphabets.cdc"
import ConcreteAlphabetsHiragana from "./ConcreteAlphabetsHiragana.cdc"
import ConcreteAlphabetsHangle from "./ConcreteAlphabetsHangle.cdc"
import ConcreteAlphabetsSpanish from "./ConcreteAlphabetsSpanish.cdc"
import ConcreteAlphabetsSimplifiedChinese from "./ConcreteAlphabetsSimplifiedChinese.cdc"
import ConcreteAlphabetsTraditionalChinese from "./ConcreteAlphabetsTraditionalChinese.cdc"
import ConcreteAlphabetsFrench from "./ConcreteAlphabetsFrench.cdc"

pub contract ConcreteBlockPoetryBIP39 {

    pub event NewPoems(poems: [String])

    pub struct interface IPoetryLogic {
        pub fun generatePoems(blockID: [UInt8; 32]): [String]
        pub fun generateConcreteAlphabets(poems: [String]): @[[AnyResource]]
    }

    pub struct PoetryLogic: IPoetryLogic {
        pub fun generatePoems(blockID: [UInt8; 32]): [String] {
            let entropyWithChecksum = self.blockIDToEntropyWithChecksum(blockID: blockID)
            var poemEn = ""
            var poemJa = ""
            var poemKo = ""
            var poemEs = ""
            var poemZhCN = ""
            var poemZhTW = ""
            var poemFr = ""
            var poemIt = ""
            var poemCs = ""
            var poemPt = ""
            var i = 0
            while i < 12 {
                let index = self.extract11Bits(from: entropyWithChecksum, at: i * 11)
                poemEn = poemEn.concat(i > 0 ? " " : "").concat(BIP39WordList.en[index]!)
                poemJa = poemJa.concat(i > 0 ? " " : "").concat(BIP39WordList.ja[index]!)
                poemKo = poemKo.concat(i > 0 ? " " : "").concat(BIP39WordList.ko[index]!)
                poemEs = poemEs.concat(i > 0 ? " " : "").concat(BIP39WordList.es[index]!)
                poemZhCN = poemZhCN.concat(i > 0 ? " " : "").concat(BIP39WordList.zhCN[index]!)
                poemZhTW = poemZhTW.concat(i > 0 ? " " : "").concat(BIP39WordList.zhTW[index]!)
                poemFr = poemFr.concat(i > 0 ? " " : "").concat(BIP39WordList.fr[index]!)
                poemIt = poemIt.concat(i > 0 ? " " : "").concat(BIP39WordList.it[index]!)
                poemCs = poemCs.concat(i > 0 ? " " : "").concat(BIP39WordList.cs[index]!)
                poemPt = poemPt.concat(i > 0 ? " " : "").concat(BIP39WordList.pt[index]!)
                i = i + 1
            }
            return [
                poemEn,
                poemJa,
                poemKo,
                poemEs,
                poemZhCN,
                poemZhTW,
                poemFr,
                poemIt,
                poemCs,
                poemPt
            ]
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

        pub fun generateConcreteAlphabets(poems: [String]): @[[AnyResource]] {
            let concreteAlphabets: @[[AnyResource]] <- []
            concreteAlphabets.append(<- ConcreteAlphabets.newText(poems[0]))
            concreteAlphabets.append(<- ConcreteAlphabetsHiragana.newText(poems[1]))
            concreteAlphabets.append(<- ConcreteAlphabetsHangle.newText(poems[2]))
            concreteAlphabets.append(<- ConcreteAlphabetsSpanish.newText(poems[3]))
            concreteAlphabets.append(<- ConcreteAlphabetsSimplifiedChinese.newText(poems[4]))
            concreteAlphabets.append(<- ConcreteAlphabetsTraditionalChinese.newText(poems[5]))
            concreteAlphabets.append(<- ConcreteAlphabetsFrench.newText(poems[6]))
            concreteAlphabets.append(<- ConcreteAlphabets.newText(poems[7]))
            concreteAlphabets.append(<- ConcreteAlphabets.newText(poems[8]))
            concreteAlphabets.append(<- ConcreteAlphabets.newText(poems[9]))
            return <- concreteAlphabets
        }
    }

    pub resource interface PoetryCollectionPublic {
        pub var poems: @{UFix64: [AnyResource]}
    }

    pub resource PoetryCollection: PoetryCollectionPublic {

        pub var poems: @{UFix64: [AnyResource]}

        init() {
            self.poems <- {}
        }

        destroy() {
            destroy self.poems
        }

        pub fun writePoems(poetryLogic: {IPoetryLogic}) {
            let poems = poetryLogic.generatePoems(blockID: getCurrentBlock().id)
            self.poems[getCurrentBlock().timestamp] <-! <- poetryLogic.generateConcreteAlphabets(poems: poems)
            emit NewPoems(poems: poems)
        }
    }

    pub fun createEmptyPoetryCollection(): @PoetryCollection {
        return <- create PoetryCollection()
    }
}
