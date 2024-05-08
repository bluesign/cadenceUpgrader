import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

import MotoGPCounter from "./MotoGPCounter.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MotoGPCardMetadata from 0xa49cc0ee46c54bfb

access(all)
contract MotoGPCard: NonFungibleToken{ 
	access(all)
	fun getVersion(): String{ 
		return "1.0.3"
	}
	
	// The total number of Cards in existence
	access(all)
	var totalSupply: UInt64
	
	// Event that emitted when the MotoGPCard contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	// Event that is emitted when a Card is withdrawn,
	// indicating the owner of the collection that it was withdrawn from.
	//
	// If the collection is not in an account's storage, `from` will be `nil`.
	//
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event that emitted when a Card is deposited to a collection.
	//
	// It indicates the owner of the collection that it was deposited to.
	//
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	// An array UInt128s that represents cardID + serial keys
	// This is primarily used to ensure there
	// are no duplicates when we mint a new Card (NFT)
	access(account)
	var allCards: [UInt128]
	
	// NFT
	// The NFT resource defines a specific Card
	// that has an id, cardID, and serial.
	// This resource will be created every time
	// a pack opens and when we need to mint Cards.
	//
	// This NFT represents a Card. These names
	// will be used interchangeably.
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The card's Issue ID (completely sequential)
		access(all)
		let id: UInt64
		
		// The card's cardID, which will be determined
		// once the pack is opened
		access(all)
		let cardID: UInt64
		
		// The card's Serial, which will also be determined
		// once the pack is opened
		access(all)
		let serial: UInt64
		
		// initializer
		//
		init(_cardID: UInt64, _serial: UInt64){ 
			let keyValue = UInt128(_cardID) + UInt128(_serial) * 0x4000000000000000 as UInt128
			if MotoGPCard.allCards.contains(keyValue){ 
				panic("This cardID and serial combination already exists")
			}
			MotoGPCard.allCards.append(keyValue)
			self.cardID = _cardID
			self.serial = _serial
			self.id = MotoGPCounter.increment("MotoGPCard")
			MotoGPCard.totalSupply = MotoGPCard.totalSupply + 1 as UInt64
			emit Mint(id: self.id)
		}
		
		// NOTE: The method getCardMetadata(): MotoGPCardMetadata.Metadata? has been removed. 
		// Use methods getViews and resolveView instead to fetch metadata
		///////////////////////////////
		// Resolver interface methods
		/////////////////////////////// 
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Traits>(), Type<MotoGPCardMetadata.Riders>()] // custom type
		
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return MotoGPCardMetadata.resolveView(view: view, id: self.id, cardID: self.cardID, serial: self.serial,																													 // Below four arguments are passed to MotoGPCardMetadata (as opposed being hardcoded there) to avoid cyclic dependencies MotoGPCard <-> MotoGPCardMetadata
																													 publicCollectionType: Type<&MotoGPCard.Collection>(), publicLinkedType: Type<&MotoGPCard.Collection>(), providerLinkedType: Type<&MotoGPCard.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-MotoGPCard.createEmptyCollection(nftType: Type<@MotoGPCard.Collection>())
				})
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// createNFT
	// allows us to create an NFT from another contract in this
	// account because we want to be able to mint NFTs
	// in MotoGPPack
	//
	access(account)
	fun createNFT(cardID: UInt64, serial: UInt64): @NFT{ 
		return <-create NFT(_cardID: cardID, _serial: serial)
	}
	
	// ICardCollectionPublic
	// Defines an interface that specifies
	// what fields and functions 
	// we want to expose to the public.
	//
	// Allows users to deposit Cards, read all the Card IDs,
	// borrow a NFT reference to access a Card's ID,
	// deposit a batch of Cards, and borrow a Card reference
	// to access all of the Card's fields.
	//
	access(all)
	resource interface ICardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun depositBatch(cardCollection: @{NonFungibleToken.Collection})
		
		access(all)
		fun borrowCard(id: UInt64): &MotoGPCard.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Card reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection
	// This resource defines a collection of Cards
	// that a user will have. We must give each user
	// this collection so they can
	// interact with Cards.
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ICardCollectionPublic, ViewResolver.ResolverCollection{ 
		// A dictionary that maps a Card's id to a 
		// Card in the collection. It holds all the 
		// Cards in a collection.
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// deposit
		// deposits a Card into the Collection
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MotoGPCard.NFT
			let id: UInt64 = token.id
			
			// add the new Card to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			
			// Only emit a deposit event if the Collection 
			// is in an account's storage
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		// depositBatch
		// This method deposits a collection of Cards into the
		// user's Collection.
		//
		// This is primarily called by an Admin to
		// deposit newly minted Cards into this Collection.
		//
		access(all)
		fun depositBatch(cardCollection: @{NonFungibleToken.Collection}){ 
			pre{ 
				cardCollection.getIDs().length <= 100:
					"Too many cards being deposited. Must be less than or equal to 100"
			}
			
			// Get an array of the IDs to be deposited
			let keys = cardCollection.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-cardCollection.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy cardCollection
		}
		
		// withdraw
		// withdraw removes a Card from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// getIDs
		// returns the ids of all the Card this
		// collection has
		// 
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its id field
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowCard
		// borrowCard returns a borrowed reference to a Card
		// so that the caller can read data from it.
		// They can use this to read its id, cardID, and serial
		//
		access(all)
		fun borrowCard(id: UInt64): &MotoGPCard.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &MotoGPCard.NFT?
		}
		
		// ResolverCollection interface method
		//
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let cardNFT = nft as! &MotoGPCard.NFT
			return cardNFT as &{ViewResolver.Resolver}
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
	
	// createEmptyCollection
	// creates a new Collection resource and returns it.
	// This will primarily be used to give a user a new Collection
	// so they can store Cards
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.totalSupply = 0
		self.allCards = []
		emit ContractInitialized()
	}
}
