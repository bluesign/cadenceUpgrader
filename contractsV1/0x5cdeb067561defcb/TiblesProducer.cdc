// TiblesProducer.cdc
import TiblesNFT from "./TiblesNFT.cdc"

access(all)
contract interface TiblesProducer{ 
	access(all)
	let ProducerStoragePath: StoragePath
	
	access(all)
	let ProducerPath: PrivatePath
	
	access(all)
	let ContentPath: PublicPath
	
	access(all)
	let contentCapability: Capability
	
	access(all)
	event MinterCreated(minterId: String)
	
	access(all)
	event TibleMinted(minterId: String, mintNumber: UInt32, id: UInt64)
	
	// Producers must provide a ContentLocation struct so that NFTs can access metadata.
	access(all)
	struct interface ContentLocation{} 
	
	access(all)
	struct interface IContentLocation{} 
	
	// This is a public resource that lets the individual tibles get their metadata.
	// Adding content is done through the Producer.
	access(all)
	resource interface IContent{ 
		// Content is stored in the set/item/variant structures. To retrieve it, we have a contentId that maps to the path.
		access(contract)
		let contentIdsToPaths:{ String:{ TiblesProducer.ContentLocation}}
		
		access(all)
		fun getMetadata(contentId: String):{ String: AnyStruct}?
	}
	
	// Provides access to producer activities like content creation and NFT minting.
	// The resource is stored in the app account's storage with a link in /private.
	access(all)
	resource interface IProducer{ 
		// Minters create and store tibles before they are sold. One minter per set-item-variant combo.
		access(contract)
		let minters: @{String:{ TiblesProducer.Minter}}
	}
	
	access(all)
	resource interface Producer: IContent, IProducer{ 
		access(contract)
		let minters: @{String:{ TiblesProducer.Minter}}
	}
	
	// Mints new NFTs for a specific set/item/variant combination.
	access(all)
	resource interface IMinter{ 
		access(all)
		let id: String
		
		// Keeps track of the mint number for items.
		access(all)
		var lastMintNumber: UInt32
		
		// Stored with each minted NFT so that it can access metadata.
		access(all)
		let contentCapability: Capability
		
		// Used only on original purchase, when the NFT gets transferred from the producer to the user's collection.
		access(all)
		fun withdraw(mintNumber: UInt32): @{TiblesNFT.INFT}
		
		access(all)
		fun mintNext()
	}
	
	access(all)
	resource interface Minter: IMinter{ 
		access(all)
		let id: String
		
		access(all)
		var lastMintNumber: UInt32
		
		access(all)
		let contentCapability: Capability
		
		access(all)
		fun withdraw(mintNumber: UInt32): @{TiblesNFT.INFT}
		
		access(all)
		fun mintNext()
	}
}
