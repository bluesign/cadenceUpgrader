access(all)
contract Heartbeat{ 
	access(all)
	event heartbeat(pulseUUID: UInt64, message: String, ts_begin: Int64)
	
	access(all)
	let greeting: String
	
	access(all)
	resource Pulse{ 
		access(all)
		var ts_begin: Int64
		
		access(all)
		var message: String
		
		init(ts_begin: Int64, message: String){ 
			self.ts_begin = ts_begin
			self.message = message
		}
	}
	
	access(all)
	fun generatePulse(ts_begin: Int64, message: String){ 
		let newPulse <- create Pulse(ts_begin: ts_begin, message: message)
		emit heartbeat(
			pulseUUID: newPulse.uuid,
			message: newPulse.message,
			ts_begin: newPulse.ts_begin
		)
		destroy newPulse
	}
	
	init(){ 
		self
			.greeting = "\u{1f44b}Greetings from Graffle.io!\u{1f469}\u{200d}\u{1f680}\u{1f680}\u{1f468}\u{200d}\u{1f680}"
	}
}
