/* 
*
*  This is an example of how to implement Dynamic NFTs on Flow.
*  A Dynamic NFT is one that can be changed after minting. In 
*  this contract, a NFT's metadata can be changed by an Administrator.
*   
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import TraderflowScores from "./TraderflowScores.cdc"

pub contract DynamicNFT: NonFungibleToken {

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, by: Address, name: String, description: String, thumbnail: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub struct NFTMetadata {
      pub let name: String
      pub let description: String
      pub(set) var thumbnail: String
      access(self) let metadata: TraderflowScores.TradeMetadata

      init(
        name: String,
        description: String,
        thumbnail: String,
        metadata: TraderflowScores.TradeMetadata
      ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.metadata = metadata
      }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let sequence: UInt64
        pub var metadata: NFTMetadata
        access(self) let trades: TraderflowScores.TradeScores
    
        pub fun getViews(): [Type] {
          return [
            Type<MetadataViews.Display>()
          ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
          let template: NFTMetadata = self.getMetadata()
          switch view {
            case Type<MetadataViews.Display>():
              return MetadataViews.Display(
                name: template.name,
                description: template.description,
                thumbnail: MetadataViews.HTTPFile(
                  url: template.thumbnail
                )
              )
          }
          return nil
        }

        pub fun getTrades(): TraderflowScores.TradeScores {
          return self.trades
        }

        pub fun getMetadata(): NFTMetadata {
          return NFTMetadata(name: self.metadata.name, description: self.metadata.description, thumbnail: self.metadata.thumbnail, metadata: self.trades.metadata())
        }

        access(contract) fun borrowTradesRef(): &TraderflowScores.TradeScores {
          return &self.trades as &TraderflowScores.TradeScores
        }
         
        access(contract) fun updateArtwork(ipfs: String) {
          self.metadata.thumbnail = ipfs
        }

        init(_name: String, _description: String, _thumbnail: String) {
          self.id = self.uuid
          self.sequence = DynamicNFT.totalSupply
          self.trades = TraderflowScores.TradeScores()
          self.metadata = NFTMetadata(name: _name, description: _description, thumbnail: _thumbnail, metadata: self.trades.metadata())
          DynamicNFT.totalSupply = DynamicNFT.totalSupply + 1
        }
    }

    pub resource interface CollectionPublic {
      pub fun deposit(token: @NonFungibleToken.NFT)
      pub fun getIDs(): [UInt64]
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
      pub fun borrowAuthNFT(id: UInt64): &DynamicNFT.NFT? {
        post {
            (result == nil) || (result?.id == id):
                "Cannot borrow DynamicNFT reference: the ID of the returned reference is incorrect"
        }
      }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
        emit Withdraw(id: token.id, from: self.owner?.address)
        return <- token
      }

      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @DynamicNFT.NFT
        emit Deposit(id: token.id, to: self.owner?.address)
        self.ownedNFTs[token.id] <-! token
      }

      pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
      }

      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }

      pub fun borrowAuthNFT(id: UInt64): &DynamicNFT.NFT? {
        if self.ownedNFTs[id] != nil {
          let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          return ref as! &DynamicNFT.NFT
        }
        return nil
      }

      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let nft = token as! &DynamicNFT.NFT
        return nft as &AnyResource{MetadataViews.Resolver}
      }

      init () {
        self.ownedNFTs <- {}
      }

      destroy() {
        destroy self.ownedNFTs
      }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }

    pub event rebuildNFT(id: UInt64, owner: Address, metadata: TraderflowScores.TradeMetadataRebuild)

    pub resource Administrator {

      pub fun mintNFT(
        recipient: &Collection{NonFungibleToken.Receiver}, 
        name: String, 
        description: String, 
        thumbnail: String
      ) {
        let nft <- create NFT(_name: name, _description: description, _thumbnail: thumbnail)
        emit Minted(id: nft.id, by: self.owner!.address, name: name, description: description, thumbnail: thumbnail)
        recipient.deposit(token: <- nft)
      }

      pub fun pushTrade(
        id: UInt64, 
        currentOwner: Address, 
        trade: TraderflowScores.Trade
      ) {
        let ownerCollection = getAccount(currentOwner).getCapability(DynamicNFT.CollectionPublicPath)
                                .borrow<&Collection{CollectionPublic}>()
                                ?? panic("This person does not have a DynamicNFT Collection set up properly.")
        let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
        let tradeRef = nftRef.borrowTradesRef()
        let update = tradeRef.pushTrade(_trade: trade)
        emit rebuildNFT(id:id, owner:currentOwner, metadata:update)
      }

      pub fun pushEquity(
        id: UInt64, 
        currentOwner: Address, 
        equity: UFix64
      ) {
        let ownerCollection = getAccount(currentOwner).getCapability(DynamicNFT.CollectionPublicPath)
                                .borrow<&Collection{CollectionPublic}>()
                                ?? panic("This person does not have a DynamicNFT Collection set up properly.")
        let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
        let tradeRef = nftRef.borrowTradesRef()
        let update = tradeRef.pushEquity(_equity: equity)
        emit rebuildNFT(id:id, owner:currentOwner, metadata:update)
      }

      pub fun updateArtwork(
        id: UInt64, 
        currentOwner: Address, 
        ipfs: String
      ) {
        let ownerCollection = getAccount(currentOwner).getCapability(DynamicNFT.CollectionPublicPath)
                                .borrow<&Collection{CollectionPublic}>()
                                ?? panic("This person does not have a DynamicNFT Collection set up properly.")
        let nftRef = ownerCollection.borrowAuthNFT(id: id) ?? panic("This account does not own an NFT with this id.")
        
        nftRef.metadata.thumbnail = ipfs
      }
    }

    init() {
        self.totalSupply = 0

        self.CollectionStoragePath = /storage/DynamicNFTCollection
        self.CollectionPublicPath = /public/DynamicNFTCollection
        self.MinterStoragePath = /storage/DynamicNFTMinter

        self.account.save(<- create Administrator(), to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 