import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Resolver from "../0xb8ea91944fd51c43/Resolver.cdc"

pub contract FlowtyOffersResolver {
    pub let PublicPath: PublicPath
    pub let StoragePath: StoragePath

    pub enum ResolverType: UInt8 {
        pub case NFT
        pub case Global
    }

    pub resource OfferResolver: Resolver.ResolverPublic {
        pub fun checkOfferResolver(
            item: &AnyResource{NonFungibleToken.INFT, MetadataViews.Resolver},
            offerParamsString: {String:String},
            offerParamsUInt64: {String:UInt64},
            offerParamsUFix64: {String:UFix64}
        ): Bool {
            if let expiry = offerParamsUInt64["expiry"] {
                assert(expiry > UInt64(getCurrentBlock().timestamp), message: "offer is expired")
            }
            switch offerParamsString["resolver"]! {
                case ResolverType.NFT.rawValue.toString():
                    assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
                    return true
                case ResolverType.Global.rawValue.toString():
                    assert(item.getType().identifier == offerParamsString["nftType"], message: "item NFT does not have specified type")
                    return true
                default:
                    panic("Invalid Resolver on Offer: ".concat(offerParamsString["resolver"] ?? "unknown"))
            }

            return false
        }

    }

    pub fun createResolver(): @OfferResolver {
        return <-create OfferResolver()
    }

    pub fun getResolverCap(): Capability<&FlowtyOffersResolver.OfferResolver{Resolver.ResolverPublic}> {
        return self.account.getCapability<&FlowtyOffersResolver.OfferResolver{Resolver.ResolverPublic}>(FlowtyOffersResolver.PublicPath)
    }

    init() {
        let p = "OffersResolver".concat(self.account.address.toString())

        self.PublicPath = PublicPath(identifier: p)!
        self.StoragePath = StoragePath(identifier: p)!

        let resolver <- create OfferResolver()
        self.account.save(<-resolver, to: self.StoragePath)
        self.account.link<&FlowtyOffersResolver.OfferResolver{Resolver.ResolverPublic}>(self.PublicPath, target: self.StoragePath)
    }
}
 