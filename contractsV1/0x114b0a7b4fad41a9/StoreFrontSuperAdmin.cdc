// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StoreFront from "./StoreFront.cdc"

// TOKEN RUNNERS: Contract responsable for Admin and Super admin permissions
access(all)
contract StoreFrontSuperAdmin{ 
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	/// Path where the public capability for the `Collection` is available
	access(all)
	let storeFrontAdminReceiverPublicPath: PublicPath
	
	/// Path where the private capability for the `Collection` is available
	access(all)
	let storeFrontAdminReceiverStoragePath: StoragePath
	
	/// Path where the store capability for the `SuperAdmin` is available
	access(all)
	let storeFrontSuperAdminStoragePath: StoragePath
	
	/// Path where the store capability for the `Admin` is available
	access(all)
	let storeFrontAdminStoragePath: StoragePath
	
	/// Event used on contract initiation
	access(all)
	event ContractInitialized()
	
	/// Event used on create super admin
	access(all)
	event StoreFrontCreated(databaseID: String)
	
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	access(all)
	resource interface ISuperAdminStoreFrontPublic{ 
		access(all)
		fun getSecondaryMarketplaceFee(): UFix64
	}
	
	access(all)
	resource SuperAdmin: ISuperAdminStoreFrontPublic{ 
		access(all)
		var adminRef: @{UInt64: StoreFront.Admin}
		
		access(all)
		var fee: UFix64
		
		init(){ 
			self.adminRef <-{} 
			self.adminRef[0] <-! StoreFront.createStoreFrontAdmin()
			self.fee = 0.0
		}
		
		access(all)
		fun getSecondaryMarketplaceFee(): UFix64{ 
			return self.fee
		}
		
		access(all)
		fun changeFee(_newFee: UFix64){ 
			self.fee = _newFee
		}
		
		access(all)
		fun withdrawAdmin(): @StoreFront.Admin{ 
			let token <- self.adminRef.remove(key: 0) ?? panic("Cannot withdraw admin resource")
			return <-token
		}
	}
	
	access(all)
	resource interface AdminTokenReceiverPublic{ 
		access(all)
		fun receiveAdmin(adminRef: Capability<&StoreFront.Admin>)
		
		access(all)
		fun receiveSuperAdmin(superAdminRef: Capability<&SuperAdmin>)
		
		access(all)
		fun getSuperAdminRefPublic(): &SuperAdmin?
	}
	
	access(all)
	resource AdminTokenReceiver: AdminTokenReceiverPublic{ 
		access(self)
		var adminRef: Capability<&StoreFront.Admin>?
		
		access(self)
		var superAdminRef: Capability<&SuperAdmin>?
		
		init(){ 
			self.adminRef = nil
			self.superAdminRef = nil
		}
		
		access(all)
		fun receiveAdmin(adminRef: Capability<&StoreFront.Admin>){ 
			self.adminRef = adminRef
		}
		
		access(all)
		fun receiveSuperAdmin(superAdminRef: Capability<&SuperAdmin>){ 
			self.superAdminRef = superAdminRef
		}
		
		access(all)
		fun getSuperAdminRefPublic(): &SuperAdmin?{ 
			return (self.superAdminRef!).borrow()
		}
		
		access(all)
		fun getAdminRef(): &StoreFront.Admin?{ 
			return (self.adminRef!).borrow()
		}
		
		access(all)
		fun getSuperAdminRef(): &SuperAdmin?{ 
			return (self.superAdminRef!).borrow()
		}
	}
	
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level function definitions
	// -----------------------------------------------------------------------
	// createAdminTokenReceiver create a admin token receiver. Must be public
	//
	access(all)
	fun createAdminTokenReceiver(): @AdminTokenReceiver{ 
		return <-create AdminTokenReceiver()
	}
	
	// createSuperAdmin create a super admin. Must be public
	//
	access(all)
	fun createSuperAdmin(
		adminTokenReceiver: Capability<&{AdminTokenReceiverPublic}>,
		storeFrontSuperAdminPrivatePath: PrivatePath,
		storeFrontAdminPrivatePath: PrivatePath
	){ 
		pre{ 
			adminTokenReceiver.address == self.requestedAdress:
				"Wallet can't get super admin permission!"
		}
		var capability_1 =
			self.account.capabilities.storage.issue<&SuperAdmin>(
				self.storeFrontSuperAdminStoragePath
			)
		self.account.capabilities.publish(capability_1, at: storeFrontSuperAdminPrivatePath)
		let capabilitySuperAdmin = capability_1
		var capability_2 =
			self.account.capabilities.storage.issue<&StoreFront.Admin>(
				self.storeFrontAdminStoragePath
			)
		self.account.capabilities.publish(capability_2, at: storeFrontAdminPrivatePath)
		let capabilityAdmin = capability_2
		(adminTokenReceiver.borrow()!).receiveSuperAdmin(superAdminRef: capabilitySuperAdmin)
		(adminTokenReceiver.borrow()!).receiveAdmin(adminRef: capabilityAdmin)
	}
	
	access(contract)
	let requestedAdress: Address
	
	init(requestedAdress: Address){ 
		// Paths
		self.storeFrontAdminReceiverPublicPath = /public/AdminTokenReceiver0x114b0a7b4fad41a9
		self.storeFrontAdminReceiverStoragePath = /storage/AdminTokenReceiver0x114b0a7b4fad41a9
		self.storeFrontSuperAdminStoragePath = /storage/superAdminStoreFront
		self.storeFrontAdminStoragePath = /storage/AdminStoreFront
		self.requestedAdress = requestedAdress
		let superAdmin <- create SuperAdmin()
		let admin <- superAdmin.withdrawAdmin()
		self.account.storage.save<@SuperAdmin>(
			<-superAdmin,
			to: self.storeFrontSuperAdminStoragePath
		)
		self.account.storage.save<@StoreFront.Admin>(<-admin, to: self.storeFrontAdminStoragePath)
		emit ContractInitialized()
	}
}
