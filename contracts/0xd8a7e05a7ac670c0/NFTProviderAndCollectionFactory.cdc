import CapabilityFactory from "./CapabilityFactory.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract NFTProviderAndCollectionFactory {
    pub struct Factory: CapabilityFactory.Factory {
        pub fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability {
            return acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(path)
        }
    }
}