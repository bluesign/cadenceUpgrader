// SPDX-License-Identifier: MIT

pub contract GenesisBoxRegistry {

	//mapping of genesis box id to Data
	access(contract) let registryRemote:  {UInt64: Data}

	pub struct Data {

		//the receiver address on flow
		pub let receiver: Address

		//the doodleId of the asset beeing teleported
		pub let genesisBoxId:UInt64

		//the remote address on ETH
		pub let remoteAddress:String

		//context like ethTx or other info to add to event
		pub let context: {String:String}

		//the wearable template ids that will be minted and sent
		pub let wearableTemplateIds:[UInt64]


		init(receiver: Address,genesisBoxId:UInt64,remoteAddress:String, wearableTemplateIds:[UInt64],context: {String:String}, teleporterId:UInt64) {
			self.receiver=receiver
			self.genesisBoxId=genesisBoxId
			self.remoteAddress=remoteAddress
			self.context=context
			self.wearableTemplateIds=wearableTemplateIds
		}
	}

	pub struct AllowedStatus {
		pub let allowed: Bool
		pub let message: String

		init(_ id: UInt64) {
			var allowed = true
			var message = "Genesis Box ID : ".concat(id.toString()).concat(" can be opened.")

			if let data = GenesisBoxRegistry.registryRemote[id] {
				allowed = false
				message = "Genesis Box ID : ".concat(data.genesisBoxId.toString()).concat(" has already been opened by ").concat(data!.receiver.toString())
			}
			self.allowed = allowed
			self.message = message
		}
	}

	access(account) fun setData(_ data: Data) {
		pre{
			!self.registryRemote.containsKey(data.genesisBoxId) : "Genesis Box ID : ".concat(data.genesisBoxId.toString()).concat(" has already been opened.")
		}
		self.registryRemote[data.genesisBoxId] = data
	}

	pub fun getGenesisBoxStatus(_ id:UInt64) : Data? {
		return self.registryRemote[id]
	}

	pub fun isValid(_ id: UInt64) : Bool {
		return self.registryRemote.containsKey(id)
	}

	init() {
		self.registryRemote={}
	}
}
