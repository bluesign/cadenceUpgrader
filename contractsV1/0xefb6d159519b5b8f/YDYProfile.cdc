access(all)
contract YDYProfile{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let adminStoragePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(all)
		fun getUserData():{ String: String}
		
		access(all)
		fun getWorkoutIDs(): [String]
		
		access(all)
		fun getWorkoutData(id: String):{ String: String}
		
		access(contract)
		fun updateUserData(key: String, value: String)
		
		access(contract)
		fun addWorkoutData(workout:{ String: String})
		
		access(contract)
		fun updateWorkoutData(id: String, key: String, value: String)
	}
	
	access(all)
	resource User: Public{ 
		access(all)
		var userData:{ String: String}
		
		access(all)
		var workoutData:{ String:{ String: String}}
		
		init(){ 
			self.userData ={} 
			self.workoutData ={} 
		}
		
		access(all)
		fun getUserData():{ String: String}{ 
			return self.userData
		}
		
		access(all)
		fun getWorkoutIDs(): [String]{ 
			return self.workoutData.keys
		}
		
		access(all)
		fun getWorkoutData(id: String):{ String: String}{ 
			return self.workoutData[id] ?? panic("No workout with this ID exists for user")
		}
		
		access(contract)
		fun updateUserData(key: String, value: String){ 
			self.userData[key] = value
		}
		
		access(contract)
		fun addWorkoutData(workout:{ String: String}){ 
			var id = workout["session_id"] ?? panic("No session_id in workout data")
			self.workoutData[id] = workout
		}
		
		access(contract)
		fun updateWorkoutData(id: String, key: String, value: String){ 
			var workout = self.workoutData[id] ?? panic("No workout with this ID exists for user")
			workout[key] = value
		}
	}
	
	access(all)
	fun createUser(): @User{ 
		return <-create User()
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun updateDataOfUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			key: String,
			value: String
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.updateUserData(key: key, value: value)
		}
		
		access(all)
		fun addWorkoutDataToUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			data:{ 
				String: String
			}
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.addWorkoutData(workout: data)
		}
		
		access(all)
		fun updateWorkoutDataOfUser(
			receiverCollectionCapability: Capability<&YDYProfile.User>,
			id: String,
			key: String,
			value: String
		){ 
			let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
			receiver.updateWorkoutData(id: id, key: key, value: value)
		}
		
		access(all)
		fun superFunction(receiverAddress: Address, nft_id: UInt64){} 
	}
	
	init(){ 
		self.publicPath = /public/YDYProfileStaging
		self.storagePath = /storage/YDYProfileStaging
		self.adminStoragePath = /storage/YDYAdminStaging
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.adminStoragePath)
	}
}
