import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import betaLilaiQuest from "./betaLilaiQuest.cdc"

pub contract betaLilaiMarket {

    pub event ItemListed(id: UInt64, price: UFix64, seller: Address?)
    pub event ItemPriceChanged(id: UInt64, newPrice: UFix64, seller: Address?)
    pub event ItemPurchased(id: UInt64, price: UFix64, seller: Address?)
    pub event ItemWithdrawn(id: UInt64, owner: Address?)
    pub event CutPercentageChanged(newPercent: UFix64, seller: Address?)

    pub resource interface SalePublic {
        pub var cutPercentage: UFix64
        pub fun purchase(itemId: UInt64, buyTokens: @FungibleToken.Vault): @betaLilaiQuest.NFT
        pub fun getPrice(itemId: UInt64): UFix64?
        pub fun getIDs(): [UInt64]
        pub fun borrowItem(id: UInt64): &betaLilaiQuest.NFT?
    }

    pub resource interface SaleListable {
    pub fun listForSale(item: @betaLilaiQuest.NFT, price: UFix64, caller: Address)
    }

    pub resource SaleCollection: SalePublic, SaleListable {
        pub var forSale: @betaLilaiQuest.NFTCollection
        access(self) var prices: {UInt64: UFix64}
        access(self) var ownerCapability: Capability
        access(self) var beneficiaryCapability: Capability
        pub var cutPercentage: UFix64

        init(ownerCapability: Capability, beneficiaryCapability: Capability, cutPercentage: UFix64) {
            self.forSale <- betaLilaiQuest.createNFTCollection()
            self.ownerCapability = ownerCapability
            self.beneficiaryCapability = beneficiaryCapability
            self.prices = {}
            self.cutPercentage = cutPercentage
        }

        pub fun listForSale(item: @betaLilaiQuest.NFT, price: UFix64, caller: Address) {
            assert(caller == self.owner?.address, message: "Caller is not the owner of the item")
            let id = item.id
            self.prices[id] = price
            self.forSale.deposit(token: <-item)
            emit ItemListed(id: id, price: price, seller: self.owner?.address)
        }

        pub fun withdraw(itemId: UInt64): @betaLilaiQuest.NFT {
            let item <- self.forSale.withdraw(id: itemId)
            self.prices.remove(key: itemId)
            emit ItemWithdrawn(id: item.id, owner: self.owner?.address)
            return <-item
        }

        pub fun purchase(itemId: UInt64, buyTokens: @FungibleToken.Vault): @betaLilaiQuest.NFT {
            pre {
                self.forSale.borrowNFT(id: itemId) != nil && self.prices[itemId] != nil:
                    "No item matching this ID for sale!"
                buyTokens.balance == (self.prices[itemId] ?? UFix64(0)):
                    "Not enough tokens to buy the item!"
            }
            let price = self.prices[itemId]!
            self.prices.remove(key: itemId)
            let beneficiaryCut <- buyTokens.withdraw(amount: price * self.cutPercentage)
            self.beneficiaryCapability.borrow<&{FungibleToken.Receiver}>()!.deposit(from: <-beneficiaryCut)
            self.ownerCapability.borrow<&{FungibleToken.Receiver}>()!.deposit(from: <-buyTokens)
            emit ItemPurchased(id: itemId, price: price, seller: self.owner?.address)
            return <-self.withdraw(itemId: itemId)
        }

        pub fun changePrice(itemId: UInt64, newPrice: UFix64) {
            pre {
                self.prices[itemId] != nil: "Cannot change the price for an item that is not for sale"
            }
            self.prices[itemId] = newPrice
            emit ItemPriceChanged(id: itemId, newPrice: newPrice, seller: self.owner?.address)
        }

        pub fun changePercentage(newPercent: UFix64) {
            pre {
                newPercent <= 1.0: "Cannot set cut percentage to greater than 100%"
            }
            self.cutPercentage = newPercent
            emit CutPercentageChanged(newPercent: newPercent, seller: self.owner?.address)
        }

        pub fun changeOwnerReceiver(newOwnerCapability: Capability) {
            pre {
                newOwnerCapability.borrow<&{FungibleToken.Receiver}>() != nil:
                    "Owner's Receiver Capability is invalid!"
            }
            self.ownerCapability = newOwnerCapability
        }

        pub fun changeBeneficiaryReceiver(newBeneficiaryCapability: Capability) {
            pre {
                newBeneficiaryCapability.borrow<&{FungibleToken.Receiver}>() != nil:
                    "Beneficiary's Receiver Capability is invalid!"
            }
            self.beneficiaryCapability = newBeneficiaryCapability
        }

        pub fun getPrice(itemId: UInt64): UFix64? {
            return self.prices[itemId]
        }

        pub fun getIDs(): [UInt64] {
            return self.forSale.getTokenIds()
        }

        pub fun borrowItem(id: UInt64): &betaLilaiQuest.NFT? {
            let ref = self.forSale.borrowNFT(id: id)
            return ref
        }

        destroy() {
            destroy self.forSale
        }
    }

    pub fun createSaleCollection(ownerCapability: Capability<&{FungibleToken.Receiver}>, beneficiaryCapability: Capability<&{FungibleToken.Receiver}>, cutPercentage: UFix64): @SaleCollection {
        return <-create SaleCollection(ownerCapability: ownerCapability, beneficiaryCapability: beneficiaryCapability, cutPercentage: cutPercentage)
    }
}