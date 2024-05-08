access(all)
contract OverluError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case NEGATIVE_VALUE_NOT_ALLOWED
		
		access(all)
		case WHITE_LIST_EXIST
		
		access(all)
		case ALREADY_EXIST
		
		access(all)
		case LOST_PUBLIC_CAPABILITY
		
		access(all)
		case EXCEEDED_AMOUNT_LIMIT
		
		access(all)
		case INVALID_USER_CERTIFICATE
		
		access(all)
		case MISMATCH_RESOURCE_TYPE
		
		access(all)
		case ACCESS_DENY
		
		access(all)
		case INVALID_BALANCE_AMOUNT
		
		access(all)
		case SAME_BOOL_STATE
		
		access(all)
		case RESOURCE_ALREADY_EXIST
		
		access(all)
		case CONTRACT_PAUSE
		
		access(all)
		case EDITION_NUMBER_EXCEED
		
		access(all)
		case NOT_OPEN
		
		access(all)
		case NOT_ENOUGH_BALANCE
		
		access(all)
		case INSUFFICIENT_ENERGY
		
		access(all)
		case NOT_EXIST
		
		access(all)
		case CAN_NOT_BE_ZERO
	}
	
	access(all)
	fun errorEncode(msg: String, err: ErrorCode): String{ 
		return "[OverluErrorMsg:".concat(msg).concat("]").concat("[OverluErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
