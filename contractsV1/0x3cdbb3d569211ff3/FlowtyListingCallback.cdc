import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowtyViews from "./FlowtyViews.cdc"

/*
FlowtyListingCallback

A contract to allow the injection of custom logic for the various
lifecycle events of a listing. For now, these callbacks are limited purely to
those created by the caller of the listing. In the future, it may be the case that
an nft itself could define its own callback.
*/

access(all)
contract FlowtyListingCallback{ 
	access(all)
	let ContainerStoragePath: StoragePath
	
	/*
		The stage of a listing represents what part of a listing lifecycle a callback is being initiated into.
		*/
	
	access(all)
	enum Stage: Int8{ 
		access(all)
		case Created // When a listing is made
		
		
		access(all)
		case Filled // When a listing is filled (purchased, loan funded, rental rented)
		
		
		access(all)
		case Completed // When a listing's life cycle completed (loan repaid, rental returned)
		
		
		access(all)
		case Destroyed // When a listing is destroyed (this should only apply if the listing was not filled previously)
	
	}
	
	/*
		So that we do not take in `AnyResource` as the input, a base resource interface type is defined
		that other listings can extend. In the future, this listing type will also need to resolve information about
		the listing such as what stage it's in, and details about the listing itself
		*/
	
	access(all)
	resource interface Listing{ 
		// There are no specific metadata views yet, and we cannot extend interfaces until
		// Crescendo goes live, so for now we are making an interface that fills the same need
		// as MetdataViews until we can extend them in the future.
		access(all)
		fun getViews(): [Type]{ 
			return []
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return nil
		}
	}
	
	/*
		The Handler is an interface with a single method that handles a listing each time the platform it origniated from
		determines the callback is necessary.
	
		**The handler resource is NOT in charge of the stage in a callback**
		*/
	
	access(all)
	resource interface Handler{ 
		access(all)
		fun handle(stage: Stage, listing: &{Listing}, nft: &{NonFungibleToken.NFT}?): Bool
		
		access(all)
		fun validateListing(listing: &{Listing}, nft: &{NonFungibleToken.NFT}?): Bool
	}
	
	/*
		Container is a general-purpose object that stores handlers.
		
		There are type-specific handler mappings which might be required to handle details about special types of
		nfts (like a Top Shot moment and whether it is locked). And there is a list of default handlers which will
		always run such as a handler to record and compare the DNA of an NFT to ensure what is being bought is what
		was listed (DNA is not changed).
	
	In the future, it may be possible for NFTs to define their own handlers, but this is not supported currently.
		*/
	
	access(all)
	resource Container{ 
		access(all)
		let nftTypeHandlers: @{Type:{ Handler}}
		
		access(all)
		var defaultHandlers: @[{Handler}]
		
		access(all)
		let data:{ String: AnyStruct}
		
		access(all)
		let resources: @{String: AnyResource}
		
		access(all)
		fun register(type: Type, handler: @{Handler}){ 
			pre{ 
				type.isSubtype(of: Type<@{NonFungibleToken.NFT}>()):
					"registered type must be an NFT"
			}
			destroy self.nftTypeHandlers.insert(key: type, <-handler)
		}
		
		access(all)
		fun handle(stage: Stage, listing: &{Listing}, nft: &{NonFungibleToken.NFT}?): Bool{ 
			let nftType = nft != nil ? (nft!).getType() : nft.getType()
			var res = true
			// TODO: a custom metadata view for anyone to define their own callback
			if let nftHandler = &self.nftTypeHandlers[nftType] as &{Handler}?{ 
				res = nftHandler.handle(stage: stage, listing: listing, nft: nft)
			}
			var index = 0
			while index < self.defaultHandlers.length{ 
				let ref = &self.defaultHandlers[index] as &{Handler}
				res = res && ref.handle(stage: stage, listing: listing, nft: nft)
				index = index + 1
			}
			return res
		}
		
		access(all)
		fun validateListing(
			listing: &{FlowtyListingCallback.Listing},
			nft: &{NonFungibleToken.NFT}?
		): Bool{ 
			let nftType = nft != nil ? (nft!).getType() : nft.getType()
			var res = true
			if let nftHandler = &self.nftTypeHandlers[nftType] as &{Handler}?{ 
				res = nftHandler.validateListing(listing: listing, nft: nft)
			}
			var index = 0
			while index < self.defaultHandlers.length{ 
				let ref = &self.defaultHandlers[index] as &{Handler}
				res = res && ref.validateListing(listing: listing, nft: nft)
				index = index + 1
			}
			return res
		}
		
		access(all)
		fun addDefaultHandler(h: @{Handler}){ 
			self.defaultHandlers.append(<-h)
		}
		
		access(all)
		fun removeDefaultHandlerAt(index: Int): @{Handler}?{ 
			if index >= self.defaultHandlers.length{ 
				return nil
			}
			return <-self.defaultHandlers.remove(at: index)
		}
		
		init(defaultHandler: @{Handler}){ 
			self.defaultHandlers <- [<-defaultHandler]
			self.nftTypeHandlers <-{} 
			self.data ={} 
			self.resources <-{} 
		}
	}
	
	access(all)
	fun createContainer(defaultHandler: @{Handler}): @Container{ 
		return <-create Container(defaultHandler: <-defaultHandler)
	}
	
	init(){ 
		self.ContainerStoragePath = StoragePath(
				identifier: "FlowtyListingCallback_".concat(
					FlowtyListingCallback.account.address.toString()
				)
			)!
	}
}
