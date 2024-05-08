import StringUtils from "./../../standardsV1/StringUtils.cdc"

access(all)
contract GameBoardUtils{ 
	access(all)
	fun convertRelativePositionsToString(_ positions: [[Int]]): String{ 
		var res: [String] = []
		for p in positions{ 
			res.append(StringUtils.joinInts(p, ","))
		}
		return StringUtils.join(res, "|")
	}
	
	access(all)
	fun convertStringToRelativePositions(_ str: String): [[Int]]{ 
		var relativePositions: [[Int]] = []
		let positionsArr: [String] = StringUtils.split(str, "|")
		var index = 0
		for p in positionsArr{ 
			relativePositions.append([])
			let positions: [String] = StringUtils.split(p, ",")
			for pos in positions{ 
				relativePositions[index].append(Int.fromString(pos)!)
			}
			index = index + 1
		}
		return relativePositions
	}
}
