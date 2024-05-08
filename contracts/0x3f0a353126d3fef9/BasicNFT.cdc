 pub contract BasicNFT{

    pub var totalSupply: UInt64

    init(){
        self.totalSupply = 0
    }

    pub resource interface NFTPublic{
        pub fun getID(): UInt64
        pub fun getURL(): String
    }

    pub resource NFT: NFTPublic{
    
        pub let id: UInt64
        pub var metadata: {String: String}

        init(InitURL: String){
            self.id = BasicNFT.totalSupply
            self.metadata = {"URL": InitURL}
            BasicNFT.totalSupply = BasicNFT.totalSupply + 1
        }

        pub fun getID(): UInt64{
            return self.id
        }        

        pub fun getURL(): String{
            return self.metadata["URL"]!
        }   

    }

    pub fun createNFT(url: String): @NFT{
        return <- create NFT(InitURL: url)
    }

}