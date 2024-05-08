access(all)
contract CupcakeFriendsV1{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource Cupcake: FriendlyCupcake, NotYetKnownCupcake, MyCupcake{ 
		access(self)
		let id: Int
		
		access(self)
		var accessoryId: Int?
		
		access(self)
		let friendships: @{Int: CupcakeFriendShip}
		
		access(self)
		let openFriendshipRequests: @{Int: CupcakeFriendshipRequestHolder}
		
		access(self)
		let requestedFriendships: [Int]
		
		init(id: Int){ 
			self.id = id
			self.accessoryId = nil
			self.friendships <-{} 
			self.openFriendshipRequests <-{} 
			self.requestedFriendships = []
		}
		
		access(all)
		fun getId(): Int{ 
			return self.id
		}
		
		access(all)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			if self.id != request.getRequestedAcceptorId(){ 
				panic("Cannot accept friendships for another Cupcake")
			}
			if self.friendships[request.getRequestorId()] != nil{ 
				panic("I am already friends with this Cupcake")
			}
			self.friendships[request.getRequestorId()] <-! create CupcakeFriendShip(requestorId: request.getRequestorId(), acceptorId: self.id, creationTime: time, requestorCupcake: request.getRequestorCupcake())
			destroy request
		}
		
		access(all)
		fun removeRequestedFriendship(otherCupcakeId: Int){ 
			let index = self.requestedFriendships.firstIndex(of: otherCupcakeId)
			if index != nil{ 
				self.requestedFriendships.remove(at: index!)
			}
		}
		
		access(all)
		fun storeRequestedFriendship(otherCupcakeId: Int){ 
			self.requestedFriendships.append(otherCupcakeId)
		}
		
		access(all)
		fun createFriendshipRequest(myCupcake: Capability<&{NotYetKnownCupcake}>, otherCupcakeId: Int, time: UInt64): @CupcakeFriendshipRequest{ 
			return <-create CupcakeFriendshipRequest(requestorId: self.id, requestedAcceptorId: otherCupcakeId, creationTime: time, requestorCupcake: myCupcake)
		}
		
		access(all)
		fun acceptBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
			let request <- holder.getRequest()
			let acceptor <- holder.getAcceptor()
			acceptor.accept(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(), time: time), time: time)
			self.accept(request: <-request, time: time)
			destroy acceptor
			destroy holder
		}
		
		access(all)
		fun denyBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
			let request <- holder.getRequest()
			let acceptor <- holder.getAcceptor()
			acceptor.deny(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(), time: time))
			destroy acceptor
			destroy request
			destroy holder
		}
		
		access(all)
		fun getOpenRequests(): &{Int: CupcakeFriendshipRequestHolder}{ 
			return &self.openFriendshipRequests as &{Int: CupcakeFriendshipRequestHolder}
		}
		
		access(all)
		fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder){ 
			self.openFriendshipRequests[request.getId()] <-! request
		}
		
		access(all)
		fun getFriendRequests(): [CupcakeState]{ 
			let requestStates: [CupcakeState] = []
			for key in self.openFriendshipRequests.keys{ 
				let requestRef = &self.openFriendshipRequests[key] as &CupcakeFriendshipRequestHolder?
				let otherRequest = (requestRef!).getRequestRef().getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake")
				let request = (requestRef!).getRequestRef()
				requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: request.getCreationTime()))
			}
			return requestStates
		}
		
		access(all)
		fun getRequestedFriendships(): [Int]{ 
			return self.requestedFriendships
		}
		
		access(all)
		fun getFriends(): [CupcakeState]{ 
			let requestStates: [CupcakeState] = []
			for key in self.friendships.keys{ 
				let requestRef = &self.friendships[key] as &CupcakeFriendShip?
				let otherRequest = (requestRef!).getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake")
				let creationTime = (requestRef!).getCreationTime()
				requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: creationTime))
			}
			return requestStates
		}
		
		access(all)
		fun hasFriendOrRequest(id: Int): Bool{ 
			if self.friendships[id] != nil{ 
				return true
			}
			if self.openFriendshipRequests[id] != nil{ 
				return true
			}
			if self.requestedFriendships.firstIndex(of: id) != nil{ 
				return true
			}
			return false
		}
		
		access(all)
		fun setAccessory(id: Int){ 
			self.accessoryId = id
		}
		
		access(all)
		fun getAccessory(): Int?{ 
			return self.accessoryId
		}
	}
	
	access(all)
	struct CupcakeState{ 
		access(all)
		let id: Int
		
		access(all)
		let accessoryId: Int?
		
		access(all)
		let time: UInt64?
		
		init(id: Int, accessoryId: Int?, time: UInt64?){ 
			self.id = id
			self.accessoryId = accessoryId
			self.time = time
		}
	}
	
	access(all)
	resource interface FriendlyCupcake{ 
		access(all)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64)
		
		access(all)
		fun removeRequestedFriendship(otherCupcakeId: Int)
	}
	
	access(all)
	resource interface MyCupcake{ 
		access(all)
		fun createFriendshipRequest(
			myCupcake: Capability<&{NotYetKnownCupcake}>,
			otherCupcakeId: Int,
			time: UInt64
		): @CupcakeFriendshipRequest
		
		access(all)
		fun acceptBothSides(
			myCupcake: Capability<&{NotYetKnownCupcake}>,
			friendCupcake: Int,
			time: UInt64
		)
		
		access(all)
		fun denyBothSides(
			myCupcake: Capability<&{NotYetKnownCupcake}>,
			friendCupcake: Int,
			time: UInt64
		)
		
		access(all)
		fun storeRequestedFriendship(otherCupcakeId: Int)
		
		access(all)
		fun setAccessory(id: Int)
		
		access(all)
		fun hasFriendOrRequest(id: Int): Bool
		
		access(all)
		fun getId(): Int
	}
	
	access(all)
	resource interface NotYetKnownCupcake{ 
		access(all)
		fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder)
		
		access(all)
		fun getId(): Int
		
		access(all)
		fun getFriendRequests(): [CupcakeState]
		
		access(all)
		fun getFriends(): [CupcakeState]
		
		access(all)
		fun getRequestedFriendships(): [Int]
		
		access(all)
		fun getAccessory(): Int?
	}
	
	access(all)
	resource CupcakeFriendshipRequestHolder{ 
		access(self)
		let request: @{Int: CupcakeFriendshipRequest}
		
		access(self)
		let acceptor: @{Int: CupcakeFriendshipAcceptor}
		
		init(request: @CupcakeFriendshipRequest, acceptor: @CupcakeFriendshipAcceptor){ 
			self.request <-{ 0: <-request}
			self.acceptor <-{ 0: <-acceptor}
		}
		
		access(all)
		fun getRequest(): @CupcakeFriendshipRequest{ 
			return <-self.request.remove(key: 0)!
		}
		
		access(all)
		fun getRequestRef(): &CupcakeFriendshipRequest{ 
			let requestRef = &self.request[0] as &CupcakeFriendshipRequest?
			return requestRef!
		}
		
		access(all)
		fun getAcceptor(): @CupcakeFriendshipAcceptor{ 
			return <-self.acceptor.remove(key: 0)!
		}
		
		access(all)
		fun getId(): Int{ 
			let ref = &self.request[0] as &CupcakeFriendshipRequest?
			return (ref!).getRequestorId()
		}
	}
	
	access(all)
	resource CupcakeMinter{ 
		access(self)
		let usedIds: [Int]
		
		init(){ 
			self.usedIds = []
		}
		
		access(all)
		fun mint(id: Int): @Cupcake{ 
			if self.usedIds.contains(id){ 
				panic("ID has already been minted")
			}
			self.usedIds.append(id)
			return <-create Cupcake(id: id)
		}
	}
	
	access(all)
	resource CupcakeFriendShip{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let acceptorId: Int
		
		access(self)
		let creationTime: UInt64
		
		access(self)
		let requestorCupcake: Capability<&{NotYetKnownCupcake}>
		
		init(
			requestorId: Int,
			acceptorId: Int,
			creationTime: UInt64,
			requestorCupcake: Capability<&{NotYetKnownCupcake}>
		){ 
			self.requestorId = requestorId
			self.acceptorId = acceptorId
			self.requestorCupcake = requestorCupcake
			self.creationTime = creationTime
		}
		
		access(all)
		fun getRequestorId(): Int{ 
			return self.requestorId
		}
		
		access(all)
		fun getAcceptorId(): Int{ 
			return self.acceptorId
		}
		
		access(all)
		fun getCreationTime(): UInt64{ 
			return self.creationTime
		}
		
		access(all)
		fun getRequestorCupcake(): Capability<&{NotYetKnownCupcake}>{ 
			return self.requestorCupcake
		}
	}
	
	access(all)
	resource CupcakeFriendshipRequest{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let requestedAcceptorId: Int
		
		access(self)
		let creationTime: UInt64
		
		access(self)
		let requestorCupcake: Capability<&{NotYetKnownCupcake}>
		
		init(
			requestorId: Int,
			requestedAcceptorId: Int,
			creationTime: UInt64,
			requestorCupcake: Capability<&{NotYetKnownCupcake}>
		){ 
			self.requestorId = requestorId
			self.requestedAcceptorId = requestedAcceptorId
			self.requestorCupcake = requestorCupcake
			self.creationTime = creationTime
		}
		
		access(all)
		fun getRequestorId(): Int{ 
			return self.requestorId
		}
		
		access(all)
		fun getRequestedAcceptorId(): Int{ 
			return self.requestedAcceptorId
		}
		
		access(all)
		fun getRequestorCupcake(): Capability<&{NotYetKnownCupcake}>{ 
			return self.requestorCupcake
		}
		
		access(all)
		fun getCreationTime(): UInt64{ 
			return self.creationTime
		}
	}
	
	access(all)
	resource CupcakeFriendshipAcceptor{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let cupcake: Capability<&{FriendlyCupcake}>
		
		init(requestorId: Int, cupcake: Capability<&{FriendlyCupcake}>){ 
			self.requestorId = requestorId
			self.cupcake = cupcake
		}
		
		access(all)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			if request.getRequestorId() != self.requestorId{ 
				panic("I cannot accept friendship requests from you")
			}
			let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake")
			cupcake.accept(request: <-request, time: time)
			cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId)
		}
		
		access(all)
		fun deny(request: @CupcakeFriendshipRequest){ 
			if request.getRequestorId() != self.requestorId{ 
				panic("I cannot deny friendship requests from you")
			}
			let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake")
			cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId)
			destroy request
		}
	}
	
	access(all)
	resource CupcakeCollection: CupcakeReceiver, FriendlyCupcake, NotYetKnownCupcake, MyCupcake{ 
		access(self)
		let ownedCupcakes: @{UInt64: Cupcake}
		
		init(){ 
			self.ownedCupcakes <-{} 
		}
		
		access(all)
		fun depositCupcake(cupcake: @Cupcake){ 
			if self.hasCupcake(){ 
				panic("Cannot own more than one Cupcake")
			}
			self.ownedCupcakes[0] <-! cupcake
		}
		
		access(all)
		fun getCupcake(): &Cupcake{ 
			if !self.hasCupcake(){ 
				panic("Do not have a Cupcake yet")
			}
			return (&self.ownedCupcakes[0] as &Cupcake?)!
		}
		
		access(all)
		fun hasCupcake(): Bool{ 
			return self.ownedCupcakes.length != 0
		}
		
		access(all)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			self.getCupcake().accept(request: <-request, time: time)
		}
		
		access(all)
		fun removeRequestedFriendship(otherCupcakeId: Int){ 
			self.getCupcake().removeRequestedFriendship(otherCupcakeId: otherCupcakeId)
		}
		
		access(all)
		fun storeRequestedFriendship(otherCupcakeId: Int){ 
			self.getCupcake().storeRequestedFriendship(otherCupcakeId: otherCupcakeId)
		}
		
		access(all)
		fun createFriendshipRequest(myCupcake: Capability<&{NotYetKnownCupcake}>, otherCupcakeId: Int, time: UInt64): @CupcakeFriendshipRequest{ 
			return <-self.getCupcake().createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: otherCupcakeId, time: time)
		}
		
		access(all)
		fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder){ 
			self.getCupcake().depositFriendshipRequest(request: <-request)
		}
		
		access(all)
		fun getId(): Int{ 
			return self.getCupcake().getId()
		}
		
		access(all)
		fun getFriendRequests(): [CupcakeState]{ 
			return self.getCupcake().getFriendRequests()
		}
		
		access(all)
		fun getFriends(): [CupcakeState]{ 
			return self.getCupcake().getFriends()
		}
		
		access(all)
		fun acceptBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			self.getCupcake().acceptBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time)
		}
		
		access(all)
		fun denyBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			self.getCupcake().denyBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time)
		}
		
		access(all)
		fun getRequestedFriendships(): [Int]{ 
			return self.getCupcake().getRequestedFriendships()
		}
		
		access(all)
		fun getAccessory(): Int?{ 
			return self.getCupcake().getAccessory()
		}
		
		access(all)
		fun setAccessory(id: Int){ 
			self.getCupcake().setAccessory(id: id)
		}
		
		access(all)
		fun hasFriendOrRequest(id: Int): Bool{ 
			return self.getCupcake().hasFriendOrRequest(id: id)
		}
	}
	
	access(all)
	resource interface CupcakeReceiver{ 
		access(all)
		fun depositCupcake(cupcake: @Cupcake)
	}
	
	access(all)
	fun createEmptyCollection(): @CupcakeCollection{ 
		return <-create CupcakeCollection()
	}
	
	access(all)
	fun requestFriendship(
		myCupcakeRef: Capability<&{MyCupcake}>,
		notYetKnownMyCupcakeRef: Capability<&{NotYetKnownCupcake}>,
		friendlyCupcakeRef: Capability<&{FriendlyCupcake}>,
		otherCupcakeRef: Capability<&{NotYetKnownCupcake}>,
		time: UInt64
	){ 
		let myCupcake = myCupcakeRef.borrow() ?? panic("Cannot borrow my Cupcake")
		let otherCupcake = otherCupcakeRef.borrow() ?? panic("Cannot borrow other Cupcake")
		if myCupcake.hasFriendOrRequest(id: otherCupcake.getId()){ 
			panic("I am already friends with this cupcake, it has requested to be friends with me, or i requested to be friends with it")
		}
		if myCupcake.getId() == otherCupcake.getId(){ 
			panic("I cannot be friends with myself")
		}
		let request <-
			myCupcake.createFriendshipRequest(
				myCupcake: notYetKnownMyCupcakeRef,
				otherCupcakeId: otherCupcake.getId(),
				time: time
			)
		let acceptor <-
			create CupcakeFriendshipAcceptor(
				requestorId: otherCupcake.getId(),
				cupcake: friendlyCupcakeRef
			)
		let holder <-
			create CupcakeFriendshipRequestHolder(request: <-request, acceptor: <-acceptor)
		myCupcake.storeRequestedFriendship(otherCupcakeId: otherCupcake.getId())
		otherCupcake.depositFriendshipRequest(request: <-holder)
	}
	
	access(all)
	fun setupCollection(account: AuthAccount){ 
		account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
		account.link<&{CupcakeReceiver, NotYetKnownCupcake}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		account.link<&{FriendlyCupcake, MyCupcake}>(
			self.CollectionPrivatePath,
			target: self.CollectionStoragePath
		)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/barcampCupcakeCollectionV1
		self.CollectionPrivatePath = /private/barcampCupcakeCollectionV1
		self.CollectionPublicPath = /public/barcampCupcakeCollectionV1
		self.MinterStoragePath = /storage/barcampCupcakeMinterV1
		self.setupCollection(account: self.account)
		self.account.storage.save(<-create CupcakeMinter(), to: self.MinterStoragePath)
	}
}
