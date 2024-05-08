import DateUtil from "./DateUtil.cdc"

//  ┌─────────────────────────────────────────────┐
// ─┤ Every year during July 7, wishes come true. │
//  └─────────────────────────────────────────────┘

pub contract Tanabata {

    pub event Success(wish: String)

    pub fun fulfill(wish: String) {
        let now = getCurrentBlock().timestamp
        if (DateUtil.isJuly7(now)) {
            emit Success(wish: wish)
        }
    }
}
