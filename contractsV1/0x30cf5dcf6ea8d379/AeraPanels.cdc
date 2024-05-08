import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import AeraPack from "./AeraPack.cdc"

import AeraRewards from "./AeraRewards.cdc"

import AeraNFT from "./AeraNFT.cdc"

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

import FindFurnace from "../0x097bafa4e0b48eef/FindFurnace.cdc"

access(all)
contract AeraPanels: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, address: Address, panel_id: UInt64, edition: UInt64)
	
	// we cannot have address here as it will always be nil
	access(all)
	event Burned(id: UInt64, panel_id: UInt64, edition: UInt64)
	
	access(all)
	event PanelMetadataRegistered(chapter_id: UInt64, slot_id: UInt64, panel_id: UInt64, detail:{ String: String})
	
	access(all)
	event PanelStaked(id: UInt64, chapter_id: UInt64, slot_id: UInt64, panel_id: UInt64, owner: Address?)
	
	access(all)
	event PanelUnstaked(id: UInt64, chapter_id: UInt64, slot_id: UInt64, panel_id: UInt64, owner: Address?)
	
	access(all)
	event ChapterMetadataRegistered(chapter_id: UInt64, required_slot_ids: [UInt64], reward_ids: [UInt64])
	
	access(all)
	event Completed(chapter_id: UInt64, address: Address, required_slot_ids: [UInt64], burned_panel_ids: [UInt64], burned_panel_uuids: [UInt64], burned_panel_editions: [UInt64], rewardTemplateIds: [UInt64])
	
	access(all)
	event RewardSent(id: UInt64, name: String, thumbnail: String, address: Address, player_id: UInt64?, chapter_index: UInt64?, chapter_id: UInt64?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(account)
	let royalties: [MetadataViews.Royalty]
	
	access(all)
	let chapterTemplates:{ UInt64: ChapterTemplate}
	
	access(all)
	let panelTemplates:{ UInt64: PanelMintDetail}
	
	access(all)
	var currentSerial: UInt64
	
	access(all)
	struct CompletionStatus{ 
		access(all)
		let message: String
		
		access(all)
		let complete: Bool
		
		access(all)
		let slot_id_to_id:{ UInt64: UInt64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(message: String, complete: Bool, slot_id_to_id:{ UInt64: UInt64}){ 
			self.message = message
			self.complete = complete
			self.slot_id_to_id = slot_id_to_id
			self.extra ={} 
		}
	}
	
	access(all)
	struct ChapterTemplate{ 
		access(all)
		let chapter_id: UInt64
		
		access(all)
		let chapter_index: UInt64
		
		access(all)
		let required_slot_ids: [UInt64]
		
		access(all)
		let reward_ids: [UInt64]
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(chapter_id: UInt64, required_slot_ids: [UInt64], reward_ids: [UInt64], chapter_index: UInt64){ 
			self.chapter_id = chapter_id
			self.required_slot_ids = required_slot_ids
			self.reward_ids = reward_ids
			self.extra ={} 
			self.chapter_index = chapter_index
		}
	}
	
	access(account)
	fun addChapterTemplate(_ chapter: ChapterTemplate){ 
		self.chapterTemplates[chapter.chapter_id] = chapter
		emit ChapterMetadataRegistered(chapter_id: chapter.chapter_id, required_slot_ids: chapter.required_slot_ids, reward_ids: chapter.reward_ids)
	}
	
	access(all)
	struct PanelMintDetail{ 
		access(all)
		let panel_template: PanelTemplate
		
		access(all)
		let mint_count: UInt64?
		
		access(all)
		var total_supply: UInt64
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(panel_template: PanelTemplate, mint_count: UInt64?, total_supply: UInt64){ 
			self.panel_template = panel_template
			self.mint_count = mint_count
			self.total_supply = total_supply
			self.extra ={} 
		}
		
		access(contract)
		fun mint(_ edition: UInt64): PanelMintDetail{ 
			pre{ 
				self.mint_count == nil || self.mint_count! >= edition:
					"Cannot mint panel with edition : ".concat(edition.toString())
			}
			self.total_supply = self.total_supply + 1
			return self
		}
		
		access(all)
		fun getStringDetail():{ String: String}{ 
			let map:{ String: String} ={} 
			map["mint_count"] = self.mint_count?.toString()
			map["total_supply"] = self.total_supply.toString()
			map["panel_title"] = self.panel_template.panel_title
			map["rarity"] = self.panel_template.rarity
			map["image_blurred_hash"] = self.panel_template.image_blurred_hash
			map["image_clear_hash"] = self.panel_template.image_clear_hash
			map["thumbnail_hash"] = self.panel_template.thumbnail_hash
			map["license_id"] = self.panel_template.license_id.toString()
			map["player_id"] = self.panel_template.player_id.toString()
			map["slot_id"] = self.panel_template.slot_id.toString()
			map["panel_id"] = self.panel_template.panel_id.toString()
			map["description"] = self.panel_template.description
			map["video_hash"] = self.panel_template.video_hash
			return map
		}
	}
	
	access(all)
	struct PanelTemplate{ 
		access(all)
		let chapter_id: UInt64
		
		access(all)
		let license_id: UInt64
		
		access(all)
		let player_id: UInt64
		
		access(all)
		let slot_id: UInt64
		
		access(all)
		let panel_id: UInt64
		
		access(all)
		let panel_title: String
		
		access(all)
		let description: String
		
		access(all)
		let rarity: String
		
		access(all)
		let image_blurred_hash: String
		
		access(all)
		let image_clear_hash: String
		
		access(all)
		let thumbnail_hash: String
		
		access(all)
		let reveal_thumbnail_hash: String
		
		access(all)
		let video_hash: String
		
		access(all)
		let extra:{ String: AnyStruct}
		
		// player info should be same across the chapter.
		init(chapter_id: UInt64, license_id: UInt64, player_id: UInt64, slot_id: UInt64, panel_id: UInt64, panel_title: String, description: String, rarity: String, image_blurred_hash: String, image_clear_hash: String, thumbnail_hash: String, reveal_thumbnail_hash: String, video_hash: String){ 
			self.chapter_id = chapter_id
			self.license_id = license_id
			self.player_id = player_id
			self.slot_id = slot_id
			self.panel_id = panel_id
			self.panel_title = panel_title
			self.description = description
			self.rarity = rarity
			self.image_blurred_hash = image_blurred_hash
			self.image_clear_hash = image_clear_hash
			self.thumbnail_hash = thumbnail_hash
			self.reveal_thumbnail_hash = reveal_thumbnail_hash
			self.video_hash = video_hash
			self.extra ={} 
		}
		
		// This should never be nil unless it is set up with error
		access(all)
		fun getPlayer(): AeraNFT.Player{ 
			return AeraNFT.getPlayer(self.player_id)!
		}
		
		access(all)
		fun getLicense(): AeraNFT.License?{ 
			return AeraNFT.getLicense(self.license_id)
		}
	}
	
	access(account)
	fun addPanelTemplate(panel: PanelTemplate, mint_count: UInt64?){ 
		let mintDetail = PanelMintDetail(panel_template: panel, mint_count: mint_count, total_supply: 0)
		self.panelTemplates[panel.panel_id] = mintDetail
		emit PanelMetadataRegistered(chapter_id: panel.chapter_id, slot_id: panel.slot_id, panel_id: panel.panel_id, detail: mintDetail.getStringDetail())
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// Question : Do we want things to be mutable here ?
		access(all)
		let panel_id: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let max_edition: UInt64?
		
		access(contract)
		var activated: Bool
		
		access(all)
		var nounce: UInt64
		
		// Question : Do we want things to be mutable here ?
		access(all)
		let tag:{ String: String}
		
		access(all)
		let scalar:{ String: UFix64}
		
		access(self)
		let extra:{ String: AnyStruct}
		
		init(panel_id: UInt64, serial: UInt64, edition: UInt64, max_edition: UInt64?){ 
			self.panel_id = panel_id
			self.nounce = 0
			self.id = self.uuid
			self.serial = serial
			self.edition = edition
			self.max_edition = max_edition
			self.activated = false
			self.tag ={} 
			self.scalar ={} 
			self.extra ={} 
		}
		
		access(contract)
		fun setActivated(_ bool: Bool){ 
			let panel = self.getPanel()
			var panicMessage = ""
			if bool{ 
				panicMessage = "This panel NFT is already staked. You cannot stake this again. ID : ".concat(self.id.toString())
				emit PanelStaked(id: self.id, chapter_id: panel.chapter_id, slot_id: panel.slot_id, panel_id: panel.panel_id, owner: self.owner?.address)
			} else{ 
				panicMessage = "This panel NFT is not staked. ID : ".concat(self.id.toString())
				emit PanelUnstaked(id: self.id, chapter_id: panel.chapter_id, slot_id: panel.slot_id, panel_id: panel.panel_id, owner: self.owner?.address)
			}
			if self.activated == bool{ 
				panic(panicMessage)
			}
			self.activated = bool
		}
		
		access(all)
		fun getPanel(): AeraPanels.PanelTemplate{ 
			return (AeraPanels.panelTemplates[self.panel_id]!).panel_template
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views: [Type] = [Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Rarity>(), Type<AeraPack.PackRevealData>(), Type<AeraNFT.License>()]
			if self.activated{ 
				views.append(Type<FindViews.SoulBound>())
			}
			return views
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let panel = self.getPanel()
			let thumbnail = MetadataViews.IPFSFile(cid: panel.thumbnail_hash, path: nil)
			var revealData:{ String: String} ={} 
			let revealViews: [Type] = [Type<AeraPack.PackRevealData>(), Type<AeraRewards.RewardClaimedData>()]
			if revealViews.contains(view){ 
				revealData ={ "id": self.id.toString(), "name": panel.panel_title, "chapterId": panel.chapter_id.toString(), "license_id": panel.license_id.toString(), "playerId": panel.player_id.toString(), "slotId": panel.slot_id.toString(), "panelId": panel.panel_id.toString(), "panelTitle": panel.panel_title, "description": panel.description, "image": panel.reveal_thumbnail_hash, "maxSerial": (self.max_edition!).toString(), "serial": self.serial.toString(), "edition": self.edition.toString(), "rarity": panel.rarity, "video_hash": panel.video_hash}
			}
			switch view{ 
				case Type<MetadataViews.Display>():
					let name = panel.panel_title
					// Question : Any preferred description on panel NFT?
					let description = panel.description
					return MetadataViews.Display(name: name, description: description, thumbnail: thumbnail)
				case Type<MetadataViews.ExternalURL>():
					if let addr = self.owner?.address{ 
						return MetadataViews.ExternalURL("https://aera.onefootball.com/collectibles/".concat(addr.toString()).concat("/panels/").concat(self.id.toString()))
					}
					return MetadataViews.ExternalURL("https://aera.onefootball.com/marketplace/")
				case Type<MetadataViews.Royalties>():
					// return MetadataViews.Royalties(AeraRewards.royalties)
					var address = AeraPanels.account.address
					if address == 0x46625f59708ec2f8{ 
						//testnet merchant address
						address = 0x4ff956c78244911b
					} else if address == 0x30cf5dcf6ea8d379{ 
						//mainnet merchant address
						address = 0xa9277dcbec7769df
					}
					let ducReceiver = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: ducReceiver!, cut: 0.06, description: "onefootball largest of 6% or 0.65")])
				case Type<MetadataViews.Medias>():
					// animation
					let file = MetadataViews.IPFSFile(cid: panel.video_hash, path: nil)
					let media = MetadataViews.Media(file: file, mediaType: "video/mp4")
					
					// thumbnail
					let thumbnailMedia = MetadataViews.Media(file: thumbnail, mediaType: "image/png")
					
					// clear or blurred panel
					var panelImageIpfsFile = MetadataViews.IPFSFile(cid: panel.image_clear_hash, path: nil)
					if !self.activated{ 
						panelImageIpfsFile = MetadataViews.IPFSFile(cid: panel.image_blurred_hash, path: nil)
					}
					let panelImage = MetadataViews.Media(file: panelImageIpfsFile, mediaType: "image/png")
					
					// pack opening asset
					let packOpeningIpfsFile = MetadataViews.IPFSFile(cid: panel.reveal_thumbnail_hash, path: nil)
					let packOpeningImage = MetadataViews.Media(file: packOpeningIpfsFile, mediaType: "image/png")
					return MetadataViews.Medias([thumbnailMedia, panelImage, media, packOpeningImage])
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("http://aera.onefootbal.com")
					let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafkreiameqwyluog75u7zg3dmf56b5mbed7cdgv6uslkph6nvmdf2aipmy", path: nil), mediaType: "image/jpg")
					let bannerImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiayhvr2sm4lco3tbsa74blynlnzhhzrjouteyqaq43giuyiln4xb4", path: nil), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/aera_football"), "discord": MetadataViews.ExternalURL("https://discord.gg/aera"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/aera_football/")}
					return MetadataViews.NFTCollectionDisplay(name: "Footballers Journey Panel", description: "Aera by OneFootball", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: AeraPanels.CollectionStoragePath, publicPath: AeraPanels.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-AeraPanels.createEmptyCollection(nftType: Type<@AeraPanels.Collection>())
						})
				case Type<MetadataViews.Traits>():
					let chapter = AeraPanels.chapterTemplates[panel.chapter_id] ?? panic("Chapter ID does not exist : ".concat(panel.chapter_id.toString()))
					let player = panel.getPlayer()
					let ts: [MetadataViews.Trait] = [MetadataViews.Trait(name: "chapter_id", value: panel.chapter_id, displayType: "number", rarity: nil), MetadataViews.Trait(name: "chapter_index", value: chapter.chapter_index, displayType: "number", rarity: nil), MetadataViews.Trait(name: "slot", value: panel.slot_id, displayType: "number", rarity: nil), MetadataViews.Trait(name: "panel_id", value: panel.panel_id, displayType: "number", rarity: nil), MetadataViews.Trait(name: "panel_description", value: panel.description, displayType: "string", rarity: nil),																																																																																																																																													  
																																																																																																																																													  // Add new
																																																																																																																																													  MetadataViews.Trait(name: "player_id", value: player.id, displayType: "number", rarity: nil), MetadataViews.Trait(name: "player_jersey_name", value: player.jerseyname, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_position", value: player.position, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_number", value: player.number, displayType: "number", rarity: nil), MetadataViews.Trait(name: "player_nationality", value: player.nationality, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_birthday", value: player.birthday, displayType: "date", rarity: nil)]
					if let l = panel.getLicense(){ 
						ts.append(MetadataViews.Trait(name: "copyright", value: l.copyright, displayType: "string", rarity: nil))
					}
					return MetadataViews.Traits(ts)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: "set", number: self.edition, max: self.max_edition)])
				case Type<AeraPack.PackRevealData>():
					let revealData:{ String: String} ={ "id": self.id.toString(), "name": panel.panel_title, "chapterId": panel.chapter_id.toString(), "license_id": panel.license_id.toString(), "playerId": panel.player_id.toString(), "slotId": panel.slot_id.toString(), "panelId": panel.panel_id.toString(), "panelTitle": panel.panel_title, "description": panel.description, "image": panel.reveal_thumbnail_hash, "maxSerial": (self.max_edition!).toString(), "serial": self.edition.toString(), "rarity": panel.rarity, "video_hash": panel.video_hash}
					return AeraPack.PackRevealData(revealData)
				case Type<AeraRewards.RewardClaimedData>():
					return AeraRewards.RewardClaimedData(revealData)
				case Type<MetadataViews.Rarity>():
					var rarity: UFix64 = 0.0
					switch panel.rarity{ 
						case "Common":
							rarity = 1.0
						case "Rare":
							rarity = 2.0
					}
					return MetadataViews.Rarity(score: rarity, max: nil, description: panel.rarity)
				case Type<FindViews.SoulBound>():
					if self.activated{ 
						return FindViews.SoulBound("This panel is staked. Cannot be moved. ID ".concat(self.id.toString()))
					}
					return nil
				case Type<AeraNFT.License>():
					if let license = panel.getLicense(){ 
						return license
					}
					return nil
				case Type<AeraPanels.PanelTemplate>():
					return (AeraPanels.panelTemplates[self.panel_id]!).panel_template
			}
			return nil
		}
		
		access(all)
		fun increaseNounce(){ 
			self.nounce = self.nounce + 1
		}
		
		access(contract)
		fun setLastOwner(){ 
			self.extra["lastOwner"] = (self.owner!).address
		}
		
		access(all)
		fun getLastOwner(): Address?{ 
			if let owner = self.extra["lastOwner"]{ 
				return owner as? Address
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun getPanelIdMap():{ UInt64: [UInt64]}
		
		access(all)
		fun hasNFT(_ id: UInt64): Bool
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// panel Id : UUID of Panel NFT
		access(self)
		var panelIdMap:{ UInt64: [UInt64]}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.panelIdMap ={} 
		}
		
		access(all)
		fun hasNFT(_ id: UInt64): Bool{ 
			return self.ownedNFTs.containsKey(id)
		}
		
		access(all)
		fun getPanelIdMap():{ UInt64: [UInt64]}{ 
			return self.panelIdMap
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs.containsKey(withdrawID):
					"missing NFT. ID : ".concat(withdrawID.toString())
			}
			let ref = self.borrowPanelNFT(id: withdrawID)
			ref.setLastOwner()
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			let typedToken <- token as! @AeraPanels.NFT
			let index = (self.panelIdMap[typedToken.panel_id]!).firstIndex(of: typedToken.uuid)!
			(self.panelIdMap[typedToken.panel_id]!).remove(at: index)
			return <-typedToken
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			assert(!token.activated || token.getLastOwner() == nil || token.getLastOwner()! == (self.owner!).address, message: "This panel is staked. Cannot be deposited. ID ".concat(token.id.toString()))
			let id: UInt64 = token.id
			let array = self.panelIdMap[token.panel_id] ?? []
			array.append(token.uuid)
			self.panelIdMap[token.panel_id] = array
			token.increaseNounce()
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Panel NFT ID : ".concat(id.toString())
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowPanelNFT(id: UInt64): &AeraPanels.NFT{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Panel NFT ID : ".concat(id.toString())
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &AeraPanels.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Panel NFT ID : ".concat(id.toString())
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let aeraPanelNFTs = nft as! &NFT
			return aeraPanelNFTs as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun stake(chapterId: UInt64, nftIds: [UInt64]){ 
			let chapter = AeraPanels.chapterTemplates[chapterId] ?? panic("Chapter ID does not exist : ".concat(chapterId.toString()))
			for id in nftIds{ 
				let nft = self.borrowPanelNFT(id: id)
				let panel = nft.getPanel()
				assert(panel.chapter_id == chapterId, message: "NFT ID : ".concat(id.toString()).concat("is not under Chapter ID ").concat(chapterId.toString()))
				
				// check if the other NFT with same Panel ID is activated. If they are, unstake them. Only 1 can be activated in a user storage at a time
				let panelNFTs = self.panelIdMap[nft.panel_id]!
				for p in panelNFTs{ 
					if p == id{ 
						continue
					}
					let p = self.borrowPanelNFT(id: p)
					if p.activated{ 
						p.setActivated(false)
					}
				}
				nft.setActivated(true)
			}
		}
		
		access(all)
		fun unstake(nftIds: [UInt64]){ 
			for id in nftIds{ 
				let nft = self.borrowPanelNFT(id: id)
				nft.setActivated(false)
			}
		}
		
		// pass in the chapter id,
		// get information for verification from chapter struct
		// store nft reference for sorting and emit better event
		// burn the nfts and emit events with reward id
		access(all)
		fun queryActivateStatus(chapterId: UInt64, nftIds: [UInt64]): CompletionStatus{ 
			let checked:{ UInt64: UInt64} ={} 
			let chapter = AeraPanels.chapterTemplates[chapterId] ?? panic("Chapter ID does not exist : ".concat(chapterId.toString()))
			let required_slot_ids = chapter.required_slot_ids
			for id in nftIds{ 
				let nft = self.borrowPanelNFT(id: id)
				let panel = nft.getPanel()
				if panel.chapter_id == chapterId{ 
					if required_slot_ids.contains(panel.slot_id){ 
						if checked[panel.slot_id] != nil{ 
							return CompletionStatus(message: "You are trying to burn 2 or more panels of the same template. IDs : ".concat(nft.id.toString()).concat(" , ").concat((checked[panel.slot_id]!).toString()), complete: false, slot_id_to_id:{} )
						}
						checked[panel.slot_id] = nft.id
					}
				}
				
				// check if the panel is staked. If it's not, panic
				if !nft.activated{ 
					return CompletionStatus(message: "Cannot burn unstaked panel for reward. Please stake it. ID : ".concat(id.toString()), complete: false, slot_id_to_id:{} )
				}
			}
			if required_slot_ids.length != checked.length{ 
				return CompletionStatus(message: "Please ensure you passed in all the needed panels for claiming the reward", complete: false, slot_id_to_id:{} )
			}
			return CompletionStatus(message: "Completed", complete: true, slot_id_to_id: checked)
		}
		
		access(all)
		fun activate(chapterId: UInt64, nfts: [FindViews.AuthNFTPointer], receiver: &{NonFungibleToken.Receiver}){ 
			
			// create a id map to pointers and get the ids
			let nftIds: [UInt64] = []
			let mappedNFTs:{ UInt64: FindViews.AuthNFTPointer} ={} 
			for p in nfts{ 
				mappedNFTs[p.id] = p
				nftIds.append(p.id)
			}
			let completeStatus = self.queryActivateStatus(chapterId: chapterId, nftIds: nftIds)
			if !completeStatus.complete{ 
				panic(completeStatus.message)
			}
			let burned_panel_ids: [UInt64] = []
			let burned_panel_uuids: [UInt64] = []
			let burned_panel_editions: [UInt64] = []
			let chapter = AeraPanels.chapterTemplates[chapterId] ?? panic("Chapter ID does not exist : ".concat(chapterId.toString()))
			let required_slot_ids = chapter.required_slot_ids
			var rewardData:{ UInt64:{ String: String}} ={} 
			var chapter_reward_ids = ""
			for i, rewardId in chapter.reward_ids{ 
				if i > 0{ 
					chapter_reward_ids = chapter_reward_ids.concat(",")
				}
				chapter_reward_ids = chapter_reward_ids.concat(rewardId.toString())
			}
			for slot_id in required_slot_ids{ 
				let nftId = completeStatus.slot_id_to_id[slot_id]!
				let pointer = mappedNFTs[nftId]!
				let vr = pointer.getViewResolver()
				if let view = vr.resolveView(Type<AeraRewards.RewardClaimedData>()){ 
					if let v = view as? AeraRewards.RewardClaimedData{ 
						rewardData[pointer.id] = v.data
					}
				}
				let edition = (MetadataViews.getEditions(vr)!).infoList[0].number
				let panel = vr.resolveView(Type<AeraPanels.PanelTemplate>())! as! AeraPanels.PanelTemplate
				burned_panel_ids.append(panel.panel_id)
				burned_panel_uuids.append(pointer.id)
				burned_panel_editions.append(edition)
				FindFurnace.burn(pointer: pointer, context:{ "tenant": "onefootball", "rewards": chapter_reward_ids})
			}
			// emit Completed(chapter_id: chapterId, address: self.owner!.address, required_slot_ids: required_slot_ids, burned_panel_ids: burned_panel_ids, burned_panel_uuids: burned_panel_uuids, burned_panel_editions: burned_panel_editions, rewardTemplateIds: chapter.reward_ids)
			for reward_template_id in chapter.reward_ids{ 
				AeraRewards.mintNFT(recipient: receiver, rewardTemplateId: reward_template_id, rewardFields: rewardData)
			// let reward=AeraRewards.getReward(reward_template_id)
			// emit RewardSent(id: rewardId, name: reward.reward_name, thumbnail: reward.thumbnail_hash, address: self.owner!.address, player_id:reward.detail_id["player_id"], chapter_index:reward.detail_id["chapter_index"], chapter_id: reward.detail_id["chapter_id"])
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, edition: UInt64, panelTemplateId: UInt64){ 
		pre{ 
			recipient.owner != nil:
				"Recipients NFT collection is not owned"
			self.panelTemplates.containsKey(panelTemplateId):
				"Panel template does not exist. ID : ".concat(panelTemplateId.toString())
		}
		AeraPanels.totalSupply = AeraPanels.totalSupply + 1
		AeraPanels.currentSerial = AeraPanels.currentSerial + 1
		let panelMintDetail = (self.panelTemplates[panelTemplateId]!).mint(edition)
		// create a new NFT
		var newNFT <- create NFT(panel_id: panelTemplateId, serial: AeraPanels.currentSerial, edition: edition, max_edition: panelMintDetail.mint_count)
		
		//Always emit events on state changes! always contain human readable and machine readable information
		emit Minted(id: newNFT.id, address: (recipient.owner!).address, panel_id: panelMintDetail.panel_template.panel_id, edition: edition)
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newNFT)
	}
	
	access(account)
	fun addRoyaltycut(_ cutInfo: MetadataViews.Royalty){ 
		var cutInfos = self.royalties
		cutInfos.append(cutInfo)
		// for validation only
		let royalties = MetadataViews.Royalties(cutInfos)
		self.royalties.append(cutInfo)
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.currentSerial = 0
		self.chapterTemplates ={} 
		self.panelTemplates ={} 
		
		// Set Royalty cuts in a transaction
		self.royalties = []
		
		// Set the named paths
		self.CollectionStoragePath = /storage/aeraPanelNFT
		self.CollectionPublicPath = /public/aeraPanelNFT
		self.CollectionPrivatePath = /private/aeraPanelNFT
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-AeraPanels.createEmptyCollection(nftType: Type<@AeraPanels.Collection>()), to: AeraPanels.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&AeraPanels.Collection>(AeraPanels.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: AeraPanels.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&AeraPanels.Collection>(AeraPanels.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: AeraPanels.CollectionPrivatePath)
		emit ContractInitialized()
	}
}
