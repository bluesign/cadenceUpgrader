/*
    Flowmap is a consensus standard that allows anyone to claim ownership of a Flow Block.
    This is achieved through the Flowmap Inscription contract, where anyone can be the first to inscribe "blocknumber.flowmap" unto a cadence resource.
    Inspired by Bitmaps on Bitcoin Ordinals. Read whitepaper here: https://bitmap.land/bitbook
    Flowmap is intended solely for entertainment purposes. It should not be regarded as an investment or used with the expectation of financial returns. 
    Users are advised to engage with it purely for enjoyment and recreational value. 0% royalties.
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

access(all) contract Flowmap: NonFungibleToken {
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) var totalSupply: UInt64
    access(all) let inscriptionFee: UFix64

    access(all) resource NFT: NonFungibleToken.INFT {
        access(all) let id: UInt64
        access(all) let inscription: String
        init() {
            self.id = Flowmap.totalSupply
            self.inscription = (Flowmap.totalSupply).toString().concat(".flowmap")
            Flowmap.totalSupply = Flowmap.totalSupply + 1
        }
    }

    access(all) resource interface CollectionPublic {
        access(all) fun getIDs(): [UInt64]
        access(all) fun deposit(token: @NonFungibleToken.NFT)
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        access(all) fun borrowFlowmap(id: UInt64): &Flowmap.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Flowmap reference: the ID of the returned reference is incorrect"
            }
        }
    }
    
    access(all) resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        init() {
            self.ownedNFTs <- {}
        }
        access(all) fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        access(all) fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Flowmap")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Flowmap.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        access(all) fun borrowFlowmap(id: UInt64): &Flowmap.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flowmap.NFT
            }
            return nil
        }
        destroy() {
            destroy self.ownedNFTs
        }
    }

    access(all) fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    access(all) fun inscribe(inscriptionFee: @FlowToken.Vault): @Flowmap.NFT {
        pre {
            Flowmap.totalSupply <= getCurrentBlock().height: "Cannot inscribe more than the current block height"
            inscriptionFee.balance >= Flowmap.inscriptionFee: "Insufficient inscription fee"
        }
        Flowmap.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!.deposit(from: <-inscriptionFee)
        return <- create Flowmap.NFT()
    }

    access(all) fun batchInscribe(inscriptionFee: @FlowToken.Vault, quantity: UFix64, receiver: Address) {
        pre {
            Flowmap.totalSupply <= getCurrentBlock().height: "Cannot inscribe more than the current block height"
            inscriptionFee.balance >= Flowmap.inscriptionFee * quantity: "Insufficient inscription fee"
        }
        Flowmap.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!.deposit(from: <-inscriptionFee)
        let receiverRef = getAccount(receiver).getCapability(Flowmap.CollectionPublicPath).borrow<&{Flowmap.CollectionPublic}>()?? panic("Could not borrow reference to the owner's Collection!")
        var i = 0
        while i < Int(quantity) {
            receiverRef.deposit(token: <- create Flowmap.NFT())
            i = i + 1
        }
    }

    init() {
        self.totalSupply = 0
        self.inscriptionFee = 0.025
        self.CollectionStoragePath = /storage/flowmapCollection
        self.CollectionPublicPath = /public/flowmapCollection
        emit ContractInitialized()
    }
}