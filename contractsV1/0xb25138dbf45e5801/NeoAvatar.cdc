import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NeoViews from "./NeoViews.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/// A NFT contract to store a NEO avatar
access(all)
contract NeoAvatar: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, teamId: UInt64, role: String, series: String, imageHash: String, address: Address)
	
	access(all)
	event Purchased(id: UInt64, name: String, teamId: UInt64, role: String, series: String, address: Address)
	
	access(all)
	event OriginalMinterSet(id: UInt64, address: Address)
	
	access(all)
	struct NeoAvatarView{ 
		access(all)
		let teamId: UInt64
		
		access(all)
		let role: String
		
		access(all)
		let series: String
		
		init(teamId: UInt64, role: String, series: String){ 
			self.teamId = teamId
			self.role = role
			self.series = series
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let role: String
		
		access(all)
		let series: String
		
		access(all)
		let teamId: UInt64
		
		access(all)
		let imageHash: String
		
		access(contract)
		var originalMinterWallet: Capability<&{FungibleToken.Receiver}>
		
		init(id: UInt64, imageHash: String, wallet: Capability<&{FungibleToken.Receiver}>, name: String, teamId: UInt64, role: String, series: String){ 
			self.id = id
			self.imageHash = imageHash
			self.originalMinterWallet = wallet
			self.teamId = teamId
			self.role = role
			self.series = series
			self.name = name
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.IPFSFile>(), Type<NeoViews.Royalties>(), Type<NeoAvatarView>(), Type<NeoViews.ExternalDomainViewUrl>()]
		}
		
		access(all)
		fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>){ 
			self.originalMinterWallet = wallet
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: "The neo avatar minted originally for address=".concat(self.originalMinterWallet.address.toString()).concat(" during the Neo Champtionship ").concat(self.series), thumbnail: MetadataViews.IPFSFile(cid: self.imageHash, path: nil))
				case Type<String>():
					return self.name
				case Type<MetadataViews.IPFSFile>():
					return MetadataViews.IPFSFile(cid: self.imageHash, path: nil)
				case Type<NeoViews.ExternalDomainViewUrl>():
					return NeoViews.ExternalDomainViewUrl(url: "https://neocollectibles.xyz")
				case Type<NeoViews.Royalties>():
					return self.getRoyalty()
				case Type<NeoAvatar.NeoAvatarView>():
					return NeoAvatarView(teamId: self.teamId, role: self.role, series: self.series)
			}
			return nil
		}
		
		access(all)
		fun getRoyalty(): NeoViews.Royalties{ 
			let minterRoyalty = NeoViews.Royalty(wallet: NeoAvatar.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.05)
			let founderRoyalty = NeoViews.Royalty(wallet: self.originalMinterWallet, cut: 0.01)
			return NeoViews.Royalties(royalties:{ "minter": minterRoyalty, "originalOwner": founderRoyalty})
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			if token.originalMinterWallet.address == NeoAvatar.account.address{ 
				token.setWallet((self.owner!).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!)
				emit OriginalMinterSet(id: token.id, address: (self.owner!).address)
			}
			let id: UInt64 = token.id
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &NeoAvatar.NFT
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
	}
	
	//This is temp until we have some global admin
	access(all)
	resource NeoAvatarAdmin{ 
		access(all)
		fun mint(teamId: UInt64, series: String, role: String, imageHash: String, wallet: Capability<&{FungibleToken.Receiver}>, collection: Capability<&{NonFungibleToken.Receiver}>){ 
			NeoAvatar.mint(teamId: teamId, series: series, role: role, imageHash: imageHash, wallet: wallet, collection: collection)
		}
	}
	
	//This method can only be called from another contract in the same account. In this case the Admin account
	access(account)
	fun mint(teamId: UInt64, series: String, role: String, imageHash: String, wallet: Capability<&{FungibleToken.Receiver}>, collection: Capability<&{NonFungibleToken.Receiver}>){ 
		self.totalSupply = self.totalSupply + 1
		let name = role.concat(" for Neo Team #").concat(teamId.toString())
		var newNFT <- create NFT(id: self.totalSupply, imageHash: imageHash, wallet: wallet, name: name, teamId: teamId, role: role, series: series)
		emit Minted(id: self.totalSupply, name: name, teamId: teamId, role: role, series: series, imageHash: imageHash, address: collection.address)
		(collection.borrow()!).deposit(token: <-newNFT)
	}
	
	access(all)
	fun purchase(id: UInt64, vault: @{FungibleToken.Vault}, nftReceiver: Capability<&{NonFungibleToken.Receiver}>){ 
		let collection = NeoAvatar.account.storage.borrow<&NeoAvatar.Collection>(from: self.CollectionStoragePath)!
		let ids = collection.getIDs()
		if !ids.contains(id){ 
			panic("This neo avatar is already sold")
		}
		let vault <- vault as! @FlowToken.Vault
		if vault.balance != 1.0{ 
			panic("The purchase does not contain the required amount of 1 flow")
		}
		let tokenRef = collection.borrowViewResolver(id: id)!
		let neoAvatar = tokenRef.resolveView(Type<NeoAvatar.NeoAvatarView>())! as! NeoAvatar.NeoAvatarView
		let display = tokenRef.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		emit Purchased(id: id, name: display.name, teamId: neoAvatar.teamId, role: neoAvatar.role, series: neoAvatar.series, address: nftReceiver.address)
		let token <- collection.withdraw(withdrawID: id)
		(nftReceiver.borrow()!).deposit(token: <-token)
		let receiver = NeoAvatar.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()!
		receiver.deposit(from: <-vault)
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		let admin <- create NeoAvatarAdmin()
		self.account.storage.save(<-admin, to: /storage/neoAvatarAdmin)
		
		// Initialize the total supply
		self.totalSupply = 0
		self.CollectionPublicPath = /public/neoAvatarCollection
		self.CollectionStoragePath = /storage/neoAvatarCollection
		emit ContractInitialized()
	}
}
