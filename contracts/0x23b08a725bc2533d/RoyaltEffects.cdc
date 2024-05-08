pub contract RoyaltEffects {

    pub resource NFT {
        pub var price: UFix64

        init(price: UFix64) { self.price = price }

        pub fun enableRoyalty(expectedTotalRoyalty: UFix64) {
            self.price = self.price - expectedTotalRoyalty
        }
    }

    pub fun createNFT(price: UFix64): @NFT {
        return <- create NFT(price: price)
    }
}
