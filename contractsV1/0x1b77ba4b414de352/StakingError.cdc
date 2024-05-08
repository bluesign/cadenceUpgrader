/**

# Common staking errors

# Author: Increment Labs

*/

access(all)
contract StakingError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case WHITE_LIST_EXIST
		
		access(all)
		case EXCEEDED_AMOUNT_LIMIT
		
		access(all)
		case INSUFFICIENT_REWARD_BALANCE // 5
		
		
		access(all)
		case SAME_BOOL_STATE
		
		access(all)
		case POOL_LIFECYCLE_ERROR
		
		access(all)
		case INVALID_USER_CERTIFICATE
		
		access(all)
		case MISMATCH_VAULT_TYPE
		
		access(all)
		case ACCESS_DENY // 10
		
		
		access(all)
		case INSUFFICIENT_BALANCE
		
		access(all)
		case INVALID_BALANCE_AMOUNT
		
		access(all)
		case NOT_FOUND
		
		access(all)
		case NOT_ELIGIBLE
	}
	
	access(all)
	fun errorEncode(msg: String, err: ErrorCode): String{ 
		return "[IncStakingErrorMsg:".concat(msg).concat("]").concat("[IncStakingErrorCode:")
			.concat(err.rawValue.toString()).concat("]")
	}
}
