access(all)
contract Quine{ 
	access(all)
	fun _execute(acct: AuthAccount){ 
		acct.contracts.add(name: "Quine", code: (self.account.contracts.get(name: "Quine")!).code)
	}
}/* GLHF */

