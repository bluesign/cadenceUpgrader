import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NowggNFT from "./NowggNFT.cdc"

access(all)
contract NowggPuzzle{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event PuzzleRegistered(puzzleId: String, parentNftTypeId: String, childNftTypeIds: [String])
	
	access(all)
	event PuzzleCombined(puzzleId: String, by: Address)
	
	access(all)
	let PuzzleHelperStoragePath: StoragePath
	
	access(all)
	let PuzzleHelperPublicPath: PublicPath
	
	access(all)
	struct Puzzle{ 
		access(contract)
		let puzzleId: String
		
		access(contract)
		let parentNftTypeId: String
		
		access(contract)
		let childNftTypeIds: [String]
		
		init(puzzleId: String, parentNftTypeId: String, childNftTypeIds: [String]){ 
			if NowggPuzzle.allPuzzles.keys.contains(puzzleId){ 
				panic("Puzzle is already registered")
			}
			if childNftTypeIds.length >= 1000{ 
				panic("Puzzle cannot have more than 1000 pieces")
			}
			self.puzzleId = puzzleId
			self.parentNftTypeId = parentNftTypeId
			self.childNftTypeIds = childNftTypeIds
		}
		
		access(all)
		fun getPuzzleInfo():{ String: AnyStruct}{ 
			return{ 
				"puzzleId": self.puzzleId,
				"parentNftTypeId": self.parentNftTypeId,
				"childNftTypeIds": self.childNftTypeIds
			}
		}
	}
	
	access(contract)
	var allPuzzles:{ String: Puzzle}
	
	access(all)
	resource interface PuzzleHelperPublic{ 
		access(all)
		fun borrowPuzzle(puzzleId: String): Puzzle?{ 
			post{ 
				result == nil || result?.puzzleId == puzzleId:
					"Cannot borrow puzzle reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource interface PuzzleHelperInterface{ 
		access(all)
		fun registerPuzzle(
			nftMinter: &NowggNFT.NFTMinter,
			puzzleId: String,
			parentNftTypeId: String,
			childNftTypeIds: [
				String
			],
			maxCount: UInt64
		)
		
		access(all)
		fun combinePuzzle(
			nftMinter: &NowggNFT.NFTMinter,
			nftProvider: &{
				NonFungibleToken.Provider,
				NonFungibleToken.CollectionPublic,
				NowggNFT.NowggNFTCollectionPublic
			},
			puzzleId: String,
			parentNftTypeId: String,
			childNftIds: [
				UInt64
			],
			metadata:{ 
				String: AnyStruct
			}
		)
	}
	
	// Resource that allows other accounts to access the functionality related to puzzles
	access(all)
	resource PuzzleHelper: PuzzleHelperPublic, PuzzleHelperInterface{ 
		access(all)
		fun borrowPuzzle(puzzleId: String): Puzzle?{ 
			if NowggPuzzle.allPuzzles[puzzleId] != nil{ 
				return NowggPuzzle.allPuzzles[puzzleId]
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun registerPuzzle(nftMinter: &NowggNFT.NFTMinter, puzzleId: String, parentNftTypeId: String, childNftTypeIds: [String], maxCount: UInt64){ 
			assert(childNftTypeIds.length < 1000, message: "childNftTypeIds must have less than 1000 elements")
			for childPuzzleTypeId in childNftTypeIds{ 
				nftMinter.registerType(typeId: childPuzzleTypeId, maxCount: maxCount)
			}
			nftMinter.registerType(typeId: parentNftTypeId, maxCount: maxCount)
			NowggPuzzle.allPuzzles[puzzleId] = Puzzle(puzzleId: puzzleId, parentNftTypeId: parentNftTypeId, childNftTypeIds: childNftTypeIds)
			emit PuzzleRegistered(puzzleId: puzzleId, parentNftTypeId: parentNftTypeId, childNftTypeIds: childNftTypeIds)
		}
		
		access(all)
		fun combinePuzzle(nftMinter: &NowggNFT.NFTMinter, nftProvider: &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NowggNFT.NowggNFTCollectionPublic}, puzzleId: String, parentNftTypeId: String, childNftIds: [UInt64], metadata:{ String: AnyStruct}){ 
			assert(childNftIds.length < 1000, message: "childNftIds must have less than 1000 elements")
			let puzzle = self.borrowPuzzle(puzzleId: puzzleId)!
			let childNftTypes = puzzle.childNftTypeIds
			for nftId in childNftIds{ 
				let nft = nftProvider.borrowNowggNFT(id: nftId)!
				let metadata = nft.getMetadata()!
				let nftTypeId = metadata["nftTypeId"]! as! String
				assert(childNftTypes.contains(nftTypeId), message: "Incorrect puzzle child NFT provided")
				var index = 0
				for childNftType in childNftTypes{ 
					if childNftType == nftTypeId{ 
						break
					}
					index = index + 1
				}
				childNftTypes.remove(at: index)
			}
			assert(childNftTypes.length == 0, message: "All required puzzle child NFTs not provided")
			nftMinter.mintNFT(recipient: nftProvider, typeId: parentNftTypeId, metaData: metadata)
			for nftId in childNftIds{ 
				destroy <-nftProvider.withdraw(withdrawID: nftId)
			}
			emit PuzzleCombined(puzzleId: puzzleId, by: nftProvider.owner?.address!)
		}
	}
	
	init(){ 
		self.PuzzleHelperStoragePath = /storage/NowggPuzzleHelperStorage
		self.PuzzleHelperPublicPath = /public/NowggPuzzleHelperPublic
		self.allPuzzles ={} 
		let puzzleHelper <- create PuzzleHelper()
		self.account.storage.save(<-puzzleHelper, to: self.PuzzleHelperStoragePath)
		self.account.unlink(self.PuzzleHelperPublicPath)
		var capability_1 =
			self.account.capabilities.storage.issue<&NowggPuzzle.PuzzleHelper>(
				self.PuzzleHelperStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.PuzzleHelperPublicPath)
		emit ContractInitialized()
	}
}
