//Wow! You are viewing LimitlessCube Profile contract.
access(all)
contract Profile{ 
	access(all)
	let ProfilePublicPath: PublicPath
	
	access(all)
	let ProfileStoragePath: StoragePath
	
	//Profile created event
	access(all)
	event ProfileCreated(
		accountAddress: Address,
		displayName: String,
		username: String,
		description: String,
		avatar: String,
		coverPhoto: String,
		email: String,
		links:{ 
			String: String
		}
	)
	
	access(all)
	struct UserProfile{ 
		access(all)
		let address: Address
		
		access(all)
		let displayName: String
		
		access(all)
		let username: String
		
		access(all)
		let description: String
		
		access(all)
		let email: String
		
		access(all)
		let avatar: String
		
		access(all)
		let coverPhoto: String
		
		access(all)
		let links:{ String: String}
		
		init(
			address: Address,
			displayName: String,
			username: String,
			description: String,
			email: String,
			avatar: String,
			coverPhoto: String,
			links:{ 
				String: String
			}
		){ 
			self.address = address
			self.displayName = displayName
			self.username = username
			self.description = description
			self.email = email
			self.avatar = avatar
			self.coverPhoto = coverPhoto
			self.links = links
		}
	}
	
	access(all)
	resource interface Public{ 
		access(all)
		fun getDisplayName(): String
		
		access(all)
		fun getDescription(): String
		
		access(all)
		fun getAvatar(): String
		
		access(all)
		fun getCoverPhoto(): String
		
		access(all)
		fun getLinks():{ String: String}
		
		//TODO: create another method to deposit with message
		access(all)
		fun asProfile(): UserProfile
	}
	
	access(all)
	resource interface Owner{ 
		access(all)
		fun setDisplayName(_ val: String){ 
			pre{ 
				val.length <= 100:
					"displayName must be 100 or less characters"
			}
		}
		
		access(all)
		fun setUsername(_ val: String){ 
			pre{ 
				val.length <= 16:
					"username must be 16 or less characters"
			}
		}
		
		access(all)
		fun setDescription(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Description must be 255 characters or less"
			}
		}
		
		access(all)
		fun setEmail(_ val: String){ 
			pre{ 
				val.length <= 100:
					"Email must be 100 characters or less"
			}
		}
		
		access(all)
		fun setAvatar(_ val: String){ 
			pre{ 
				val.length <= 255:
					"Avatar must be 255 characters or less"
			}
		}
		
		access(all)
		fun setCoverPhoto(_ val: String){ 
			pre{ 
				val.length <= 255:
					"CoverPhoto must be 255 characters or less"
			}
		}
	}
	
	access(all)
	resource User: Public, Owner{ 
		access(self)
		var displayName: String
		
		access(self)
		var username: String
		
		access(self)
		var description: String
		
		access(self)
		var email: String
		
		access(self)
		var avatar: String
		
		access(self)
		var coverPhoto: String
		
		access(self)
		var links:{ String: String}
		
		init(displayName: String, username: String, description: String, email: String, links:{ String: String}){ 
			self.displayName = displayName
			self.username = username
			self.description = description
			self.email = email
			self.avatar = "https://avatars.onflow.org/avatar/ghostnote"
			self.coverPhoto = "https://avatars.onflow.org/avatar/ghostnote"
			self.links = links
		}
		
		access(all)
		fun asProfile(): UserProfile{ 
			return UserProfile(address: (self.owner!).address, displayName: self.getDisplayName(), username: self.getUsername(), description: self.getDescription(), email: self.getEmail(), avatar: self.getAvatar(), coverPhoto: self.getCoverPhoto(), links: self.getLinks())
		}
		
		access(all)
		fun getDisplayName(): String{ 
			return self.displayName
		}
		
		access(all)
		fun getUsername(): String{ 
			return self.username
		}
		
		access(all)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(all)
		fun getEmail(): String{ 
			return self.email
		}
		
		access(all)
		fun getAvatar(): String{ 
			return self.avatar
		}
		
		access(all)
		fun getCoverPhoto(): String{ 
			return self.coverPhoto
		}
		
		access(all)
		fun getLinks():{ String: String}{ 
			return self.links
		}
		
		access(all)
		fun setDisplayName(_ val: String){ 
			self.displayName = val
		}
		
		access(all)
		fun setUsername(_ val: String){ 
			self.displayName = val
		}
		
		access(all)
		fun setAvatar(_ val: String){ 
			self.avatar = val
		}
		
		access(all)
		fun setCoverPhoto(_ val: String){ 
			self.coverPhoto = val
		}
		
		access(all)
		fun setDescription(_ val: String){ 
			self.description = val
		}
		
		access(all)
		fun setEmail(_ val: String){ 
			self.email = val
		}
		
		access(all)
		fun setLinks(_ val:{ String: String}){ 
			self.links = val
		}
	}
	
	access(all)
	fun find(_ address: Address): &{Profile.Public}{ 
		return getAccount(address).capabilities.get<&{Profile.Public}>(Profile.ProfilePublicPath)
			.borrow()!
	}
	
	access(all)
	fun createUser(
		accountAddress: Address,
		displayName: String,
		username: String,
		description: String,
		avatar: String,
		coverPhoto: String,
		email: String,
		links:{ 
			String: String
		}
	): @Profile.User{ 
		pre{ 
			displayName.length <= 100:
				"displayName must be 100 or less characters"
			username.length <= 16:
				"username must be 16 or less characters"
			description.length <= 255:
				"Descriptions must be 255 or less characters"
			email.length <= 100:
				"Descriptions must be 100 or less characters"
			avatar.length <= 255:
				"Descriptions must be 255 or less characters"
			coverPhoto.length <= 255:
				"Descriptions must be 255 or less characters"
		}
		let profile <-
			create Profile.User(
				displayName: displayName,
				username: username,
				description: description,
				email: email,
				links: links
			)
		emit ProfileCreated(
			accountAddress: accountAddress,
			displayName: displayName,
			username: username,
			description: description,
			avatar: avatar,
			coverPhoto: coverPhoto,
			email: email,
			links: links
		)
		return <-profile
	}
	
	init(){ 
		self.ProfilePublicPath = /public/LCubeUserProfile
		self.ProfileStoragePath = /storage/LCubeUserProfile
	}
}
