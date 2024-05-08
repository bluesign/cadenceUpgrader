import Crypto

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract ColdStorage{ 
	access(all)
	struct Key{ 
		access(all)
		let publicKey: [UInt8]
		
		access(all)
		let signatureAlgorithm: UInt8
		
		access(all)
		let hashAlgorithm: UInt8
		
		init(
			publicKey: [
				UInt8
			],
			signatureAlgorithm: SignatureAlgorithm,
			hashAlgorithm: HashAlgorithm
		){ 
			self.publicKey = publicKey
			self.signatureAlgorithm = signatureAlgorithm.rawValue
			self.hashAlgorithm = hashAlgorithm.rawValue
		}
	}
	
	access(all)
	struct interface ColdStorageRequest{ 
		access(all)
		var signature: Crypto.KeyListSignature
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var spenderAddress: Address
		
		access(all)
		view fun signableBytes(): [UInt8]
	}
	
	access(all)
	struct WithdrawRequest: ColdStorageRequest{ 
		access(all)
		var signature: Crypto.KeyListSignature
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var spenderAddress: Address
		
		access(all)
		var recipientAddress: Address
		
		access(all)
		var amount: UFix64
		
		init(spenderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signature: Crypto.KeyListSignature){ 
			self.spenderAddress = spenderAddress
			self.recipientAddress = recipientAddress
			self.amount = amount
			self.seqNo = seqNo
			self.signature = signature
		}
		
		access(all)
		view fun signableBytes(): [UInt8]{ 
			let spenderAddress = self.spenderAddress.toBytes()
			let recipientAddressBytes = self.recipientAddress.toBytes()
			let amountBytes = self.amount.toBigEndianBytes()
			let seqNoBytes = self.seqNo.toBigEndianBytes()
			return spenderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
		}
	}
	
	access(all)
	resource PendingWithdrawal{ 
		access(self)
		var pendingVault: @{FungibleToken.Vault}
		
		access(self)
		var request: WithdrawRequest
		
		init(pendingVault: @{FungibleToken.Vault}, request: WithdrawRequest){ 
			self.pendingVault <- pendingVault
			self.request = request
		}
		
		access(all)
		fun _execute(fungibleTokenReceiverPath: PublicPath){ 
			var pendingVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			self.pendingVault <-> pendingVault
			let recipient = getAccount(self.request.recipientAddress)
			let receiver =
				(recipient.capabilities.get<&{FungibleToken.Receiver}>(fungibleTokenReceiverPath)!)
					.borrow()
				?? panic("Unable to borrow receiver reference for recipient")
			receiver.deposit(from: <-pendingVault)
		}
	}
	
	access(all)
	resource interface PublicVault{ 
		access(all)
		fun getSequenceNumber(): UInt64
		
		access(all)
		fun getBalance(): UFix64
		
		access(all)
		fun getKey(): Key
		
		access(all)
		fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal
	}
	
	access(all)
	resource Vault: FungibleToken.Receiver, PublicVault{ 
		access(self)
		var address: Address
		
		access(self)
		var key: Key
		
		access(self)
		var contents: @{FungibleToken.Vault}
		
		access(self)
		var seqNo: UInt64
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			self.contents.deposit(from: <-from)
		}
		
		access(all)
		fun getSequenceNumber(): UInt64{ 
			return self.seqNo
		}
		
		access(all)
		fun getBalance(): UFix64{ 
			return self.contents.balance
		}
		
		access(all)
		fun getKey(): Key{ 
			return self.key
		}
		
		access(all)
		fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal{ 
			pre{ 
				self.isValidSignature(request: request)
			}
			post{ 
				self.seqNo == request.seqNo + UInt64(1)
			}
			self.incrementSequenceNumber()
			return <-create PendingWithdrawal(pendingVault: <-self.contents.withdraw(amount: request.amount), request: request)
		}
		
		access(self)
		fun incrementSequenceNumber(){ 
			self.seqNo = self.seqNo + UInt64(1)
		}
		
		access(self)
		view fun isValidSignature(request:{ ColdStorage.ColdStorageRequest}): Bool{ 
			pre{ 
				self.seqNo == request.seqNo
				self.address == request.spenderAddress
			}
			return ColdStorage.validateSignature(key: self.key, signature: request.signature, message: request.signableBytes())
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
		
		init(address: Address, key: Key, contents: @{FungibleToken.Vault}){ 
			self.key = key
			self.seqNo = UInt64(0)
			self.contents <- contents
			self.address = address
		}
	}
	
	access(all)
	fun createVault(address: Address, key: Key, contents: @{FungibleToken.Vault}): @Vault{ 
		return <-create Vault(address: address, key: key, contents: <-contents)
	}
	
	access(all)
	view fun validateSignature(
		key: Key,
		signature: Crypto.KeyListSignature,
		message: [
			UInt8
		]
	): Bool{ 
		let keyList = Crypto.KeyList()
		let signatureAlgorithm =
			SignatureAlgorithm(rawValue: key.signatureAlgorithm)
			?? panic("invalid signature algorithm")
		let hashAlgorithm =
			HashAlgorithm(rawValue: key.hashAlgorithm) ?? panic("invalid hash algorithm")
		keyList.add(
			PublicKey(publicKey: key.publicKey, signatureAlgorithm: signatureAlgorithm),
			hashAlgorithm: hashAlgorithm,
			weight: 1000.0
		)
		return keyList.verify(signatureSet: [signature], signedData: message)
	}
}
