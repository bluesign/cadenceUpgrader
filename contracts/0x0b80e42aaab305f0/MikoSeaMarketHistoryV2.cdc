import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract MikoSeaMarketHistoryV2 {
    //------------------------------------------------------------
    // Events
    //------------------------------------------------------------
    pub event TransactionCreated(transactionId: UInt64, ownerAddress: Address, amount: UFix64, message: String, type: String, metadata: {String:String}, createdAt: UFix64)
    pub event RevenueUpdatedStatus(revenueId: UInt64, status: String, updatedAt: UFix64)
    pub event RevenueCreated(revenueId: UInt64, userAddress: Address, amount: UFix64, transactionIds: [UInt64], metadata: {String:String}, createdAt: UFix64)

    //------------------------------------------------------------
    // Path
    //------------------------------------------------------------
    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath

    //------------------------------------------------------------
    // Data
    //------------------------------------------------------------
    pub let adminCap: Capability<&{AdminPublicCollection}>
    pub var nextTransactionId: UInt64
    pub var nextRevenueId: UInt64

    //------------------------------------------------------------
    // Transaction resource
    //------------------------------------------------------------
    pub resource Transaction {
        pub let transactionId: UInt64
        pub let userAddress: Address
        // ¥, without fee
        pub let amount: UFix64
        // ¥
        pub let royalties: MetadataViews.Royalties?

        // secondMarket
        // creatorFee
        // withdraw
        // rejectRefund
        pub let type: String
        pub var metadata: {String:String}
        pub let createdAt: UFix64
        pub var updatedAt: UFix64
        pub var message: String
        pub var revenueId: UInt64?

        init(
            userAddress: Address,
            amount: UFix64,
            royalties: MetadataViews.Royalties?,
            type: String,
            metadata: {String:String},
            message: String
        ){
            pre {
                ["secondMarket", "creatorFee", "rejectRefund", "withdraw", "platformFee"].contains(type) : "type is invalid"
            }

            self.amount=amount
            self.royalties=royalties
            self.userAddress=userAddress
            self.type=type
            self.metadata=metadata
            self.message=message
            self.createdAt=getCurrentBlock().timestamp
            self.updatedAt=getCurrentBlock().timestamp
            self.revenueId = nil
            self.transactionId = MikoSeaMarketHistoryV2.nextTransactionId
            MikoSeaMarketHistoryV2.nextTransactionId = MikoSeaMarketHistoryV2.nextTransactionId + 1
        }

        access(contract) fun updateMetadata(_ metadata: {String:String}) {
            self.metadata=metadata
            self.updatedAt=getCurrentBlock().timestamp
        }

        access(contract) fun updateMessage(_ message: String) {
            self.message=message
            self.updatedAt=getCurrentBlock().timestamp
        }

        access(contract) fun updateRevenueId(_ revenueId: UInt64) {
            self.revenueId=revenueId
            self.updatedAt=getCurrentBlock().timestamp
        }
    }

    pub resource Revenue {
        pub let revenueId: UInt64
        pub let transactionIds: [UInt64]
        pub let amount: UFix64
        pub let userAddress: Address

        // request amount status, only admin can do that
        // created: transaction is created
        // done: admin sent amount to user
        // rejected: admin rejected this transaction
        pub var status: String

        pub let createdAt: UFix64
        pub var updatedAt: UFix64

        pub var metadata: {String:String}

        init (
            transactionIds: [UInt64],
            metadata: {String:String},
            amount: UFix64,
            userAddress: Address
        ) {
            self.revenueId = MikoSeaMarketHistoryV2.nextRevenueId
            self.transactionIds = transactionIds
            self.status = "created"
            self.createdAt = getCurrentBlock().timestamp
            self.updatedAt = getCurrentBlock().timestamp
            self.metadata = metadata
            self.amount = amount
            self.userAddress = userAddress
            MikoSeaMarketHistoryV2.nextRevenueId = MikoSeaMarketHistoryV2.nextRevenueId + 1

            emit RevenueCreated(revenueId: self.revenueId, userAddress: userAddress, amount: amount, transactionIds: transactionIds, metadata: metadata, createdAt: self.createdAt)
        }

        access(contract) fun updateStatus(_ status: String) {
            pre {
                ["rejected", "done"].firstIndex(of: status) != nil : "status is invalid"
            }
            self.status=status
            self.updatedAt=getCurrentBlock().timestamp

            emit RevenueUpdatedStatus(revenueId: self.revenueId, status: self.status, updatedAt: self.updatedAt)
        }
    }

    //------------------------------------------------------------
    // Admin public
    //------------------------------------------------------------
    pub resource interface AdminPublicCollection {
        pub fun getTransactionById(_ id: UInt64): &Transaction?
        pub fun getRevenueById(_ id: UInt64): &Revenue?
    }

    pub resource Admin: AdminPublicCollection {
        // map: {userAddress: [transactionId]}
        pub let userTransactions: {Address: [UInt64]}

        // map: {userAddress: [revenueId]}
        pub let userRevenues: {Address: [UInt64]}

        // map: {userAddress : yen balance}
        pub let userBalances: {Address: Fix64}

        // map: {userAddress : pointBalance}
        pub let userPointBalances: {Address: Fix64}

        // all transaction data
        // map: {transactionId : Tranaction}
        pub let transactionData: @{UInt64: Transaction}

        // all Revenue data
        // map: {revenueId : Revenue}
        pub let revenueData: @{UInt64: Revenue}

        init() {
            self.userTransactions = {}
            self.transactionData <- {}
            self.userBalances = {}
            self.userPointBalances = {}
            self.userRevenues = {}
            self.revenueData <- {}
        }
        pub fun getTransactionById(_ id: UInt64): &Transaction? {
            return &self.transactionData[id] as &Transaction?
        }

        pub fun getRevenueById(_ id: UInt64): &Revenue? {
            return &self.revenueData[id] as &Revenue?
        }

        pub fun addTransaction(
            owner: Address,
            amount: UFix64,
            royalties: MetadataViews.Royalties?,
            type: String,
            metadata: {String:String},
            message: String
        ): &Transaction {
            let transaction <- create Transaction(userAddress: owner, amount: amount, royalties: royalties, type: type, metadata: metadata, message: message)
            let transactionId = transaction.transactionId
            if !self.userTransactions.containsKey(owner) {
                self.userTransactions[owner] = []
                self.userBalances[owner] = 0.0
            }
            self.userTransactions[owner]!.insert(at: 0, transaction.transactionId)
            if type == "withdraw" {
                self.userBalances[owner] = self.userBalances[owner]! - Fix64(amount)
            } else {
                self.userBalances[owner] = self.userBalances[owner]! + Fix64(amount)
            }

            emit TransactionCreated(transactionId: transaction.transactionId, ownerAddress: transaction.userAddress, amount: transaction.amount, message: transaction.message, type: transaction.type, metadata: transaction.metadata, createdAt: transaction.createdAt)

            // add transaction
            let old <- self.transactionData[transaction.transactionId] <- transaction
            destroy old

            return self.getTransactionById(transactionId)!;
        }

        pub fun addTransactionWithoutFee(
            owner: Address,
            amount: UFix64,
            type: String,
            metadata: {String:String},
            message: String
        ): &Transaction {
            return self.addTransaction(owner: owner, amount: amount, royalties: nil, type: type, metadata: metadata, message: message)
        }

        pub fun updateMetadata(_ transactionId: UInt64, metadata: {String:String}): &Transaction? {
            self.transactionData[transactionId]?.updateMetadata(metadata)
            return self.getTransactionById(transactionId);
        }

        pub fun updateMessage(_ transactionId: UInt64, message: String): &Transaction? {
            self.transactionData[transactionId]?.updateMessage(message)
            return self.getTransactionById(transactionId);
        }

        // not in use
        priv fun createRequestRevenueByTransactionIds(_ address: Address, metadata: {String:String}) {
            let ids = self.userTransactions[address] ?? []
            if ids.length == 0 {
                return
            }

            // get transactionIds
            let transactionIds:[UInt64] = []
            let transactions: [&Transaction] = []
            for id in ids {
                if let tx = self.getTransactionById(id) {
                    if tx.revenueId == nil {
                        transactionIds.append(tx.transactionId)
                        transactions.append(tx)
                    }
                }
            }

            // add event withdraw && update balance
            let totalAmount = MikoSeaMarketHistoryV2.getTotalAmount(transactionIds)
            if totalAmount <= 0.0 {
                return
            }
            let txWithdraw = self.addTransaction(owner: address, amount: totalAmount, royalties: nil, type: "withdraw", metadata: metadata, message: "振込申請")
            transactionIds.append(txWithdraw.transactionId)
            transactions.append(txWithdraw)

            // create revenue
            let revenue <- create Revenue(transactionIds: transactionIds, metadata: metadata, amount: totalAmount, userAddress: address)
            let revenueId = revenue.revenueId
            let old <- self.revenueData[revenueId] <- revenue
            destroy old

            // add user revenue
            if !self.userRevenues.containsKey(address) {
                self.userRevenues[address] = []
            }
            self.userRevenues[address]!.insert(at: 0, revenueId)

            // update revenueId for transactions
            for tx in transactions {
                tx.updateRevenueId(revenueId)
            }
        }

        pub fun createRequestRevenue(_ address: Address, amount: UFix64, metadata: {String:String}) {
            // add event withdraw && update balance
            let userBalance = self.userBalances[address] ?? 0.0
            if Fix64(amount) > userBalance {
                return
            }
            let txWithdraw = self.addTransaction(owner: address, amount: amount, royalties: nil, type: "withdraw", metadata: metadata, message: "振込申請")

            // create revenue
            let revenue <- create Revenue(transactionIds: [], metadata: metadata, amount: amount, userAddress: address)
            let revenueId = revenue.revenueId
            txWithdraw.updateRevenueId(revenueId)
            let old <- self.revenueData[revenueId] <- revenue
            destroy old

            // add user revenue
            if !self.userRevenues.containsKey(address) {
                self.userRevenues[address] = []
            }
            self.userRevenues[address]!.insert(at: 0, revenueId)
        }

        // when admin transfer monney done
        pub fun updateStatusRevenue(_ revenueId: UInt64, status: String) {
            self.revenueData[revenueId]?.updateStatus(status)
        }

        destroy () {
            destroy <- self.transactionData
            destroy <- self.revenueData
        }
    }

    priv fun getAdminRef(): &MikoSeaMarketHistoryV2.Admin {
        return self.account.borrow<&MikoSeaMarketHistoryV2.Admin>(from: MikoSeaMarketHistoryV2.AdminStoragePath)!
    }

    pub fun getById(_ id: UInt64): &Transaction? {
        return self.getAdminRef().getTransactionById(id)
    }

    pub fun getUserTransactionIds(_ address: Address): [UInt64] {
        return self.getAdminRef().userTransactions[address] ?? []
    }

    pub fun getUserBalance(_ address: Address): Fix64 {
        return self.getAdminRef().userBalances[address] ?? 0.0
    }

    pub fun getRevenuesByAddress(_ address: Address): [&Revenue] {
        let revenueIds = self.getAdminRef().userRevenues[address] ?? []
        let res: [&Revenue] = []
        for id in revenueIds {
            if let revenue = self.getAdminRef().getRevenueById(id) {
                res.append(revenue)
            }
        }
        return res
    }

    pub fun getTotalAmount(_ transactionIds: [UInt64]): UFix64 {
        var totalAmount = 0.0
        for id in transactionIds {
            if let tx = MikoSeaMarketHistoryV2.getById(id){
                if tx.type != "withdraw" {
                    totalAmount = totalAmount + tx.amount
                }
            }
        }
        return totalAmount
    }

    //------------------------------------------------------------
    // Initializer
    //------------------------------------------------------------
    init () {
        self.AdminStoragePath = /storage/MikoSeaMarketHistoryV2Admin
        self.AdminPublicPath = /public/MikoSeaMarketHistoryV2Admin
        self.nextTransactionId = 1
        self.nextRevenueId = 1

        self.account.save(<- create Admin(), to: self.AdminStoragePath)
        self.account.link<&{AdminPublicCollection}>(self.AdminPublicPath, target: self.AdminStoragePath)
        self.adminCap = self.account.getCapability<&{AdminPublicCollection}>(self.AdminPublicPath)
    }
}
