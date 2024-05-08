import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Profile from "../0xd796ff17107bbff6/Profile.cdc"

import FIND from 0xd136d89c8958d52a

import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

access(all)
contract Admin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
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
		fun addCapability(_ cap: Capability<&FIND.Network>)
	}
	
	//admin proxy with capability receiver 
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&FIND.Network>?
		
		access(all)
		fun addCapability(_ cap: Capability<&FIND.Network>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		access(all)
		fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			((self.capability!).borrow()!).setWallet(wallet)
		}
		
		/// Enable or disable public registration 
		access(all)
		fun setPublicEnabled(_ enabled: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			((self.capability!).borrow()!).setPublicEnabled(enabled)
		}
		
		access(all)
		fun setAddonPrice(name: String, price: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			((self.capability!).borrow()!).setAddonPrice(name: name, price: price)
		}
		
		access(all)
		fun setPrice(_default: UFix64, additional:{ Int: UFix64}){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			((self.capability!).borrow()!).setPrice(default: _default, additionalPrices: additional)
		}
		
		access(all)
		fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection>){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
				FIND.validateFindName(name):
					"A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}
			((self.capability!).borrow()!).register(name: name, vault: <-vault, profile: profile, leases: leases)
		}
		
		access(all)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}
		
		access(all)
		fun debug(_ value: Bool){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}
		
		/*
				pub fun setArtifactTypeConverter(from: Type, converters: [Capability<&{TypedMetadata.TypeConverter}>]) {
					pre {
						self.capability != nil: "Cannot create FIND, capability is not set"
					}
		
					Artifact.setTypeConverter(from: from, converters: converters)
				}
		
				pub fun createForge(platform: Artifact.MinterPlatform) : @Artifact.Forge {
					pre {
						self.capability != nil: "Cannot create FIND, capability is not set"
					}
					return <- Artifact.createForge(platform:platform)
				}
		
				pub fun createVersusArtWithContent(name: String, artist:String, artistAddress:Address, description: String, url: String, type: String, royalty: {String: Art.Royalty}, edition: UInt64, maxEdition: UInt64) : @Art.NFT {
					return <- 	Art.createArtWithContent(name: name, artist: artist, artistAddress: artistAddress, description: description, url: url, type: type, royalty: royalty, edition: edition, maxEdition: maxEdition)
				}
		
				*/
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/findAdminProxy
		self.AdminProxyStoragePath = /storage/findAdminProxy
	}
}
