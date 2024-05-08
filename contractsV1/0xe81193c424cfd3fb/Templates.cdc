// SPDX-License-Identifier: MIT
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// This contracts stores all the defined interfaces and structs.
// Interfaces can span on both Doodles and Wearables therefore it is better to have them in a central contract
access(all)
contract Templates{ 
	access(contract)
	let counters:{ String: UInt64}
	
	access(contract)
	let features:{ String: Bool}
	
	access(all)
	fun getCounter(_ name: String): UInt64{ 
		return Templates.counters[name] ?? 0
	}
	
	access(all)
	event CountersReset()
	
	access(account)
	fun createEditionInfoManually(name: String, counter: String, edition: UInt64?): EditionInfo{ 
		let oldMax = Templates.counters[counter] ?? 0
		if let e = edition{ 
			// If edition is passed in, check if the edition is larger than the existing max.
			// If so, set it as max, otherwise just mint with edition
			if e > oldMax{ 
				Templates.counters[counter] = e
			}
			return EditionInfo(counter: counter, name: name, number: e)
		}
		// If edition is NOT passed in, increment by 1 and set new max as edition
		let max = oldMax + 1
		Templates.counters[counter] = max
		return EditionInfo(counter: counter, name: name, number: max)
	}
	
	access(all)
	struct interface Editionable{ 
		access(all)
		view fun getCounterSuffix(): String
		
		// e.g. set , position
		access(all)
		view fun getClassifier(): String
		
		// e.g. character, wearable
		access(all)
		view fun getContract(): String
		
		access(all)
		fun getCounter(): String{ 
			return self.getContract().concat("_").concat(self.getClassifier()).concat("_").concat(
				self.getCounterSuffix()
			)
		}
		
		access(account)
		fun createEditionInfo(_ edition: UInt64?): EditionInfo{ 
			return Templates.createEditionInfoManually(
				name: self.getClassifier(),
				counter: self.getCounter(),
				edition: edition
			)
		}
		
		access(all)
		fun getCurrentCount(): UInt64{ 
			return Templates.counters[self.getCounter()] ?? 0
		}
	}
	
	access(all)
	struct interface Retirable{ 
		access(all)
		var active: Bool
		
		access(all)
		view fun getCounterSuffix(): String
		
		access(all)
		view fun getClassifier(): String
		
		access(all)
		view fun getContract(): String
		
		access(account)
		fun enable(_ bool: Bool){ 
			pre{ 
				self.active:
					self.getContract().concat("-").concat(self.getClassifier()).concat(" is already retired : ").concat(self.getCounterSuffix())
			}
			self.active = bool
		}
	}
	
	access(all)
	struct interface RoyaltyHolder{ 
		access(all)
		let royalties: [Templates.Royalty]
		
		access(all)
		fun getRoyalties(): [MetadataViews.Royalty]{ 
			let royalty: [MetadataViews.Royalty] = []
			for r in self.royalties{ 
				royalty.append(r.getRoyalty())
			}
			return royalty
		}
	}
	
	access(all)
	struct EditionInfo{ 
		access(all)
		let counter: String
		
		access(all)
		let name: String
		
		access(all)
		let number: UInt64
		
		init(counter: String, name: String, number: UInt64){ 
			self.counter = counter
			self.name = name
			self.number = number
		}
		
		access(all)
		fun getSupply(): UInt64{ 
			return Templates.counters[self.counter] ?? 0
		}
		
		access(all)
		fun getAsMetadataEdition(_ active: Bool): MetadataViews.Edition{ 
			var max: UInt64? = nil
			if !active{ 
				max = Templates.counters[self.counter]
			}
			return MetadataViews.Edition(name: self.name, number: self.number, max: max)
		}
		
		access(all)
		fun getMaxEdition(): UInt64{ 
			return Templates.counters[self.counter]!
		}
	}
	
	access(all)
	struct Royalty{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let cut: UFix64
		
		access(all)
		let description: String
		
		access(all)
		let publicPath: String
		
		init(name: String, address: Address, cut: UFix64, description: String, publicPath: String){ 
			self.name = name
			self.address = address
			self.cut = cut
			self.description = description
			self.publicPath = publicPath
		}
		
		access(all)
		fun getPublicPath(): PublicPath{ 
			return PublicPath(identifier: self.publicPath)!
		}
		
		access(all)
		fun getRoyalty(): MetadataViews.Royalty{ 
			let cap =
				getAccount(self.address).capabilities.get<&{FungibleToken.Receiver}>(
					self.getPublicPath()
				)
			return MetadataViews.Royalty(receiver: cap!, cut: self.cut, description: self.name)
		}
	}
	
	access(all)
	fun featureEnabled(_ action: String): Bool{ 
		return self.features[action] ?? false
	}
	
	access(all)
	fun assertFeatureEnabled(_ action: String){ 
		if !Templates.featureEnabled(action){ 
			panic("Action cannot be taken, feature is not enabled : ".concat(action))
		}
	}
	
	access(account)
	fun resetCounters(){ 
		// The counter is in let, therefore we have to do this.
		for key in self.counters.keys{ 
			self.counters.remove(key: key)
		}
		emit CountersReset()
	}
	
	access(account)
	fun setFeature(action: String, enabled: Bool){ 
		self.features[action] = enabled
	}
	
	init(){ 
		self.counters ={} 
		self.features ={} 
	}
}
