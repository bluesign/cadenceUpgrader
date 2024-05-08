/*
Code inspired from https://github.com/JambbTeam/flow-nft-vouchers
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NeoMember from "./NeoMember.cdc"

import NeoMotorcycle from "./NeoMotorcycle.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Clock from "./Clock.cdc"

import Debug from "./Debug.cdc"

access(all)
contract NeoVoucher: NonFungibleToken{ 
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, type: UInt64)
	
	// Redeemed
	// Fires when a user Redeems a NeoVoucher, prepping
	// it for Consumption to receive reward
	//
	access(all)
	event Redeemed(voucherId: UInt64, address: Address)
	
	// Consumed
	// Fires when an Admin consumes a NeoVoucher, deleting it forever
	// NOTE: Reward is not tracked. This is to simplify contract.
	//	   It is to be administered in the consume() tx, 
	//	   else thoust be punished by thine users.
	//
	access(all)
	event Consumed(voucherId: UInt64, address: Address, memberId: UInt64, teamId: UInt64, role: String, edition: UInt64, maxEdition: UInt64, name: String)
	
	access(all)
	event Purchased(voucherId: UInt64, address: Address, amount: UFix64)
	
	access(all)
	event Gifted(voucherId: UInt64, address: Address, full: Bool)
	
	access(all)
	event NotValidCollection(address: Address)
	
	// NeoVoucher Collection Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Contract-Singleton Redeemed NeoVoucher Collection
	access(all)
	let RedeemedCollectionPublicPath: PublicPath
	
	access(all)
	let RedeemedCollectionStoragePath: StoragePath
	
	// totalSupply
	// The total number of NeoVoucher that have been minted
	//
	access(all)
	var totalSupply: UInt64
	
	// metadata
	// the mapping of NeoVoucher TypeID's to their respective Metadata
	//
	access(contract)
	var metadata:{ UInt64: Metadata}
	
	// redeemed
	// tracks currently redeemed vouchers for consumption
	// 
	access(contract)
	var redeemers:{ UInt64: Address}
	
	// NeoVoucher Type Metadata Definitions
	// 
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// MIME type: image/png, image/jpeg, video/mp4, audio/mpeg
		access(all)
		let mediaType: String
		
		// IPFS storage hash
		access(all)
		let mediaHash: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let price: UFix64
		
		//time this voucher can be opened at, at the latest
		access(all)
		let timestamp: UFix64
		
		init(name: String, description: String, mediaType: String, mediaHash: String, thumbnailHash: String, wallet: Capability<&{FungibleToken.Receiver}>, price: UFix64, timestamp: UFix64){ 
			self.name = name
			self.description = description
			self.mediaType = mediaType
			self.mediaHash = mediaHash
			self.thumbnailHash = thumbnailHash
			self.wallet = wallet
			self.price = price
			self.timestamp = timestamp
		}
	}
	
	/// redeem(token)
	/// This public function represents the core feature of this contract: redemptions.
	/// The NFT's, aka NeoVoucher, can be 'redeemed' into the RedeemedCollection, which
	/// will ultimately consume them to the tune of an externally agreed-upon reward.
	///
	access(all)
	fun redeem(collection: &NeoVoucher.Collection, voucherID: UInt64){ 
		let voucher = collection.borrowNeoVoucher(id: voucherID) ?? panic("This neo voucher is already redeemed.")
		let whitelistAddresses = ["0xd2080c06c8b93c0d", "0x5a16175a09403578", "0x31b734c8bbe5aaf3", "0xb006f153b1a53923", "0x85561f8d3bb5ed83", "0xa0b1b3d713449442", "0x36ef378785835e55", "0xd4175c85b913863c", "0x478af2b5f727e631", "0xe1d5954d03ccb02d", "0x93fe10481d5622b9", "0x196c1869b10635b1", "0x63c213f549fa5d82", "0x549802c4c6edbd04", "0x36f060ab83303d5a", "0x5f662af6efe4a273", "0xf9e05616ccd4831a", "0x857057e5336d7dcb", "0x914d806bff9f23d0", "0x451459400329a010", "0x832fd1359b50835f", "0x3fd034c13156a6ce", "0xfa3a0fb4819829cc", "0x51664caf2b7550ef", "0x6935ca1cc29608cc", "0x197dc8d4db60e3a7", "0x3e30f7cb2559be1e", "0x90ffa96425ec2e08", "0xea0dd3503ce7b827", "0x423eb1ea3cf14f82", "0x46ace569ff52bd67", "0xe24b9226f4fc1ffa", "0xa1bf3abeb7619193", "0x66585205af7746e5", "0x59935060d6a1cda", "0x1e69c35662dfb96b", "0x5f60fb9ce5ec6bfb", "0x5fc4cbc0a52fce41", "0x3a7a2af28d43354b", "0xa7b4f0f556f7989e", "0xc8c7eeec9b78e7fb", "0x5ddd1e0585edacfe", "0x59d06d22a958fb1c", "0xf1e0feb1216b5368", "0x7f785e9ddaf68333", "0x26657b3e6a7e47b6", "0x73fba796d89d0595", "0xb8023f7992b2858d", "0x6b75d62f17e48230", "0x368b4f175831543a", "0x5a8585572de1d85e", "0x5d2fb230463fa6b", "0x9627d55ad751fdf3", "0xb5413e1c4dc81b05", "0x42921f1da9563ce4", "0x5159075e4cd4324c", "0x2c479c5c9eb30f", "0x33c221718d0b93ca", "0xef43af4dcc9214b6", "0x81f897e8b5dc9f9", "0x7d3610ad2540cef1", "0xb7ffae8d70d85dda", "0x1155112f813ac64d", "0x74a06f8b337a77da", "0x2c3122964f50851d", "0x8f6bf7a919bf4edb", "0x886f3aeaf848c535", "0xb759fca4b2aa2f13", "0xc861a006412c1cc5", "0xb1f5bbebfd57a833", "0x12f6eaad8e737997", "0x938e01c508336ef8", "0x1bdb509d15f75f37", "0x3358c97ffb850b8b", "0xb72631b47237f4a4", "0x42ec365ab5f89312", "0x8630fa754bf11151", "0x2a0eccae942667be", "0xc7927f3291a48a5b", "0x8628996576f79e0a", "0x16ae8f1cbfceaa9e", "0x746e3935e2426b77", "0xbceff658ef27516e", "0x6304124e48e9bbd9", "0xa4a7037a19f7bf06", "0xc6f1a47ac4b70d33", "0xb1f5bbebfd57a833", "0x92b86f833d10b222", "0xf485bc7c3d368579", "0x9627d55ad751fdf3", "0x345f3c44cc602464", "0xc861a006412c1cc5", "0x36f060ab83303d5a", "0xb1f5bbebfd57a833", "0x4d558e936031655d", "0xc749e848698d0725", "0xff5dfa61021d8d73"]
		var time = voucher.getMetadata().timestamp
		if whitelistAddresses.contains((collection.owner!).address.toString()){ 
			time = 1646510400.0
		}
		let timestamp = Clock.time()
		Debug.log("Current=".concat(timestamp.toString()).concat(" voucherTime=").concat(voucher.getMetadata().timestamp.toString()))
		if timestamp < time{ 
			panic("You cannot open the voucher yet")
		}
		
		// withdraw their voucher
		let token <- collection.withdraw(withdrawID: voucherID)
		
		// establish the receiver for Redeeming NeoVoucher
		let receiver = NeoVoucher.account.capabilities.get<&{NonFungibleToken.Receiver}>(NeoVoucher.RedeemedCollectionPublicPath).borrow()!
		
		// deposit for consumption
		receiver.deposit(token: <-token)
		
		// store who redeemed this voucher for consumer to reward
		NeoVoucher.redeemers[voucherID] = (collection.owner!).address
		emit Redeemed(voucherId: voucherID, address: (collection.owner!).address)
	}
	
	// NFT
	// NeoVoucher
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's typeID
		access(self)
		var typeID: UInt64
		
		// init
		//
		init(initID: UInt64, typeID: UInt64){ 
			self.id = initID
			self.typeID = typeID
		}
		
		access(contract)
		fun setTypeId(_ id: UInt64){ 
			self.typeID = id
		}
		
		access(all)
		fun getTypeID(): UInt64{ 
			return self.typeID
		}
		
		// Expose metadata of this NeoVoucher type
		//
		access(all)
		fun getMetadata(): Metadata{ 
			return NeoVoucher.metadata[self.typeID]!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<Metadata>(), Type<String>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = self.getMetadata()
			let file:{ MetadataViews.File} = MetadataViews.IPFSFile(cid: metadata.thumbnailHash, path: nil)
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: file)
				case Type<String>():
					return metadata.name
				case Type<NeoVoucher.Metadata>():
					return metadata
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun buy(vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>): UInt64
	}
	
	// Collection
	// A collection of NeoVoucher NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun buy(vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>): UInt64{ 
			pre{ 
				self.ownedNFTs.length != 0:
					"No more vouchers"
			}
			let vault <- vault as! @FlowToken.Vault
			let key = self.ownedNFTs.keys[0]
			let nftRef = self.borrowViewResolver(id: key)!
			let metadata = nftRef.resolveView(Type<Metadata>())! as! Metadata
			let amount = vault.balance
			var fullNFT = false
			if metadata.price != amount{ 
				if amount == 100.0{ 
					fullNFT = true
				} else{ 
					panic("Vault does not contain ".concat(metadata.price.toString()).concat(" amount of Flow"))
				}
			}
			(metadata.wallet.borrow()!).deposit(from: <-vault)
			let nft <- self.withdraw(withdrawID: key) as! @NFT
			if fullNFT{ 
				nft.setTypeId(2)
			}
			let token <- nft as @{NonFungibleToken.NFT}
			(collectionCapability.borrow()!).deposit(token: <-token)
			emit Purchased(voucherId: key, address: collectionCapability.address, amount: amount)
			return key
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
			let token <- token as! @NeoVoucher.NFT
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
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowNeoVoucher
		// Gets a reference to an NFT in the collection as a NeoVoucher.NFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the NeoVoucher.
		//
		access(all)
		fun borrowNeoVoucher(id: UInt64): &NeoVoucher.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NeoVoucher.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &NFT
			return exampleNFT
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
		//
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64){ 
		NeoVoucher.totalSupply = NeoVoucher.totalSupply + 1
		emit Minted(id: NeoVoucher.totalSupply, type: typeID)
		
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-create NeoVoucher.NFT(initID: NeoVoucher.totalSupply, typeID: typeID))
	}
	
	// batchMintNFT
	// Mints a batch of new NFTs
	// and deposits them in the recipients collection using their collection reference
	//
	access(account)
	fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, count: Int){ 
		var index = 0
		while index < count{ 
			self.mintNFT(recipient: recipient, typeID: typeID)
			index = index + 1
		}
	}
	
	// registerMetadata
	// Registers metadata for a typeID
	//
	access(account)
	fun registerMetadata(typeID: UInt64, metadata: Metadata){ 
		NeoVoucher.metadata[typeID] = metadata
	}
	
	// consume
	// consumes a NeoVoucher from the Redeemed Collection by destroying it
	// NOTE: it is expected the consumer also rewards the redeemer their due
	//		  in the case of this repository, an NFT is included in the consume transaction
	access(account)
	fun consume(voucherID: UInt64, rewardID: UInt64){ 
		
		// grab the voucher from the redeemed collection
		let redeemedCollection = NeoVoucher.account.storage.borrow<&NeoVoucher.Collection>(from: NeoVoucher.RedeemedCollectionStoragePath)!
		let voucher <- redeemedCollection.withdraw(withdrawID: voucherID) as! @NeoVoucher.NFT
		var fullVoucher = false
		if voucher.getTypeID() == 2{ 
			fullVoucher = true
		}
		// discard the empty collection and the voucher
		destroy voucher
		
		//the admin burns the voucher and sends the nft to the user
		let redeemer = NeoVoucher.redeemers[voucherID]!
		
		// get the recipients public account object
		let recipient = getAccount(redeemer)
		
		// borrow a public reference to the receivers collection
		let receiver = recipient.capabilities.get<&NeoMember.Collection>(NeoMember.CollectionPublicPath).borrow<&NeoMember.Collection>() ?? panic("Could not borrow a reference to the recipient's collection")
		let members = NeoVoucher.account.storage.borrow<&NeoMember.Collection>(from: NeoMember.CollectionStoragePath) ?? panic("Could not borrow a reference to the neo members for neo")
		let memberRef = members.borrow(rewardID)
		emit Consumed(voucherId: voucherID, address: redeemer, memberId: rewardID, teamId: memberRef.getTeamId(), role: memberRef.role, edition: memberRef.edition, maxEdition: memberRef.maxEdition, name: memberRef.name)
		let member <- members.withdraw(withdrawID: rewardID) as! @NeoMember.NFT
		if fullVoucher{ 
			member.addAchievement(NeoMotorcycle.Achievement(name: "OG Neo-fester", description: "In racing it\u{2019}s all about being first. You\u{2019}re one of the first people to ever gain access to Neo-Fest and that won\u{2019}t be forgotten. With at least 3 years of entry you\u{2019}re certain to never miss out on the NeoVerse's biggest in-person event year after year. It\u{2019}s going to be truly unforgettable!"))
		}
		receiver.deposit(token: <-member)
	}
	
	// fetch
	// Get a reference to a NeoVoucher from an account's Collection, if available.
	// If an account does not have a NeoVoucher.Collection, panic.
	// If it has a collection but does not contain the itemID, return nil.
	// If it has a collection and that collection contains the itemID, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, itemID: UInt64): &NeoVoucher.NFT?{ 
		let collection = getAccount(from).capabilities.get<&NeoVoucher.Collection>(NeoVoucher.CollectionPublicPath).borrow<&NeoVoucher.Collection>() ?? panic("Couldn't get collection")
		// We trust NeoVoucher.Collection.borrowNeoVoucher to get the correct itemID
		// (it checks it before returning it).
		return collection.borrowNeoVoucher(id: itemID)
	}
	
	// getMetadata
	// Get the metadata for a specific  of NeoVoucher
	//
	access(all)
	fun getMetadata(typeID: UInt64): Metadata?{ 
		return NeoVoucher.metadata[typeID]
	}
	
	//This is temp until we have some global admin
	access(all)
	resource NeoVoucherAdmin{ 
		access(all)
		fun registerNeoVoucherMetadata(typeID: UInt64, metadata: NeoVoucher.Metadata){ 
			NeoVoucher.registerMetadata(typeID: typeID, metadata: metadata)
		}
		
		access(all)
		fun batchMintNeoVoucher(recipient: &{NonFungibleToken.CollectionPublic}, count: Int){ 
			//We only have one type right now
			NeoVoucher.batchMintNFT(recipient: recipient, typeID: 1, count: count)
		}
		
		access(all)
		fun giftVoucher(recipient: Capability<&{NonFungibleToken.CollectionPublic}>, fullNFT: Bool){ 
			if !recipient.check(){ 
				emit NotValidCollection(address: recipient.address)
				return
			}
			let source = NeoVoucher.account.storage.borrow<&NeoVoucher.Collection>(from: NeoVoucher.CollectionStoragePath) ?? panic("Could not borrow a reference to the owner's voucher")
			let key = source.getIDs()[0]
			let nft <- source.withdraw(withdrawID: key) as! @NFT
			if fullNFT{ 
				nft.setTypeId(2)
			}
			let token <- nft as @{NonFungibleToken.NFT}
			(recipient.borrow()!).deposit(token: <-token)
			emit Gifted(voucherId: key, address: recipient.address, full: fullNFT)
		}
	}
	
	// initializer
	//
	init(){ 
		self.CollectionStoragePath = /storage/neoVoucherCollection
		self.CollectionPublicPath = /public/neoVoucherCollection
		
		// only one redeemedCollection should ever exist, in the deployer storage
		self.RedeemedCollectionStoragePath = /storage/neoVoucherRedeemedCollection
		self.RedeemedCollectionPublicPath = /public/neoVoucherRedeemedCollection
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Initialize predefined metadata
		self.metadata ={} 
		self.redeemers ={} 
		
		// this contract will hold a Collection that NeoVoucher can be deposited to and Admins can Consume them to grant rewards
		// to the depositing account
		let redeemedCollection <- create Collection()
		// establish the collection users redeem into
		self.account.storage.save(<-redeemedCollection, to: self.RedeemedCollectionStoragePath)
		// set up a public link to the redeemed collection so they can deposit/view
		var capability_1 = self.account.capabilities.storage.issue<&NeoVoucher.Collection>(NeoVoucher.RedeemedCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: NeoVoucher.RedeemedCollectionPublicPath)
		
		// set up a private link to the redeemed collection as a resource, so 
		emit ContractInitialized()
		let admin <- create NeoVoucherAdmin()
		self.account.storage.save(<-admin, to: /storage/neoVoucherAdmin)
	}
}
