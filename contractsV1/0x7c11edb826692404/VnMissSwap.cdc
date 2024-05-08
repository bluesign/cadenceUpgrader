import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import VnMiss from "./VnMiss.cdc"

import VnMissCandidate from "./VnMissCandidate.cdc"

access(all)
contract VnMissSwap{ 
	access(all)
	var startAt: UFix64
	
	access(all)
	var endAt: UFix64
	
	access(self)
	let additional:{ UInt64:{ VnMiss.Level: UInt64}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event SwapForNFT(from: [UInt64], to: UInt64, recipient: Address, candidateID: UInt64)
	
	access(all)
	event SwapTimeChange(startAt: UFix64, endAt: UFix64)
	
	access(all)
	fun levelAsString(level: UInt8): String{ 
		switch level{ 
			case VnMiss.Level.Bronze.rawValue:
				return "Bronze"
			case VnMiss.Level.Silver.rawValue:
				return "Silver"
			case VnMiss.Level.Diamond.rawValue:
				return "Diamond"
		}
		return ""
	}
	
	access(all)
	fun swapNFTForNFT(
		list: @[
			VnMiss.NFT; 5
		],
		target: @VnMiss.NFT,
		recipient: Capability<&{NonFungibleToken.CollectionPublic}>
	){ 
		let now = getCurrentBlock().timestamp
		assert(self.startAt <= now && self.endAt >= now, message: "Not open")
		assert(list.length == 5, message: "Should input 5 nft")
		let receiver = recipient.borrow() ?? panic("Collection broken")
		var i = 0
		let level: UInt8 = target.level
		let from: [UInt64] = []
		while i < list.length{ 
			let ref = &list[i] as &VnMiss.NFT
			from.append(ref.id)
			assert(level == ref.level, message: "All nft should use same tier")
			i = i + 1
		}
		let max = fun (level: UInt8): UInt64{ 
				switch level{ 
					case VnMiss.Level.Bronze.rawValue:
						return 195
					case VnMiss.Level.Silver.rawValue:
						return 4
					case VnMiss.Level.Diamond.rawValue:
						return 1
				}
				panic("Level invalid")
			}
		let levelE = VnMiss.Level(rawValue: level)!
		let targetId = target.id
		let candidateID = target.candidateID
		let minted = self.additional[candidateID] ??{} 
		let id = (minted[levelE] ?? max(level)) + 1
		minted[levelE] = id
		self.additional[candidateID] = minted
		let minter =
			self.account.storage.borrow<&VnMiss.NFTMinter>(from: VnMiss.MinterStoragePath)
			?? panic("Can not borrow")
		let c = VnMissCandidate.getCandidate(id: candidateID)!
		minter.mintNFT(
			recipient: receiver,
			candidateID: candidateID,
			level: VnMiss.Level(rawValue: level)!,
			name: c.buildName(level: self.levelAsString(level: level), id: id),
			thumbnail: target.thumbnail
		)
		receiver.deposit(token: <-target)
		emit SwapForNFT(
			from: from,
			to: targetId,
			recipient: recipient.address,
			candidateID: candidateID
		)
		destroy list
	}
	
	access(all)
	resource Admin{ 
		/**
				 * Admin will call this function on demand
				 */
		
		access(all)
		fun setTime(startAt: UFix64, endAt: UFix64){ 
			VnMissSwap.startAt = startAt
			VnMissSwap.endAt = endAt
			emit SwapTimeChange(startAt: startAt, endAt: endAt)
		}
	}
	
	init(){ 
		// Sat Apr 16 2022 15:00:00 GMT+0000
		self.startAt = 1650121200.0
		// Sat Apr 16 2022 16:00:00 GMT+0000
		self.endAt = 1650898800.0
		self.additional ={} 
		self.AdminStoragePath = /storage/BNMUVnMissSwap
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
