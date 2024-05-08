import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

pub contract InscriptionMetadata {

    /// Provides access to a set of metadata views. A struct or 
    /// resource (e.g. an NFT) can implement this interface to provide access to 
    /// the views that it supports.
    ///
    pub resource interface Resolver {
        pub fun getViews(): [Type]
        pub fun resolveView(_ view: Type): AnyStruct?
    }

    /// A group of view resolvers indexed by ID.
    ///
    pub resource interface ResolverCollection {
        pub fun getIDs(): [UInt64]
    }

    /// Basic view that includes the name, description and thumbnail for an 
    /// object. Most objects should implement this view.
    /// InscriptionView is a group of views used to give a complete picture of an inscription
    ///
    pub struct InscriptionView {
        pub let id: UInt64
        pub let uuid: UInt64
        pub let inscription: String

        init(
            id : UInt64,
            uuid : UInt64,
            inscription : String,
        ) {
            self.id = id
            self.uuid = uuid
            self.inscription = inscription
        }
    }

    /// Helper to get an Inscription view 
    ///
    /// @param id: The inscription id
    /// @param viewResolver: A reference to the resolver resource
    /// @return A InscriptionView struct
    ///
    pub fun getInscriptionView(id: UInt64, viewResolver: &{Resolver}) : InscriptionView {
        let inscriptionView = viewResolver.resolveView(Type<InscriptionView>())
        if inscriptionView != nil {
            return inscriptionView! as! InscriptionView
        }

        return InscriptionView(
            id : id,
            uuid: viewResolver.uuid,
            inscription: "",
        )
    }

}
 