/*
  FlowInteractionTemplateAudit

  The FlowInteractionTemplateAudit contract manages the creation 
  of AuditManager resources. It also maintains some
  helpful utilities for querying from AuditManager 
  resouces.

  AuditManager resouces maintain the IDs of
  InteractionTemplate data structures that have been audited by the
  owner of the AuditManager. The owner of an
  AuditManager resource is consididered an 
  Interaction Template Auditor.

  See additional documentation: https://github.com/onflow/fcl-contracts
*/

access(all)
contract FlowInteractionTemplateAudit{ 
	/****** Audit Events ******/
	
	// The event that is emitted when an audit is added to an 
	// AuditManager.
	// 
	access(all)
	event AuditAdded(templateId: String, auditor: Address, auditManagerID: UInt64)
	
	// The event that is emitted when an audit is revoked from an 
	// AuditManager.
	// 
	access(all)
	event AuditRevoked(templateId: String, auditor: Address, auditManagerID: UInt64)
	
	// The event that is emitted when an AuditManager
	// is created.
	// 
	access(all)
	event AuditorCreated(auditManagerID: UInt64)
	
	/****** Storage Paths ******/
	access(all)
	let AuditManagerStoragePath: StoragePath
	
	access(all)
	let AuditManagerPublicPath: PublicPath
	
	access(all)
	let AuditManagerPrivatePath: PrivatePath
	
	// Public Interface for AuditManager.
	//
	// Maintains the publically accessible methods on an
	// AuditManager resource.
	//
	access(all)
	resource interface AuditManagerPublic{ 
		access(all)
		fun getAudits(): [String]
		
		access(all)
		fun getHasAuditedTemplate(templateId: String): Bool
	}
	
	// Private Interface for AuditManager.
	//
	// Maintains the private methods on an
	// AuditManager resource. These methods 
	// must be only accessible by the owner of the AuditManager
	//
	access(all)
	resource interface AuditManagerPrivate{ 
		access(all)
		fun addAudit(templateId: String)
		
		access(all)
		fun revokeAudit(templateId: String)
	}
	
	// The AuditManager resource.
	//
	// Maintains the IDs of the InteractionTemplate the owner of the 
	// AuditManager has audited.
	//
	access(all)
	resource AuditManager: AuditManagerPublic, AuditManagerPrivate{ 
		
		// Maintains the set of Interaction Template IDs that the owner of this 
		// Manager has audited.
		//
		// Represents a map from Interaction Template ID (String) => isAudited (Bool).
		// The value of each element of the map is Boolean 'true'.
		// This is a map as to allow for cheaper lookups, inserts and removals.
		//
		access(self)
		var audits:{ String: Bool}
		
		init(){ 
			// Initialize the set of audits maintained by this AuditManager resource
			self.audits ={} 
			emit AuditorCreated(auditManagerID: self.uuid)
		}
		
		// Returns the Interaction Template IDs that the owner of this 
		// AuditManager has audited.
		//
		// @return An array of Interaction Template IDs that the owner of this 
		// AuditManager has audited.
		//
		access(all)
		fun getAudits(): [String]{ 
			return self.audits.keys
		}
		
		// Returns whether the owner of the AuditManager has audited
		// a given Interaction Template by ID.
		//
		// @param templateId: ID of an Interaction Template
		//
		// @return Whether the AuditManager has templateId as one of the
		// Interaction Template IDs the owner of the AuditManager has audited.
		//
		access(all)
		fun getHasAuditedTemplate(templateId: String): Bool{ 
			return self.audits.containsKey(templateId)
		}
		
		// Adds an Interaction Template ID to the AuditManager
		// to denote that the Interaction Template it corresponds to has been audited by the
		// owner of the AuditManager.
		//
		// @param templateId: ID of an Interaction Template
		//
		access(all)
		fun addAudit(templateId: String){ 
			pre{ 
				!self.audits.containsKey(templateId):
					"Cannot audit template that is already audited"
			}
			self.audits.insert(key: templateId, true)
			emit AuditAdded(templateId: templateId, auditor: self.owner?.address!, auditManagerID: self.uuid)
		}
		
		// Revoke an Interaction Template ID from the AuditManager
		// to denote that the Interaction Template it corresponds to is no longer audited by the
		// owner of the AuditManager.
		//
		// @param templateId: ID of an Interaction Template
		//
		access(all)
		fun revokeAudit(templateId: String){ 
			pre{ 
				self.audits.containsKey(templateId):
					"Cannot revoke audit for a template that is not already audited"
			}
			self.audits.remove(key: templateId)
			emit AuditRevoked(templateId: templateId, auditor: self.owner?.address!, auditManagerID: self.uuid)
		}
	}
	
	// Utility method to create a AuditManager resource.
	//
	// @return An AuditManager resource
	//
	access(all)
	fun createAuditManager(): @AuditManager{ 
		return <-create AuditManager()
	}
	
	// Utility method to check which auditors have audited a given Interaction Template ID 
	//
	// @param templateId: ID of an Interaction Template
	// @param auditors: Array of addresses of auditors
	// 
	// @return A map of auditorAddress => isAuditedByAuditor
	//
	access(all)
	fun getHasTemplateBeenAuditedByAuditors(templateId: String, auditors: [Address]):{ 
		Address: Bool
	}{ 
		let audits:{ Address: Bool} ={} 
		for auditor in auditors{ 
			let auditManagerRef = getAccount(auditor).capabilities.get<&FlowInteractionTemplateAudit.AuditManager>(FlowInteractionTemplateAudit.AuditManagerPublicPath).borrow<&FlowInteractionTemplateAudit.AuditManager>() ?? panic("Could not borrow Audit Manager public reference")
			audits.insert(key: auditor, auditManagerRef.getHasAuditedTemplate(templateId: templateId))
		}
		return audits
	}
	
	// Utility method to get an array of Interaction Template IDs audited by an auditor. 
	//
	// @param auditor: Address of an auditor
	// 
	// @return An array of Interaction Template IDs
	//
	access(all)
	fun getAuditsByAuditor(auditor: Address): [String]{ 
		let auditManagerRef =
			getAccount(auditor).capabilities.get<&FlowInteractionTemplateAudit.AuditManager>(
				FlowInteractionTemplateAudit.AuditManagerPublicPath
			).borrow<&FlowInteractionTemplateAudit.AuditManager>()
			?? panic("Could not borrow Audit Manager public reference")
		return auditManagerRef.getAudits()
	}
	
	init(){ 
		self.AuditManagerStoragePath = /storage/FlowInteractionTemplateAuditManagerStoragePath
		self.AuditManagerPublicPath = /public/FlowInteractionTemplateAuditManagerPublicPath
		self.AuditManagerPrivatePath = /private/FlowInteractionTemplateAuditManagerPrivatePath
	}
}
