import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import REVV from "./REVV.cdc"

// The REVVVaultAccess contract's role is to allow the REVV contract account owner ('REVV owner')
// to grant other accounts ('other account') access to withdraw REVV from the REVV owner's REVV vault
// while imposing the conditions that:
// [+] there is a max withdrawal limit per other account and,
// [+] access to the REVV owner vault can be revoked by the REVV owner.
//
// The other account can in this way independently withdraw REVV from the REVV owner's vault,
// without the need for multi-sig transactions, or REVV owner sending a transfer transaction.
//
// The immediate use case is for the TeleportCustody operator account to be able to withdraw REVV
// from the REVV owner REVV Vault when they need to top up the TeleportCustody contract, without having to ask
// the REVV owner for a transfer.
//
// The VaultProxy and VaultGuard are based on the FUSD contract's MinterProxy and Minter design.
//
// How to use the contract:
// * The REVV vault owner creates a VaultGuard resource with a max amount and an address for the other account that will withdraw the REVV.
// * The other account creates and saves a VaultProxy resource
// * The REVV owner sets the VaultGuard capability on the VaultProxy
// * The other account can now withdraw REVV
// * The REVV owner can revoke access at any time by unlinking the VaultGuard capability
//
access(all)
contract REVVVaultAccess{ 
	
	// The storage path for the Proxy Vault
	access(all)
	let VaultProxyStoragePath: StoragePath
	
	// The public path for the Proxy Vault
	access(all)
	let VaultProxyPublicPath: PublicPath
	
	// The storage path for the REVV contract Admin
	access(all)
	let AdminStoragePath: StoragePath
	
	// The amount of REVV authorized for Vault Guards
	access(all)
	var totalAuthorizedAmount: UFix64
	
	// Dictionary to store a (VaultProxy address) -> (VaultGuard paths) map
	// The registry helps answer which guards match which proxy.
	//
	access(contract)
	let proxyToGuardMap:{ Address: VaultGuardPaths}
	
	// Dictionary to store a (VaultGuard paths) -> (VaultProxy Address) map
	// The registry helps answer which proxy owners match which guard
	//
	access(contract)
	let guardToProxyMap:{ StoragePath: Address}
	
	// Struct used to store paths for a Vault
	// Should be saved in a dictionary with VaultProxy as key
	//
	access(all)
	struct VaultGuardPaths{ 
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let privatePath: PrivatePath
		
		init(storagePath: StoragePath, privatePath: PrivatePath){ 
			self.storagePath = storagePath
			self.privatePath = privatePath
		}
	}
	
	// VaultGuard
	//
	// The VaultGuard's role is to be the source of a revokable link to the account's REVV vault.
	//
	access(all)
	resource VaultGuard{ 
		
		// max is the largest total amount that can be withdrawn using the VaultGuard
		//
		access(all)
		let max: UFix64
		
		// total keeps track of how much has been withdrawn via the VaultGuard
		//
		access(all)
		var total: UFix64
		
		// A reference to the vault that holds REVV tokens
		//
		access(self)
		let vaultCapability: Capability<&REVV.Vault>
		
		// withdraws REVV tokens from the VaultGuard's internal vault reference
		// Will fail if vault reference is nil / revoked, or amount + previously withdrawn exceeds max
		//
		access(all)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount + self.total <= self.max:
					"total of amount + previously withdrawn exceeds max withdrawal."
			}
			self.total = self.total + amount
			return <-(self.vaultCapability.borrow()!).withdraw(amount: amount)
		}
		
		// constructor - takes a REVV vault reference, and a max withdrawal amount
		//
		init(vaultCapability: Capability<&REVV.Vault>, max: UFix64){ 
			pre{ 
				max > 0.0:
					"VaultGuard max needs to be greater than zero"
				vaultCapability != nil:
					"vaultCapability is nil in REVV.VaultGuard constructor"
			}
			self.vaultCapability = vaultCapability
			self.max = max
			self.total = UFix64(0.0)
		}
	}
	
	// createVaultGuard
	//
	// @param adminRef - a reference to a REVVVaultAccess.Admin. Only accessible to contract account
	// @param vaultProxyAddress - the account address where the VaultProxy will be stored
	// @param maxAmount - the max amount of REVV which VaultGuard will allow the VaultProxy to transfer
	// @param guardStoragePath - the storage path in the REVVVaultAccess contract owner account
	// @param guardPrivatePath - the private path linked to the guardStoragePath
	// 
	access(all)
	fun createVaultGuard(
		adminRef: &Admin,
		vaultProxyAddress: Address,
		maxAmount: UFix64,
		guardStoragePath: StoragePath,
		guardPrivatePath: PrivatePath
	){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
			self.totalAuthorizedAmount + maxAmount <= REVV.MAX_SUPPLY:
				"Requested max amount + previously authorized amount exceeds max supply"
			self.proxyToGuardMap.containsKey(vaultProxyAddress) == false:
				"VaultProxy Address already registered"
			self.guardToProxyMap.containsKey(guardStoragePath) == false:
				"VaultGuard StoragePath already registered"
		}
		self.totalAuthorizedAmount = self.totalAuthorizedAmount + maxAmount
		let vaultCapability = self.account.capabilities.get<&REVV.Vault>(REVV.RevvVaultPrivatePath)
		let _guard <- create VaultGuard(vaultCapability: vaultCapability!, max: maxAmount)
		self.account.storage.save(<-_guard, to: guardStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&VaultGuard>(guardStoragePath)
		self.account.capabilities.publish(capability_1, at: guardPrivatePath)
		let pathObject =
			VaultGuardPaths(storagePath: guardStoragePath, privatePath: guardPrivatePath)
		self.proxyToGuardMap.insert(key: vaultProxyAddress, pathObject)
		self.guardToProxyMap.insert(key: guardStoragePath, vaultProxyAddress)
	}
	
	// getVaultGuardPaths returns storage path and private path for a VaultGuard
	// @param account address of VaultProxy using the VaultGuard
	//
	access(all)
	fun getVaultGuardPaths(vaultProxyAddress: Address): VaultGuardPaths?{ 
		return self.proxyToGuardMap[vaultProxyAddress]
	}
	
	// getVaultProxyAddress returns an address of a VaultProxy
	// @param the storage path of the VaultGuard used by the VaultProxy
	//
	access(all)
	fun getVaultProxyAddress(guardStoragePath: StoragePath): Address?{ 
		return self.guardToProxyMap[guardStoragePath]
	}
	
	// returns all VaultProxy addresses
	//
	access(all)
	fun getAllVaultProxyAddresses(): [Address]{ 
		return self.proxyToGuardMap.keys
	}
	
	// returns all storage paths for VaultGuards
	//
	access(all)
	fun getAllVaultGuardStoragePaths(): [StoragePath]{ 
		return self.guardToProxyMap.keys
	}
	
	// returns max authorized amount of withdrawal for an account address
	//
	access(all)
	fun getMaxAmountForAccount(vaultProxyAddress: Address): UFix64{ 
		let paths = self.proxyToGuardMap[vaultProxyAddress]!
		let capability =
			self.account.capabilities.get<&REVVVaultAccess.VaultGuard>(paths.privatePath)
		let vaultRef = capability.borrow()!
		return vaultRef.max
	}
	
	// returns total withdrawn amount for an account address
	//
	access(all)
	fun getTotalAmountForAccount(vaultProxyAddress: Address): UFix64{ 
		let paths = self.proxyToGuardMap[vaultProxyAddress]!
		let capability =
			self.account.capabilities.get<&REVVVaultAccess.VaultGuard>(paths.privatePath)
		let vaultRef = capability.borrow()!
		return vaultRef.total
	}
	
	// revokes withdrawal capability for an account
	//
	access(all)
	fun revokeVaultGuard(adminRef: &Admin, vaultProxyAddress: Address){ 
		pre{ 
			adminRef != nil:
				"adminRef is nil"
		}
		let paths = self.getVaultGuardPaths(vaultProxyAddress: vaultProxyAddress)!
		self.account.unlink(paths.privatePath)
		
		//remove from maps
		self.proxyToGuardMap.remove(key: vaultProxyAddress)
		self.guardToProxyMap.remove(key: paths.storagePath)
		
		//delete guard
		let _guard <-
			self.account.storage.load<@REVVVaultAccess.VaultGuard>(from: paths.storagePath)!
		self.totalAuthorizedAmount = self.totalAuthorizedAmount - _guard.max
		destroy _guard
	}
	
	// interface which allows setting of VaultGuard capability
	//
	access(all)
	resource interface VaultProxyPublic{ 
		access(all)
		fun setCapability(cap: Capability<&REVVVaultAccess.VaultGuard>)
	}
	
	// VaultProxy is a resource to allow designated other accounts to retrieve REVV from the REVV contract's REVV vault.
	// Any account can call createVaultProxy() to create a VaultProxy, but only if REVV account calls setCapability
	// on the VaultProxy, can REVV be withdrawn
	//
	access(all)
	resource VaultProxy: VaultProxyPublic{ 
		access(self)
		var vaultGuardCap: Capability<&REVVVaultAccess.VaultGuard>?
		
		// withdraw REVV. ***MUST** be kept private / non-publicly accessible after setCapability has been called
		// Will fail unless REVV contract account has set a capability using setCapability
		//
		access(all)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				(self.vaultGuardCap!).check() == true:
					"Can't withdraw. vaultGuardCap.check() failed"
			}
			let cap = (self.vaultGuardCap!).borrow()
			return <-(cap!).withdraw(amount: amount)
		}
		
		// set a REVV.VaultGuard capability, to allow withdrawal.
		// Only the REVV contract account can create a VaultGuard so the method can be publicly accessible.
		// 
		access(all)
		fun setCapability(cap: Capability<&REVVVaultAccess.VaultGuard>){ 
			pre{ 
				cap.check() == true:
					"Capability<&REVV.VaultGuard> failed check()"
				cap != nil:
					"Setting Capability<&REVV.VaultGuard> that is nil"
			}
			self.vaultGuardCap = cap
		}
		
		init(){ 
			self.vaultGuardCap = nil
		}
	}
	
	// Anyone can create a VaultProxy but it's useless until the Vault Guard capability is set on it.
	// Only the REVVVaultAccess owner can create and set a VaultGuard capability
	//
	access(all)
	fun createVaultProxy(): @REVVVaultAccess.VaultProxy{ 
		return <-create VaultProxy()
	}
	
	// Admin resource
	//
	access(all)
	resource Admin{} 
	
	init(){ 
		self.totalAuthorizedAmount = UFix64(0)
		self.proxyToGuardMap ={} 
		self.guardToProxyMap ={} 
		self.VaultProxyStoragePath = /storage/revvVaultProxy
		self.VaultProxyPublicPath = /public/revvVaultProxy
		self.AdminStoragePath = /storage/revvVaultAccessAdmin
		
		// create an Admin and save it in storage
		//
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
