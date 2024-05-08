import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

// Common information for all copies of the same item
access(all)
contract Edition{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// The total amount of editions that have been created
	access(all)
	var totalEditions: UInt64
	
	// Struct to display and handle commissions
	access(all)
	struct CommissionStructure{ 
		access(all)
		let firstSalePercent: UFix64
		
		access(all)
		let secondSalePercent: UFix64
		
		access(all)
		let description: String
		
		init(firstSalePercent: UFix64, secondSalePercent: UFix64, description: String){ 
			self.firstSalePercent = firstSalePercent
			self.secondSalePercent = secondSalePercent
			self.description = description
		}
	}
	
	// Events  
	access(all)
	event CreateEdition(editionId: UInt64, maxEdition: UInt64)
	
	access(all)
	event ChangeCommision(editionId: UInt64)
	
	access(all)
	event ChangeMaxEdition(editionId: UInt64, maxEdition: UInt64)
	
	// Edition's status(commission and amount copies of the same item)
	access(all)
	struct EditionStatus{ 
		access(all)
		let royalty:{ Address: CommissionStructure}
		
		access(all)
		let editionId: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		init(royalty:{ Address: CommissionStructure}, editionId: UInt64, maxEdition: UInt64){ 
			self.royalty = royalty
			self.editionId = editionId
			// Amount copies of the same item
			self.maxEdition = maxEdition
		}
	}
	
	// Attributes one edition, where stores royalty and amount of copies
	access(all)
	resource EditionItem{ 
		access(all)
		let editionId: UInt64
		
		access(all)
		var royalty:{ Address: CommissionStructure}
		
		// Amount copies of the same item
		access(self)
		var maxEdition: UInt64
		
		init(royalty:{ Address: CommissionStructure}, maxEdition: UInt64){ 
			Edition.totalEditions = Edition.totalEditions + 1 as UInt64
			self.royalty = royalty
			self.editionId = Edition.totalEditions
			self.maxEdition = maxEdition
		}
		
		// Get status of edition		
		access(all)
		fun getEdition(): EditionStatus{ 
			return EditionStatus(
				royalty: self.royalty,
				editionId: self.editionId,
				maxEdition: self.maxEdition
			)
		}
		
		// Change commision
		access(all)
		fun changeCommission(royalty:{ Address: CommissionStructure}){ 
			self.royalty = royalty
			emit ChangeCommision(editionId: self.editionId)
		}
		
		// Change count of copies. This is used for Open Edition, because the eventual amount of copies are known only after finish of sale	   
		access(all)
		fun changeMaxEdition(maxEdition: UInt64){ 
			pre{ 
				// Possible change this number only once after Open Edition would be completed
				self.maxEdition < UInt64(1):
					"Forbid change max edition"
			}
			self.maxEdition = maxEdition
			emit ChangeMaxEdition(editionId: self.editionId, maxEdition: maxEdition)
		}
	}
	
	// EditionCollectionPublic is a resource interface that restricts users to
	// retreiving the edition's information
	access(all)
	resource interface EditionCollectionPublic{ 
		access(all)
		fun getEdition(_ id: UInt64): EditionStatus?
	}
	
	//EditionCollection contains a dictionary EditionItems and provides
	// methods for manipulating EditionItems
	access(all)
	resource EditionCollection: EditionCollectionPublic{ 
		
		// Edition Items
		access(account)
		var editionItems: @{UInt64: EditionItem}
		
		init(){ 
			self.editionItems <-{} 
		}
		
		// Validate royalty
		access(self)
		fun validateRoyalty(royalty:{ Address: CommissionStructure}){ 
			var firstSummaryPercent = 0.00
			var secondSummaryPercent = 0.00
			for key in royalty.keys{ 
				firstSummaryPercent = firstSummaryPercent + (royalty[key]!).firstSalePercent
				secondSummaryPercent = secondSummaryPercent + (royalty[key]!).secondSalePercent
				let account = getAccount(key)
				let vaultCap = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
				if !vaultCap.check(){ 
					let panicMessage = "Account ".concat(key.toString()).concat(" does not provide fusd vault capability")
					panic(panicMessage)
				}
			}
			if firstSummaryPercent != 100.00{ 
				panic("The first summary sale percent should be 100 %")
			}
			if secondSummaryPercent >= 100.00{ 
				panic("The second summary sale percent should be less than 100 %")
			}
		}
		
		// Create edition (common information for all copies of the same item)
		access(all)
		fun createEdition(royalty:{ Address: CommissionStructure}, maxEdition: UInt64): UInt64{ 
			self.validateRoyalty(royalty: royalty)
			let item <- create EditionItem(royalty: royalty, maxEdition: maxEdition)
			let id = item.editionId
			
			// update the auction items dictionary with the new resources
			let oldItem <- self.editionItems[id] <- item
			destroy oldItem
			emit CreateEdition(editionId: id, maxEdition: maxEdition)
			return id
		}
		
		access(all)
		fun getEdition(_ id: UInt64): EditionStatus?{ 
			if self.editionItems[id] == nil{ 
				return nil
			}
			
			// Get the edition item resources
			let itemRef = &self.editionItems[id] as &Edition.EditionItem?
			return itemRef.getEdition()
		}
		
		//Change commission
		access(all)
		fun changeCommission(id: UInt64, royalty:{ Address: CommissionStructure}){ 
			pre{ 
				self.editionItems[id] != nil:
					"Edition does not exist"
			}
			self.validateRoyalty(royalty: royalty)
			let itemRef = &self.editionItems[id] as &Edition.EditionItem?
			itemRef.changeCommission(royalty: royalty)
		}
		
		// Change count of copies. This is used for Open Edition, because the eventual amount of copies are unknown 
		access(all)
		fun changeMaxEdition(id: UInt64, maxEdition: UInt64){ 
			pre{ 
				self.editionItems[id] != nil:
					"Edition does not exist"
			}
			let itemRef = &self.editionItems[id] as &Edition.EditionItem?
			itemRef.changeMaxEdition(maxEdition: maxEdition)
		}
	}
	
	// createEditionCollection returns a new createEditionCollection resource to the caller
	access(self)
	fun createEditionCollection(): @EditionCollection{ 
		let editionCollection <- create EditionCollection()
		return <-editionCollection
	}
	
	init(){ 
		self.totalEditions = 0 as UInt64
		self.CollectionPublicPath = /public/bloctoXtinglesEdition
		self.CollectionStoragePath = /storage/bloctoXtinglesEdition
		let edition <- Edition.createEditionCollection()
		self.account.storage.save(<-edition, to: Edition.CollectionStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{Edition.EditionCollectionPublic}>(
				Edition.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: Edition.CollectionPublicPath)
	}
}
