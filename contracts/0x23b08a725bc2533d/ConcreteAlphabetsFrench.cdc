// You can create concrete poems with these alphabet resources.

import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

pub contract ConcreteAlphabetsFrench {
    pub resource U00C0{} // À
    pub resource U00C2{} // Â
    pub resource U00C6{} // Æ
    pub resource U00C7{} // Ç
    pub resource U00C8{} // È
    pub resource U00C9{} // É
    pub resource U00CA{} // Ê
    pub resource U00CB{} // Ë
    pub resource U00CE{} // Î
    pub resource U00CF{} // Ï
    pub resource U00D4{} // Ô
    pub resource U00D9{} // Ù
    pub resource U00DB{} // Û
    pub resource U00DC{} // Ü
    pub resource U00E0{} // à
    pub resource U00E2{} // â
    pub resource U00E6{} // æ
    pub resource U00E7{} // ç
    pub resource U00E8{} // è
    pub resource U00E9{} // é
    pub resource U00EA{} // ê
    pub resource U00EB{} // ë
    pub resource U00EE{} // î
    pub resource U00EF{} // ï
    pub resource U00F4{} // ô
    pub resource U00F9{} // ù
    pub resource U00FB{} // û
    pub resource U00FC{} // ü
    pub resource U00FF{} // ÿ
    pub resource U0152{} // Œ
    pub resource U0153{} // œ
    pub resource U0178{} // Ÿ
    pub resource U02B3{} // ʳ
    pub resource U02E2{} // ˢ
    pub resource U1D48{} // ᵈ
    pub resource U1D49{} // ᵉ

    pub fun newLetter(_ ch: Character): @AnyResource {
        switch ch.toString() {
            case "À": return <- create U00C0()
            case "Â": return <- create U00C2()
            case "Æ": return <- create U00C6()
            case "Ç": return <- create U00C7()
            case "È": return <- create U00C8()
            case "É": return <- create U00C9()
            case "Ê": return <- create U00CA()
            case "Ë": return <- create U00CB()
            case "Î": return <- create U00CE()
            case "Ï": return <- create U00CF()
            case "Ô": return <- create U00D4()
            case "Ù": return <- create U00D9()
            case "Û": return <- create U00DB()
            case "Ü": return <- create U00DC()
            case "à": return <- create U00E0()
            case "â": return <- create U00E2()
            case "æ": return <- create U00E6()
            case "ç": return <- create U00E7()
            case "è": return <- create U00E8()
            case "é": return <- create U00E9()
            case "ê": return <- create U00EA()
            case "ë": return <- create U00EB()
            case "î": return <- create U00EE()
            case "ï": return <- create U00EF()
            case "ô": return <- create U00F4()
            case "ù": return <- create U00F9()
            case "û": return <- create U00FB()
            case "ü": return <- create U00FC()
            case "ÿ": return <- create U00FF()
            case "Œ": return <- create U0152()
            case "œ": return <- create U0153()
            case "Ÿ": return <- create U0178()
            case "ʳ": return <- create U02B3()
            case "ˢ": return <- create U02E2()
            case "ᵈ": return <- create U1D48()
            case "ᵉ": return <- create U1D49()
            default: return <- ConcreteAlphabets.newLetter(ch)
        }
    }

    pub fun newText(_ str: String): @[AnyResource] {
        var res: @[AnyResource] <- []
        for ch in str {
            res.append(<- ConcreteAlphabetsFrench.newLetter(ch))
        }
        return <- res
    }

    pub fun toCharacter(_ letter: &AnyResource): Character {
        switch letter.getType() {
            case Type<@U00C0>(): return "À"
            case Type<@U00C2>(): return "Â"
            case Type<@U00C6>(): return "Æ"
            case Type<@U00C7>(): return "Ç"
            case Type<@U00C8>(): return "È"
            case Type<@U00C9>(): return "É"
            case Type<@U00CA>(): return "Ê"
            case Type<@U00CB>(): return "Ë"
            case Type<@U00CE>(): return "Î"
            case Type<@U00CF>(): return "Ï"
            case Type<@U00D4>(): return "Ô"
            case Type<@U00D9>(): return "Ù"
            case Type<@U00DB>(): return "Û"
            case Type<@U00DC>(): return "Ü"
            case Type<@U00E0>(): return "à"
            case Type<@U00E2>(): return "â"
            case Type<@U00E6>(): return "æ"
            case Type<@U00E7>(): return "ç"
            case Type<@U00E8>(): return "è"
            case Type<@U00E9>(): return "é"
            case Type<@U00EA>(): return "ê"
            case Type<@U00EB>(): return "ë"
            case Type<@U00EE>(): return "î"
            case Type<@U00EF>(): return "ï"
            case Type<@U00F4>(): return "ô"
            case Type<@U00F9>(): return "ù"
            case Type<@U00FB>(): return "û"
            case Type<@U00FC>(): return "ü"
            case Type<@U00FF>(): return "ÿ"
            case Type<@U0152>(): return "Œ"
            case Type<@U0153>(): return "œ"
            case Type<@U0178>(): return "Ÿ"
            case Type<@U02B3>(): return "ʳ"
            case Type<@U02E2>(): return "ˢ"
            case Type<@U1D48>(): return "ᵈ"
            case Type<@U1D49>(): return "ᵉ"
            default: return ConcreteAlphabets.toCharacter(letter)
        }
    }

    pub fun toString(_ text: &[AnyResource]): String {
        var res: String = ""
        var i = 0
        while i < text.length {
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabetsFrench.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
