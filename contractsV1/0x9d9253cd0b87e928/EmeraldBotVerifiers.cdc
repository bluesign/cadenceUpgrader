import EmeraldPass from "../0x6a07dbeb03167a13/EmeraldPass.cdc"

access(all)
contract EmeraldBotVerifiers{ 
	access(all)
	let VerifierCollectionStoragePath: StoragePath
	
	access(all)
	let VerifierCollectionPublicPath: PublicPath
	
	access(all)
	let VerifierCollectionPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event VerifierCreated(
		verifierId: UInt64,
		name: String,
		mode: UInt8,
		guildId: String,
		roleIds: [
			String
		]
	)
	
	access(all)
	event VerifierDeleted(verifierId: UInt64)
	
	access(all)
	enum VerificationMode: UInt8{ 
		access(all)
		case Normal
		
		access(all)
		case ShortCircuit
	}
	
	access(all)
	resource Verifier{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let scriptCode: String
		
		access(all)
		let guildId: String
		
		access(all)
		let roleIds: [String]
		
		access(all)
		let verificationMode: VerificationMode
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			name: String,
			description: String,
			image: String,
			scriptCode: String,
			guildId: String,
			roleIds: [
				String
			],
			verificationMode: VerificationMode,
			extra:{ 
				String: AnyStruct
			}
		){ 
			self.name = name
			self.description = description
			self.image = image
			self.scriptCode = scriptCode
			self.guildId = guildId
			self.roleIds = roleIds
			self.verificationMode = verificationMode
			self.extra = extra
		}
	}
	
	access(all)
	resource interface VerifierCollectionPublic{ 
		access(all)
		fun getVerifierIds(): [UInt64]
		
		access(all)
		fun getVerifier(verifierId: UInt64): &Verifier?
		
		access(all)
		fun getVerifiersByGuildId(guildId: String): [&Verifier?]
	}
	
	access(all)
	resource VerifierCollection: VerifierCollectionPublic{ 
		access(all)
		let verifiers: @{UInt64: Verifier}
		
		access(all)
		fun addVerifier(name: String, description: String, image: String, scriptCode: String, guildId: String, roleIds: [String], verificationMode: VerificationMode, extra:{ String: AnyStruct}){ 
			pre{ 
				EmeraldPass.isActive(user: (self.owner!).address) || self.verifiers.keys.length < 1:
					"You cannot have more than one verifier if you do not own Emerald Pass (https://pass.ecdao.org)."
			}
			let verifier <- create Verifier(name: name, description: description, image: image, scriptCode: scriptCode, guildId: guildId, roleIds: roleIds, verificationMode: verificationMode, extra: extra)
			emit VerifierCreated(verifierId: verifier.uuid, name: name, mode: verificationMode.rawValue, guildId: guildId, roleIds: roleIds)
			self.verifiers[verifier.uuid] <-! verifier
		}
		
		access(all)
		fun deleteVerifier(verifierId: UInt64){ 
			emit VerifierDeleted(verifierId: verifierId)
			destroy self.verifiers.remove(key: verifierId)
		}
		
		access(all)
		fun getVerifierIds(): [UInt64]{ 
			return self.verifiers.keys
		}
		
		access(all)
		fun getVerifier(verifierId: UInt64): &Verifier?{ 
			return &self.verifiers[verifierId] as &Verifier?
		}
		
		access(all)
		fun getVerifiersByGuildId(guildId: String): [&Verifier?]{ 
			let response: [&Verifier?] = []
			for id in self.getVerifierIds(){ 
				let verifier = self.getVerifier(verifierId: id)!
				if verifier.guildId == guildId{ 
					response.append(verifier)
				}
			}
			return response
		}
		
		init(){ 
			self.verifiers <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(): @VerifierCollection{ 
		return <-create VerifierCollection()
	}
	
	init(){ 
		self.VerifierCollectionStoragePath = /storage/EmeraldBotVerifierCollection001
		self.VerifierCollectionPublicPath = /public/EmeraldBotVerifierCollection001
		self.VerifierCollectionPrivatePath = /private/EmeraldBotVerifierCollection001
		emit ContractInitialized()
	}
}
