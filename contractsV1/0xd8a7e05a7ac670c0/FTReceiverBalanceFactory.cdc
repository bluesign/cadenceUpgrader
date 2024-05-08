import CapabilityFactory from "./CapabilityFactory.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract FTReceiverBalanceFactory{ 
	access(all)
	struct Factory: CapabilityFactory.Factory{ 
		access(all)
		fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
			return acct.getCapability<&{FungibleToken.Receiver, FungibleToken.Balance}>(path)
		}
	}
}
