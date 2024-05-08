pub contract Ping {
	pub event PingEmitted(sound: String)
	pub(set) var sound: String

	pub init() {
		self.sound = "ping ping ping"
	}

	pub fun setSound(sound: String) {
		self.sound = sound
	}

	pub fun getSound(): String {
		return self.sound
	}

	pub fun echo() {
		emit PingEmitted(sound: self.sound)
	}
}