import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowtyWrapped from "./FlowtyWrapped.cdc"

import StringUtils from "./../../standardsV1/StringUtils.cdc"

access(all)
contract WrappedEditions{ 
	access(all)
	struct Wrapped2023Data{ 
		access(all)
		let username: String?
		
		access(all)
		let tickets: Int
		
		access(all)
		let totalNftsOwned: Int
		
		access(all)
		let floatCount: Int
		
		access(all)
		let favoriteCollections: [String] // type identifier of each collection
		
		
		access(all)
		let collections: [String] // type identifier of each collection
		
		
		access(all)
		fun toTraits(): MetadataViews.Traits{ 
			let traits: [MetadataViews.Trait] =
				[
					WrappedEditions.buildTrait("username", self.username),
					WrappedEditions.buildTrait("tickets", self.tickets),
					WrappedEditions.buildTrait("totalNftsOwned", self.totalNftsOwned),
					WrappedEditions.buildTrait("floatCount", self.floatCount),
					WrappedEditions.buildTrait("favoriteCollections", self.favoriteCollections),
					WrappedEditions.buildTrait("collections", self.collections)
				]
			return MetadataViews.Traits(traits)
		}
		
		init(
			_ username: String?,
			_ tickets: Int,
			totalNftsOwned: Int,
			floatCount: Int,
			favoriteCollections: [
				String
			],
			collections: [
				String
			]
		){ 
			self.username = username
			self.tickets = tickets
			self.totalNftsOwned = totalNftsOwned
			self.floatCount = floatCount
			self.favoriteCollections = favoriteCollections
			self.collections = collections
		}
	}
	
	access(all)
	struct Edition2023: FlowtyWrapped.WrappedEdition{ 
		access(all)
		let name: String
		
		access(all)
		var supply: UInt64
		
		access(all)
		var baseImageUrl: String
		
		access(all)
		var baseHtmlUrl: String
		
		access(all)
		let raffleID: UInt64
		
		access(all)
		var status: String
		
		access(all)
		let mintedAddresses:{ Address: Bool}
		
		access(all)
		fun resolveView(_ t: Type, _ nft: &FlowtyWrapped.NFT): AnyStruct?{ 
			let wrapped = nft.data["wrapped"]! as! Wrapped2023Data
			switch t{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "Flowty 2023 #".concat(nft.serial.toString()), description: "A celebration and statistical review of an exciting year on Flowty and across the Flow blockchain ecosystem.", thumbnail: MetadataViews.HTTPFile(url: self.baseImageUrl.concat(nft.address.toString())))
				case Type<MetadataViews.Editions>():
					let editionYear = MetadataViews.Edition(name: "Flowty Wrapped 2023", number: nft.serial, max: nil)
					let editionList: [MetadataViews.Edition] = [editionYear]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Medias>():
					var username = wrapped.username ?? ""
					if username == ""{ 
						username = nft.owner != nil ? (nft.owner!).address.toString() : "Unknown"
					}
					let params = "?username=".concat(username).concat("&raffleTickets=").concat(wrapped.tickets.toString())
					let htmlMedia = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmRfVR98oe6qxeWFcnY9tfM2CLUJg3rvxbBPS5LjYwp69Z".concat(params), path: nil), mediaType: "text/html")
					let imageMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.baseImageUrl.concat(nft.serial.toString())), mediaType: "image/jpeg")
					return MetadataViews.Medias([htmlMedia, imageMedia])
				case Type<MetadataViews.Traits>():
					return wrapped.toTraits()
			}
			return nil
		}
		
		access(all)
		fun getEditionSupply(): UInt64{ 
			return self.supply
		}
		
		access(account)
		fun mint(address: Address, data:{ String: AnyStruct}): @FlowtyWrapped.NFT{ 
			pre{ 
				self.mintedAddresses[address] == nil:
					"address has already been minted"
			}
			self.supply = self.supply + 1
			let casted = data["wrapped"]! as! Wrapped2023Data
			let nft <- FlowtyWrapped.mint(id: FlowtyWrapped.totalSupply, serial: self.supply, editionName: self.name, address: address, data: data)
			
			// allocate raffle tickets
			let manager = FlowtyWrapped.getRaffleManager()
			let raffle = manager.borrowRaffle(id: self.raffleID) ?? panic("raffle not found in manager")
			let entries: [Address] = []
			var count = 0
			while count < casted.tickets{ 
				entries.append(address)
				count = count + 1
			}
			raffle.addEntries(entries)
			self.mintedAddresses[address] = true
			return <-nft
		}
		
		access(all)
		fun getName(): String{ 
			return self.name
		}
		
		access(all)
		fun setStatus(_ s: String){ 
			self.status = s
		}
		
		access(all)
		fun setBaseImageUrl(_ s: String){ 
			self.baseImageUrl = s
		}
		
		access(all)
		fun setBaseHtmlUrl(_ s: String){ 
			self.baseHtmlUrl = s
		}
		
		init(raffleID: UInt64, baseImageUrl: String, baseHtmlUrl: String){ 
			self.name = "Flowty Wrapped 2023"
			self.supply = 0
			self.raffleID = raffleID
			self.baseImageUrl = baseImageUrl
			self.baseHtmlUrl = baseHtmlUrl
			self.status = "CLOSED"
			self.mintedAddresses ={} 
		}
	}
	
	access(all)
	fun buildTrait(_ name: String, _ value: AnyStruct): MetadataViews.Trait{ 
		return MetadataViews.Trait(name: name, value: value, displayType: nil, rarity: nil)
	}
}
