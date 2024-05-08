//SPDX-License-Identifier: UNLICENSED

// The Creator Registry stores the mappings from the name of an
// creator to the vaults in which they'd like to receive tokens,
// as well as the cut they'd like to take from marketplace transactions.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import DropchaseCoin from "./DropchaseCoin.cdc"

access(all)
contract DropchaseCreatorRegistry{ 
	
	// Emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Emitted when a FT-receiving capability for an creator has been updated
	// If address is nil, that means the capability has been removed.
	access(all)
	event CapabilityUpdated(name: String, ftType: Type, address: Address?)
	
	// Emitted when an creator's cut percentage has been updated
	// If the cutPercentage is nil, that means it has been removed.
	access(all)
	event CutPercentageUpdated(name: String, cutPercentage: UFix64?)
	
	// Emitted when an creator's cut percentage has been updated
	// If the cutPercentage is nil, that means it has been removed.
	access(all)
	event CutPackPercentageUpdated(name: String, cutPackPercentage: UFix64?)
	
	// Emitted when the default cut percentage has been updated
	access(all)
	event DefaultCutPercentageUpdated(cutPercentage: UFix64?)
	
	// Emitted when the default cut percentage has been updated
	access(all)
	event DefaultCutPackPercentageUpdated(cutPackPercentage: UFix64?)
	
	// capabilities is a mapping from creator name, to fungible token ID, to
	// the capability for a receiver for the fungible token
	access(self)
	var capabilities:{ String:{ String: Capability<&{FungibleToken.Receiver}>}}
	
	// The mappings from the name of an creator to the cut percentage
	// that they are supposed to receive.
	access(self)
	var cutPercentages:{ String: UFix64}
	
	// The mappings from the name of an creator to the cut percentage
	// that they are supposed to receive.
	access(self)
	var cutPackPercentages:{ String: UFix64}
	
	// The default cut percentage
	access(all)
	var defaultCutPercentage: UFix64
	
	// The default cut percentage
	access(all)
	var defaultCutPackPercentage: UFix64
	
	// Get the capability for depositing accounting tokens to the influencer
	access(all)
	fun getCapability(name: String): Capability?{ 
		let ftId = Type<@DropchaseCoin.Vault>().identifier
		if let caps = self.capabilities[name]{ 
			return caps[ftId]
		} else{ 
			return nil
		}
	}
	
	// Get the current cut percentage for the creator
	access(all)
	fun getCutPercentage(name: String): UFix64{ 
		if let cut = DropchaseCreatorRegistry.cutPercentages[name]{ 
			return cut
		} else{ 
			return DropchaseCreatorRegistry.defaultCutPercentage
		}
	}
	
	// Get the current pack cut percentage for the creator
	access(all)
	fun getPackCutPercentage(name: String): UFix64{ 
		if let cut = DropchaseCreatorRegistry.cutPackPercentages[name]{ 
			return cut
		} else{ 
			return DropchaseCreatorRegistry.defaultCutPackPercentage
		}
	}
	
	// Admin is an authorization resource that allows the contract owner to 
	// update values in the registry.
	access(all)
	resource Admin{ 
		
		// Update the FT-receiving capability for an creator
		access(all)
		fun setCapability(
			name: String,
			ftType: Type,
			capability: Capability<&{FungibleToken.Receiver}>?
		){ 
			let ftId = ftType.identifier
			if let cap = capability{ 
				if let caps = DropchaseCreatorRegistry.capabilities[name]{ 
					caps[ftId] = cap
					DropchaseCreatorRegistry.capabilities[name] = caps
				} else{ 
					DropchaseCreatorRegistry.capabilities[name] ={ ftId: cap}
				}
				// This is the only way to get the address behind a capability from Cadence right
				// now.  It will panic if the capability is not pointing to anything, but in that
				// case we should in fact panic anyways.
				let addr = ((cap.borrow() ?? panic("Capability is empty")).owner ?? panic("Capability owner is empty")).address
				emit CapabilityUpdated(name: name, ftType: ftType, address: addr)
			} else{ 
				if let caps = DropchaseCreatorRegistry.capabilities[name]{ 
					caps.remove(key: ftId)
					DropchaseCreatorRegistry.capabilities[name] = caps
				}
				emit CapabilityUpdated(name: name, ftType: ftType, address: nil)
			}
		}
		
		// Update the cut percentage for the creator
		access(all)
		fun setCutPercentage(name: String, cutPercentage: UFix64?){ 
			DropchaseCreatorRegistry.cutPercentages[name] = cutPercentage
			emit CutPercentageUpdated(name: name, cutPercentage: cutPercentage)
		}
		
		// Update the pack cut percentage for the creator
		access(all)
		fun setCutPackPercentage(name: String, cutPackPercentage: UFix64?){ 
			DropchaseCreatorRegistry.cutPackPercentages[name] = cutPackPercentage
			emit CutPackPercentageUpdated(name: name, cutPackPercentage: cutPackPercentage)
		}
		
		// Update the default cut percentage
		access(all)
		fun setDefaultCutPercentage(cutPercentage: UFix64){ 
			DropchaseCreatorRegistry.defaultCutPercentage = cutPercentage
			emit DefaultCutPercentageUpdated(cutPercentage: cutPercentage)
		}
		
		// Update the default cut percentage
		access(all)
		fun setDefaultPackCutPercentage(cutPackPercentage: UFix64){ 
			DropchaseCreatorRegistry.defaultCutPackPercentage = cutPackPercentage
			emit DefaultCutPackPercentageUpdated(cutPackPercentage: cutPackPercentage)
		}
	}
	
	init(){ 
		self.cutPercentages ={} 
		self.cutPackPercentages ={} 
		self.capabilities ={} 
		self.defaultCutPercentage = 0.05
		self.defaultCutPackPercentage = 0.20
		self.account.storage.save<@Admin>(
			<-create Admin(),
			to: /storage/DropchaseCreatorRegistryAdmin
		)
	}
}
