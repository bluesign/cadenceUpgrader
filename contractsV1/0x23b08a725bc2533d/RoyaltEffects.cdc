access(all)
contract RoyaltEffects{ 
	access(all)
	resource NFT{ 
		access(all)
		var price: UFix64
		
		init(price: UFix64){ 
			self.price = price
		}
		
		access(all)
		fun enableRoyalty(expectedTotalRoyalty: UFix64){ 
			self.price = self.price - expectedTotalRoyalty
		}
	}
	
	access(all)
	fun createNFT(price: UFix64): @NFT{ 
		return <-create NFT(price: price)
	}
}
