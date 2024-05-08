pub contract BasicNFT {

    pub var totalSupply: UInt64
    
    init() {
        self.totalSupply = 0
    }

    pub resource interface NFTPublic {
        pub fun getId(): UInt64
        pub fun getURL(): String
    }

    pub resource NFT: NFTPublic{
        pub let id: UInt64
        pub var metadata: {String: String}

        init(initURL: String) {
            self.id = BasicNFT.totalSupply
            self.metadata = {"URL" : initURL}
            BasicNFT.totalSupply = BasicNFT.totalSupply + 1
        }

        pub fun getId(): UInt64 {
            return self.id
        }

        pub fun getURL(): String {
            return self.metadata["URL"]!
        }
    }

    pub fun createNFT(url: String): @NFT{
        return <- create NFT(initURL: url)
    }
}