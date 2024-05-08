import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract Permitted{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	let PublicPath: PublicPath
	
	access(all)
	event PermittedType(_ type: String, _ permitted: Bool, _ message: String)
	
	access(all)
	event PermittedUUID(_ uuid: UInt64, _ permitted: Bool, _ message: String)
	
	access(all)
	event PermittedTypeRemoved(_ type: Type)
	
	access(all)
	resource Manager{ 
		access(account)
		let permitted:{ Type: Bool}
		
		access(account)
		let permittedUUID:{ UInt64: Bool}
		
		access(all)
		fun isPermitted(_ nft: &{NonFungibleToken.NFT}): Bool{ 
			let t = nft.getType()
			return (self.permitted[t] == nil || self.permitted[t]!)
			&& (self.permittedUUID[nft.uuid] == nil || self.permittedUUID[nft.uuid]!)
		}
		
		access(all)
		fun setPermittedType(_ t: Type, _ b: Bool, _ s: String){ 
			self.permitted[t] = b
			let manager = Permitted.getReasonManager()
			manager.setReason(t, s)
			emit PermittedType(t.identifier, b, s)
		}
		
		access(all)
		fun removeType(_ t: Type){ 
			self.permitted.remove(key: t)
			emit PermittedTypeRemoved(t)
		}
		
		access(all)
		fun setPermittedUUID(_ uuid: UInt64, _ b: Bool, _ s: String){ 
			self.permittedUUID[uuid] = b
			emit PermittedUUID(uuid, b, s)
		}
		
		access(all)
		fun getAll():{ Type: Bool}{ 
			return self.permitted
		}
		
		init(){ 
			self.permitted ={} 
			self.permittedUUID ={} 
		}
	}
	
	access(all)
	fun isPermitted(_ nft: &{NonFungibleToken.NFT}): Bool{ 
		return (self.account.storage.borrow<&Manager>(from: Permitted.StoragePath)!).isPermitted(
			nft
		)
	}
	
	access(all)
	fun getAll():{ Type: Bool}{ 
		return (self.account.storage.borrow<&Manager>(from: Permitted.StoragePath)!).getAll()
	}
	
	access(all)
	fun getReasonManagerPublicPath(): PublicPath{ 
		return /public/permittedReason
	}
	
	access(all)
	fun getReasonManagerStoragePath(): StoragePath{ 
		return /storage/permittedReason
	}
	
	access(all)
	resource PermitReasonManager{ 
		access(all)
		let typeReasons:{ Type: String}
		
		access(all)
		let uuidReasons:{ Type: String}
		
		init(){ 
			self.typeReasons ={} 
			self.uuidReasons ={} 
		}
		
		access(all)
		fun setReason(_ t: Type, _ s: String){ 
			self.typeReasons[t] = s
		}
		
		access(all)
		fun getReason(_ t: Type): String?{ 
			return self.typeReasons[t]
		}
	}
	
	access(all)
	fun getReason(_ t: Type): String?{ 
		return (
			self.account.storage.borrow<&PermitReasonManager>(
				from: Permitted.getReasonManagerStoragePath()
			)!
		).getReason(t)
	}
	
	access(account)
	fun getReasonManager(): &PermitReasonManager{ 
		return self.account.storage.borrow<&PermitReasonManager>(
			from: Permitted.getReasonManagerStoragePath()
		)!
	}
	
	access(all)
	fun createReasonManager(): @PermitReasonManager{ 
		return <-create PermitReasonManager()
	}
	
	init(){ 
		self.StoragePath = /storage/permittedManager
		self.PublicPath = /public/permittedManager
		self.account.storage.save(<-create Manager(), to: self.StoragePath)
		self.account.storage.save(
			<-self.createReasonManager(),
			to: self.getReasonManagerStoragePath()
		)
	}
}
