import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract TSInnovators22: NonFungibleToken{ 
	/************************************************/
	/******************** STATE *********************/
	/************************************************/
	// The total number of TSInnovators tokens in existence
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var allInnovatorTokens:{ String: Address}
	
	access(all)
	var allHashes: [String]
	
	/************************************************/
	/******************** EVENTS ********************/
	/************************************************/
	//Standard events from NonFungibleToken standard
	access(all)
	event ContractInitialized()
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	//TSInnovators22 events
	access(all)
	event InnovatorsTokenMinted(id: UInt64, email: String, description: String, org: String, serial: String, hash: String)
	
	// ** THIS REPRESENTS A TSINNOVATORS TOKEN **
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		//NFT Standard attribuet the 'uuid' of our token
		access(all)
		let id: UInt64
		
		//TSInnovators attributes
		access(all)
		let ipfsHash: String
		
		access(all)
		let email: String
		
		access(all)
		let description: String
		
		access(all)
		let org: String
		
		access(all)
		let serial: String
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_ipfsHash: String, _email: String, _description: String, _org: String, _serial: String){ 
			self.id = TSInnovators22.totalSupply
			TSInnovators22.totalSupply = TSInnovators22.totalSupply + 1
			self.ipfsHash = _ipfsHash
			self.email = _email
			self.description = _description
			self.org = _org
			self.serial = _serial
			
			//Token initialized 
			emit InnovatorsTokenMinted(id: self.id, email: self.email, description: self.description, org: self.org, serial: self.serial, hash: self.ipfsHash)
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		//We dont wan't the withdraw function to be publically accessible
		//pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT 
		access(all)
		view fun getIDs(): [UInt64]
		
		//Check if user has a token 
		access(all)
		fun hasToken(): Bool
		
		//Returns NonFungibleToken nft
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		//Returns TSInnovators22 nft
		access(all)
		fun borrowTSInnovatorsToken(id: UInt64): &NFT?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		// A dictionairy of all TSInnovators tokens 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun hasToken(): Bool{ 
			return !(self.getIDs().length == 0)
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			pre{ 
				self.getIDs().length == 0:
					"You Already Own A TSInnovatorNFT"
			}
			let myToken <- token as! @TSInnovators22.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			
			//UPDATE MAP WITH NEW TOKEN
			TSInnovators22.allInnovatorTokens[myToken.serial] = self.owner?.address
			TSInnovators22.allHashes.append(myToken.ipfsHash)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Cannot borrow NFT, no such id"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowTSInnovatorsToken(id: UInt64): &NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			}
			return nil
		}
		
		//Ideally the POAP token is not transferrable so withdraw and delete will not be 
		//included in public collection
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist in your collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun delete(id: UInt64){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("You do not own this FLOAT in your collection")
			let nft <- token as! @NFT
			destroy nft
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
	fun createToken(ipfsHash: String, email: String, description: String, org: String, serial: String): @TSInnovators22.NFT{ 
		return <-create NFT(_ipfsHash: ipfsHash, _email: email, _description: description, _org: org, _serial: serial)
	}
	
	init(){ 
		self.totalSupply = 0
		self.allInnovatorTokens ={} 
		self.allHashes = []
	}
}
