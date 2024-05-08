access(all)
contract Universe{ 
	access(all)
	resource Thing{ 
		access(all)
		fun is_necessary(): Bool{ 
			return true
		}
	}
}
