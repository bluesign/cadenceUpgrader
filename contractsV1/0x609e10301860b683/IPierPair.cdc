import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import PierLPToken from 0x609e10301860b683

import PierMath from 0xa378eeb799df8387

/**

IPierPair is the interface that defines the parts of a pair
that should be exposed to public access.

@author Metapier Foundation Ltd.

 */

access(all)
contract interface IPierPair{ 
	
	// Event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	// Event that is emitted when swap is executed
	access(all)
	event Swap(poolId: UInt64, amountIn: UFix64, amountOut: UFix64, swapAForB: Bool)
	
	// Event that is emitted when mint is executed
	access(all)
	event Mint(poolId: UInt64, amountAIn: UFix64, amountBIn: UFix64)
	
	// Event that is emitted when burn is executed
	access(all)
	event Burn(poolId: UInt64, amountLP: UFix64, amountAOut: UFix64, amountBOut: UFix64)
	
	// IPool defines the exposed components of a liquidity pool
	access(all)
	resource interface IPool{ 
		
		// *** Basic Information ***
		
		// The identifier (owner's address) of the pool
		access(all)
		let poolId: UInt64
		
		// The K value computed by the last mint or burn
		access(all)
		var kLast: UInt256
		
		// Type of token A's vault (e.g., A.0x1654653399040a61.FlowToken.Vault)
		access(all)
		let tokenAType: Type
		
		// Type of token B's vault (e.g., A.0x3c5959b568896393.FUSD.Vault)
		access(all)
		let tokenBType: Type
		
		// returns [token A reserve, token B reserve]
		access(all)
		fun getReserves(): [UFix64; 2]
		
		// *** TWAP Information for Oracles ***
		// The timestamp of the most recent burn, mint, or swap
		access(all)
		var lastBlockTimestamp: UFix64
		
		// use Word64 instead of UFix64 because overflow is acceptable
		// as long as the delta can be computed correctly
		access(all)
		var lastPriceACumulative: Word64
		
		access(all)
		var lastPriceBCumulative: Word64
		
		// *** Trading & Liquidity ***
		// Takes in a vault of token A or token B, then returns a vault of the other token
		// with its balance equals to `forAmount`. It throws an error if the `xy = k` curve
		// cannot be maintained.
		//
		// @param fromVault The input vault of the swap (either token A or token B)
		// @param forAmount The expected output balance of the swap
		// @return A vault of the other token in the pool with its balance equals to `forAmount`
		access(all)
		fun swap(fromVault: @{FungibleToken.Vault}, forAmount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				forAmount > 0.0:
					"Metapier IPierPair: Zero swap output amount"
				fromVault.balance > 0.0:
					"Metapier IPierPair: Zero swap input amount"
				fromVault.isInstance(self.tokenAType) || fromVault.isInstance(self.tokenBType):
					"Metapier IPierPair: Invalid swap input type"
			}
			post{ 
				!result.isInstance(before(fromVault.getType())):
					"Metapier IPierPair: Unexpected swap output"
				result.isInstance(self.tokenAType) || result.isInstance(self.tokenBType):
					"Metapier IPierPair: Unexpected swap output"
				result.balance == forAmount:
					"Metapier IPierPair: Inaccurate swap output amount"
			}
		}
		
		// Mints new LP tokens by providing liquidity to the pool.
		//
		// @param vaultA Liquidity to provide for token A
		// @param vaultB Liquidity to provide for token B
		// @return New LP tokens as a share of the pool
		access(all)
		fun mint(
			vaultA: @{FungibleToken.Vault},
			vaultB: @{FungibleToken.Vault}
		): @PierLPToken.Vault{ 
			pre{ 
				vaultA.balance > 0.0 && vaultB.balance > 0.0:
					"Metapier IPierPair: Zero mint input amount"
				vaultA.isInstance(self.tokenAType):
					"Metapier IPierPair: Invalid token A for mint"
				vaultB.isInstance(self.tokenBType):
					"Metapier IPierPair: Invalid token B for mint"
			}
			post{ 
				result.tokenId == self.poolId:
					"Metapier IPierPair: Unexpected LP token minted"
			}
		}
		
		// Burns the given LP tokens to withdraw its share of the pool.
		//
		// @param lpTokenVault The LP tokens to burn
		// @return The withdrawn share of the pool as [token A vault, token B vault]
		access(all)
		fun burn(lpTokenVault: @PierLPToken.Vault): @[{FungibleToken.Vault}; 2]{ 
			pre{ 
				lpTokenVault.tokenId == self.poolId:
					"Metapier IPierPair: Invalid LP token to burn"
				lpTokenVault.balance > 0.0:
					"Metapier IPierPair: Zero balance to burn"
			}
			post{ 
				result[0].isInstance(self.tokenAType):
					"Metapier IPierPair: Unexpected burn output"
				result[1].isInstance(self.tokenBType):
					"Metapier IPierPair: Unexpected burn output"
			}
		}
	}
}
