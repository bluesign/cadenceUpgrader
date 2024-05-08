// Based on Verses Profile. Needed a Profile without a Wallet Solution. Using MultiFungible Token Instead 0x229e7617283d5085 for a Wallet Solution.
// A Basic Profile. web: DAAM.Agency
// Ami Rajpal: ami@daam.agency
// DAAM Agency (web: daam.agency)
import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract DAAM_Profile{ 
	// Storage:
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	/******************************************************************************************/
	// Events:
	access(all)
	event ContractInitialized()
	
	access(all)
	event ProfileCreated(name: String)
	
	access(all)
	event UpdateEmail(email: String?)
	
	access(all)
	event UpdateAbout(about: String?)
	
	access(all)
	event UpdateDescription(description: String?)
	
	access(all)
	event UpdateWeb(web: String)
	
	access(all)
	event UpdateSocial(social:{ String: String})
	
	access(all)
	event UpdateAvatar()
	
	access(all)
	event UpdateHeroImage()
	
	access(all)
	event UpdateNotes(notes: [String]) // returning notes.keys	 
	
	
	access(all)
	event RemoveWeb(web: String)
	
	access(all)
	event RemoveSocial(social: String)
	
	access(all)
	event RemoveNotes(note: String)
	
	/******************************************************************************************/
	// Interface:
	// Public
	access(all)
	resource interface Public{ 
		access(all)
		fun getProfile(): UserHandler
	}
	
	/******************************************************************************************/
	// Structs:
	// UserHandler
	access(all)
	struct UserHandler{ 
		access(all)
		let name: String
		
		access(all)
		let email: String?
		
		access(all)
		let about: String?
		
		access(all)
		let description: String?
		
		access(all)
		let web: [MetadataViews.ExternalURL]
		
		access(all)
		let social:{ String: String}
		
		access(all)
		let avatar:{ MetadataViews.File}?
		
		access(all)
		let heroImage:{ MetadataViews.File}?
		
		access(all)
		let notes:{ String: String}
		
		init(_ user: &User){ 
			pre{ 
				user != nil
			}
			self.name = user.name
			self.email = user.email
			self.about = user.about
			self.description = user.description
			self.web = *user.web
			self.social = *user.social
			self.avatar = *user.avatar
			self.heroImage = *user.heroImage
			self.notes = *user.notes
		}
	}
	
	/******************************************************************************************/
	// Resource:
	// User
	access(all)
	resource User: Public{ 
		access(all)
		let name: String
		
		access(all)
		var email: String?
		
		access(all)
		var about: String?
		
		access(all)
		var description: String?
		
		access(all)
		var web: [MetadataViews.ExternalURL]
		
		access(all)
		var social:{ String: String}
		
		access(all)
		var avatar:{ MetadataViews.File}?
		
		access(all)
		var heroImage:{ MetadataViews.File}?
		
		access(all)
		var notes:{ String: String} // {Types of Notes : Note}
		
		
		// Init
		init(name: String, about: String?, description: String?, web: String?, social:{ String: String}?, avatar:{ MetadataViews.File}?, heroImage:{ MetadataViews.File}?, notes:{ String: String}?){ 
			self.name = name
			self.email = nil
			self.about = about
			self.description = description
			self.web = web != nil ? [MetadataViews.ExternalURL(web!)] : []
			self.social = social != nil ? social! :{} 
			self.avatar = avatar
			self.heroImage = heroImage
			self.notes = notes != nil ? notes! :{} 
			emit ProfileCreated(name: self.name)
		}
		
		access(self)
		fun validateEmailPortion(_ ref: [UInt8], _ plusLimit: Int){ // plusLimit limits the number of '+' 
			
			var plus_counter = 0
			for r in ref{ 
				log("r: ".concat(r.toString()))
				if r == 43{ 
					plus_counter = plus_counter + 1
				}
				if (r < 97 || r > 122) && r != 95 && r != 43 && (r < 48 || r > 57){ // ascii: 97='a', 122='z', 95='_', 43='+', 48='0', 57='9' 
					
					panic("Invalid Email Entered")
				}
				if plus_counter > plusLimit{ 
					panic("Invalid Email Entered")
				}
			}
		}
		
		// Functions
		// Internal Functions
		access(self)
		fun verifyEmail(_ entered_name: String, _ entered_at: String, _ entered_dot: String): String{ 
			let name = entered_name.toLower().utf8
			let at = entered_at.toLower().utf8
			let dot = entered_dot.toLower().utf8
			self.validateEmailPortion(name, 1)
			self.validateEmailPortion(at, 0)
			self.validateEmailPortion(dot, 0)
			let email = entered_name.toLower().concat("@").concat(entered_at.toLower()).concat(".").concat(entered_dot.toLower())
			assert(email.length <= 40, message: "Email too long.")
			log("Email: ".concat(email))
			return email
		}
		
		// Set Functions
		access(all)
		fun setEmail(name: String?, at: String?, dot: String?){ 
			pre{ 
				name == nil && at == nil && dot == nil || name != nil && at != nil && dot != nil:
					"Invalid Email Entered."
			}
			if name == nil{ 
				self.email = nil
				return
			}
			self.email = self.verifyEmail(name!, at!, dot!)
			emit UpdateEmail(email: self.email)
		}
		
		access(all)
		fun setAbout(_ about: String?){ 
			self.about = about
			emit UpdateAbout(about: about)
		}
		
		access(all)
		fun setDescription(_ desc: String?){ 
			self.description = desc
			emit UpdateDescription(description: desc)
		}
		
		access(all)
		fun setAvatar(_ avatar:{ MetadataViews.File}?){ 
			self.avatar = avatar
			emit UpdateAvatar()
		}
		
		access(all)
		fun setHeroImage(_ hero:{ MetadataViews.File}?){ 
			self.heroImage = hero
			emit UpdateHeroImage()
		}
		
		// Add Functions
		access(all)
		fun addWeb(_ web: String){ 
			for w in self.web{ 
				assert(w.url != web, message: web.concat(" has already been added."))
			}
			self.web.append(MetadataViews.ExternalURL(web))
			emit UpdateWeb(web: web)
		}
		
		access(all)
		fun addSocial(_ social:{ String: String}){ 
			for s in social.keys{ 
				self.social[s] = social[s]
			}
			emit UpdateSocial(social: social)
		}
		
		access(all)
		fun addNotes(_ notes:{ String: String}){ 
			for n in notes.keys{ 
				self.notes[n] = notes[n]
			}
			emit UpdateNotes(notes: notes.keys)
		}
		
		// Remove Functions
		access(all)
		fun removeWeb(_ web: String){ 
			var counter = 0
			for w in self.web{ 
				if w.url == web{ 
					self.web.remove(at: counter)
					emit RemoveWeb(web: web)
					return
				}
				counter = counter + 1
			}
			panic("Could not remove Website. Doesn not exist in list in list.")
		}
		
		access(all)
		fun removeSocial(_ social: String){ 
			pre{ 
				self.social.containsKey(social):
					social.concat(" doesn not exist.")
			}
			self.social.remove(key: social)
			emit RemoveSocial(social: social)
		}
		
		access(all)
		fun removeNotes(_ note: String){ 
			pre{ 
				self.notes.containsKey(note):
					note.concat(" doesn not exist.")
			}
			self.notes.remove(key: note)
			emit RemoveNotes(note: note)
		}
		
		// Resource Public Functions
		access(all)
		fun getProfile(): UserHandler{ 
			return UserHandler(&self as &User)
		}
	} // End User Resource
	
	
	/******************************************************************************************/
	// Contract Public Functions:
	access(all)
	fun createProfile(
		name: String,
		about: String?,
		description: String?,
		web: String?,
		social:{ 
			String: String
		}?,
		avatar:{ MetadataViews.File}?,
		heroImage:{ MetadataViews.File}?,
		notes:{ 
			String: String
		}?
	): @User{ 
		return <-create User(
			name: name,
			about: about,
			description: description,
			web: web,
			social: social,
			avatar: avatar,
			heroImage: heroImage,
			notes: notes
		)
	}
	
	access(all)
	fun check(_ address: Address): Bool{ 
		let ref = getAccount(address).capabilities.get<&User>(self.publicPath).borrow() as &User?
		return ref != nil
	}
	
	// Initialization
	init(){ 
		let defaultPath = "DAAM_Profile"
		self.publicPath = PublicPath(identifier: defaultPath)!
		self.storagePath = StoragePath(identifier: defaultPath)!
		emit ContractInitialized()
	}
}
