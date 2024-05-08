import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import LampionsNFT from "./LampionsNFT.cdc"

import LampionsPack from "./LampionsPack.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Admin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	access(all)
	let AdminServerStoragePath: StoragePath
	
	access(all)
	let AdminServerPrivatePath: PrivatePath
	
	// This is just an empty resource to signal that you can control the admin, more logic can be added here or changed later if you want to
	access(all)
	resource Server{} 
	
	/// ===================================================================================
	// Admin things
	/// ===================================================================================
	//Admin client to use for capability receiver pattern
	access(all)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(all)
		fun addCapability(_ cap: Capability<&Server>)
	}
	
	//admin proxy with capability receiver 
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&Server>?
		
		access(all)
		fun addCapability(_ cap: Capability<&Server>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(all)
		fun registerGame(_ game: LampionsNFT.Game){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsNFT.addGame(game)
		}
		
		access(all)
		fun registerPlay(_ play: LampionsNFT.Play){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsNFT.addPlay(play)
		}
		
		access(all)
		fun registerLicense(_ license: LampionsNFT.License){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsNFT.addLicense(license)
		}
		
		access(all)
		fun registerPlayer(_ player: LampionsNFT.Player){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsNFT.addPlayer(player)
		}
		
		access(all)
		fun mintLampions(recipient: &{NonFungibleToken.Receiver}, play_id: UInt64, edition: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsNFT.mintNFT(recipient: recipient, play_id: play_id, edition: edition)
		}
		
		access(all)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}
		
		access(all)
		fun debug(_ value: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			Debug.enable(value)
		}
		
		access(all)
		fun registerPackMetadata(typeId: UInt64, metadata: LampionsPack.Metadata){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsPack.registerMetadata(typeId: typeId, metadata: metadata)
		}
		
		access(all)
		fun batchMintPacks(typeId: UInt64, hashes: [String]){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let recipient = Admin.account.capabilities.get<&{NonFungibleToken.Receiver}>(LampionsPack.CollectionPublicPath).borrow()!
			for hash in hashes{ 
				LampionsPack.mintNFT(recipient: recipient, typeId: typeId, hash: hash)
			}
		}
		
		access(all)
		fun requeue(packId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			let cap = Admin.account.storage.borrow<&LampionsPack.Collection>(from: LampionsPack.DLQCollectionStoragePath)!
			cap.requeue(packId: packId)
		}
		
		access(all)
		fun fulfill(packId: UInt64, rewardIds: [UInt64], salt: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			LampionsPack.fulfill(packId: packId, rewardIds: rewardIds, salt: salt)
		}
		
		//THis cap here could be the server really in this case
		access(all)
		fun getProviderCap(): Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>{ 
			pre{ 
				self.capability != nil:
					"Cannot create Admin, capability is not set"
			}
			return Admin.account.capabilities.get<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>(LampionsNFT.CollectionPrivatePath)!
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/onefootballAdminProxy
		self.AdminProxyStoragePath = /storage/onefootballAdminProxy
		
		//create a dummy server for now, if we have a resource later we want to use instead of server we can change to that
		self.AdminServerPrivatePath = /private/onefootballAdminServer
		self.AdminServerStoragePath = /storage/onefootballAdminServer
		self.account.storage.save(<-create Server(), to: self.AdminServerStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Server>(self.AdminServerStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminServerPrivatePath)
	}
}
