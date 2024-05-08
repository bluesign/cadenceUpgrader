access(all)
contract Setsuna{ 
	access(all)
	resource Ishiki{} 
	
	access(all)
	fun ikiru(){ 
		destroy create Ishiki()
	}
}
