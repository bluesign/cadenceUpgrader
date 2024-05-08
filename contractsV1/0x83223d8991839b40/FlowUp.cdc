import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

/// FlowUp contract to store inscriptions
///
access(all)
contract FlowUp{ 
	/* --- Events --- */
	/// Event emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	/// Event emitted when a new inscription is created
	access(all)
	event InscriptionCreated(
		id: UInt64,
		mimeType: String,
		metadata: [
			UInt8
		],
		value: UFix64,
		metaProtocol: String?,
		encoding: String?,
		parentId: UInt64?
	)
	
	access(all)
	event InscriptionBurned(id: UInt64)
	
	access(all)
	event InscriptionExtracted(id: UInt64, value: UFix64)
	
	access(all)
	event InscriptionFused(from: UInt64, to: UInt64, value: UFix64)
	
	access(all)
	event InscriptionArchived(id: UInt64)
	
	/* --- Variable, Enums and Structs --- */
	access(all)
	var totalInscriptions: UInt64
	
	/* --- Interfaces & Resources --- */
	/// The rarity of a Inscription value
	///
	access(all)
	enum ValueRarity: UInt8{ 
		access(all)
		case Common
		
		access(all)
		case Uncommon
		
		access(all)
		case Rare
		
		access(all)
		case SuperRare
		
		access(all)
		case Epic
		
		access(all)
		case Legendary
	}
	
	/// The data of an inscription
	///
	access(all)
	struct InscriptionData{ 
		/// whose value is the MIME type of the inscription
		access(all)
		let mimeType: String
		
		/// The metadata content of the inscription
		access(all)
		let metadata: [UInt8]
		
		/// The protocol used to encode the metadata
		access(all)
		let metaProtocol: String?
		
		/// The encoding used to encode the metadata
		access(all)
		let encoding: String?
		
		/// The timestamp of the inscription
		access(all)
		let createdAt: UFix64
		
		init(
			_ mimeType: String,
			_ metadata: [
				UInt8
			],
			_ metaProtocol: String?,
			_ encoding: String?
		){ 
			self.mimeType = mimeType
			self.metadata = metadata
			self.metaProtocol = metaProtocol
			self.encoding = encoding
			self.createdAt = getCurrentBlock().timestamp
		}
	}
	
	/// The metadata view for FlowUp Inscription
	///
	access(all)
	struct InscriptionView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let parentId: UInt64?
		
		access(all)
		let data: FlowUp.InscriptionData
		
		access(all)
		let value: UFix64
		
		access(all)
		let extractable: Bool
		
		init(
			id: UInt64,
			parentId: UInt64?,
			data: FlowUp.InscriptionData,
			value: UFix64,
			extractable: Bool
		){ 
			self.id = id
			self.parentId = parentId
			self.data = data
			self.value = value
			self.extractable = extractable
		}
	}
	
	/// The public interface to the inscriptions
	///
	access(all)
	resource interface InscriptionPublic{ 
		// identifiers
		access(all)
		view fun getId(): UInt64
		
		access(all)
		view fun getParentId(): UInt64?
		
		// data
		access(all)
		view fun getData(): InscriptionData
		
		access(all)
		view fun getMimeType(): String
		
		access(all)
		view fun getMetadata(): [UInt8]
		
		access(all)
		view fun getMetaProtocol(): String?
		
		access(all)
		view fun getContentEncoding(): String?
		
		// attributes
		access(all)
		view fun getMinCost(): UFix64
		
		access(all)
		view fun getInscriptionValue(): UFix64
		
		access(all)
		view fun getInscriptionRarity(): ValueRarity
		
		access(all)
		view fun isExtracted(): Bool
		
		access(all)
		view fun isExtractable(): Bool
	}
	
	/// The resource that stores the inscriptions
	///
	access(all)
	resource Inscription: InscriptionPublic, ViewResolver.Resolver{ 
		/// the id of the inscription
		access(self)
		let id: UInt64
		
		/// the id of the parent inscription
		access(self)
		let parentId: UInt64?
		
		/// the data of the inscription
		access(self)
		let data: InscriptionData
		
		/// the inscription value
		access(self)
		var value: @FlowToken.Vault?
		
		init(value: @FlowToken.Vault, mimeType: String, metadata: [UInt8], metaProtocol: String?, encoding: String?, parentId: UInt64?){ 
			post{ 
				self.isValueValid():
					"Inscription value should be bigger than minimium $FLOW at least."
			}
			self.id = FlowUp.totalInscriptions
			FlowUp.totalInscriptions = FlowUp.totalInscriptions + 1
			self.parentId = parentId
			self.data = InscriptionData(mimeType, metadata, metaProtocol, encoding)
			self.value <- value
		}
		
		/** ------ Functionality ------  */
		/// Check if the inscription is extracted
		///
		access(all)
		view fun isExtracted(): Bool{ 
			return self.value == nil
		}
		
		/// Check if the inscription is not extracted and has an owner
		///
		access(all)
		view fun isExtractable(): Bool{ 
			return !self.isExtracted() && self.owner != nil
		}
		
		/// Check if the inscription value is valid
		///
		access(all)
		view fun isValueValid(): Bool{ 
			return self.value?.balance ?? panic("No value") >= self.getMinCost()
		}
		
		/// Fuse the inscription with another inscription
		///
		access(all)
		fun fuse(_ other: @Inscription){ 
			pre{ 
				!self.isExtracted():
					"Inscription already extracted"
			}
			let otherValue <- other.extract()
			let from = other.getId()
			let fusedValue = otherValue.balance
			destroy other
			let selfValue = (&self.value as &FlowToken.Vault?)!
			selfValue.deposit(from: <-otherValue)
			emit InscriptionFused(from: from, to: self.getId(), value: fusedValue)
		}
		
		/// Extract the inscription value
		///
		access(all)
		fun extract(): @FlowToken.Vault{ 
			pre{ 
				!self.isExtracted():
					"Inscription already extracted"
			}
			post{ 
				self.isExtracted():
					"Inscription not extracted"
			}
			let balance = self.value?.balance ?? panic("No value")
			let res <- self.value <- nil
			emit InscriptionExtracted(id: self.id, value: balance)
			return <-res!
		}
		
		/// Extract a part of the inscription value, but keep the inscription be not extracted
		///
		access(all)
		fun partialExtract(_ amount: UFix64): @FlowToken.Vault{ 
			pre{ 
				!self.isExtracted():
					"Inscription already extracted"
			}
			post{ 
				self.isValueValid():
					"Inscription value should be bigger than minimium $FLOW at least."
				!self.isExtracted():
					"Inscription should not be extracted"
			}
			let ret <- self.value?.withdraw(amount: amount) ?? panic("No value")
			assert(ret.balance == amount, message: "Returned value should be equal to the amount")
			emit InscriptionExtracted(id: self.id, value: amount)
			return <-(ret as! @FlowToken.Vault)
		}
		
		/// Get the minimum value of the inscription
		///
		access(all)
		view fun getMinCost(): UFix64{ 
			let data = self.data
			return FlowUp.estimateValue(index: self.getId(), mimeType: data.mimeType, data: data.metadata, protocol: data.metaProtocol, encoding: data.encoding)
		}
		
		/// Get the value of the inscription
		///
		access(all)
		view fun getInscriptionValue(): UFix64{ 
			return self.value?.balance ?? 0.0
		}
		
		/// Get the rarity of the inscription
		///
		access(all)
		view fun getInscriptionRarity(): ValueRarity{ 
			let value = self.value?.balance ?? 0.0
			if value <= 0.1{ // 0.001 ~ 0.1 
				
				return ValueRarity.Common
			} else if value <= 10.0{ // 0.1 ~ 10 
				
				return ValueRarity.Uncommon
			} else if value <= 1000.0{ // 10 ~ 1000 
				
				return ValueRarity.Rare
			} else if value <= 10000.0{ // 1000 ~ 10000 
				
				return ValueRarity.SuperRare
			} else if value <= 100000.0{ // 10000 ~ 100000 
				
				return ValueRarity.Epic
			} else{ // 100000 ~ 
				
				return ValueRarity.Legendary
			}
		}
		
		/** ---- Implementation of InscriptionPublic ---- */
		access(all)
		view fun getId(): UInt64{ 
			return self.id
		}
		
		access(all)
		view fun getParentId(): UInt64?{ 
			return self.parentId
		}
		
		access(all)
		view fun getData(): InscriptionData{ 
			return self.data
		}
		
		access(all)
		view fun getMimeType(): String{ 
			return self.data.mimeType
		}
		
		access(all)
		view fun getMetadata(): [UInt8]{ 
			return self.data.metadata
		}
		
		access(all)
		view fun getMetaProtocol(): String?{ 
			return self.data.metaProtocol
		}
		
		access(all)
		view fun getContentEncoding(): String?{ 
			return self.data.encoding
		}
		
		/** ---- Implementation of MetadataViews.Resolver ---- */
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<FlowUp.InscriptionView>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Rarity>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let rarity = self.getInscriptionRarity()
			let ratityView = MetadataViews.Rarity(score: UFix64(rarity.rawValue), max: UFix64(ValueRarity.Legendary.rawValue), description: nil)
			let mimeType = self.getMimeType()
			let metadata = self.getMetadata()
			let encoding = self.getContentEncoding()
			let isUTF8 = encoding == "utf8" || encoding == "utf-8" || encoding == nil
			let fileView = MetadataViews.HTTPFile(url: "data:".concat(mimeType).concat(";").concat(isUTF8 ? "utf8;charset=UTF-8" : encoding!).concat(",").concat(isUTF8 ? String.fromUTF8(metadata)! : encoding == "hex" ? String.encodeHex(metadata) : ""))
			switch view{ 
				case Type<FlowUp.InscriptionView>():
					return FlowUp.InscriptionView(id: self.getId(), parentId: self.getParentId(), data: self.getData(), value: self.getInscriptionValue(), extractable: self.isExtractable())
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.getId())
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: "FIXeS Inscription #".concat(self.getId().toString()), description: "FlowUp is a decentralized protocol to store and exchange inscriptions.", thumbnail: fileView)
				case Type<MetadataViews.Medias>():
					return MetadataViews.Medias([MetadataViews.Media(file: fileView, mediaType: mimeType)])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://fixes.world/")
				case Type<MetadataViews.Rarity>():
					return ratityView
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits([MetadataViews.Trait(name: "id", value: self.getId(), displayType: nil, rarity: nil), MetadataViews.Trait(name: "mimeType", value: self.getMimeType(), displayType: nil, rarity: nil), MetadataViews.Trait(name: "metaProtocol", value: self.getMetaProtocol(), displayType: nil, rarity: nil), MetadataViews.Trait(name: "encoding", value: self.getContentEncoding(), displayType: nil, rarity: nil), MetadataViews.Trait(name: "rarity", value: rarity.rawValue, displayType: nil, rarity: ratityView)])
			}
			return nil
		}
	}
	
	access(all)
	resource interface ArchivedInscriptionsPublic{ 
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowInscription(_ id: UInt64): &FlowUp.Inscription?
	}
	
	/// The resource that stores the archived inscriptions
	///
	access(all)
	resource ArchivedInscriptions{ 
		access(self)
		let inscriptions: @{UInt64: FlowUp.Inscription}
		
		init(){ 
			self.inscriptions <-{} 
		}
		
		// --- Public Methods ---
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.inscriptions.keys
		}
		
		access(all)
		view fun borrowInscription(_ id: UInt64): &FlowUp.Inscription?{ 
			return self.borrowInscriptionWritableRef(id)
		}
		
		// --- Private Methods ---
		access(all)
		fun archive(_ ins: @FlowUp.Inscription){ 
			pre{ 
				ins.isExtracted():
					"Inscription should be extracted"
			}
			// inscription id should be unique
			let id = ins.getId()
			let old <- self.inscriptions.insert(key: id, <-ins)
			emit InscriptionArchived(id: id)
			destroy old
		}
		
		access(all)
		view fun borrowInscriptionWritableRef(_ id: UInt64): &FlowUp.Inscription?{ 
			return &self.inscriptions[id] as &FlowUp.Inscription?
		}
	}
	
	/* --- Methods --- */
	/// Create a new inscription
	///
	access(all)
	fun createInscription(
		value: @FlowToken.Vault,
		mimeType: String,
		metadata: [
			UInt8
		],
		metaProtocol: String?,
		encoding: String?,
		parentId: UInt64?
	): @Inscription{ 
		let bal = value.balance
		let ins <-
			create Inscription(
				value: <-value,
				mimeType: mimeType,
				metadata: metadata,
				metaProtocol: metaProtocol,
				encoding: encoding,
				parentId: parentId
			)
		// emit event
		emit InscriptionCreated(
			id: ins.getId(),
			mimeType: ins.getMimeType(),
			metadata: ins.getMetadata(),
			value: bal,
			metaProtocol: ins.getMetaProtocol(),
			encoding: ins.getContentEncoding(),
			parentId: ins.getParentId()
		)
		return <-ins
	}
	
	access(all)
	view fun estimateValue(
		index: UInt64,
		mimeType: String,
		data: [
			UInt8
		],
		protocol: String?,
		encoding: String?
	): UFix64{ 
		let currIdxValue = UFix64(index / UInt64(UInt8.max) + 1)
		let maxIdxValue = 1000.0
		let estimatedIndexValue = currIdxValue < maxIdxValue ? currIdxValue : maxIdxValue
		let bytes =
			UFix64(
				(
					mimeType.length + (protocol != nil ? (protocol!).length : 0)
					+ (encoding != nil ? (encoding!).length : 0)
				)
				* 3
			)
			+ UFix64(data.length)
			+ estimatedIndexValue
		return bytes * 0.0002
	}
	
	/// Get the storage path of a inscription
	///
	access(all)
	view fun getFixesStoragePath(index: UInt64): StoragePath{ 
		let prefix = "Fixes_".concat(self.account.address.toString())
		return StoragePath(identifier: prefix.concat("_").concat(index.toString()))!
	}
	
	access(all)
	view fun getArchivedFixesStoragePath(): StoragePath{ 
		let prefix = "Fixes_".concat(self.account.address.toString())
		return StoragePath(identifier: prefix.concat("_archived"))!
	}
	
	init(){ 
		self.totalInscriptions = 0
		emit ContractInitialized()
	}
}
