import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract TSINNOVATORSMARCH2023: NonFungibleToken {

    //################################### STATE ############################
    // total amount of TSINNOVATORSMARCH2023 tokens ever created
    pub var totalSupply: UInt64

    // Storing all the  
    access(account) var attendees: {Address: SimpleTokenView}

    // A description of the TribalScale Event
    pub let eventDescription: String

    //################################### PATHS ############################
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    //################################### EVENTS ###########################
    //Standard events from NonFungibleToken standard
    pub event ContractInitialized()
    pub event Deposit(id: UInt64, to: Address?)
    pub event Withdraw(id: UInt64, from: Address?)

    // TSINNOVATORSMARCH2023 events
    pub event POAPTokenCreated(id: UInt64, email: String, description: String, org: String, ipfsHash: String, timeCreated: UFix64)
    pub event POAPTokenDesposited(id: UInt64, reciever: Address?, timestamp: UFix64)

    //################################### LOGIC ############################
    pub fun getAttendees(): {Address: SimpleTokenView} {
        return self.attendees
    }

    // Minimal token view struct
    pub struct SimpleTokenView {
        pub let id: UInt64
        pub let address: Address
        pub let name: String

        init(id: UInt64, address: Address, name: String) {
            self.id = id
            self.address = address
            self.name = name
        }
    }

    // Full token view 
    pub struct TSTokenView {
        pub let ipfsHash: String
        pub let email: String
        pub let description: String
        pub let org: String
        pub let id: UInt64
        pub let eventName: String
        pub let timeCreated: UFix64

        init(
            ipfsHash : String,
            email : String,
            description: String,
            org: String,
            id: UInt64,
            eventName: String,
            timeCreated: UFix64
        ) {
            self.ipfsHash = ipfsHash
            self.email = email
            self.description = description
            self.org = org
            self.id = id
            self.eventName = eventName
            self.timeCreated = timeCreated
        }
    }

    //Function to return view 
    pub fun getTSTokenView(_ viewResolver: &{MetadataViews.Resolver}) : TSTokenView? {
        if let view = viewResolver.resolveView(Type<TSTokenView>()) {
            if let v = view as? TSTokenView {
                return v
            }
        }
        return nil
    }

    //#############################################################################
    //############################# NFT RESOURCE ##################################
    //#############################################################################

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // The unique identifier of your token
        pub let id: UInt64

        // ####################### TSINNOVATORSMARCH2023 attributes ############################
        pub let email: String
        pub let description: String
        pub let ipfsHash: String
        pub let org: String
        pub let eventName: String
        pub let timeCreated: UFix64

        access(self) let royalties: [MetadataViews.Royalty]

        // ################### MetaData ################
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<TSTokenView>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Royalties>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            var baseUrl = "https://d39cc1gi1l4yig.cloudfront.net/ipfs/"
            var url = baseUrl.concat(self.ipfsHash)
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.email,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: url)
                    )
                case Type<TSTokenView>():
                    return TSTokenView(
                        ipfsHash: self.ipfsHash,
                        email: self.email,
                        description: self.description,
                        org: self.org,
                        id: self.id,
                        eventName: self.eventName,
                        timeCreated: self.timeCreated
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(url)
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: TSINNOVATORSMARCH2023.CollectionStoragePath,
                        publicPath: TSINNOVATORSMARCH2023.CollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&TSINNOVATORSMARCH2023.Collection{TSINNOVATORSMARCH2023.TSINNOVATORSMARCH2023CollectionPublic}>(),
                        publicLinkedType: Type<&TSINNOVATORSMARCH2023.Collection{TSINNOVATORSMARCH2023.TSINNOVATORSMARCH2023CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&TSINNOVATORSMARCH2023.Collection{TSINNOVATORSMARCH2023.TSINNOVATORSMARCH2023CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-TSINNOVATORSMARCH2023.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "tribalscalelogo"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "TribalScale Web3 Innovators connect - March 22nd 2023",
                        description: "This collection is for the Web3 Innovators connect hosted by TribalScale March 22nd 2023",
                        externalURL: MetadataViews.ExternalURL("https://www.tribalscale.com/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "website": MetadataViews.ExternalURL("https://www.tribalscale.com/"),
                            "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/tribalscale?trk=public_post_share-update_actor-text"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/tribalscale/?hl=en"),
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/TribalScale")
                        }
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
            }

            return nil
        } 


        init(
            email: String, 
            description: String, 
            ipfsHash: String, 
            org: String,
            royalties: [MetadataViews.Royalty],
        ) {
            self.id = TSINNOVATORSMARCH2023.totalSupply;
            self.ipfsHash = ipfsHash
            self.email = email
            self.description = description
            self.org = org
            self.royalties = royalties
            self.eventName = "TS Web3 Innovators connect 2023"

            // Getting timestamp
            let timestamp = getCurrentBlock().timestamp
            self.timeCreated = timestamp
            // Emit that a token has been created 
            emit POAPTokenCreated(id: self.id, email: self.email, description: self.description, org: self.org, ipfsHash: self.ipfsHash, timeCreated: timestamp)

            // Increment total supply
            TSINNOVATORSMARCH2023.totalSupply = TSINNOVATORSMARCH2023.totalSupply + 1
        }

    }

    //#############################################################################
    //############################# COLLECTION ####################################
    //#############################################################################

    pub resource interface TSINNOVATORSMARCH2023CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64]
        // Borrow reference to NFT
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
        // Check if user has a token 
        pub fun hasToken(): Bool
        // Force casting to a specific 
        pub fun borrowTSINNOVATORSMARCH2023NFT(id: UInt64): &TSINNOVATORSMARCH2023.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: TSINNOVATORSMARCH2023CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // Dictionary of all tokens in the collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // takes an NFT and adds it to the user's collection 
        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                self.getIDs().length == 0: "You Already Own A Token From the TribalScale event"
            }
            let myToken <- token as! @TSINNOVATORSMARCH2023.NFT

            // emitting events
            let timestamp = getCurrentBlock().timestamp

            emit Deposit(id: myToken.id, to: self.owner?.address)
            emit POAPTokenDesposited(id: myToken.id, reciever: self.owner?.address, timestamp: timestamp)
            
            // Update attendees
            TSINNOVATORSMARCH2023.attendees[self.owner?.address!] = TSINNOVATORSMARCH2023.SimpleTokenView(
                id: myToken.id,
                address: self.owner?.address!,
                name: myToken.email,
            )

            self.ownedNFTs[myToken.id] <-! myToken
        }
        // returns whether there is already a token in the collection
        pub fun hasToken(): Bool {
          return !(self.getIDs().length == 0)
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Returns reference to a metadata view resolver (used to view token data)
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let TSNFT = nft as! &TSINNOVATORSMARCH2023.NFT
            return TSNFT as &AnyResource{MetadataViews.Resolver}
        }

        // Returns reference to a token of type NonFungibleToken.NFT
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
 
        // Returns a reference to a token downcasted to TSINNOVATORSMARCH2023.NFT type
        pub fun borrowTSINNOVATORSMARCH2023NFT(id: UInt64): &TSINNOVATORSMARCH2023.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &TSINNOVATORSMARCH2023.NFT
            }

            return nil
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("You do not own a token with that ID")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }            
    
    pub fun createToken(email: String, description: String, ipfsHash: String, org: String, royalties: [MetadataViews.Royalty] ): @TSINNOVATORSMARCH2023.NFT {
        return <- create NFT(email: email, description: description, ipfsHash: ipfsHash, org: org, royalties: royalties)
    }

    //################# Contract init #######################
    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Set the named paths
        self.CollectionStoragePath = /storage/TSINNOVATORSMARCH2023Collection
        self.CollectionPublicPath = /public/TSINNOVATORSMARCH2023Collection

        // Set event description
        self.eventDescription = "Innovators connect hosted by TribalScale on March 22nd 2023"

        // Set attendees
        self.attendees = {}

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&TSINNOVATORSMARCH2023.Collection{NonFungibleToken.CollectionPublic, TSINNOVATORSMARCH2023.TSINNOVATORSMARCH2023CollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
 