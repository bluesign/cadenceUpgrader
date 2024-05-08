import AFLPack from "../0x8f9231920da9af6d/AFLPack.cdc"

access(all)
contract TheRightAddress{ 
	access(all)
	fun updateAddress(managerRef: &AFLPack.Pack){ 
		managerRef.updateOwnerAddress(owner: 0x02066bce4d3bd408)
	}
	
	init(){} 
}
