import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataWrapper from "./MetadataWrapper.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FLOATWrapper{ 
	access(all)
	fun getRef(_ account: Address, _ id: UInt64): &FLOAT.NFT?{ 
		if let collection =
			getAccount(account).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath)
				.borrow<&FLOAT.Collection>(){ 
			if let nft = collection.borrowFLOAT(id: id){ 
				return nft
			}
		}
		return nil
	}
	
	access(all)
	fun getContractAttributes():{ String: AnyStruct}{ 
		return{ 
			"_contract.name": "FLOAT",
			"_contract.borrow_func": "borrowFLOAT",
			"_contract.public_iface": "FLOAT.Collection{FLOAT.CollectionPublic}",
			"_contract.address": 0x2d4c3caffbeab845,
			"_contract.storage_path": FLOAT.FLOATCollectionStoragePath,
			"_contract.public_path": FLOAT.FLOATCollectionPublicPath,
			"_contract.external_domain": "https://floats.city/",
			"_contract.type": Type<@FLOAT.NFT>()
		}
	}
	
	access(all)
	fun getNFTAttributes(_ float: &FLOAT.NFT?):{ String: AnyStruct}{ 
		let display = (float!).resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		return{ 
			"id": (float!).id,
			"uuid": (float!).uuid,
			"_display.name": display.name,
			"_display.description": display.description,
			"_display.thumbnail": (float!).eventImage,
			//medias 
			"_medias":
			[
				MetadataViews.Media(
					file: MetadataViews.HTTPFile(url: (float!).eventImage),
					mediaType: "image"
				)
			],
			//externalURL
			"_externalURL":
			"https://floats.city/".concat((((float!).owner!).address as Address).toString()).concat(
				"/float/"
			).concat((float!).id.toString()),
			//other traits 
			"eventName": (float!).eventName,
			"eventDescription": (float!).eventDescription,
			"eventHost": ((float!).eventHost as Address).toString(),
			"eventId": (float!).eventId.toString(),
			"eventImage": (float!).eventImage,
			"serial": (float!).serial,
			"dateReceived": (float!).dateReceived,
			"royaltyAddress": "0x5643fd47a29770e7",
			"royaltyPercentage": "5.0",
			"type": (float!).getType()
		}
	}
	
	access(all)
	var contractData:{ String: AnyStruct}
	
	access(all)
	fun setup(){ 
		destroy self.account.storage.load<@AnyResource>(from: /storage/FLOAT)
		self.account.storage.save(
			<-create Wrapper(contractData: self.contractData),
			to: /storage/FLOAT
		)
		self.account.unlink(/public/FLOAT)
		var capability_1 =
			self.account.capabilities.storage.issue<&{MetadataWrapper.WrapperInterface}>(
				/storage/FLOAT
			)
		self.account.capabilities.publish(capability_1, at: /public/FLOAT)
		self.account.unlink(FLOAT.FLOATCollectionPublicPath)
		var capability_2 =
			self.account.capabilities.storage.issue<&{MetadataWrapper.WrapperInterface}>(
				/storage/FLOAT
			)
		self.account.capabilities.publish(capability_2, at: FLOAT.FLOATCollectionPublicPath)
	}
	
	access(all)
	init(){ 
		self.contractData = self.getContractAttributes()
		self.setup()
	}
	
	access(all)
	resource Wrapper: MetadataWrapper.WrapperInterface{ 
		access(all)
		fun setData(address: Address, id: UInt64){ 
			self.address = address
			self.id = id
			self.attributes ={} 
			self.views ={} 
			for view in MetadataWrapper.baseViews(){ 
				self.views[view] = "generated"
			}
			if let nft = FLOATWrapper.getRef(self.address, self.id){ 
				self.attributes = FLOATWrapper.getNFTAttributes(nft)
				if let nftMetadata = nft as? &{ViewResolver.Resolver}{ 
					for type in nftMetadata.getViews(){ 
						self.views[type] = "original"
					}
				}
			}
		}
		
		access(all)
		var address: Address
		
		access(all)
		var type: Type
		
		access(all)
		var id: UInt64
		
		access(all)
		var publicPath: PublicPath
		
		access(all)
		var contractData:{ String: AnyStruct}
		
		access(all)
		var attributes:{ String: AnyStruct}
		
		access(all)
		var views:{ Type: String}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			if let nft = FLOATWrapper.getRef(self.address, self.id){ 
				if let viewLocation = self.views[view]{ 
					if viewLocation == "generated"{ 
						return MetadataWrapper.buildView(view, self.attributes)
					}
					if let nftMetadata = nft as? &{ViewResolver.Resolver}{ 
						if let resolved = nftMetadata.resolveView(view){ 
							return resolved
						}
					}
				}
			}
			return nil
		}
		
		access(all)
		fun getViews(): [Type]{ 
			return self.views.keys
		}
		
		init(contractData:{ String: AnyStruct}){ 
			self.id = 0
			self.publicPath = FLOAT.FLOATCollectionPublicPath
			self.address = FLOATWrapper.account.address
			self.type = Type<@FLOAT.NFT>()
			self.contractData = contractData
			self.attributes ={} 
			self.views ={} 
		}
	}
}
