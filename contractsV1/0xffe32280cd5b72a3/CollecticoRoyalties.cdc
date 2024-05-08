import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

/*
	Provides cuts of the issuer
	(c) CollecticoLabs.com
 */

access(all)
contract CollecticoRoyalties{ 
	access(all)
	fun getIssuerRoyalties(): [MetadataViews.Royalty]{ 
		return []
	}
}
