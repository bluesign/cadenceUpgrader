access(all)
contract Utils{ 
	access(all)
	struct AddressNamePair{ 
		access(all)
		let address: Address
		
		access(all)
		let name: String
		
		init(address: Address, name: String){ 
			self.address = address
			self.name = name
		}
	}
	
	access(all)
	fun convertStringToAddress(_ input: String): Address?{ 
		var address = input
		if input.utf8[1] == 120{ 
			address = input.slice(from: 2, upTo: input.length)
		}
		var r: UInt64 = 0
		var bytes = address.decodeHex()
		while bytes.length > 0{ 
			r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
		}
		return Address(r)
	}
	
	access(all)
	fun royaltyCutStringToUFix64(_ royaltyCut: String): UFix64{ 
		var decimalPos = 0
		if royaltyCut[0] == "."{ 
			decimalPos = 1
		} else if royaltyCut[1] == "."{ 
			if royaltyCut[0] == "1"{ 
				// "1" in the first postiion must be 1.0 i.e. 100% cut
				return 1.0
			} else if royaltyCut[0] == "0"{ 
				decimalPos = 2
			}
		} else{ 
			// Invalid royalty value
			return 0.0
		}
		var royaltyCutStrLen = royaltyCut.length
		if royaltyCut.length > 8 + decimalPos{ 
			// UFix64 is capped at 8 digits after the decimal
			// so truncate excess decimal values from the string
			royaltyCutStrLen = 8 + decimalPos
		}
		let royaltyCutPercentValue = royaltyCut.slice(from: decimalPos, upTo: royaltyCutStrLen)
		var bytes = royaltyCutPercentValue.utf8
		var i = 0
		var cutValueInteger: UInt64 = 0
		var cutValueDivisor: UFix64 = 1.0
		let zeroAsciiIntValue: UInt64 = 48
		// First convert the string to a non-decimal Integer
		while i < bytes.length{ 
			cutValueInteger = cutValueInteger * 10 + UInt64(bytes[i]) - zeroAsciiIntValue
			cutValueDivisor = cutValueDivisor * 10.0
			i = i + 1
		}
		
		// Convert the resulting Integer to a decimal in the range 0.0 - 0.99999999
		return UFix64(cutValueInteger) / cutValueDivisor
	}
	
	access(all)
	fun getMimeType(_ metadataFileType: String): String{ 
		switch metadataFileType{ 
			case "mp4":
				return "video/mp4"
			case "mov":
				return "video/quicktime"
			case "webm":
				return "video/webm"
			case "ogv":
				return "video/ogg"
			case "png":
				return "image/png"
			case "jpeg":
				return "image/jpeg"
			case "jpg":
				return "image/jpeg"
			case "gif":
				return "image/gif"
			case "webp":
				return "image/webp"
			case "svg":
				return "image/svg+xml"
			case "glb":
				return "model/gltf-binary"
			case "gltf":
				return "model/gltf+json"
			case "obj":
				return "model/obj"
			case "mtl":
				return "model/mtl"
			case "mp3":
				return "audio/mpeg"
			case "ogg":
				return "audio/ogg"
			case "oga":
				return "audio/ogg"
			case "wav":
				return "audio/wav"
			case "html":
				return "text/html"
		}
		return ""
	}
}
