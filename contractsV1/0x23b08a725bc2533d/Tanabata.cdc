import DateUtil from "./DateUtil.cdc"

//  ┌─────────────────────────────────────────────┐
// ─┤ Every year during July 7, wishes come true. │
//  └─────────────────────────────────────────────┘
access(all)
contract Tanabata{ 
	access(all)
	event Success(wish: String)
	
	access(all)
	fun fulfill(wish: String){ 
		let now = getCurrentBlock().timestamp
		if DateUtil.isJuly7(now){ 
			emit Success(wish: wish)
		}
	}
}
