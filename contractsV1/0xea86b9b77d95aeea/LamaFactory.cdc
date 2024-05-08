import CapabilityFactory from "./CapabilityFactory.cdc"

import Lama from "./Lama.cdc"

access(all)
contract LamaFactory{ 
	access(all)
	struct Factory: CapabilityFactory.Factory{ 
		access(all)
		fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
			return acct.getCapability<&{Lama.ParentAccess}>(path)
		}
	}
}
