access(all)
contract ProjectMetadata{ 
	// ProjectMetadataRandomNFT
	access(all)
	struct RatioRandomNFTItem{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let image: String
		
		access(contract)
		let nftMetadata:{ String: String}
		
		access(contract)
		let nftIDs: [UInt64]
		
		access(contract)
		let maxSupply: UInt64
		
		access(contract)
		let ratio: UFix64
		
		init(
			id: UInt64,
			image: String,
			maxSupply: UInt64,
			nftMetadata:{ 
				String: String
			},
			ratio: UFix64
		){ 
			pre{ 
				ratio <= 1.0:
					"ratio sould be <= 100%"
			}
			self.image = image
			self.nftIDs = []
			self.maxSupply = maxSupply
			self.ratio = ratio
			self.nftMetadata = nftMetadata
			self.id = id
		}
		
		access(all)
		fun addNFT(_ nftID: UInt64){ 
			self.nftIDs.append(nftID)
		}
		
		access(all)
		fun getImage(): String{ 
			return self.image
		}
		
		access(all)
		fun getRatio(): UFix64{ 
			return self.ratio
		}
		
		access(all)
		fun getNftMetadata():{ String: String}{ 
			return self.nftMetadata
		}
		
		access(all)
		fun getNftIDs(): [UInt64]{ 
			return self.nftIDs
		}
		
		access(all)
		fun getMaxSupply(): UInt64{ 
			return self.maxSupply
		}
		
		access(all)
		fun getTotalSupply(): UInt64{ 
			return UInt64(self.nftIDs.length)
		}
	}
	
	access(all)
	struct RatioRandomNFT{ 
		access(all)
		let items: [RatioRandomNFTItem]
		
		init(
			images: [
				String
			],
			maxSupplies: [
				UInt64
			],
			nftMetadatas: [{
				
					String: String
				}
			],
			ratios: [
				UFix64
			]
		){ 
			pre{ 
				images.length == maxSupplies.length:
					"maxSupplies length is invalid"
				images.length == nftMetadatas.length:
					"nftMetadatas length is invalid"
				images.length == ratios.length:
					"ratios length is invalid"
			}
			self.items = []
			var i = 0
			var totalRatio = 0.0
			while i < images.length{ 
				let randomItem = RatioRandomNFTItem(id: UInt64(i + 1), image: images[i], maxSupply: maxSupplies[i], nftMetadata: nftMetadatas[i], ratio: ratios[i])
				self.items.append(randomItem)
				totalRatio = totalRatio + randomItem.getRatio()
				i = i + 1
			}
			if totalRatio != 1.0{ 
				panic("Total raito must be equal 100%")
			}
		}
		
		access(all)
		fun getImages(): [String]{ 
			let res: [String] = []
			for item in self.items{ 
				res.append(item.getImage())
			}
			return res
		}
		
		access(all)
		fun getNftMetadatas(): [{String: String}]{ 
			let res: [{String: String}] = []
			for item in self.items{ 
				res.append(item.getNftMetadata())
			}
			return res
		}
		
		access(all)
		fun updateItem(itemId: UInt64, item: RatioRandomNFTItem){ 
			var i = 0
			while i < self.items.length{ 
				if self.items[i].id == itemId{ 
					self.items[i] = item
					return
				}
				i = i + 1
			}
		}
		
		access(contract)
		fun getRandomByRatio(_ items: [RatioRandomNFTItem]): RatioRandomNFTItem{ 
			let defaultItem = items[0]
			let itemLen = items.length
			var i = 0
			var cumSum = 0.0
			let randomNum: UFix64 = UFix64(revertibleRandom() % 1000000) / 1000000.0 // get random number from 0.0 to 0.99999
			
			while i < itemLen{ 
				cumSum = cumSum + items[i].getRatio()
				if randomNum <= cumSum{ 
					return items[i]
				}
				i = i + 1
			}
			return defaultItem
		}
		
		access(all)
		fun getRaitoRandomItemForMint(_ quantity: UInt64): [RatioRandomNFTItem]{ 
			let randomItems: [RatioRandomNFTItem] = []
			while UInt64(randomItems.length) < quantity{ 
				// get images valid
				let itemValid: [RatioRandomNFTItem] = []
				for item in self.items{ 
					if item.getMaxSupply() > item.getTotalSupply(){ 
						itemValid.append(item)
					}
				}
				if itemValid.length == 0{ 
					panic("RANDOM_NFT_IS_SOLD_OUT")
				}
				
				// prepare random image
				let itemRandom = self.getRandomByRatio(itemValid)
				randomItems.append(itemRandom)
			}
			return randomItems
		}
		
		access(all)
		fun addNFT(itemId: UInt64, nftID: UInt64){ 
			var i = 0
			while i < self.items.length{ 
				let item: RatioRandomNFTItem = self.items[i]
				if item.id == itemId{ 
					item.addNFT(nftID)
					self.items[i] = item
				}
				i = i + 1
			}
		}
	}
	
	// LotteryRandom
	access(all)
	event LotteryRandom(
		nftID: UInt64,
		nftType: String,
		nftOwner: Address,
		lotteryNumber: UInt64,
		winner: Bool
	)
	
	access(all)
	struct LotteryItem{ 
		access(all)
		let nftID: UInt64
		
		access(all)
		let nftOwner: Address
		
		access(all)
		let timestamp: UFix64
		
		access(all)
		let lotteryNumber: UInt64
		
		access(all)
		let nftType: String
		
		init(nftID: UInt64, nftOwner: Address, nftType: String, lotteryNumber: UInt64){ 
			self.nftID = nftID
			self.nftOwner = nftOwner
			self.lotteryNumber = lotteryNumber
			self.nftType = nftType
			self.timestamp = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	struct LotteryRandomNFT{ 
		access(all)
		let lotteryItems: [LotteryItem]
		
		access(all)
		let luckyNumbers: [UInt64]
		
		access(all)
		let lotteryNumberNotUse: [UInt64]
		
		access(all)
		let nftMetadata:{ String: String}
		
		access(self)
		var winner: LotteryItem?
		
		init(nftMetadata:{ String: String}, luckyNumbers: [UInt64], totalNumber: UInt64){ 
			// validate lucky numbers
			for luckyNumber in luckyNumbers{ 
				if luckyNumber < 1 || luckyNumber > totalNumber{ 
					panic("Lucky number is invalid: ".concat(luckyNumber.toString()))
				}
			}
			self.winner = nil
			self.lotteryItems = []
			self.nftMetadata = nftMetadata
			self.luckyNumbers = luckyNumbers
			self.lotteryNumberNotUse = []
			var i = UInt64(1)
			while i <= totalNumber{ 
				self.lotteryNumberNotUse.append(i)
				i = i + 1
			}
		}
		
		access(all)
		fun isNftUsed(nftID: UInt64, nftType: String): Bool{ 
			for item in self.lotteryItems{ 
				if item.nftType == nftType && item.nftID == nftID{ 
					return true
				}
			}
			return false
		}
		
		access(self)
		fun getLotteryNumberIndex(): Int{ 
			let randomNumber = revertibleRandom()
			let randomNum = UFix64(revertibleRandom() % 1000000) / 1000000.0 // get random number from 0.0 to 0.99999
			
			let randomIndex = Int(randomNum * UFix64(self.lotteryNumberNotUse.length)) // get random number from 0 to lotteryNumberNotUse.length - 1
			
			return randomIndex
		}
		
		// create a lottery number and update winner
		access(all)
		fun tokenGate(nftID: UInt64, nftType: String, nftOwner: Address): Void{ 
			if self.isNftUsed(nftID: nftID, nftType: nftType){ 
				return
			}
			let lotteryNumberIndex = self.getLotteryNumberIndex()
			let lotteryNumber = self.lotteryNumberNotUse[lotteryNumberIndex]
			self.lotteryNumberNotUse.remove(at: lotteryNumberIndex)
			let item =
				LotteryItem(
					nftID: nftID,
					nftOwner: nftOwner,
					nftType: nftType,
					lotteryNumber: lotteryNumber
				)
			self.lotteryItems.append(item)
			if self.luckyNumbers.contains(lotteryNumber){ 
				self.winner = item
				emit LotteryRandom(nftID: nftID, nftType: nftType, nftOwner: nftOwner, lotteryNumber: lotteryNumber, winner: true)
			} else{ 
				emit LotteryRandom(nftID: nftID, nftType: nftType, nftOwner: nftOwner, lotteryNumber: lotteryNumber, winner: false)
			}
		}
		
		access(all)
		fun getWinner(): LotteryItem?{ 
			return self.winner
		}
		
		access(all)
		fun resetGate(){ 
			while self.lotteryItems.length != 0{ 
				self.lotteryItems.remove(at: 0)
			}
		}
	}
}
