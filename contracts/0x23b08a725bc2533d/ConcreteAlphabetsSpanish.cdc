// You can create concrete poems with these alphabet resources.

import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

pub contract ConcreteAlphabetsSpanish {
    pub resource U00C1{} // Á
    pub resource U00C9{} // É
    pub resource U00CD{} // Í
    pub resource U00D3{} // Ó
    pub resource U00DA{} // Ú
    pub resource U00DC{} // Ü
    pub resource U00D1{} // Ñ
    pub resource U00E1{} // á
    pub resource U00E9{} // é
    pub resource U00ED{} // í
    pub resource U00F3{} // ó
    pub resource U00FA{} // ú
    pub resource U00FC{} // ü
    pub resource U00F1{} // ñ
    pub resource U00AA{} // ª
    pub resource U00BA{} // º
    pub resource U00A1{} // ¡
    pub resource U00BF{} // ¿

    pub fun newLetter(_ ch: Character): @AnyResource {
        switch ch.toString() {
            case "Á": return <- create U00C1()
            case "É": return <- create U00C9()
            case "Í": return <- create U00CD()
            case "Ó": return <- create U00D3()
            case "Ú": return <- create U00DA()
            case "Ü": return <- create U00DC()
            case "Ñ": return <- create U00D1()
            case "á": return <- create U00E1()
            case "é": return <- create U00E9()
            case "í": return <- create U00ED()
            case "ó": return <- create U00F3()
            case "ú": return <- create U00FA()
            case "ü": return <- create U00FC()
            case "ñ": return <- create U00F1()
            case "ª": return <- create U00AA()
            case "º": return <- create U00BA()
            case "¡": return <- create U00A1()
            case "¿": return <- create U00BF()
            default: return <- ConcreteAlphabets.newLetter(ch)
        }
    }

    pub fun newText(_ str: String): @[AnyResource] {
        var res: @[AnyResource] <- []
        for ch in str {
            res.append(<- ConcreteAlphabetsSpanish.newLetter(ch))
        }
        return <- res
    }

    pub fun toCharacter(_ letter: &AnyResource): Character {
        switch letter.getType() {
            case Type<@U00C1>(): return "Á"
            case Type<@U00C9>(): return "É"
            case Type<@U00CD>(): return "Í"
            case Type<@U00D3>(): return "Ó"
            case Type<@U00DA>(): return "Ú"
            case Type<@U00DC>(): return "Ü"
            case Type<@U00D1>(): return "Ñ"
            case Type<@U00E1>(): return "á"
            case Type<@U00E9>(): return "é"
            case Type<@U00ED>(): return "í"
            case Type<@U00F3>(): return "ó"
            case Type<@U00FA>(): return "ú"
            case Type<@U00FC>(): return "ü"
            case Type<@U00F1>(): return "ñ"
            case Type<@U00AA>(): return "ª"
            case Type<@U00BA>(): return "º"
            case Type<@U00A1>(): return "¡"
            case Type<@U00BF>(): return "¿"
            default: return ConcreteAlphabets.toCharacter(letter)
        }
    }

    pub fun toString(_ text: &[AnyResource]): String {
        var res: String = ""
        var i = 0
        while i < text.length {
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabetsSpanish.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
