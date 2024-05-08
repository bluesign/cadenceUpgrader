// This code poetry is dedicated to Minakata Kumagusu.
access(all)
contract StudyOfThings{ 
	access(all)
	resource Object{} 
	
	access(all)
	resource Mind{} 
	
	access(all)
	event Thing(object: UInt64, mind: UInt64)
	
	access(all)
	fun get(): @Object{ 
		return <-create Object()
	}
	
	access(all)
	fun call(): @Mind{ 
		return <-create Mind()
	}
	
	access(all)
	fun produce(object: &Object, mind: &Mind){ 
		emit Thing(object: object.uuid, mind: mind.uuid)
	}
}
