import GomokuType from "./GomokuType.cdc"

access(all)
contract GomokuIdentity{ 
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Events
	access(all)
	event Create(id: UInt32, address: Address, role: UInt8)
	
	access(all)
	event CollectionCreated()
	
	access(all)
	event Withdraw(id: UInt32, from: Address?)
	
	access(all)
	event Deposit(id: UInt32, to: Address?)
	
	init(){ 
		self.CollectionStoragePath = /storage/gomokuIdentityCollection
		self.CollectionPublicPath = /public/gomokuIdentityCollection
	}
	
	access(all)
	resource IdentityToken{ 
		access(all)
		let id: UInt32
		
		access(all)
		let address: Address
		
		access(all)
		let role: GomokuType.Role
		
		access(all)
		var stoneColor: GomokuType.StoneColor
		
		access(self)
		var destroyable: Bool
		
		init(
			id: UInt32,
			address: Address,
			role: GomokuType.Role,
			stoneColor: GomokuType.StoneColor
		){ 
			self.id = id
			self.address = address
			self.role = role
			self.stoneColor = stoneColor
			self.destroyable = false
		}
		
		access(account)
		fun switchIdentity(){ 
			switch self.stoneColor{ 
				case GomokuType.StoneColor.black:
					self.stoneColor = GomokuType.StoneColor.white
				case GomokuType.StoneColor.white:
					self.stoneColor = GomokuType.StoneColor.black
			}
		}
		
		access(account)
		fun setDestroyable(_ value: Bool){ 
			self.destroyable = value
		}
	}
	
	access(account)
	fun createIdentity(
		id: UInt32,
		address: Address,
		role: GomokuType.Role,
		stoneColor: GomokuType.StoneColor
	): @IdentityToken{ 
		emit Create(id: id, address: address, role: role.rawValue)
		return <-create IdentityToken(id: id, address: address, role: role, stoneColor: stoneColor)
	}
	
	access(all)
	resource IdentityCollection{ 
		access(all)
		let StoragePath: StoragePath
		
		access(all)
		let PublicPath: PublicPath
		
		access(self)
		var ownedIdentityTokenMap: @{UInt32: IdentityToken}
		
		access(self)
		var destroyable: Bool
		
		init(){ 
			self.ownedIdentityTokenMap <-{} 
			self.destroyable = false
			self.StoragePath = /storage/compositionIdentity
			self.PublicPath = /public/compositionIdentity
		}
		
		access(account)
		fun withdraw(by id: UInt32): @IdentityToken?{ 
			if let token <- self.ownedIdentityTokenMap.remove(key: id){ 
				emit Withdraw(id: token.id, from: self.owner?.address)
				if self.ownedIdentityTokenMap.keys.length == 0{ 
					self.destroyable = true
				}
				return <-token
			} else{ 
				return nil
			}
		}
		
		access(account)
		fun deposit(token: @IdentityToken){ 
			let token <- token
			let id: UInt32 = token.id
			let oldToken <- self.ownedIdentityTokenMap[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			self.destroyable = false
			destroy oldToken
		}
		
		access(all)
		fun getIds(): [UInt32]{ 
			return self.ownedIdentityTokenMap.keys
		}
		
		access(all)
		fun getBalance(): Int{ 
			return self.ownedIdentityTokenMap.keys.length
		}
		
		access(all)
		fun borrow(id: UInt32): &IdentityToken?{ 
			return &self.ownedIdentityTokenMap[id] as &IdentityToken?
		}
	}
	
	access(all)
	fun createEmptyVault(): @IdentityCollection{ 
		emit CollectionCreated()
		return <-create IdentityCollection()
	}
}
