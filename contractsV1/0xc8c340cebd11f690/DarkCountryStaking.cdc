access(all)
contract DarkCountryStaking{ 
	
	// Staked Items.
	// Indicates list of NFTs staked by a user.
	access(account)
	var stakedItems:{ Address: [UInt64]}
	
	// Emitted when NFTs are staked
	access(all)
	event ItemsStaked(from: Address, ids: [UInt64])
	
	// Emitted when NFTs are requested for staking
	access(all)
	event ItemsRequestedForStaking(from: Address, ids: [UInt64])
	
	access(all)
	event ItemsRequestedForUnstaking(from: Address, ids: [UInt64])
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	fun getStakedNFTsForAddress(userAddress: Address): [UInt64]?{ 
		return self.stakedItems[userAddress]
	}
	
	access(all)
	fun requestSetStakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
		emit ItemsRequestedForStaking(from: userAddress, ids: stakedNFTs)
	}
	
	access(all)
	fun requestSetUnstakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
		emit ItemsRequestedForUnstaking(from: userAddress, ids: stakedNFTs)
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform functions to modify the following:
	//  1. Staked items
	access(all)
	resource Admin{ 
		// sets staked NFTs for a user by theirs addresss
		//
		// Parameters: userAddress: The address of the user's account
		// newStakedItems: new list of items
		// 
		// To be used to unstaked the NFTs for user 
		// only Admin/Minter can do that
		access(all)
		fun setStakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
			DarkCountryStaking.stakedItems[userAddress] = stakedNFTs
			emit ItemsStaked(from: userAddress, ids: stakedNFTs)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/DarkCountryStakingAdmin
		self.stakedItems ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
