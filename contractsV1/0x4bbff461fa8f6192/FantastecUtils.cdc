access(all)
contract FantastecUtils{ 
	access(all)
	fun splitString(input: String, delimiter: String): [String]{ 
		let parts: [String] = []
		var currentPart = ""
		for char in input{ 
			if char == delimiter[0]{ 
				if currentPart != ""{ 
					parts.append(currentPart)
					currentPart = ""
				}
			} else{ 
				currentPart = currentPart.concat(char.toString())
			}
		}
		if currentPart != ""{ 
			parts.append(currentPart)
		}
		return parts
	}
}
