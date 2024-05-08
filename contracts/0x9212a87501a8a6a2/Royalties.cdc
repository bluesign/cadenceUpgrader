 /*
    Royalties.cdc

    The contract manages royalty fee distributions for Flowverse NFT platform

    Author: Brian Min brian@flowverse.co
*/

import NFTStorefrontV2 from "../0x4eb8a10cb9f87357/NFTStorefrontV2.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

access(all) contract Royalties {
    pub let AdminStoragePath: StoragePath

    pub struct Override {
        pub let rateOverride: UFix64?
        pub let descriptionOverride: String?
        pub let receiverOverride: Capability<&AnyResource{FungibleToken.Receiver}>?
        pub let rateMatcher: UFix64?
        pub let descriptionMatcher: String?
        pub let receiverIdentifierMatcher: String?
        init(
            rateOverride: UFix64?,
            descriptionOverride: String?,
            receiverOverride: Capability<&AnyResource{FungibleToken.Receiver}>?,
            rateMatcher: UFix64?,
            descriptionMatcher: String?,
            receiverIdentifierMatcher: String?
        ) {
            pre {
                rateOverride == nil || (rateOverride! >= 0.0 && rateOverride! <= 1.0): "Rate should be in valid range i.e [0,1]"
                rateMatcher == nil || (rateMatcher! >= 0.0 && rateMatcher! <= 1.0): "Rate should be in valid range i.e [0,1]"
            }
            self.rateOverride = rateOverride
            self.descriptionOverride = descriptionOverride
            self.receiverOverride = receiverOverride
            self.rateMatcher = rateMatcher
            self.descriptionMatcher = descriptionMatcher
            self.receiverIdentifierMatcher = receiverIdentifierMatcher
        }
    }

    access(contract) var overrides: {String: [Override]}
    
    pub resource RoyaltiesAdmin {
        pub fun addRoyaltyOverride(
            identifier: String,
            rateOverride: UFix64?,
            descriptionOverride: String?,
            receiverOverride: Capability<&AnyResource{FungibleToken.Receiver}>?,
            rateMatcher: UFix64?,
            descriptionMatcher: String?,
            receiverIdentifierMatcher: String?
        ) {
            if Royalties.overrides[identifier] == nil {
                Royalties.overrides[identifier] = []
            }

            Royalties.overrides[identifier]!.append(
              Override(
                rateOverride: rateOverride,
                descriptionOverride: descriptionOverride,
                receiverOverride: receiverOverride,
                rateMatcher: rateMatcher,
                descriptionMatcher: descriptionMatcher,
                receiverIdentifierMatcher: receiverIdentifierMatcher
              )
            )
        }

        pub fun removeRoyaltyOverride(identifier: String, index: Int) {
            if Royalties.overrides[identifier] == nil {
                panic("Royalty override not found")
            }

            Royalties.overrides[identifier]!.remove(at: index)
            if Royalties.overrides[identifier]!.length == 0 {
                Royalties.overrides.remove(key: identifier)
            }
        }
    }

    access(all) fun getOverridesMapping(): {String: [Override]} {
        return Royalties.overrides
    }
    
    access(all) fun getOverrides(_ identifier: String): [Override] {
        return Royalties.overrides[identifier] ?? []
    }

    access(all) fun findMatchingOverride(overrides: [Override], royalty: MetadataViews.Royalty, ftReceiverPathIdentifier: String): Override? {
        for o in overrides {
            if o.rateMatcher != nil && o.rateMatcher! != royalty.cut {
                continue
            }
            if o.descriptionMatcher != nil && o.descriptionMatcher!.toLower() != royalty.description.toLower() {
                continue
            }
            if o.receiverIdentifierMatcher != nil && o.receiverIdentifierMatcher! != ftReceiverPathIdentifier {
                continue
            }
            return o
        }
        return nil
    }

    access(all) fun getNFTRoyalties(nft: &NonFungibleToken.NFT, ftReceiverPath: PublicPath, receiverAddressOverrides: [Address]): [MetadataViews.Royalty] {
        let royalties: [MetadataViews.Royalty] = []
        if nft.getViews().contains(Type<MetadataViews.Royalties>()) {
            let royaltyOverrides = self.getOverrides(nft.getType().identifier)
            let royaltiesRef = nft.resolveView(Type<MetadataViews.Royalties>()) ?? panic("Unable to retrieve the royalties")
            let metadataRoyalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
            for i, royalty in metadataRoyalties {
                let o = self.findMatchingOverride(overrides: royaltyOverrides, royalty: royalty, ftReceiverPathIdentifier: ftReceiverPath.toString())
                var rate: UFix64 = royalty.cut 
                var description: String = royalty.description 
                var receiver: Capability<&AnyResource{FungibleToken.Receiver}>? = nil
                if o != nil {
                    if o!.rateOverride != nil {
                        rate = o!.rateOverride!
                    }
                    if o!.descriptionOverride != nil {
                        description = o!.descriptionOverride!
                    }
                    if o!.receiverOverride != nil {
                        receiver = o!.receiverOverride!
                    }
                }
                // Skip if rate is 0
                if rate == 0.0 {
                    continue
                }
                if receiverAddressOverrides.length > i {
                    receiver = getAccount(receiverAddressOverrides[i]).getCapability<&AnyResource{FungibleToken.Receiver}>(ftReceiverPath)
                }
                if receiver == nil {
                    receiver = getAccount(royalty.receiver.address).getCapability<&AnyResource{FungibleToken.Receiver}>(ftReceiverPath)
                }
                if(receiver!.check()) {
                    royalties.append(
                        MetadataViews.Royalty(
                            receiver: receiver!,
                            cut: rate,
                            description: description
                        )
                    )
                }
            }
        }
        return royalties
    }

    access(all) fun getRoyaltySaleCutsForStorefrontV2(
        nft: &NonFungibleToken.NFT,
        salePrice: UFix64,
        ftReceiverPath: PublicPath,
        receiverAddressOverrides: [Address]
    ): [NFTStorefrontV2.SaleCut] {
        let saleCuts: [NFTStorefrontV2.SaleCut] = []
        let royalties = self.getNFTRoyalties(nft: nft, ftReceiverPath: ftReceiverPath, receiverAddressOverrides: receiverAddressOverrides)
        for royalty in royalties {
            saleCuts.append(NFTStorefrontV2.SaleCut(receiver: royalty.receiver, amount: royalty.cut * salePrice))
        }
        return saleCuts
    }

    init() {
        self.overrides = {}
        self.AdminStoragePath = /storage/FlowverseRoyaltiesAdmin
        let admin <- create RoyaltiesAdmin()
        self.account.save(<-admin, to: self.AdminStoragePath)
    }
}
