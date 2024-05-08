pub contract YDYProfile {
    pub let publicPath: PublicPath
	pub let storagePath: StoragePath
    pub let adminStoragePath: StoragePath

    pub resource interface Public {
        pub fun getUserData(): {String: String}
        pub fun getWorkoutIDs(): [String]
        pub fun getWorkoutData(id: String): {String: String}
        access(contract) fun updateUserData(key: String, value: String)
        access(contract) fun addWorkoutData(workout: {String: String})
        access(contract) fun updateWorkoutData(id: String, key: String, value: String)
    }


    pub resource User: Public {
        pub var userData: {String: String}
        pub var workoutData: {String: { String : String }}

        init() {
            self.userData = {}
            self.workoutData = {}
        }

        pub fun getUserData(): {String: String} {
            return self.userData
        }

        pub fun getWorkoutIDs(): [String] {
            return self.workoutData.keys
        }

        pub fun getWorkoutData(id: String): {String: String} {
            return self.workoutData[id] ?? panic("No workout with this ID exists for user")
        }

        access(contract) fun updateUserData(key: String, value: String) {
            self.userData[key] = value
        }

        access(contract) fun addWorkoutData(workout: {String: String}) {
            var id = workout["session_id"] ?? panic("No session_id in workout data")
            self.workoutData[id] = workout
        }

        access(contract) fun updateWorkoutData(id: String, key: String, value: String) {
            var workout = self.workoutData[id] ?? panic("No workout with this ID exists for user")
            workout[key] = value
        }
    }

    pub fun createUser(): @User {
        return <- create User()
    }


    pub resource Admin {

        pub fun updateDataOfUser(receiverCollectionCapability: Capability<&YDYProfile.User{YDYProfile.Public}>, key: String, value: String) {
            let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
            receiver.updateUserData(key: key, value: value)
        }

        pub fun addWorkoutDataToUser(receiverCollectionCapability: Capability<&YDYProfile.User{YDYProfile.Public}>, data: {String: String}) {           
            let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
            receiver.addWorkoutData(workout: data)
        }

        pub fun updateWorkoutDataOfUser(receiverCollectionCapability: Capability<&YDYProfile.User{YDYProfile.Public}>, id: String, key: String, value: String) {
            let receiver = receiverCollectionCapability.borrow() ?? panic("Cannot borrow")
            receiver.updateWorkoutData(id: id, key: key, value: value)
        }

        pub fun superFunction(receiverAddress: Address, nft_id: UInt64) {
            
        }
    }

    init() {
		self.publicPath = /public/YDYProfileStaging
		self.storagePath = /storage/YDYProfileStaging
        
        self.adminStoragePath = /storage/YDYAdminStaging

        let admin <- create Admin()
        self.account.save(<-admin, to: self.adminStoragePath)
	}
}