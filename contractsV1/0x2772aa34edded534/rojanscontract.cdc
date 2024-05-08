/*
rojanscontract

This is the contract for rojanscontract NFTs!

This was implemented using Niftory interfaces. For full details on how this
contract functions, please see the Niftory and NFTRegistry contracts.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

import MutableMetadata from "../0x7ec1f607f0872a9e/MutableMetadata.cdc"

import MutableMetadataTemplate from "../0x7ec1f607f0872a9e/MutableMetadataTemplate.cdc"

import MutableMetadataSet from "../0x7ec1f607f0872a9e/MutableMetadataSet.cdc"

import MutableMetadataSetManager from "../0x7ec1f607f0872a9e/MutableMetadataSetManager.cdc"

import MetadataViewsManager from "../0x7ec1f607f0872a9e/MetadataViewsManager.cdc"

import NiftoryNonFungibleToken from "../0x7ec1f607f0872a9e/NiftoryNonFungibleToken.cdc"

import NiftoryNFTRegistry from "../0x7ec1f607f0872a9e/NiftoryNFTRegistry.cdc"

import NiftoryMetadataViewsResolvers from "../0x7ec1f607f0872a9e/NiftoryMetadataViewsResolvers.cdc"

import NiftoryNonFungibleTokenProxy from "../0x7ec1f607f0872a9e/NiftoryNonFungibleTokenProxy.cdc"

access(all)
contract rojanscontract: NonFungibleToken, ViewResolver{ 
	
	// ========================================================================
	// Constants
	// ========================================================================
	
	// Suggested paths where collection could be stored
	access(all)
	let COLLECTION_PRIVATE_PATH: PrivatePath
	
	access(all)
	let COLLECTION_PUBLIC_PATH: PublicPath
	
	access(all)
	let COLLECTION_STORAGE_PATH: StoragePath
	
	// Accessor token to be used with NiftoryNFTRegistry to retrieve
	// meta-information about this NFT project
	access(all)
	let REGISTRY_ADDRESS: Address
	
	access(all)
	let REGISTRY_BRAND: String
	
	// ========================================================================
	// Attributes
	// ========================================================================
	// Arbitrary metadata for this NFT contract
	access(all)
	var metadata: AnyStruct?
	
	// Number of NFTs created
	access(all)
	var totalSupply: UInt64
	
	// ========================================================================
	// Contract Events
	// ========================================================================
	// This contract was initialized
	access(all)
	event ContractInitialized()
	
	// A withdrawal of NFT `id` has occurred from the `from` Address
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// A deposit of an NFT `id` has occurred to the `to` Address
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	///////////////////////////////////////////////////////////////////////////
	// Contract metadata was modified
	access(all)
	event ContractMetadataUpdated()
	
	// Metadata Views Manager was locked
	access(all)
	event MetadataViewsManagerLocked()
	
	// Metadata Views Resolver was added
	access(all)
	event MetadataViewsResolverAdded(type: Type)
	
	// Metadata Views Resolver was removed
	access(all)
	event MetadataViewsResolverRemoved(type: Type)
	
	// Set Manager Name or Description updated
	access(all)
	event SetManagerMetadataUpdated()
	
	// Set added to Set Manager
	access(all)
	event SetAddedToSetManager(setID: Int)
	
	///////////////////////////////////////////////////////////////////////////
	// Set `setId` was locked (no new templates can be added)
	access(all)
	event SetLocked(setId: Int)
	
	// The metadata for Set `setId` was locked and cannot be modified
	access(all)
	event SetMetadataLocked(setId: Int)
	
	// Set `setId` was modified
	access(all)
	event SetMetadataModified(setId: Int)
	
	// A new Template `templateId` was added to Set `setId`
	access(all)
	event TemplateAddedToSet(setId: Int, templateId: Int)
	
	///////////////////////////////////////////////////////////////////////////
	// Template `templateId` was locked in Set `setId`, which disables minting
	access(all)
	event TemplateLocked(setId: Int, templateId: Int)
	
	// Template `templateId` of Set `setId` had it's maxMint set to `maxMint`
	access(all)
	event TemplateMaxMintSet(setId: Int, templateId: Int, maxMint: UInt64)
	
	// Template `templateId` of Set `setId` has minted NFT with serial `serial`
	access(all)
	event NFTMinted(id: UInt64, setId: Int, templateId: Int, serial: UInt64)
	
	///////////////////////////////////////////////////////////////////////////
	// The metadata for NFT/Template `templateId` of Set `setId` was locked
	access(all)
	event NFTMetadataLocked(setId: Int, templateId: Int)
	
	// The metadata for NFT/Template `templateId` of Set `setId` was modified
	access(all)
	event NFTMetadataModified(setId: Int, templateId: Int)
	
	///////////////////////////////////////////////////////////////////////////
	// NFT `serial` from Template `templateId` of Set `setId` was burned
	access(all)
	event NFTBurned(setId: Int, templateId: Int, serial: UInt64)
	
	// ========================================================================
	// NFT
	// ========================================================================
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, NiftoryNonFungibleToken.NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let setId: Int
		
		access(all)
		let templateId: Int
		
		access(all)
		let serial: UInt64
		
		access(all)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return rojanscontract._contract()
		}
		
		access(all)
		fun set(): &MutableMetadataSet.Set{ 
			return self._contract().getSetManagerPublic().getSet(self.setId)
		}
		
		access(all)
		fun metadata(): &MutableMetadata.Metadata{ 
			return self.set().getTemplate(self.templateId).metadata()
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return self._contract().getMetadataViewsManagerPublic().getViews()
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let nftRef = &self as &{NiftoryNonFungibleToken.NFTPublic}
			return self._contract().getMetadataViewsManagerPublic().resolveView(view: view, nftRef: nftRef)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(setId: Int, templateId: Int, serial: UInt64){ 
			self.id = rojanscontract.totalSupply
			rojanscontract.totalSupply = rojanscontract.totalSupply + 1
			self.setId = setId
			self.templateId = templateId
			self.serial = serial
		}
	}
	
	// ========================================================================
	// Collection
	// ========================================================================
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, NiftoryNonFungibleToken.CollectionPublic, NiftoryNonFungibleToken.CollectionPrivate{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
			return rojanscontract._contract()
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT ".concat(id.toString()).concat(" does not exist in collection.")
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrow(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in collection."
			}
			let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let fullNft = nftRef as! &NFT
			return fullNft
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in collection."
			}
			let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let fullNft = nftRef as! &NFT
			return fullNft
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @rojanscontract.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		fun depositBulk(tokens: @[{NonFungibleToken.NFT}]){ 
			while tokens.length > 0{ 
				let token <- tokens.removeLast() as! @rojanscontract.NFT
				self.deposit(token: <-token)
			}
			destroy tokens
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs[withdrawID] != nil:
					"NFT ".concat(withdrawID.toString()).concat(" does not exist in collection.")
			}
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun withdrawBulk(withdrawIDs: [UInt64]): @[{NonFungibleToken.NFT}]{ 
			let tokens: @[{NonFungibleToken.NFT}] <- []
			while withdrawIDs.length > 0{ 
				tokens.append(<-self.withdraw(withdrawID: withdrawIDs.removeLast()))
			}
			return <-tokens
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// ========================================================================
	// Manager
	// ========================================================================
	access(all)
	resource Manager: NiftoryNonFungibleToken.ManagerPublic, NiftoryNonFungibleToken.ManagerPrivate{ 
		// ========================================================================
		// Public
		// ========================================================================
		access(all)
		fun metadata(): AnyStruct?{ 
			return rojanscontract.metadata
		}
		
		access(all)
		fun getSetManagerPublic(): &MutableMetadataSetManager.Manager{ 
			return NiftoryNFTRegistry.getSetManagerPublic(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND)
		}
		
		access(all)
		fun getMetadataViewsManagerPublic(): &MetadataViewsManager.Manager{ 
			return NiftoryNFTRegistry.getMetadataViewsManagerPublic(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND)
		}
		
		access(all)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return NiftoryNFTRegistry.buildNFTCollectionData(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND, fun (): @{NonFungibleToken.Collection}{ 
					return <-rojanscontract.createEmptyCollection(nftType: Type<@rojanscontract.Collection>())
				})
		}
		
		// ========================================================================
		// Contract metadata
		// ========================================================================
		access(all)
		fun modifyContractMetadata(): &AnyStruct{ 
			emit ContractMetadataUpdated()
			let maybeMetadata = rojanscontract.metadata
			if maybeMetadata == nil{ 
				let blankMetadata:{ String: String} ={} 
				rojanscontract.metadata = blankMetadata
			}
			return (&rojanscontract.metadata as &AnyStruct?)!
		}
		
		access(all)
		fun replaceContractMetadata(_ metadata: AnyStruct?){ 
			emit ContractMetadataUpdated()
			rojanscontract.metadata = metadata
		}
		
		// ========================================================================
		// Metadata Views Manager
		// ========================================================================
		access(self)
		fun _getMetadataViewsManagerPrivate(): &MetadataViewsManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND)
			let manager = rojanscontract.account.capabilities.get<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.private).borrow()!
			return manager
		}
		
		access(all)
		fun lockMetadataViewsManager(){ 
			self._getMetadataViewsManagerPrivate().lock()
			emit MetadataViewsManagerLocked()
		}
		
		access(all)
		fun setMetadataViewsResolver(_ resolver:{ MetadataViewsManager.Resolver}){ 
			self._getMetadataViewsManagerPrivate().addResolver(resolver)
			emit MetadataViewsResolverAdded(type: resolver.type)
		}
		
		access(all)
		fun removeMetadataViewsResolver(_ type: Type){ 
			self._getMetadataViewsManagerPrivate().removeResolver(type)
			emit MetadataViewsResolverRemoved(type: type)
		}
		
		// ========================================================================
		// Set Manager
		// ========================================================================
		access(self)
		fun _getSetManagerPrivate(): &MutableMetadataSetManager.Manager{ 
			let record = NiftoryNFTRegistry.getRegistryRecord(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND)
			let setManager = rojanscontract.account.capabilities.get<&MutableMetadataSetManager.Manager>(record.setManager.paths.private).borrow()!
			return setManager
		}
		
		access(all)
		fun setMetadataManagerName(_ name: String){ 
			self._getSetManagerPrivate().setName(name)
			emit SetManagerMetadataUpdated()
		}
		
		access(all)
		fun setMetadataManagerDescription(_ description: String){ 
			self._getSetManagerPrivate().setDescription(description)
			emit SetManagerMetadataUpdated()
		}
		
		access(all)
		fun addSet(_ set: @MutableMetadataSet.Set){ 
			let setManager = self._getSetManagerPrivate()
			let setId = setManager.numSets()
			setManager.addSet(<-set)
			emit SetAddedToSetManager(setID: setId)
		}
		
		// ========================================================================
		// Set
		// ========================================================================
		access(self)
		fun _getSetMutable(_ setId: Int): &MutableMetadataSet.Set{ 
			return self._getSetManagerPrivate().getSetMutable(setId)
		}
		
		access(all)
		fun lockSet(setId: Int){ 
			self._getSetMutable(setId).lock()
			emit SetLocked(setId: setId)
		}
		
		access(all)
		fun lockSetMetadata(setId: Int){ 
			self._getSetMutable(setId).metadataMutable().lock()
			emit SetMetadataLocked(setId: setId)
		}
		
		access(all)
		fun modifySetMetadata(setId: Int): &AnyStruct{ 
			emit SetMetadataModified(setId: setId)
			return self._getSetMutable(setId).metadataMutable().getMutable()
		}
		
		access(all)
		fun replaceSetMetadata(setId: Int, new: AnyStruct){ 
			self._getSetMutable(setId).metadataMutable().replace(new)
			emit SetMetadataModified(setId: setId)
		}
		
		access(all)
		fun addTemplate(setId: Int, template: @MutableMetadataTemplate.Template){ 
			let set = self._getSetMutable(setId)
			let templateId = set.numTemplates()
			set.addTemplate(<-template)
			emit TemplateAddedToSet(setId: setId, templateId: templateId)
		}
		
		// ========================================================================
		// Minting
		// ========================================================================
		access(self)
		fun _getTemplateMutable(_ setId: Int, _ templateId: Int): &MutableMetadataTemplate.Template{ 
			return self._getSetMutable(setId).getTemplateMutable(templateId)
		}
		
		access(all)
		fun lockTemplate(setId: Int, templateId: Int){ 
			self._getTemplateMutable(setId, templateId).lock()
			emit TemplateLocked(setId: setId, templateId: templateId)
		}
		
		access(all)
		fun setTemplateMaxMint(setId: Int, templateId: Int, max: UInt64){ 
			self._getTemplateMutable(setId, templateId).setMaxMint(max)
			emit TemplateMaxMintSet(setId: setId, templateId: templateId, maxMint: max)
		}
		
		access(all)
		fun mint(setId: Int, templateId: Int): @{NonFungibleToken.NFT}{ 
			let template = self._getTemplateMutable(setId, templateId)
			template.registerMint()
			let serial = template.minted()
			let nft <- create NFT(setId: setId, templateId: templateId, serial: serial)
			emit NFTMinted(id: nft.id, setId: setId, templateId: templateId, serial: serial)
			return <-nft
		}
		
		access(all)
		fun mintBulk(setId: Int, templateId: Int, numToMint: UInt64): @[{NonFungibleToken.NFT}]{ 
			pre{ 
				numToMint > 0:
					"Must mint at least one NFT"
			}
			let template = self._getTemplateMutable(setId, templateId)
			let nfts: @[{NonFungibleToken.NFT}] <- []
			var leftToMint = numToMint
			while leftToMint > 0{ 
				template.registerMint()
				let serial = template.minted()
				let nft <- create NFT(setId: setId, templateId: templateId, serial: serial)
				emit NFTMinted(id: nft.id, setId: setId, templateId: templateId, serial: serial)
				nfts.append(<-nft)
				leftToMint = leftToMint - 1
			}
			return <-nfts
		}
		
		// ========================================================================
		// NFT metadata
		// ========================================================================
		access(self)
		fun _getNFTMetadata(_ setId: Int, _ templateId: Int): &MutableMetadata.Metadata{ 
			return self._getTemplateMutable(setId, templateId).metadataMutable()
		}
		
		access(all)
		fun lockNFTMetadata(setId: Int, templateId: Int){ 
			self._getNFTMetadata(setId, templateId).lock()
			emit NFTMetadataLocked(setId: setId, templateId: templateId)
		}
		
		access(all)
		fun modifyNFTMetadata(setId: Int, templateId: Int): &AnyStruct{ 
			emit NFTMetadataModified(setId: setId, templateId: templateId)
			return self._getNFTMetadata(setId, templateId).getMutable()
		}
		
		access(all)
		fun replaceNFTMetadata(setId: Int, templateId: Int, new: AnyStruct){ 
			self._getNFTMetadata(setId, templateId).replace(new)
			emit NFTMetadataModified(setId: setId, templateId: templateId)
		}
	}
	
	// ========================================================================
	// Contract functions
	// ========================================================================
	access(all)
	view fun _contract(): &{NiftoryNonFungibleToken.ManagerPublic}{ 
		return NiftoryNFTRegistry.getNFTManagerPublic(rojanscontract.REGISTRY_ADDRESS, rojanscontract.REGISTRY_BRAND)
	}
	
	access(all)
	fun getViews(): [Type]{ 
		let possibleViews = [Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>()]
		let views: [Type] = [Type<MetadataViews.NFTCollectionData>()]
		let viewManager = self._contract().getMetadataViewsManagerPublic()
		for view in possibleViews{ 
			if viewManager.inspectView(view: view) != nil{ 
				views.append(view)
			}
		}
		return views
	}
	
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		let viewManager = self._contract().getMetadataViewsManagerPublic()
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return self._contract().getNFTCollectionData()
			case Type<MetadataViews.NFTCollectionDisplay>():
				let maybeView = viewManager.inspectView(view: Type<MetadataViews.NFTCollectionDisplay>())
				if maybeView == nil{ 
					return nil
				}
				let view = maybeView!
				if view.isInstance(Type<NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolver>()){ 
					let resolver = view as! NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolver
					
					// External URL
					let externalURL = MetadataViews.ExternalURL(NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultExternalURLPrefix, uri: resolver.defaultExternalURL))
					
					// Square image
					let squareImageURL = NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultSquareImagePrefix, uri: resolver.defaultSquareImage)
					let squareImageMediaType = resolver.defaultSquareImageMediaType
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: squareImageURL), mediaType: squareImageMediaType)
					
					// Banner image
					let bannerImageURL = NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultBannerImagePrefix, uri: resolver.defaultBannerImage)
					let bannerImageMediaType = resolver.defaultBannerImageMediaType
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: bannerImageURL), mediaType: bannerImageMediaType)
					return MetadataViews.NFTCollectionDisplay(name: resolver.defaultName, description: resolver.defaultDescription, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{} )
				}
				if view.isInstance(Type<NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolverWithIpfsGateway>()){ 
					let resolver = view as! NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolverWithIpfsGateway
					
					// External URL
					let externalURL = MetadataViews.ExternalURL(NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultExternalURLPrefix, uri: resolver.defaultExternalURL))
					
					// Square image
					let squareImageURL = NiftoryMetadataViewsResolvers._useIpfsGateway(ipfsGateway: resolver.ipfsGateway, uri: NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultSquareImagePrefix, uri: resolver.defaultSquareImage))
					let squareImageMediaType = resolver.defaultSquareImageMediaType
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: squareImageURL), mediaType: squareImageMediaType)
					
					// Banner image
					let bannerImageURL = NiftoryMetadataViewsResolvers._useIpfsGateway(ipfsGateway: resolver.ipfsGateway, uri: NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultBannerImagePrefix, uri: resolver.defaultBannerImage))
					let bannerImageMediaType = resolver.defaultBannerImageMediaType
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: bannerImageURL), mediaType: bannerImageMediaType)
					return MetadataViews.NFTCollectionDisplay(name: resolver.defaultName, description: resolver.defaultDescription, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{} )
				}
				return nil
			case Type<MetadataViews.ExternalURL>():
				let maybeView = viewManager.inspectView(view: Type<MetadataViews.ExternalURL>())
				if maybeView == nil{ 
					return nil
				}
				let view = maybeView!
				if view.isInstance(Type<NiftoryMetadataViewsResolvers.ExternalURLResolver>()){ 
					let resolver = view as! NiftoryMetadataViewsResolvers.ExternalURLResolver
					return MetadataViews.ExternalURL(NiftoryMetadataViewsResolvers._prefixUri(allowedPrefixes: NiftoryMetadataViewsResolvers.DEFAULT_ALLOWED_URI_PREFIXES(), _default: resolver.defaultPrefix, uri: resolver.defaultURL))
				}
				return nil
		}
		return nil
	}
	
	// ========================================================================
	// Init
	// ========================================================================
	init(nftManagerProxy: &{NiftoryNonFungibleTokenProxy.Public, NiftoryNonFungibleTokenProxy.Private}){ 
		let record = NiftoryNFTRegistry.generateRecord(account: self.account.address, project: "cl98w58er00010ijyz4egiary_rojanscontract")
		self.REGISTRY_ADDRESS = 0x32d62d5c43ad1038
		self.REGISTRY_BRAND = "cl98w58er00010ijyz4egiary_rojanscontract"
		self.COLLECTION_PUBLIC_PATH = record.collectionPaths.public
		self.COLLECTION_PRIVATE_PATH = record.collectionPaths.private
		self.COLLECTION_STORAGE_PATH = record.collectionPaths.storage
		
		// No metadata to start with
		self.metadata = nil
		
		// Initialize the total supply to 0.
		self.totalSupply = 0
		
		// The Manager for this NFT
		//
		// NFT Manager storage
		let nftManager <- create Manager()
		
		// Save a MutableSetManager to this contract's storage, as the source of
		// this NFT contract's metadata.
		//
		// MutableMetadataSetManager storage
		self.account.storage.save<@MutableMetadataSetManager.Manager>(<-MutableMetadataSetManager._create(name: "rojanscontract", description: "The set manager for rojanscontract."), to: record.setManager.paths.storage)
		
		// MutableMetadataSetManager public
		var capability_1 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_1, at: record.setManager.paths.public)
		
		// MutableMetadataSetManager private
		var capability_2 = self.account.capabilities.storage.issue<&MutableMetadataSetManager.Manager>(record.setManager.paths.storage)
		self.account.capabilities.publish(capability_2, at: record.setManager.paths.private)
		
		// Save a MetadataViewsManager to this contract's storage, which will
		// allow observers to inspect standardized metadata through any of its
		// configured MetadataViews resolvers.
		//
		// MetadataViewsManager storage
		self.account.storage.save<@MetadataViewsManager.Manager>(<-MetadataViewsManager._create(), to: record.metadataViewsManager.paths.storage)
		
		// MetadataViewsManager public
		var capability_3 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_3, at: record.metadataViewsManager.paths.public)
		
		// MetadataViewsManager private
		var capability_4 = self.account.capabilities.storage.issue<&MetadataViewsManager.Manager>(record.metadataViewsManager.paths.storage)
		self.account.capabilities.publish(capability_4, at: record.metadataViewsManager.paths.private)
		let contractName = "rojanscontract"
		
		// Royalties
		let royaltiesResolver = NiftoryMetadataViewsResolvers.RoyaltiesResolver(royalties: MetadataViews.Royalties([]))
		nftManager.setMetadataViewsResolver(royaltiesResolver)
		
		// Collection Data
		let collectionDataResolver = NiftoryMetadataViewsResolvers.NFTCollectionDataResolver()
		nftManager.setMetadataViewsResolver(collectionDataResolver)
		
		// Display
		let displayResolver = NiftoryMetadataViewsResolvers.DisplayResolver(nameField: "title", defaultName: contractName.concat("NFT"), descriptionField: "description", defaultDescription: contractName.concat(" NFT"), imageField: "mediaUrl", defaultImagePrefix: "ipfs://", defaultImage: "ipfs://bafybeig6la3me5x3veull7jzxmwle4sfuaguou2is3o3z44ayhe7ihlqpa/NiftoryBanner.png")
		nftManager.setMetadataViewsResolver(displayResolver)
		
		// Collection Display
		let collectionResolver = NiftoryMetadataViewsResolvers.NFTCollectionDisplayResolver(nameField: "title", defaultName: contractName, descriptionField: "description", defaultDescription: contractName.concat(" Collection"), externalUrlField: "domainUrl", defaultExternalURLPrefix: "https://", defaultExternalURL: "https://niftory.com", squareImageField: "squareImage", defaultSquareImagePrefix: "ipfs://", defaultSquareImage: "ipfs://bafybeihc76uodw2at2xi2l5jydpvscj5ophfpqgblbrmsfpeffhcmgdtl4/squareImage.png", squareImageMediaTypeField: "squareImageMediaType", defaultSquareImageMediaType: "image/png", bannerImageField: "bannerImage", defaultBannerImagePrefix: "ipfs://", defaultBannerImage: "ipfs://bafybeig6la3me5x3veull7jzxmwle4sfuaguou2is3o3z44ayhe7ihlqpa/NiftoryBanner.png", bannerImageMediaTypeField: "bannerImageMediaType", defaultBannerImageMediaType: "image/png", socialsFields: [])
		nftManager.setMetadataViewsResolver(collectionResolver)
		
		// ExternalURL
		let externalURLResolver = NiftoryMetadataViewsResolvers.ExternalURLResolver(field: "domainUrl", defaultPrefix: "https://", defaultURL: "https://niftory.com")
		nftManager.setMetadataViewsResolver(externalURLResolver)
		
		// Save NFT Manager
		self.account.storage.save<@Manager>(<-nftManager, to: record.nftManager.paths.storage)
		
		// NFT Manager public
		var capability_5 = self.account.capabilities.storage.issue<&{NiftoryNonFungibleToken.ManagerPublic}>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_5, at: record.nftManager.paths.public)
		
		// NFT Manager private
		var capability_6 = self.account.capabilities.storage.issue<&Manager>(record.nftManager.paths.storage)
		self.account.capabilities.publish(capability_6, at: record.nftManager.paths.private)
		nftManagerProxy.add(registryAddress: self.REGISTRY_ADDRESS, brand: self.REGISTRY_BRAND, cap: self.account.capabilities.get<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>(record.nftManager.paths.private)!)
	}
}
