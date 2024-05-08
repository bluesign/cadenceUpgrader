// Author: Morgan Wilde
// Author's website: flowdeveloper.com
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract SongVest: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event SongMint(id: UInt64, series: UInt, serialNumber: UInt)
	
	// The SongVest Song NFT.
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let series: UInt
		
		access(all)
		let title: String
		
		access(all)
		let writers: String
		
		access(all)
		let artist: String
		
		access(all)
		let description: String
		
		access(all)
		let creator: String
		
		access(all)
		let supply: UInt
		
		access(all)
		let serialNumber: UInt
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(series: UInt, title: String, writers: String, artist: String, description: String, creator: String, supply: UInt, serialNumber: UInt){ 
			pre{ 
				series > 0:
					"Series must be greater than zero"
				serialNumber < 1_000_000_000:
					"Serial number must be less than 1000,000,000"
			}
			self.id = 1_000_000_000 * UInt64(series) + UInt64(serialNumber)
			self.series = series
			self.title = title
			self.writers = writers
			self.artist = artist
			self.description = description
			self.creator = creator
			self.supply = supply
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource interface SongCollection{ 
		access(all)
		fun borrowSong(id: UInt64): &SongVest.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, SongCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn Song must be the same as the requested ID."
			}
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Song not found in collection.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SongVest.NFT
			let id = token.id
			let existingToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy existingToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(all)
		fun borrowSong(id: UInt64): &SongVest.NFT{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &SongVest.NFT
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		post{ 
			result.getIDs().length == 0:
				"The created collection must be empty!"
		}
		return <-create Collection()
	}
	
	access(all)
	resource Minter{ 
		access(all)
		var seriesNumber: UInt
		
		init(){ 
			self.seriesNumber = 0
		}
		
		access(all)
		fun mintSong(seriesNumber: UInt, title: String, writers: String, artist: String, description: String, creator: String, supply: UInt): @Collection{ 
			var collection <- create Collection()
			if self.seriesNumber >= seriesNumber{ 
				// This song series was already minted.
				log("Series number \"".concat(seriesNumber.toString()).concat("\" has been used."))
			} else{ 
				// This is a brand new song series.
				self.seriesNumber = seriesNumber
				var serialNumber: UInt = 0
				while serialNumber < supply{ 
					let song <- create NFT(series: self.seriesNumber, title: title, writers: writers, artist: artist, description: description, creator: creator, supply: supply, serialNumber: serialNumber)
					emit SongMint(id: song.id, series: self.seriesNumber, serialNumber: serialNumber)
					collection.deposit(token: <-song)
					serialNumber = serialNumber + 1 as UInt
					SongVest.totalSupply = SongVest.totalSupply + 1 as UInt64
				}
			}
			return <-collection
		}
	}
	
	init(){ 
		// Initialize the total supply.
		self.totalSupply = 0
		
		// Paths
		self.CollectionStoragePath = /storage/SongVestCollection
		self.CollectionPublicPath = /public/SongVestCollection
		self.MinterStoragePath = /storage/SongVestMinter
		self.account.storage.save(<-create Minter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
