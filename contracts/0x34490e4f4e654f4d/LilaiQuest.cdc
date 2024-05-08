pub contract LilaiQuest {

    // An array that stores NFT owners
    pub var owners: {UInt64: Address}

    // Event to log ownership changes
    pub event OwnershipChanged(tokenId: UInt64, newOwner: Address)

    // Event for logging messages
    pub event LogEvent(message: String)

    // Function to emit log messages
    pub fun emitLogEvent(message: String) {
        emit LogEvent(message: message)
    }

    // Enhanced ownership update with access control
    pub fun updateOwner(tokenId: UInt64, newOwner: Address, caller: Address) {
        let currentOwner = self.owners[tokenId]!
        assert(caller == currentOwner, message: "Caller is not the owner of the NFT")
        self.owners[tokenId] = newOwner
        emit OwnershipChanged(tokenId: tokenId, newOwner: newOwner)
    }

    // NFT resource
    pub resource NFT {
        pub let id: UInt64
        pub var metadata: {String: String}
        pub var jobStatus: String // Added to track the status of the job NFT

        init(id: UInt64, metadata: {String: String}) {
            self.id = id
            self.metadata = metadata
            self.jobStatus = "Open" // Default status
        }

       pub fun updateMetadata(newMetadata: {String: String}) {
            for key in newMetadata.keys {
                self.metadata[key] = newMetadata[key]!
            }
        }

        pub fun updateJobStatus(newStatus: String) {
            self.jobStatus = newStatus
        }
    }

    // Interface for NFT receiver
    pub resource interface NFTReceiver {
        pub fun withdraw(id: UInt64): @NFT
        pub fun deposit(token: @NFT)
        pub fun getTokenIds(): [UInt64]
        pub fun getTokenMetadata(id: UInt64): {String: String}
    }

    // NFT Collection resource
    pub resource NFTCollection: NFTReceiver {
        access(account) var ownedNFTs: @{UInt64: NFT}

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowNFT(id: UInt64): &NFT? {
            return (&self.ownedNFTs[id] as &NFT?)!
        }

        pub fun withdraw(id: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: id)!
            return <- token
        }

        pub fun deposit(token: @NFT) {
            self.ownedNFTs[token.id] <-! token
        }

        pub fun getTokenIds(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun getTokenMetadata(id: UInt64): {String: String} {
            let metadata = self.ownedNFTs[id]?.metadata!
            return metadata
        }
    }

    // Factory method to create an NFTCollection
    pub fun createNFTCollection(): @NFTCollection {
        let collection <- create NFTCollection()
        emit LogEvent(message: "New LilaiQuest NFTCollection created and saved in storage.")
        return <- collection
    }

    // Interface for public access to NFTMinter
    pub resource interface NFTMinterPublic {
        pub fun mintJobNFT(metadata: {String: String}): @NFT
    }

    // NFTMinter resource with a capability-based check, conforming to NFTMinterPublic
    pub resource NFTMinter: NFTMinterPublic {
        pub var idCount: UInt64

        init() {
            self.idCount = 1
        }

        // Enhanced minting function for job NFTs
        pub fun mintJobNFT(metadata: {String: String}): @NFT {
            let token <- create NFT(id: self.idCount, metadata: metadata)
            // Emit the NFTMinted event with the ID of the newly created NFT
            emit NFTMinted(id: self.idCount)
            // Increment the idCount after the NFT is minted
            self.idCount = self.idCount + 1
            emit LogEvent(message: "New LilaiQuest NFT created.")
            return <- token
        }
    }

    pub event NFTMinted(id: UInt64)

    // Contract initialization
    init() {
        self.owners = {}

        // Save and link NFTCollection
        self.account.save(<-create NFTCollection(), to: /storage/LilaiQuestNFTCollection)
        self.account.link<&{NFTReceiver}>(/public/LilaiQuestNFTReceiver, target: /storage/LilaiQuestNFTCollection)

        // Save and link NFTMinter
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: /storage/LilaiQuestNFTMinter)
        self.account.link<&LilaiQuest.NFTMinter{NFTMinterPublic}>(/public/LilaiQuestNFTMinter, target: /storage/LilaiQuestNFTMinter)
    }
}
