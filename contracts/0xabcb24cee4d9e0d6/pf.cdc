
import test from "../0x4dd4b29c1ac89044/test.cdc"
pub contract pf{
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
