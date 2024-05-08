// You can create concrete poems with these alphabet resources.

pub contract ConcreteAlphabets {
    pub resource A {}
    pub resource B {}
    pub resource C {}
    pub resource D {}
    pub resource E {}
    pub resource F {}
    pub resource G {}
    pub resource H {}
    pub resource I {}
    pub resource J {}
    pub resource K {}
    pub resource L {}
    pub resource M {}
    pub resource N {}
    pub resource O {}
    pub resource P {}
    pub resource Q {}
    pub resource R {}
    pub resource S {}
    pub resource T {}
    pub resource U {}
    pub resource V {}
    pub resource W {}
    pub resource X {}
    pub resource Y {}
    pub resource Z {}
    pub resource a {}
    pub resource b {}
    pub resource c {}
    pub resource d {}
    pub resource e {}
    pub resource f {}
    pub resource g {}
    pub resource h {}
    pub resource i {}
    pub resource j {}
    pub resource k {}
    pub resource l {}
    pub resource m {}
    pub resource n {}
    pub resource o {}
    pub resource p {}
    pub resource q {}
    pub resource r {}
    pub resource s {}
    pub resource t {}
    pub resource u {}
    pub resource v {}
    pub resource w {}
    pub resource x {}
    pub resource y {}
    pub resource z {}
    pub resource _ {}

    pub fun newLetter(_ ch: Character): @AnyResource {
        switch ch {
            case "A": return <- create A()
            case "B": return <- create B()
            case "C": return <- create C()
            case "D": return <- create D()
            case "E": return <- create E()
            case "F": return <- create F()
            case "G": return <- create G()
            case "H": return <- create H()
            case "I": return <- create I()
            case "J": return <- create J()
            case "K": return <- create K()
            case "L": return <- create L()
            case "M": return <- create M()
            case "N": return <- create N()
            case "O": return <- create O()
            case "P": return <- create P()
            case "Q": return <- create Q()
            case "R": return <- create R()
            case "S": return <- create S()
            case "T": return <- create T()
            case "U": return <- create U()
            case "V": return <- create V()
            case "W": return <- create W()
            case "X": return <- create X()
            case "Y": return <- create Y()
            case "Z": return <- create Z()
            case "a": return <- create a()
            case "b": return <- create b()
            case "c": return <- create c()
            case "d": return <- create d()
            case "e": return <- create e()
            case "f": return <- create f()
            case "g": return <- create g()
            case "h": return <- create h()
            case "i": return <- create i()
            case "j": return <- create j()
            case "k": return <- create k()
            case "l": return <- create l()
            case "m": return <- create m()
            case "n": return <- create n()
            case "o": return <- create o()
            case "p": return <- create p()
            case "q": return <- create q()
            case "r": return <- create r()
            case "s": return <- create s()
            case "t": return <- create t()
            case "u": return <- create u()
            case "v": return <- create v()
            case "w": return <- create w()
            case "x": return <- create x()
            case "y": return <- create y()
            case "z": return <- create z()
            default: return <- create _()
        }
    }

    pub fun newText(_ str: String): @[AnyResource] {
        var res: @[AnyResource] <- []
        for ch in str {
            res.append(<- ConcreteAlphabets.newLetter(ch))
        }
        return <- res
    }

    pub fun toCharacter(_ letter: &AnyResource): Character {
        switch letter.getType() {
            case Type<@A>(): return "A"
            case Type<@B>(): return "B"
            case Type<@C>(): return "C"
            case Type<@D>(): return "D"
            case Type<@E>(): return "E"
            case Type<@F>(): return "F"
            case Type<@G>(): return "G"
            case Type<@H>(): return "H"
            case Type<@I>(): return "I"
            case Type<@J>(): return "J"
            case Type<@K>(): return "K"
            case Type<@L>(): return "L"
            case Type<@M>(): return "M"
            case Type<@N>(): return "N"
            case Type<@O>(): return "O"
            case Type<@P>(): return "P"
            case Type<@Q>(): return "Q"
            case Type<@R>(): return "R"
            case Type<@S>(): return "S"
            case Type<@T>(): return "T"
            case Type<@U>(): return "U"
            case Type<@V>(): return "V"
            case Type<@W>(): return "W"
            case Type<@X>(): return "X"
            case Type<@Y>(): return "Y"
            case Type<@Z>(): return "Z"
            case Type<@a>(): return "a"
            case Type<@b>(): return "b"
            case Type<@c>(): return "c"
            case Type<@d>(): return "d"
            case Type<@e>(): return "e"
            case Type<@f>(): return "f"
            case Type<@g>(): return "g"
            case Type<@h>(): return "h"
            case Type<@i>(): return "i"
            case Type<@j>(): return "j"
            case Type<@k>(): return "k"
            case Type<@l>(): return "l"
            case Type<@m>(): return "m"
            case Type<@n>(): return "n"
            case Type<@o>(): return "o"
            case Type<@p>(): return "p"
            case Type<@q>(): return "q"
            case Type<@r>(): return "r"
            case Type<@s>(): return "s"
            case Type<@t>(): return "t"
            case Type<@u>(): return "u"
            case Type<@v>(): return "v"
            case Type<@w>(): return "w"
            case Type<@x>(): return "x"
            case Type<@y>(): return "y"
            case Type<@z>(): return "z"
            case Type<@_>(): return " "
            default: return "?"
        }
    }

    pub fun toString(_ text: &[AnyResource]): String {
        var res: String = ""
        var i = 0
        while i < text.length {
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabets.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
