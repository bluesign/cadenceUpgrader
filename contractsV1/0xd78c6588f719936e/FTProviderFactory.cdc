import CapabilityFactory from "../0xea86b9b77d95aeea/CapabilityFactory.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FTProviderFactory{ 
	access(all)
	struct Factory: CapabilityFactory.Factory{ 
		access(all)
		fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
			return acct.getCapability<&{FungibleToken.Provider}>(path)
		}
	}
}
