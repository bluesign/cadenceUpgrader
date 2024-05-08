access(all)
contract Ping{ 
	access(all)
	event PingEmitted(sound: String)
	
	access(all)
	var sound: String
	
	access(all)
	init(){ 
		self.sound = "ping ping ping"
	}
	
	access(all)
	fun setSound(sound: String){ 
		self.sound = sound
	}
	
	access(all)
	fun getSound(): String{ 
		return self.sound
	}
	
	access(all)
	fun echo(){ 
		emit PingEmitted(sound: self.sound)
	}
}
