import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	Collectico interface for Basic NFTs (M of N)
	(c) CollecticoLabs.com
 */

access(all)
contract interface CollecticoStandardNFT{ 
	
	// Interface that the Items have to conform to
	access(all)
	resource interface IItem{ 
		// The unique ID that each Item has
		access(all)
		let id: UInt64
	}
	
	// Requirement that all conforming smart contracts have
	// to define a resource called Item that conforms to IItem
	access(all)
	resource interface Item: IItem, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
	}
}
