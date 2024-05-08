import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import TopShot from "./TopShot.cdc"

import Resolver from "../0xb8ea91944fd51c43/Resolver.cdc"

access(all)
contract ResolverSubedition{ 
	access(all)
	enum ResolverType: UInt8{ 
		access(all)
		case TopShotSubedition
	}
	
	access(all)
	resource OfferResolver: Resolver.ResolverPublic{ 
		access(all)
		fun checkOfferResolver(item: &{NonFungibleToken.INFT, ViewResolver.Resolver}, offerParamsString:{ String: String}, offerParamsUInt64:{ String: UInt64}, offerParamsUFix64:{ String: UFix64}): Bool{ 
			if offerParamsString["resolver"] == ResolverType.TopShotSubedition.rawValue.toString(){ 
				let view = item.resolveView(Type<TopShot.TopShotMomentMetadataView>())!
				let metadata = view as! TopShot.TopShotMomentMetadataView
				let offersSubeditionId = offerParamsString["subeditionId"]
				let nftsSubeditionId = TopShot.getMomentsSubedition(nftID: item.id)
				assert(offersSubeditionId != nil, message: "subeditionId does not exist on Offer")
				assert(nftsSubeditionId != nil, message: "subeditionId does not exist on NFT")
				if offerParamsString["playId"] == metadata.playID.toString() && offerParamsString["setId"] == metadata.setID.toString() && offersSubeditionId! == (nftsSubeditionId!).toString(){ 
					return true
				}
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
