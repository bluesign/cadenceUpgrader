import MessageCard from "./MessageCard.cdc"

access(all)
contract MessageCardRenderers{ 
	access(all)
	struct SvgPartsRenderer: MessageCard.IRenderer{ 
		access(all)
		let svgParts: [String]
		
		access(all)
		let replaceKeyAndParamKeys:{ String: String}
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		access(all)
		fun render(params:{ String: AnyStruct}): MessageCard.RenderResult{ 
			return MessageCard.RenderResult(dataType: "svg", data: self.generateSvg(params: params), extraData: self.extraData)
		}
		
		access(all)
		fun generateSvg(params:{ String: AnyStruct}): String{ 
			var svg = ""
			for svgPart in self.svgParts{ 
				let paramKey = self.replaceKeyAndParamKeys[svgPart]
				if paramKey != nil{ 
					svg = svg.concat(params[paramKey!] != nil ? params[paramKey!]! as! String : "")
				} else{ 
					svg = svg.concat(svgPart)
				}
			}
			return svg
		}
		
		init(svgParts: [String], replaceKeyAndParamKeys:{ String: String}, extraData:{ String: AnyStruct}){ 
			self.svgParts = svgParts
			self.replaceKeyAndParamKeys = replaceKeyAndParamKeys
			self.extraData = extraData
		}
	}
}
