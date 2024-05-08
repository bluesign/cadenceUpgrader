// SPDX-License-Identifier: Unlicense
// import NonFungibleToken from "../"./NonFungibleToken.cdc"/NonFungibleToken.cdc"
// import NFTStorefront from "../"./NFTStorefront.cdc"/NFTStorefront.cdc"
// import StoreFront from "../"./StoreFront.cdc"/StoreFront.cdc"
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StoreFront, NFTStorefront from 0x4e1a246d0753fe0e

// TOKEN RUNNERS: Contract responsable for Admin and Super admin permissions
access(all)
contract StoreFrontAdmin{ 
	// -----------------------------------------------------------------------
	// StoreFrontAdmin contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The next NFT ID that is used to create NFT. 
	// Every time a NFT is created, nextNFTId is assigned 
	// to the new NFT's ID and then is incremented by 1.
	access(account)
	var nextStoreFrontId: UInt64
	
	/// Path where the `Admin` is stored
	access(all)
	let storageFrontStoragePath: StoragePath
	
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
	event StoreFrontCreated(storeFrontId: UInt64, databaseID: String)
	
	// -----------------------------------------------------------------------
	// StoreFrontAdmin contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// ----------------------------------------------------------------------- 
	// StoreFrontAdmin is a resource that storefront creator has
	// to mint NFT and create templates
	// 
	access(all)
	resource Admin{ 
		access(contract)
		let storeFrontId: UInt64
		
		init(storeFrontId: UInt64){ 
			self.storeFrontId = storeFrontId
		}
		
		access(all)
		fun mintNFT(templateId: UInt64, databaseID: String, hashMetadata: String): @StoreFront.NFT{ 
			pre{ 
				(StoreFront.getTemplate(templateId: templateId)!).storeFrontId == self.storeFrontId:
					"can't mint template from other store front"
			}
			return <-StoreFront.mintNFT(
				templateId: templateId,
				databaseID: databaseID,
				hashMetadata: hashMetadata
			)
		}
		
		access(all)
		fun createTemplate(
			storeFrontId: UInt64,
			metadata:{ 
				String: String
			},
			maxEditions: UInt64,
			creationDate: UInt64
		): UInt64{ 
			pre{ 
				storeFrontId == self.storeFrontId:
					"can't create template to other store front"
			}
			return StoreFront.createTemplate(
				storeFrontId: storeFrontId,
				metadata: metadata,
				maxEditions: maxEditions,
				creationDate: creationDate
			)
		}
		
		access(all)
		fun updateMetadata(templateId: UInt64, metadata:{ String: String}){ 
			pre{ 
				(StoreFront.getTemplate(templateId: templateId)!).storeFrontId == self.storeFrontId:
					"can't update template from other store front"
			}
			StoreFront.updateMetadata(templateId: templateId, metadata: metadata)
		}
	}
	
	access(all)
	resource interface ISuperAdminStoreFrontPublic{ 
		access(all)
		fun getStoreFrontPublic(): &NFTStorefront.Storefront
	}
	
	access(all)
	resource SuperAdmin: ISuperAdminStoreFrontPublic{ 
		access(all)
		let storeFrontId: UInt64
		
		access(all)
		let storeFront: @NFTStorefront.Storefront
		
		access(contract)
		var adminRef: @{UInt64: Admin}
		
		init(databaseID: String){ 
			self.storeFrontId = StoreFrontAdmin.nextStoreFrontId
			self.storeFront <- NFTStorefront.createStorefront()
			self.adminRef <-{} 
			self.adminRef[0] <-! create Admin(storeFrontId: self.storeFrontId)
			StoreFrontAdmin.nextStoreFrontId = StoreFrontAdmin.nextStoreFrontId + UInt64(1)
			emit StoreFrontCreated(storeFrontId: self.storeFrontId, databaseID: databaseID)
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
		fun withdrawAdmin(): @Admin{ 
			let token <- self.adminRef.remove(key: 0) ?? panic("Cannot withdraw admin resource")
			return <-token
		}
	}
	
	access(all)
	resource interface AdminTokenReceiverPublic{ 
		access(all)
		fun receiveAdmin(storeFrontId: UInt64, adminRef: Capability<&Admin>)
		
		access(all)
		fun receiveSuperAdmin(storeFrontId: UInt64, superAdminRef: Capability<&SuperAdmin>)
	}
	
	access(all)
	resource AdminTokenReceiver: AdminTokenReceiverPublic{ 
		access(self)
		var adminRef:{ UInt64: Capability<&Admin>}
		
		access(self)
		var superAdminRef:{ UInt64: Capability<&SuperAdmin>}
		
		init(){ 
			self.adminRef ={} 
			self.superAdminRef ={} 
		}
		
		access(all)
		fun receiveAdmin(storeFrontId: UInt64, adminRef: Capability<&Admin>){ 
			self.adminRef[storeFrontId] = adminRef
		}
		
		access(all)
		fun receiveSuperAdmin(storeFrontId: UInt64, superAdminRef: Capability<&SuperAdmin>){ 
			self.superAdminRef[storeFrontId] = superAdminRef
		}
		
		access(all)
		fun getAdminRef(storeFrontId: UInt64): &Admin?{ 
			return (self.adminRef[storeFrontId]!).borrow()
		}
		
		access(all)
		fun getSuperAdminRef(storeFrontId: UInt64): &SuperAdmin?{ 
			return (self.superAdminRef[storeFrontId]!).borrow()
		}
	}
	
	// -----------------------------------------------------------------------
	// StoreFrontAdmin contract-level function definitions
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
		self.storageFrontStoragePath = /storage/StoreFrontAdmin
		self.storeFrontAdminReceiverPublicPath = /public/AdminTokenReceiver
		self.storeFrontAdminReceiverStoragePath = /storage/AdminTokenReceiver
		self.nextStoreFrontId = 1
		emit ContractInitialized()
	}
}
