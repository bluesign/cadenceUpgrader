/**
 * @title AFLBadges
 * @author Julian Rutherford aka j00lz
 * @notice This smart contract is used to manage AFL badges.
 * @dev This contract allows administrators to create, update, and delete badges and assign them to templates.
 */

access(all)
contract AFLBadges{ 
	
	/// @dev Every Template can have a list of badge ids associated with it
	access(contract)
	let badgeIdsByTemplateId:{ UInt64: [UInt64]}
	
	access(contract)
	let badges:{ UInt64: Badge}
	
	access(contract)
	var nextBadgeId: UInt64
	
	/// @dev AdminStoragePath is used to store the Admin resource in the contract account's storage
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event BadgeCreated(id: UInt64, name: String, description: String, imageUrl: String)
	
	access(all)
	event BadgeUpdated(id: UInt64, name: String, description: String, imageUrl: String)
	
	access(all)
	event BadgeRemoved(id: UInt64)
	
	access(all)
	event BadgeAssignedToTemplate(badgeId: UInt64, templateId: UInt64)
	
	access(all)
	event BadgeRemovedFromTemplate(badgeId: UInt64, templateId: UInt64)
	
	/**
		 * @title Badge
		 * @notice This struct represents a badge, containing its ID, name, description, and image URL.
		 **/
	
	access(all)
	struct Badge{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let imageUrl: String
		
		init(id: UInt64, name: String, description: String, imageUrl: String){ 
			self.id = id
			self.name = name
			self.description = description
			self.imageUrl = imageUrl
		}
	}
	
	// Public Read access functions
	/// @notice Returns a badge with the given ID, or nil if not found.
	access(all)
	fun getBadge(id: UInt64): Badge?{ 
		return self.badges[id]
	}
	
	/// @notice Returns an array containing all badges.
	access(all)
	fun getBadges(): [Badge]{ 
		return self.badges.values
	}
	
	/**
		 * @notice Returns an array of badges associated with the given template ID.
		 * @param id The ID of the template.
		 * @return An array of badges associated with the template ID.
		 **/
	
	access(all)
	fun getBadgesForTemplate(id: UInt64): [Badge]{ 
		let badgeIds = self.badgeIdsByTemplateId[id]
		if badgeIds == nil{ 
			return []
		}
		var badges: [Badge] = []
		for badgeId in badgeIds!{ 
			let badge = self.badges[badgeId]!
			badges.append(badge)
		}
		return badges
	}
	
	/**
		 * @notice Returns an array of badges associated with the given array of template IDs.
		 * @param templateIds An array of template IDs.
		 * @return A dictionary with keys of template IDs and corresponding arrays of badges.
		 **/
	
	access(all)
	fun getBadgesForTemplates(ids: [UInt64]):{ UInt64: [Badge]}{ 
		var badgesByTemplateId:{ UInt64: [Badge]} ={} 
		for id in ids{ 
			badgesByTemplateId[id] = self.getBadgesForTemplate(id: id)
		}
		return badgesByTemplateId
	}
	
	/**
		 * @notice Returns an array of template IDs associated with the given badge ID.
		 * @param id The ID of the badge.
		 * @return An array of template IDs associated with the badge ID.
		 */
	
	access(all)
	fun getTemplatesForBadge(id: UInt64): [UInt64]{ 
		let templateIds: [UInt64] = []
		for templateId in self.badgeIdsByTemplateId.keys{ 
			let badgeIds = self.badgeIdsByTemplateId[templateId]!
			let index = badgeIds.firstIndex(of: id)
			if index != nil{ 
				templateIds.append(templateId)
			}
		}
		return templateIds
	}
	
	/**
		 * @title Admin Resource
		 * @notice This resource grants admin access to create, update, delete badges and assign them to templates.
		 * @dev This resource should be stored in the contract account's storage using the AdminStoragePath.
		 **/
	
	access(all)
	resource Admin{ 
		/* 
				 * @notice Creates a new badge with the given name, description, and image URL, and assigns a unique ID to it.
				 * @param name The name of the badge.
				 * @param description The description of the badge.
				 * @param imageUrl The image URL of the badge.
				 **/
		
		access(all)
		fun createBadge(name: String, description: String, imageUrl: String): UInt64{ 
			let badge =
				Badge(
					id: AFLBadges.nextBadgeId,
					name: name,
					description: description,
					imageUrl: imageUrl
				)
			AFLBadges.badges[AFLBadges.nextBadgeId] = badge
			AFLBadges.nextBadgeId = AFLBadges.nextBadgeId + 1
			emit BadgeCreated(
				id: badge.id,
				name: badge.name,
				description: badge.description,
				imageUrl: badge.imageUrl
			)
			return AFLBadges.nextBadgeId
		}
		
		/**
				* @notice Updates the badge with the given ID, name, description, and image URL.
				* @param id The ID of the badge to update.
				* @param name The new name of the badge.
				* @param description The new description of the badge.
				* @param imageUrl The new image URL of the badge.
				**/
		
		access(all)
		fun updateBadge(id: UInt64, name: String, description: String, imageUrl: String){ 
			let badge = Badge(id: id, name: name, description: description, imageUrl: imageUrl)
			AFLBadges.badges[id] = badge
			emit BadgeUpdated(
				id: badge.id,
				name: badge.name,
				description: badge.description,
				imageUrl: badge.imageUrl
			)
		}
		
		/**
				* @notice Removes a badge with the given badge ID.
				* @dev This function also removes the badge from all associated templates.
				* @param badgeId The ID of the badge to remove.
				**/
		
		access(all)
		fun removeBadge(id: UInt64){ 
			// remove badge from all templates
			for templateId in AFLBadges.badgeIdsByTemplateId.keys{ 
				let badgeIds = AFLBadges.badgeIdsByTemplateId[templateId]!
				let index = badgeIds.firstIndex(of: id)
				if index != nil{ 
					badgeIds.remove(at: index!)
				}
			}
			AFLBadges.badges[id] = nil
			emit BadgeRemoved(id: id)
		}
		
		/**
				* @notice Adds a badge with the given badge ID to the specified template ID.
				* @param badgeId The ID of the badge to add.
				* @param templateId The ID of the template to add the badge to.
				**/
		
		access(all)
		fun addBadgeToTemplate(badgeId: UInt64, templateId: UInt64){ 
			pre{ 
				AFLBadges.badges[badgeId] != nil:
					"No badge for badge id: ".concat(badgeId.toString())
			}
			if AFLBadges.badgeIdsByTemplateId[templateId] == nil{ 
				AFLBadges.badgeIdsByTemplateId[templateId] = []
			}
			(AFLBadges.badgeIdsByTemplateId[templateId]!).append(badgeId)
			emit BadgeAssignedToTemplate(badgeId: badgeId, templateId: templateId)
		}
		
		/**
				* @notice Adds a badge with the given badge ID to each of the specified template IDs.
				* @param badgeId The ID of the badge to add.
				* @param templateIds The IDs of the templates to add the badge to.
				**/
		
		access(all)
		fun addBadgeToTemplates(badgeId: UInt64, templateIds: [UInt64]){ 
			for id in templateIds{ 
				self.addBadgeToTemplate(badgeId: badgeId, templateId: id)
			}
		}
		
		/**
				* @notice Removes a badge with the given badge ID from the specified template ID.
				* @param badgeId The ID of the badge to remove.
				* @param templateId The ID of the template to remove the badge from.
				**/
		
		access(all)
		fun removeBadgeFromTemplate(badgeId: UInt64, templateId: UInt64){ 
			pre{ 
				AFLBadges.badges[badgeId] != nil:
					"No badge for badge id"
				AFLBadges.badgeIdsByTemplateId[templateId] != nil:
					"No badges for template id"
				(AFLBadges.badgeIdsByTemplateId[templateId]!).contains(badgeId):
					"Badge does not exist for template id"
			}
			(AFLBadges.badgeIdsByTemplateId[templateId]!).remove(
				at: (AFLBadges.badgeIdsByTemplateId[templateId]!).firstIndex(of: badgeId)!
			)
			emit BadgeRemovedFromTemplate(badgeId: badgeId, templateId: templateId)
		}
		
		/**
				* @notice Removes a badge with the given badge ID from the specified template IDs.
				* @param badgeId The ID of the badge to remove.
				* @param templateId The ID of the template to remove the badge from.
				**/
		
		access(all)
		fun removeBadgeFromTemplates(badgeId: UInt64, templateIds: [UInt64]){ 
			for id in templateIds{ 
				self.removeBadgeFromTemplate(badgeId: badgeId, templateId: id)
			}
		}
	}
	
	/**
		* @notice Initializes the contract, setting up the initial state.
		* @dev This function sets up the contract storage and creates an Admin resource which is saved to the contract account's storage.
		**/
	
	init(){ 
		self.badgeIdsByTemplateId ={} 
		self.badges ={} 
		self.nextBadgeId = 0
		self.AdminStoragePath = /storage/AFLBadgesAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
