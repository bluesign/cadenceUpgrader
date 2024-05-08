import ContractVersion from "./ContractVersion.cdc"

pub contract Pausable: ContractVersion {

  pub fun getVersion(): String {
    return "1.1.5"
  }

  pub event Paused(account: Address)
  pub event Unpaused(account: Address)

  pub resource interface PausableExternal {
    pub fun isPaused(): Bool
  }

  pub resource interface PausableInternal {
    pub fun pause()
    pub fun unPause()
  }
  
  pub resource PausableResource: PausableInternal, PausableExternal {    
    access(self) var paused: Bool

    init(paused: Bool) {
      self.paused = paused
    }

    pub fun isPaused(): Bool {
      return self.paused
    }

    pub fun pause() {
      pre {
        self.paused == false: "Invalid: The resource is paused already"
      }
      self.paused = true
      emit Paused(account: self.owner!.address)
    }

    pub fun unPause() {
      pre {
        self.paused == true: "Invalid: The resource is not paused"
      }
      self.paused = false
      emit Unpaused(account: self.owner!.address)
    }
  }

  pub fun createResource(paused: Bool): @PausableResource {
    return <- create PausableResource(paused: paused)
  } 

  init(){}
}