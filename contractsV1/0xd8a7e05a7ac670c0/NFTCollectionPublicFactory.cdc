import CapabilityFactory from "./CapabilityFactory.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFTCollectionPublicFactory{ 
	access(all)
	struct Factory: CapabilityFactory.Factory{ 
		access(all)
		fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
			return acct.getCapability<&{NonFungibleToken.CollectionPublic}>(path)
		}
	}
}
