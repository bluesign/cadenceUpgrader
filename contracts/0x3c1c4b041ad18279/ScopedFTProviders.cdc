import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import StringUtils from "../0xa340dc0a4ec828ab/StringUtils.cdc"

// ScopedFTProviders
//
// TO AVOID RISK, PLEASE DEPLOY YOUR OWN VERSION OF THIS CONTRACT SO THAT
// MALICIOUS UPDATES ARE NOT POSSIBLE
//
// ScopedProviders are meant to solve the issue of unbounded access FungibleToken vaults 
// when a provider is called for.
pub contract ScopedFTProviders {
    pub struct interface FTFilter {
        pub fun canWithdrawAmount(_ amount: UFix64): Bool
        pub fun markAmountWithdrawn(_ amount: UFix64)
        pub fun getDetails(): {String: AnyStruct}
    }

    pub struct AllowanceFilter: FTFilter {
        access(self) let allowance: UFix64
        access(self) var allowanceUsed: UFix64

        init(_ allowance: UFix64) {
            self.allowance = allowance
            self.allowanceUsed = 0.0
        }

        pub fun canWithdrawAmount(_ amount: UFix64): Bool {
            return amount + self.allowanceUsed <= self.allowance
        }

        pub fun markAmountWithdrawn(_ amount: UFix64) {
            self.allowanceUsed = self.allowanceUsed + amount
        }

        pub fun getDetails(): {String: AnyStruct} {
            return {
                "allowance": self.allowance,
                "allowanceUsed": self.allowanceUsed
            }
        }
    }

    pub resource interface ScopedFTProviderPublic {
        pub fun balance(): UFix64
        pub fun deposit(tokens: @FungibleToken.Vault)
    }

    // ScopedFTProvider
    //
    // A ScopedFTProvider is a wrapped FungibleTokenProvider with 
    // filters that can be defined by anyone using the ScopedFTProvider.
    pub resource ScopedFTProvider: FungibleToken.Provider, ScopedFTProviderPublic {
        access(self) let provider: Capability<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>
        access(self) var filters: [{FTFilter}]

        // block timestamp that this provider can no longer be used after
        access(self) let expiration: UFix64?

        pub init(provider: Capability<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>, filters: [{FTFilter}], expiration: UFix64?) {
            self.provider = provider
            self.filters = filters
            self.expiration = expiration
        }

        pub fun check(): Bool {
            return self.provider.check()
        }

        pub fun balance(): UFix64 {
            return self.provider.borrow()!.balance
        }

        pub fun deposit(tokens: @FungibleToken.Vault) {
            self.provider.borrow()!.deposit(from: <-tokens)
        }

        pub fun canWithdraw(_ amount: UFix64): Bool {
            if self.expiration != nil && getCurrentBlock().timestamp >= self.expiration! {
                return false
            }

            for f in self.filters {
                if !f.canWithdrawAmount(amount) {
                    return false
                }
            }

            return true
        }

        pub fun getProviderType(): Type {
            return self.provider.borrow()!.getType()
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            pre {
                self.expiration == nil || self.expiration! >= getCurrentBlock().timestamp: "provider has expired"
            }

            var i = 0
            while i < self.filters.length {
                if !self.filters[i].canWithdrawAmount(amount) {
                    panic(StringUtils.join(["cannot withdraw tokens. filter of type", self.filters[i].getType().identifier, "failed."], " "))
                }

                self.filters[i].markAmountWithdrawn(amount)
                i = i + 1
            }

            return <-self.provider.borrow()!.withdraw(amount: amount)
        }

        pub fun getDetails(): [{String: AnyStruct}] {
            let details: [{String: AnyStruct}] = []
            for f in self.filters {
                details.append(f.getDetails())
            }

            return details
        }
    }

    pub fun createScopedFTProvider(
        provider: Capability<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>,
        filters: [{FTFilter}],
        expiration: UFix64?
    ): @ScopedFTProvider {
        return <- create ScopedFTProvider(provider: provider, filters: filters, expiration: expiration)
    }
}
