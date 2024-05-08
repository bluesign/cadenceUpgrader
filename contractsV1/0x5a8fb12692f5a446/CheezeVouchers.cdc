import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import CheezeNFT from "./CheezeNFT.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract CheezeVouchers{ 
	access(all)
	var totalVoucherSupply: UInt64
	
	access(self)
	var cutPercent: UFix64
	
	access(self)
	var cutReceiver: Capability<&FUSD.Vault>
	
	access(self)
	var listings:{ UInt64: ListingDetails}
	
	access(self)
	var storedNFTs: @{UInt64: [CheezeNFT.NFT]}
	
	access(self)
	var vouchersAvailable:{ UInt64: UInt64}
	
	access(self)
	var voucherUsed:{ UInt64: Bool}
	
	access(all)
	event ListingCreated(listingId: UInt64)
	
	access(all)
	event VoucherBought(voucherId: UInt64)
	
	access(all)
	event VoucherFulfilled(nftId: UInt64, voucherId: UInt64, listingId: UInt64)
	
	access(all)
	event DepositVoucher(voucherId: UInt64)
	
	access(all)
	resource Voucher{ 
		access(all)
		let id: UInt64
		
		access(all)
		let listingId: UInt64
		
		init(id: UInt64, listingId: UInt64){ 
			self.id = id
			self.listingId = listingId
		}
	}
	
	access(all)
	resource VoucherCollection{ 
		access(contract)
		var ownedVouchers: @{UInt64: Voucher}
		
		access(all)
		fun deposit(voucher: @Voucher){ 
			let id: UInt64 = voucher.id
			// add the new token to the dictionary which removes the old one
			let oldVoucher <- self.ownedVouchers[id] <- voucher
			emit DepositVoucher(voucherId: id)
			destroy oldVoucher
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.ownedVouchers.keys
		}
		
		access(all)
		fun listingIdForVoucherWithId(voucherId: UInt64): UInt64{ 
			pre{ 
				self.ownedVouchers.keys.contains(voucherId)
			}
			post{ 
				self.ownedVouchers.keys.contains(voucherId)
			}
			let voucherRef = (&self.ownedVouchers[voucherId] as &Voucher?)!
			return voucherRef.listingId
		}
		
		init(){ 
			self.ownedVouchers <-{} 
		}
	}
	
	access(all)
	resource Administrator{ 
		access(all)
		fun fulfillVoucher(address: Address, voucherId: UInt64, random: UInt64){ 
			pre{ 
				(getAccount(address).capabilities.get<&CheezeVouchers.VoucherCollection>(/public/VoucherCollection).borrow()!).getIDs().contains(voucherId)
				!CheezeVouchers.voucherUsed[voucherId]!
			}
			post{ 
				CheezeVouchers.voucherUsed[voucherId]!
			}
			let voucherCollection =
				getAccount(address).capabilities.get<&CheezeVouchers.VoucherCollection>(
					/public/VoucherCollection
				).borrow()!
			let listingId = voucherCollection.listingIdForVoucherWithId(voucherId: voucherId)
			let stored <- CheezeVouchers.storedNFTs.remove(key: listingId)!
			let randomNftIndex = random % UInt64(stored.length)
			let token <- stored.remove(at: randomNftIndex)
			let nftId = token.id
			let receiver =
				getAccount(address).capabilities.get<&CheezeNFT.Collection>(
					/public/CheezeNFTReceiver
				).borrow()!
			receiver.deposit(token: <-token)
			CheezeVouchers.voucherUsed[voucherId] = true
			emit VoucherFulfilled(nftId: nftId, voucherId: voucherId, listingId: listingId)
			CheezeVouchers.storedNFTs[listingId] <-! stored
		}
	}
	
	access(all)
	resource ListingCreator{ 
		access(all)
		let listingId: UInt64
		
		access(all)
		var nfts: @[CheezeNFT.NFT]
		
		init(price: UFix64, sellerPaymentReceiver: Capability<&FUSD.Vault>){ 
			self.listingId = UInt64(CheezeVouchers.listings.length) + 1
			self.nfts <- []
			CheezeVouchers.listings[self.listingId] = ListingDetails(
					listingId: self.listingId,
					price: price,
					sellerPaymentReceiver: sellerPaymentReceiver
				)
		}
		
		access(all)
		fun putOnSale(tokens: @[CheezeNFT.NFT]){ 
			var i = 0 as UInt64
			let len = tokens.length
			while i < UInt64(len){ 
				let nft <- tokens.removeFirst()
				self.nfts.append(<-nft)
				i = i + 1
			}
			destroy tokens
		}
	}
	
	access(all)
	struct ListingDetails{ 
		access(all)
		var listingId: UInt64
		
		access(all)
		var price: UFix64
		
		access(all)
		var sellerPaymentReceiver: Capability<&FUSD.Vault>
		
		init(listingId: UInt64, price: UFix64, sellerPaymentReceiver: Capability<&FUSD.Vault>){ 
			self.listingId = listingId
			self.price = price
			self.sellerPaymentReceiver = sellerPaymentReceiver
		}
	}
	
	access(all)
	view fun priceFor(listingId: UInt64): UFix64{ 
		return (self.listings[listingId]!).price
	}
	
	access(all)
	view fun availableVouchers(listingId: UInt64): UInt64{ 
		return self.vouchersAvailable[listingId]!
	}
	
	access(all)
	fun buyVoucher(listingId: UInt64, payment: @FUSD.Vault): @CheezeVouchers.Voucher{ 
		pre{ 
			payment.balance == self.priceFor(listingId: listingId)
			self.availableVouchers(listingId: listingId) > 0
		}
		self.vouchersAvailable[listingId] = self.vouchersAvailable[listingId]! - 1
		let price = self.priceFor(listingId: listingId)
		let listing = self.listings[listingId]!
		let receiver = listing.sellerPaymentReceiver.borrow()!
		
		// Move money
		let beneficiaryCut <- payment.withdraw(amount: price * self.cutPercent)
		(self.cutReceiver.borrow()!).deposit(from: <-beneficiaryCut)
		receiver.deposit(from: <-payment)
		
		// Actually create Voucher
		self.totalVoucherSupply = self.totalVoucherSupply + 1
		let id = self.totalVoucherSupply
		emit VoucherBought(voucherId: id)
		self.voucherUsed[id] = false
		return <-create Voucher(id: id, listingId: listingId)
	}
	
	access(all)
	fun createEmptyCollection(): @VoucherCollection{ 
		return <-create VoucherCollection()
	}
	
	access(all)
	fun createListingCreator(
		price: UFix64,
		sellerPaymentReceiver: Capability<&FUSD.Vault>
	): @ListingCreator{ 
		return <-create ListingCreator(price: price, sellerPaymentReceiver: sellerPaymentReceiver)
	}
	
	init(){ 
		self.totalVoucherSupply = 0
		self.listings ={} 
		self.storedNFTs <-{} 
		self.vouchersAvailable ={} 
		self.voucherUsed ={} 
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: /storage/cheezeVouchersAdmin)
		self.cutReceiver = self.account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)!
		self.cutPercent = 0.25
	}
}
