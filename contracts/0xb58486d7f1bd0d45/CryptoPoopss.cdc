import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract CryptoPoopss: NonFungibleToken {
    pub var totalSupply: UInt64

    pub event ContractInitialized()

    pub event Withdraw(id: UInt64, from: Address?)

    pub event Deposit(id: UInt64, to: Address?)

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub(set) var metadata: {String: String}

        init(metadata: {String: String}) {
            self.id = CryptoPoopss.totalSupply 
            CryptoPoopss.totalSupply = CryptoPoopss.totalSupply + (1 as UInt64)

            self.metadata = metadata
        }
    }

    pub resource interface MyCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowEntireNFT(id: UInt64): &NFT
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MyCollectionPublic {
        // id of the NFT -> NFT with that id
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let cryptoPoop <- token as! @NFT
            emit Deposit(id: cryptoPoop.id, to:self.owner!.address)
            self.ownedNFTs[cryptoPoop.id] <-! cryptoPoop
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This collection doesn't cotain nft with that id")
            emit Withdraw(id: withdrawID, from: self.owner?.address)
            return <- token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?) ?? panic("nothing in this index")
        }

        pub fun borrowEntireNFT(id: UInt64): &NFT {
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?) ?? panic("something")
            return refNFT as! &NFT
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    pub resource NFTMinter {
        pub fun createNFT(metadata: {String: String}): @NFT {
            let newNFT <- create NFT(metadata: metadata)
            return <- newNFT
        }

        init() {

        }
    }

    init() {
        self.totalSupply = 0
        emit ContractInitialized()

        self.account.save(<- create NFTMinter(), to: /storage/Mintere)
    }
}