import ChainzPack from "./ChainzPack.cdc"
import ChainzNFT from "./ChainzNFT.cdc"
import ChainzKey from "./ChainzKey.cdc"

pub contract ChainzAdmin {

    pub let AdminStoragePath: StoragePath

    pub resource Admin {

        // openPack
        // calls openPack on the user's Pack Collection
        //
        pub fun openPack(
            id: UInt64, 
            packCollectionRef: &ChainzPack.Collection{ChainzPack.AdminAccessible}, 
            cardCollectionRef: &ChainzNFT.Collection{ChainzNFT.CollectionPublic}, 
            names: [String], 
            descriptions: [String], 
            thumbnails: [String],
            metadatas: [{String: String}],
            keyTiers: [String],
            keyTypes: [String],
            keySerials: [UInt64],
            keyMetadatas: [{String: String}]
        ) {
            packCollectionRef.openPack(id: id, cardCollectionRef: cardCollectionRef, names: names, descriptions: descriptions, thumbnails: thumbnails, metadatas: metadatas)

            // Mint the user a Chainz Ket
            let recipient = packCollectionRef.owner!.address
            let chainzKeyCollection = getAccount(recipient).getCapability(ChainzKey.CollectionPublicPath)
                                        .borrow<&ChainzKey.Collection{ChainzKey.CollectionPublic}>()
                                        ?? panic("This user does not have a ChainzKey Collection set up.")
            
            var i: Int = 0
            while i < keyTiers.length {
                chainzKeyCollection.deposit(token: <- ChainzKey.createNFT(tier: keyTiers[i], type: keyTypes[i], serial: keySerials[i], metadata: keyMetadatas[i]))
                i = i + 1
            }
        }
     
        pub fun airdropMoments(
            cardCollectionRef: &ChainzNFT.Collection{ChainzNFT.CollectionPublic}, 
            names: [String], 
            descriptions: [String], 
            thumbnails: [String],
            metadatas: [{String: String}],
        ) {
            let recipient = cardCollectionRef.owner!.address
            let chainzNFTCollection = getAccount(recipient).getCapability(ChainzNFT.CollectionPublicPath)
                                        .borrow<&ChainzNFT.Collection{ChainzNFT.CollectionPublic}>()
                                        ?? panic("This user does not have a ChainzNFT Collection set up.")

            var i: Int = 0
            while i < names.length {
                chainzNFTCollection.deposit(token: <- ChainzNFT.createNFT(name: names[i], description: descriptions[i], thumbnail: thumbnails[i], metadata: metadatas[i]))
                i = i + 1
            }  

        }

        pub fun createPackType(name: String, price: UFix64, maxSupply: UInt64, reserved: UInt64, extra: {String: String}) {
            ChainzPack.createPackType(name: name, price: price, maxSupply: maxSupply, reserved: reserved, extra: extra)
        }

         pub fun togglePackTypeActive(id: UInt64) {
            ChainzPack.toggleActive(packTypeId: id)
        }

        pub fun reserveMintPack(packCollectionRef: &ChainzPack.Collection{ChainzPack.CollectionPublic}, packTypeId: UInt64) {
            ChainzPack.reserveMint(packCollectionRef: packCollectionRef, packTypeId: packTypeId)
        }

        // createAdmin
        // only an admin can ever create
        // a new Admin resource
        //
        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }

        init() {
            
        }
    }

    init() {
        self.AdminStoragePath = /storage/ChainzAdmin
        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}
 