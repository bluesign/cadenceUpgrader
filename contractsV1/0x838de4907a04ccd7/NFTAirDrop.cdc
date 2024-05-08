import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFTAirDrop{ 
	access(all)
	event Claimed(nftType: Type, nftID: UInt64, recipient: Address)
	
	access(all)
	let DropStoragePath: StoragePath
	
	access(all)
	let DropPublicPath: PublicPath
	
	access(all)
	resource interface DropPublic{ 
		access(all)
		fun claim(id: UInt64, signature: [UInt8], receiver: &{NonFungibleToken.CollectionPublic})
	}
	
	access(all)
	resource Drop: DropPublic{ 
		access(self)
		let nftType: Type
		
		access(self)
		let collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		access(self)
		let claims:{ UInt64: [UInt8]}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}, publicKey: [UInt8]){ 
			let collection = self.collection.borrow()!
			self.claims[token.id] = publicKey
			collection.deposit(token: <-token)
		}
		
		access(all)
		fun claim(id: UInt64, signature: [UInt8], receiver: &{NonFungibleToken.CollectionPublic}){ 
			let collection = self.collection.borrow()!
			let rawPublicKey = self.claims.remove(key: id) ?? panic("no claim exists for NFT")
			let publicKey = PublicKey(publicKey: rawPublicKey, signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
			let address = (receiver.owner!).address
			let message = self.makeClaimMessage(address: address, id: id)
			let isValidClaim = publicKey.verify(signature: signature, signedData: message, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
			assert(isValidClaim, message: "invalid claim signature")
			receiver.deposit(token: <-collection.withdraw(withdrawID: id))
			emit Claimed(nftType: self.nftType, nftID: id, recipient: address)
		}
		
		access(all)
		fun makeClaimMessage(address: Address, id: UInt64): [UInt8]{ 
			let addressBytes = address.toBytes()
			let idBytes = id.toBigEndianBytes()
			return addressBytes.concat(idBytes)
		}
		
		init(nftType: Type, collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.nftType = nftType
			self.collection = collection
			self.claims ={} 
		}
	}
	
	access(all)
	fun createDrop(
		nftType: Type,
		collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
	): @Drop{ 
		return <-create Drop(nftType: nftType, collection: collection)
	}
	
	init(){ 
		self.DropStoragePath = /storage/BarterYardPackNFTAirDrop
		self.DropPublicPath = /public/BarterYardPackNFTAirDrop
	}
}
