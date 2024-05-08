import CapabilityFactory from "../0xea86b9b77d95aeea/CapabilityFactory.cdc"

import Lama from "../0xea86b9b77d95aeea/Lama.cdc"

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
