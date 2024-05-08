import BasicBeasts from "./BasicBeasts.cdc"

access(all)
contract HunterScore{ 
	
	// -----------------------------------------------------------------------
	// BasicBeasts Events
	// -----------------------------------------------------------------------
	access(all)
	event HunterScoreIncreased(wallet: Address, points: UInt32)
	
	access(all)
	event HunterScorePointsDeducted(wallet: Address, points: UInt32)
	
	access(all)
	event Banned(wallet: Address)
	
	access(all)
	event Unbanned(wallet: Address)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// HunterScore Fields
	// -----------------------------------------------------------------------
	access(self)
	var hunterScores:{ Address: UInt32}
	
	access(self)
	var beastsCollected:{ Address: [UInt64]}
	
	access(self)
	var beastTemplatesCollected:{ Address: [UInt32]}
	
	access(self)
	var banned: [Address]
	
	// String: skin + " " + starLevel.toString()
	// e.g. "Normal 1"
	// UInt32: pointReward
	//
	access(self)
	var pointTable:{ String: UInt32}
	
	// -----------------------------------------------------------------------
	// Admin Resource Functions
	//
	// Admin is a special authorization resource that 
	// allows the owner to perform important contract functions
	// -----------------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		fun deductPoints(wallet: Address, pointsToDeduct: UInt32){ 
			pre{ 
				HunterScore.hunterScores[wallet] != nil:
					"Can't deduct points: Address has no hunter score."
			}
			if pointsToDeduct > HunterScore.hunterScores[wallet]!{ 
				HunterScore.hunterScores.insert(key: wallet, 0)
			} else{ 
				HunterScore.hunterScores.insert(key: wallet, HunterScore.hunterScores[wallet]! - pointsToDeduct)
			}
			emit HunterScorePointsDeducted(wallet: wallet, points: pointsToDeduct)
		}
		
		access(all)
		fun banAddress(wallet: Address){ 
			pre{ 
				!HunterScore.banned.contains(wallet):
					"Can't ban wallet: Address is already banned."
			}
			HunterScore.banned.append(wallet)
			emit Banned(wallet: wallet)
		}
		
		access(all)
		fun unbanAddress(wallet: Address){ 
			pre{ 
				HunterScore.banned.contains(wallet):
					"Can't unban wallet: Address is not banned."
			}
			var i = 0
			while i < HunterScore.banned.length{ 
				if HunterScore.banned[i] == wallet{ 
					HunterScore.banned.remove(at: i)
				} else{ 
					i = i + 1
				}
			}
			emit Unbanned(wallet: wallet)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(account)
	fun increaseHunterScore(
		wallet: Address,
		beasts: @BasicBeasts.Collection
	): @BasicBeasts.Collection{ 
		if !self.banned.contains(wallet){ 
			
			// Initialize arrays if the wallet is not already in the dictionaries
			if HunterScore.beastsCollected[wallet] == nil{ 
				HunterScore.beastsCollected[wallet] = []
			}
			if HunterScore.beastTemplatesCollected[wallet] == nil{ 
				HunterScore.beastTemplatesCollected[wallet] = []
			}
			
			// Calculate points
			var points: UInt32 = 0
			for id in beasts.getIDs(){ 
				
				// Check if beast NFT has been collected before
				if !(HunterScore.beastsCollected[wallet]!).contains(id){ 
					(					 
					 // Add ID into beastsCollected
					 HunterScore.beastsCollected[wallet]!).append(id)
					
					// Add points depending on skin and star level
					var beast = beasts.borrowBeast(id: id)!
					var skinAndStarLevel = beast.getBeastTemplate().skin.concat(" ").concat(beast.getBeastTemplate().starLevel.toString())
					
					// Add points
					if HunterScore.pointTable[skinAndStarLevel] != nil{ 
						points = points + HunterScore.pointTable[skinAndStarLevel]!
					}
					if !(HunterScore.beastTemplatesCollected[wallet]!).contains(beast.getBeastTemplate().beastTemplateID){ 
						(						 // Add beastTemplateID if beastTemplate has been newly collected by the wallet
						 HunterScore.beastTemplatesCollected[wallet]!).append(beast.getBeastTemplate().beastTemplateID)
					}
				}
			}
			
			// Increase the Hunter Score
			if HunterScore.hunterScores[wallet] != nil{ 
				HunterScore.hunterScores[wallet] = HunterScore.hunterScores[wallet]! + points
			} else{ 
				HunterScore.hunterScores[wallet] = points
			}
			emit HunterScoreIncreased(wallet: wallet, points: points)
		}
		return <-beasts
	}
	
	access(all)
	fun getHunterScores():{ Address: UInt32}{ 
		return self.hunterScores
	}
	
	access(all)
	fun getHunterScore(wallet: Address): UInt32?{ 
		return self.hunterScores[wallet]
	}
	
	access(all)
	fun getAllBeastsCollected():{ Address: [UInt64]}{ 
		return self.beastsCollected
	}
	
	access(all)
	fun getBeastsCollected(wallet: Address): [UInt64]?{ 
		return self.beastsCollected[wallet]
	}
	
	access(all)
	fun getAllBeastTemplatesCollected():{ Address: [UInt32]}{ 
		return self.beastTemplatesCollected
	}
	
	access(all)
	fun getBeastTemplatesCollected(wallet: Address): [UInt32]?{ 
		return self.beastTemplatesCollected[wallet]
	}
	
	access(all)
	fun getPointTable():{ String: UInt32}{ 
		return self.pointTable
	}
	
	access(all)
	fun getPointReward(skinAndStarLevel: String): UInt32?{ 
		return self.pointTable[skinAndStarLevel]
	}
	
	access(all)
	fun getAllBanned(): [Address]{ 
		return self.banned
	}
	
	access(all)
	fun isAddressBanned(wallet: Address): Bool{ 
		return self.banned.contains(wallet)
	}
	
	init(){ 
		// Set named paths
		self.AdminStoragePath = /storage/HunterScoreAdmin
		self.AdminPrivatePath = /private/HunterScoreAdminUpgrade
		self.hunterScores ={} 
		self.beastsCollected ={} 
		self.beastTemplatesCollected ={} 
		self.banned = []
		self.pointTable ={ 
				"Normal 1": 10,
				"Normal 2": 30,
				"Normal 3": 90,
				"Metallic Silver 1": 50,
				"Metallic Silver 2": 150,
				"Metallic Silver 3": 450,
				"Cursed Black 1": 300,
				"Cursed Black 2": 900,
				"Cursed Black 3": 2700,
				"Shiny Gold 1": 1000,
				"Shiny Gold 2": 3000,
				"Shiny Gold 3": 9000,
				"Mythic Diamond 1": 10000,
				"Mythic Diamond 2": 10000,
				"Mythic Diamond 3": 10000
			}
		
		// Put Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&HunterScore.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		?? panic("Could not get a capability to the admin")
	}
}
