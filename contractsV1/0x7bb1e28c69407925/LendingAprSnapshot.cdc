import LendingConfig from "../0x2df970b6cdee5735/LendingConfig.cdc"

import LendingError from "../0x2df970b6cdee5735/LendingError.cdc"

import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

access(all)
contract LendingAprSnapshot{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	/// { marketAddr => perMarketAprData}
	access(self)
	let _markets:{ Address: AprSnapshot}
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	access(all)
	event MarketDataTracked(market: Address, marketType: String, startTrackingFrom: UFix64)
	
	access(all)
	event MarketDataErased(market: Address, erasedFrom: UFix64)
	
	access(all)
	event AprSampled(
		market: Address,
		truncatedTimestamp: UInt64,
		supplyApr: UFix64,
		borrowApr: UFix64
	)
	
	/// Per-snapshot data point
	access(all)
	struct Observation{ 
		// Unix timestamp
		access(all)
		let timestamp: UFix64
		
		// supplyApr in ufix64
		access(all)
		let supplyApr: UFix64
		
		// borrowApr in ufix64 (e.g. 0.12345678 => 12.35%)
		access(all)
		let borrowApr: UFix64
		
		init(t: UFix64, supplyApr: UFix64, borrowApr: UFix64){ 
			self.timestamp = t
			self.supplyApr = supplyApr
			self.borrowApr = borrowApr
		}
	}
	
	/// Per-market snapshot configurations and data points
	access(all)
	struct AprSnapshot{ 
		/// Contains functions to query public market data
		access(all)
		let poolPublicCap: Capability<&{LendingInterfaces.PoolPublic}>
		
		/// Each sample covers a 6-hour window: i.e. sampleLength = 21600s
		access(all)
		let sampleLength: UInt64
		
		/// We store 1 year of apr data in maximum: i.e. numSamples = 1460
		access(all)
		let numSamples: UInt64
		
		/// A circular buffer storing apr samples
		access(self)
		let aprObservations: [Observation]
		
		/// Reserved parameter fields: {ParamName: Value}
		access(self)
		let _reservedFields:{ String: AnyStruct}
		
		/// Returns the index into the circular buffer of the given timestamp
		access(all)
		fun observationIndexOf(timestamp: UFix64): UInt64{ 
			return UInt64(timestamp) / self.sampleLength % self.numSamples
		}
		
		access(all)
		fun sample(): Bool{ 
			let now = getCurrentBlock().timestamp
			let idx = self.observationIndexOf(timestamp: now)
			let ob = self.aprObservations[idx]
			let timeElapsed = now - ob.timestamp
			if UInt64(timeElapsed) > self.sampleLength{ 
				let poolRef = self.poolPublicCap.borrow() ?? panic("cannot borrow reference to lendingPool")
				let newSupplyApr: UFix64 = LendingConfig.ScaledUInt256ToUFix64(poolRef.getPoolSupplyAprScaled())
				let newBorrowApr: UFix64 = LendingConfig.ScaledUInt256ToUFix64(poolRef.getPoolBorrowAprScaled())
				// Truncate timestamp for better plotting in frontend
				let samplePeriodStart: UInt64 = UInt64(now) / self.sampleLength * self.sampleLength
				self.aprObservations[idx] = Observation(t: UFix64(samplePeriodStart), supplyApr: newSupplyApr, borrowApr: newBorrowApr)
				emit AprSampled(market: poolRef.getPoolAddress(), truncatedTimestamp: samplePeriodStart, supplyApr: newSupplyApr, borrowApr: newBorrowApr)
				return true
			}
			return false
		}
		
		access(all)
		fun queryHistoricalAprData(scale: UInt8, plotPoints: UInt64): [Observation]{ 
			let now = getCurrentBlock().timestamp
			let idxNow: UInt64 = self.observationIndexOf(timestamp: now)
			var idxPrev: UInt64 = 0
			switch scale{ 
				case 0:
					// idx for timestamp 1 month ago
					idxPrev = self.observationIndexOf(
							timestamp: now - 30.0 * UFix64(self.sampleLength) * 4.0
						)
				case 1:
					// idx for timestamp 6 month ago
					idxPrev = self.observationIndexOf(
							timestamp: now - 180.0 * UFix64(self.sampleLength) * 4.0
						)
				case 2:
					// idx for timestamp 1 year ago. (Use 360 instead of 365 for the purpose of exact-division)
					idxPrev = self.observationIndexOf(
							timestamp: now - 360.0 * UFix64(self.sampleLength) * 4.0
						)
				default:
					panic("invalid spanning param")
			}
			let numSampledPoints =
				idxPrev < idxNow ? idxNow - idxPrev + 1 : self.numSamples + idxNow - idxPrev + 1
			assert(
				plotPoints <= numSampledPoints,
				message: "invalid plotPoints param: cannot plot due to insufficient samples"
			)
			let step: UInt64 = numSampledPoints / plotPoints
			var res: [Observation] = []
			var i: UInt64 = 0
			while i < plotPoints{ 
				let ob = self.aprObservations[idxPrev]
				// Filtering non-meaningful data
				if ob.timestamp > 0.0{ 
					res.append(Observation(t: ob.timestamp, supplyApr: ob.supplyApr, borrowApr: ob.borrowApr))
				}
				idxPrev = idxPrev + step
				if idxPrev >= self.numSamples{ 
					idxPrev = idxPrev - self.numSamples
				}
				i = i + 1
			}
			return res
		}
		
		access(all)
		fun getLatestData(): Observation{ 
			let now = getCurrentBlock().timestamp
			let idx = self.observationIndexOf(timestamp: now)
			return self.aprObservations[idx]
		}
		
		/// Proposed params: sampleLength = 21600 (6h) && numSamples = 1460 (store 1 year's data)
		init(poolPublicCap: Capability<&{LendingInterfaces.PoolPublic}>){ 
			self.poolPublicCap = poolPublicCap
			// 6h
			self.sampleLength = 30
			// stores 1 year's data
			self.numSamples = 1460
			self.aprObservations = []
			var i: UInt64 = 0
			// Init circular buffer
			while i < self.numSamples{ 
				self.aprObservations.append(Observation(t: 0.0, supplyApr: 0.0, borrowApr: 0.0))
				i = i + 1
			}
			self._reservedFields ={} 
		}
	}
	
	/// sample() is made public so everyone can sample the given market's apr data, as long as it's expired.
	/// @Returns sampled or not
	access(all)
	fun sample(poolAddr: Address): Bool{ 
		pre{ 
			self._markets.containsKey(poolAddr) == true:
				LendingError.ErrorEncode(msg: "Market not tracked yet", err: LendingError.ErrorCode.MARKET_NOT_OPEN)
		}
		return (self._markets[poolAddr]!).sample()
	}
	
	/////////////// TODO: Check if it's ok to pull 120 x (3 UFix64) in 1 script?
	/// A getter function for frontend to query stored samples and plot data.
	/// @scale: Spanning of time the drawing should cover - 0 (1 month), 1 (6 months), 2 (1 year). 
	/// @plotPoints: Maximum data points the drawing needs, e.g. 120 points in maximum
	/// @Returns historical apy data in a timestamp-ascending order. Note: only meaningful data is returned, so the length is not guaranteed to be equal to `plotPoints`.
	access(all)
	fun queryHistoricalAprData(poolAddr: Address, scale: UInt8, plotPoints: UInt64): [Observation]{ 
		pre{ 
			self._markets.containsKey(poolAddr) == true:
				LendingError.ErrorEncode(msg: "Market not tracked yet", err: LendingError.ErrorCode.MARKET_NOT_OPEN)
		}
		return (self._markets[poolAddr]!).queryHistoricalAprData(
			scale: scale,
			plotPoints: plotPoints
		)
	}
	
	access(all)
	fun getLatestData(poolAddr: Address): Observation{ 
		return (self._markets[poolAddr]!).getLatestData()
	}
	
	access(contract)
	fun trackMarketData(poolAddr: Address){ 
		pre{ 
			self._markets.containsKey(poolAddr) == false:
				LendingError.ErrorEncode(msg: "Market has already been tracked", err: LendingError.ErrorCode.ADD_MARKET_DUPLICATED)
		}
		// Start tracking a new market
		let poolPublicCap =
			getAccount(poolAddr).capabilities.get<&{LendingInterfaces.PoolPublic}>(
				LendingConfig.PoolPublicPublicPath
			)
		assert(
			poolPublicCap.check() == true,
			message: LendingError.ErrorEncode(
				msg: "Cannot borrow reference to PoolPublic resource",
				err: LendingError.ErrorCode.CANNOT_ACCESS_POOL_PUBLIC_CAPABILITY
			)
		)
		self._markets[poolAddr] = AprSnapshot(poolPublicCap: poolPublicCap!)
		emit MarketDataTracked(
			market: poolAddr,
			marketType: (poolPublicCap.borrow()!).getUnderlyingTypeString(),
			startTrackingFrom: getCurrentBlock().timestamp
		)
	}
	
	access(contract)
	fun eraseMarketData(poolAddr: Address){ 
		pre{ 
			self._markets.containsKey(poolAddr) == true:
				LendingError.ErrorEncode(msg: "Market not tracked yet", err: LendingError.ErrorCode.MARKET_NOT_OPEN)
		}
		self._markets.remove(key: poolAddr)
		emit MarketDataErased(market: poolAddr, erasedFrom: getCurrentBlock().timestamp)
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun trackMarketData(poolAddr: Address){ 
			LendingAprSnapshot.trackMarketData(poolAddr: poolAddr)
		}
		
		access(all)
		fun eraseMarketData(poolAddr: Address){ 
			LendingAprSnapshot.eraseMarketData(poolAddr: poolAddr)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/lendingAprSnapshotAdmin
		self._markets ={} 
		self._reservedFields ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: self.AdminStoragePath)
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
