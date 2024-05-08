/**

# This contract is the interface description of PriceOracle.
  The oracle includes an medianizer, which obtains prices from multiple feeds and calculate the median as the final price.

# Structure 
  Feeder1(off-chain) --> PriceFeeder(resource) 3.4$											   PriceReader1(resource)
  Feeder2(off-chain) --> PriceFeeder(resource) 3.2$ --> PriceOracle(contract) cal median 3.4$ --> PriceReader2(resource)
  Feeder3(off-chain) --> PriceFeeder(resource) 3.6$											   PriceReader3(resource)

# Robustness
  1. Median value is the current aggregation strategy.
  2. _MinFeederNumber determines the minimum number of feeds required to provide a valid price. As long as there're more than 50% of the nodes are honest the median data is trustworthy.
  3. The feeder needs to set a price expiration time, after which the price will be invalid (0.0). Dev is responsible to detect and deal with this abnormal data in the contract logic.

#  More price-feeding institutions and partners are welcome to join and build a more decentralized oracle on flow.
#  To apply to join the Feeder whitelist, please follow: https://docs.increment.fi/protocols/decentralized-price-feed-oracle/apply-as-feeder
#  On-chain price data can be publicly & freely accessed through the PublicPriceOracle contract.

# Author Increment Labs

*/

access(all)
contract interface OracleInterface{ 
	/*
			************************************
					Reader interfaces
			************************************
		*/
	
	/// Oracle price reader, users need to save this resource in their local storage
	///
	/// Only readers in the addr whitelist have permission to read prices
	/// Please do not share your PriceReader capability with others and take the responsibility of community governance.
	access(all)
	resource interface PriceReader{ 
		/// Get the median price of all current feeds.
		///
		/// @Return Median price, returns 0.0 if the current price is invalid
		///
		access(all)
		fun getMedianPrice(): UFix64
		
		access(all)
		fun getPriceIdentifier(): String{ 
			return ""
		}
		
		/// Calculate the *raw* median of the price feed with no filtering of expired data.
		///
		access(all)
		fun getRawMedianPrice(): UFix64{ 
			return 0.0
		}
		
		/// Calculate the published block height of the *raw* median data. If it's an even list, it is the smaller one of the two middle value.
		///
		access(all)
		fun getRawMedianBlockHeight(): UInt64{ 
			return 0
		}
	}
	
	/// Reader related public interfaces opened on PriceOracle smart contract
	///
	access(all)
	resource interface OraclePublicInterface_Reader{ 
		/// Users who need to read the oracle price should mint this resource and save locally.
		///
		access(all)
		fun mintPriceReader(): @{OracleInterface.PriceReader}
		
		/// Recommended path for PriceReader, users can manage resources by themselves
		///
		access(all)
		fun getPriceReaderStoragePath(): StoragePath
	}
	
	/*
			************************************
					Feeder interfaces
			************************************
		*/
	
	/// Panel for publishing price. Every feeder needs to mint this resource locally.
	///
	access(all)
	resource interface PriceFeeder: PriceFeederPublic{ 
		/// The feeder uses this function to offer price at the price panel
		///
		/// Param price - price from off-chain
		///
		access(all)
		fun publishPrice(price: UFix64)
		
		/// Set valid duration of price. If there is no update within the duration, the price will be expired.
		///
		/// Param blockheightDuration by the block numbers
		///
		access(all)
		fun setExpiredDuration(blockheightDuration: UInt64)
	}
	
	access(all)
	resource interface PriceFeederPublic{ 
		/// Get the current feed price, this function can only be called by the PriceOracle contract
		///
		access(all)
		fun fetchPrice(certificate: &{OracleInterface.OracleCertificate}): UFix64
		
		/// Get the current feed price regardless of whether it's expired or not.
		///
		access(all)
		fun getRawPrice(certificate: &{OracleInterface.OracleCertificate}): UFix64{ 
			return 0.0
		}
		
		access(all)
		fun getLatestPublishBlockHeight(): UInt64{ 
			return 0
		}
		
		access(all)
		fun getExpiredHeightDuration(): UInt64{ 
			return 0
		}
	}
	
	/// Feeder related public interfaces opened on PriceOracle smart contract
	///
	access(all)
	resource interface OraclePublicInterface_Feeder{ 
		/// Feeders need to mint their own price panels and expose the exact public path to oracle contract
		///
		/// @Return Resource of price panel
		///
		access(all)
		fun mintPriceFeeder(): @{OracleInterface.PriceFeeder}
		
		/// The oracle contract will get the PriceFeeder resource based on this path
		///
		/// Feeders need to expose the capabilities at this public path
		///
		access(all)
		fun getPriceFeederPublicPath(): PublicPath
		
		access(all)
		fun getPriceFeederStoragePath(): StoragePath
	}
	
	/// IdentityCertificate resource which is used to identify account address or perform caller authentication
	///
	access(all)
	resource interface IdentityCertificate{} 
	
	/// Each oracle contract will hold its own certificate to identify itself.
	///
	/// Only the oracle contract can mint the certificate.
	///
	access(all)
	resource interface OracleCertificate: IdentityCertificate{} 
	
	/*
			************************************
					Governace interfaces
			************************************
		*/
	
	/// Community administrator, Increment Labs will then collect community feedback and initiate voting for governance.
	///
	access(all)
	resource interface Admin{ 
		access(all)
		fun configOracle(
			priceIdentifier: String,
			minFeederNumber: Int,
			feederStoragePath: StoragePath,
			feederPublicPath: PublicPath,
			readerStoragePath: StoragePath
		)
		
		access(all)
		fun addFeederWhiteList(feederAddr: Address)
		
		access(all)
		fun addReaderWhiteList(readerAddr: Address)
		
		access(all)
		fun delFeederWhiteList(feederAddr: Address)
		
		access(all)
		fun delReaderWhiteList(readerAddr: Address)
		
		access(all)
		fun getFeederWhiteListPrice(): [UFix64]
	}
}
