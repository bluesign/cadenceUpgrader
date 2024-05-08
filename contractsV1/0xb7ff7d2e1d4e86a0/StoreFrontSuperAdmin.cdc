// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

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
		fun getStoreFrontPublic(): &NFTStorefront.Storefront
		
		access(all)
		fun getSecondaryMarketplaceFee(): UFix64
	}
	
	access(all)
	resource SuperAdmin: ISuperAdminStoreFrontPublic{ 
		access(all)
		var storeFront: @NFTStorefront.Storefront
		
		access(all)
		var adminRef: @{UInt64: StoreFront.Admin}
		
		access(all)
		var fee: UFix64
		
		init(databaseID: String){ 
			self.storeFront <- NFTStorefront.createStorefront()
			self.adminRef <-{} 
			self.adminRef[0] <-! StoreFront.createStoreFrontAdmin()
			self.fee = 0.0
			emit StoreFrontCreated(databaseID: databaseID)
		}
		
		access(all)
		fun getStoreFront(): &NFTStorefront.Storefront{ 
			return &self.storeFront as &NFTStorefront.Storefront
		}
		
		access(all)
		fun getStoreFrontPublic(): &NFTStorefront.Storefront{ 
			return &self.storeFront as &NFTStorefront.Storefront
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
	fun createSuperAdmin(databaseID: String): @SuperAdmin{ 
		return <-create SuperAdmin(databaseID: databaseID)
	}
	
	init(){ 
		// Paths
		self.storeFrontAdminReceiverPublicPath = /public/AdminTokenReceiver0xb7ff7d2e1d4e86a0
		self.storeFrontAdminReceiverStoragePath = /storage/AdminTokenReceiver0xb7ff7d2e1d4e86a0
		emit ContractInitialized()
	}
}
