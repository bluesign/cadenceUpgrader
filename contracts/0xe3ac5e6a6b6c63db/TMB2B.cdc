// Description: Smart Contract for Ticketmaster Business NFTs
// SPDX-License-Identifier: UNLICENSED


import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract TMB2B : NonFungibleToken{
    
    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)


    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath



    pub resource NFT : NonFungibleToken.INFT{

        pub let id: UInt64
        pub var link: String
        pub var batch: UInt32
        pub var sequence: UInt16
        pub var limit: UInt16
        

        init(initID: UInt64, initlink: String, initbatch: UInt32, initsequence: UInt16, initlimit: UInt16) {
            self.id = initID
            self.link = initlink
            self.batch = initbatch
            self.sequence=initsequence
            self.limit=initlimit
            
        }
    }

    
    pub resource interface TMB2BCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowTMB2B(id: UInt64): &TMB2B.NFT? {
    
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow TMB2B reference: The ID of the returned reference is incorrect"
            }
        }
    }


    
    pub resource Collection: TMB2BCollectionPublic,NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
    
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }


        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {

            let token <- self.ownedNFTs.remove(key: withdrawID)!
            
            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        
        pub fun deposit(token: @NonFungibleToken.NFT) {
        
            let token <- token as! @TMB2B.NFT
            let id: UInt64 = token.id

            
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
            
            
        }

        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!  
        }

        
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowTMB2B(id: UInt64): &TMB2B.NFT? {
            if self.ownedNFTs[id] == nil {
                return nil
            } 
            else {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &TMB2B.NFT
            }
        }

    }

    
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    
    pub resource NFTMinter {

        pub var minterID: UInt64
        
        init() {
            self.minterID = 0    
        }

        pub fun mintNFT(glink: String, gbatch: UInt32, glimit: UInt16, gsequence:UInt16): @NFT {


            let tokenID = (UInt64(gbatch) << 32) | (UInt64(glimit) << 16) | UInt64(gsequence)
            var newNFT <- create NFT(initID: tokenID, initlink: glink, initbatch: gbatch, initsequence: gsequence, initlimit: glimit)


            self.minterID= tokenID

            TMB2B.totalSupply = TMB2B.totalSupply + UInt64(1)
            return <-newNFT
        }
    }

	init() {
        
        
        self.CollectionStoragePath = /storage/TMB2BCollection
        self.CollectionPublicPath = /public/TMB2BCollection
        self.MinterStoragePath = /storage/TMB2BMinter


        self.totalSupply = 0


        self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
        self.account.link<&{NonFungibleToken.CollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        self.account.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
 
 