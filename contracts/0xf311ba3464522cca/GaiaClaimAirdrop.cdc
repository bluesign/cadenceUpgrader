import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract GaiaClaimAirdrop {
    pub event ContractInitialized()
    pub event ClaimAdded(claimID: String, nftType: Type, nftID: UInt64, address: Address, description: String)
    pub event ClaimRemoved(claimID: String, nftType: Type, nftID: UInt64, address: Address, description: String)
    pub event ClaimCompleted(claimID: String, nftType: Type, nftID: UInt64, address: Address, description: String)

    pub let ManagerStoragePath: StoragePath

    access(contract) let userClaims: {Address: {String: Bool}}
    access(contract) let claims: @{String: Claim}

    pub struct ClaimDetails {
        pub let claimID: String
        pub let address: Address
        pub let nftType: Type
        pub let nftID: UInt64
        pub let description: String

        init(claimID: String, address: Address, nftType: Type, nftID: UInt64, description: String) {
            self.claimID = claimID
            self.address = address
            self.nftType = nftType
            self.nftID = nftID
            self.description = description
        }
    }

    pub resource Claim {
        access(contract) let claimID: String
        access(contract) let address: Address
        access(contract) let nftType: Type
        access(contract) let nftID: UInt64
        access(contract) let description: String
        access(contract) let vault: Capability<&{NonFungibleToken.Provider}>

        init(claimID: String, address: Address, nftType: Type, nftID: UInt64, description: String, vault: Capability<&{NonFungibleToken.Provider}>) {
            self.claimID = claimID
            self.address = address
            self.nftType = nftType
            self.nftID = nftID
            self.vault = vault
            self.description = description
        }
    }

    pub resource ClaimManager {
        pub fun addClaim(claimID: String, address: Address, nftType: Type, nftID: UInt64, description: String, vault: Capability<&{NonFungibleToken.Provider}>) {
            pre {
                GaiaClaimAirdrop.claims.containsKey(claimID) == false: "Claim ID is already in use"
            }

            let claim <- create Claim(
                claimID: claimID,
                address: address,
                nftType: nftType,
                nftID: nftID,
                description: description,
                vault: vault,
            )

            let old <- GaiaClaimAirdrop.claims[claimID] <- claim
            destroy old

            if !GaiaClaimAirdrop.userClaims.containsKey(address) {
                GaiaClaimAirdrop.userClaims[address] = {}
            }

            GaiaClaimAirdrop.userClaims[address]!.insert(key: claimID, true)

            emit ClaimAdded(claimID: claimID, nftType: nftType, nftID: nftID, address: address, description: description)
        }

        pub fun removeClaim(claimID: String) {
            if GaiaClaimAirdrop.claims.containsKey(claimID) {
                let claim <- GaiaClaimAirdrop.claims.remove(key: claimID)!
                emit ClaimRemoved(claimID: claim.claimID, nftType: claim.nftType, nftID: claim.nftID, address: claim.address, description: claim.description)

                if GaiaClaimAirdrop.userClaims.containsKey(claim.address) {
                    GaiaClaimAirdrop.userClaims[claim.address]?.remove(key: claimID)
                }

                destroy claim
            }
        }
    }

    pub fun getAddressClaims(address: Address): [ClaimDetails] {
        let claims: [ClaimDetails] = []

        if GaiaClaimAirdrop.userClaims.containsKey(address) {
            let claimIDs = GaiaClaimAirdrop.userClaims[address]?.keys ?? []

            for claimID in claimIDs {
                let claim = &GaiaClaimAirdrop.claims[claimID] as &Claim?

                if claim != nil {
                    claims.append(ClaimDetails(
                        claimID: claim!.claimID,
                        address: claim!.address,
                        nftType: claim!.nftType,
                        nftID: claim!.nftID,
                        description: claim!.description,
                    ))
                }
            }
        }

        return claims
    }

    pub fun getClaim(claimID: String): ClaimDetails? {
        let claim = &GaiaClaimAirdrop.claims[claimID] as &Claim?

        if claim != nil {
            return ClaimDetails(
                claimID: claim!.claimID,
                address: claim!.address,
                nftType: claim!.nftType,
                nftID: claim!.nftID,
                description: claim!.description,
            )
        } else {
            return nil
        }
    }

    pub fun completeClaim(claimID: String, receiverCapabilityPath: PublicPath): Address? {
        let claim = &GaiaClaimAirdrop.claims[claimID] as &GaiaClaimAirdrop.Claim?
            ?? panic("Claim not found")

        let collection = getAccount(claim.address).getCapability<&{NonFungibleToken.CollectionPublic}>(receiverCapabilityPath).borrow()
            ?? panic("Could not borrow NFT receiver collection")

        let vault = claim.vault.borrow()
            ?? panic("Could not borrow NFT provider collection")

        let nft <- vault.withdraw(withdrawID: claim.nftID)
        collection.deposit(token: <- nft)

        let address = claim.address

        emit ClaimCompleted(claimID: claim.claimID, nftType: claim.nftType, nftID: claim.nftID, address: claim.address, description: claim.description)

        destroy GaiaClaimAirdrop.claims.remove(key: claimID)

        if GaiaClaimAirdrop.userClaims.containsKey(address) {
            GaiaClaimAirdrop.userClaims[address]?.remove(key: claimID)
            if GaiaClaimAirdrop.userClaims[address]!.keys.length == 0 {
                GaiaClaimAirdrop.userClaims.remove(key: address)
            }
        }

        return address
    }

    access(account) fun createClaimManager(): @ClaimManager {
        return <- create ClaimManager()
    }

    init() {
        self.userClaims = {}
        self.claims <- {}

        self.ManagerStoragePath = /storage/GaiaClaimAirdropManager

        self.account.save(<- self.createClaimManager(), to: self.ManagerStoragePath)

        emit ContractInitialized()
    }
}
