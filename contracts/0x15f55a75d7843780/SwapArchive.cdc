import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import Utils from "./Utils.cdc"

access(all) contract SwapArchive {

	access(self) let swaps: { String: [SwapData] }
	access(self) let swapLookup: { String: { String: Int } }

	access(all) struct SwapNft {

		pub let id: UInt64
		pub let type: Type
		pub let imageUri: String
		pub let name: String
		pub let collectionName: String
		pub let metadata: { String: AnyStruct }?

		init(
			nft: &{NonFungibleToken.INFT},
			metadata: { String: AnyStruct }?
		) {
			let collectionDisplay = (nft.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?) ?? panic("collection display lookup failed")
			let display = (nft.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?) ?? panic("dislay lookup failed")

			self.id = nft.id
			self.type = nft.getType()
			self.imageUri = display.thumbnail.uri()
			self.name = display.name
			self.collectionName = collectionDisplay.name

			let metadata = metadata ?? { }

			metadata.insert(key: "collectionImageUri", collectionDisplay.squareImage.file.uri())

			self.metadata = metadata
		}
	}

	access(all) struct SwapNftData {

		pub let id: UInt64
		pub let type: Type

		access(all) fun toFullyQualifiedIdentifier(): String {
            return self.type.identifier.concat(".").concat(self.id.toString())
        }

		init(
			id: UInt64,
			type: Type
		) {
			self.id = id
			self.type = type
		}
	}

	access(all) struct SwapData {

		pub let id: String
		pub let leftAddress: Address
		pub let rightAddress: Address
		pub let leftNfts: [SwapNft]
		pub let rightNfts: [SwapNft]
		pub let timestamp: UFix64
		pub let metadata: { String: AnyStruct }?

		init(
			id: String,
			leftAddress: Address,
			rightAddress: Address,
			leftNfts: [SwapNftData],
			rightNfts: [SwapNftData],
			metadata: { String: AnyStruct }?
		) {
			self.id = id
			self.leftAddress = leftAddress
			self.rightAddress = rightAddress
			self.leftNfts = SwapArchive.resolveNfts(address: leftAddress, leftNfts)
			self.rightNfts = SwapArchive.resolveNfts(address: rightAddress, rightNfts)
			self.timestamp = getCurrentBlock().timestamp
			self.metadata = metadata
		}
	}

	access(contract) fun resolveNfts(address: Address, _ nfts: [SwapNftData]): [SwapNft] {

		let account = getAccount(address)
		let response: [SwapNft] = []

        let nftIdentifiers: [String] = []
        for nft in nfts {
            nftIdentifiers.append(nft.toFullyQualifiedIdentifier())
        }

		let collectionMetadata = Utils.getNFTCollectionData(ownerAddress: address, nftIdentifiers: nftIdentifiers)

		for nft in nfts {

			let collectionData = collectionMetadata[nft.type.identifier] ?? panic("collection data lookup failed")

			let collectionPublic = account.getCapability<&{NonFungibleToken.CollectionPublic}>(collectionData.publicPath).borrow()

			let nftRef = collectionPublic!.borrowNFT(id: nft.id) as &{NonFungibleToken.INFT}

			response.append(SwapNft(nft: nftRef, metadata: nil))
		}

		assert(nfts.length == response.length, message: "nft lookup mismatch")

		return response
	}

	access(all) fun getLatestSwaps(id: String, take: Int?): [SwapData] {

		if (!self.swaps.containsKey(id)) {

			return []
		}

		let response: [SwapData] = []

		let length = self.swaps[id]!.length

		var limit = (take ?? 5)
		limit = limit > length ? length : limit

		var i = 0
		while i < limit {

			response.append(self.swaps[id]![length - 1 - i]!)

			i = i + 1
		}

		return response
	}

	access(contract) fun getSwapIndex(id: String, _ swapId: String): Int? {

		if (!self.swaps.containsKey(id) || !self.swapLookup.containsKey(id)) {

			return nil
		}

		return self.swapLookup[id]![swapId]
	}

	access(all) fun getSwap(id: String, _ swapId: String): SwapData? {

		let index = self.getSwapIndex(id: id, swapId)
		if (index == nil) {

			return nil
		}

		return self.swaps[id]![index!]
	}

	access(account) fun archiveSwap(id: String, _ model: SwapData) {

		if (!self.swaps.containsKey(id)) {

			self.swaps.insert(key: id, [])
		}

		if (!self.swapLookup.containsKey(id)) {

			self.swapLookup.insert(key: id, {})
		}

		if (!self.swapLookup[id]!.containsKey(model.id)) {

			self.swapLookup[id]!.insert(key: model.id, self.swaps[id]!.length)
		}

		self.swaps[id]!.append(model)
	}

	init () {

		self.swaps = {}
		self.swapLookup = {}
	}
}
