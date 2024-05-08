import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract TheFabricantNFTAccess{ 
	
	// -----------------------------------------------------------------------
	// TheFabricantNFTAccess contract Events
	// -----------------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let RedeemerStoragePath: StoragePath
	
	access(all)
	event EventAdded(eventName: String, types: [Type])
	
	access(all)
	event EventRedemption(
		eventName: String,
		address: Address,
		nftID: UInt64,
		nftType: Type,
		nftUuid: UInt64
	)
	
	access(all)
	event AccessListChanged(eventName: String, addresses: [Address])
	
	// eventName: {redeemerAddress: nftUuid}
	access(self)
	var event:{ String:{ Address: UInt64}}
	
	// eventName: [nftTypes]
	access(self)
	var eventToTypes:{ String: [Type]}
	
	// eventName: [addresses]
	access(self)
	var accessList:{ String: [Address]}
	
	access(all)
	resource Admin{ 
		
		//add event to event dictionary
		access(all)
		fun addEvent(eventName: String, types: [Type]){ 
			pre{ 
				TheFabricantNFTAccess.event[eventName] == nil:
					"eventName already exists"
			}
			TheFabricantNFTAccess.event[eventName] ={} 
			TheFabricantNFTAccess.eventToTypes[eventName] = types
			emit EventAdded(eventName: eventName, types: types)
		}
		
		access(all)
		fun changeAccessList(eventName: String, addresses: [Address]){ 
			TheFabricantNFTAccess.accessList[eventName] = addresses
			emit AccessListChanged(eventName: eventName, addresses: addresses)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(all)
	resource Redeemer{ 
		
		// user redeems an nft for an event
		access(all)
		fun redeem(eventName: String, nftRef: &{NonFungibleToken.NFT}){ 
			pre{ 
				(nftRef.owner!).address == (self.owner!).address:
					"redeemer is not owner of nft"
				TheFabricantNFTAccess.event[eventName] != nil:
					"event does exist"
				!(TheFabricantNFTAccess.event[eventName]!).keys.contains((self.owner!).address):
					"address already redeemed for this event"
				!(TheFabricantNFTAccess.event[eventName]!).values.contains(nftRef.uuid):
					"nft is already used for redemption for this event"
			}
			let array = TheFabricantNFTAccess.getEventToTypes()[eventName]!
			if array.contains(nftRef.getType()){ 
				let oldAddressToUUID = TheFabricantNFTAccess.event[eventName]!
				oldAddressToUUID[(self.owner!).address] = nftRef.uuid
				TheFabricantNFTAccess.event[eventName] = oldAddressToUUID
				emit EventRedemption(eventName: eventName, address: (self.owner!).address, nftID: nftRef.id, nftType: nftRef.getType(), nftUuid: nftRef.uuid)
				return
			} else{ 
				panic("the nft you have provided is not a redeemable type for this event")
			}
		}
		
		// destructor
		//
		// initializer
		//
		init(){} 
	}
	
	access(all)
	fun createNewRedeemer(): @Redeemer{ 
		return <-create Redeemer()
	}
	
	access(all)
	fun getEvent():{ String:{ Address: UInt64}}{ 
		return TheFabricantNFTAccess.event
	}
	
	access(all)
	fun getEventToTypes():{ String: [Type]}{ 
		return TheFabricantNFTAccess.eventToTypes
	}
	
	access(all)
	fun getAccessList():{ String: [Address]}{ 
		return TheFabricantNFTAccess.accessList
	}
	
	// -----------------------------------------------------------------------
	// initialization function
	// -----------------------------------------------------------------------
	//
	init(){ 
		self.event ={} 
		self.eventToTypes ={} 
		self.accessList ={} 
		self.AdminStoragePath = /storage/NFTAccessAdmin0022
		self.RedeemerStoragePath = /storage/NFTAccessRedeemer0022
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
