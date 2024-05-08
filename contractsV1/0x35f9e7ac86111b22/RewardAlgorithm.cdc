access(all)
contract interface RewardAlgorithm{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	resource interface Algorithm{ 
		access(all)
		fun randomAlgorithm(): Int
	}
}
