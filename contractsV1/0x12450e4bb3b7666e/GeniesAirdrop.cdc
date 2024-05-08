import Genies from "./Genies.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract GeniesAirdrop{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event GeniesNFTAirdropVaultCreateted(geniesVaultID: UInt64)
	
	// when Airdrop is created
	access(all)
	event AirdropCreated(nftId: UInt64, owner: Address?, receiver: Address?)
	
	// when Airdrop is claimed or deleted
	access(all)
	event AirdropCompleted(nftId: UInt64, owner: Address?, receiver: Address?, claimed: Bool)
	
	access(all)
	event CapabilityAdded(address: Address)
	
	access(all)
	let GeniesAdminStoragePath: StoragePath
	
	access(all)
	let GeniesNFTAirdropVaultStoragePath: StoragePath
	
	access(all)
	let GeniesNFTAirdropVaultPrivatePath: PrivatePath
	
	access(all)
	let GeniesNFTAirdropVaultPublicPath: PublicPath
	
	access(all)
	resource Admin{ 
		access(self)
		var claimCapabilities:{ Address: Capability<&{GeniesNFTAirdropVaultClaim}>}
		
		init(){ 
			self.claimCapabilities ={} 
		}
		
		// This gives Admin the capability to claim the Airdrop on behalf of you.
		access(all)
		fun addClaimCapability(cap: Capability<&{GeniesNFTAirdropVaultClaim}>){ 
			self.claimCapabilities[cap.address] = cap
			emit CapabilityAdded(address: cap.address)
		}
		
		// get the GeniesNFTAirdropVaultClaim capability for the resource owner
		access(all)
		fun getClaimCapability(address: Address): Capability<&{GeniesNFTAirdropVaultClaim}>?{ 
			pre{ 
				self.claimCapabilities[address] != nil:
					"No capability for this address."
			}
			return self.claimCapabilities[address]
		}
		
		access(all)
		fun createEmptyGeniesNFTAirdropVault(): @GeniesAirdrop.GeniesNFTAirdropVault{ 
			return <-create GeniesNFTAirdropVault()
		}
	}
	
	access(all)
	resource interface GeniesNFTAirdropVaultPublic{ 
		access(all)
		fun getIDs(): [UInt64]
	}
	
	access(all)
	resource interface GeniesNFTAirdropVaultClaim{ 
		access(all)
		fun claim(nftId: UInt64, address: Address)
	}
	
	access(all)
	resource GeniesNFTAirdropVault: GeniesNFTAirdropVaultPublic, GeniesNFTAirdropVaultClaim{ 
		access(all)
		var ownerships:{ UInt64: Address}
		
		access(all)
		var giftNFTs:{ UInt64: Capability<&Genies.Collection>}
		
		init(){ 
			self.giftNFTs ={} 
			self.ownerships ={} 
		}
		
		// nft owner can create airdrop and store the nft in their vault with optional receiverAddress.
		// If the receiverAddress is provided, only that address will be able to claim this nft. Otherwise, anyone can claim.
		access(all)
		fun createAirdrop(nftProviderCap: Capability<&Genies.Collection>, nftId: UInt64, receiverAddress: Address?){ 
			// Make sure the dictionary doesn't contain this nft id, so we don't accidentally destroy resource.
			// This should not happen in theory given nft id is unique.
			pre{ 
				!self.giftNFTs.containsKey(nftId):
					"Duplicate NFT Id"
				nftProviderCap.address == (self.owner!).address:
					"Capability owner should be the same as the Vault resource owner"
			}
			self.giftNFTs[nftId] = nftProviderCap
			// setting the ownership of the nft if address is provided. Otherwise, this nft is ownershipless.
			if receiverAddress != nil{ 
				self.ownerships[nftId] = receiverAddress
			}
			emit AirdropCreated(nftId: nftId, owner: self.owner?.address, receiver: receiverAddress)
		}
		
		// claim an airdrop. nftId has to be valid.
		access(all)
		fun claim(nftId: UInt64, address: Address){ 
			pre{ 
				self.giftNFTs.containsKey(nftId):
					"Invalid nftId to claim"
				
				// if the nft being claimed has assigned ownership, check the claimer's address first.
				!self.ownerships.containsKey(nftId) || self.ownerships[nftId] == address:
					"Invalid owner to claim"
			}
			let receiverAccount = getAccount(address)
			let claimerCollection = receiverAccount.capabilities.get<&Genies.Collection>(Genies.CollectionPublicPath).borrow<&Genies.Collection>()!
			let nftProviderCap = self.giftNFTs.remove(key: nftId) ?? panic("missing NFT id")
			let token <- (nftProviderCap.borrow()!).withdraw(withdrawID: nftId)
			
			// Remove the nft id from the ownership table if the table contains. 
			if self.ownerships.containsKey(nftId){ 
				self.ownerships.remove(key: nftId)
			}
			claimerCollection.deposit(token: <-token)
			emit AirdropCompleted(nftId: nftId, owner: self.owner?.address, receiver: address, claimed: true)
		}
		
		// delisting the Airdrop back to the owner, nftId must be valid.
		access(all)
		fun delistingAirdrop(nftId: UInt64){ 
			pre{ 
				self.giftNFTs.containsKey(nftId):
					"Invalid nftId to remove"
			}
			self.giftNFTs.remove(key: nftId) ?? panic("missing NFT id")
			if self.ownerships.containsKey(nftId){ 
				self.ownerships.remove(key: nftId)
			}
			emit AirdropCompleted(nftId: nftId, owner: self.owner?.address, receiver: self.owner?.address, claimed: false)
		}
		
		// remove all Airdrops and store them back to the Genies.Collection resource.
		access(all)
		fun delistingAllAirdrops(claimerCollection: &Genies.Collection){ 
			let keys = self.getIDs()
			for key in keys{ 
				self.delistingAirdrop(nftId: key)
			}
		}
		
		access(all)
		fun getIDs(): [UInt64]{ 
			return self.giftNFTs.keys
		}
	}
	
	init(){ 
		// set the named paths
		self.GeniesNFTAirdropVaultStoragePath = /storage/GeniesNFTAirdropVaultStoragePath
		self.GeniesNFTAirdropVaultPrivatePath = /private/GeniesNFTAirdropVaultPrivatePath
		self.GeniesNFTAirdropVaultPublicPath = /public/GeniesNFTAirdropVaultPublicPath
		self.GeniesAdminStoragePath = /storage/GeniesAdminStoragePath
		
		// create Admin resource. 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.GeniesAdminStoragePath)
		emit ContractInitialized()
		
		// create GeniesNFTAirdropVault resource 
		let vault <- create GeniesNFTAirdropVault()
		self.account.storage.save(<-vault, to: self.GeniesNFTAirdropVaultStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&GeniesAirdrop.GeniesNFTAirdropVault>(
				GeniesAirdrop.GeniesNFTAirdropVaultStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: GeniesAirdrop.GeniesNFTAirdropVaultPublicPath
		)
		var capability_2 =
			self.account.capabilities.storage.issue<&GeniesAirdrop.GeniesNFTAirdropVault>(
				GeniesAirdrop.GeniesNFTAirdropVaultStoragePath
			)
		self.account.capabilities.publish(
			capability_2,
			at: GeniesAirdrop.GeniesNFTAirdropVaultPrivatePath
		)
	}
}
