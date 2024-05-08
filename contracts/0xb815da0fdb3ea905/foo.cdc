
import test from "../0x01e8f58ed57c5ea6/test.cdc"
pub contract foo{
    priv fun getA(): AuthAccount{
        return self.account
    }
    pub struct o: test.op{
        pub fun f(){
        }
    }
    init() {
    }
}
