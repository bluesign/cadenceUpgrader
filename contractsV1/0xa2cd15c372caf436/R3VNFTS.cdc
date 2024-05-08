
// Join us by visiting https://r3volution.io
access(all)
contract R3VNFTS{ 
	access(all)
	event NFTMinted(id: Int, md: String)
	
	access(all)
	event NFTWithdraw(id: Int, md: String, acct: String)
	
	access(all)
	event NFTDeposit(id: Int, md: String, acct: String)
	
	// the R3V NFT resource
	access(all)
	resource NFT{ 
		// our unique NFT serial number
		access(all)
		let id: Int
		
		// our metadata is the base64 of our JSON string
		access(all)
		let metadata: String
		
		init(id: Int, metadata: String){ 
			self.id = id
			self.metadata = metadata
		}
	}
	
	// the NFTReceiver interface declares methods for accessing a Collection resource
	// this receiver should always be located on an initialized account at /public/RevNFTReceiver
	// example on how to obtain contained IDs:
	//
	// pub fun main(): [Int] {
	//	 let nftOwner = getAccount(0x$account)
	//	 let capability = nftOwner.getCapability<&{R3VNFTS.NFTReceiver}>(/public/RevNFTReceiver)
	//	 let receiverRef = capability.borrow()
	//			 ?? panic("Could not borrow the receiver reference")
	//	 return(receiverRef.getIDs())
	// }
	//
	access(all)
	resource interface NFTReceiver{ 
		// deposit an @NFT into this receiver
		access(all)
		fun deposit(token: @NFT)
		
		// get the IDs of the NFTs this receiver stores
		access(all)
		fun getIDs(): [Int]
		
		// check if a specific ID is stored in this receiver
		access(all)
		fun idExists(id: Int): Bool
		
		// get the metadata of the provided receivers as a [string]
		access(all)
		fun getMetadata(ids: [Int]): [String]
	}
	
	// the Collection resource exists at /storage/RevNFTCollection
	// to setup this collection on a user, we will need to create it with a transaction
	// we should also setup the /public/RevNFTReceiver at this time
	//
	// transaction {
	//	 prepare(acct: AuthAccount) {
	//		 let collection <- R3VNFTS.createEmptyCollection()
	//		 acct.save<@R3VNFTS.Collection>(<-collection, to: /storage/RevNFTCollection)
	//		 acct.link<&{R3VNFTS.NFTReceiver}>(/public/RevNFTReceiver, target: /storage/RevNFTCollection)
	//	 }
	// }
	//
	access(all)
	resource Collection: NFTReceiver{ 
		// map<id, NFT>
		access(all)
		var ownedNFTs: @{Int: NFT}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdrawal NFT from the Collection.ownedNFTs map
		access(all)
		fun withdraw(withdrawID: Int): @NFT{ 
			let location = (self.owner!).address.toString()
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit NFTWithdraw(id: token.id, md: token.metadata, acct: location)
			return <-token
		}
		
		// deposit NFT into this Collection.ownedNFTs map
		access(all)
		fun deposit(token: @NFT){ 
			let id = token.id
			let md = token.metadata
			self.ownedNFTs[token.id] <-! token
			let location = (self.owner!).address.toString()
			emit NFTDeposit(id: id, md: md, acct: location)
		}
		
		// returns a Bool on whether the provided ID exists within this Collection.ownedNFTs.keys
		access(all)
		fun idExists(id: Int): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// gets all keys within this Collection.ownedNFTs
		access(all)
		fun getIDs(): [Int]{ 
			return self.ownedNFTs.keys
		}
		
		// get an array of strings from the provided Collection.owndeNFTs.keys
		access(all)
		fun getMetadata(ids: [Int]): [String]{ 
			var ret: [String] = []
			for id in ids{ 
				ret.append(self.ownedNFTs[id]?.metadata!)
			}
			return ret
		}
	
	// nuke this collection upon destruction
	}
	
	// helper function to create a new collection
	access(all)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	// our minter resource: internal only
	// our minting transaction will typically look like:
	//
	// transaction(metadata: [String]) {
	//
	//	 let receiverRef: &{R3VNFTS.NFTReceiver}
	//	 let minterRef: &R3VNFTS.NFTMinter
	//
	//	 prepare(acct: AuthAccount) {
	//		 self.receiverRef = acct.getCapability<&{R3VNFTS.NFTReceiver}>(/public/RevNFTReceiver)
	//			 .borrow()
	//			 ?? panic("Could not borrow receiver reference")
	//		 self.minterRef = acct.borrow<&R3VNFTS.NFTMinter>(from: /storage/RevNFTMinter)
	//			 ?? panic("Could not borrow minter reference")
	//	 }
	//
	//	 execute {
	//		 var i: Int = 0;
	//		 while i < metadata.length {
	//			 let newNFT <- self.minterRef.mintNFT(metadata: metadata[i])
	//			 self.receiverRef.deposit(token: <-newNFT)
	//			 i = i + 1
	//		 }
	//	 }
	// }
	access(all)
	resource NFTMinter{ 
		// NFT serial number
		access(all)
		var idCount: Int
		
		init(){ 
			// starting at serial 1
			self.idCount = 1
		}
		
		// mint a new NFT from this NFTMinter
		access(all)
		fun mintNFT(metadata: String): @NFT{ 
			var newNFT <- create NFT(id: self.idCount, metadata: metadata)
			self.idCount = self.idCount + 1
			emit NFTMinted(id: newNFT.id, md: metadata)
			return <-newNFT
		}
	}
	
	init(){ 
		self.account.storage.save(<-self.createEmptyCollection(), to: /storage/RevNFTCollection)
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(/storage/RevNFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/RevNFTReceiver)
		self.account.storage.save(<-create NFTMinter(), to: /storage/RevNFTMinter)
	}
}
