//Wow! You are viewing LimitlessCube Profile contract.

pub contract Profile {
	pub let ProfilePublicPath: PublicPath
	pub let ProfileStoragePath: StoragePath

	//Profile created event
	pub event ProfileCreated(accountAddress:Address, displayName: String, username: String, description: String, avatar:String, coverPhoto:String, email:String, links:{String:String})

	pub struct UserProfile {
		pub let address: Address
		pub let displayName: String
		pub let username: String	
		pub let description: String
		pub let email: String
		pub let avatar: String
		pub let coverPhoto: String
		pub let links: {String:String}

		init(address: Address,
		displayName: String,
		username: String,
		description: String, 
		email: String, 
		avatar: String, 
		coverPhoto: String, 
		links: {String:String}) {
			self.address=address
			self.displayName=displayName
			self.username=username
			self.description=description
			self.email=email
			self.avatar=avatar
			self.coverPhoto=coverPhoto
			self.links=links
		}
	}
	pub resource interface Public {
		pub fun getDisplayName(): String
		pub fun getDescription(): String
		pub fun getAvatar(): String
		pub fun getCoverPhoto(): String
		pub fun getLinks() : {String:String}
		//TODO: create another method to deposit with message
		pub fun asProfile() : UserProfile
	}

	pub resource interface Owner {
		pub fun setDisplayName(_ val: String) {
			pre {
				val.length <= 100: "displayName must be 100 or less characters"
			}
		}

			pub fun setUsername(_ val: String) {
			pre {
				val.length <= 16: "username must be 16 or less characters"
			}
		}

		pub fun setDescription(_ val: String) {
			pre {
				val.length <= 255: "Description must be 255 characters or less"
			}
		}

		pub fun setEmail(_ val: String){
			pre {
				val.length <= 100: "Email must be 100 characters or less"
			}
		}

		pub fun setAvatar(_ val: String){
			pre {
				val.length <= 255: "Avatar must be 255 characters or less"
			}
		}

		pub fun setCoverPhoto(_ val: String){
			pre {
				val.length <= 255: "CoverPhoto must be 255 characters or less"
			}
		}   
	}

	pub resource User: Public, Owner {
		access(self) var displayName: String
		access(self) var username: String
		access(self) var description: String
		access(self) var email: String
		access(self) var avatar: String
		access(self) var coverPhoto: String
		access(self) var links: {String: String}

		init(displayName:String, username: String,description: String, email: String, links:{String:String}) {
			self.displayName = displayName
			self.username = username
			self.description=description
			self.email=email
			self.avatar = "https://avatars.onflow.org/avatar/ghostnote"
			self.coverPhoto = "https://avatars.onflow.org/avatar/ghostnote"
			self.links=links
		}		

		pub fun asProfile() : UserProfile {

			return UserProfile(
				address: self.owner!.address,
				displayName: self.getDisplayName(),
				username: self.getUsername(),
				description: self.getDescription(),
				email: self.getEmail(),
				avatar: self.getAvatar(),
				coverPhoto: self.getCoverPhoto(),
				links: self.getLinks()
			)
		}


		pub fun getDisplayName(): String { return self.displayName }
		pub fun getUsername(): String { return self.username }
		pub fun getDescription(): String{ return self.description}
		pub fun getEmail(): String{ return self.email}
		pub fun getAvatar(): String { return self.avatar }
		pub fun getCoverPhoto(): String { return self.coverPhoto }
		pub fun getLinks(): {String:String} { return self.links }

		pub fun setDisplayName(_ val: String) { self.displayName = val }
		pub fun setUsername(_ val: String) { self.displayName = val }
		pub fun setAvatar(_ val: String) { self.avatar = val }
		pub fun setCoverPhoto(_ val: String) { self.coverPhoto = val }
		pub fun setDescription(_ val: String) { self.description=val}
		pub fun setEmail(_ val: String) { self.email=val}
		pub fun setLinks(_ val: {String:String}) { self.links=val}
	}

	pub fun find(_ address: Address) : &{Profile.Public} {
		return getAccount(address)
		.getCapability<&{Profile.Public}>(Profile.ProfilePublicPath)
		.borrow()!
	}

	pub fun createUser(accountAddress:Address, displayName: String, username: String, description:String, avatar:String, coverPhoto:String, email:String, links:{String:String}) : @Profile.User {
		pre {			
			displayName.length <= 100: "displayName must be 100 or less characters"
			username.length <= 16: "username must be 16 or less characters"
			description.length <= 255: "Descriptions must be 255 or less characters"
			email.length <= 100: "Descriptions must be 100 or less characters"
			avatar.length <= 255: "Descriptions must be 255 or less characters"
			coverPhoto.length <= 255: "Descriptions must be 255 or less characters"
		}

		let profile <- create Profile.User(displayName: displayName,username: username, description: description, email: email, links:links)

		emit ProfileCreated(accountAddress:accountAddress, displayName:displayName, username:username,  description:description, avatar:avatar, coverPhoto:coverPhoto, email:email, links:links)

		return <- profile
	}

	init() {
		self.ProfilePublicPath = /public/LCubeUserProfile
		self.ProfileStoragePath = /storage/LCubeUserProfile
	}

}
 