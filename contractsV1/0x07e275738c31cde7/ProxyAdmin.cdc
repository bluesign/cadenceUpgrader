import AFLPack from "../0x8f9231920da9af6d/AFLPack.cdc"

access(all)
contract ProxyAdmin{ 
	access(all)
	resource interface MinterProxyPublic{ 
		access(all)
		fun setMinterCapability(cap: Capability<&AFLPack.Pack>)
	}
	
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		access(self)
		var minterCapability: Capability<&AFLPack.Pack>?
		
		access(all)
		fun setMinterCapability(cap: Capability<&AFLPack.Pack>){ 
			self.minterCapability = cap
		}
		
		access(all)
		fun updateOwner(owner: Address){ 
			((self.minterCapability!).borrow()!).updateOwnerAddress(owner: owner)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	init(){ 
		self.account.storage.save(<-create MinterProxy(), to: /storage/proxy)
		var capability_1 = self.account.capabilities.storage.issue<&MinterProxy>(/storage/proxy)
		self.account.capabilities.publish(capability_1, at: /public/proxy)
	}
}
