pub contract Stuff {
  pub var name: String

  pub fun changeName(newName: String) {
    self.name = newName
  }
  
  init() {
    self.name = "Sahil Saha"
  }
} 