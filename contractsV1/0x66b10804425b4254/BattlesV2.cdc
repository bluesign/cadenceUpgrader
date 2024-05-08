import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import REVV from "../0xd01e482eb680ec9f/REVV.cdc"

/// BattlesV2
///
/// A REVV-bound contract for FEHV Battle Mode
///
access(all)
contract BattlesV2{ 
	
	/// TournamentCreated
	/// A tournament struct has been created for a racing event.
	///
	access(all)
	event TournamentCreated(tournamentId: String, amount: UFix64)
	
	/// LobbyEnded
	/// A lobby has ended with refunds or rewards.
	///
	access(all)
	event LobbyEnded(tournamentId: String, lobbyId: String, isSuccessful: Bool)
	
	/// UnpaidPlayer
	/// An entitled player has not been paid.
	///
	access(all)
	event UnpaidPlayer(tournamentId: String, player: Address, amount: UFix64)
	
	/// TransferCompleted
	/// A player paid the participation fee for a tournament.
	///
	access(all)
	event TransferCompleted(tournamentId: String, from: Address, amount: UFix64, paymentId: String)
	
	/// Player
	/// A struct representing a player's payment with its current state.
	///
	access(all)
	struct Player{ 
		access(all)
		let paymentId: String
		
		access(all)
		var isFinished: Bool
		
		access(all)
		var prizeAmount: UFix64?
		
		access(all)
		var lobbyId: String?
		
		init(paymentId: String){ 
			self.paymentId = paymentId
			self.isFinished = false
			self.prizeAmount = nil
			self.lobbyId = nil
		}
		
		access(contract)
		fun finish(lobbyId: String, prizeAmount: UFix64){ 
			pre{ 
				!self.isFinished
				self.prizeAmount == nil
				self.lobbyId == nil
			}
			self.isFinished = true
			self.prizeAmount = prizeAmount
			self.lobbyId = lobbyId
		}
	}
	
	/// Tournament
	/// A struct representing a Race Event containing multiple virtual lobbies.
	///
	access(all)
	struct Tournament{ 
		access(contract)
		let amount: UFix64
		
		access(contract)
		let players:{ Address: Player}
		
		access(contract)
		var finishedPlayers: Int
		
		init(amount: UFix64){ 
			self.amount = amount
			self.players ={} 
			self.finishedPlayers = 0
		}
		
		access(contract)
		fun addPlayer(from: Address, paymentId: String){ 
			self.players.insert(key: from, Player(paymentId: paymentId))
		}
		
		access(contract)
		fun incrementFinishedPlayers(){ 
			self.finishedPlayers = self.finishedPlayers + 1
		}
	}
	
	/// TournamentView
	/// A struct representing the external readable state of a Race Event.
	///
	access(all)
	struct TournamentView{ 
		access(all)
		let amount: UFix64
		
		access(all)
		let totalPlayers: Int
		
		access(all)
		let finishedPlayers: Int
		
		access(all)
		let rewardDistribution: [UFix64]
		
		access(all)
		let publicKey: String
		
		init(
			amount: UFix64,
			totalPlayers: Int,
			finishedPlayers: Int,
			rewardDistribution: [
				UFix64
			],
			publicKey: String
		){ 
			self.amount = amount
			self.totalPlayers = totalPlayers
			self.finishedPlayers = finishedPlayers
			self.rewardDistribution = rewardDistribution
			self.publicKey = publicKey
		}
	}
	
	/// AdminStoragePath
	/// The storage location for the Admin resource.
	access(all)
	let AdminStoragePath: StoragePath
	
	/// publicKey
	/// The public key for decrypting game signatures.
	access(all)
	var publicKey: String
	
	/// tournaments
	/// The dictionary storage that stores all the Tournaments.
	access(self)
	let tournaments:{ String: Tournament}
	
	/// rewards
	/// The percentages for each reward category.
	access(self)
	var rewards: [UFix64]
	
	/// revvVault
	/// The REVV contract vault used to safeguard payments.
	access(self)
	let revvVault: @REVV.Vault
	
	/// feeReceiver
	/// The REVV fee account capability.
	access(self)
	var feeReceiver: Capability<&REVV.Vault>?
	
	/// isValidSignature
	/// Internal function used to check if a message matches its signature.
	///
	access(self)
	fun isValidSignature(message: String, signature: String): Bool{ 
		let key =
			PublicKey(
				publicKey: self.publicKey.decodeHex(),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			)
		return key.verify(
			signature: signature.decodeHex(),
			signedData: message.utf8,
			domainSeparationTag: "",
			hashAlgorithm: HashAlgorithm.SHA3_256
		)
	}
	
	/// getRevvReceiver
	/// Internal function to get the REVV receiver of an account address.
	///
	access(self)
	fun getRevvReceiver(addr: Address): &{FungibleToken.Receiver}?{ 
		let recipient = getAccount(addr)
		let receiverCap = recipient.capabilities.get_<YOUR_TYPE>(REVV.RevvReceiverPublicPath)
		return receiverCap.borrow<&{FungibleToken.Receiver}>()
	}
	
	/// finishPlayer
	/// Internal function to set the player's payment as processed.
	///
	access(self)
	fun finishPlayer(tournamentId: String, player: Address, lobbyId: String, amount: UFix64){ 
		pre{ 
			self.tournaments.containsKey(tournamentId):
				"invalid tournament id"
			(self.tournaments[tournamentId]!).players.containsKey(player):
				"player not in tournament"
			!((self.tournaments[tournamentId]!).players[player]!).isFinished:
				"player already processed"
		}
		((self.tournaments[tournamentId]!).players[player]!).finish(
			lobbyId: lobbyId,
			prizeAmount: amount
		)
		(self.tournaments[tournamentId]!).incrementFinishedPlayers()
	}
	
	/// getPlayerPayment
	/// Retrieves the payment state of a player.
	///
	access(all)
	fun getPlayerPayment(tournamentId: String, from: Address): Player?{ 
		if !self.tournaments.containsKey(tournamentId){ 
			return nil
		}
		return (self.tournaments[tournamentId]!).players[from]
	}
	
	/// getTournamentView
	/// Retrieves the battle details of a race slot.
	///
	access(all)
	fun getTournamentView(tournamentId: String): TournamentView?{ 
		if !self.tournaments.containsKey(tournamentId){ 
			return nil
		}
		let tournament = self.tournaments[tournamentId]!
		return TournamentView(
			amount: tournament.amount,
			totalPlayers: tournament.players.length,
			finishedPlayers: tournament.finishedPlayers,
			rewardDistribution: self.rewards,
			publicKey: self.publicKey
		)
	}
	
	/// joinTournament
	/// Allows anyone with a valid signature to join a Race Event.
	///
	access(all)
	fun joinTournament(
		tournamentId: String,
		amount: UFix64,
		from: Address,
		paymentId: String,
		sigValidUntil: UFix64,
		signature: String,
		payment: @REVV.Vault
	){ 
		pre{ 
			self.feeReceiver != nil:
				"fee receiver not set"
			self.publicKey.length > 0:
				"public key not set"
			self.rewards.length > 0:
				"rewards array not set"
			amount == payment.balance:
				"invalid amount"
			getCurrentBlock().timestamp < sigValidUntil:
				"expired signature"
		}
		let message =
			tournamentId.concat(amount.toString()).concat(from.toString()).concat(paymentId).concat(
				sigValidUntil.toString()
			)
		let isValid = self.isValidSignature(message: message, signature: signature)
		assert(isValid, message: "invalid signature")
		if !self.tournaments.containsKey(tournamentId){ 
			self.tournaments.insert(key: tournamentId, Tournament(amount: amount))
			emit TournamentCreated(tournamentId: tournamentId, amount: amount)
		} else{ 
			assert(amount == (self.tournaments[tournamentId]!).amount, message: "unequal amount")
			assert(!(self.tournaments[tournamentId]!).players.containsKey(from), message: "entry fee already paid")
		}
		self.revvVault.deposit(from: <-payment)
		(self.tournaments[tournamentId]!).addPlayer(from: from, paymentId: paymentId)
		emit TransferCompleted(
			tournamentId: tournamentId,
			from: from,
			amount: amount,
			paymentId: paymentId
		)
	}
	
	/// refundLobby
	/// Allows anyone with a valid signature to refund a lobby.
	///
	access(all)
	fun refundLobby(tournamentId: String, lobbyId: String, players: [Address], signature: String){ 
		pre{ 
			self.publicKey.length > 0:
				"public key not set"
			self.tournaments.containsKey(tournamentId):
				"invalid tournament id"
			players.length > 0:
				"empty player list"
		}
		var message = "refund-lobby".concat(tournamentId).concat(lobbyId)
		for address in players{ 
			message = message.concat(address.toString())
		}
		let isValid = self.isValidSignature(message: message, signature: signature)
		assert(isValid, message: "invalid signature")
		let amount = (self.tournaments[tournamentId]!).amount
		for address in players{ 
			self.finishPlayer(tournamentId: tournamentId, player: address, lobbyId: lobbyId, amount: amount)
			let receiverRef = self.getRevvReceiver(addr: address)
			if receiverRef == nil{ 
				emit UnpaidPlayer(tournamentId: tournamentId, player: address, amount: amount)
				continue
			}
			let revv <- self.revvVault.withdraw(amount: amount)
			(receiverRef!).deposit(from: <-revv)
		}
		emit LobbyEnded(tournamentId: tournamentId, lobbyId: lobbyId, isSuccessful: false)
	}
	
	/// rewardLobby
	/// Allows anyone with a valid result to reward a lobby.
	///
	access(all)
	fun rewardLobby(tournamentId: String, lobbyId: String, players: [Address], signature: String){ 
		pre{ 
			self.feeReceiver != nil:
				"fee receiver not set"
			self.publicKey.length > 0:
				"public key not set"
			self.rewards.length > 0:
				"rewards array not set"
			self.tournaments.containsKey(tournamentId):
				"invalid tournament id"
			players.length >= self.rewards.length:
				"invalid lobby size"
		}
		var message = "reward-lobby".concat(tournamentId).concat(lobbyId)
		for address in players{ 
			message = message.concat(address.toString())
		}
		let isValid = self.isValidSignature(message: message, signature: signature)
		assert(isValid, message: "invalid signature")
		let totalLobbyPrize = (self.tournaments[tournamentId]!).amount * UFix64(players.length)
		var prizeLeft = totalLobbyPrize
		var count = 0
		while count < self.rewards.length{ 
			let amount = totalLobbyPrize * self.rewards[count]
			self.finishPlayer(tournamentId: tournamentId, player: players[count], lobbyId: lobbyId, amount: amount)
			let receiverRef = self.getRevvReceiver(addr: players[count])
			if receiverRef == nil{ 
				emit UnpaidPlayer(tournamentId: tournamentId, player: players[count], amount: amount)
				count = count + 1
				continue
			}
			let revv <- self.revvVault.withdraw(amount: amount)
			(receiverRef!).deposit(from: <-revv)
			prizeLeft = prizeLeft - amount
			count = count + 1
		}
		if prizeLeft > 0.0{ 
			let receiver = (self.feeReceiver!).borrow() ?? panic("cannot borrow fee receiver")
			let revv <- self.revvVault.withdraw(amount: prizeLeft)
			receiver.deposit(from: <-revv)
		}
		while count < players.length{ 
			self.finishPlayer(tournamentId: tournamentId, player: players[count], lobbyId: lobbyId, amount: 0.0)
			count = count + 1
		}
		emit LobbyEnded(tournamentId: tournamentId, lobbyId: lobbyId, isSuccessful: true)
	}
	
	/// Admin
	/// A token resource that allows its holder to change the settings.
	access(all)
	resource Admin{} 
	
	/// setFeeReceiver
	/// Allows the admin token holder to set the fee receiver.
	///
	access(all)
	fun setFeeReceiver(admin: &Admin, feeReceiver: Capability<&REVV.Vault>){ 
		pre{ 
			admin != nil:
				"invalid admin token"
			feeReceiver.borrow() != nil:
				"invalid receiver"
		}
		self.feeReceiver = feeReceiver
	}
	
	/// setPublicKey
	/// Allows the admin token holder to set the public key.
	///
	access(all)
	fun setPublicKey(admin: &Admin, publicKey: String){ 
		pre{ 
			admin != nil:
				"invalid admin token"
		}
		self.publicKey = publicKey
	}
	
	/// setRewards
	/// Allows the admin token holder to set the reward percentages.
	///
	access(all)
	fun setRewards(admin: &Admin, rewards: [UFix64]){ 
		pre{ 
			admin != nil:
				"invalid admin token"
		}
		var totalCuts = 0.0
		for r in rewards{ 
			totalCuts = totalCuts + r
		}
		assert(totalCuts <= 1.0, message: "unexpected reward distribution")
		self.rewards = rewards
	}
	
	init(){ 
		self.AdminStoragePath = /storage/AdminFEHVBattlesV2
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.feeReceiver = nil
		self.tournaments ={} 
		self.rewards = []
		self.publicKey = ""
		self.revvVault <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>()) as! @REVV.Vault
	}
}
