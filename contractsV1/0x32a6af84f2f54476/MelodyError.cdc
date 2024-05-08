access(all)
contract MelodyError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case PAUSED
		
		access(all)
		case NOT_EXIST
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case NEGATIVE_VALUE_NOT_ALLOWED
		
		access(all)
		case ALREADY_EXIST
		
		access(all)
		case CAN_NOT_BE_ZERO
		
		access(all)
		case SAME_BOOL_STATE
		
		access(all)
		case WRONG_LIFE_CYCLE_STATE
		
		access(all)
		case ACCESS_DENIED
		
		access(all)
		case PAYMENT_NOT_REVOKABLE
		
		access(all)
		case NOT_TRANSFERABLE
		
		access(all)
		case TYPE_MISMATCH
	}
	
	access(all)
	fun errorEncode(msg: String, err: ErrorCode): String{ 
		return "[MelodyErrorMsg:".concat(msg).concat("]").concat("[MelodyErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
