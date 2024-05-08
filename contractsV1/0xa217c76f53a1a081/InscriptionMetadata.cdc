import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract InscriptionMetadata{ 
	
	/// Provides access to a set of metadata views. A struct or 
	/// resource (e.g. an NFT) can implement this interface to provide access to 
	/// the views that it supports.
	///
	access(all)
	resource interface Resolver{ 
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	/// A group of view resolvers indexed by ID.
	///
	access(all)
	resource interface ResolverCollection{ 
		access(all)
		fun getIDs(): [UInt64]
	}
	
	/// Basic view that includes the name, description and thumbnail for an 
	/// object. Most objects should implement this view.
	/// InscriptionView is a group of views used to give a complete picture of an inscription
	///
	access(all)
	struct InscriptionView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let uuid: UInt64
		
		access(all)
		let inscription: String
		
		init(id: UInt64, uuid: UInt64, inscription: String){ 
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
	access(all)
	fun getInscriptionView(id: UInt64, viewResolver: &{Resolver}): InscriptionView{ 
		let inscriptionView = viewResolver.resolveView(Type<InscriptionView>())
		if inscriptionView != nil{ 
			return inscriptionView! as! InscriptionView
		}
		return InscriptionView(id: id, uuid: viewResolver.uuid, inscription: "")
	}
}
