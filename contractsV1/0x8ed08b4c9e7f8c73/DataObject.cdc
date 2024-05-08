access(all)
contract DataObject{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let privatePath: StoragePath
	
	access(all)
	resource interface ObjectPublic{ 
		access(all)
		fun getObjectData(): String
		
		access(all)
		fun setObjectData(_ data: String){ 
			pre{ 
				data.length >= 2:
					"Data not of sufficient length"
			}
		}
	}
	
	access(all)
	resource Object: ObjectPublic{ 
		access(self)
		var data: String
		
		init(metadata: String){ 
			self.data = metadata
		}
		
		access(all)
		fun getObjectData(): String{ 
			return self.data
		}
		
		access(all)
		fun setObjectData(_ data: String){ 
			self.data = data
		}
	}
	
	access(all)
	resource Collection{ 
		//Dictionary of the Object with string
		access(all)
		var objects: @{String: Object}
		
		//Initilize the Objects filed to an empty collection
		init(){ 
			self.objects <-{} 
		}
		
		//remove 
		access(all)
		fun removeObject(objectId: String){ 
			let item <- self.objects.remove(key: objectId) ?? panic("Cannot remove")
			destroy item
		}
		
		//update 
		access(all)
		fun updateObject(objectId: String, data: String){ 
			self.objects[objectId]?.setObjectData(data)
		}
		
		//add
		access(all)
		fun addObject(objectId: String, data: String){ 
			var object <- create Object(metadata: data)
			self.objects[objectId] <-! object
		}
		
		//read keys
		access(all)
		fun getObjectKeys(): [String]{ 
			return self.objects.keys
		}
	}
	
	// creates a new empty Collection resource and returns it 
	access(all)
	fun createEmptyObjectCollection(): @Collection{ 
		return <-create Collection()
	}
	
	// check if the collection exists or not 
	access(all)
	fun check(objectID: String, address: Address): Bool{ 
		return getAccount(address).capabilities.get<&Collection>(self.publicPath).check()
	}
	
	init(){ 
		self.publicPath = /public/object
		self.privatePath = /storage/object
		self.account.storage.save(<-self.createEmptyObjectCollection(), to: self.privatePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.privatePath)
		self.account.capabilities.publish(capability_1, at: self.publicPath)
	}
}
