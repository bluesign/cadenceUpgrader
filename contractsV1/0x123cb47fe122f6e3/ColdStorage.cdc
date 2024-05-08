import Crypto

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MoxyToken from "./MoxyToken.cdc"

access(all)
contract ColdStorage{ 
	access(all)
	struct Key{ 
		access(all)
		let publicKey: String
		
		access(all)
		let weight: UFix64
		
		init(publicKey: String,								// signatureAlgorithm: SignatureAlgorithm, 
								// hashAlgorithm: HashAlgorithm, 
								weight: UFix64){ 
			self.publicKey = publicKey
			self.weight = weight
		}
	}
	
	access(all)
	struct interface ColdStorageRequest{ 
		access(all)
		var sigSet: [Crypto.KeyListSignature]
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var senderAddress: Address
		
		access(all)
		view fun signableBytes(): [UInt8]
	}
	
	access(all)
	struct WithdrawRequest: ColdStorageRequest{ 
		access(all)
		var sigSet: [Crypto.KeyListSignature]
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var senderAddress: Address
		
		access(all)
		var recipientAddress: Address
		
		access(all)
		var amount: UFix64
		
		init(senderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, sigSet: [Crypto.KeyListSignature]){ 
			self.senderAddress = senderAddress
			self.recipientAddress = recipientAddress
			self.amount = amount
			self.seqNo = seqNo
			self.sigSet = sigSet
		}
		
		access(all)
		view fun signableBytes(): [UInt8]{ 
			let senderAddress = self.senderAddress.toBytes()
			let recipientAddressBytes = self.recipientAddress.toBytes()
			let amountBytes = self.amount.toBigEndianBytes()
			let seqNoBytes = self.seqNo.toBigEndianBytes()
			return senderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
		}
	}
	
	access(all)
	struct KeyListChangeRequest: ColdStorageRequest{ 
		access(all)
		var sigSet: [Crypto.KeyListSignature]
		
		access(all)
		var seqNo: UInt64
		
		access(all)
		var senderAddress: Address
		
		access(all)
		var newKeys: [Key]
		
		init(newKeys: [Key], seqNo: UInt64, senderAddress: Address, sigSet: [Crypto.KeyListSignature]){ 
			self.newKeys = newKeys
			self.seqNo = seqNo
			self.senderAddress = senderAddress
			self.sigSet = sigSet
		}
		
		access(all)
		view fun signableBytes(): [UInt8]{ 
			let senderAddress = self.senderAddress.toBytes()
			let seqNoBytes = self.seqNo.toBigEndianBytes()
			return senderAddress.concat(seqNoBytes)
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
			var pendingVault: @{FungibleToken.Vault} <-
				MoxyToken.createEmptyVault(vaultType: Type<@MoxyToken.Vault>())
			self.pendingVault <-> pendingVault
			let recipient = getAccount(self.request.recipientAddress)
			let receiver =
				recipient.capabilities.get<&{FungibleToken.Receiver}>(fungibleTokenReceiverPath)
					.borrow<&{FungibleToken.Receiver}>()
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
		fun getKeys(): [Key]
		
		access(all)
		fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal
		
		access(all)
		fun updateSignatures(request: KeyListChangeRequest)
	}
	
	access(all)
	resource Vault: FungibleToken.Receiver, PublicVault{ 
		access(self)
		var address: Address
		
		access(self)
		var keys: [Key]
		
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
		fun getKeys(): [Key]{ 
			return self.keys
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
		
		access(all)
		fun updateSignatures(request: KeyListChangeRequest){ 
			pre{ 
				self.seqNo == request.seqNo
				self.address == request.senderAddress
				self.isValidSignature(request: request)
			}
			post{ 
				self.seqNo == request.seqNo + UInt64(1)
			}
			self.incrementSequenceNumber()
			self.keys = request.newKeys
		}
		
		access(self)
		fun incrementSequenceNumber(){ 
			self.seqNo = self.seqNo + UInt64(1)
		}
		
		access(self)
		view fun isValidSignature(request:{ ColdStorage.ColdStorageRequest}): Bool{ 
			pre{ 
				self.seqNo == request.seqNo:
					"Squence number does not match"
				self.address == request.senderAddress:
					"Address does not match"
			}
			let a = ColdStorage.validateSignature(keys: self.keys, signatureSet: request.sigSet, message: request.signableBytes())
			return a
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
		
		init(address: Address, keys: [Key], contents: @{FungibleToken.Vault}){ 
			self.keys = keys
			self.seqNo = UInt64(0)
			self.contents <- contents
			self.address = address
		}
	}
	
	access(all)
	fun createVault(address: Address, keys: [Key], contents: @{FungibleToken.Vault}): @Vault{ 
		return <-create Vault(address: address, keys: keys, contents: <-contents)
	}
	
	access(all)
	view fun validateSignature(
		keys: [
			Key
		],
		signatureSet: [
			Crypto.KeyListSignature
		],
		message: [
			UInt8
		]
	): Bool{ 
		let keyList = Crypto.KeyList()
		for key in keys{ 
			keyList.add(PublicKey(publicKey: key.publicKey.decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256), hashAlgorithm: HashAlgorithm.SHA3_256, weight: key.weight)
		}
		return keyList.verify(signatureSet: signatureSet, signedData: message)
	}
}
