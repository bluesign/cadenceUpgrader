
access(all) contract CupcakeFriendsV1 {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let MinterStoragePath: StoragePath

    pub resource Cupcake : FriendlyCupcake,NotYetKnownCupcake,MyCupcake {
        priv let id : Int;
        priv var accessoryId : Int?;
        priv let friendships : @{Int : CupcakeFriendShip};
        priv let openFriendshipRequests : @{Int: CupcakeFriendshipRequestHolder};
        priv let requestedFriendships : [Int];

        init(id: Int) {
            self.id = id;
            self.accessoryId = nil;
            self.friendships <- {}
            self.openFriendshipRequests <- {};
            self.requestedFriendships = [];
        }

        pub fun getId() : Int {
            return self.id;
        }

        pub fun accept(request : @CupcakeFriendshipRequest, time : UInt64) {
            if(self.id != request.getRequestedAcceptorId()) {
                panic("Cannot accept friendships for another Cupcake");
            }
            if(self.friendships[request.getRequestorId()] != nil) {
                panic("I am already friends with this Cupcake");
            }
            self.friendships[request.getRequestorId()] <-! create CupcakeFriendShip(requestorId: request.getRequestorId(), acceptorId: self.id, creationTime: time, requestorCupcake: request.getRequestorCupcake());
            destroy request;
        }

        pub fun removeRequestedFriendship(otherCupcakeId : Int) {
            let index = self.requestedFriendships.firstIndex(of: otherCupcakeId)
            if(index != nil) {
                self.requestedFriendships.remove(at: index!);
            }
        } 
        
        pub fun storeRequestedFriendship(otherCupcakeId : Int) {
            self.requestedFriendships.append(otherCupcakeId);
        }

        pub fun createFriendshipRequest(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,otherCupcakeId : Int, time : UInt64) : @CupcakeFriendshipRequest {
            return <- create CupcakeFriendshipRequest(requestorId: self.id, requestedAcceptorId: otherCupcakeId, creationTime: time, requestorCupcake: myCupcake);
        }

        

        pub fun acceptBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time : UInt64) {
            let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
            let request <- holder.getRequest()
            let acceptor <- holder.getAcceptor()
            acceptor.accept(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(),time: time), time: time)
            self.accept(request: <- request, time: time)

            destroy acceptor
            destroy holder;
        }

        pub fun denyBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time: UInt64) {
            let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
            let request <- holder.getRequest()
            let acceptor <- holder.getAcceptor()
            acceptor.deny(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(), time: time))
            destroy acceptor;
            destroy request;
            destroy holder;
        }

        pub fun getOpenRequests() : &{Int: CupcakeFriendshipRequestHolder} {
            return &self.openFriendshipRequests as &{Int: CupcakeFriendshipRequestHolder}
        }

        pub fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder) {
            self.openFriendshipRequests[request.getId()] <-! request;
        }

        pub fun getFriendRequests() : [CupcakeState] {
            let requestStates : [CupcakeState] = [];
            for key in self.openFriendshipRequests.keys {
                let requestRef = &self.openFriendshipRequests[key] as &CupcakeFriendshipRequestHolder?
                let otherRequest = requestRef!.getRequestRef().getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake");
                let request = requestRef!.getRequestRef();
                requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: request.getCreationTime()));
            }
            return requestStates;
        }
        pub fun getRequestedFriendships() : [Int] {
            return self.requestedFriendships;
        }
        pub fun getFriends() : [CupcakeState] {
            let requestStates : [CupcakeState] = [];
            for key in self.friendships.keys {
                let requestRef = &self.friendships[key] as &CupcakeFriendShip?
                let otherRequest = requestRef!.getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake");
                let creationTime = requestRef!.getCreationTime();
                requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: creationTime));
            }
            return requestStates;
        }

        
        pub fun hasFriendOrRequest(id : Int) : Bool {
            if(self.friendships[id] != nil) {
                return true;
            }
            if(self.openFriendshipRequests[id] != nil) {
                return true;
            }
            if(self.requestedFriendships.firstIndex(of: id) != nil) {
                return true;
            }
            return false;
        }

        pub fun setAccessory(id : Int) {
            self.accessoryId = id;
        }

        pub fun getAccessory() : Int? {
            return self.accessoryId
        }


        destroy() {
            destroy self.friendships;
            destroy self.openFriendshipRequests;
        }

    }

    pub struct CupcakeState {
        pub let id : Int;
        pub let accessoryId : Int?;
        pub let time : UInt64?;

        init(id : Int, accessoryId : Int?, time : UInt64?) {
            self.id = id;
            self.accessoryId = accessoryId;
            self.time = time;
        }
    }

    pub resource interface FriendlyCupcake {
        pub fun accept(request : @CupcakeFriendshipRequest, time: UInt64);
        pub fun removeRequestedFriendship(otherCupcakeId : Int);
    }

    pub resource interface MyCupcake {
        pub fun createFriendshipRequest(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,otherCupcakeId : Int, time: UInt64) : @CupcakeFriendshipRequest;
        pub fun acceptBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time: UInt64);
        pub fun denyBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time: UInt64);
        pub fun storeRequestedFriendship(otherCupcakeId : Int);
        pub fun setAccessory(id : Int);
        pub fun hasFriendOrRequest(id : Int) : Bool;
        pub fun getId() : Int;
    }

    pub resource interface NotYetKnownCupcake {
        pub fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder);
        pub fun getId() : Int;
        pub fun getFriendRequests() : [CupcakeState];
        pub fun getFriends() : [CupcakeState];
        pub fun getRequestedFriendships() : [Int];
        pub fun getAccessory() : Int?;
    }

    pub resource CupcakeFriendshipRequestHolder {
        priv let request : @{Int:CupcakeFriendshipRequest};
        priv let acceptor : @{Int: CupcakeFriendshipAcceptor};

        init(request : @CupcakeFriendshipRequest, acceptor : @CupcakeFriendshipAcceptor) {
            self.request <- {0: <-request};
            self.acceptor <- {0: <-acceptor};
        }

        pub fun getRequest() : @CupcakeFriendshipRequest {
            return <- self.request.remove(key: 0)!;
        }

        pub fun getRequestRef() : &CupcakeFriendshipRequest {
            let requestRef = &self.request[0] as &CupcakeFriendshipRequest?;
            return requestRef!;
        }

        pub fun getAcceptor() : @CupcakeFriendshipAcceptor {
            return <- self.acceptor.remove(key: 0)!;
        }

        pub fun getId() : Int {
            let ref = &self.request[0] as &CupcakeFriendshipRequest?;
            return ref!.getRequestorId();
        }

        destroy () {
            destroy self.request;
            destroy self.acceptor;
        }
    }

    pub resource CupcakeMinter {

        priv let usedIds : [Int];

        init() {
            self.usedIds = [];
        }

        pub fun mint(id : Int) : @Cupcake {
            if(self.usedIds.contains(id)) {
                panic("ID has already been minted");
            }
            self.usedIds.append(id);
            return <- create Cupcake(id: id);
        }
    }

    pub resource CupcakeFriendShip {
        priv let requestorId : Int;
        priv let acceptorId : Int;
        priv let creationTime : UInt64;
        priv let requestorCupcake: Capability<&AnyResource{NotYetKnownCupcake}>;

        init(requestorId : Int, acceptorId : Int, creationTime : UInt64, requestorCupcake : Capability<&AnyResource{NotYetKnownCupcake}>) {
            self.requestorId = requestorId;
            self.acceptorId = acceptorId;
            self.requestorCupcake = requestorCupcake;
            self.creationTime = creationTime;
        }

        pub fun getRequestorId() : Int {
            return self.requestorId;
        }

        pub fun getAcceptorId() : Int {
            return self.acceptorId;
        }

        pub fun getCreationTime() : UInt64 {
            return self.creationTime;
        }

        pub fun getRequestorCupcake() : Capability<&AnyResource{NotYetKnownCupcake}> {
            return self.requestorCupcake;
        }
    }

    pub resource CupcakeFriendshipRequest {
        priv let requestorId : Int;
        priv let requestedAcceptorId : Int;
        priv let creationTime : UInt64;
        priv let requestorCupcake: Capability<&AnyResource{NotYetKnownCupcake}>;

        init(requestorId : Int, requestedAcceptorId : Int, creationTime : UInt64, requestorCupcake : Capability<&AnyResource{NotYetKnownCupcake}>) {
            self.requestorId = requestorId;
            self.requestedAcceptorId = requestedAcceptorId;
            self.requestorCupcake = requestorCupcake;
            self.creationTime = creationTime;
        }

        pub fun getRequestorId() : Int {
            return self.requestorId;
        }

        pub fun getRequestedAcceptorId() : Int {
            return self.requestedAcceptorId;
        }

        pub fun getRequestorCupcake() : Capability<&AnyResource{NotYetKnownCupcake}> {
            return self.requestorCupcake;
        }

        pub fun getCreationTime() : UInt64 {
            return self.creationTime;
        }
    }

    pub resource CupcakeFriendshipAcceptor {
        priv let requestorId : Int;
        priv let cupcake : Capability<&AnyResource{FriendlyCupcake}>;

        init(requestorId : Int, cupcake : Capability<&AnyResource{FriendlyCupcake}>) {
            self.requestorId = requestorId;
            self.cupcake = cupcake;
        }

        pub fun accept(request: @CupcakeFriendshipRequest, time : UInt64) {
            if(request.getRequestorId() != self.requestorId) {
                panic("I cannot accept friendship requests from you");
            }
            let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake")
            cupcake.accept(request: <- request, time: time)
            cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId);
        }

        pub fun deny(request: @CupcakeFriendshipRequest) {
            if(request.getRequestorId() != self.requestorId) {
                panic("I cannot deny friendship requests from you");
            }
            let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake");
            cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId);
            destroy request;
        }
    }

    pub resource CupcakeCollection : CupcakeReceiver, FriendlyCupcake, NotYetKnownCupcake, MyCupcake{
        priv let ownedCupcakes: @{UInt64: Cupcake};

        init() {
            self.ownedCupcakes <- {}
        }

        pub fun depositCupcake(cupcake : @Cupcake) {
            if(self.hasCupcake()) {
                panic("Cannot own more than one Cupcake");
            }
            self.ownedCupcakes[0] <-! cupcake;
        }

        pub fun getCupcake() : &Cupcake {
            if(!self.hasCupcake()) {
                panic("Do not have a Cupcake yet");
            }
            return (&self.ownedCupcakes[0] as &Cupcake?)!;
        }

        pub fun hasCupcake() : Bool {
            return self.ownedCupcakes.length != 0;
        }

        pub fun accept(request : @CupcakeFriendshipRequest, time: UInt64) {
            self.getCupcake().accept(request: <- request, time: time)
        }
        pub fun removeRequestedFriendship(otherCupcakeId : Int) {
            self.getCupcake().removeRequestedFriendship(otherCupcakeId: otherCupcakeId);
        }
        pub fun storeRequestedFriendship(otherCupcakeId : Int) {
            self.getCupcake().storeRequestedFriendship(otherCupcakeId: otherCupcakeId);
        }
        pub fun createFriendshipRequest(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,otherCupcakeId : Int, time: UInt64) : @CupcakeFriendshipRequest {
            return <- self.getCupcake().createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: otherCupcakeId, time: time);
        }
        pub fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder) {
            self.getCupcake().depositFriendshipRequest(request: <-request);
        }
        pub fun getId() : Int {
            return self.getCupcake().getId();
        }
        pub fun getFriendRequests() : [CupcakeState] {
            return self.getCupcake().getFriendRequests();
        }
        pub fun getFriends() : [CupcakeState] {
            return self.getCupcake().getFriends();
        }
        pub fun acceptBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time: UInt64) {
            self.getCupcake().acceptBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time);
        }
        pub fun denyBothSides(myCupcake : Capability<&AnyResource{NotYetKnownCupcake}>,friendCupcake : Int, time: UInt64) {
            self.getCupcake().denyBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time);
        }
        pub fun getRequestedFriendships() : [Int] {
            return self.getCupcake().getRequestedFriendships();
        }
        pub fun getAccessory() : Int? {
            return self.getCupcake().getAccessory();
        }
        pub fun setAccessory(id : Int) {
            self.getCupcake().setAccessory(id: id)
        }
        pub fun hasFriendOrRequest(id : Int) : Bool {
            return self.getCupcake().hasFriendOrRequest(id: id)
        }
        destroy() {
            destroy self.ownedCupcakes;
        }
    }

    pub resource interface CupcakeReceiver {
        pub fun depositCupcake(cupcake : @Cupcake);
    }

    pub fun createEmptyCollection() : @CupcakeCollection {
        return <- create CupcakeCollection();
    }

    pub fun requestFriendship(myCupcakeRef : Capability<&AnyResource{MyCupcake}>,notYetKnownMyCupcakeRef: Capability<&AnyResource{NotYetKnownCupcake}>,friendlyCupcakeRef : Capability<&AnyResource{FriendlyCupcake}>,otherCupcakeRef : Capability<&AnyResource{NotYetKnownCupcake}>, time: UInt64)  {
        let myCupcake = myCupcakeRef.borrow() ?? panic("Cannot borrow my Cupcake")
        let otherCupcake = otherCupcakeRef.borrow() ?? panic("Cannot borrow other Cupcake");
        if(myCupcake.hasFriendOrRequest(id: otherCupcake.getId())) {
            panic("I am already friends with this cupcake, it has requested to be friends with me, or i requested to be friends with it");
        }
        if(myCupcake.getId() == otherCupcake.getId()) {
            panic("I cannot be friends with myself");
        }
        let request <- myCupcake.createFriendshipRequest(myCupcake: notYetKnownMyCupcakeRef, otherCupcakeId: otherCupcake.getId(), time: time);
        let acceptor <- create CupcakeFriendshipAcceptor(requestorId: otherCupcake.getId(), cupcake: friendlyCupcakeRef);
        let holder <- create CupcakeFriendshipRequestHolder(request: <-request, acceptor: <-acceptor);
        myCupcake.storeRequestedFriendship(otherCupcakeId: otherCupcake.getId());
        otherCupcake.depositFriendshipRequest(request: <-holder)
    }

    pub fun setupCollection(account : AuthAccount) {
        account.save( <- self.createEmptyCollection(), to: self.CollectionStoragePath)
        account.link<&{CupcakeReceiver,NotYetKnownCupcake}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        account.link<&{FriendlyCupcake,MyCupcake}>(self.CollectionPrivatePath, target: self.CollectionStoragePath)
    }

    init() {
        self.CollectionStoragePath = /storage/barcampCupcakeCollectionV1
        self.CollectionPrivatePath = /private/barcampCupcakeCollectionV1
        self.CollectionPublicPath = /public/barcampCupcakeCollectionV1
        self.MinterStoragePath = /storage/barcampCupcakeMinterV1
        self.setupCollection(account: self.account);

        self.account.save(<-create CupcakeMinter(), to: self.MinterStoragePath)
    }
}
 