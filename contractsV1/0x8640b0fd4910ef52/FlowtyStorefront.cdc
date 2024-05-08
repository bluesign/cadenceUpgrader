import NFTStorefrontV2 from "./../../standardsV1/NFTStorefrontV2.cdc"

access(all)
contract FlowtyStorefront{ 
	access(all)
	fun getStorefrontRef(owner: Address): &NFTStorefrontV2.Storefront{ 
		return getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
			NFTStorefrontV2.StorefrontPublicPath
		).borrow()
		?? panic("Could not borrow public storefront from address")
	}
	
	access(all)
	fun getStorefrontRefSafe(owner: Address): &NFTStorefrontV2.Storefront?{ 
		return getAccount(owner).capabilities.get<&NFTStorefrontV2.Storefront>(
			NFTStorefrontV2.StorefrontPublicPath
		).borrow()
	}
}
