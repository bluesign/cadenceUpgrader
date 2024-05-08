// MetadataViews used by products at Flowty
// For more information, please see our developer docs:
//
// https://docs.flowty.io/developer-docs/
access(all)
contract FlowtyViews{ 
	
	// DNA is only needed for NFTs that can change dynamically. It is used
	// to prevent an NFT from being sold that's been changed between the time of
	// making a listing, and that listing being filled.
	// 
	// If implemented, DNA is recorded when a listing is made.
	// When the same listing is being filled, the DNA will again be checked.
	// If the DNA of an item when being filled doesn't match what was recorded when
	// listed, do not permit filling the listing.
	access(all)
	struct DNA{ 
		access(all)
		let value: String
		
		init(_ value: String){ 
			self.value = value
		}
	}
}
