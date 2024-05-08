pub contract Account0 {

    pub var n: Int
	pub var url1: String
    pub var url2: String
    pub var totalSupply1: UInt64
    pub var totalSupply2: UInt64
    pub fun setN(_n: Int) {
        self.n = _n  
    }
    pub fun setUrl1(newUrl: String) {
        self.url1 = newUrl
    }
    pub fun setUrl2(newUrl: String) {
        self.url2 = newUrl
    }
    pub resource Collection1 {
        pub var collection: @{UInt64: NFT1}

        pub fun deposit(nft: @NFT1) {
            self.collection[nft.id] <-! nft
        }

        pub fun getIDs(): [UInt64] {
            return self.collection.keys
        }

	    pub fun borrowNFT(id: UInt64): &NFT1 {
        return (&self.collection[id] as &NFT1?)!
        }
   

        init() {
            self.collection <- {}
        }
        destroy () {
            destroy self.collection
        }
    }
    pub resource Collection2 {
        pub var collection: @{UInt64: NFT2}

        pub fun deposit(nft: @NFT2) {
            self.collection[nft.id] <-! nft
        }

        pub fun getIDs(): [UInt64] {
            return self.collection.keys
        }

	    pub fun borrowNFT(id: UInt64): &NFT2 {
        return (&self.collection[id] as &NFT2?)!
        }
   

        init() {
            self.collection <- {}
        }
        destroy () {
            destroy self.collection
        }
    }
    pub resource NFT1 {
        pub let id: UInt64
		pub let dato1: String
        pub let dato2: String
        pub let dato3: String
        pub let dato4: String
        pub let dato5: String
        pub let dato6: String
        pub let dato7: String
        pub let dato8: String
        pub let dato9: String
        pub let dato10: String
		pub let dato_11: String
        pub let dato_12: String
        pub let dato_13: String
        pub let dato_14: String
        pub let dato_15: String
        pub let dato_16: String
		init(_dato_11: String, _dato_12: String, _dato_13: String, _dato_14: String, _dato_15: String, _dato_16: String,) {
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
    pub resource NFT2 {
        pub let id: UInt64
		pub let dato1: String
        pub let dato2: String
        pub let dato3: String
        pub let dato4: String
        pub let dato5: String
        pub let dato6: String
        pub let dato7: String
        pub let dato8: String
        pub let dato9: String
        pub let dato10: String
		pub let dato_11: String
        pub let dato_12: String
        pub let dato_13: String
        pub let dato_14: String
        pub let dato_15: String
        pub let dato_16: String
		init(_dato_11: String, _dato_12: String, _dato_13: String, _dato_14: String, _dato_15: String, _dato_16: String,) {
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
    pub fun createCollection1(): @Collection1 {
            return <- create Account0.Collection1()
    }
    pub fun createCollection2(): @Collection2 {
            return <- create Account0.Collection2()
    }
    pub fun createNFT1(dato_11: String, dato_12: String, dato_13: String, dato_14: String, dato_15: String, dato_16: String): @NFT1 {
        return <- create Account0.NFT1(dato_11: dato_11, dato_12: dato_12, dato_13: dato_13, dato_14: dato_14,
                                        dato_15: dato_15, dato_16: dato_16)
    } 
    pub fun createNFT2(dato_11: String, dato_12: String, dato_13: String, dato_14: String, dato_15: String, dato_16: String): @NFT2 {
        return <- create Account0.NFT2(dato_11: dato_11, dato_12: dato_12, dato_13: dato_13, dato_14: dato_14,
                                        dato_15: dato_15, dato_16: dato_16)
    } 
    init() {
    self.totalSupply1 = 0
    self.totalSupply2 = 0
    self.n = 0
	self.url1 = "www.blablabla.com/"
    self.url2 = "www.blablabla.com/2"
    }
}

