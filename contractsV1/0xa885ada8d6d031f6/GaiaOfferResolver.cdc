import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Resolver from "../0xb8ea91944fd51c43/Resolver.cdc"

import Wearables from "../0xe81193c424cfd3fb/Wearables.cdc"

access(all)
contract GaiaOfferResolver{ 
	access(all)
	enum ResolverType: UInt8{ 
		access(all)
		case NFT
		
		access(all)
		case DoodlesWearableTemplate
	}
	
	access(all)
	resource OfferResolver: Resolver.ResolverPublic{ 
		access(all)
		fun checkOfferResolver(item: &{NonFungibleToken.INFT, ViewResolver.Resolver}, offerParamsString:{ String: String}, offerParamsUInt64:{ String: UInt64}, offerParamsUFix64:{ String: UFix64}): Bool{ 
			if offerParamsString["resolver"] == ResolverType.NFT.rawValue.toString(){ 
				assert(item.id.toString() == offerParamsString["nftId"], message: "item NFT does not have specified ID")
				return true
			} else if offerParamsString["resolver"] == ResolverType.DoodlesWearableTemplate.rawValue.toString(){ 
				// get the Doodles Wearable template for this NFT
				let view = item.resolveView(Type<Wearables.Metadata>())! as! Wearables.Metadata
				assert(view.templateId.toString() == offerParamsString["templateId"], message: "item NFT does not have specified templateId")
				return true
			} else{ 
				panic("Invalid Resolver on Offer")
			}
			return false
		}
	}
	
	access(all)
	fun createResolver(): @OfferResolver{ 
		return <-create OfferResolver()
	}
}
