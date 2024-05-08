pub contract ObjectOrientedOntology {

    pub resource interface SensualObject {
        pub fun undermine(): &[Object]
        pub fun overmine(): [Capability<&Object{SensualObject}>]
    }

    pub resource Object: SensualObject {
        pub(set) var causes: @[Object]
        pub(set) var effects: [Capability<&Object{SensualObject}>]

        init() {
            self.causes <- []
            self.effects = []
        }

        pub fun undermine(): &[Object] {
            return (&self.causes as! &[Object])!
        }

        pub fun overmine(): [Capability<&Object{SensualObject}>] {
            return self.effects
        }

        destroy() {
            destroy self.causes
        }
    }

    pub fun createObject(): @Object {
        return <- create Object()
    }
}
