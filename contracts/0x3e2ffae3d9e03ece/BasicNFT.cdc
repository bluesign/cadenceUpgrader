// BasicNFT.cdc
//
// The NonFungibleToken contract is a sample implementation of a non-fungible token (NFT) on Flow.
//
// This contract defines one of the simplest forms of NFTs using an
// integer ID and metadata field.
// 
// Learn more about non-fungible tokens in this tutorial: https://developers.flow.com/cadence/tutorial/05-non-fungible-tokens-1

pub contract BasicNFT {

    // Declare the NFT resource type
    pub resource NFT {
        // The unique ID that differentiates each NFT
        pub let id: UInt64

        // String mapping to hold metadata
        pub var metadata: {String: String}

        // Initialize both fields in the init function
        init(initID: UInt64) {
            self.id = initID
            self.metadata = {}
        }
    }

    // Function to create a new NFT
    pub fun createNFT(id: UInt64): @NFT {
        return <-create NFT(initID: id)
    }

    // Create a single new NFT and save it to account storage
    init() {
        self.account.save<@NFT>(<-create NFT(initID: 1), to: /storage/BasicNFTPath)
    }
}
