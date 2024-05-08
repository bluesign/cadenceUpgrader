access(all) contract SwapStatsRegistry {

	access(self) var accountSwapStats: { String: [AccountStats] }

	access(self) var accountSwapStatsLookup: { String: { Address: Int } }

	access(self) var accountSwapPartners: { String: { Address: [Address] } }

	access(all) struct AccountSwapData {

		pub let partnerAddress: Address
		pub let totalTradeVolumeReceived: UInt
		pub let totalTradeVolumeSent: UInt

		init(
			partnerAddress: Address,
			totalTradeVolumeSent: UInt,
			totalTradeVolumeReceived: UInt
		) {
			self.partnerAddress = partnerAddress
			self.totalTradeVolumeReceived = totalTradeVolumeReceived
			self.totalTradeVolumeSent = totalTradeVolumeSent
		}
	}

	access(all) struct AccountStats {

		pub let address: Address
		pub var totalTradeVolumeReceived: Int
		pub var totalTradeVolumeSent: Int
		pub var totalUniqueTradeCount: Int
		pub var totalTradeCount: Int
		pub(set) var rank: Int?
		pub var metadata: { String: AnyStruct }?

		pub fun updateData(id: String, _ data: AccountSwapData) {

			self.totalTradeVolumeReceived = self.totalTradeVolumeReceived + Int(data.totalTradeVolumeReceived)
			self.totalTradeVolumeSent = self.totalTradeVolumeSent + Int(data.totalTradeVolumeSent)
			self.totalTradeCount = self.totalTradeCount + 1

			if (!SwapStatsRegistry.accountSwapPartners[id]![self.address]!.contains(data.partnerAddress)) {

				SwapStatsRegistry.accountSwapPartners[id]![self.address]!.append(data.partnerAddress)
				self.totalUniqueTradeCount = self.totalUniqueTradeCount + 1
			}
		}

		pub fun clearData() {
			self.totalTradeVolumeReceived = 0
			self.totalTradeVolumeSent = 0
			self.totalUniqueTradeCount = 0
			self.totalTradeCount = 0
			self.metadata = nil
			self.rank = nil
		}

		pub fun updateMetadata(_ metadata: { String: AnyStruct }?) {

			self.metadata = metadata
		}

		init(_ address: Address, _ metadata: { String: AnyStruct }?) {
			self.metadata = metadata
			self.address = address
			self.totalTradeVolumeReceived = 0
			self.totalTradeVolumeSent = 0
			self.totalUniqueTradeCount = 0
			self.totalTradeCount = 0
			self.rank = nil
		}
	}

	access(all) fun paginateAccountStats(id: String, skip: Int, take: Int, filter: { String: AnyStruct }?): [AccountStats] {

		if (!self.accountSwapStats.containsKey(id)) {

			return []
		}

		// let resolved = self.resolveAccountStats(id: id)

		let response: [AccountStats] = []

		let hasFilter = filter != nil

		var i = skip

		while i < take {

			// response.append(response[i])
			response.append(self.accountSwapStats[id]![i])

			i = i + 1
		}

		return response
	}

	access(all) fun getAccountStats(id: String, address: Address): AccountStats {

		/* var response = AccountStats(address, nil)

		let resolved = self.resolveAccountStats(id: id)

		for model in resolved {
			if (model.address == address) {
				response = model
				break
			}
		}

		return response */

		let index = self.getAccountStatsIndex(id: id, address: address)
		if (index == nil) {

			return AccountStats(address, nil)
		}

		return self.accountSwapStats[id]![index!]!
	}

	access(contract) fun sortStats(_ array: [AccountStats], _ compare: ((AccountStats, AccountStats): Int)): [AccountStats] {

		if array.length < 2 { 

			return array 
		}

		let pivotIndex = array.length / 2
		let pivot = array[pivotIndex]

		var less: [AccountStats] = []
		var greater: [AccountStats] = []

		var i = 0
		while i < array.length {
			if i != pivotIndex {
				if compare(array[i], pivot) < 0 {
					less.append(array[i])
				} else {
					greater.append(array[i])
				}
			}
			i = i + 1
		}

		return self.sortStats(less, compare).concat([pivot]).concat(self.sortStats(greater, compare))
	}

	access(self) fun resolveAccountStats(id: String): [AccountStats] {

		if (!self.accountSwapStats.containsKey(id)) {

			return []
		}

		let response = self.sortStats(self.accountSwapStats[id]!, fun(a: AccountStats, b: AccountStats): Int {

			let diff = b.totalUniqueTradeCount - a.totalUniqueTradeCount
			if (diff == 0) {

				return b.totalTradeCount - a.totalTradeCount
			}

			return diff
		})

		let length = response.length

		var i = 0
		while i < length {

			response[i].rank = i + 1

			i = i + 1
		}

		return response
	}

	access(all) fun getAccountStatsCount(id: String): Int {

		if (!self.accountSwapStatsLookup.containsKey(id)) {

			return 0
		}

		return self.accountSwapStatsLookup[id]!.length
	}

	access(contract) fun getAccountStatsIndex(id: String, address: Address): Int? {

		if (!self.accountSwapStats.containsKey(id) || !self.accountSwapStatsLookup.containsKey(id)) {

			return nil
		}

		return self.accountSwapStatsLookup[id]![address]
	}

	access(account) fun addAccountStats(id: String, address: Address, _ data: AccountSwapData) {

		assert(address != data.partnerAddress, message: "partner address not allowed")

		if (!self.accountSwapStats.containsKey(id)) {

			self.accountSwapStats.insert(key: id, [])
		}

		if (!self.accountSwapStatsLookup.containsKey(id)) {

			self.accountSwapStatsLookup.insert(key: id, {})
		}

		if (!self.accountSwapPartners.containsKey(id)) {

			self.accountSwapPartners.insert(key: id, {})
		}

		if (!self.accountSwapPartners[id]!.containsKey(address)) {

			self.accountSwapPartners[id]!.insert(key: address, [])
		}

		var index = self.getAccountStatsIndex(id: id, address: address)
		if (index == nil) {

			index = self.accountSwapStats[id]!.length

			self.accountSwapStatsLookup[id]!.insert(key: address, index!)

			self.accountSwapStats[id]!.append(AccountStats(address, nil))
		}

		assert(self.accountSwapStats[id]![index!]!.address == address, message: "stat lookup address mismatch")

		self.accountSwapStats[id]![index!]!.updateData(id: id, data)
	}

	access(account) fun clearAccountStats(id: String, address: Address) {

		let index = self.getAccountStatsIndex(id: id, address: address)
		if (index != nil) {

			assert(self.accountSwapStats[id]![index!]!.address == address, message: "stat lookup address mismatch")

			self.accountSwapStats[id]![index!]!.clearData()
		}

		if (self.accountSwapPartners.containsKey(id) && self.accountSwapPartners[id]!.containsKey(address)) {

			self.accountSwapPartners[id]!.insert(key: address, [])
		}
	}

	access(account) fun clearAllAccountStatsById(id: String, limit: Int?) {

        if (self.accountSwapStats.containsKey(id)) {

            var counter = 0
            while counter < limit ?? self.accountSwapStats[id]!.length {
                self.accountSwapStats[id]!.remove(at: 0)
                counter = counter + 1
            }
        }
	}

    access(account) fun clearAllAccountStatsLookupById(id: String, limit: Int?) {

        if (self.accountSwapStatsLookup.containsKey(id)) {

            let keys = self.accountSwapStatsLookup[id]!.keys.slice(from: 0, upTo: limit ?? self.accountSwapStatsLookup[id]!.length)
            for key in keys {
                self.accountSwapStatsLookup[id]!.remove(key: key)
            }
        }
    }

    access(account) fun clearAllAccountStatsPartnersById(id: String, limit: Int?) {

        if (self.accountSwapPartners.containsKey(id)) {

            let keys: [Address] = []
            var counter = 0
            self.accountSwapPartners[id]!.forEachKey(fun (key: Address): Bool {

                if counter >= limit ?? self.accountSwapPartners[id]!.length {
                    return false
                }

                keys.append(key)
                counter = counter + 1

                return true
            })

            for key in keys {
                self.accountSwapPartners[id]!.remove(key: key)
            }
        }
    }

	init () {

		self.accountSwapStats = {}
		self.accountSwapStatsLookup = {}
		self.accountSwapPartners = {}
	}
}
