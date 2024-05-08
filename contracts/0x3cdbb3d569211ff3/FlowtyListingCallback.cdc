import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import FlowtyViews from "./FlowtyViews.cdc"

/*
FlowtyListingCallback

A contract to allow the injection of custom logic for the various
lifecycle events of a listing. For now, these callbacks are limited purely to
those created by the caller of the listing. In the future, it may be the case that
an nft itself could define its own callback.
*/
pub contract FlowtyListingCallback {
    pub let ContainerStoragePath: StoragePath

    /*
    The stage of a listing represents what part of a listing lifecycle a callback is being initiated into.
    */
    pub enum Stage: Int8 {
        pub case Created // When a listing is made
        pub case Filled // When a listing is filled (purchased, loan funded, rental rented)
        pub case Completed // When a listing's life cycle completed (loan repaid, rental returned)
        pub case Destroyed // When a listing is destroyed (this should only apply if the listing was not filled previously)
    }

    /*
    So that we do not take in `AnyResource` as the input, a base resource interface type is defined
    that other listings can extend. In the future, this listing type will also need to resolve information about
    the listing such as what stage it's in, and details about the listing itself
    */
    pub resource interface Listing {
        // There are no specific metadata views yet, and we cannot extend interfaces until
        // Crescendo goes live, so for now we are making an interface that fills the same need
        // as MetdataViews until we can extend them in the future.
        pub fun getViews(): [Type] {
            return []
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }

    /*
    The Handler is an interface with a single method that handles a listing each time the platform it origniated from
    determines the callback is necessary.

    **The handler resource is NOT in charge of the stage in a callback**
    */
    pub resource interface Handler {
        pub fun handle(stage: Stage, listing: &{Listing}, nft: &NonFungibleToken.NFT?): Bool
        pub fun validateListing(listing: &{Listing}, nft: &NonFungibleToken.NFT?): Bool
    }

    /*
    Container is a general-purpose object that stores handlers.
    
    There are type-specific handler mappings which might be required to handle details about special types of
    nfts (like a Top Shot moment and whether it is locked). And there is a list of default handlers which will
    always run such as a handler to record and compare the DNA of an NFT to ensure what is being bought is what
    was listed (DNA is not changed).

In the future, it may be possible for NFTs to define their own handlers, but this is not supported currently.
    */
    pub resource Container {
        pub let nftTypeHandlers: @{Type: {Handler}}
        pub var defaultHandlers: @[{Handler}]

        pub let data: {String: AnyStruct}
        pub let resources: @{String: AnyResource}

        pub fun register(type: Type, handler: @{Handler}) {
            pre {
                type.isSubtype(of: Type<@NonFungibleToken.NFT>()): "registered type must be an NFT"
            }

            destroy self.nftTypeHandlers.insert(key: type, <- handler)
        }

        pub fun handle(stage: Stage, listing: &{Listing}, nft: &NonFungibleToken.NFT?): Bool {
            let nftType = nft != nil ? nft!.getType() : nft.getType()

            var res = true
            // TODO: a custom metadata view for anyone to define their own callback
            if let nftHandler = &self.nftTypeHandlers[nftType] as &{Handler}? {
                res = nftHandler.handle(stage: stage, listing: listing, nft: nft)
            }

            var index = 0
            while index < self.defaultHandlers.length {
                let ref = &self.defaultHandlers[index] as &{Handler}
                res = res && ref.handle(stage: stage, listing: listing, nft: nft)
                index = index + 1
            }

            return res
        }

        pub fun validateListing(listing: &{FlowtyListingCallback.Listing}, nft: &NonFungibleToken.NFT?): Bool {
            let nftType = nft != nil ? nft!.getType() : nft.getType()

            var res = true
            if let nftHandler = &self.nftTypeHandlers[nftType] as &{Handler}? {
                res = nftHandler.validateListing(listing: listing, nft: nft)
            }

            var index = 0
            while index < self.defaultHandlers.length {
                let ref = &self.defaultHandlers[index] as &{Handler}
                res = res && ref.validateListing(listing: listing, nft: nft)
                index = index + 1
            }

            return res
        }

        pub fun addDefaultHandler(h: @{Handler}) {
            self.defaultHandlers.append(<-h)
        }

        pub fun removeDefaultHandlerAt(index: Int): @{Handler}? {
            if index >= self.defaultHandlers.length {
                return nil
            }

            return <- self.defaultHandlers.remove(at: index)
        }

        init(defaultHandler: @{Handler}) {
            self.defaultHandlers <- [ <-defaultHandler]
            self.nftTypeHandlers <- {}

            self.data = {}
            self.resources <- {}
        }

        destroy () {
            destroy self.nftTypeHandlers
            destroy self.defaultHandlers
            destroy self.resources
        }
    }

    pub fun createContainer(defaultHandler: @{Handler}): @Container {
        return <- create Container(defaultHandler: <- defaultHandler)
    }

    init() {
        self.ContainerStoragePath = StoragePath(identifier: "FlowtyListingCallback_".concat(FlowtyListingCallback.account.address.toString()))!
    }
}