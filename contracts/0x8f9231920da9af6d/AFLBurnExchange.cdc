import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import AFLNFT from "./AFLNFT.cdc"

pub contract AFLBurnExchange {
    access(self) let tokens: @{UInt64: NonFungibleToken.NFT} // nftId of token to be swapped -> new token 

    pub event TokenAddedForExchange(oldTokenId: UInt64, newTokenId: UInt64)
    pub event TokenExchanged(oldTokenId: UInt64, newTokenId: UInt64)

    pub fun getTokenId(id: UInt64): UInt64 {
        let tokenRef = &self.tokens[id] as &NonFungibleToken.NFT?
        return tokenRef?.id ?? 0
    }

    pub fun swap(token: @NonFungibleToken.NFT): @NonFungibleToken.NFT {
        pre {
            token.getType() == Type<@AFLNFT.NFT>() : "Wrong token type."
            self.tokens[token.id] != nil: "No token found available in exchange for the provided token id: ".concat(token.id.toString()
        }
        let oldTokenId = token.id
        
        // get the token details
        let data = AFLNFT.getNFTData(nftId: token.id) 
        let templateId = data.templateId
        let serial = data.mintNumber

        // withdraw new token
        let newToken <- self.tokens.remove(key: token.id) ?? panic("No token found for exchange")
        
        // burn old token
        destroy token
        
        emit TokenExchanged(oldTokenId: oldTokenId, newTokenId: newToken.id)

        // return new token to user
        return <- newToken
    }

    pub fun getTokenIds(): [UInt64] {
        return self.tokens.keys
    }

    // nftId = duplicateTokenId 
    // @token = new token
    access(account) fun addTokenForExchange(nftId: UInt64, token: @NonFungibleToken.NFT) {
        pre {
            self.tokens[nftId] == nil: "Token already exists: ".concat(nftId.toString()) 
        }
        let newTokenId = token.id
        self.tokens[nftId] <-! token
        emit TokenAddedForExchange(oldTokenId: nftId, newTokenId: newTokenId)
    }

    access(account) fun withdrawToken(nftId: UInt64): @NonFungibleToken.NFT {
        pre {
            self.tokens[nftId] != nil: "No token found available in exchange for the provided token id: ".concat(nftId.toString())
        }
        let token <- self.tokens.remove(key: nftId)!
        return <- token
    }

    init() {
        self.tokens <- {}
    }
}

