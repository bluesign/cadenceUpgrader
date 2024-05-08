import CapabilityFactory from "./CapabilityFactory.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FTReceiverFactory{ 
	access(all)
	struct Factory: CapabilityFactory.Factory{ 
		access(all)
		fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
			return acct.getCapability<&{FungibleToken.Receiver}>(path)
		}
	}
}
