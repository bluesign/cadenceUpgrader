import Crypto
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FantastecNFT from "./FantastecNFT.cdc"

pub contract interface IFantastecPackNFT {
    /// StoragePath for Collection Resource
    pub let CollectionStoragePath: StoragePath

    /// PublicPath expected for deposit
    pub let CollectionPublicPath: PublicPath

    /// PublicPath for receiving NFT
    pub let CollectionIFantastecPackNFTPublicPath: PublicPath

    /// StoragePath for the NFT Operator Resource (issuer owns this)
    pub let OperatorStoragePath: StoragePath

    /// PrivatePath to share IOperator interfaces with Operator (typically with PDS account)
    pub let OperatorPrivPath: PrivatePath

    /// Burned
    /// Emitted when a NFT has been burned
    pub event Burned(id: UInt64 )

    pub resource interface IOperator {
        pub fun mint(packId: UInt64, productId: UInt64): @NFT
        pub fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
        pub fun open(id: UInt64, recipient: Address)
    }

    pub resource FantastecPackNFTOperator: IOperator {
        pub fun mint(packId: UInt64, productId: UInt64): @NFT
        pub fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
        pub fun open(id: UInt64, recipient: Address)
    }

    pub resource interface IFantastecPack {
        pub var ownedNFTs: @{UInt64: FantastecNFT.NFT}

        pub fun addFantastecNFT(nft: @FantastecNFT.NFT)
        pub fun open(recipient: Address)
    }

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
    }

    pub resource interface IFantastecPackNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }
}