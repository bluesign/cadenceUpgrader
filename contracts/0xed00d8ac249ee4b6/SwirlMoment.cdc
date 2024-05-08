import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import SwirlNametag from "./SwirlNametag.cdc"

pub contract SwirlMoment: NonFungibleToken {
    pub var totalSupply: UInt64
    pub var nextNonceForProofOfMeeting: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Log(str: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath

    pub struct Coordinate {
        pub let lat: Fix64
        pub let lng: Fix64

        init(lat: Fix64, lng: Fix64) {
            self.lat = lat
            self.lng = lng
        }
    }

    pub struct ProofOfMeeting {
        pub let account: PublicAccount
        pub let location: Coordinate

        pub let nonce: UInt64
        pub let keyIndex: Int
        pub let signature: String

        init(account: PublicAccount, location: Coordinate, nonce: UInt64, keyIndex: Int, signature: String) {
            self.account = account
            self.location = location
            self.nonce = nonce
            self.keyIndex = keyIndex
            self.signature = signature
        }

        pub fun signedData(): [UInt8] {
            var json = "{"
            json = json.concat("\"address\":\"").concat(self.account.address.toString()).concat("\",")
            json = json.concat("\"lat\":").concat(self.location.lat.toString()).concat(",")
            json = json.concat("\"lng\":").concat(self.location.lng.toString()).concat(",")
            json = json.concat("\"nonce\":").concat(self.nonce.toString())
            json = json.concat("}")
            return json.utf8
        }

        pub fun signPubKey(): AccountKey {
            return self.account.keys.get(keyIndex: self.keyIndex) ?? panic("no key at given index")
        }
    }

    /// Mints a new NFT. Proof-of-Location is required to mint moment
    pub fun mint(proofs: [ProofOfMeeting]) {
        // validate swirl participants' messages
        for proof in proofs {
            // 0. resolve profile from the participant's SwirlNametag.
            let collectionRef = proof.account
                .getCapability(SwirlNametag.CollectionPublicPath)
                .borrow<&{SwirlNametag.SwirlNametagCollectionPublic}>()
                ?? panic("no SwirlNametag.Collection found: ".concat(proof.account.address.toString()))

            let nametags = collectionRef.getIDs()
            if nametags.length == 0 {
                panic("no nametag found: ".concat(proof.account.address.toString()))
            }
            let nametag = collectionRef.borrowSwirlNametag(id: nametags[0]) ?? panic("unable to borrow nametag")
            let profile = nametag.profile

            // 1. ensure that nonce is up to date (to prevent signature replay attack)
            if proof.nonce != SwirlMoment.nextNonceForProofOfMeeting {
                panic("nonce mismatch: ".concat(proof.account.address.toString()))
            }

            // 2. verify that the message is signed correctly
            let isValid = proof.signPubKey().publicKey.verify(
                signature: proof.signature.decodeHex(),
                signedData: proof.signedData(),
                domainSeparationTag: "",
                hashAlgorithm: HashAlgorithm.SHA2_256
            )
            if !isValid {
                panic("invalid signature: ".concat(proof.account.address.toString()))
            }

            // 3. make sure they're in a close location (<= 1km!)
            // since we can't correctly calculate harversine distance in cadence,
            // we use 0.00904372 degrees to approximate as 1km (without correcting the earth's curvature...)
            if self.abs(proofs[0].location.lat - proof.location.lat) > 0.00904372 {
                panic("location too far: ".concat(proof.account.address.toString()))
            }
            if self.abs(proofs[0].location.lng - proof.location.lng) > 0.00904372 {
                panic("location too far: ".concat(proof.account.address.toString()))
            }

            // 4. mint
            for p in proofs {
                if p.account.address == proof.account.address {
                    continue
                }
                let recipient = p.account.getCapability(SwirlMoment.CollectionPublicPath)
                    .borrow<&{NonFungibleToken.CollectionPublic}>()
                    ?? panic("no SwirlMoment.Collection found: ".concat(proof.account.address.toString()))

                self.mintNFT(recipient: recipient, nametagID: nametag.id, location: proof.location)
            }
        }
        SwirlMoment.nextNonceForProofOfMeeting = SwirlMoment.nextNonceForProofOfMeeting + 1
    }

    priv fun abs(_ x: Fix64): Fix64 {
        if x < 0.0 {
            return -x
        }
        return x
    }

    priv fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, nametagID: UInt64, location: Coordinate) {
        // create a new NFT
        var newNFT <- create NFT(
            id: SwirlMoment.totalSupply,
            nametagID: nametagID,
            location: location,
            mintedAt: getCurrentBlock().timestamp,
        )
        recipient.deposit(token: <-newNFT)
        SwirlMoment.totalSupply = SwirlMoment.totalSupply + 1
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        /// the token ID
        pub let id: UInt64

        /// the token ID of the nametag, linked to the profile of the person you met
        pub let nametagID: UInt64

        /// where you met
        pub let location: Coordinate

        /// the time you met
        pub let mintedAt: UFix64

        init(id: UInt64, nametagID: UInt64, location: Coordinate, mintedAt: UFix64) {
            self.id = id
            self.nametagID = nametagID
            self.location = location
            self.mintedAt = mintedAt
        }

        pub fun profile(): SwirlNametag.Profile {
            return SwirlNametag.getProfile(self.nametagID)
        }

        pub fun getViews(): [Type] {
            let views: [Type] = [
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.Serial>(),
                    Type<MetadataViews.ExternalURL>(),
                    Type<MetadataViews.NFTCollectionData>(),
                    Type<MetadataViews.NFTCollectionDisplay>(),
                    Type<MetadataViews.Traits>()
                ]
            return views
        }

        pub fun name(): String {
            return "Swirl Moment with ".concat(self.profile().nickname)
        }

        pub fun profileImageUrl(): String {
            let profile = self.profile()
            var url = "https://swirl.deno.dev/dnft/moment.svg?"
            url = url.concat("nickname=").concat(profile.nickname)
            url = url.concat("&profile_img=").concat(String.encodeHex(profile.profileImage.utf8))
            url = url.concat("&color=").concat(String.encodeHex(profile.color.utf8))
            url = url.concat("&met_at=").concat(self.mintedAt.toString())
            return url
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<SwirlNametag.Profile>():
                    return self.profile()
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.",
                        thumbnail: MetadataViews.HTTPFile(url: self.profileImageUrl()),
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL(self.profileImageUrl())

                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SwirlMoment.CollectionStoragePath,
                        publicPath: SwirlMoment.CollectionPublicPath,
                        providerPath: SwirlMoment.ProviderPrivatePath,
                        publicCollection: Type<&SwirlMoment.Collection{SwirlMoment.SwirlMomentCollectionPublic}>(),
                        publicLinkedType: Type<&SwirlMoment.Collection{SwirlMoment.SwirlMomentCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&SwirlMoment.Collection{SwirlMoment.SwirlMomentCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-SwirlMoment.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: self.profileImageUrl()),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Swirl Moment",
                        description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.",
                        externalURL: MetadataViews.ExternalURL("https://hyphen.at/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {}
                    )
                case Type<MetadataViews.Traits>():
                    let traits: {String: AnyStruct} = {}
                    traits["locationLat"] = self.location.lat
                    traits["locationLng"] = self.location.lng
                    traits["mintedAt"] = self.mintedAt
                    let traitsView = MetadataViews.dictToTraits(dict: traits, excludedNames: [])

                    return traitsView
                default:
                    return nil
            }
        }
    }

    pub resource interface SwirlMomentCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSwirlMoment(id: UInt64): &SwirlMoment.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow SwirlMoment reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: SwirlMomentCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            panic("soulbound; SBT is not transferable")
        }

        pub fun burn(id: UInt64) {
            let token <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            destroy token
        }

        // deposit takes an NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @SwirlMoment.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowSwirlMoment(id: UInt64): &SwirlMoment.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &SwirlMoment.NFT
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let SwirlMomentNFT = nft as! &SwirlMoment.NFT
            return SwirlMomentNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    init() {
        self.totalSupply = 0
        self.nextNonceForProofOfMeeting = 0

        self.CollectionStoragePath = /storage/SwirlMomentCollection
        self.CollectionPublicPath = /public/SwirlMomentCollection
        self.ProviderPrivatePath = /private/SwirlNFTCollectionProvider

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&SwirlMoment.Collection{NonFungibleToken.CollectionPublic, SwirlMoment.SwirlMomentCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
