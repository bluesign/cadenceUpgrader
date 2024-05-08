access(all)
contract NeverEndingStory{ 
	access(all)
	resource Story{} 
	
	init(){ 
		self.account.storage.save(<-create Story(), to: /storage/NeverEndingStory)
	}
}
