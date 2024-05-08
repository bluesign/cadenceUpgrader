import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract BridgeManager{ 
	// Mapping with LockUp recipients as keys and LockUp
	// holders as values.
	access(all)
	let lockUpsMapping:{ Address: [Address]}
	
	// Constants for all the available paths
	access(all)
	let LockUpStoragePath: StoragePath
	
	access(all)
	let LockUpPrivatePath: PrivatePath
	
	access(all)
	let LockUpPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// Events emitted from the contract
	access(all)
	event LockUpCreated(holder: Address, recipient: Address)
	
	access(all)
	event LockUpDestroyed(holder: Address?, recipient: Address)
	
	access(all)
	event LockUpRecipientChanged(holder: Address, recipient: Address)
	
	access(all)
	event LockUpReleasedAtChanged(holder: Address, releasedAt: UInt64)
	
	access(all)
	event LockUpNameChanged(holder: Address, name: String)
	
	access(all)
	event LockUpDescriptionChanged(holder: Address, description: String)
	
	init(){ 
		self.lockUpsMapping ={} 
		self.LockUpStoragePath = /storage/bridge
		self.LockUpPrivatePath = /private/bridge
		self.LockUpPublicPath = /public/bridge
		self.AdminStoragePath = /storage/admin
		self.AdminPrivatePath = /private/admin
		let admin <- create Admin()
		self.account.storage.save<@Admin>(<-admin, to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
	}
	
	access(all)
	struct FungibleTokenInfo{ 
		access(all)
		let name: String
		
		access(all)
		let receiverPath: PublicPath
		
		access(all)
		let balancePath: PublicPath
		
		access(all)
		let privatePath: PrivatePath
		
		access(all)
		let storagePath: StoragePath
		
		init(
			name: String,
			receiverPath: PublicPath,
			balancePath: PublicPath,
			privatePath: PrivatePath,
			storagePath: StoragePath
		){ 
			self.name = name
			self.receiverPath = receiverPath
			self.balancePath = balancePath
			self.privatePath = privatePath
			self.storagePath = storagePath
		}
	}
	
	access(all)
	struct NonFungibleTokenInfo{ 
		access(all)
		let name: String
		
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let privatePath: PrivatePath
		
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let publicType: Type
		
		access(all)
		let privateType: Type
		
		init(
			name: String,
			publicPath: PublicPath,
			privatePath: PrivatePath,
			storagePath: StoragePath,
			publicType: Type,
			privateType: Type
		){ 
			self.name = name
			self.publicPath = publicPath
			self.privatePath = privatePath
			self.storagePath = storagePath
			self.publicType = publicType
			self.privateType = privateType
		}
	}
	
	access(all)
	struct FTLockUpInfo{ 
		access(all)
		let identifier: String
		
		access(all)
		let balance: UFix64?
		
		init(identifier: String, balance: UFix64?){ 
			self.identifier = identifier
			self.balance = balance
		}
	}
	
	access(all)
	struct NFTLockUpInfo{ 
		access(all)
		let identifier: String
		
		access(all)
		let nftIDs: [UInt64]?
		
		init(identifier: String, nftIDs: [UInt64]?){ 
			self.identifier = identifier
			self.nftIDs = nftIDs
		}
	}
	
	access(all)
	struct LockUpInfo{ 
		access(all)
		let holder: Address
		
		access(all)
		let releasedAt: UInt64
		
		access(all)
		let createdAt: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let recipient: Address
		
		access(all)
		let fungibleTokens: [FTLockUpInfo]
		
		access(all)
		let nonFungibleTokens: [NFTLockUpInfo]
		
		init(
			holder: Address,
			releasedAt: UInt64,
			createdAt: UInt64,
			name: String,
			description: String,
			recipient: Address,
			fungibleTokens: [
				FTLockUpInfo
			],
			nonFungibleTokens: [
				NFTLockUpInfo
			]
		){ 
			self.holder = holder
			self.releasedAt = releasedAt
			self.createdAt = createdAt
			self.name = name
			self.description = description
			self.recipient = recipient
			self.fungibleTokens = fungibleTokens
			self.nonFungibleTokens = nonFungibleTokens
		}
	}
	
	access(all)
	resource interface LockUpPublic{ 
		access(all)
		fun getInfo(): LockUpInfo
		
		// E.g Type<FlowToken>().identifier => A.7e60df042a9c0868.FlowToken
		access(all)
		fun withdrawFT(
			identifier: String,
			amount: UFix64,
			receiver: Capability<&{FungibleToken.Receiver}>,
			feeTokens: @{FungibleToken.Vault}
		)
		
		// E.g Type<Domains>().identifier => A.9a0766d93b6608b7.Domains
		access(all)
		fun withdrawNFT(
			identifier: String,
			receiver: Capability<&{NonFungibleToken.Receiver}>,
			feeTokens: @{FungibleToken.Vault},
			nftIDs: [
				UInt64
			]?
		)
	}
	
	access(all)
	resource interface LockUpPrivate{ 
		access(all)
		fun lockFT(identifier: String, vault: Capability<&{FungibleToken.Vault}>, balance: UFix64?)
		
		access(all)
		fun lockFTs(_ ftsMapping:{ String: FTLockUp})
		
		access(all)
		fun lockNFT(
			identifier: String,
			collection: Capability<&{NonFungibleToken.Collection}>,
			nftIDs: [
				UInt64
			]?
		)
		
		access(all)
		fun setReleasedAt(releasedAt: UInt64)
		
		access(all)
		fun setName(name: String)
		
		access(all)
		fun setDescription(description: String)
		
		access(all)
		fun setRecipient(recipient: Address)
		
		access(all)
		fun setBalance(identifier: String, balance: UFix64)
		
		access(all)
		fun setNFTIDs(identifier: String, nftIDs: [UInt64])
	}
	
	access(all)
	struct FTLockUp{ 
		access(all)
		let vault: Capability<&{FungibleToken.Vault}>
		
		access(all)
		var balance: UFix64?
		
		init(vault: Capability<&{FungibleToken.Vault}>, balance: UFix64?){ 
			self.vault = vault
			self.balance = balance
		}
		
		access(all)
		fun updateBalance(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	struct NFTLockUp{ 
		access(all)
		let collection: Capability<&{NonFungibleToken.Collection}>
		
		access(all)
		var nftIDs: [UInt64]?
		
		init(collection: Capability<&{NonFungibleToken.Collection}>, nftIDs: [UInt64]?){ 
			self.collection = collection
			self.nftIDs = nftIDs
		}
		
		access(all)
		fun updateNFTIDs(nftIDs: [UInt64]){ 
			self.nftIDs = nftIDs
		}
	}
	
	access(all)
	resource LockUp: LockUpPublic, LockUpPrivate{ 
		access(self)
		let holder: Address
		
		access(self)
		var releasedAt: UInt64
		
		access(self)
		var createdAt: UInt64
		
		access(self)
		var name: String
		
		access(self)
		var description: String
		
		access(self)
		var recipient: Address
		
		access(self)
		let ftLockUps:{ String: FTLockUp}
		
		access(self)
		let nftLockUps:{ String: NFTLockUp}
		
		init(holder: Address, releasedAt: UInt64, name: String, description: String, recipient: Address){ 
			self.holder = holder
			self.releasedAt = releasedAt
			self.createdAt = UInt64(getCurrentBlock().timestamp)
			self.name = name
			self.description = description
			self.recipient = recipient
			self.ftLockUps ={} 
			self.nftLockUps ={} 
		}
		
		access(all)
		fun getInfo(): LockUpInfo{ 
			let fungibleTokens: [FTLockUpInfo] = []
			let nonFungibleTokens: [NFTLockUpInfo] = []
			for key in self.ftLockUps.keys{ 
				let ftLockUpInfo = FTLockUpInfo(identifier: key, balance: (self.ftLockUps[key]!).balance)
				fungibleTokens.append(ftLockUpInfo)
			}
			for key in self.nftLockUps.keys{ 
				let nftLockUpInfo = NFTLockUpInfo(identifier: key, nftIDs: (self.nftLockUps[key]!).nftIDs)
				nonFungibleTokens.append(nftLockUpInfo)
			}
			return LockUpInfo(holder: self.holder, releasedAt: self.releasedAt, createdAt: self.createdAt, name: self.name, description: self.description, recipient: self.recipient, fungibleTokens: fungibleTokens, nonFungibleTokens: nonFungibleTokens)
		}
		
		access(all)
		fun withdrawFT(identifier: String, amount: UFix64, receiver: Capability<&{FungibleToken.Receiver}>, feeTokens: @{FungibleToken.Vault}){ 
			let currentTime = UInt64(getCurrentBlock().timestamp)
			// if self.releasedAt > currentTime {
			//	 panic("The assets are still in lock-up period.")
			// }
			if self.recipient != receiver.address{ 
				panic("Non-authorized recipient.")
			}
			let ftLockUp = self.ftLockUps[identifier] ?? panic("Non-supported FungibleToken.")
			if ftLockUp.balance != nil && amount > ftLockUp.balance!{ 
				panic("You cannot withdraw more than the remaining balance of: ".concat((ftLockUp.balance!).toString()))
			}
			let ownerVault = ftLockUp.vault.borrow() ?? panic("Could not borrow FungibleToken.Vault reference.")
			let recipientvault = receiver.borrow() ?? panic("Could not borrow FungibleToken.Receiver reference.")
			let admin = BridgeManager.getAdmin()
			let feeSent = feeTokens.balance
			if feeSent < admin.lockUpWithdrawFees{ 
				panic("You did not send enough FLOW tokens. Expected: ".concat(admin.lockUpWithdrawFees.toString()))
			}
			// Withdraws the requested amount from the owner's vault
			// and deposits it to the recipient's vault
			recipientvault.deposit(from: <-ownerVault.withdraw(amount: amount))
			if ftLockUp.balance != nil{ 
				(self.ftLockUps[identifier]!).updateBalance(balance: ftLockUp.balance! - amount)
			}
			admin.deposit(feeTokens: <-feeTokens)
		}
		
		access(all)
		fun withdrawNFT(identifier: String, receiver: Capability<&{NonFungibleToken.Receiver}>, feeTokens: @{FungibleToken.Vault}, nftIDs: [UInt64]?){ 
			let currentTime = UInt64(getCurrentBlock().timestamp)
			// if self.releasedAt > currentTime {
			//	 panic("The assets are still in lock-up period!")
			// }
			if self.recipient != receiver.address{ 
				panic("Non authorized recipient!")
			}
			let nftLockUp = self.nftLockUps[identifier] ?? panic("Non-supported FungibleToken.")
			let receiverRef = receiver.borrow() ?? panic("Could not borrow NonFungibleToken.Receiver reference.")
			let collectionRef = nftLockUp.collection.borrow() ?? panic("Could not borrow NonFungibleToken.Collection reference.")
			let admin = BridgeManager.getAdmin()
			let feeSent = feeTokens.balance
			if feeSent < admin.lockUpWithdrawFees{ 
				panic("You did not send enough FLOW tokens. Expected: ".concat(admin.lockUpWithdrawFees.toString()))
			}
			let currentCollectionIDs = collectionRef.getIDs()
			var IDs: [UInt64] = []
			var remainingNFTIDs: [UInt64] = nftLockUp.nftIDs!
			if let ids = nftIDs{ 
				IDs.appendAll(ids)
			} else{ 
				IDs = nftLockUp.nftIDs!
			}
			for id in IDs{ 
				if !currentCollectionIDs.contains(id){ 
					continue
				}
				if let index = remainingNFTIDs.firstIndex(of: id){ 
					let nft <- collectionRef.withdraw(withdrawID: id)
					receiverRef.deposit(token: <-nft)
					remainingNFTIDs.remove(at: index)
				}
			}
			(self.nftLockUps[identifier]!).updateNFTIDs(nftIDs: remainingNFTIDs)
			admin.deposit(feeTokens: <-feeTokens)
		}
		
		access(all)
		fun lockFT(identifier: String, vault: Capability<&{FungibleToken.Vault}>, balance: UFix64?){ 
			self.ftLockUps[identifier] = FTLockUp(vault: vault, balance: balance)
		}
		
		access(all)
		fun lockFTs(_ ftMapping:{ String: FTLockUp}){ 
			for identifier in self.ftLockUps.keys{ 
				if !ftMapping.containsKey(identifier){ 
					self.ftLockUps.remove(key: identifier)
				}
			}
			for identifier in ftMapping.keys{ 
				self.ftLockUps.insert(key: identifier, ftMapping[identifier]!)
			}
		}
		
		access(all)
		fun lockNFT(identifier: String, collection: Capability<&{NonFungibleToken.Collection}>, nftIDs: [UInt64]?){ 
			var IDs: [UInt64] = []
			if let ids = nftIDs{ 
				self.checkNFTExistence(collection: collection, nftIDs: nftIDs!)
				IDs.appendAll(ids)
			} else{ 
				IDs.appendAll((collection.borrow()!).getIDs())
			}
			if let nftLockUp = self.nftLockUps[identifier]{ 
				for id in IDs{ 
					if !(nftLockUp.nftIDs!).contains(id){ 
						(nftLockUp.nftIDs!).append(id)
					}
				}
				self.nftLockUps.insert(key: identifier, nftLockUp)
			} else{ 
				self.nftLockUps[identifier] = NFTLockUp(collection: collection, nftIDs: IDs)
			}
		}
		
		access(all)
		fun setReleasedAt(releasedAt: UInt64){ 
			self.releasedAt = releasedAt
			emit LockUpReleasedAtChanged(holder: self.holder, releasedAt: releasedAt)
		}
		
		access(all)
		fun setName(name: String){ 
			self.name = name
			emit LockUpNameChanged(holder: self.holder, name: name)
		}
		
		access(all)
		fun setDescription(description: String){ 
			self.description = description
			emit LockUpDescriptionChanged(holder: self.holder, description: description)
		}
		
		access(all)
		fun setRecipient(recipient: Address){ 
			BridgeManager.removeFromLockUpsMapping(holder: self.holder, recipient: self.recipient)
			self.recipient = recipient
			BridgeManager.addToLockUpsMapping(holder: self.holder, recipient: self.recipient)
			emit LockUpRecipientChanged(holder: self.holder, recipient: recipient)
		}
		
		access(all)
		fun setBalance(identifier: String, balance: UFix64){ 
			if !self.ftLockUps.containsKey(identifier){ 
				panic("Non-supported FungibleToken.")
			}
			(self.ftLockUps[identifier]!).updateBalance(balance: balance)
		}
		
		access(all)
		fun setNFTIDs(identifier: String, nftIDs: [UInt64]){ 
			if !self.nftLockUps.containsKey(identifier){ 
				panic("Non-supported NonFungibleToken.")
			}
			if nftIDs.length > 0{ 
				self.checkNFTExistence(collection: (self.nftLockUps[identifier]!).collection, nftIDs: nftIDs)
			}
			(self.nftLockUps[identifier]!).updateNFTIDs(nftIDs: nftIDs)
		}
		
		access(self)
		fun checkNFTExistence(collection: Capability<&{NonFungibleToken.Collection}>, nftIDs: [UInt64]){ 
			let collectionRef = collection.borrow() ?? panic("Could not borrow NonFungibleToken.Collection reference.")
			for nftID in nftIDs{ 
				let nft = collectionRef.borrowNFT(nftID)
			}
		}
	}
	
	access(all)
	resource Admin{ 
		access(contract)
		var lockUpCreationFees: UFix64
		
		access(contract)
		var lockUpWithdrawFees: UFix64
		
		access(contract)
		let feesVault: @{FungibleToken.Vault}
		
		access(contract)
		let fungibleTokenInfoMapping:{ String: FungibleTokenInfo}
		
		access(contract)
		let nonFungibleTokenInfoMapping:{ String: NonFungibleTokenInfo}
		
		init(){ 
			self.lockUpCreationFees = 0.0
			self.lockUpWithdrawFees = 0.0
			self.feesVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			self.fungibleTokenInfoMapping ={} 
			self.nonFungibleTokenInfoMapping ={} 
		}
		
		access(all)
		fun addFungibleTokenInfo(identifier: String, tokenInfo: FungibleTokenInfo){ 
			self.fungibleTokenInfoMapping[identifier] = tokenInfo
		}
		
		access(all)
		fun addNonFungibleTokenInfo(identifier: String, tokenInfo: NonFungibleTokenInfo){ 
			self.nonFungibleTokenInfoMapping[identifier] = tokenInfo
		}
		
		access(all)
		fun updateCreationFees(fees: UFix64){ 
			self.lockUpCreationFees = fees
		}
		
		access(all)
		fun updateWithdrawFees(fees: UFix64){ 
			self.lockUpWithdrawFees = fees
		}
		
		access(all)
		fun deposit(feeTokens: @{FungibleToken.Vault}){ 
			self.feesVault.deposit(from: <-feeTokens)
		}
	}
	
	access(all)
	fun createLockUp(
		holder: Address,
		releasedAt: UInt64,
		name: String,
		description: String,
		recipient: Address,
		feeTokens: @{FungibleToken.Vault}
	): @LockUp{ 
		// pre {
		//	 releasedAt > UInt64(getCurrentBlock().timestamp) : "releasedAt should be a future date timestamp"
		// }
		let admin = self.getAdmin()
		let feeSent = feeTokens.balance
		// if feeSent < admin.lockUpCreationFees {
		//	 panic(
		//		 "You did not send enough FLOW tokens. Expected: "
		//		 .concat(admin.lockUpCreationFees.toString())
		//	 )
		// }
		let lockUp <-
			create LockUp(
				holder: holder,
				releasedAt: releasedAt,
				name: name,
				description: description,
				recipient: recipient
			)
		BridgeManager.addToLockUpsMapping(holder: holder, recipient: recipient)
		emit LockUpCreated(holder: holder, recipient: recipient)
		admin.deposit(feeTokens: <-feeTokens)
		return <-lockUp
	}
	
	access(all)
	fun getFungibleTokenInfoMapping():{ String: FungibleTokenInfo}{ 
		let admin = self.getAdmin()
		return *admin.fungibleTokenInfoMapping
	}
	
	access(all)
	fun getNonFungibleTokenInfoMapping():{ String: NonFungibleTokenInfo}{ 
		let admin = self.getAdmin()
		return *admin.nonFungibleTokenInfoMapping
	}
	
	access(all)
	fun getCreationFees(): UFix64{ 
		let admin = self.getAdmin()
		return admin.lockUpCreationFees
	}
	
	access(all)
	fun getWithdrawFees(): UFix64{ 
		let admin = self.getAdmin()
		return admin.lockUpWithdrawFees
	}
	
	access(contract)
	fun addToLockUpsMapping(holder: Address, recipient: Address){ 
		if self.lockUpsMapping.containsKey(recipient){ 
			(self.lockUpsMapping[recipient]!).append(holder)
		} else{ 
			self.lockUpsMapping[recipient] = [holder]
		}
	}
	
	access(contract)
	fun removeFromLockUpsMapping(holder: Address, recipient: Address){ 
		if !self.lockUpsMapping.containsKey(recipient){ 
			return
		}
		let holders = self.lockUpsMapping[recipient]!
		var index: Int = 0
		for h in holders{ 
			if h == holder{ 
				break
			}
			index = index + 1
		}
		holders.remove(at: index)
		self.lockUpsMapping[recipient] = holders
	}
	
	access(contract)
	fun getAdmin(): &Admin{ 
		let admin =
			self.account.capabilities.get<&Admin>(self.AdminPrivatePath).borrow<&Admin>()
			?? panic("Could not borrow BridgeManager.Admin reference.")
		return admin
	}
}
