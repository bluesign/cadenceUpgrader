import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract DalleOnFlow: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var price: UFix64
	
	access(all)
	var mintingEnabled: Bool
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	access(all)
	event CreatedCollection()
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailCID: String
		
		access(all)
		var flagged: Bool
		
		access(all)
		var metadata:{ String: String}
		
		init(_description: String, _thumbnailCID: String, _metadata:{ String: String}){ 
			self.id = DalleOnFlow.totalSupply
			DalleOnFlow.totalSupply = DalleOnFlow.totalSupply + 1
			self.name = "DOF #".concat(self.id.toString())
			self.description = _description
			self.thumbnailCID = _thumbnailCID
			self.flagged = false
			self.metadata = _metadata
			emit Minted(id: self.id, metadata: _metadata)
		}
		
		access(contract)
		fun flagNFT(){ 
			self.flagged = true
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnailCID, path: ""))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DalleOnFlow.CollectionStoragePath, publicPath: DalleOnFlow.CollectionPublicPath, publicCollection: Type<&DalleOnFlow.Collection>(), publicLinkedType: Type<&DalleOnFlow.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DalleOnFlow.createEmptyCollection(nftType: Type<@DalleOnFlow.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://www.dalleonflow.art/logo.webp"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "DalleOnFlow", description: "DalleOnFlow", externalURL: MetadataViews.ExternalURL("https://www.dalleonflow.art/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/dalleonflow")})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.dalleonflow.art/")
				case Type<MetadataViews.Royalties>():
					let royaltyReceiver = getAccount(0x18deb5b8e5393198).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: royaltyReceiver!, cut: 0.05, description: "This is the royalty receiver for DalleOnFlow")])
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
		fun borrowDalleOnFlowNFT(id: UInt64): &DalleOnFlow.NFT
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let myToken <- token as! @DalleOnFlow.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowDalleOnFlowNFT(id: UInt64): &DalleOnFlow.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &DalleOnFlow.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = ref as! &DalleOnFlow.NFT
			return nft as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun mintNFT(description: String, thumbnailCID: String, metadata:{ String: String}, recepient: Capability<&DalleOnFlow.Collection>, payment: @FlowToken.Vault){ 
			pre{ 
				DalleOnFlow.mintingEnabled == true:
					"Minting is not enabled"
				DalleOnFlow.totalSupply < 9999:
					"The maximum number of DalleOnFlow NFTs has been reached"
				payment.balance == 10.24:
					"Payment does not match the price."
			}
			let dofWallet = getAccount(0x18deb5b8e5393198).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!
			dofWallet.deposit(from: <-payment)
			let nft <- create NFT(_description: description, _thumbnailCID: thumbnailCID, _metadata: metadata)
			let recepientCollection = recepient.borrow()!
			recepientCollection.deposit(token: <-nft)
		}
		
		access(all)
		fun flagNFT(id: UInt64, recepient: Capability<&DalleOnFlow.Collection>): &DalleOnFlow.NFT{ 
			let nft = (recepient.borrow()!).borrowDalleOnFlowNFT(id: id)
			nft.flagNFT()
			return nft
		}
		
		access(all)
		fun changePrice(newPrice: UFix64){ 
			DalleOnFlow.price = newPrice
		}
		
		access(all)
		fun changeMintingEnabled(isEnabled: Bool){ 
			DalleOnFlow.mintingEnabled = isEnabled
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.price = 10.24
		self.mintingEnabled = false
		self.CollectionStoragePath = /storage/DalleOnFlowCollection
		self.CollectionPublicPath = /public/DalleOnFlowCollection
		self.AdminStoragePath = /storage/DalleOnFlowAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
