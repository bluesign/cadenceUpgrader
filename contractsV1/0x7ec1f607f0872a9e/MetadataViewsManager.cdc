/*
MetadataViewsManager

MetadataViews (please see that contract for more details) provides metadata
standards for NFTs to implement so 3rd-party applications need not rely on the
specific implementation of a given NFT.

This contract provides a way to augment an NFT contract with a customizable
MetadataViews interface so that admins of this manager may add or remove NFT
Resolvers. These Resolvers take an AnyStruct (likely to be an interface of the
NFT itself) and map that AnyStruct to one of the MetadataViews Standards.

For example, one may make a Display resolver and assume that the "AnyStruct"
object can be downcasted into an interface that can resolve the name,
description, and url of that NFT. For instance, the Resolver can assume the
NFT's underlying metadata is a {String: String} dictionary and the Display name
is the same as nftmetadata['name'].

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract MetadataViewsManager{ 
	
	// ===========================================================================
	// Resolver
	// ===========================================================================
	
	// A Resolver effectively converts one struct into another. Under normal
	// conditions, the input should be an NFT and the output should be a
	// standard MetadataViews interface.
	access(all)
	struct interface Resolver{ 
		
		// The type of the particular MetadataViews struct this Resolver creates
		access(all)
		let type: Type
		
		// The actual resolve function
		access(all)
		fun resolve(_ nftRef: AnyStruct): AnyStruct?
	}
	
	// ===========================================================================
	// Manager
	// ===========================================================================
	access(all)
	resource interface Public{ 
		
		// Is manager locked?
		access(all)
		fun locked(): Bool
		
		// Get all views supported by the manager
		access(all)
		fun getViews(): [Type]
		
		// Resolve a particular view of a provided reference struct (i.e. NFT)
		access(all)
		fun resolveView(view: Type, nftRef: AnyStruct): AnyStruct?
		
		// Inspect a raw resolver
		access(all)
		fun inspectView(view: Type):{ Resolver}?
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock this manager so that resolvers can be neither added nor removed
		access(all)
		fun lock()
		
		// Add the given resolver if the manager is not locked
		access(all)
		fun addResolver(_ resolver:{ Resolver})
		
		// Remove the resolver of the provided type
		access(all)
		fun removeResolver(_ type: Type)
	}
	
	access(all)
	resource Manager: Private, Public{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this manager locked?
		access(self)
		var _locked: Bool
		
		// Resolvers this manager has available
		access(self)
		let _resolvers:{ Type:{ Resolver}}
		
		// ========================================================================
		// Public
		// ========================================================================
		access(all)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(all)
		fun getViews(): [Type]{ 
			return self._resolvers.keys
		}
		
		access(all)
		fun resolveView(view: Type, nftRef: AnyStruct): AnyStruct?{ 
			let resolverRef = &self._resolvers[view] as &{Resolver}?
			if resolverRef == nil{ 
				return nil
			}
			return (resolverRef!).resolve(nftRef)
		}
		
		access(all)
		fun inspectView(view: Type):{ Resolver}?{ 
			return self._resolvers[view]
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(all)
		fun lock(){ 
			self._locked = true
		}
		
		access(all)
		fun addResolver(_ resolver:{ Resolver}){ 
			pre{ 
				!self._locked:
					"Manager is locked."
			}
			self._resolvers[resolver.type] = resolver
		}
		
		access(all)
		fun removeResolver(_ type: Type){ 
			pre{ 
				!self._locked:
					"Manager is locked."
			}
			self._resolvers.remove(key: type)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(){ 
			self._resolvers ={} 
			self._locked = false
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Manager
	access(all)
	fun _create(): @Manager{ 
		return <-create Manager()
	}
}
