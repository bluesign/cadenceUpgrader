// Description: Smart Contract for Stanz.club
// SPDX-License-Identifier: UNLICENSED

// Testnet accounts
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/**
 * @dev Implementation of the StanzClub NFT collection with NonFungibleToken and MetadataViews standards.
**/
pub contract StanzClub: NonFungibleToken {
    pub var totalSupply: UInt64
    pub var name: String
    
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath   
    

    /** Struct to store NFT rarity metadata.
     *
     * @param rarity: Fixed-point unsigned integer optional representing the rarity level.
     * @param rarityName: String of the rarity name.
     * @param parts: Dictionary containing specific rarities.
    **/
    pub struct Rarity{
        pub let rarity: UFix64?
        pub let rarityName: String
        pub let parts: {String: RarityPart}

        init(rarity: UFix64?, rarityName: String, parts:{String:RarityPart}) {
            self.rarity=rarity
            self.rarityName=rarityName
            self.parts=parts
        }
    }

    /** Struct to store NFT rarity parts metadata.
     *
     * @param rarity: Fixed-point unsigned integer optional storing the rarity level.
     * @param rarityName: String storing the rarity name.
     * @param name: String storing the rarity parts name.
    **/
    pub struct RarityPart{
        pub let rarity: UFix64?
        pub let rarityName: String
        pub let name: String

        init(rarity: UFix64?, rarityName: String, name:String) {
            self.rarity=rarity
            self.rarityName=rarityName
            self.name=name
        }
    }
    
    /** Resource interface to expose account access-only NFT modifiers. **/
    pub resource interface NFTModifier {

        /// Interface template for setting metadata URL.
        access(account) fun setURLMetadataHelper(newURL: String, newThumbnail: String)

        /// Interface template for setting rarity metadata.
        access(account) fun setRarityHelper(rarity: UFix64, rarityName: String, rarityValue: String)

        /// Interface template for setting edition metadata.
        access(account) fun setEditionHelper(editionNumber: UInt64)

        /// Interface template for setting specific custom metadata field.
        access(account) fun setMetadataHelper(metadata_name: String, metadata_value: String)
    }
    
    /** Resource defining NFT type.
     *
     * @param id: Unsigned integer storing the NFT ID.
     * @param link: String storing the NFT URL link.
     * @param batch: Unsigned integer storing the NFT batch.
     * @param sequence: Unsigned integer storing the NFT sequence number.
     * @param limit: Unsigned integer storing the NFT mint limit value.
     * @param name: String storing the NFT name.
     * @param description: String storing the written description of the NFT.
     * @param thumbnail: String storing the small thumbnail representation of the NFT. 
     * This field should be a web-friendly file (i.e JPEG, PNG).
     *
     * @param rarity: Fixed-point unsigned integer optional storing rarity level.
	 * @param rarityName: String storing the rarity name.
     * @param rarityValue: String storing the rarity parts name.
	 * @param parts: Dictionary containing rarities.
     * 
     * @param editionNumber: Unsigned integer storing the NFT edition number.
     * @param metadata: Dictionary containing custom metadata.
     *
     * Requirements:
     *  - @StanzClub.NFTModifier
     *  - @NonFungibleToken.INFT
     *  - @MetadataViews.Resolver
    **/
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, NFTModifier {
        pub let id: UInt64
        pub var link: String
        pub var batch: UInt32
        pub var sequence: UInt16
        pub var limit: UInt16
        pub var name: String
        pub var description: String
        pub var thumbnail: String
        pub var royalties: [MetadataViews.Royalty]

        pub var rarity: UFix64?
		pub var rarityName: String
        pub var rarityValue: String
		pub var parts: {String: RarityPart}

        pub var editionNumber: UInt64
        
        pub var metadata: {String: String}


        /* Account access-only function for setting the NFT URL link and small thumbnail 
           representation of the NFT.
    
           @dev see {@StanzClub.NFTModifier-setURLMetadataHelper}
           @param newURL: String of the new URL link.
           @param newThumbnail: String of the new NFT thumbnail.
        */
        access(account) fun setURLMetadataHelper(newURL: String, newThumbnail: String){
            self.link = newURL
            self.thumbnail = newThumbnail
            log("URL metadata is set to: ")
            log(self.link)
            log(self.thumbnail)
        }

        /* Account access-only function for setting the rarity level, name, parts name,
           and the rarity parts structure.
          
           @dev see {@StanzClub.NFTModifier-setRarityHelper}
           @param rarity: Fixed-point unsigned integer of the new rarity level.
           @param rarityName: String of the new rarity name.
           @param rarityValue: String of the new rarity parts name.
        */
        access(account) fun setRarityHelper(rarity: UFix64, rarityName: String, rarityValue: String)  {
            self.rarity = rarity
            self.rarityName = rarityName
            self.rarityValue = rarityValue
            
            self.parts = {rarityName:RarityPart(rarity: rarity, rarityName: rarityName, name:rarityValue)}
            
            log("Rarity metadata is updated")
        }

        /* Account access-only function for setting the NFT edition number.
        
           @dev see {@StanzClub.NFTModifier-setEditionHelper}
           @param editionNumber: Unsigned integer of the new NFT edition number.
        */
        access(account) fun setEditionHelper(editionNumber: UInt64)  {
            self.editionNumber = editionNumber
            
            log("Edition metadata is updated")
        }

        /* Account access-only function for setting a specific custom metadata field.

           @dev see {@StanzClub.NFTModifier-setMetadataHelper}
           @param metadata_name: String of the custom metadata field to be set.
           @param metadata_value: String of the custom metadata field corresponding to the 
           `metadata_name` to be set.
        */ 
        access(account) fun setMetadataHelper(metadata_name: String, metadata_value: String)  {
            self.metadata.insert(key: metadata_name, metadata_value)
            log("Custom Metadata store is updated")
        }
        
        /* StanzClub.@NFT resource constructor */
        init(
            initID: UInt64, 
            initlink: String, 
            initbatch: UInt32, 
            initsequence: UInt16, 
            initlimit: UInt16, 
            name: String, 
            description: String, 
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            editionNumber: UInt64, 
            metadata: {String:String}, 
        ) {
            self.id = initID
            self.link = initlink
            self.batch = initbatch
            self.sequence=initsequence
            self.limit=initlimit

            self.name = name 
            self.description = description
            self.thumbnail = thumbnail
            self.royalties = royalties
            
            self.rarity = nil
            self.rarityName = "Tier"
            self.rarityValue= "null"
            self.parts = {self.rarityName: RarityPart(rarity: self.rarity, rarityName: self.rarityName, name: self.rarityValue)}
            self.editionNumber = editionNumber
        
            self.metadata = metadata
        }

        /* Public function to provide access to metadata views.

           @dev see {@MetadataViews.Resolver-getViews}
           @return returns an array of the following:
            - @StanzClub.Rarity
            - @MetadatViews.Display
            - @MetadatViews.Editions
            - @MetadatViews.Serial
            - @MetadatViews.ExternalURL
            - @MetadatViews.NFTCollectionData
            - @MetadatViews.NFTCollectionDisplay
            - @MetadatViews.Royalties
            - @MetadatViews.Traits
        */
        pub fun getViews(): [Type] {
            return [
                Type<Rarity>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        /* Public function to provide access to specific views.

           @dev see {@MetadataViews:Resolver-resolveView}
           @param view: Type of the view to return.
           @return returns one of the following:
            - @StanzClub.Rarity
            - @MetadatViews.Display
            - @MetadatViews.Editions
            - @MetadatViews.Serial
            - @MetadatViews.ExternalURL
            - @MetadatViews.NFTCollectionData
            - @MetadatViews.NFTCollectionDisplay
            - @MetadatViews.Royalties
            - @MetadatViews.Traits
            - nil
        */        
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                // This view provides information on the NFT rarity.
                case Type<Rarity>():
                    return Rarity(
                        rarity : self.rarity,
                        rarityName: self.rarityName,
                        parts : self.parts

                    )
                
                // This view provides general descriptive information on 
                // the NFT.
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name : self.name,
                        description: self.description,
                        thumbnail : MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                
                // This view provides information on the NFT edition.
                case Type<MetadataViews.Editions>():
                    let editionInfo: MetadataViews.Edition = MetadataViews.Edition(name: "Stanz Club NFT", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(editionList)
                
                // This view provides the serial number of the NFT.
                // NOTE: Unused.
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                
                // This view provides the royalties of the NFT.
                // NOTE: Unused.
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])

                // This view provides the external URL of the NFT.
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(
                        url: self.link
                            .concat(self.batch.toString())
                            .concat("/")
                            .concat(self.sequence.toString())
                    )
                    
                // This view provides information for where to set up a NFT 
                // collection in storage and to create the empty collection.
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: StanzClub.CollectionStoragePath,
                        publicPath: StanzClub.CollectionPublicPath,
                        providerPath: /private/StanzClubCollection,
                        publicCollection: Type<&StanzClub.Collection{StanzClub.StanzClubCollectionPublic}>(),
                        publicLinkedType: Type<&StanzClub.Collection{StanzClub.StanzClubCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&StanzClub.Collection{StanzClub.StanzClubCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-StanzClub.createEmptyCollection()
                        })
                    )
                
                // This view provides the NFT display information.
                case Type<MetadataViews.NFTCollectionDisplay>():
                    // Set square image file and type
                    // Square-sized image to represent this collection.
                    var squareImageFile: String = "null"
                    var squareImageType: String = "null"

                    if var _file = self.metadata["SQUARE_IMAGE_FILE"] { squareImageFile = _file }
                    if var _type = self.metadata["SQUARE_IMAGE_TYPE"] { squareImageType = _type }

                    let squareImage: MetadataViews.Media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile (url: squareImageFile),
                        mediaType: squareImageType
                    )

                    // Set banner image file and type
                    // Banner-sized image for this collection, recommended to have a size near 1200x630.
                    var bannerImageFile: String = "null"
                    var bannerImageType: String = "null"

                    if var _file = self.metadata["BANNER_IMAGE_FILE"] { bannerImageFile = _file }
                    if var _type = self.metadata["BANNER_IMAGE_TYPE"] { bannerImageType = _type }

                    let bannerImage: MetadataViews.Media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile (url: bannerImageFile),
                        mediaType: bannerImageType
                    )

                    // Return NFTCollectionDisplay
                    return MetadataViews.NFTCollectionDisplay(
                        name: "StanzClub Collection",
                        description: "StanzClub Collection",
                        externalURL: MetadataViews.ExternalURL(
                            url: self.link
                        ),
                        squareImage: squareImage,
                        bannerImage: bannerImage,
                        socials: {}
                    )
                
                // This view provides the distinct NFT traits information. 
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    
                    for key in self.metadata.keys {
                        traits.append(MetadataViews.Trait(
                            name: key,
                            value: self.metadata[key],
                            displayType: key,
                            rarity: MetadataViews.Rarity(
                                score: (0.0 as UFix64),
                                max: (100.0 as UFix64),
                                description: key
                            )
                        ))
                    }

                    return MetadataViews.Traits(traits)
            }

            // View type is invalid. Return nil.
            return nil
        }
    }

    /** Resource interface to expose public collection functions. **/
    pub resource interface StanzClubCollectionPublic {

        /// Interface template for depositing an @NonFungibleToken.NFT into a collection.
        pub fun deposit(token: @NonFungibleToken.NFT)

        /// Interface template for getting a collection's NFT IDs.
        pub fun getIDs(): [UInt64]

        /// Interface template for borrowing a @NonFungibleToken.NFT reference.
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT

        /// Interface template for borrowing a @StanzClub.NFT reference.
        pub fun borrowStanzClub(id: UInt64): &StanzClub.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow StanzClub reference: The ID of the returned reference is incorrect"
            }
        }
    }

    /** Resource defining a collection for storing NFTs in account.
     *
     * Requirements:
     *  - @StanzClub.StanzClubCollectionPublic
     *  - @NonFungibleToken.Provider
     *  - @NonFungibleToken.Receiver
     *  - @NonFungibleToken.CollectionPublic
     *  - @MetadataViews.ResolverCollection
    **/
    pub resource Collection: StanzClubCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        /* StanzClub.@Collection resource constructor */
        init () {
            self.ownedNFTs <- {}
        }

        /* Public function to allow withdrawal of an NFT of resource type @NonFungibleToken.NFT from
           the account's collection.

           @dev see {@NonFungibletoken.Provider-withdraw}
           @param withdrawID: Unsigned integer of the NFT ID to be withdrawn from the account's 
           collection.
           @return returns a @NonFungibleToken.NFT resource from the account's collection.

           Emits a {Withdraw} event.
        */
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)!
            
            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /* Public function to allow deposit of an NFT of resource type @NonFungibleToken.NFT into the
           account's collection. Input `token` of resource type @NonFungibleToken.NFT is cast to resource 
           type @StanzClub.NFT.

           @dev see {@StanzClub.StanzClubCollectionPublic-deposit}
           @param token: @NonFungibleToken.NFT resource to be deposited into the account's collection.

           Emits a {Deposit} event.
        */
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @StanzClub.NFT    
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /* Public function to allow borrowing of an NFT reference of resource type @NonFungibleToken.NFT 
           from the account's collection. NFT `id` of resource type @StanzClub.NFT is cast and unwrapped 
           to resource type @NonFungibleToken.NFT.

           @dev see {@StanzClub.StanzClubCollectionPublic-borrowNFT}
           @param id: Unsigned integer of the NFT ID to be referenced from the account's collection.
           @return returns a @NonFungibleToken.NFT resource from the account's collection.
        */
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        /* Public function to provide a list of NFT IDs stored within the account's collection.

           @dev see {@StanzClub.StanzClubCollectionPublic-getIDs}
           @return returns a list of NFT IDs stored within the account's collection.
        */
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /* Resource destructor override function */
        destroy() {
            destroy self.ownedNFTs
        }

        /* Public function to allow borrowing of an NFT view reference.

           @dev see {@StanzClub.StanzClubCollectionPublic-borrowViewResolver}
           @param id: Unsigned integer of the NFT ID whose view reference is returned from the account's 
           collection.
           @return returns an NFT view reference from the account's collection.
        */
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let exampleNFT = nft as! &StanzClub.NFT
            return exampleNFT as &AnyResource{MetadataViews.Resolver}
        }

        /* Public function to allow borrowing of an NFT reference optional of resource type @StanzClub.NFT 
           from the account's collection.

           @dev see {@StanzClub.StanzClubCollectionPublic-borrowStanzClub}
           @param id: Unsigned integer of the NFT ID to be referenced from the account's collection.
           @return returns a @NonFungibleToken.NFT resource from the account's collection.
        */
        pub fun borrowStanzClub(id: UInt64): &StanzClub.NFT? {
            if self.ownedNFTs[id] == nil {
                return nil
            }
            else {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &StanzClub.NFT
            }
        }

    }

    /* Public function to initialize an empty collection */
    pub fun createEmptyCollection(): @StanzClub.Collection {
        return <- create Collection()
    }

    /* Resource defining the minting of a @StanzClub.NFT */
    pub resource NFTMinter {
        pub var minterID: UInt64
        
        /* StanzClub.@NFTMinter resource constructor */
        init() {
            self.minterID = 0    
        }

        /* Public function for minting a @StanzClub.NFT.
         
           @param glink: String storing the generated NFT URL link.
           @param gbatch: Unsigned integer storing the generated NFT batch.
           @param glimit: Unsigned integer storing the generated NFT mint limit value.
           @param gsequence: Unsigned integer storing the generated NFT sequence number.
           @param name: String storing the NFT name.
           @param description: String storing the written description of the NFT.
           @param thumbnail: String storing the small thumbnail representation of the NFT. 
           This field should be a web-friendly file (i.e JPEG, PNG).
           @param editionNumber: String storing the small thumbnail representation of the NFT. 
           @param metadata: Dictionary containing custom metadata.
           @return returns minted NFT of type @StanzClub.NFT
        */
        pub fun mintNFT(
            glink: String,
            gbatch: UInt32,
            glimit: UInt16,
            gsequence: UInt16,
            name: String,
            description: String,
            thumbnail: String,
            royalties: [MetadataViews.Royalty],
            editionNumber: UInt64,
            metadata: {String: String}
        ): @NFT {
            let tokenID = (UInt64(gbatch) << 32) | (UInt64(glimit) << 16) | UInt64(gsequence)
            
            var newNFT <- create NFT(
                initID: tokenID,
                initlink: glink,
                initbatch: gbatch,
                initsequence: gsequence,
                initlimit: glimit,
                name: name,
                description: description,
                thumbnail: thumbnail,
                royalties: royalties,
                editionNumber: editionNumber,
                metadata: metadata
            )

            self.minterID = tokenID
            StanzClub.totalSupply = StanzClub.totalSupply + 1

            return <-newNFT
        }
    }

    /* Public resource storing the modifier functions for the account. */
    pub resource Modifier {

        pub var ModifierID: UInt64
        
        /* Public modifier function for the account's `currentNFT`'s URL link and thumbnail.

           @param currentNFT: Optional @StanzClub.NFT reference to modify.
           @param newURL: String storing the new URL to change to.
           @param newThumbnail: String storing the new thumbnail to change to.
           @return returns the new, updated URL link.
        */
        pub fun setURLMetadata(currentNFT: &StanzClub.NFT?, newURL: String, newThumbnail: String) : String {
            let ref2 =  currentNFT!
            ref2.setURLMetadataHelper(newURL: newURL, newThumbnail: newThumbnail)
            log("URL metadata is set to: ")
            log(newURL)
            return newURL
        }
        
        /* Public modifier function for the account's `currentNFT`'s rarity fields and its 
           @StanzClub.RarityParts struct.

           @param currentNFT: Optional @StanzClub.NFT reference to modify.
           @param rarity: Fixed-point unsigned integer storing rarity level to change to.
	       @param rarityName: String storing the rarity name to change to.
           @param rarityValue: String storing the rarity parts name to change to.
        */
        pub fun setRarity(currentNFT: &StanzClub.NFT?, rarity:UFix64, rarityName:String, rarityValue:String)  {
            let ref2 =  currentNFT!
            ref2.setRarityHelper(rarity: rarity, rarityName: rarityName, rarityValue: rarityValue)
            log("Rarity metadata is updated")
        }
        
        /* Public modifier function for the account's `currentNFT`'s edition number field.

           @param currentNFT: Optional @StanzClub.NFT reference to modify.
           @param editionNumber: Unsigned integer storing the NFT edition number to change to.
        */
        pub fun setEdition(currentNFT: &StanzClub.NFT?, editionNumber:UInt64)  {
            let ref2 =  currentNFT!
            ref2.setEditionHelper(editionNumber: editionNumber)
            log("Edition metadata is updated")
        }
        
        /* Public modifier function for the account's `currentNFT`'s metadata fields. This
           modifier will modify a specific custom metadata field.

           @param currentNFT: Optional @StanzClub.NFT reference to modify.
           @param metadata_name: String of the custom metadata field to change to.
           @param metadata_value: String of the custom metadata field corresponding to change 
           `metadata_name` to.
        */
        pub fun setMetadata(currentNFT: &StanzClub.NFT?, metadata_name: String, metadata_value: String)  {
            let ref2 =  currentNFT!
            ref2.setMetadataHelper(metadata_name: metadata_name, metadata_value: metadata_value)
            log("Custom Metadata store is updated")
        }

        /* StanzClub.@Modifier resource constructor */
        init() {
            self.ModifierID = 0    
        }
    }

    /* StanzClub contract constructor 
     *
     * Emits a {ContractInitialized} event.
    */
	init() {
        self.CollectionStoragePath = /storage/StanzClubCollection
        self.CollectionPublicPath = /public/StanzClubCollection
        self.MinterStoragePath = /storage/StanzClubMinter

        self.totalSupply = 0
        self.name = "Stanz Club"

		self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
        self.account.link<&{NonFungibleToken.CollectionPublic, StanzClub.StanzClubCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath, 
            target: self.CollectionStoragePath
        )
        self.account.save(<-create NFTMinter(), to: self.MinterStoragePath)
        self.account.save(<-create Modifier(), to: /storage/StanzClubModifier)
        emit ContractInitialized()
	}
}
 
 