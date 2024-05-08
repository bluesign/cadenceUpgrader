pub contract MediaArts {

    pub var latestID: UInt32

    pub resource MediaArt {
        pub let id: UInt32
        
        init() {
            self.id = MediaArts.latestID
            MediaArts.latestID = MediaArts.latestID + 1
        }
        
        pub fun isMediaArt(): Bool {
            return self.id == MediaArts.latestID
        }
    }

    pub fun create(): @MediaArt {
        return <- create MediaArt()
    }

    init() {
        self.latestID = 0
    }
}
