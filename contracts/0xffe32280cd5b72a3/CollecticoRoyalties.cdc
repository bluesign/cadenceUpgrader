import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

/*
    Provides cuts of the issuer
    (c) CollecticoLabs.com
 */
pub contract CollecticoRoyalties {
    pub fun getIssuerRoyalties(): [MetadataViews.Royalty] {
        return []
    }
}
