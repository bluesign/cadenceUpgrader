/**
> Author: FIXeS World <https://fixes.world/>

# FixesInscriptionFactory

This contract is a helper factory contract to create Fixes Inscriptions.

*/

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// Fixes Imports
import Fixes from "./Fixes.cdc"

access(all)
contract FixesInscriptionFactory{ 
	/* --- General Private Methods --- */
	
	/// Estimate inscribing cost
	///
	access(all)
	view fun estimateFrc20InsribeCost(_ dataStr: String): UFix64{ 
		// estimate the required storage
		return Fixes.estimateValue(
			index: Fixes.totalInscriptions,
			mimeType: "text/plain",
			data: dataStr.utf8,
			protocol: "frc20",
			encoding: nil
		)
	}
	
	/// This is the general factory method to create a fixes inscription
	///
	access(all)
	view fun createFrc20Inscription(
		_ dataStr: String,
		_ costReserve: @FlowToken.Vault
	): @Fixes.Inscription{ 
		return <-Fixes.createInscription(
			value: <-costReserve,
			mimeType: "text/plain",
			metadata: dataStr.utf8,
			metaProtocol: "frc20",
			encoding: nil,
			parentId: nil
		)
	}
	
	/// This is the general factory method to create and store a fixes inscription
	///
	access(all)
	fun createAndStoreFrc20Inscription(
		_ dataStr: String,
		_ costReserve: @FlowToken.Vault,
		_ store: &Fixes.InscriptionsStore
	): UInt64{ 
		pre{ 
			store.owner?.address != nil:
				"Inscriptions store must be stored in a valid account."
		}
		post{ 
			store.getLength() == before(store.getLength()) + 1:
				"Inscription was not stored."
		}
		// estimate the required storage
		let estimatedReqValue = self.estimateFrc20InsribeCost(dataStr)
		assert(
			costReserve.balance >= estimatedReqValue,
			message: "Insufficient balance to create the inscription."
		)
		let inscription <- self.createFrc20Inscription(dataStr, <-costReserve)
		let insId = inscription.getId()
		// store the inscription (now it will have an owner address)
		store.store(<-inscription)
		// return the new inscription id
		return insId
	}
	
	/* --- Public Methods --- */
	// Basic FRC20 Inscription
	access(all)
	view fun buildMintFRC20(tick: String, amt: UFix64): String{ 
		return "op=mint,tick=".concat(tick).concat(",amt=").concat(amt.toString())
	}
	
	access(all)
	view fun buildBurnFRC20(tick: String, amt: UFix64): String{ 
		return "op=burn,tick=".concat(tick).concat(",amt=").concat(amt.toString())
	}
	
	access(all)
	view fun buildDeployFRC20(tick: String, max: UFix64, limit: UFix64, burnable: Bool): String{ 
		return "op=deploy,tick=".concat(tick).concat(",max=").concat(max.toString()).concat(",lim=")
			.concat(limit.toString()).concat(",burnable=").concat(burnable ? "1" : "0")
	}
	
	access(all)
	view fun buildTransferFRC20(tick: String, to: Address, amt: UFix64): String{ 
		return "op=transfer,tick=".concat(tick).concat(",amt=").concat(amt.toString()).concat(
			",to="
		).concat(to.toString())
	}
	
	// Market FRC20 Inscription
	access(all)
	view fun buildMarketEnable(tick: String): String{ 
		return "op=enable-market,tick=".concat(tick)
	}
	
	access(all)
	view fun buildMarketListBuyNow(tick: String, amount: UFix64, price: UFix64): String{ 
		return "op=list-buynow,tick=".concat(tick).concat(",amt=").concat(amount.toString()).concat(
			",price="
		).concat(price.toString())
	}
	
	access(all)
	view fun buildMarketListSellNow(tick: String, amount: UFix64, price: UFix64): String{ 
		return "op=list-sellnow,tick=".concat(tick).concat(",amt=").concat(amount.toString())
			.concat(",price=").concat(price.toString())
	}
	
	access(all)
	view fun buildMarketTakeBuyNow(tick: String, amount: UFix64): String{ 
		return "op=list-take-buynow,tick=".concat(tick).concat(",amt=").concat(amount.toString())
	}
	
	access(all)
	view fun buildMarketTakeSellNow(tick: String, amount: UFix64): String{ 
		return "op=list-take-sellnow,tick=".concat(tick).concat(",amt=").concat(amount.toString())
	}
	
	// Staking FRC20 Inscription
	access(all)
	view fun buildStakeDonate(tick: String?, amount: UFix64?): String{ 
		var dataStr = "op=withdraw,usage=donate"
		if tick != nil && amount != nil{ 
			dataStr = dataStr.concat(",tick=").concat(tick!).concat(",amt=").concat((amount!).toString())
		}
		return dataStr
	}
	
	access(all)
	view fun buildStakeWithdraw(tick: String, amount: UFix64): String{ 
		return "op=withdraw,tick=".concat(tick).concat(",amt=").concat(amount.toString()).concat(
			",usage=staking"
		)
	}
	
	access(all)
	view fun buildStakeDeposit(tick: String): String{ 
		return "op=deposit,tick=".concat(tick)
	}
	
	// EVM Agency Inscription
	access(all)
	view fun buildEvmAgencyCreate(tick: String): String{ 
		return "op=create-evm-agency,tick=".concat(tick)
	}
	
	// FGame Lottery Inscription
	/// The cost of this lottery pool is $FIXES
	///
	access(all)
	view fun estimateLotteryFIXESTicketsCost(_ ticketAmount: UInt64, _ powerup: UFix64?): UFix64{ 
		pre{ 
			ticketAmount > 0:
				"Ticket amount must be greater than 0"
			powerup == nil || powerup! >= 1.0 && powerup! <= 10.0:
				"Powerup must be between 1.0 and 10.0"
		}
		let base = 2000.0
		return base * UFix64(ticketAmount) * (powerup ?? 1.0)
	}
	
	/// Build the inscription for lottery $FIXES tickets buying
	///
	access(all)
	view fun buildLotteryBuyFIXESTickets(_ ticketAmount: UInt64, _ powerup: UFix64?): String{ 
		let amount = self.estimateLotteryFIXESTicketsCost(ticketAmount, powerup)
		return "op=withdraw,tick=fixes".concat(",amt=").concat(amount.toString()).concat(
			",usage=lottery"
		)
	}
	
	// FRC20 Voting Commands
	/// Build the inscription for voting command to set the burnable status of a FRC20 token
	///
	access(all)
	view fun buildVoteCommandSetBurnable(tick: String, burnable: Bool): String{ 
		return "op=burnable,tick=".concat(tick).concat(",v=").concat(burnable ? "1" : "0")
	}
	
	/// Build the inscription for voting command to burn unsupplied tokens of a FRC20 token
	///
	access(all)
	view fun buildVoteCommandBurnUnsupplied(tick: String, percent: UFix64): String{ 
		return "op=burnUnsup,tick=".concat(tick).concat(",perc=").concat(percent.toString())
	}
	
	/// Build the inscription for voting command to move treasury to lottery jackpot
	///
	access(all)
	view fun buildVoteCommandMoveTreasuryToLotteryJackpot(tick: String, amount: UFix64): String{ 
		return "op=withdrawFromTreasury,usage=lottery,tick=".concat(tick).concat(",amt=").concat(
			amount.toString()
		)
	}
	
	/// Build the inscription for voting command to move treasury to staking
	///
	access(all)
	view fun buildVoteCommandMoveTreasuryToStaking(
		tick: String,
		amount: UFix64,
		vestingBatchAmount: UInt32,
		vestingInterval: UFix64
	): String{ 
		return "op=withdrawFromTreasury,usage=staking,tick=".concat(tick).concat(",amt=").concat(
			amount.toString()
		).concat(",batch=").concat(vestingBatchAmount.toString()).concat(",interval=").concat(
			vestingInterval.toString()
		)
	}
}
