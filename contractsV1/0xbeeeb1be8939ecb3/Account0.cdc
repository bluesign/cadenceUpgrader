access(all)
contract Account0{ 
	access(all)
	var n: Int
	
	access(all)
	var url1: String
	
	access(all)
	var url2: String
	
	access(all)
	var totalSupply1: UInt64
	
	access(all)
	var totalSupply2: UInt64
	
	access(all)
	fun setN(_n: Int){ 
		self.n = _n
	}
	
	access(all)
	fun setUrl1(newUrl: String){ 
		self.url1 = newUrl
	}
	
	access(all)
	fun setUrl2(newUrl: String){ 
		self.url2 = newUrl
	}
	
	access(all)
	resource Collection1{ 
		access(all)
		var collection: @{UInt64: NFT1}
		
		access(all)
		fun deposit(nft: @NFT1){ 
			self.collection[nft.id] <-! nft
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.collection.keys
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &NFT1{ 
			return (&self.collection[id] as &NFT1?)!
		}
		
		init(){ 
			self.collection <-{} 
		}
	}
	
	access(all)
	resource Collection2{ 
		access(all)
		var collection: @{UInt64: NFT2}
		
		access(all)
		fun deposit(nft: @NFT2){ 
			self.collection[nft.id] <-! nft
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.collection.keys
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &NFT2{ 
			return (&self.collection[id] as &NFT2?)!
		}
		
		init(){ 
			self.collection <-{} 
		}
	}
	
	access(all)
	resource NFT1{ 
		access(all)
		let id: UInt64
		
		access(all)
		let dato1: String
		
		access(all)
		let dato2: String
		
		access(all)
		let dato3: String
		
		access(all)
		let dato4: String
		
		access(all)
		let dato5: String
		
		access(all)
		let dato6: String
		
		access(all)
		let dato7: String
		
		access(all)
		let dato8: String
		
		access(all)
		let dato9: String
		
		access(all)
		let dato10: String
		
		access(all)
		let dato_11: String
		
		access(all)
		let dato_12: String
		
		access(all)
		let dato_13: String
		
		access(all)
		let dato_14: String
		
		access(all)
		let dato_15: String
		
		access(all)
		let dato_16: String
		
		init(
			_dato_11: String,
			_dato_12: String,
			_dato_13: String,
			_dato_14: String,
			_dato_15: String,
			_dato_16: String
		){ 
			self.id = Account0.totalSupply1
			self.dato1 = "dato1"
			self.dato2 = "dato2"
			self.dato3 = "dato3"
			self.dato4 = "dato4"
			self.dato5 = "dato5"
			self.dato6 = "dato6"
			self.dato7 = "dato7"
			self.dato8 = "dato8"
			self.dato9 = "dato9"
			self.dato10 = "dato10"
			self.dato_11 = _dato_11
			self.dato_12 = _dato_12
			self.dato_13 = _dato_13
			self.dato_14 = _dato_14
			self.dato_15 = _dato_15
			self.dato_16 = _dato_16
			Account0.totalSupply1 = Account0.totalSupply1 + 1
		}
	}
	
	access(all)
	resource NFT2{ 
		access(all)
		let id: UInt64
		
		access(all)
		let dato1: String
		
		access(all)
		let dato2: String
		
		access(all)
		let dato3: String
		
		access(all)
		let dato4: String
		
		access(all)
		let dato5: String
		
		access(all)
		let dato6: String
		
		access(all)
		let dato7: String
		
		access(all)
		let dato8: String
		
		access(all)
		let dato9: String
		
		access(all)
		let dato10: String
		
		access(all)
		let dato_11: String
		
		access(all)
		let dato_12: String
		
		access(all)
		let dato_13: String
		
		access(all)
		let dato_14: String
		
		access(all)
		let dato_15: String
		
		access(all)
		let dato_16: String
		
		init(
			_dato_11: String,
			_dato_12: String,
			_dato_13: String,
			_dato_14: String,
			_dato_15: String,
			_dato_16: String
		){ 
			self.id = Account0.totalSupply2
			self.dato1 = "dato1"
			self.dato2 = "dato2"
			self.dato3 = "dato3"
			self.dato4 = "dato4"
			self.dato5 = "dato5"
			self.dato6 = "dato6"
			self.dato7 = "dato7"
			self.dato8 = "dato8"
			self.dato9 = "dato9"
			self.dato10 = "dato10"
			self.dato_11 = _dato_11
			self.dato_12 = _dato_12
			self.dato_13 = _dato_13
			self.dato_14 = _dato_14
			self.dato_15 = _dato_15
			self.dato_16 = _dato_16
			Account0.totalSupply2 = Account0.totalSupply2 + 1
		}
	}
	
	access(all)
	fun createCollection1(): @Collection1{ 
		return <-create Account0.Collection1()
	}
	
	access(all)
	fun createCollection2(): @Collection2{ 
		return <-create Account0.Collection2()
	}
	
	access(all)
	fun createNFT1(
		dato_11: String,
		dato_12: String,
		dato_13: String,
		dato_14: String,
		dato_15: String,
		dato_16: String
	): @NFT1{ 
		return <-create Account0.NFT1(
			_dato_11: dato_11,
			_dato_12: dato_12,
			_dato_13: dato_13,
			_dato_14: dato_14,
			_dato_15: dato_15,
			_dato_16: dato_16
		)
	}
	
	access(all)
	fun createNFT2(
		dato_11: String,
		dato_12: String,
		dato_13: String,
		dato_14: String,
		dato_15: String,
		dato_16: String
	): @NFT2{ 
		return <-create Account0.NFT2(
			_dato_11: dato_11,
			_dato_12: dato_12,
			_dato_13: dato_13,
			_dato_14: dato_14,
			_dato_15: dato_15,
			_dato_16: dato_16
		)
	}
	
	init(){ 
		self.totalSupply1 = 0
		self.totalSupply2 = 0
		self.n = 0
		self.url1 = "www.blablabla.com/"
		self.url2 = "www.blablabla.com/2"
	}
}
