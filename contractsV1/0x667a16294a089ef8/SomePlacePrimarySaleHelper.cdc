/*
	Help manage a primary sale for SomePlace collectibles utilizing preminted NFTs that are in storage.
	This is meant to be curated for specific drops where there are leftover NFTs to be sold publically from a private sale.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import SomePlaceCollectible from "./SomePlaceCollectible.cdc"

access(all)
contract SomePlacePrimarySaleHelper{ 
	access(self)
	let premintedNFTCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
	
	access(account)
	fun retrieveAvailableNFT(): @SomePlaceCollectible.NFT{ 
		let nftCollection = self.premintedNFTCap.borrow()!
		let randomIndex = revertibleRandom<UInt64>() % UInt64(nftCollection.getIDs().length)
		return <-(
			nftCollection.withdraw(withdrawID: nftCollection.getIDs()[randomIndex])
			as!
			@SomePlaceCollectible.NFT
		)
	}
	
	access(all)
	fun getRemainingNFTCount(): Int{ 
		return (self.premintedNFTCap.borrow()!).getIDs().length
	}
	
	init(){ 
		var capability_1 =
			self.account.capabilities.storage.issue<&SomePlaceCollectible.Collection>(
				SomePlaceCollectible.CollectionStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: /private/SomePlacePrimarySaleHelperAccess
		)
		self.premintedNFTCap = self.account.capabilities.get<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>(/private/SomePlacePrimarySaleHelperAccess)!
	}
}
