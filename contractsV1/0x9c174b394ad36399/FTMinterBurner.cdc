/// Support FT minter/burner, minimal interfaces
/// do we want mintToAccount?
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract interface FTMinterBurner{ 
	access(all)
	resource interface IMinter{ 
		// only define func for PegBridge to call, allowedAmount isn't strictly required
		access(all)
		fun mintTokens(amount: UFix64): @{FungibleToken.Vault}
	}
	
	access(all)
	resource interface IBurner{ 
		access(all)
		fun burnTokens(from: @{FungibleToken.Vault})
	}
	
	/// token contract must also define same name resource and impl mintTokens/burnTokens
	access(all)
	resource interface Minter: IMinter{} 
	
	// we could add pre/post to mintTokens fun here
	access(all)
	resource interface Burner: IBurner{} 
// we could add pre/post to burnTokens fun here
}
