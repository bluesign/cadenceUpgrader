access(all)
contract EventEmitter{ 
	access(all)
	event StringEvent(_ value: String)
	
	access(all)
	event AddressEvent(_ value: Address)
	
	access(all)
	fun EmitString(_ value: String){ 
		emit StringEvent(value)
	}
	
	access(all)
	fun EmitAddress(_ value: Address){ 
		emit AddressEvent(value)
	}
	
	init(){} 
}
