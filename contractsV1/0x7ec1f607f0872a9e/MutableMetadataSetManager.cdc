/*
MutableSetManager

MutableSet.Set (please see that contract for more details) provides a way to
create Sets of alike resources with some shared properties. This contract
provides management and access to a logical collection of these Sets. For
example, this contract would be best used to manage the metadata for an entire
NFT contract.

A SetManager should have a name and description and provides a way to add
additional Sets and access those Sets for mutation, if allowed by the Set.

*/

import MutableMetadataSet from "./MutableMetadataSet.cdc"

access(all)
contract MutableMetadataSetManager{ 
	
	// ==========================================================================
	// Manager
	// ==========================================================================
	access(all)
	resource interface Public{ 
		
		// Name of this manager
		access(all)
		fun name(): String
		
		// Description of this manager
		access(all)
		fun description(): String
		
		// Number of sets in this manager
		access(all)
		fun numSets(): Int
		
		// Get the public version of a particular set
		access(all)
		fun getSet(_ id: Int): &MutableMetadataSet.Set
	}
	
	access(all)
	resource interface Private{ 
		
		// Set the name of the manager
		access(all)
		fun setName(_ name: String)
		
		// Set the name of the description
		access(all)
		fun setDescription(_ description: String)
		
		// Get the private version of a particular set
		access(all)
		fun getSetMutable(_ id: Int): &MutableMetadataSet.Set
		
		// Add a mutable set to the set manager.
		access(all)
		fun addSet(_ set: @MutableMetadataSet.Set)
	}
	
	access(all)
	resource Manager: Public, Private{ 
		
		// ========================================================================
		// Attributes
		// ========================================================================
		
		// Name of this manager
		access(self)
		var _name: String
		
		// Description of this manager
		access(self)
		var _description: String
		
		// Sets owned by this manager
		access(self)
		var _mutableSets: @[MutableMetadataSet.Set]
		
		// ========================================================================
		// Public functions
		// ========================================================================
		access(all)
		fun name(): String{ 
			return self._name
		}
		
		access(all)
		fun description(): String{ 
			return self._description
		}
		
		access(all)
		fun numSets(): Int{ 
			return self._mutableSets.length
		}
		
		access(all)
		fun getSet(_ id: Int): &MutableMetadataSet.Set{ 
			pre{ 
				id >= 0 && id < self._mutableSets.length:
					id.toString().concat(" is not a valid set ID. Number of sets is ").concat(self._mutableSets.length.toString())
			}
			return &self._mutableSets[id] as &MutableMetadataSet.Set
		}
		
		// ========================================================================
		// Private functions
		// ========================================================================
		access(all)
		fun setName(_ name: String){ 
			self._name = name
		}
		
		access(all)
		fun setDescription(_ description: String){ 
			self._description = description
		}
		
		access(all)
		fun getSetMutable(_ id: Int): &MutableMetadataSet.Set{ 
			pre{ 
				id >= 0 && id < self._mutableSets.length:
					id.toString().concat(" is not a valid set ID. Number of sets is ").concat(self._mutableSets.length.toString())
			}
			return &self._mutableSets[id] as &MutableMetadataSet.Set
		}
		
		access(all)
		fun addSet(_ set: @MutableMetadataSet.Set){ 
			let id = self._mutableSets.length
			self._mutableSets.append(<-set)
			emit SetAdded(id: id)
		}
		
		// ========================================================================
		// init/destroy
		// ========================================================================
		init(name: String, description: String){ 
			self._name = name
			self._description = description
			self._mutableSets <- []
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	// Create a new SetManager resource with the given name and description
	access(all)
	fun _create(name: String, description: String): @Manager{ 
		return <-create Manager(name: name, description: description)
	}
	
	// ==========================================================================
	// Ignore
	// ==========================================================================
	// Not used - exists to conform to contract updatability requirements
	access(all)
	event SetAdded(id: Int)
}
