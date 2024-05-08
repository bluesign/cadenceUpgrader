pub contract ActualInfinity {

    pub resource Creativity {
        pub var creativity: @Creativity
        init() { self.creativity <- create Creativity() }
        destroy() { destroy self.creativity }
    }

    pub fun create(): @Creativity {
        return <- create Creativity()
    }
}
