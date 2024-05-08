// You can create concrete poems with these alphabet resources.
access(all)
contract ConcreteAlphabets{ 
	access(all)
	resource A{} 
	
	access(all)
	resource B{} 
	
	access(all)
	resource C{} 
	
	access(all)
	resource D{} 
	
	access(all)
	resource E{} 
	
	access(all)
	resource F{} 
	
	access(all)
	resource G{} 
	
	access(all)
	resource H{} 
	
	access(all)
	resource I{} 
	
	access(all)
	resource J{} 
	
	access(all)
	resource K{} 
	
	access(all)
	resource L{} 
	
	access(all)
	resource M{} 
	
	access(all)
	resource N{} 
	
	access(all)
	resource O{} 
	
	access(all)
	resource P{} 
	
	access(all)
	resource Q{} 
	
	access(all)
	resource R{} 
	
	access(all)
	resource S{} 
	
	access(all)
	resource T{} 
	
	access(all)
	resource U{} 
	
	access(all)
	resource V{} 
	
	access(all)
	resource W{} 
	
	access(all)
	resource X{} 
	
	access(all)
	resource Y{} 
	
	access(all)
	resource Z{} 
	
	access(all)
	resource a{} 
	
	access(all)
	resource b{} 
	
	access(all)
	resource c{} 
	
	access(all)
	resource d{} 
	
	access(all)
	resource e{} 
	
	access(all)
	resource f{} 
	
	access(all)
	resource g{} 
	
	access(all)
	resource h{} 
	
	access(all)
	resource i{} 
	
	access(all)
	resource j{} 
	
	access(all)
	resource k{} 
	
	access(all)
	resource l{} 
	
	access(all)
	resource m{} 
	
	access(all)
	resource n{} 
	
	access(all)
	resource o{} 
	
	access(all)
	resource p{} 
	
	access(all)
	resource q{} 
	
	access(all)
	resource r{} 
	
	access(all)
	resource s{} 
	
	access(all)
	resource t{} 
	
	access(all)
	resource u{} 
	
	access(all)
	resource v{} 
	
	access(all)
	resource w{} 
	
	access(all)
	resource x{} 
	
	access(all)
	resource y{} 
	
	access(all)
	resource z{} 
	
	access(all)
	resource _{} 
	
	access(all)
	fun newLetter(_ ch: Character): @AnyResource{ 
		switch ch{ 
			case "A":
				return <-create A()
			case "B":
				return <-create B()
			case "C":
				return <-create C()
			case "D":
				return <-create D()
			case "E":
				return <-create E()
			case "F":
				return <-create F()
			case "G":
				return <-create G()
			case "H":
				return <-create H()
			case "I":
				return <-create I()
			case "J":
				return <-create J()
			case "K":
				return <-create K()
			case "L":
				return <-create L()
			case "M":
				return <-create M()
			case "N":
				return <-create N()
			case "O":
				return <-create O()
			case "P":
				return <-create P()
			case "Q":
				return <-create Q()
			case "R":
				return <-create R()
			case "S":
				return <-create S()
			case "T":
				return <-create T()
			case "U":
				return <-create U()
			case "V":
				return <-create V()
			case "W":
				return <-create W()
			case "X":
				return <-create X()
			case "Y":
				return <-create Y()
			case "Z":
				return <-create Z()
			case "a":
				return <-create a()
			case "b":
				return <-create b()
			case "c":
				return <-create c()
			case "d":
				return <-create d()
			case "e":
				return <-create e()
			case "f":
				return <-create f()
			case "g":
				return <-create g()
			case "h":
				return <-create h()
			case "i":
				return <-create i()
			case "j":
				return <-create j()
			case "k":
				return <-create k()
			case "l":
				return <-create l()
			case "m":
				return <-create m()
			case "n":
				return <-create n()
			case "o":
				return <-create o()
			case "p":
				return <-create p()
			case "q":
				return <-create q()
			case "r":
				return <-create r()
			case "s":
				return <-create s()
			case "t":
				return <-create t()
			case "u":
				return <-create u()
			case "v":
				return <-create v()
			case "w":
				return <-create w()
			case "x":
				return <-create x()
			case "y":
				return <-create y()
			case "z":
				return <-create z()
			default:
				return <-create _()
		}
	}
	
	access(all)
	fun newText(_ str: String): @[AnyResource]{ 
		var res: @[AnyResource] <- []
		for ch in str{ 
			res.append(<-ConcreteAlphabets.newLetter(ch))
		}
		return <-res
	}
	
	access(all)
	fun toCharacter(_ letter: &AnyResource): Character{ 
		switch letter.getType(){ 
			case Type<@A>():
				return "A"
			case Type<@B>():
				return "B"
			case Type<@C>():
				return "C"
			case Type<@D>():
				return "D"
			case Type<@E>():
				return "E"
			case Type<@F>():
				return "F"
			case Type<@G>():
				return "G"
			case Type<@H>():
				return "H"
			case Type<@I>():
				return "I"
			case Type<@J>():
				return "J"
			case Type<@K>():
				return "K"
			case Type<@L>():
				return "L"
			case Type<@M>():
				return "M"
			case Type<@N>():
				return "N"
			case Type<@O>():
				return "O"
			case Type<@P>():
				return "P"
			case Type<@Q>():
				return "Q"
			case Type<@R>():
				return "R"
			case Type<@S>():
				return "S"
			case Type<@T>():
				return "T"
			case Type<@U>():
				return "U"
			case Type<@V>():
				return "V"
			case Type<@W>():
				return "W"
			case Type<@X>():
				return "X"
			case Type<@Y>():
				return "Y"
			case Type<@Z>():
				return "Z"
			case Type<@a>():
				return "a"
			case Type<@b>():
				return "b"
			case Type<@c>():
				return "c"
			case Type<@d>():
				return "d"
			case Type<@e>():
				return "e"
			case Type<@f>():
				return "f"
			case Type<@g>():
				return "g"
			case Type<@h>():
				return "h"
			case Type<@i>():
				return "i"
			case Type<@j>():
				return "j"
			case Type<@k>():
				return "k"
			case Type<@l>():
				return "l"
			case Type<@m>():
				return "m"
			case Type<@n>():
				return "n"
			case Type<@o>():
				return "o"
			case Type<@p>():
				return "p"
			case Type<@q>():
				return "q"
			case Type<@r>():
				return "r"
			case Type<@s>():
				return "s"
			case Type<@t>():
				return "t"
			case Type<@u>():
				return "u"
			case Type<@v>():
				return "v"
			case Type<@w>():
				return "w"
			case Type<@x>():
				return "x"
			case Type<@y>():
				return "y"
			case Type<@z>():
				return "z"
			case Type<@_>():
				return " "
			default:
				return "?"
		}
	}
	
	access(all)
	fun toString(_ text: &[AnyResource]): String{ 
		var res: String = ""
		var i = 0
		while i < text.length{ 
			let letter = text[i] as &AnyResource
			res = res.concat(ConcreteAlphabets.toCharacter(letter).toString())
			i = i + 1
		}
		return res
	}
}
