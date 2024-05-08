import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract SwirlNametag: NonFungibleToken {
    pub var totalSupply: UInt64
    priv let profiles: {UInt64: Profile}

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath

    pub struct SocialHandle {
        pub let channel: String
        pub let handle: String

        init(channel: String, handle: String) {
            self.channel = channel
            self.handle = handle
        }
    }

    pub struct Profile {
        pub let nickname: String
        pub let profileImage: String
        pub let keywords: [String]
        pub let color: String
        pub let socialHandles: [SocialHandle]

        init(
            nickname: String,
            profileImage: String,
            keywords: [String],
            color: String,
            socialHandles: [SocialHandle]
        ) {
            self.nickname = nickname
            self.profileImage = profileImage
            self.keywords = keywords
            self.color = color
            self.socialHandles = socialHandles
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64

        init(id: UInt64) {
            self.id = id
        }

        pub fun getViews(): [Type] {
            let views: [Type] = [
                    Type<Profile>(),
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.Serial>(),
                    Type<MetadataViews.NFTCollectionData>(),
                    Type<MetadataViews.NFTCollectionDisplay>(),
                    Type<MetadataViews.Traits>()
                ]
            return views
        }

        pub fun name(): String {
            return "Swirl Nametag: ".concat(self.profile().nickname)
        }

        pub fun profile(): Profile {
            return SwirlNametag.getProfile(self.id)
        }

        pub fun profileImageUrl(): String {
            let profile = self.profile()
            var url = "https://swirl.deno.dev/dnft/nametag.svg?"
            url = url.concat("nickname=").concat(profile.nickname)
            url = url.concat("&profile_img=").concat(String.encodeHex(profile.profileImage.utf8))
            url = url.concat("&color=").concat(String.encodeHex(profile.color.utf8))
            return url
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<Profile>():
                    return self.profile()

                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.",
                        thumbnail: MetadataViews.HTTPFile(url: self.profileImageUrl())
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: SwirlNametag.CollectionStoragePath,
                        publicPath: SwirlNametag.CollectionPublicPath,
                        providerPath: SwirlNametag.ProviderPrivatePath,
                        publicCollection: Type<&SwirlNametag.Collection{SwirlNametag.SwirlNametagCollectionPublic}>(),
                        publicLinkedType: Type<&SwirlNametag.Collection{SwirlNametag.SwirlNametagCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&SwirlNametag.Collection{SwirlNametag.SwirlNametagCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-SwirlNametag.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(url: self.profileImageUrl()),
                        mediaType: "image/svg+xml"
                    )
                    let socials: {String: MetadataViews.ExternalURL} = {}
                    for handle in self.profile().socialHandles {
                        socials[handle.channel] = MetadataViews.ExternalURL(handle.handle)
                    }

                    return MetadataViews.NFTCollectionDisplay(
                        name: "Swirl Nametag",
                        description: "Swirl, share your digital profiles as NFT and keep IRL moment with others.",
                        externalURL: MetadataViews.ExternalURL("https://hyphen.at/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: socials,
                    )
                case Type<MetadataViews.Traits>():
                    let profile = self.profile()
                    let traits: {String: AnyStruct} = {}
                    traits["nickname"] = profile.nickname
                    traits["keywords"] = profile.keywords
                    traits["color"] = profile.color
                    for handle in profile.socialHandles {
                        traits[handle.channel] = handle.handle
                    }
                    let traitsView = MetadataViews.dictToTraits(dict: traits, excludedNames: [])

                    return traitsView
                default:
                    return nil
            }
        }
    }

    pub resource interface SwirlNametagCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSwirlNametag(id: UInt64): &SwirlNametag.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow SwirlNametag reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: SwirlNametagCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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

        // deposit takes an NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @SwirlNametag.NFT

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

        pub fun borrowSwirlNametag(id: UInt64): &SwirlNametag.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &SwirlNametag.NFT
            }

            return nil
        }

        pub fun updateSwirlNametag(profile: Profile) {
            let tokenIDs = self.getIDs()
            if tokenIDs.length == 0 {
                panic("no nametags")
            }
            SwirlNametag.setProfile(tokenID: tokenIDs[0], profile: profile)
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let SwirlNametagNFT = nft as! &SwirlNametag.NFT
            return SwirlNametagNFT as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun getProfile(_ tokenID: UInt64): Profile {
        return self.profiles[tokenID] ?? panic("no profile for token ID")
    }

    access(contract) fun setProfile(tokenID: UInt64, profile: Profile) {
        self.profiles[tokenID] = profile
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, profile: Profile) {
        // create a new NFT
        var newNFT <- create NFT(id: SwirlNametag.totalSupply + 1)
        SwirlNametag.setProfile(tokenID: newNFT.id, profile: profile)
        recipient.deposit(token: <-newNFT)
        SwirlNametag.totalSupply = SwirlNametag.totalSupply + 1
    }

    init() {
        self.totalSupply = 0
        self.profiles = {}

        self.CollectionStoragePath = /storage/SwirlNametagCollection
        self.CollectionPublicPath = /public/SwirlNametagCollection
        self.ProviderPrivatePath = /private/SwirlNFTCollectionProvider

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        self.account.link<&SwirlNametag.Collection{NonFungibleToken.CollectionPublic, SwirlNametag.SwirlNametagCollectionPublic, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
