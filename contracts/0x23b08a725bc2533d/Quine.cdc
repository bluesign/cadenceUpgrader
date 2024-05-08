 pub contract Quine {
 pub fun execute(acct
:AuthAccount ) { acct
.contracts.add (name:
"Quine", code :  self
.account   .contracts
.get (name: "Quine")!
.code) } } /* GLHF */