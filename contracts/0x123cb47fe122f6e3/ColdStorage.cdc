import Crypto

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MoxyToken from "./MoxyToken.cdc"

pub contract ColdStorage {

  pub struct Key {
    pub let publicKey: String
    pub let weight: UFix64

    init(
      publicKey: String, 
      // signatureAlgorithm: SignatureAlgorithm, 
      // hashAlgorithm: HashAlgorithm, 
      weight: UFix64,
    ) {
      self.publicKey = publicKey
      self.weight = weight
    }
  }

  pub struct interface ColdStorageRequest {
    pub var sigSet: [Crypto.KeyListSignature]
    pub var seqNo: UInt64
    pub var senderAddress: Address

    pub fun signableBytes(): [UInt8]
  }

  pub struct WithdrawRequest: ColdStorageRequest {
    pub var sigSet: [Crypto.KeyListSignature]
    pub var seqNo: UInt64

    pub var senderAddress: Address
    pub var recipientAddress: Address
    pub var amount: UFix64

    init(
      senderAddress: Address,
      recipientAddress: Address,  
      amount: UFix64, 
      seqNo: UInt64, 
      sigSet: [Crypto.KeyListSignature],
    ) {
      self.senderAddress = senderAddress
      self.recipientAddress = recipientAddress
      self.amount = amount

      self.seqNo = seqNo
      self.sigSet = sigSet
    }

    pub fun signableBytes(): [UInt8] {
      let senderAddress = self.senderAddress.toBytes()
      let recipientAddressBytes = self.recipientAddress.toBytes()
      let amountBytes = self.amount.toBigEndianBytes()
      let seqNoBytes = self.seqNo.toBigEndianBytes()

      return senderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
    }
  }

  pub struct KeyListChangeRequest: ColdStorageRequest {
    pub var sigSet: [Crypto.KeyListSignature]
    pub var seqNo: UInt64
    pub var senderAddress: Address

    pub var newKeys: [Key]

    init(
      newKeys: [Key],
      seqNo: UInt64,
      senderAddress: Address,
      sigSet: [Crypto.KeyListSignature],
    ) {
      self.newKeys = newKeys
      self.seqNo = seqNo
      self.senderAddress = senderAddress
      self.sigSet = sigSet
    }

    pub fun signableBytes(): [UInt8] {
      let senderAddress = self.senderAddress.toBytes()
      let seqNoBytes = self.seqNo.toBigEndianBytes()

      return senderAddress.concat(seqNoBytes)
    }
  }

  pub resource PendingWithdrawal {

    access(self) var pendingVault: @FungibleToken.Vault
    access(self) var request: WithdrawRequest

    init(pendingVault: @FungibleToken.Vault, request: WithdrawRequest) {
      self.pendingVault <- pendingVault
      self.request = request
    }

    pub fun execute(fungibleTokenReceiverPath: PublicPath) {
      var pendingVault: @FungibleToken.Vault <- MoxyToken.createEmptyVault()
      self.pendingVault <-> pendingVault

      let recipient = getAccount(self.request.recipientAddress)
      let receiver = recipient
        .getCapability(fungibleTokenReceiverPath)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference for recipient")

      receiver.deposit(from: <- pendingVault)
    }

    destroy (){
      pre {
        self.pendingVault.balance == 0.0 as UFix64
      }
      destroy self.pendingVault
    }
  }

  pub resource interface PublicVault {
    pub fun getSequenceNumber(): UInt64

    pub fun getBalance(): UFix64

    pub fun getKeys(): [Key]

    pub fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal

    pub fun updateSignatures(request: KeyListChangeRequest)
  }

  pub resource Vault : FungibleToken.Receiver, PublicVault {    
    access(self) var address: Address
    access(self) var keys: [Key]
    access(self) var contents: @FungibleToken.Vault
    access(self) var seqNo: UInt64

    pub fun deposit(from: @FungibleToken.Vault) {
      self.contents.deposit(from: <-from)
    }

    pub fun getSequenceNumber(): UInt64 {
        return self.seqNo
    }

    pub fun getBalance(): UFix64 {
      return self.contents.balance
    }

    pub fun getKeys(): [Key] {
      return self.keys
    }

    pub fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal {
      pre {
        self.isValidSignature(request: request)
      } 
      post {
        self.seqNo == request.seqNo + UInt64(1)
      }

      self.incrementSequenceNumber()

      return <- create PendingWithdrawal(pendingVault: <- self.contents.withdraw(amount: request.amount), request: request)
    }

    pub fun updateSignatures(request: KeyListChangeRequest) {
      pre {
        self.seqNo == request.seqNo 
        self.address == request.senderAddress
        self.isValidSignature(request: request)
      }
      post {
        self.seqNo == request.seqNo + UInt64(1)
      }

      self.incrementSequenceNumber()

      self.keys = request.newKeys
    } 

    access(self) fun incrementSequenceNumber(){
      self.seqNo = self.seqNo + UInt64(1)
    }

    access(self) fun isValidSignature(request: {ColdStorage.ColdStorageRequest}): Bool {
      pre {
        self.seqNo == request.seqNo : "Squence number does not match"
        self.address == request.senderAddress : "Address does not match"
      }

      let a = ColdStorage.validateSignature(
        keys: self.keys,
        signatureSet: request.sigSet,
        message: request.signableBytes()
      )

      return a
    }

    init(address: Address, keys: [Key], contents: @FungibleToken.Vault) {
      self.keys = keys
      self.seqNo = UInt64(0)
      self.contents <- contents
      self.address = address
    }

    destroy() {
      destroy self.contents
    }
  }

  pub fun createVault(
    address: Address, 
    keys: [Key], 
    contents: @FungibleToken.Vault,
  ): @Vault {
    return <- create Vault(address: address, keys: keys, contents: <- contents)
  }

  pub fun validateSignature(
    keys: [Key],
    signatureSet: [Crypto.KeyListSignature],
    message: [UInt8],
  ): Bool {

    let keyList = Crypto.KeyList()

    for key in keys {
      keyList.add(
        PublicKey(
          publicKey: key.publicKey.decodeHex(),
          signatureAlgorithm: SignatureAlgorithm.ECDSA_P256,
        ),
        hashAlgorithm: HashAlgorithm.SHA3_256,
        weight: key.weight,
      )
    }

    return keyList.verify(
      signatureSet: signatureSet,
      signedData: message
    )
  }
}
 
