pub contract NeverEndingStory {

    pub resource Story {
        destroy() {
            panic("The Nothing")
        }
    }

    init() {
        self.account.save(<- create Story(), to: /storage/NeverEndingStory)
    }
}
