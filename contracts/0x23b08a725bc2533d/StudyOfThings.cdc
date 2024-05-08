// This code poetry is dedicated to Minakata Kumagusu.

pub contract StudyOfThings {
    pub resource Object {}

    pub resource Mind {}

    pub event Thing(object: UInt64, mind: UInt64)


    pub fun get(): @Object {
        return <- create Object()
    }

    pub fun call(): @Mind {
        return <- create Mind()
    }

    pub fun produce(object: &Object, mind: &Mind) {
        emit Thing(object: object.uuid, mind: mind.uuid)
    }
}
