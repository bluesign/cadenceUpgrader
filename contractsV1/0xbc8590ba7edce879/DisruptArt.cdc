// DisruptArt NFT Smart Contract
// NFT Marketplace : www.DisruptArt.io
// Owner		   : Disrupt Art, INC.
// Developer	   : www.blaze.ws
// Version		 : 0.0.5
// Blockchain	  : Flow www.onFlow.org
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DisruptArt: NonFungibleToken{ 
	
	// Total number of token supply
	access(all)
	var totalSupply: UInt64
	
	// Total number of token groups
	access(all)
	var tokenGroupsCount: UInt64
	
	// NFT No of Editions(Multiple copies) limit
	access(all)
	var editionLimit: UInt
	
	/// Path where the `Collection` is stored
	access(all)
	let disruptArtStoragePath: StoragePath
	
	/// Path where the public capability for the `Collection` is
	access(all)
	let disruptArtPublicPath: PublicPath
	
	/// NFT Minter
	access(all)
	let disruptArtMinterPath: StoragePath
	
	// Contract Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, content: String, owner: Address?, name: String)
	
	access(all)
	event GroupMint(id: UInt64, content: String, owner: Address?, name: String, tokenGroupId: UInt64)
	
	// TOKEN RESOURCE
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		
		// Unique identifier for NFT Token
		access(all)
		let id: UInt64
		
		// Meta data to store token data (use dict for data)
		access(self)
		let metaData:{ String: String}
		
		// NFT token name
		access(all)
		let name: String
		
		// NFT token creator address
		access(all)
		let creator: Address?
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// In current store static dict in meta data
		init(id: UInt64, content: String, name: String, description: String, creator: Address?){ 
			self.id = id
			self.metaData ={ "content": content, "description": description}
			self.creator = creator
			self.name = name
		}
	}
	
	// Account's public collection
	access(all)
	resource interface DisruptArtCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	// NFT Collection resource
	access(all)
	resource Collection: DisruptArtCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		
		// Contains caller's list of NFTs
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @DisruptArt.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// function returns token keys of owner
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// function returns token data of token id
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// function to check wether the owner have token or not
		access(all)
		fun tokenExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
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
	
	// NFT MINTER
	access(all)
	resource NFTMinter{ 
		
		// Function to mint group of tokens
		access(all)
		fun GroupMint(recipient: &{DisruptArtCollectionPublic}, content: String, description: String, name: String, edition: UInt){ 
			pre{ 
				DisruptArt.editionLimit >= edition:
					"Edition count exceeds the limit"
				edition >= 2:
					"Edition count should be greater than or equal to 2"
			}
			var count = 0 as UInt
			DisruptArt.tokenGroupsCount = DisruptArt.tokenGroupsCount + 1 as UInt64
			while count < edition{ 
				let token <- create NFT(id: DisruptArt.totalSupply, content: content, name: name, description: description, creator: recipient.owner?.address)
				emit GroupMint(id: DisruptArt.totalSupply, content: content, owner: recipient.owner?.address, name: name, tokenGroupId: DisruptArt.tokenGroupsCount)
				recipient.deposit(token: <-token)
				DisruptArt.totalSupply = DisruptArt.totalSupply + 1 as UInt64
				count = count + 1
			}
		}
		
		access(all)
		fun Mint(recipient: &{DisruptArtCollectionPublic}, content: String, name: String, description: String){ 
			let token <- create NFT(id: DisruptArt.totalSupply, content: content, name: name, description: description, creator: recipient.owner?.address)
			emit Mint(id: DisruptArt.totalSupply, content: content, owner: recipient.owner?.address, name: name)
			recipient.deposit(token: <-token)
			DisruptArt.totalSupply = DisruptArt.totalSupply + 1 as UInt64
		}
	}
	
	// This is used to create the empty collection. without this address cannot access our NFT token
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create DisruptArt.Collection()
	}
	
	// Admin can change the maximum supported group minting count limit for the platform. Currently it is 50
	access(all)
	resource Admin{ 
		access(all)
		fun changeLimit(limit: UInt){ 
			DisruptArt.editionLimit = limit
		}
	}
	
	// Contract init
	init(){ 
		
		// total supply is zero at the time of contract deployment
		self.totalSupply = 0
		self.tokenGroupsCount = 0
		self.editionLimit = 50
		self.disruptArtStoragePath = /storage/DisruptArtNFTCollection
		self.disruptArtPublicPath = /public/DisruptArtNFTPublicCollection
		self.disruptArtMinterPath = /storage/DisruptArtNFTMinter
		self.account.storage.save(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.disruptArtStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{DisruptArtCollectionPublic}>(self.disruptArtStoragePath)
		self.account.capabilities.publish(capability_1, at: self.disruptArtPublicPath)
		self.account.storage.save(<-create self.Admin(), to: /storage/DirsuptArtAdmin)
		
		// store a minter resource in account storage
		self.account.storage.save(<-create NFTMinter(), to: self.disruptArtMinterPath)
		emit ContractInitialized()
	}
}
