/**
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import AnchainUtils from "../0x7ba45bdcac17806a/AnchainUtils.cdc"

// MetaPandaVoucher
// NFT items for MetaPandaVoucher!
//
access(all)
contract MetaPandaVoucher: NonFungibleToken{ 
	
	// Standard Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata: Metadata)
	
	// Redeemed
	// Fires when a user redeems a voucher, prepping
	// it for consumption to receive a reward
	//
	access(all)
	event Redeemed(id: UInt64, redeemer: Address)
	
	// Consumed
	// Fires when an Admin consumes a voucher, deleting
	// it forever
	//
	access(all)
	event Consumed(id: UInt64)
	
	// redeemers
	// Tracks all accounts that have redeemed a voucher 
	//
	access(contract)
	let redeemers:{ UInt64: Address}
	
	// Named Paths
	//
	access(all)
	let RedeemedCollectionStoragePath: StoragePath
	
	access(all)
	let RedeemedCollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// totalSupply
	// The total number of MetaPandaVoucher that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// MetaPandaVoucher Metadata
	//
	access(all)
	struct Metadata{ 
		// Metadata is kept as flexible as possible so we can introduce 
		// any type of sale conditions we want and enforce these off-chain.
		// It would be great to eventually move this validation on-chain.
		access(all)
		let details:{ String: String}
		
		init(details:{ String: String}){ 
			self.details = details
		}
	}
	
	// MetaPandaVoucherView
	//
	access(all)
	struct MetaPandaVoucherView{ 
		access(all)
		let uuid: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let file: AnchainUtils.File
		
		init(uuid: UInt64, id: UInt64, metadata: Metadata, file: AnchainUtils.File){ 
			self.uuid = uuid
			self.id = id
			self.metadata = metadata
			self.file = file
		}
	}
	
	// NFT
	// A MetaPandaVoucher as an NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's metadata
		access(all)
		let metadata: Metadata
		
		// The token's file
		access(all)
		let file: AnchainUtils.File
		
		// initializer
		//
		init(id: UInt64, metadata: Metadata, file: AnchainUtils.File){ 
			self.id = id
			self.metadata = metadata
			self.file = file
		}
		
		// getViews
		// Returns a list of ways to view this NFT.
		//
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetaPandaVoucherView>(), Type<AnchainUtils.File>()]
		}
		
		// resolveView
		// Returns a particular view of this NFT.
		//
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "MetaPandaVoucher ".concat(self.id.toString()), description: "", thumbnail: self.file.thumbnail)
				case Type<MetaPandaVoucherView>():
					return MetaPandaVoucherView(uuid: self.uuid, id: self.id, metadata: self.metadata, file: self.file)
				case Type<AnchainUtils.File>():
					return self.file
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Collection
	// A collection of MetaPandaVoucher NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, AnchainUtils.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an 'UInt64' ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// borrowViewResolverSafe
		//
		access(all)
		fun borrowViewResolverSafe(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] != nil{ 
				let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				if nft != nil{ 
					return nft! as! &MetaPandaVoucher.NFT as &{ViewResolver.Resolver}
				}
			}
			return nil
		}
		
		// borrowViewResolver
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] != nil{ 
				let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				if nft != nil{ 
					return nft! as! &MetaPandaVoucher.NFT as &{ViewResolver.Resolver}
				}
			}
			panic("NFT not found in collection.")
		}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MetaPandaVoucher.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return nft
			}
			panic("NFT not found in collection.")
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// destructor
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// NFTMinter
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT
		// Mints a new NFT with a new ID and deposits it in the recipients 
		// collection using their collection reference
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: Metadata, file: AnchainUtils.File){ 
			emit Minted(id: MetaPandaVoucher.totalSupply, metadata: metadata)
			recipient.deposit(token: <-create MetaPandaVoucher.NFT(id: MetaPandaVoucher.totalSupply, metadata: metadata, file: file))
			MetaPandaVoucher.totalSupply = MetaPandaVoucher.totalSupply + 1 as UInt64
		}
		
		// consume
		// Consumes a voucher from the redeemed collection by destroying it
		//
		access(all)
		fun consume(_ voucherID: UInt64): Address{ 
			// Obtain a reference to the redeemed collection
			let redeemedCollection = MetaPandaVoucher.account.storage.borrow<&MetaPandaVoucher.Collection>(from: MetaPandaVoucher.RedeemedCollectionStoragePath)!
			
			// Burn the voucher
			destroy <-redeemedCollection.withdraw(withdrawID: voucherID)
			
			// Let event listeners know that this voucher has been consumed
			emit Consumed(id: voucherID)
			return MetaPandaVoucher.redeemers.remove(key: voucherID)!
		}
	}
	
	// createEmptyCollection
	// A public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// redeem
	// This public function represents the core feature of this contract: redemptions.
	// The NFTs, aka vouchers, can be 'redeemed' into the RedeemedCollection. The admin
	// can then consume these in exchange for merchandise.
	//
	access(all)
	fun redeem(collection: &MetaPandaVoucher.Collection, voucherID: UInt64){ 
		// Withdraw the voucher
		let token <- collection.withdraw(withdrawID: voucherID)
		
		// Get a reference to our redeemer collection
		let receiver = MetaPandaVoucher.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(MetaPandaVoucher.RedeemedCollectionPublicPath).borrow<&{NonFungibleToken.CollectionPublic}>()!
		
		// Deposit the voucher for consumption
		receiver.deposit(token: <-token)
		
		// Store who redeemed this voucher
		MetaPandaVoucher.redeemers[voucherID] = (collection.owner!).address
		emit Redeemed(id: voucherID, redeemer: (collection.owner!).address)
	}
	
	// getRedeemers
	// Return the redeemers dictionary
	//
	access(all)
	fun getRedeemers():{ UInt64: Address}{ 
		return self.redeemers
	}
	
	// initializer
	//
	init(){ 
		// Set our named paths
		self.RedeemedCollectionStoragePath = /storage/MetaPandaVoucherRedeemedCollection
		self.RedeemedCollectionPublicPath = /public/MetaPandaVoucherRedeemedCollection
		self.CollectionStoragePath = /storage/MetaPandaVoucherCollection
		self.CollectionPublicPath = /public/MetaPandaVoucherCollection
		self.MinterStoragePath = /storage/MetaPandaVoucherMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize redeemers mapping
		self.redeemers ={} 
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// Create a collection that users can place their redeemed vouchers in
		self.account.storage.save(<-create Collection(), to: self.RedeemedCollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, AnchainUtils.ResolverCollection}>(self.RedeemedCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.RedeemedCollectionPublicPath)
		
		// Create a personal collection just in case the contract ever holds vouchers to distribute later
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, AnchainUtils.ResolverCollection}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
