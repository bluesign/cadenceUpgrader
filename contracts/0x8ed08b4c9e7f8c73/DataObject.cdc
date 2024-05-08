pub contract DataObject {
  pub let publicPath: PublicPath
  pub let privatePath: StoragePath
  
  pub resource interface ObjectPublic {
    pub fun getObjectData(): String
    pub fun setObjectData(_ data: String){
      pre {
        data.length >= 2: "Data not of sufficient length"
      }
    }
  }

  pub resource Object:ObjectPublic {
    access(self) var data: String
    
    init(metadata: String){
      self.data = metadata
    }

    pub fun getObjectData(): String { return self.data }
    pub fun setObjectData(_ data: String) { self.data = data }

  }

  pub resource Collection {
    //Dictionary of the Object with string
    pub var objects: @{String: Object}

    //Initilize the Objects filed to an empty collection
    init() {
      self.objects <- {}
    }

    //remove 
    pub fun removeObject(objectId: String) {
      let item <- self.objects.remove(key: objectId) 
      ?? panic("Cannot remove")
      destroy item
    }

    //update 
    pub fun updateObject(objectId: String, data: String){
      self.objects[objectId]?.setObjectData(data)
    }

    //add
    pub fun addObject(objectId: String, data: String){
      var object <- create Object(metadata: data)
      self.objects[objectId] <-! object
    }

    //read keys
    pub fun getObjectKeys(): [String] {
        return self.objects.keys
    }
    destroy() {
        destroy self.objects
    }
  }

  // creates a new empty Collection resource and returns it 
  pub fun createEmptyObjectCollection(): @Collection {
    return <- create Collection()
  } 

  // check if the collection exists or not 
  pub fun check(objectID: String, address: Address): Bool {
    return getAccount(address)
      .getCapability<&Collection>(self.publicPath)
      .check()
  }

  init() {
    self.publicPath = /public/object
    self.privatePath = /storage/object

    self.account.save(<- self.createEmptyObjectCollection(), to: self.privatePath)

    self.account.link<&Collection>(self.publicPath, target: self.privatePath)
  }


}