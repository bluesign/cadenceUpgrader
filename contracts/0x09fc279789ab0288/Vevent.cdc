import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract Vevent {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    pub struct interface Verifier {
        pub fun verify(user: Address): Bool
    }

    pub resource interface ProjectPublic {
        pub let id: UInt64
        pub let buyers: {Address: UInt64}
        pub let prices: {UFix64: UInt64}
        pub var active: Bool
        access(account) fun purchase(user: Address, vault: @DapperUtilityCoin.Vault)
    }

    pub resource Project: ProjectPublic {
        pub let id: UInt64
        pub let buyers: {Address: UInt64}
        // maps the price to the amount of squares you get
        pub let prices: {UFix64: UInt64}
        pub var active: Bool
        pub let verifier: [{Verifier}]

        access(account) fun purchase(user: Address, vault: @DapperUtilityCoin.Vault) {
            pre {
                self.prices[vault.balance] != nil: "This price is not supported."
            }
            self.buyers[user] = (self.buyers[user] ?? 0) + self.prices[vault.balance]!

            let owner: Address = 0x14b41acafe20d346
            let ownerVault = getAccount(owner).getCapability(/public/dapperUtilityCoinReceiver)
                            .borrow<&{FungibleToken.Receiver}>() 
                            ?? panic("This is not a Dapper Wallet account.")
            ownerVault.deposit(from: <- vault)
        }

        pub fun toggleActive() {
            self.active = !self.active
        }

        init(prices: {UFix64: UInt64}, verifier: [{Verifier}]) {
            self.id = self.uuid
            self.buyers = {}
            self.prices = prices
            self.active = true
            self.verifier = verifier
        }
    }

    pub resource interface CollectionPublic {
        pub fun getProjectIds(): [UInt64]
        pub fun getProjectPublic(projectId: UInt64): &Project{ProjectPublic}?
    }

    pub resource Collection: CollectionPublic {
        pub let projects: @{UInt64: Project}

        pub fun createProject(
            prices: {UFix64: UInt64},
            verifier: [{Verifier}]
        ) {
            let project <- create Project(prices: prices, verifier: verifier)
            self.projects[project.id] <-! project
        }

        pub fun purchase(projectOwner: Address, projectId: UInt64, payment: @DapperUtilityCoin.Vault) {
            let collection: &Collection{CollectionPublic} = getAccount(projectOwner).getCapability(Vevent.CollectionPublicPath)
                                .borrow<&Collection{CollectionPublic}>()
                                ?? panic("This project owner does not have a collection set up or linked properly.")
            let project: &Project{ProjectPublic} = collection.getProjectPublic(projectId: projectId) 
                                ?? panic("Project with this id does not exist.")
            project.purchase(user: self.owner!.address, vault: <- payment)
        }

        pub fun getProjectIds(): [UInt64] {
            return self.projects.keys
        }

        pub fun getProject(projectId: UInt64): &Project? {
            return &self.projects[projectId] as &Project?
        }

        pub fun getProjectPublic(projectId: UInt64): &Project{ProjectPublic}? {
            return &self.projects[projectId] as &Project{ProjectPublic}?
        }

        init() {
            self.projects <- {}
        }

        destroy() {
            destroy self.projects
        }
    }

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    init() {
        self.CollectionStoragePath = /storage/VeventCollection
        self.CollectionPublicPath = /public/VeventCollection
    }

}
 