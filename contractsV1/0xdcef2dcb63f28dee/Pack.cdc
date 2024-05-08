// SPDX-License-Identifier: Apache License 2.0
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Elvn from "../0x6292b23b3eb3f999/Elvn.cdc"

import Moments from "../0x6292b23b3eb3f999/Moments.cdc"

access(all)
contract Pack{ 
	// payment
	access(self)
	let vault: @Elvn.Vault
	
	// releaseId: [Pack]
	// Pack: [Moments]
	access(self)
	let salePacks: @{UInt64: [Pack.Token]}
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	event BuyPack(packId: UInt64, price: UFix64)
	
	access(all)
	event OpenPack(packId: UInt64, momentsIds: [UInt64], address: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	resource Token{ 
		access(all)
		let id: UInt64
		
		access(all)
		let releaseId: UInt64
		
		access(all)
		let price: UFix64
		
		access(self)
		let momentsMap: @[Moments.NFT]
		
		access(all)
		fun openPacks(): @[Moments.NFT]{ 
			pre{ 
				self.momentsMap.length > 0:
					"There are no moments in the pack"
			}
			let map: @[Moments.NFT] <- []
			let momentsIds: [UInt64] = []
			while self.momentsMap.length > 0{ 
				let moment <- self.momentsMap.removeFirst()
				momentsIds.append(moment.id)
				map.append(<-moment)
			}
			emit OpenPack(packId: self.id, momentsIds: momentsIds, address: self.owner?.address)
			return <-map
		}
		
		init(tokenId: UInt64, releaseId: UInt64, price: UFix64, momentsMap: @[Moments.NFT]){ 
			self.id = tokenId
			self.releaseId = releaseId
			self.price = price
			self.momentsMap <- momentsMap
		}
	}
	
	access(all)
	resource interface MomentsCollectionPublic{ 
		access(all)
		fun getIds(): [UInt64]
	}
	
	access(all)
	resource Collection: MomentsCollectionPublic{ 
		access(all)
		var ownedPacks: @{UInt64: Pack.Token}
		
		access(all)
		fun getIds(): [UInt64]{ 
			return self.ownedPacks.keys
		}
		
		access(all)
		fun withdraw(withdrawID: UInt64): @Pack.Token{ 
			let token <- self.ownedPacks.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @Pack.Token){ 
			let id: UInt64 = token.id
			self.ownedPacks[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		init(){ 
			self.ownedPacks <-{} 
		}
	}
	
	access(all)
	view fun isNonExists(releaseId: UInt64): Bool{ 
		return self.salePacks[releaseId] == nil
	}
	
	access(all)
	fun buyPack(releaseId: UInt64, vault: @{FungibleToken.Vault}): @Pack.Token{ 
		pre{ 
			!self.isNonExists(releaseId: releaseId):
				"Not found releaseId: ".concat(releaseId.toString())
		}
		let balance = vault.balance
		self.vault.deposit(from: <-vault)
		let packsRef = &self.salePacks[releaseId] as &[Pack.Token]?
		if packsRef.length == 0{ 
			return panic("Sold out pack")
		}
		let packRef = &packsRef[0] as &Pack.Token
		if packRef.price > balance{ 
			return panic("Not enough vault balance")
		}
		let salePacks <- self.salePacks.remove(key: releaseId) ?? panic("unreachable")
		let randomIndex = revertibleRandom<UInt64>() % UInt64(packsRef.length)
		let pack <- salePacks.remove(at: randomIndex)
		self.salePacks[releaseId] <-! salePacks
		emit BuyPack(packId: pack.id, price: pack.price)
		return <-pack
	}
	
	access(all)
	fun getPackRemainingCount(releaseId: UInt64): Int{ 
		pre{ 
			!self.isNonExists(releaseId: releaseId):
				"Not found releaseId: ".concat(releaseId.toString())
		}
		let packsRef = &self.salePacks[releaseId] as &[Pack.Token]?
		return packsRef.length
	}
	
	access(all)
	fun getPackPrice(releaseId: UInt64): UFix64{ 
		pre{ 
			!self.isNonExists(releaseId: releaseId):
				"Not found releaseId: ".concat(releaseId.toString())
		}
		let packsRef = &self.salePacks[releaseId] as &[Pack.Token]?
		if packsRef.length == 0{ 
			return panic("Sold out pack")
		}
		let packRef = &packsRef[0] as &Pack.Token
		return packRef.price
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun addPack(token: @Pack.Token){ 
			let releaseId = token.releaseId
			if Pack.salePacks[releaseId] == nil{ 
				let packs: @[Pack.Token] <- [<-token]
				Pack.salePacks[releaseId] <-! packs
				return
			}
			let packPrice = Pack.getPackPrice(releaseId: releaseId)
			if packPrice != token.price{ 
				destroy token
				return panic("Pack price is not equal")
			}
			let packs <- Pack.salePacks.remove(key: releaseId) ?? panic("unreachable")
			packs.append(<-token)
			Pack.salePacks[releaseId] <-! packs
		}
		
		access(all)
		fun createPackToken(
			releaseId: UInt64,
			price: UFix64,
			momentsMap: @[
				Moments.NFT
			]
		): @Pack.Token{ 
			let pack <-
				create Pack.Token(
					tokenId: Pack.totalSupply,
					releaseId: releaseId,
					price: price,
					momentsMap: <-momentsMap
				)
			Pack.totalSupply = Pack.totalSupply + 1
			return <-pack
		}
		
		access(all)
		fun withdraw(amount: UFix64?): @{FungibleToken.Vault}{ 
			if let amount = amount{ 
				return <-Pack.vault.withdraw(amount: amount)
			} else{ 
				let balance = Pack.vault.balance
				return <-Pack.vault.withdraw(amount: balance)
			}
		}
	}
	
	access(all)
	fun createEmptyCollection(): @Pack.Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/sportiumPackCollection
		self.CollectionPublicPath = /public/sportiumPackCollection
		self.salePacks <-{} 
		self.vault <- Elvn.createEmptyVault(vaultType: Type<@Elvn.Vault>()) as! @Elvn.Vault
		self.totalSupply = 0
		self.account.storage.save(<-create Administrator(), to: /storage/sportiumPackAdministrator)
	}
}
