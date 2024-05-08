/**

# Common swap errors

# Author: Increment Labs

*/

access(all)
contract SwapError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case CANNOT_CREATE_PAIR_WITH_SAME_TOKENS
		
		access(all)
		case ADD_PAIR_DUPLICATED
		
		access(all)
		case NONEXISTING_SWAP_PAIR
		
		access(all)
		case LOST_PUBLIC_CAPABILITY // 5
		
		
		access(all)
		case SLIPPAGE_OFFSET_TOO_LARGE
		
		access(all)
		case EXCESSIVE_INPUT_AMOUNT
		
		access(all)
		case EXPIRED
		
		access(all)
		case INSUFFICIENT_OUTPUT_AMOUNT
		
		access(all)
		case MISMATCH_LPTOKEN_VAULT // 10
		
		
		access(all)
		case ADD_ZERO_LIQUIDITY
		
		access(all)
		case REENTRANT
		
		access(all)
		case FLASHLOAN_EXECUTOR_SETUP
		
		access(all)
		case FEE_TO_SETUP
		
		access(all)
		case BELOW_MINIMUM_INITIAL_LIQUIDITY // 15
	
	}
	
	access(all)
	fun ErrorEncode(msg: String, err: ErrorCode): String{ 
		return "[IncSwapErrorMsg:".concat(msg).concat("]").concat("[IncSwapErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
