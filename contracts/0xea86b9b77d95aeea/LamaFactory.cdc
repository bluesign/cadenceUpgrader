import CapabilityFactory from "./CapabilityFactory.cdc"
import Lama from "./Lama.cdc"

pub contract LamaFactory {
    pub struct Factory: CapabilityFactory.Factory {
        pub fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability {
            return acct.getCapability<&{Lama.ParentAccess}>(path)
        }
    }
}