import CapabilityFactory from "../0xea86b9b77d95aeea/CapabilityFactory.cdc"
import Lama from "../0xea86b9b77d95aeea/Lama.cdc"

pub contract LamaFactory {
    pub struct Factory: CapabilityFactory.Factory {
        pub fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability {
            return acct.getCapability<&{Lama.ParentAccess}>(path)
        }
    }
}