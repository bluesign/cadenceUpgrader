import MIKOSEANFTV2 from "./MIKOSEANFTV2.cdc"
import MIKOSEANFT from "./MIKOSEANFT.cdc"
import MikoSeaMarket from "./MikoSeaMarket.cdc"
import MikoSeaNFTMetadata from "./MikoSeaNFTMetadata.cdc"

pub contract MikoSeaUtility {
    // rate transform from yen to usd, ex: {"USD_TO_JPY": 171.2}
    pub var ratePrice: {String:UFix64}
    access(self) var metadata: {String:String}

    pub let AdminStoragePath: StoragePath
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // is not in used
    pub struct NFTDataCommon { }
    pub struct NFTDataWithListing { }

    pub struct NFTDataCommonWithListing {
        pub let id: UInt64
        pub let serialNumber: UInt64
        pub let image: String
        pub let name: String
        pub let nftMetadata: {String:String}
        pub let nftType: String

        pub let projectId: UInt64
        pub let projectTitle: String
        pub let projectDescription: String
        pub let flowProjectId: UInt64
        pub let projectMaxSupply: UInt64
        pub let isNFTReveal: Bool

        pub let blockHeight: UInt64
        pub let holder: Address
        pub let isInMarket: Bool
        pub let listingId: UInt64?

        init(id: UInt64,
        serialNumber: UInt64,
        name: String,
        image: String,
        nftMetadata: {String:String},
        projectId: UInt64,
        isNFTReveal: Bool,
        projectTitle: String,
        projectDescription: String,
        maxSupply: UInt64,
        blockHeight: UInt64,
        holder: Address,
        listingId: UInt64?,
        nftType: String
        ){
            self.id = id
            self.serialNumber = serialNumber
            self.projectId = projectId
            self.flowProjectId = projectId
            self.image = image
            self.isNFTReveal = isNFTReveal
            self.projectTitle = projectTitle
            self.projectDescription = projectDescription
            self.name = name
            self.nftMetadata = nftMetadata
            self.blockHeight = blockHeight
            self.projectMaxSupply = maxSupply
            self.holder = holder
            self.isInMarket = listingId != nil
            self.listingId = listingId
            self.nftType = nftType
        }
    }

    pub fun yenToDollar(yen: UFix64): UFix64 {
        if MikoSeaUtility.ratePrice["USD_TO_JPY"] == nil {
        return 0.0
        }
        if MikoSeaUtility.ratePrice["USD_TO_JPY"]! <= 0.0 {
        return 0.0
        }
        return yen / MikoSeaUtility.ratePrice["USD_TO_JPY"]!
    }

    pub resource Admin {
        pub fun updateRate(key: String, value: UFix64) {
            MikoSeaUtility.ratePrice[key] = value
        }
    }

    pub fun floor(_ num: Fix64): Int {
        var strRes = ""
        var numStr = num.toString()
        var i = 0;
        while i < numStr.length {
            if numStr[i] == "." {
                break;
            }
            strRes = strRes.concat(numStr.slice(from: i, upTo: i + 1))
            i = i + 1
        }
        let numInt = Int.fromString(strRes) ?? 0
        if Fix64(numInt) == num {
            return numInt
        }
        if num >= 0.0 {
            return numInt
        }
        return numInt - 1
    }

    pub fun getListingId(addr: Address, nftType: Type, nftID: UInt64): UInt64? {
        if let ref = getAccount(addr).getCapability<&{MikoSeaMarket.StorefrontPublic}>(MikoSeaMarket.MarketPublicPath).borrow() {
            for order in ref.getOrders() {
                if nftID == order.nftID && order.nftType == nftType && order.status != "done" {
                    return order.getId()
                }
            }
        }
        return nil
    }

    pub fun getNftV2Detail(_ nftID: UInt64): NFTDataCommonWithListing? {
        if let addr = MIKOSEANFTV2.getHolder(nftID: nftID) {
            let account = getAccount(addr)
            let collectioncap = account.getCapability<&{MIKOSEANFTV2.CollectionPublic}>(MIKOSEANFTV2.CollectionPublicPath)
            if let collectionRef = collectioncap.borrow() {
                if let nft = collectionRef.borrowMIKOSEANFTV2(id: nftID) {
                    let project = MIKOSEANFTV2.getProjectById(nft.nftData.projectId)!
                    return NFTDataCommonWithListing(
                        id: nft.id,
                        serialNumber: nft.nftData.serialNumber,
                        name: nft.getMetadata()["name"] ?? "",
                        image: nft.getImage(),
                        nftMetadata: nft.getMetadata(),
                        projectId: project.projectId,
                        isNFTReveal: project.isReveal,
                        projectTitle: nft.getTitle(),
                        projectDescription: nft.getDescription(),
                        maxSupply: project.maxSupply,
                        blockHeight: nft.nftData.blockHeight,
                        holder: addr,
                        listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id),
                        nftType: "mikoseav2"
                    )
                }
            }
        }
        return nil
    }

    pub fun getNftV1Detail(addr: Address, nftID: UInt64): NFTDataCommonWithListing? {
        let account = getAccount(addr)
        let collectionCapability = account.getCapability<&{MIKOSEANFT.MikoSeaCollectionPublic}>(MIKOSEANFT.CollectionPublicPath)
        let collectionRef = collectionCapability.borrow()
        if let collectionRef = collectionCapability.borrow() {
            if let nft = collectionRef.borrowMiKoSeaNFT(id: nftID) {
                let listingId= MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id)
                return NFTDataCommonWithListing(
                    id: nft.id,
                    serialNumber: nft.data.mintNumber,
                    name: nft.getTitle(),
                    image: nft.getImage(),
                    nftMetadata: MikoSeaNFTMetadata.getNFTMetadata(nftType: "mikosea", nftID: nft.id) ?? {},
                    projectId: nft.data.projectId,
                    isNFTReveal: true,
                    projectTitle: nft.getTitle(),
                    projectDescription: nft.getDescription(),
                    maxSupply: MIKOSEANFT.getProjectTotalSupply(nft.data.projectId),
                    blockHeight: 0,
                    holder: addr,
                    listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFT.NFT>(), nftID: nft.id),
                    nftType: "mikosea"
                )
            }
        }
        return nil
    }

    pub fun parseNftV2List(_ nfts: [&MIKOSEANFTV2.NFT]): [NFTDataCommonWithListing] {
        let projects: {UInt64: &MIKOSEANFTV2.ProjectData} = {}
        let response: [NFTDataCommonWithListing] = []
        for nft in nfts {
            if projects[nft.nftData.projectId] == nil {
                projects[nft.nftData.projectId] = MIKOSEANFTV2.getProjectById(nft.nftData.projectId)!
            }
            let project = projects[nft.nftData.projectId]!
            if let addr = MIKOSEANFTV2.getHolder(nftID: nft.id) {
                let listingId= MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id)
                response.append(
                    NFTDataCommonWithListing(
                        id: nft.id,
                        serialNumber: nft.nftData.serialNumber,
                        name: nft.getMetadata()["name"] ?? "",
                        image: nft.getImage(),
                        nftMetadata: nft.getMetadata(),
                        projectId: project.projectId,
                        isNFTReveal: project.isReveal,
                        projectTitle: nft.getTitle(),
                        projectDescription: nft.getDescription(),
                        maxSupply: project.maxSupply,
                        blockHeight: nft.nftData.blockHeight,
                        holder: addr,
                        listingId: MikoSeaUtility.getListingId(addr: addr, nftType: Type<@MIKOSEANFTV2.NFT>(), nftID: nft.id),
                        nftType: "mikoseav2"
                    )
                )
            }
        }
        return response
    }

    init() {
        self.AdminStoragePath = /storage/MikoSeaUtilityAdminStoragePath
        self.CollectionStoragePath = /storage/MikoSeaUtilityCollectionStoragePath
        self.CollectionPublicPath = /public/MikoSeaUtilityCollectionPublicPath

        self.ratePrice = {
            "USD_TO_JPY": 130.75
        }
        self.metadata = { }

        // Put the Admin in storage
        self.account.save(<- create Admin(), to: self.AdminStoragePath)
    }
}
