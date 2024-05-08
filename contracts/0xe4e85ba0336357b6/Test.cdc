import TestImport from "../0xea57707519a77b05/TestImport.cdc"

access(all) contract Test {

    access(all) var x: TestImport.TestStruct

    init() {
        self.x = TestImport.TestStruct()
    }
}