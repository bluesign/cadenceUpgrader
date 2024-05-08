access(all)
contract MediaArts{ 
	access(all)
	var latestID: UInt32
	
	access(all)
	resource MediaArt{ 
		access(all)
		let id: UInt32
		
		init(){ 
			self.id = MediaArts.latestID
			MediaArts.latestID = MediaArts.latestID + 1
		}
		
		access(all)
		fun isMediaArt(): Bool{ 
			return self.id == MediaArts.latestID
		}
	}
	
	access(all)
	fun _create(): @MediaArt{ 
		return <-create MediaArt()
	}
	
	init(){ 
		self.latestID = 0
	}
}
