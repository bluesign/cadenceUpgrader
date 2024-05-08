import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract TenantService: NonFungibleToken{ 
	
	// basic data about the tenant
	access(all)
	let id: String
	
	access(all)
	let name: String
	
	access(all)
	let description: String
	
	access(all)
	var closed: Bool
	
	// NFT
	access(all)
	var totalSupply: UInt64
	
	// paths
	access(all)
	let ADMIN_OBJECT_PATH: StoragePath
	
	access(all)
	let PRIVATE_NFT_COLLECTION_PATH: StoragePath
	
	access(all)
	let PUBLIC_NFT_COLLECTION_PATH: PublicPath
	
	// archetypes
	access(self)
	let archetypes:{ UInt64: Archetype}
	
	access(self)
	let archetypeAdmins: @{UInt64: ArchetypeAdmin}
	
	access(self)
	var archetypeSeq: UInt64
	
	access(self)
	let artifactsByArchetype:{ UInt64:{ UInt64: Bool}} // archetypeId -> {artifactId: true}
	
	
	// artifacts
	access(self)
	let artifacts:{ UInt64: Artifact}
	
	access(self)
	let artifactAdmins: @{UInt64: ArtifactAdmin}
	
	access(self)
	var artifactSeq: UInt64
	
	access(self)
	var nextNftSerialNumber:{ UInt64: UInt64}
	
	access(self)
	let setsByArtifact:{ UInt64:{ UInt64: Bool}} // artifactId -> {setId: true}
	
	
	access(self)
	let faucetsByArtifact:{ UInt64:{ UInt64: Bool}} // artifactId -> {faucetId: true}
	
	
	// sets
	access(self)
	let sets:{ UInt64: Set}
	
	access(self)
	let setAdmins: @{UInt64: SetAdmin}
	
	access(self)
	var setSeq: UInt64
	
	access(self)
	let artifactsBySet:{ UInt64:{ UInt64: Bool}} // setId -> {artifactId: true}
	
	
	access(self)
	let faucetsBySet:{ UInt64:{ UInt64: Bool}} // setId -> {faucetId: true}
	
	
	// prints
	access(self)
	let prints:{ UInt64: Print}
	
	access(self)
	let printAdmins: @{UInt64: PrintAdmin}
	
	access(self)
	var printSeq: UInt64
	
	// faucets
	access(self)
	let faucets:{ UInt64: Faucet}
	
	access(self)
	let faucetAdmins: @{UInt64: FaucetAdmin}
	
	access(self)
	var faucetSeq: UInt64
	
	// tenant events
	access(all)
	event TenantClosed()
	
	// NFT events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	init(tenantId: String, tenantName: String, tenantDescription: String, ADMIN_OBJECT_PATH: StoragePath, PRIVATE_NFT_COLLECTION_PATH: StoragePath, PUBLIC_NFT_COLLECTION_PATH: PublicPath){ 
		self.id = tenantId
		self.name = tenantName
		self.description = tenantDescription
		self.closed = false
		self.archetypes ={} 
		self.archetypeAdmins <-{} 
		self.archetypeSeq = 1
		self.artifactsByArchetype ={} 
		self.artifacts ={} 
		self.artifactAdmins <-{} 
		self.artifactSeq = 1
		self.nextNftSerialNumber ={} 
		self.setsByArtifact ={} 
		self.faucetsByArtifact ={} 
		self.sets ={} 
		self.setAdmins <-{} 
		self.setSeq = 1
		self.artifactsBySet ={} 
		self.faucetsBySet ={} 
		self.prints ={} 
		self.printAdmins <-{} 
		self.printSeq = 1
		self.faucets ={} 
		self.faucetAdmins <-{} 
		self.faucetSeq = 1
		self.totalSupply = 0
		self.OBJECT_TYPE_MASK = UInt64.max << 55
		self.SEQUENCE_MASK = UInt64.max << UInt64(9) >> UInt64(9)
		self.ADMIN_OBJECT_PATH = ADMIN_OBJECT_PATH
		self.PRIVATE_NFT_COLLECTION_PATH = PRIVATE_NFT_COLLECTION_PATH
		self.PUBLIC_NFT_COLLECTION_PATH = PUBLIC_NFT_COLLECTION_PATH
		
		// create a collection for the admin
		self.account.storage.save<@ShardedCollection>(<-TenantService.createEmptyShardedCollection(numBuckets: 32), to: TenantService.PRIVATE_NFT_COLLECTION_PATH)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(TenantService.PRIVATE_NFT_COLLECTION_PATH)
		self.account.capabilities.publish(capability_1, at: TenantService.PUBLIC_NFT_COLLECTION_PATH)
		
		// put the admin in storage
		self.account.storage.save<@TenantAdmin>(<-create TenantAdmin(), to: TenantService.ADMIN_OBJECT_PATH)
		emit ContractInitialized()
	}
	
	access(all)
	enum ObjectType: UInt8{ 
		access(all)
		case UNKNOWN
		
		// An Archetype is a high level organizational unit for a type of NFT. For instance, in the
		// case that the Tenant is a company dealing with professional sports they might have an Archetype
		// for each of the sports that they support, ie: Basketball, Baseball, Football, etc.
		//
		access(all)
		case ARCHETYPE
		
		// An Artifact is the actual object that is minted as an NFT. It contains all of the meta data data
		// and a reference to the Archetype that it belongs to.
		//
		access(all)
		case ARTIFACT
		
		// NFTs can be minted into a Set. A set could be something along the lines of "Greatest Pitchers",
		// "Slam Dunk Artists", or "Running Backs" (continuing with the sports theme from above). NFT do
		// not have to be minted into a set. Also, an NFT could be minted from an Artifact by itself, and
		// in another instance as part of a set - so that the NFT references the same Artifact, but only
		// one of them belongs to the Set.
		//
		access(all)
		case SET
		
		// A Print reserves a block of serial numbers for minting at a later time. It is associated with
		// a single Artifact and when the Print is minted it reserves the next serial number through however
		// many serial numbers are to be reserved. NFTs can then later be minted from the Print and will
		// be given the reserved serial numbers.
		//
		access(all)
		case PRINT
		
		// A Faucet is similar to a Print except that it doesn't reserve a block of serial numbers, it merely
		// mints NFTs from a given Artifact on demand. A Faucet can have a maxMintCount or be unbound and
		// mint infinitely (or however many NFTs are allowed to be minted for the Artifact that it is bound to).
		//
		access(all)
		case FAUCET
		
		// An NFT holds metadata, a reference to it's Artifact (and therefore Archetype), a reference to
		// it's Set (if it belongs to one), a reference to it's Print (if it was minted by one), a reference
		// to it's Faucet (if it was minted by one) and has a unique serial number.
		access(all)
		case NFT
	}
	
	access(all)
	let OBJECT_TYPE_MASK: UInt64
	
	access(all)
	let SEQUENCE_MASK: UInt64
	
	// Generates an ID for the given object type and sequence. We generate IDs this way
	// so that they are unique across the various types of objects supported by this
	// contract.
	//
	access(all)
	fun generateId(_ objectType: ObjectType, _ sequence: UInt64): UInt64{ 
		if sequence > 36028797018963967{ 
			panic("sequence may only have 55 bits and must be less than 36028797018963967")
		}
		var ret: UInt64 = UInt64(objectType.rawValue)
		ret = ret << UInt64(55)
		ret = ret | sequence << UInt64(9) >> UInt64(9)
		return ret
	}
	
	// Extracts the ObjectType from an id
	//
	access(all)
	view fun getObjectType(_ id: UInt64): ObjectType{ 
		return ObjectType(rawValue: UInt8(id >> UInt64(55)))!
	}
	
	// Extracts the sequence from an id
	//
	access(all)
	fun getSequence(_ id: UInt64): UInt64{ 
		return id & TenantService.SEQUENCE_MASK
	}
	
	// Indicates whether or not the given id is for a given ObjectType.
	//
	access(all)
	view fun isObjectType(_ id: UInt64, _ objectType: ObjectType): Bool{ 
		return TenantService.getObjectType(id) == objectType
	}
	
	// Returns the tenant id that was supplied when the contract was created
	//
	access(all)
	fun getTenantId(): String{ 
		return self.id
	}
	
	// Returns the version of this contract
	//
	access(all)
	fun getVersion(): UInt32{ 
		return 2
	}
	
	// TenantAdmin is used for administering the Tenant
	//
	access(all)
	resource TenantAdmin{ 
		
		// Closes the Tenant, rendering any write access impossible
		//
		access(all)
		fun close(){ 
			if !TenantService.closed{ 
				TenantService.closed = true
				emit TenantClosed()
			}
		}
		
		// Creates a new Archetype returning it's id.
		//
		access(all)
		fun createArchetype(name: String, description: String, metadata:{ String: TenantService.MetadataField}): UInt64{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
			}
			var archetype = Archetype(name: name, description: description, metadata: metadata)
			TenantService.archetypes[archetype.id] = archetype
			TenantService.archetypeAdmins[archetype.id] <-! create ArchetypeAdmin(archetype.id)
			return archetype.id
		}
		
		// Grants admin access to the given Archetype
		//
		access(all)
		view fun borrowArchetypeAdmin(_ id: UInt64): &ArchetypeAdmin?{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.archetypeAdmins[id] != nil:
					"Archetype not found"
				TenantService.isObjectType(id, ObjectType.ARCHETYPE):
					"ObjectType is not an Archetype"
			}
			return &TenantService.archetypeAdmins[id] as &ArchetypeAdmin?
		}
		
		// Creates a new Artifact returning it's id.
		//
		access(all)
		fun createArtifact(archetypeId: UInt64, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}): UInt64{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.archetypes[archetypeId] != nil:
					"The Archetype wasn't found"
				self.borrowArchetypeAdmin(archetypeId)?.closed != true:
					"The Archetype is closed"
			}
			var artifact = Artifact(archetypeId: archetypeId, name: name, description: description, maxMintCount: maxMintCount, metadata: metadata)
			TenantService.artifacts[artifact.id] = artifact
			TenantService.artifactAdmins[artifact.id] <-! create ArtifactAdmin(id: artifact.id)
			TenantService.nextNftSerialNumber[artifact.id] = 1
			return artifact.id
		}
		
		// Grants admin access to the given Artifact
		//
		access(all)
		view fun borrowArtifactAdmin(_ id: UInt64): &ArtifactAdmin?{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.artifactAdmins[id] != nil:
					"Artifact not found"
				TenantService.isObjectType(id, ObjectType.ARTIFACT):
					"ObjectType is not an Artifact"
			}
			return &TenantService.artifactAdmins[id] as &ArtifactAdmin?
		}
		
		// Creates a new Set returning it's id.
		//
		access(all)
		fun createSet(name: String, description: String, metadata:{ String: TenantService.MetadataField}): UInt64{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
			}
			var set = Set(name: name, description: description, metadata: metadata)
			TenantService.sets[set.id] = set
			TenantService.setAdmins[set.id] <-! create SetAdmin(set.id)
			return set.id
		}
		
		// Grants admin access to the given Set
		//
		access(all)
		view fun borrowSetAdmin(_ id: UInt64): &SetAdmin?{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.setAdmins[id] != nil:
					"Set not found"
				TenantService.isObjectType(id, ObjectType.SET):
					"ObjectType is not a Set"
			}
			return &TenantService.setAdmins[id] as &SetAdmin?
		}
		
		// Creates a new Print returning it's id.
		//
		access(all)
		fun createPrint(artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}): UInt64{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.borrowArtifactAdmin(artifactId)?.closed != true:
					"The Artifact is closed"
				setId == nil || self.borrowSetAdmin(setId!)?.closed != true:
					"The Set is closed"
			}
			var print = Print(artifactId: artifactId, setId: setId, name: name, description: description, maxMintCount: maxMintCount, metadata: metadata)
			TenantService.prints[print.id] = print
			TenantService.printAdmins[print.id] <-! create PrintAdmin(print.id, print.serialNumberStart)
			return print.id
		}
		
		// Grants admin access to the given Print
		//
		access(all)
		view fun borrowPrintAdmin(_ id: UInt64): &PrintAdmin?{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.printAdmins[id] != nil:
					"Print not found"
				TenantService.isObjectType(id, ObjectType.PRINT):
					"ObjectType is not a print"
			}
			return &TenantService.printAdmins[id] as &PrintAdmin?
		}
		
		// Creates a new Faucet returning it's id.
		//
		access(all)
		fun createFaucet(artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}): UInt64{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.borrowArtifactAdmin(artifactId)?.closed != true:
					"The Artifact is closed"
				setId == nil || self.borrowSetAdmin(setId!)?.closed != true:
					"The Set is closed"
			}
			var faucet = Faucet(artifactId: artifactId, setId: setId, name: name, description: description, maxMintCount: maxMintCount, metadata: metadata)
			TenantService.faucets[faucet.id] = faucet
			TenantService.faucetAdmins[faucet.id] <-! create FaucetAdmin(id: faucet.id)
			return faucet.id
		}
		
		// Grants admin access to the given Faucet
		//
		access(all)
		view fun borrowFaucetAdmin(_ id: UInt64): &FaucetAdmin?{ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				TenantService.faucetAdmins[id] != nil:
					"Faucet not found"
				TenantService.isObjectType(id, ObjectType.FAUCET):
					"ObjectType is not a faucet"
			}
			return &TenantService.faucetAdmins[id] as &FaucetAdmin?
		}
		
		// Mints an NFT
		//
		access(all)
		fun mintNFT(artifactId: UInt64, printId: UInt64?, faucetId: UInt64?, setId: UInt64?, metadata:{ String: TenantService.MetadataField}): @NFT{ 
			pre{ 
				TenantService.artifacts[artifactId] != nil:
					"Cannot mint the NFT: The Artifact wasn't found"
				self.borrowArtifactAdmin(artifactId)?.closed != true:
					"The Artifact is closed"
				printId == nil || TenantService.isObjectType(printId!, ObjectType.PRINT):
					"Id supplied for printId is not an ObjectType of print"
				faucetId == nil || TenantService.isObjectType(faucetId!, ObjectType.FAUCET):
					"Id supplied for faucetId is not an ObjectType of faucet"
				setId == nil || TenantService.isObjectType(setId!, ObjectType.SET):
					"Id supplied for setId is not an ObjectType of set"
				printId == nil || TenantService.prints[printId!] != nil:
					"Cannot mint the NFT: The Print wasn't found"
				faucetId == nil || TenantService.faucets[faucetId!] != nil:
					"Cannot mint the NFT: The Faucet wasn't found"
				setId == nil || TenantService.sets[setId!] != nil:
					"Cannot mint the NFT: The Set wasn't found"
				printId == nil || self.borrowPrintAdmin(printId!)?.closed != true:
					"The Print is closed"
				faucetId == nil || self.borrowFaucetAdmin(faucetId!)?.closed != true:
					"The Faucet is closed"
				setId == nil || self.borrowSetAdmin(setId!)?.closed != true:
					"The Set is closed"
				faucetId == nil || (TenantService.faucets[faucetId!]!).artifactId == artifactId:
					"The artifactId doesn't match the Faucet's artifactId"
				printId == nil || (TenantService.prints[printId!]!).artifactId == artifactId:
					"The artifactId doesn't match the Print's artifactId"
				faucetId == nil || (TenantService.faucets[faucetId!]!).setId == setId:
					"The setId doesn't match the Faucet's setId"
				printId == nil || (TenantService.prints[printId!]!).setId == setId:
					"The setId doesn't match the Print's setId"
				!(faucetId != nil && printId != nil):
					"Can only mint from one of a faucet or print"
			}
			let artifact: Artifact = TenantService.artifacts[artifactId]!
			let artifactAdmin = self.borrowArtifactAdmin(artifactId)!
			artifactAdmin.logMint(1)
			if printId != nil{ 
				artifactAdmin.logPrint(1)
			}
			let archetype: Archetype = TenantService.archetypes[artifact.archetypeId]!
			let archetypeAdmin = self.borrowArchetypeAdmin(artifact.archetypeId)!
			if archetypeAdmin != nil{ 
				archetypeAdmin.logMint(1)
				if printId != nil{ 
					archetypeAdmin.logPrint(1)
				}
			}
			if faucetId != nil{ 
				let faucetAdmin = self.borrowFaucetAdmin(faucetId!)!
				faucetAdmin.logMint(1)
			}
			if setId != nil{ 
				let setAdmin = self.borrowSetAdmin(setId!)!
				setAdmin.logMint(1)
				if printId != nil{ 
					setAdmin.logPrint(1)
				}
			}
			if printId != nil{ 
				let printAdmin = self.borrowPrintAdmin(printId!)!
				printAdmin.logMint(1)
			}
			let newNFT: @NFT <- create NFT(archetypeId: artifact.archetypeId, artifactId: artifact.id, printId: printId, faucetId: faucetId, setId: setId, metadata: metadata)
			return <-newNFT
		}
		
		// Mints many NFTs
		//
		access(all)
		fun batchMintNFTs(count: UInt64, artifactId: UInt64, printId: UInt64?, faucetId: UInt64?, setId: UInt64?, metadata:{ String: TenantService.MetadataField}): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < count{ 
				newCollection.deposit(token: <-self.mintNFT(artifactId: artifactId, printId: printId, faucetId: faucetId, setId: setId, metadata: metadata))
				i = i + 1 as UInt64
			}
			return <-newCollection
		}
		
		// Creates a new TenantAdmin that allows for another account
		// to administer the Tenant
		//
		access(all)
		fun createNewTenantAdmin(): @TenantAdmin{ 
			return <-create TenantAdmin()
		}
	}
	
	// =====================================
	// Archetype
	// =====================================
	access(all)
	event ArchetypeCreated(_ id: UInt64)
	
	access(all)
	event ArchetypeDestroyed(_ id: UInt64)
	
	access(all)
	event ArchetypeClosed(_ id: UInt64)
	
	access(all)
	fun getArchetype(_ id: UInt64): Archetype?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.ARCHETYPE):
				"Id supplied is not for an archetype"
		}
		return TenantService.archetypes[id]
	}
	
	access(all)
	fun getArchetypeView(_ id: UInt64): ArchetypeView?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.ARCHETYPE):
				"Id supplied is not for an archetype"
		}
		if TenantService.archetypes[id] == nil{ 
			return nil
		}
		let archetype = TenantService.archetypes[id]!
		let archetypeAdmin = (&TenantService.archetypeAdmins[id] as &ArchetypeAdmin?)!
		return ArchetypeView(id: archetype.id, name: archetype.name, description: archetype.description, metadata: archetype.metadata, mintCount: archetypeAdmin.mintCount, printCount: archetypeAdmin.printCount, closed: archetypeAdmin.closed)
	}
	
	access(all)
	fun getArchetypeViews(_ archetypes: [UInt64]): [ArchetypeView]{ 
		let ret: [ArchetypeView] = []
		for archetype in archetypes{ 
			let element = self.getArchetypeView(archetype)
			if element != nil{ 
				ret.append(element!)
			}
		}
		return ret
	}
	
	access(all)
	fun getAllArchetypes(): [Archetype]{ 
		return TenantService.archetypes.values
	}
	
	// The immutable data for an Archetype
	//
	access(all)
	struct Archetype{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		init(name: String, description: String, metadata:{ String: TenantService.MetadataField}){ 
			self.id = TenantService.generateId(ObjectType.ARCHETYPE, TenantService.archetypeSeq)
			self.name = name
			self.description = description
			self.metadata = metadata
			TenantService.archetypeSeq = TenantService.archetypeSeq + 1 as UInt64
			emit ArchetypeCreated(self.id)
		}
	}
	
	// The mutable data for an Archetype
	//
	access(all)
	resource ArchetypeAdmin{ 
		access(all)
		let id: UInt64
		
		access(all)
		var mintCount: UInt64
		
		access(all)
		var printCount: UInt64
		
		access(all)
		var closed: Bool
		
		init(_ id: UInt64){ 
			self.id = id
			self.mintCount = 0
			self.printCount = 0
			self.closed = false
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				emit ArchetypeClosed(self.id)
			}
		}
		
		access(all)
		fun logMint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Archetype is closed"
			}
			self.mintCount = self.mintCount + count
		}
		
		access(all)
		fun logPrint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Archetype is closed"
			}
			self.printCount = self.printCount + count
		}
	}
	
	// An immutable view for an Archetype and all of it's data
	//
	access(all)
	struct ArchetypeView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let mintCount: UInt64
		
		access(all)
		let printCount: UInt64
		
		access(all)
		let closed: Bool
		
		init(id: UInt64, name: String, description: String, metadata:{ String: TenantService.MetadataField}, mintCount: UInt64, printCount: UInt64, closed: Bool){ 
			self.id = id
			self.name = name
			self.description = description
			self.metadata = metadata
			self.mintCount = mintCount
			self.printCount = printCount
			self.closed = closed
		}
	}
	
	// =====================================
	// Artifact
	// =====================================
	access(all)
	event ArtifactCreated(_ id: UInt64)
	
	access(all)
	event ArtifactMaxMintCountChanged(_ id: UInt64, _ oldMaxMintCount: UInt64, _ newMaxMintCount: UInt64)
	
	access(all)
	event ArtifactDestroyed(_ id: UInt64)
	
	access(all)
	event ArtifactClosed(_ id: UInt64)
	
	access(all)
	fun getArtifact(_ id: UInt64): Artifact?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.ARTIFACT):
				"Id supplied is not for an artifact"
		}
		return TenantService.artifacts[id]
	}
	
	access(all)
	fun getArtifactView(_ id: UInt64): ArtifactView?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.ARTIFACT):
				"Id supplied is not for an artifact"
		}
		if TenantService.artifacts[id] == nil{ 
			return nil
		}
		let artifact = TenantService.artifacts[id]!
		let artifactAdmin = (&TenantService.artifactAdmins[id] as &ArtifactAdmin?)!
		return ArtifactView(id: artifact.id, archetypeId: artifact.archetypeId, name: artifact.name, description: artifact.description, metadata: artifact.metadata, maxMintCount: artifact.maxMintCount, mintCount: artifactAdmin.mintCount, printCount: artifactAdmin.printCount, closed: artifactAdmin.closed)
	}
	
	access(all)
	fun getArtifactViews(_ artifacts: [UInt64]): [ArtifactView]{ 
		let ret: [ArtifactView] = []
		for artifact in artifacts{ 
			let element = self.getArtifactView(artifact)
			if element != nil{ 
				ret.append(element!)
			}
		}
		return ret
	}
	
	access(all)
	fun getAllArtifacts(): [Artifact]{ 
		return TenantService.artifacts.values
	}
	
	access(all)
	fun getArtifactsBySet(_ setId: UInt64): [UInt64]{ 
		let map = TenantService.artifactsBySet[setId]
		if map != nil{ 
			return (map!).keys
		}
		return []
	}
	
	access(all)
	fun getFaucetsBySet(_ setId: UInt64): [UInt64]{ 
		let map = TenantService.faucetsBySet[setId]
		if map != nil{ 
			return (map!).keys
		}
		return []
	}
	
	access(all)
	fun getSetsByArtifact(_ artifactId: UInt64): [UInt64]{ 
		let map = TenantService.setsByArtifact[artifactId]
		if map != nil{ 
			return (map!).keys
		}
		return []
	}
	
	access(all)
	fun getFaucetsByArtifact(_ artifactId: UInt64): [UInt64]{ 
		let map = TenantService.faucetsByArtifact[artifactId]
		if map != nil{ 
			return (map!).keys
		}
		return []
	}
	
	access(all)
	fun getArtifactsByArchetype(_ archetypeId: UInt64): [UInt64]{ 
		let map = TenantService.artifactsByArchetype[archetypeId]
		if map != nil{ 
			return (map!).keys
		}
		return []
	}
	
	// The immutable data for an Artifact
	//
	access(all)
	struct Artifact{ 
		access(all)
		let id: UInt64
		
		access(all)
		let archetypeId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		init(archetypeId: UInt64, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}){ 
			self.id = TenantService.generateId(ObjectType.ARTIFACT, TenantService.artifactSeq)
			self.archetypeId = archetypeId
			self.name = name
			self.description = description
			self.maxMintCount = maxMintCount
			self.metadata = metadata
			TenantService.artifactSeq = TenantService.artifactSeq + 1 as UInt64
			emit ArtifactCreated(self.id)
		}
	}
	
	// The mutable data for an Artifact
	//
	access(all)
	resource ArtifactAdmin{ 
		access(all)
		let id: UInt64
		
		access(all)
		var mintCount: UInt64
		
		access(all)
		var printCount: UInt64
		
		access(all)
		var closed: Bool
		
		init(id: UInt64){ 
			self.id = id
			self.mintCount = 0
			self.printCount = 0
			self.closed = false
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				emit ArtifactClosed(self.id)
			}
		}
		
		access(all)
		fun logMint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Artifact is closed"
				(TenantService.artifacts[self.id]!).maxMintCount == 0 as UInt64 || (TenantService.artifacts[self.id]!).maxMintCount >= self.mintCount + count:
					"The Artifact would exceed it's maxMintCount"
			}
			self.mintCount = self.mintCount + count
		}
		
		access(all)
		fun logPrint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Artifact is closed"
			}
			self.printCount = self.printCount + count
		}
	}
	
	// An immutable view for an Artifact and all of it's data
	//
	access(all)
	struct ArtifactView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let archetypeId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let mintCount: UInt64
		
		access(all)
		let printCount: UInt64
		
		access(all)
		let closed: Bool
		
		init(id: UInt64, archetypeId: UInt64, name: String, description: String, metadata:{ String: TenantService.MetadataField}, maxMintCount: UInt64, mintCount: UInt64, printCount: UInt64, closed: Bool){ 
			self.id = id
			self.archetypeId = archetypeId
			self.name = name
			self.description = description
			self.metadata = metadata
			self.maxMintCount = maxMintCount
			self.mintCount = mintCount
			self.printCount = printCount
			self.closed = closed
		}
	}
	
	// =====================================
	// Set
	// =====================================
	access(all)
	event SetCreated(_ id: UInt64)
	
	access(all)
	event SetDestroyed(_ id: UInt64)
	
	access(all)
	event SetClosed(_ id: UInt64)
	
	access(all)
	fun getSet(_ id: UInt64): Set?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.SET):
				"Id supplied is not for an set"
		}
		return TenantService.sets[id]
	}
	
	access(all)
	fun getSetView(_ id: UInt64): SetView?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.SET):
				"Id supplied is not for an set"
		}
		if TenantService.sets[id] == nil{ 
			return nil
		}
		let set = TenantService.sets[id]!
		let setAdmin = (&TenantService.setAdmins[id] as &SetAdmin?)!
		return SetView(id: set.id, name: set.name, description: set.description, metadata: set.metadata, mintCount: setAdmin.mintCount, printCount: setAdmin.printCount, closed: setAdmin.closed)
	}
	
	access(all)
	fun getSetViews(_ sets: [UInt64]): [SetView]{ 
		let ret: [SetView] = []
		for set in sets{ 
			let element = self.getSetView(set)
			if element != nil{ 
				ret.append(element!)
			}
		}
		return ret
	}
	
	access(all)
	fun getAllSets(): [Set]{ 
		return TenantService.sets.values
	}
	
	// The immutable data for an Set
	//
	access(all)
	struct Set{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		init(name: String, description: String, metadata:{ String: TenantService.MetadataField}){ 
			self.id = TenantService.generateId(ObjectType.SET, TenantService.setSeq)
			self.name = name
			self.description = description
			self.metadata = metadata
			TenantService.setSeq = TenantService.setSeq + 1 as UInt64
			TenantService.faucetsBySet[self.id] ={} 
			emit SetCreated(self.id)
		}
	}
	
	// The mutable data for an Set
	//
	access(all)
	resource SetAdmin{ 
		access(all)
		let id: UInt64
		
		access(all)
		var mintCount: UInt64
		
		access(all)
		var printCount: UInt64
		
		access(all)
		var closed: Bool
		
		init(_ id: UInt64){ 
			self.id = id
			self.mintCount = 0
			self.printCount = 0
			self.closed = false
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				emit SetClosed(self.id)
			}
		}
		
		access(all)
		fun logMint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Set is closed"
			}
			self.mintCount = self.mintCount + count
		}
		
		access(all)
		fun logPrint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Set is closed"
			}
			self.printCount = self.printCount + count
		}
	}
	
	// An immutable view for an Set and all of it's data
	//
	access(all)
	struct SetView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let mintCount: UInt64
		
		access(all)
		let printCount: UInt64
		
		access(all)
		let closed: Bool
		
		init(id: UInt64, name: String, description: String, metadata:{ String: TenantService.MetadataField}, mintCount: UInt64, printCount: UInt64, closed: Bool){ 
			self.id = id
			self.name = name
			self.description = description
			self.metadata = metadata
			self.mintCount = mintCount
			self.printCount = printCount
			self.closed = closed
		}
	}
	
	// =====================================
	// Print
	// =====================================
	access(all)
	event PrintCreated(_ id: UInt64)
	
	access(all)
	event PrintDestroyed(_ id: UInt64)
	
	access(all)
	event PrintClosed(_ id: UInt64)
	
	access(all)
	fun getPrint(_ id: UInt64): Print?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.PRINT):
				"Id supplied is not for a print"
		}
		return TenantService.prints[id]
	}
	
	access(all)
	fun getPrintView(_ id: UInt64): PrintView?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.PRINT):
				"Id supplied is not for a print"
		}
		if TenantService.prints[id] == nil{ 
			return nil
		}
		let print = TenantService.prints[id]!
		let printAdmin = (&TenantService.printAdmins[id] as &PrintAdmin?)!
		return PrintView(id: print.id, artifactId: print.artifactId, setId: print.setId, name: print.name, description: print.description, maxMintCount: print.maxMintCount, metadata: print.metadata, serialNumberStart: print.serialNumberStart, nextNftSerialNumber: printAdmin.nextNftSerialNumber, mintCount: printAdmin.mintCount, closed: printAdmin.closed)
	}
	
	access(all)
	fun getPrintViews(_ prints: [UInt64]): [PrintView]{ 
		let ret: [PrintView] = []
		for print in prints{ 
			let element = self.getPrintView(print)
			if element != nil{ 
				ret.append(element!)
			}
		}
		return ret
	}
	
	access(all)
	fun getAllPrints(): [Print]{ 
		return TenantService.prints.values
	}
	
	// The immutable data for an Print
	//
	access(all)
	struct Print{ 
		access(all)
		let id: UInt64
		
		access(all)
		let artifactId: UInt64
		
		access(all)
		let setId: UInt64?
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let serialNumberStart: UInt64
		
		init(artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}){ 
			pre{ 
				maxMintCount > 0:
					"maxMintCount must be greater than 0"
			}
			self.id = TenantService.generateId(ObjectType.PRINT, TenantService.printSeq)
			self.artifactId = artifactId
			self.setId = setId
			self.name = name
			self.description = description
			self.maxMintCount = maxMintCount
			self.metadata = metadata
			self.serialNumberStart = TenantService.nextNftSerialNumber[artifactId]!
			TenantService.nextNftSerialNumber[artifactId] = self.serialNumberStart + maxMintCount
			TenantService.printSeq = TenantService.printSeq + 1 as UInt64
			emit PrintCreated(self.id)
		}
	}
	
	// The mutable data for an Print
	//
	access(all)
	resource PrintAdmin{ 
		access(all)
		let id: UInt64
		
		access(all)
		var nextNftSerialNumber: UInt64
		
		access(all)
		var mintCount: UInt64
		
		access(all)
		var closed: Bool
		
		init(_ id: UInt64, _ serialNumberStart: UInt64){ 
			self.id = id
			self.mintCount = 0
			self.closed = false
			self.nextNftSerialNumber = serialNumberStart
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				emit PrintClosed(self.id)
			}
		}
		
		access(all)
		fun getAndIncrementSerialNumber(): UInt64{ 
			let ret: UInt64 = self.nextNftSerialNumber
			self.nextNftSerialNumber = ret + 1 as UInt64
			return ret
		}
		
		access(all)
		fun logMint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Print is closed"
				(TenantService.prints[self.id]!).maxMintCount >= self.mintCount + count:
					"The Print would exceed it's maxMintCount"
			}
			self.mintCount = self.mintCount + count
		}
	}
	
	// An immutable view for an Print and all of it's data
	//
	access(all)
	struct PrintView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let artifactId: UInt64
		
		access(all)
		let setId: UInt64?
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let serialNumberStart: UInt64
		
		access(all)
		let nextNftSerialNumber: UInt64
		
		access(all)
		let mintCount: UInt64
		
		access(all)
		let closed: Bool
		
		init(id: UInt64, artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}, serialNumberStart: UInt64, nextNftSerialNumber: UInt64, mintCount: UInt64, closed: Bool){ 
			self.id = id
			self.artifactId = artifactId
			self.setId = setId
			self.name = name
			self.description = description
			self.maxMintCount = maxMintCount
			self.metadata = metadata
			self.serialNumberStart = serialNumberStart
			self.nextNftSerialNumber = nextNftSerialNumber
			self.mintCount = mintCount
			self.closed = closed
		}
	}
	
	// =====================================
	// Faucet
	// =====================================
	access(all)
	event FaucetCreated(_ id: UInt64)
	
	access(all)
	event FaucetMaxMintCountChanged(_ id: UInt64, _ oldMaxMintCount: UInt64, _ newMaxMintCount: UInt64)
	
	access(all)
	event FaucetDestroyed(_ id: UInt64)
	
	access(all)
	event FaucetClosed(_ id: UInt64)
	
	access(all)
	fun getFaucet(_ id: UInt64): Faucet?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.FAUCET):
				"Id supplied is not for a faucet"
		}
		return TenantService.faucets[id]
	}
	
	access(all)
	fun getFaucetView(_ id: UInt64): FaucetView?{ 
		pre{ 
			TenantService.isObjectType(id, ObjectType.FAUCET):
				"Id supplied is not for a faucet"
		}
		if TenantService.faucets[id] == nil{ 
			return nil
		}
		let faucet = TenantService.faucets[id]!
		let faucetAdmin = (&TenantService.faucetAdmins[id] as &FaucetAdmin?)!
		return FaucetView(id: faucet.id, artifactId: faucet.artifactId, setId: faucet.setId, name: faucet.name, description: faucet.description, maxMintCount: faucet.maxMintCount, metadata: faucet.metadata, mintCount: faucetAdmin.mintCount, closed: faucetAdmin.closed)
	}
	
	access(all)
	fun getFaucetViews(_ faucets: [UInt64]): [FaucetView]{ 
		let ret: [FaucetView] = []
		for faucet in faucets{ 
			let element = self.getFaucetView(faucet)
			if element != nil{ 
				ret.append(element!)
			}
		}
		return ret
	}
	
	access(all)
	fun getAllFaucets(): [Faucet]{ 
		return TenantService.faucets.values
	}
	
	// The immutable data for an Faucet
	//
	access(all)
	struct Faucet{ 
		access(all)
		let id: UInt64
		
		access(all)
		let artifactId: UInt64
		
		access(all)
		let setId: UInt64?
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		init(artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}){ 
			self.id = TenantService.generateId(ObjectType.FAUCET, TenantService.faucetSeq)
			self.artifactId = artifactId
			self.setId = setId
			self.name = name
			self.description = description
			self.maxMintCount = maxMintCount
			self.metadata = metadata
			TenantService.faucetSeq = TenantService.faucetSeq + 1 as UInt64
			if self.setId != nil{ 
				let faucetsBySet = TenantService.faucetsBySet[self.setId!]!
				faucetsBySet[self.id] = true
			}
			emit FaucetCreated(self.id)
		}
	}
	
	// The mutable data for an Faucet
	//
	access(all)
	resource FaucetAdmin{ 
		access(all)
		let id: UInt64
		
		access(all)
		var mintCount: UInt64
		
		access(all)
		var closed: Bool
		
		init(id: UInt64){ 
			self.id = id
			self.mintCount = 0
			self.closed = false
		}
		
		access(all)
		fun close(){ 
			if !self.closed{ 
				self.closed = true
				emit FaucetClosed(self.id)
			}
		}
		
		access(all)
		fun logMint(_ count: UInt64){ 
			pre{ 
				TenantService.closed != true:
					"The Tenant is closed"
				self.closed != true:
					"The Faucet is closed"
				(TenantService.faucets[self.id]!).maxMintCount == 0 as UInt64 || (TenantService.faucets[self.id]!).maxMintCount >= self.mintCount + count:
					"The Faucet would exceed it's maxMintCount"
			}
			self.mintCount = self.mintCount + count
		}
	}
	
	// An immutable view for an Faucet and all of it's data
	//
	access(all)
	struct FaucetView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let artifactId: UInt64
		
		access(all)
		let setId: UInt64?
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let maxMintCount: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		let mintCount: UInt64
		
		access(all)
		let closed: Bool
		
		init(id: UInt64, artifactId: UInt64, setId: UInt64?, name: String, description: String, maxMintCount: UInt64, metadata:{ String: TenantService.MetadataField}, mintCount: UInt64, closed: Bool){ 
			self.id = id
			self.artifactId = artifactId
			self.setId = setId
			self.name = name
			self.description = description
			self.maxMintCount = maxMintCount
			self.metadata = metadata
			self.mintCount = mintCount
			self.closed = closed
		}
	}
	
	// =====================================
	// NFT
	// =====================================
	access(all)
	event NFTCreated(_ id: UInt64)
	
	access(all)
	event NFTDestroyed(_ id: UInt64)
	
	access(all)
	fun getNFTView(_ nft: &NFT): NFTView{ 
		let archetype = self.getArchetypeView(nft.archetypeId)!
		let artifact = self.getArtifactView(nft.artifactId)!
		var set: SetView? = nil
		if nft.setId != nil{ 
			set = self.getSetView(nft.setId!)!
		}
		var print: PrintView? = nil
		if nft.printId != nil{ 
			print = self.getPrintView(nft.printId!)!
		}
		var faucet: FaucetView? = nil
		if nft.faucetId != nil{ 
			faucet = self.getFaucetView(nft.faucetId!)!
		}
		return NFTView(id: nft.id, archetype: archetype, artifact: artifact, print: print, faucet: faucet, set: set, serialNumber: nft.serialNumber, metadata: nft.getMetadata())
	}
	
	access(all)
	fun getNFTViews(_ nfts: [&NFT]): [NFTView]{ 
		let ret: [NFTView] = []
		for nft in nfts{ 
			ret.append(self.getNFTView(nft))
		}
		return ret
	}
	
	// The immutable data for an NFT, this is the actual NFT
	//
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let archetypeId: UInt64
		
		access(all)
		let artifactId: UInt64
		
		access(all)
		let printId: UInt64?
		
		access(all)
		let faucetId: UInt64?
		
		access(all)
		let setId: UInt64?
		
		access(all)
		let serialNumber: UInt64
		
		access(self)
		let metadata:{ String: TenantService.MetadataField}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(archetypeId: UInt64, artifactId: UInt64, printId: UInt64?, faucetId: UInt64?, setId: UInt64?, metadata:{ String: TenantService.MetadataField}){ 
			self.id = TenantService.generateId(ObjectType.NFT, TenantService.totalSupply)
			self.archetypeId = archetypeId
			self.artifactId = artifactId
			self.printId = printId
			self.faucetId = faucetId
			self.setId = setId
			self.metadata = metadata
			if self.printId != nil{ 
				let printAdmin = (&TenantService.printAdmins[self.printId!!] as &PrintAdmin?)!
				self.serialNumber = printAdmin.getAndIncrementSerialNumber()
			} else{ 
				self.serialNumber = TenantService.nextNftSerialNumber[self.artifactId]!
				TenantService.nextNftSerialNumber[self.artifactId] = self.serialNumber + 1 as UInt64
			}
			TenantService.totalSupply = TenantService.totalSupply + 1 as UInt64
			if self.setId != nil{ 
				if TenantService.setsByArtifact[self.artifactId] == nil{ 
					TenantService.setsByArtifact[self.artifactId] ={} 
				}
				let setsByArtifact = TenantService.setsByArtifact[self.artifactId]!
				setsByArtifact[self.setId!] = true
				if TenantService.artifactsBySet[self.setId!] == nil{ 
					TenantService.artifactsBySet[self.setId!] ={} 
				}
				let artifactsBySet = TenantService.artifactsBySet[self.setId!]!
				artifactsBySet[self.artifactId] = true
			}
			if self.faucetId != nil{ 
				if TenantService.faucetsByArtifact[self.artifactId] == nil{ 
					TenantService.faucetsByArtifact[self.artifactId] ={} 
				}
				let faucetsByArtifact = TenantService.faucetsByArtifact[self.artifactId]!
				faucetsByArtifact[self.faucetId!] = true
			}
			if TenantService.artifactsByArchetype[self.archetypeId] == nil{ 
				TenantService.artifactsByArchetype[self.archetypeId] ={} 
			}
			let artifactsByArchetype = TenantService.artifactsByArchetype[self.archetypeId]!
			artifactsByArchetype[self.artifactId] = true
			emit NFTCreated(self.id)
		}
		
		access(all)
		fun getMetadata():{ String: TenantService.MetadataField}{ 
			return self.metadata
		}
	}
	
	// An immutable view for an NFT and all of it's data
	//
	access(all)
	struct NFTView{ 
		access(all)
		let id: UInt64
		
		access(all)
		let archetype: ArchetypeView
		
		access(all)
		let artifact: ArtifactView
		
		access(all)
		let print: PrintView?
		
		access(all)
		let faucet: FaucetView?
		
		access(all)
		let set: SetView?
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let metadata:{ String: TenantService.MetadataField}
		
		init(id: UInt64, archetype: ArchetypeView, artifact: ArtifactView, print: PrintView?, faucet: FaucetView?, set: SetView?, serialNumber: UInt64, metadata:{ String: TenantService.MetadataField}){ 
			self.id = id
			self.archetype = archetype
			self.artifact = artifact
			self.print = print
			self.faucet = faucet
			self.set = set
			self.serialNumber = serialNumber
			self.metadata = metadata
		}
	}
	
	// The public version of the collection that accounts can use
	// to deposit NFTs into other accounts
	//
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowNFTData(id: UInt64): &TenantService.NFT?
		
		access(all)
		fun borrowNFTDatas(ids: [UInt64]): [&TenantService.NFT]
	}
	
	// The collection where NFTs are stored
	//
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @TenantService.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				TenantService.isObjectType(id, ObjectType.NFT):
					"Id supplied is not for an nft"
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowNFTData(id: UInt64): &TenantService.NFT?{ 
			pre{ 
				TenantService.isObjectType(id, ObjectType.NFT):
					"Id supplied is not for an nft"
			}
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TenantService.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		fun borrowNFTDatas(ids: [UInt64]): [&TenantService.NFT]{ 
			let nfts: [&TenantService.NFT] = []
			for id in ids{ 
				let nft = self.borrowNFTData(id: id)
				if nft != nil{ 
					nfts.append(nft!)
				}
			}
			return nfts
		}
		
		access(all)
		fun getNFTView(id: UInt64): NFTView?{ 
			pre{ 
				TenantService.isObjectType(id, ObjectType.NFT):
					"Id supplied is not for an nft"
			}
			let nft = self.borrowNFTData(id: id)
			if nft == nil{ 
				return nil
			}
			return TenantService.getNFTView(nft!)
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
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create TenantService.Collection()
	}
	
	// ShardedCollection stores a dictionary of TenantService Collections
	// An NFT is stored in the field that corresponds to its id % numBuckets
	//
	access(all)
	resource ShardedCollection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		access(all)
		var collections: @{UInt64: Collection}
		
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! TenantService.createEmptyCollection(nftType: Type<@TenantService.Collection>()) as! @Collection
				i = i + UInt64(1)
			}
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			let bucket = withdrawID % self.numBuckets
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- TenantService.createEmptyCollection(nftType: Type<@TenantService.Collection>())
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let bucket = token.id % self.numBuckets
			let collection <- self.collections.remove(key: bucket)!
			collection.deposit(token: <-token)
			self.collections[bucket] <-! collection
		}
		
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			var ids: [UInt64] = []
			for key in self.collections.keys{ 
				for id in self.collections[key]?.getIDs() ?? []{ 
					ids.append(id)
				}
			}
			return ids
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowNFT(id)!!
		}
		
		access(all)
		fun borrowNFTData(id: UInt64): &TenantService.NFT?{ 
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowNFTData(id: id) ?? nil
		}
		
		access(all)
		fun borrowNFTDatas(ids: [UInt64]): [&TenantService.NFT]{ 
			let nfts: [&TenantService.NFT] = []
			for id in ids{ 
				let nft = self.borrowNFTData(id: id)
				if nft != nil{ 
					nfts.append(nft!)
				}
			}
			return nfts
		}
		
		access(all)
		fun getNFTView(id: UInt64): NFTView?{ 
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.getNFTView(id: id) ?? nil
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	access(all)
	fun createEmptyShardedCollection(numBuckets: UInt64): @ShardedCollection{ 
		return <-create ShardedCollection(numBuckets: numBuckets)
	}
	
	// =====================================
	// Metadata
	// =====================================
	// The type of a meta data field
	//
	access(all)
	enum MetadataFieldType: UInt8{ 
		access(all)
		case STRING
		
		access(all)
		case MIME
		
		access(all)
		case NUMBER
		
		access(all)
		case BOOLEAN
		
		access(all)
		case DATE
		
		access(all)
		case DATE_TIME
		
		access(all)
		case URL
		
		access(all)
		case URL_WITH_HASH
		
		access(all)
		case GEO_POINT
	}
	
	// a meta data field of variable type
	//
	access(all)
	struct MetadataField{ 
		access(all)
		let type: MetadataFieldType
		
		access(all)
		let value: AnyStruct
		
		init(_ type: MetadataFieldType, _ value: AnyStruct){ 
			self.type = type
			self.value = value
		}
		
		access(all)
		fun getMimeValue(): Mime?{ 
			if self.type != MetadataFieldType.MIME{ 
				return nil
			}
			return self.value as? Mime
		}
		
		access(all)
		fun getStringValue(): String?{ 
			if self.type != MetadataFieldType.STRING{ 
				return nil
			}
			return self.value as? String
		}
		
		access(all)
		fun getNumberValue(): String?{ 
			if self.type != MetadataFieldType.NUMBER{ 
				return nil
			}
			return self.value as? String
		}
		
		access(all)
		fun getBooleanValue(): Bool?{ 
			if self.type != MetadataFieldType.BOOLEAN{ 
				return nil
			}
			return self.value as? Bool
		}
		
		access(all)
		fun getURLValue(): String?{ 
			if self.type != MetadataFieldType.URL{ 
				return nil
			}
			return self.value as? String
		}
		
		access(all)
		fun getDateValue(): String?{ 
			if self.type != MetadataFieldType.DATE{ 
				return nil
			}
			return self.value as? String
		}
		
		access(all)
		fun getDateTimeValue(): String?{ 
			if self.type != MetadataFieldType.DATE_TIME{ 
				return nil
			}
			return self.value as? String
		}
		
		access(all)
		fun getURLWithHashValue(): URLWithHash?{ 
			if self.type != MetadataFieldType.URL_WITH_HASH{ 
				return nil
			}
			return self.value as? URLWithHash
		}
		
		access(all)
		fun getGeoPointValue(): GeoPoint?{ 
			if self.type != MetadataFieldType.GEO_POINT{ 
				return nil
			}
			return self.value as? GeoPoint
		}
	}
	
	// A url with a hash of the contents found at the url
	//
	access(all)
	struct URLWithHash{ 
		access(all)
		let url: String
		
		access(all)
		let hash: String?
		
		access(all)
		let hashAlgo: String?
		
		init(_ url: String, _ hash: String, _ hashAlgo: String?){ 
			self.url = url
			self.hash = hash
			self.hashAlgo = hashAlgo
		}
	}
	
	// A geo point without any specific projection
	//
	access(all)
	struct GeoPoint{ 
		access(all)
		let lat: UFix64
		
		access(all)
		let lng: UFix64
		
		init(_ lat: UFix64, _ lng: UFix64){ 
			self.lat = lat
			self.lng = lng
		}
	}
	
	// A piece of Mime content
	//
	access(all)
	struct Mime{ 
		access(all)
		let type: String
		
		access(all)
		let bytes: [UInt8]
		
		init(_ type: String, _ bytes: [UInt8]){ 
			self.type = type
			self.bytes = bytes
		}
	}
}
