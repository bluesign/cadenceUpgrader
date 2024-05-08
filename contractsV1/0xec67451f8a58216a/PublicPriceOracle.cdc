/**

# This contract provides public oracle data sourced from the multi-node PriceOracle contracts of Increment.

# Anyone can access price data directly with getLatestPrice() & getLatestBlockHeight(), no whitelist needed. Check example here: https://docs.increment.fi/protocols/decentralized-price-feed-oracle/using-price-feeds

# Admin controls what PriceOracles are exposed publicly.

# Author: Increment Labs

*/

import OracleInterface from "../0xcec15c814971c1dc/OracleInterface.cdc"

import OracleConfig from "../0xcec15c814971c1dc/OracleConfig.cdc"

access(all)
contract PublicPriceOracle{ 
	/// {OracleAddr: PriceIdentifier}
	access(self)
	let oracleAddrToPriceIdentifier:{ Address: String}
	
	/// The storage path for the Admin resource
	access(all)
	let OracleAdminStoragePath: StoragePath
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	/// Events
	access(all)
	event OracleAdded(oracleAddr: Address)
	
	access(all)
	event OracleRemoved(oracleAddr: Address)
	
	/// Get the price data from the most recent update.
	/// The data is updated whichever condition happens first: 
	///   1. The price deviation is beyond a threahold (by default 0.5%)
	///   2. A fixed window of time has passed (by default 2000 blocks)
	/// Note: It is recommended to check the updated block height of this data with getLatestBlockHeight(), and handle the extreme condition if this data is too old.
	///
	access(all)
	fun getLatestPrice(oracleAddr: Address): UFix64{ 
		let oraclePublicInterface_ReaderRef =
			getAccount(oracleAddr).capabilities.get<
				&{OracleInterface.OraclePublicInterface_Reader}
			>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
			?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
		let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
		let priceReaderRef =
			PublicPriceOracle.account.storage.borrow<&OracleInterface.PriceReader>(
				from: priceReaderSuggestedPath
			)
			?? panic("Lost local price reader resource.")
		let medianPrice = priceReaderRef.getRawMedianPrice()
		return medianPrice
	}
	
	/// Get the block height at the time of the latest update.
	///
	access(all)
	fun getLatestBlockHeight(oracleAddr: Address): UInt64{ 
		let oraclePublicInterface_ReaderRef =
			getAccount(oracleAddr).capabilities.get<
				&{OracleInterface.OraclePublicInterface_Reader}
			>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
			?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
		let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
		let priceReaderRef =
			PublicPriceOracle.account.storage.borrow<&OracleInterface.PriceReader>(
				from: priceReaderSuggestedPath
			)
			?? panic("Lost local price reader resource.")
		let medianBlockHeight: UInt64 = priceReaderRef.getRawMedianBlockHeight()
		return medianBlockHeight
	}
	
	access(all)
	fun getAllSupportedOracles():{ Address: String}{ 
		return self.oracleAddrToPriceIdentifier
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun addOracle(oracleAddr: Address){ 
			if !PublicPriceOracle.oracleAddrToPriceIdentifier.containsKey(oracleAddr){ 
				/// Mint oracle reader
				let oraclePublicInterface_ReaderRef = getAccount(oracleAddr).capabilities.get<&{OracleInterface.OraclePublicInterface_Reader}>(OracleConfig.OraclePublicInterface_ReaderPath).borrow() ?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
				let priceReaderSuggestedPath = oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
				if PublicPriceOracle.account.storage.borrow<&OracleInterface.PriceReader>(from: priceReaderSuggestedPath) == nil{ 
					let priceReader <- oraclePublicInterface_ReaderRef.mintPriceReader()
					destroy <-PublicPriceOracle.account.storage.load<@AnyResource>(from: priceReaderSuggestedPath)
					PublicPriceOracle.oracleAddrToPriceIdentifier[oracleAddr] = priceReader.getPriceIdentifier()
					PublicPriceOracle.account.storage.save(<-priceReader, to: priceReaderSuggestedPath)
				}
				emit OracleAdded(oracleAddr: oracleAddr)
			}
		}
		
		access(all)
		fun removeOracle(oracleAddr: Address){ 
			PublicPriceOracle.oracleAddrToPriceIdentifier.remove(key: oracleAddr)
			/// Remove local oracle reader resource
			let oraclePublicInterface_ReaderRef =
				getAccount(oracleAddr).capabilities.get<
					&{OracleInterface.OraclePublicInterface_Reader}
				>(OracleConfig.OraclePublicInterface_ReaderPath).borrow()
				?? panic("Lost oracle public capability at ".concat(oracleAddr.toString()))
			let priceReaderSuggestedPath =
				oraclePublicInterface_ReaderRef.getPriceReaderStoragePath()
			destroy <-PublicPriceOracle.account.storage.load<@AnyResource>(
				from: priceReaderSuggestedPath
			)
			emit OracleRemoved(oracleAddr: oracleAddr)
		}
	}
	
	init(){ 
		self.OracleAdminStoragePath = /storage/publicOracleAdmin
		self.oracleAddrToPriceIdentifier ={} 
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: self.OracleAdminStoragePath)
		self.account.storage.save(<-create Admin(), to: self.OracleAdminStoragePath)
	}
}
