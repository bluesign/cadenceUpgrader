// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import MIKOSEANFT from "./MIKOSEANFT.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import MikoSeaUtility from "./MikoSeaUtility.cdc"

pub contract MikoSeaNftAuctionV2 {

    // storage auction history
    pub struct BidItem {
        pub let bidId: UInt64
        pub let auctionId: UInt64
        // bidder address
        pub let address: Address
        pub let bidPrice: UFix64
        // created time
        pub let bidTime: UFix64

        init(auctionId: UInt64, address: Address, bidPrice: UFix64, bidTime: UFix64?) {
            self.address = address
            self.bidPrice = bidPrice
            self.bidTime = bidTime ?? getCurrentBlock().timestamp
            self.auctionId = auctionId
            MikoSeaNftAuctionV2.bidNumber[auctionId] =  (MikoSeaNftAuctionV2.bidNumber[auctionId] ?? 0) + 1
            self.bidId = MikoSeaNftAuctionV2.bidNumber[auctionId]!
        }
    }

    pub struct BidWinner {
        pub let bidItem: BidItem
        // created time
        pub let lastTimeCanPay: UFix64

        init(bidItem: BidItem, lastTimeCanPay: UFix64) {
            self.bidItem = bidItem
            self.lastTimeCanPay = lastTimeCanPay
        }
    }

    // This struct aggreates status for the auction and is exposed in order to create websites using auction information
    pub struct AuctionInfo {
        pub let auctionId: UInt64

        // Yen
        pub let price : UFix64
        pub let minimumBidIncrement : UFix64
        pub let numberOfBids : Int
        //Active is probably not needed when we have completed and expired above, consider removing it
        pub let active: Bool
        pub let auctionStatus: AuctionStatusEnum
        pub let auctionEndTime : UFix64
        pub let auctionStartTime : UFix64
        pub let auctionCompleteTime: UFix64?
        pub let metadata: {String:String}
        pub let nftId: UInt64?
        pub let owner: Address
        pub let leader: BidItem?
        pub let winner: BidWinner?
        pub let minNextBid: UFix64
        pub let sendNftTime: UFix64?

        init(auctionId:UInt64,
            currentPrice: UFix64,
            numberOfBids:Int,
            active: Bool,
            auctionStatus: AuctionStatusEnum,
            metadata: {String:String},
            nftId: UInt64?,
            leader: BidItem?,
            winner: BidWinner?,
            minimumBidIncrement: UFix64,
            owner: Address,
            auctionStartTime : UFix64,
            auctionEndTime : UFix64,
            auctionCompleteTime: UFix64?,
            sendNftTime: UFix64?,
            minNextBid:UFix64,
        ) {
            self.auctionId=auctionId
            self.price= currentPrice
            self.numberOfBids=numberOfBids
            self.active=active
            self.auctionStatus = auctionStatus
            self.metadata=metadata
            self.nftId=nftId
            self.leader= leader
            self.minimumBidIncrement=minimumBidIncrement
            self.owner=owner
            self.auctionStartTime=auctionStartTime
            self.auctionEndTime=auctionEndTime
            self.auctionCompleteTime = auctionCompleteTime
            self.sendNftTime = sendNftTime
            self.minNextBid=minNextBid
            self.winner = winner
        }
    }

    pub enum AuctionStatusEnum: UInt8 {
        pub case auctioning
        pub case compeleted
        pub case winnerReceived
        pub case canceled
        pub case rejected
    }

    pub enum PaymentWithEnum: UInt8 {
        pub case creaditCard
        pub case bankTransfer
    }

    // The total amount of AuctionItems that have been created
    pub var totalAuctions: UInt64

    // value when settle auction
    pub var defaultRoyalties: MetadataViews.Royalties

    // value when settle auction
    pub let nftRoyalties: {UInt64: MetadataViews.Royalties}

    pub let auctionIdRejected: [UInt64]
    // only MikoSea admin can add user in to black list, {auctionId: [user address]}
    pub let blackList: {UInt64:[Address]}

    pub let AdminStoragePath: StoragePath
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // number of bid on each auction
    pub var bidNumber: {UInt64:UInt64}

    // rate transform from yen to usd, ex: {"USD_TO_YEN": 171.2}
    pub var ratePrice: {String:UFix64}

    // Events
    pub event TokenPurchased(id: UInt64, nftId: UInt64, price: UFix64, from:Address, to:Address?)
    pub event SentNFT(auctionId: UInt64, nftId: UInt64, price: UFix64, to:Address)
    pub event CollectionCreated(owner: Address)
    pub event Created(auctionId: UInt64, owner: Address, startPrice: UFix64, startTime: UFix64, endTime: UFix64, nftId: UInt64, createdAt: UFix64, maxPriceCanPay: UFix64, minimumBidIncrement: UFix64, metadata: {String:String})
    pub event AuctionExtendTime(auctionId: UInt64, newEndTime: UFix64, extendTime: UFix64)
    pub event Bid(auctionId: UInt64, bidderAddress: Address, bidPrice: UFix64, bidTime: UFix64, bidId: UInt64)
    pub event BidderReceipted(auctionId: UInt64, nftId: UInt64, bidder: Address)
    pub event Canceled(auctionId: UInt64)
    pub event Completed(auctionId: UInt64)
    pub event MarketplaceEarned(amount:UFix64, owner: Address)
    pub event AuctionRejected(auctionId: UInt64)
    pub event AuctionUnrejected(auctionId: UInt64)
    pub event AddToBlackList(auctionId: UInt64, addresses: [Address])
    pub event RemoveFromBlackList(auctionId: UInt64, addresses: [Address])

    // AuctionItem contains the Resources and metadata for a single auction
    pub resource AuctionItem {
        //The id of this individual auction
        access(contract) let auctionId: UInt64

        access(contract) let bidList: [BidItem]

        //  winner can't payAuction after timeOutWinner (seconds)
        access(self) var timeOutWinner: UFix64
        // if winner price is >= maxPriceCanPay; the winner have to bank to ownerAuction and ownerAuction can transfer NFT as manuallly
        access(self) var maxPriceCanPay: UFix64

        access(self) var paymentWith: PaymentWithEnum

        //The Item that is sold at this auction
        //It would be really easy to extend this auction with using a NFTCollection here to be able to auction of several NFTs as a single
        //Lets say if you want to auction of a pack of TopShot moments
        access(contract) var NFT: @MIKOSEANFT.NFT?

        access(self) var metadata: {String:String}

        //This is the escrow vault that holds the tokens for the current largest bid
        access(self) let bidVault: @FungibleToken.Vault

        //The minimum increment for a bid. This is an english auction style system where bids increase
        access(self) var minimumBidIncrement: UFix64

        //the time the acution should start at
        access(self) var auctionStartTime: UFix64

        //the time the acution should end at
        access(self) var auctionEndTime: UFix64

        //the time the acution should completed at
        access(self) var auctionCompleteTime: UFix64?

        //the time the winner receive NFT
        access(self) var sendNftTime: UFix64?

        //Right now the dropitem is not moved from the collection when it ends, it is just marked here that it has ended
        // auctioning -> completed(when owner compeletes as manually) -> finished(when bidder payAuction)
        access(self) var auctionStatus: AuctionStatusEnum

        // Auction State
        access(self) var startPrice: UFix64

        //the capability for the owner of the NFT to return the item to if the auction is cancelled
        access(self) let ownerCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>

        //the capability to pay the owner of the item when the auction is done
        access(self) let ownerVaultCap: Capability<&{FungibleToken.Receiver}>

        // access(self) let cutPercentage: UFix64
        access(self) var royalties: MetadataViews.Royalties

        pub let createdAt: UFix64

        init(
            NFT: @MIKOSEANFT.NFT,
            minimumBidIncrement: UFix64,
            auctionStartTime: UFix64,
            startPrice: UFix64,
            maxPriceCanPay: UFix64,
            auctionEndTime: UFix64,
            timeOutWinner: UFix64,
            ownerCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>,
            ownerVaultCap: Capability<&{FungibleToken.Receiver}>,
            metadata: {String:String},
            royalties: MetadataViews.Royalties,
            paymentWith: PaymentWithEnum
        ) {
            MikoSeaNftAuctionV2.totalAuctions = MikoSeaNftAuctionV2.totalAuctions + 1

            self.auctionId = MikoSeaNftAuctionV2.totalAuctions
            self.NFT <- NFT
            self.minimumBidIncrement = minimumBidIncrement
            self.auctionEndTime = auctionEndTime
            self.startPrice = startPrice
            self.maxPriceCanPay = maxPriceCanPay
            self.auctionStartTime = auctionStartTime
            self.auctionStatus = AuctionStatusEnum.auctioning
            self.ownerCollectionCap = ownerCollectionCap
            self.ownerVaultCap = ownerVaultCap
            self.bidList = []
            self.metadata = metadata
            self.royalties = royalties
            self.bidVault <- FlowToken.createEmptyVault()
            self.timeOutWinner = timeOutWinner
            self.createdAt = getCurrentBlock().timestamp
            self.auctionCompleteTime = nil
            self.sendNftTime = nil
            self.paymentWith = paymentWith
        }

        // get auction metadata
        access(account) fun getMetadata() : {String:String} {
            return self.metadata
        }

        //Number of bids made, that is aggregated to the status struct
        access(account) fun getNumberOfBids():Int {
            return self.bidList.length
        }

        access(account) fun setAuctionStatus(status: AuctionStatusEnum) {
            self.auctionStatus = status
        }

        access(account) fun isWinner(bidderAddress: Address) : Bool {
            return self.getWinner()?.bidItem?.address == bidderAddress
        }

        access(account) fun getMaxPriceCanPay(): UFix64 {
            return self.maxPriceCanPay
        }

        access(account) fun isValidPriceCanPay(_ amount: UFix64):Bool {
            return amount < self.maxPriceCanPay || self.paymentWith != MikoSeaNftAuctionV2.PaymentWithEnum.creaditCard
        }

        access(account) fun getCurrentPrice(): UFix64 {
            let winner = self.getWinner()
            let leader = self.getLeader()
            return winner?.bidItem?.bidPrice ?? leader?.bidPrice ?? 0.0
        }

        access(account) fun completeAuction() {
            self.setAuctionStatus(status: AuctionStatusEnum.compeleted)
            self.auctionCompleteTime = getCurrentBlock().timestamp
        }

        pub fun getPymentWith() : MikoSeaNftAuctionV2.PaymentWithEnum{
            return self.paymentWith
        }

        pub fun floor(_ num: Fix64): Int {
            var strRes = ""
            var numStr = num.toString()
            var i = 0;
            while i < numStr.length {
                if numStr[i] == "." {
                    break;;
                }
                strRes = strRes.concat(numStr.slice(from: i, upTo: i))
                i = i + 1
            }
            return Int.fromString(strRes) ?? 0
        }

        pub fun getLeader(): BidItem? {
            let bidListLen = self.bidList.length
            if bidListLen == 0 {
                return nil
            }
            if self.isAuctionCompleted() || self.isAuctionFinished() {
                let winner = self.getWinner()
                if winner == nil {
                    return nil
                }
                return BidItem(
                    auctionId: self.auctionId,
                    address: winner!.bidItem.address,
                    bidPrice: winner!.bidItem.bidPrice,
                    bidTime: winner!.bidItem.bidTime
                )
            }
            var i = bidListLen - 1
            while i >= 0 {
                let bidItem = self.bidList[i]
                if !MikoSeaNftAuctionV2.isUserInBlacList(auctionId: self.auctionId, address: bidItem.address) {
                    return bidItem
                }
                i = i - 1
            }
            return nil
        }

        pub fun getWinnerIndex(): Int? {
            let bidListLen = self.bidList.length
            if bidListLen == 0 {
                return nil
            }
            let timeDiff = Fix64(getCurrentBlock().timestamp) - Fix64(self.auctionCompleteTime ?? self.auctionEndTime)

            if timeDiff < 0.0 {
                return nil
            }

            let maxTimeOut = Fix64(self.bidList.length) * Fix64(self.timeOutWinner)
            if timeDiff > maxTimeOut {
                return nil
            }

            var step = self.floor(Fix64(timeDiff) / Fix64(self.timeOutWinner))
            if timeDiff > 0.0 && timeDiff % Fix64(self.timeOutWinner) == 0.0 {
                step = step - 1
            }
            return self.bidList.length - 1 - step
        }

        pub fun getLastTimeCanPay(_ winnerIndex: Int): UFix64 {
            return (self.auctionCompleteTime ?? self.auctionEndTime) + self.timeOutWinner * UFix64(winnerIndex)
        }

        pub fun getWinner(): BidWinner? {
            let bidListLen = self.bidList.length
            if bidListLen == 0 {
                return nil
            }
            if self.isAuctionCanceled() || self.isAuctionRejected() {
                return nil
            }
            let winnerIndex = self.getWinnerIndex()
            if winnerIndex == nil {
                return nil
            }
            let winner = self.bidList[winnerIndex!]
            return BidWinner(bidItem: winner, lastTimeCanPay: self.getLastTimeCanPay(winnerIndex!))
        }

        pub fun isCanPlaceBid():Bool {
            let isRejected = MikoSeaNftAuctionV2.auctionIdRejected.contains(self.auctionId)
            let active = !isRejected && self.auctionStatus == AuctionStatusEnum.auctioning && self.isAuctionStarted() && !self.isAuctionExpired() && !self.isAuctionFinished()
            return active;
        }

        access(self) fun isAuctionCompleted(): Bool {
            return self.isAuctionExpired() || self.auctionStatus == AuctionStatusEnum.compeleted
        }

        // is bidder receipted the NFT
        access(self) fun isAuctionFinished(): Bool {
            return self.bidList.length > 0 && self.NFT == nil
        }

        access(self) fun isAuctionStarted(): Bool {
            return self.auctionStartTime <= getCurrentBlock().timestamp
        }

        access(self) fun isAuctionCanceled(): Bool {
            return self.auctionStatus == AuctionStatusEnum.canceled
        }

        access(self) fun isAuctionRejected(): Bool {
            return MikoSeaNftAuctionV2.auctionIdRejected.contains(self.auctionId)
        }

        access(account) fun cancelAuction() {
            pre {
                !self.isAuctionCanceled() : "AUCTION_CANCELED"
            }
            self.returnAuctionItemToOwner()
            self.setAuctionStatus(status:  AuctionStatusEnum.canceled)
            return
        }

        pub fun getCurrentPriceDollar(): UFix64 {
            return MikoSeaUtility.yenToDollar(yen: self.getCurrentPrice())
            // return MikoSeaNftAuctionV2.getPriceFromRate(unit: "USD_TO_YEN", price: self.getCurrentPrice())
        }

        // complete auction as manually
        access(account) fun sendNftToWiner() {
            let winer = self.getWinner()
            if winer == nil {
                return
            }
            let winerCap = getAccount(winer!.bidItem.address).getCapability<&{MIKOSEANFT.MikoSeaCollectionPublic}>(MIKOSEANFT.CollectionPublicPath)
            self.sendNFT(winerCap)
            self.sendNftTime = getCurrentBlock().timestamp
        }

        // sendNFT sends the NFT to the Collection belonging to the provided Capability
        access(contract) fun sendNFT(_ capability: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>) {
            let nftId = self.NFT?.id ?? panic("NFT not exists")
            if let collectionRef = capability.borrow() {
                let nftId = self.NFT?.id ?? panic("NFT_NOT_EXISTS")
                MIKOSEANFT.removeAllCommentByNftId(nftId)

                let NFT <- self.NFT <- nil
                collectionRef.deposit(token: <-NFT!)

                emit SentNFT(auctionId: self.auctionId, nftId: nftId, price: self.getCurrentPrice(), to: collectionRef.owner!.address)
                return
            }
            if let ownerCollection=self.ownerCollectionCap.borrow() {
                let NFT <- self.NFT <- nil
                ownerCollection.deposit(token: <-NFT!)

                emit SentNFT(auctionId: self.auctionId, nftId: nftId, price: self.getCurrentPrice(), to: ownerCollection.owner!.address)
                return
            }
        }

        // SendNFTs sends the bid tokens to the Vault Receiver belonging to the provided Capability
        access(contract) fun SendNFTs(_ capability: Capability<&{FungibleToken.Receiver}>) {
            // borrow a reference to the owner's NFT receiver
            let bidVaultRef = &self.bidVault as &FungibleToken.Vault
            if let vaultRef = capability.borrow() {
                vaultRef.deposit(from: <- self.bidVault.withdraw(amount: self.bidVault.balance))
            } else {
                let ownerRef= self.ownerVaultCap.borrow()!
                ownerRef.deposit(from: <- self.bidVault.withdraw(amount: self.bidVault.balance))
            }
        }

        //Withdraw cutPercentage to marketplace and put it in their vault
        access(self) fun depositToCut(cutPercentage: UFix64, receiverCap:Capability<&{FungibleToken.Receiver}>): UFix64 {
            let receiverRef = receiverCap.borrow()
            if receiverRef != nil {
                let amount=self.getCurrentPrice() * cutPercentage
                let beneficiaryCut <- self.bidVault.withdraw(amount:amount)
                emit MarketplaceEarned(amount: amount, owner: receiverRef!.owner!.address)
                receiverRef!.deposit(from: <- beneficiaryCut)
                return amount
            }
            return 0.0
        }

        // When auction is complete, bidder have to payAuction
        // bidVault: Dollar
        access(account) fun payAuction(winner: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>, bidVault: @FungibleToken.Vault) {
            pre {
                self.NFT != nil: "NFT_NOT_EXISTS"
                self.isValidPriceCanPay(bidVault.balance) : "CAN'T_USING_CARD"
                !self.isAuctionFinished() : "AUCTION_COMPLETED_OR_EXPIRED"
                !self.isAuctionCanceled() : "AUCTION_CANCELED"
                !self.isAuctionRejected() : "AUCTION_REJECTED"
                self.isWinner(bidderAddress: winner.address) : "NOT_WINNER"
            }
            let bidPrice = bidVault.balance
            let priceNeed = self.getCurrentPrice()
            let priceNeedDollar = self.getCurrentPriceDollar()
            if priceNeedDollar > bidPrice {
                panic("BID_PRICE_MUST_BE_LARGER_".concat(priceNeed.toString()))
            }

            self.bidVault.deposit(from: <- bidVault)
            // transfer FT to royalties
            for royalty in self.royalties.getRoyalties() {
                let cutValue = self.depositToCut(cutPercentage: royalty.cut, receiverCap: royalty.receiver)
            }

            // cuts by default
            for royalty in MikoSeaNftAuctionV2.defaultRoyalties.getRoyalties() {
                let cutValue = self.depositToCut(cutPercentage: royalty.cut, receiverCap: royalty.receiver)
            }

            let nftId=self.NFT?.id ?? panic("NFT_NOT_EXISTS")

            self.sendNFT(winner)
            self.sendNftTime = getCurrentBlock().timestamp

            // cut By Nft
            for royalty in MikoSeaNftAuctionV2.nftRoyalties[nftId]?.getRoyalties() ?? [] {
                let cutValue = self.depositToCut(cutPercentage: royalty.cut, receiverCap: royalty.receiver)
            }

            self.SendNFTs(self.ownerVaultCap)

            // emit TokenPurchased(id: self.auctionId,
            //     nftId: nftId,
            //     price: bidPrice,
            //     from: self.ownerVaultCap.address,
            //     to: winner.address)
        }

        access(account) fun returnAuctionItemToOwner() {
            // deposit the NFT into the owner's collection
            self.sendNFT(self.ownerCollectionCap)
         }

        //this can be negative if is expired
        access(account) fun timeRemaining() : Fix64 {
            let endTime = self.auctionCompleteTime ?? self.auctionEndTime
            let currentTime = getCurrentBlock().timestamp

            let remaining= Fix64(endTime) - Fix64(currentTime)
            return remaining
        }

        access(account) fun isAuctionExpired(): Bool {
            let timeRemaining= self.timeRemaining()
            return timeRemaining < Fix64(0.0)
        }

        access(account) fun minNextBid() :UFix64{
            //If there are bids then the next min bid is the current price plus the increment
            let currentPrice = self.getCurrentPrice()
            if currentPrice != 0.0 {
                return currentPrice + self.minimumBidIncrement
            }
            //else start price
            return self.startPrice
        }

        pub fun isValidStepBidPrice(bidPrice: UFix64): Bool {
            var diffPrice: UFix64 = 0.0
            if self.getCurrentPrice() == 0.0 {
                if bidPrice == self.startPrice {
                    return true
                }
                diffPrice = bidPrice - self.startPrice
            } else {
                diffPrice = bidPrice - self.getCurrentPrice()
            }
            return (diffPrice % self.minimumBidIncrement) == 0.0
        }

        //Extend an auction with a given set of blocks
        access(account) fun extendWith(_ amount: UFix64) {
            pre {
                self.auctionStatus == AuctionStatusEnum.auctioning || !self.isAuctionFinished(): "AUCTION_COMPLETED_OR_EXPIRED"
            }
            self.auctionEndTime= self.auctionEndTime + amount
            emit AuctionExtendTime(auctionId: self.auctionId, newEndTime: self.auctionEndTime, extendTime: amount)
        }

        // This method should probably use preconditions more
        access(account) fun placeBid(bidPrice: UFix64, bidderCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>) {
            pre {
                !MikoSeaNftAuctionV2.isUserInBlacList(auctionId: self.auctionId, address: bidderCollectionCap.address) : "YOU_ARE_IN_BLACK_LIST"
                !self.isAuctionCanceled() : "AUCTION_CANCELED"
                !self.isAuctionRejected() : "AUCTION_REJECTED"
                !self.isAuctionCompleted() : "AUCTION_COMPLETED_OR_EXPIRED"
                self.isAuctionStarted() : "AUCTION_NOT_STARTED"
                self.NFT != nil: "NFT_NOT_EXISTS"
            }

            let bidderAddress=bidderCollectionCap.address

            let minNextBid=self.minNextBid()
            if bidPrice < minNextBid {
                panic("BID_PRICE_MUST_BE_LARGER_".concat(minNextBid.toString()))
            }
            if !self.isValidStepBidPrice(bidPrice: bidPrice) {
                panic("BID_PRICE_MUSE_BE_STEP_OF_".concat(self.minimumBidIncrement.toString()))
            }

            // add bidItem in bidList; it also  Update the current price of the token
            let bidItem = BidItem(auctionId: self.auctionId, address: bidderAddress, bidPrice: bidPrice, bidTime: nil)
            self.bidList.append(bidItem)

            emit Bid(auctionId: self.auctionId, bidderAddress: bidderAddress, bidPrice: bidPrice, bidTime: bidItem.bidTime, bidId: UInt64(bidItem.bidId))
        }

        access(account) fun getAuctionInfo() :AuctionInfo {
            let isRejected = MikoSeaNftAuctionV2.auctionIdRejected.contains(self.auctionId)
            let active = self.isCanPlaceBid()
            let winner = self.getWinner()
            let leader = self.getLeader()
            return AuctionInfo(
                auctionId:self.auctionId,
                currentPrice: self.getCurrentPrice(),
                numberOfBids: self.getNumberOfBids(),
                active: active,
                auctionStatus: isRejected ? AuctionStatusEnum.rejected : self.auctionStatus,
                metadata: self.metadata,
                nftId: self.NFT?.id,
                leader: leader,
                winner: winner,
                minimumBidIncrement: self.minimumBidIncrement,
                owner: self.ownerVaultCap.address,
                auctionStartTime: self.auctionStartTime,
                auctionEndTime: self.auctionEndTime,
                auctionCompleteTime: self.auctionCompleteTime,
                sendNftTime: self.sendNftTime,
                minNextBid: self.minNextBid(),
            )
        }

        destroy() {
            // send the NFT back to auction owner
            if self.NFT != nil {
                self.sendNFT(self.ownerCollectionCap)
            }
            destroy self.NFT
            destroy self.bidVault
        }
    }

    // AuctionPublic is a resource interface that restricts users to
    // retreiving the auction price list and placing bids
    pub resource interface AuctionPublic {
        pub fun getAllAuctionInfo(): {UInt64: AuctionInfo}
        pub fun getAuctionInfo(_ id:UInt64): AuctionInfo
        pub fun getBidList(_ id: UInt64): [BidItem]
        pub fun getWinner(_ id: UInt64): BidWinner?
        pub fun getMaxPriceCanPay(id: UInt64): UFix64
        pub fun isValidPriceCanPay(id: UInt64, amount: UFix64): Bool
        pub fun isValidStepBidPrice(auctionId: UInt64, price: UFix64): Bool
        pub fun placeBid(
            id: UInt64,
            bidPrice: UFix64,
            bidderCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>
        )

        pub fun payAcution(
            id: UInt64,
            winner: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>,
            bidVault: @FungibleToken.Vault
        )

        pub fun getNftData(_ auctionId: UInt64): MIKOSEANFT.NFTData?
        pub fun getNftImage(_ auctionId: UInt64): String?
        pub fun getNftTitle(_ auctionId: UInt64): String?
        pub fun getNftDescription(_ auctionId: UInt64): String?
        pub fun getMinNextBid(_ auctionId: UInt64): UFix64
        pub fun getAuctionPriceDollar(_ auctionId: UInt64): UFix64
        pub fun getPaymentWith(_ auctionId: UInt64): MikoSeaNftAuctionV2.PaymentWithEnum
    }

    // AuctionCollection contains a dictionary of AuctionItems and provides
    // methods for manipulating the AuctionItems
    pub resource AuctionCollection: AuctionPublic {
        // Auction Items
        pub var auctionItems: @{UInt64: AuctionItem}
        pub let receiverCap: Capability<&{FungibleToken.Receiver}>

        init(
            receiverCap: Capability<&{FungibleToken.Receiver}>,
        ) {
            self.receiverCap = receiverCap
            self.auctionItems <- {}
        }

        access(self) fun getAuctionRef(_ id: UInt64): &AuctionItem {
            pre {
                self.auctionItems[id] != nil:
                    "AUCTION_NOT_STARTED"
            }
            let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
            return itemRef
        }

        // getAuctionPrices returns a dictionary of available NFT IDs with their current price
        pub fun getAllAuctionInfo(): {UInt64: AuctionInfo} {
            let priceList: {UInt64: AuctionInfo} = {}

            for id in self.auctionItems.keys {
                let itemRef = (&self.auctionItems[id] as? &AuctionItem?)!
                priceList[id] = itemRef.getAuctionInfo()
            }

            return priceList
        }

        pub fun getAuctionInfo(_ id:UInt64): AuctionInfo {
            let itemRef = self.getAuctionRef(id)
            return itemRef.getAuctionInfo()
        }

        pub fun getBidList(_ id: UInt64): [BidItem] {
            let itemRef = self.getAuctionRef(id)
            return itemRef.bidList
        }

        pub fun getWinner(_ id: UInt64): BidWinner? {
            let itemRef = self.getAuctionRef(id)
            return itemRef.getWinner()
        }

        pub fun getMaxPriceCanPay(id: UInt64): UFix64 {
            let itemRef = self.getAuctionRef(id)
            return itemRef.getMaxPriceCanPay()
        }

        pub fun isValidPriceCanPay(id: UInt64, amount: UFix64):Bool {
            let itemRef = self.getAuctionRef(id)
            return itemRef.isValidPriceCanPay(amount)
        }

        pub fun isValidStepBidPrice(auctionId: UInt64, price: UFix64): Bool {
            return self.getAuctionRef(auctionId).isValidStepBidPrice(bidPrice: price)
        }

        // placeBid sends the bidder's tokens to the bid vault and updates the
        // currentPrice of the current auction item
        pub fun placeBid(
            id: UInt64,
            bidPrice: UFix64,
            bidderCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>) {
            // Get the auction item resources
            let itemRef = self.getAuctionRef(id)
            itemRef.placeBid(
              bidPrice: bidPrice,
              bidderCollectionCap:bidderCollectionCap)
        }

        pub fun payAcution(
            id: UInt64,
            winner: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>,
            bidVault: @FungibleToken.Vault
        ) {
            let itemRef = self.getAuctionRef(id)
            itemRef.payAuction(winner: winner, bidVault: <- bidVault)
        }

        pub fun extendAllAuctionsWith(_ amount: UFix64) {
            for id in self.auctionItems.keys {
                let itemRef = (&self.auctionItems[id] as? &AuctionItem?)!
                itemRef.extendWith(amount)
            }
        }

        pub fun extendAuctionWith(id: UInt64, amount: UFix64) {
            let itemRef = (&self.auctionItems[id] as? &AuctionItem?)
            itemRef?.extendWith(amount)
        }

        pub fun keys() : [UInt64] {
            return self.auctionItems.keys
        }

        pub fun getNftData(_ auctionId: UInt64): MIKOSEANFT.NFTData? {
            let itemRef = (&self.auctionItems[auctionId] as? &AuctionItem?)!
            return itemRef.NFT?.data
        }

        pub fun getNftImage(_ auctionId: UInt64): String? {
            let itemRef = (&self.auctionItems[auctionId] as? &AuctionItem?)!
            return itemRef.NFT?.getImage()
        }

        pub fun getNftTitle(_ auctionId: UInt64): String? {
            let itemRef = (&self.auctionItems[auctionId] as? &AuctionItem?)!
            return itemRef.NFT?.getTitle()
        }

        pub fun getNftDescription(_ auctionId: UInt64): String? {
            let itemRef = (&self.auctionItems[auctionId] as? &AuctionItem?)!
            return itemRef.NFT?.getTitle()
        }

        // addTokenToauctionItems adds an NFT to the auction items and sets the meta data
        // for the auction item
        pub fun createAuction(
            token: @MIKOSEANFT.NFT,
            minimumBidIncrement: UFix64,
            auctionEndTime: UFix64,
            auctionStartTime: UFix64,
            timeOutWinner: UFix64,
            startPrice: UFix64,
            maxPriceCanPay: UFix64,
            ownerCollectionCap: Capability<&{MIKOSEANFT.MikoSeaCollectionPublic}>,
            ownerVaultCap: Capability<&{FungibleToken.Receiver}>,
            metadata: {String:String},
            royalties: MetadataViews.Royalties,
            paymentWith: PaymentWithEnum) {

            pre {
                ownerCollectionCap.borrow() != nil : "ownerCollectionRef must be required"
                ownerVaultCap.borrow() != nil : "ownerVaultRef must be required"
                auctionStartTime < auctionEndTime : "auctionStartTime must be < auctionEndTime"
            }

            let nftId = token.id

            // create a new auction items resource container
            let item <- create AuctionItem(
                NFT: <-token,
                minimumBidIncrement: minimumBidIncrement,
                auctionStartTime: auctionStartTime,
                startPrice: startPrice,
                maxPriceCanPay: maxPriceCanPay,
                auctionEndTime: auctionEndTime,
                timeOutWinner: timeOutWinner,
                ownerCollectionCap: ownerCollectionCap,
                ownerVaultCap: ownerVaultCap,
                metadata: metadata,
                royalties: royalties,
                paymentWith: paymentWith
            )

            let id = item.auctionId
            let createdAt = item.createdAt

            // update the auction items dictionary with the new resources
            let oldItem <- self.auctionItems[id] <- item
            destroy oldItem

            let owner= ownerVaultCap.address

            MikoSeaNftAuctionV2.bidNumber[id] = 0
            emit Created(
                auctionId: id,
                owner: owner,
                startPrice: startPrice,
                startTime: auctionStartTime,
                endTime: auctionEndTime,
                nftId: nftId,
                createdAt: createdAt,
                maxPriceCanPay: maxPriceCanPay,
                minimumBidIncrement: minimumBidIncrement,
                metadata: metadata
                )
        }

        pub fun cancelAuction(_ id: UInt64) {
            let itemRef = self.getAuctionRef(id)
            itemRef.cancelAuction()
            emit Canceled(auctionId: id)
        }

        pub fun completeAuction(id: UInt64) {
            let itemRef = self.getAuctionRef(id)
            itemRef.completeAuction()
            emit Completed(auctionId: id)
        }

        pub fun sendNftToWiner(_ id: UInt64) {
            let itemRef = self.getAuctionRef(id)
            itemRef.sendNftToWiner()
        }

        pub fun getMinNextBid(_ auctionId: UInt64): UFix64 {
            let itemRef = self.getAuctionRef(auctionId)
            return itemRef.minNextBid()
        }

        pub fun getAuctionPriceDollar(_ auctionId: UInt64): UFix64 {
            let itemRef = self.getAuctionRef(auctionId)
            return itemRef.getCurrentPriceDollar()
        }

        pub fun getPaymentWith(_ auctionId: UInt64): MikoSeaNftAuctionV2.PaymentWithEnum {
            return self.getAuctionRef(auctionId).getPymentWith()
        }

        destroy() {
            // destroy the empty resources
            destroy self.auctionItems
        }
    }

    //------------------------------------------------------------
    // Admin
    //------------------------------------------------------------

    pub resource Admin {
        pub fun setDefaultAuctionSaleCuts(_ royalty: MetadataViews.Royalties) {
            MikoSeaNftAuctionV2.defaultRoyalties = royalty
        }

        pub fun setNftAuctionSaleCuts(nftId: UInt64, cuts: MetadataViews.Royalties) {
            MikoSeaNftAuctionV2.nftRoyalties[nftId] = cuts
        }

        pub fun rejectAuction(auctionId: UInt64) {
            let indexFound = MikoSeaNftAuctionV2.auctionIdRejected.firstIndex(of: auctionId)
            if indexFound == nil {
                MikoSeaNftAuctionV2.auctionIdRejected.append(auctionId)
            }
            emit AuctionRejected(auctionId: auctionId)
        }

        pub fun unRejectedAuction(auctionId: UInt64) {
            let indexFound = MikoSeaNftAuctionV2.auctionIdRejected.firstIndex(of: auctionId)
            if indexFound != nil {
                MikoSeaNftAuctionV2.auctionIdRejected.remove(at: indexFound!)
            }
            emit AuctionUnrejected(auctionId: auctionId)
        }

        pub fun addUserToBlacklist(auctionId: UInt64, addresses: [Address]) {
            if MikoSeaNftAuctionV2.blackList[auctionId] == nil {
                MikoSeaNftAuctionV2.blackList[auctionId] = []
            }
            MikoSeaNftAuctionV2.blackList[auctionId]!.appendAll(addresses)
            emit AddToBlackList(auctionId: auctionId, addresses: addresses)
        }

        pub fun removeUserFromBlacklist(auctionId: UInt64, addresses: [Address]) {
            if MikoSeaNftAuctionV2.blackList[auctionId] == nil || MikoSeaNftAuctionV2.blackList[auctionId]!.length == 0 {
                MikoSeaNftAuctionV2.blackList[auctionId] = []
                return
            }
            let temp : [Address] = []
            for address in MikoSeaNftAuctionV2.blackList[auctionId] ?? [] {
                if !addresses.contains(address) {
                    temp.append(address)
                }
            }
            MikoSeaNftAuctionV2.blackList[auctionId] = temp
            emit RemoveFromBlackList(auctionId: auctionId, addresses: addresses)
        }

        // pub fun setRate(key:String, rate: UFix64) {
        //     MikoSeaNftAuctionV2.ratePrice[key] = rate
        // }
    }

    // MikoSeaAuction public function
    pub fun isUserInBlacList(auctionId: UInt64, address: Address): Bool {
        return MikoSeaNftAuctionV2.blackList[auctionId]?.contains(address) ?? false
    }

    // createAuctionCollection returns a new AuctionCollection resource to the caller
    pub fun createAuctionCollection(ownerCap: Capability<&{FungibleToken.Receiver}>): @AuctionCollection {
        let auctionCollection <- create AuctionCollection(
            receiverCap: ownerCap
        )

        emit CollectionCreated(owner: ownerCap.address)
        return <- auctionCollection
    }

    // pub fun getPriceFromRate(unit: String, price: UFix64) : UFix64 {
    //     return (MikoSeaNftAuctionV2.ratePrice[unit] ?? 0.0) * price
    // }

    init() {
        self.totalAuctions = 0
        self.AdminStoragePath = /storage/MikoSeaNftAuctionV2AdminStoragePath
        self.CollectionStoragePath = /storage/MikoSeaNftAuctionV2CollectionStoragePath
        self.CollectionPublicPath = /public/MikoSeaNftAuctionV2CollectionPublicPath

        self.bidNumber = {}
        self.ratePrice = {
            "USD_TO_YEN": 137.29
        }
        self.auctionIdRejected = []
        self.defaultRoyalties = MetadataViews.Royalties([])
        self.nftRoyalties = {}
        self.blackList = {}
        // Put the Admin in storage
        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}

