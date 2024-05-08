/*
MutableSet

We want to be able to associate metadata with a group of related resources.
Those resources themselves may have their own metadata represented by
MutableMetadataTemplate.Template (please see that contract for more details).
However, imagine a use case like an NFT brand manager wanting to release a
season of NFTs. The attributes of the 'season' would apply to all of the NFTs.

MutableSet.Set allows for multiple Templates to be associated with a single
Set-wide MutableMetadata.Metadata.

A Set owner can also signal to observers that no more resources will be added
to a particular logical Set of NFTs by locking the Set.

*/

import MutableMetadata from "./MutableMetadata.cdc"

import MutableMetadataTemplate from "./MutableMetadataTemplate.cdc"

access(all)
contract MutableMetadataSet{ 
	
	// ===========================================================================
	// Set
	// ===========================================================================
	access(all)
	resource interface Public{ 
		
		// Is this set locked from more Templates being added?
		access(all)
		fun locked(): Bool
		
		// Number of Templates in this set
		access(all)
		fun numTemplates(): Int
		
		// Public version of underyling MutableMetadata.Metadata
		access(all)
		fun metadata(): &MutableMetadata.Metadata
		
		// Retrieve the public version of a particular template given by the
		// Template ID (index into the self._templates array) only if it exists
		access(all)
		fun getTemplate(_ id: Int): &MutableMetadataTemplate.Template
	}
	
	access(all)
	resource interface Private{ 
		
		// Lock this set so more Templates may not be added to it.
		access(all)
		fun lock()
		
		// Private version of underyling MutableMetadata.Metadata
		access(all)
		fun metadataMutable(): &MutableMetadata.Metadata
		
		// Retrieve the private version of a particular template given by the
		// Template ID (index into the self._templates array) only if it exists
		access(all)
		fun getTemplateMutable(_ id: Int): &MutableMetadataTemplate.Template
		
		// Add a Template to this set if not locked
		access(all)
		fun addTemplate(_ template: @MutableMetadataTemplate.Template)
	}
	
	access(all)
	resource Set: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Is this set locked from more Templates being added?
		access(self)
		var _locked: Bool
		
		// Public version of underyling MutableMetadata.Metadata
		access(self)
		var _metadata: @MutableMetadata.Metadata
		
		// Templates in this set
		access(self)
		var _templates: @[MutableMetadataTemplate.Template]
		
		// ========================================================================
		// Public
		// ========================================================================
		access(all)
		fun locked(): Bool{ 
			return self._locked
		}
		
		access(all)
		fun numTemplates(): Int{ 
			return self._templates.length
		}
		
		access(all)
		fun metadata(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(all)
		fun getTemplate(_ id: Int): &MutableMetadataTemplate.Template{ 
			pre{ 
				id >= 0 && id < self._templates.length:
					id.toString().concat(" is not a valid template ID. Number of templates is ").concat(self._templates.length.toString())
			}
			return &self._templates[id] as &MutableMetadataTemplate.Template
		}
		
		// ========================================================================
		// Private
		// ========================================================================
		access(all)
		fun lock(){ 
			self._locked = true
		}
		
		access(all)
		fun metadataMutable(): &MutableMetadata.Metadata{ 
			return &self._metadata as &MutableMetadata.Metadata
		}
		
		access(all)
		fun getTemplateMutable(_ id: Int): &MutableMetadataTemplate.Template{ 
			pre{ 
				id >= 0 && id < self._templates.length:
					id.toString().concat(" is not a valid template ID. Number of templates is ").concat(self._templates.length.toString())
			}
			return &self._templates[id] as &MutableMetadataTemplate.Template
		}
		
		access(all)
		fun addTemplate(_ template: @MutableMetadataTemplate.Template){ 
			pre{ 
				!self._locked:
					"Cannot add template. Set is locked"
			}
			let id = self._templates.length
			self._templates.append(<-template)
			emit TemplateAdded(id: id)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(metadata: @MutableMetadata.Metadata){ 
			self._locked = false
			self._metadata <- metadata
			self._templates <- []
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new Set resource with the given Metadata
	access(all)
	fun _create(metadata: @MutableMetadata.Metadata): @Set{ 
		return <-create Set(metadata: <-metadata)
	}
	
	// ==========================================================================
	// Ignore
	// ==========================================================================
	// Not used - exists to conform to contract updatability requirements
	access(all)
	event TemplateAdded(id: Int)
}
