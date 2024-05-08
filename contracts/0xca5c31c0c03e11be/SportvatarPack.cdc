import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import SportvatarTemplate from "./SportvatarTemplate.cdc"
import Sportbit from "./Sportbit.cdc"
import Crypto
import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"

/*

 This contract defines the Sportvatar Packs and a Collection to manage them.

 Each Pack will contain one item for each required Component (body, hair, eyes, nose, mouth, clothing),
 and two other Components that are optional (facial hair, accessory, hat, eyeglasses, background).

 Packs will be pre-minted and can be purchased from the contract owner's account by providing a
 verified signature that is different for each Pack (more info in the purchase function).

 Once purchased, packs cannot be re-sold and users will only be able to open them to receive
 the contained Components into their collection.

 */

pub contract SportvatarPack {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath

    // Counter for all the Packs ever minted
    pub var totalSupply: UInt64

    // Standard events that will be emitted
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Created(id: UInt64, prefix: String)
    pub event Opened(id: UInt64)
    pub event Purchased(id: UInt64)
    pub event Claimed(id: UInt64)

    // The public interface contains only the ID and the price of the Pack
    pub resource interface Public {
        pub let id: UInt64
        pub let price: UFix64
        pub let flameCount: UInt32
        pub let series: UInt32
        pub let name: String
    }

    // The Pack resource that implements the Public interface and that contains
    // different Components in a Dictionary
    pub resource Pack: Public {
        pub let id: UInt64
        pub let price: UFix64
        pub let flameCount: UInt32
        pub let series: UInt32
        pub let name: String
        access(account) let components: @[Sportbit.NFT]
        access(account) var randomString: String

        // Initializes the Pack with all the Components.
        // It receives also the price and a random String that will signed by
        // the account owner to validate the purchase process.
        init(
            components: @[Sportbit.NFT],
            randomString: String,
            price: UFix64,
            flameCount: UInt32,
            series: UInt32,
            name: String
        ) {

            // Makes sure that if it's set to have a flame component, this one is present in the array

            var flameCountCheck: UInt32 = 0
            if(flameCount > 0){
                var i: Int = 0
                while(i < components.length){
                    if(components[i].name == "Sport Flame" && components[i].getLayer() == UInt32(0)){
                        flameCountCheck = flameCountCheck + 1
                    }
                    i = i + 1
                }
            }

            if(flameCount != flameCountCheck){
                panic("There is a mismatch in the Sport Flame count")
            }




            // Increments the total supply counter
            SportvatarPack.totalSupply = SportvatarPack.totalSupply + UInt64(1)
            self.id = SportvatarPack.totalSupply

            // Moves all the components into the array
            self.components <- []
            while(components.length > 0){
                self.components.append(<- components.remove(at: 0))
            }

            destroy components

            // Sets the randomString text and the price
            self.randomString = randomString
            self.price = price
            self.flameCount = flameCount
            self.series = series
            self.name = name
        }

        destroy() {
            destroy self.components
        }

        // This function is used to retrieve the random string to match it
        // against the signature passed during the purchase process
        access(contract) fun getRandomString(): String {
            return self.randomString
        }

        // This function reset the randomString so that after the purchase nobody
        // will be able to re-use the verified signature
        access(contract) fun setRandomString(randomString: String) {
            self.randomString = randomString
        }

        pub fun removeComponent(at: Int): @Sportbit.NFT {
            return <- self.components.remove(at: at)
        }

    }

    //Pack CollectionPublic interface that allows users to purchase a Pack
    pub resource interface CollectionPublic {
        pub fun getIDs(): [UInt64]
        pub fun deposit(token: @SportvatarPack.Pack)
        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{SportvatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String, expectedPrice: UFix64)
        pub fun claimForFree(tokenId: UInt64, recipientCap: Capability<&{SportvatarPack.CollectionPublic}>, signature: String)
    }

    // Main Collection that implements the Public interface and that
    // will handle the purchase transactions
    pub resource Collection: CollectionPublic {
        // Dictionary of all the Packs owned
        access(account) let ownedPacks: @{UInt64: SportvatarPack.Pack}
        // Capability to send the FLOW tokens to the owner's account
        access(account) let ownerVault: Capability<&AnyResource{FungibleToken.Receiver}>

        // Initializes the Collection with the vault receiver capability
        init (ownerVault: Capability<&{FungibleToken.Receiver}>) {
            self.ownedPacks <- {}
            self.ownerVault = ownerVault
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedPacks.keys
        }

        // deposit takes a Pack and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @SportvatarPack.Pack) {
            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedPacks[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // withdraw removes a Pack from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @SportvatarPack.Pack {
            let token <- self.ownedPacks.remove(key: withdrawID) ?? panic("Missing Pack")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // This function allows any Pack owner to open the pack and receive its content
        // into the owner's Component Collection.
        // The pack is destroyed after the Components are delivered.
        pub fun openPack(id: UInt64) {

            // Gets the Component Collection Public capability to be able to
            // send there the Components contained in the Pack
            let recipientCap = self.owner!.getCapability<&{Sportbit.CollectionPublic}>(Sportbit.CollectionPublicPath)
            let recipient = recipientCap.borrow()!

            // Removed the pack from the collection
            let pack <- self.withdraw(withdrawID: id)

            // Removes all the components from the Pack and deposits them to the
            // Component Collection of the owner

            while(pack.components.length > 0){
                recipient.deposit(token: <- pack.removeComponent(at: 0))
            }

            // Emits the event to notify that the pack was opened
            emit Opened(id: pack.id)

            destroy pack
        }

        // Gets the price for a specific Pack
        access(account) fun getPrice(id: UInt64): UFix64 {
            let pack: &SportvatarPack.Pack = (&self.ownedPacks[id] as auth &SportvatarPack.Pack?)!
            return pack.price
        }

        // Gets the random String for a specific Pack
        access(account) fun getRandomString(id: UInt64): String {
            let pack: &SportvatarPack.Pack = (&self.ownedPacks[id] as auth &SportvatarPack.Pack?)!
            return pack.getRandomString()
        }

        // Sets the random String for a specific Pack
        access(account) fun setRandomString(id: UInt64, randomString: String) {
            let pack: &SportvatarPack.Pack = (&self.ownedPacks[id] as auth &SportvatarPack.Pack?)!
            pack.setRandomString(randomString: randomString)
        }


        // This function provides the ability for anyone to purchase a Pack
        // It receives as parameters the Pack ID, the Pack Collection Public capability to receive the pack,
        // a vault containing the necessary FLOW token, and finally a signature to validate the process.
        // The signature is generated off-chain by the smart contract's owner account using the Crypto library
        // to generate a hash from the original random String contained in each Pack.
        // This will guarantee that the contract owner will be able to decide which user can buy a pack, by
        // providing them the correct signature.
        //
        //
        pub fun purchase(tokenId: UInt64, recipientCap: Capability<&{SportvatarPack.CollectionPublic}>, buyTokens: @FungibleToken.Vault, signature: String, expectedPrice: UFix64) {

            // Checks that the pack is still available and that the FLOW tokens are sufficient
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) <= buyTokens.balance : "Not enough tokens to buy the Pack!"
                self.getPrice(id: tokenId) == expectedPrice : "Price not set as expected!"
                buyTokens.isInstance(Type<@DapperUtilityCoin.Vault>()) : "Vault not of the right Token Type"
            }

            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: self.getRandomString(id: tokenId).utf8)){
                panic("Unable to validate the signature for the pack!")
            }


            // Borrows the recipient's capability and withdraws the Pack from the collection.
            // If this fails the transaction will revert but the signature will be exposed.
            // For this reason in case it happens, the randomString will be reset when the purchase
            // reservation timeout expires by the web server back-end.
            let recipient = recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)

            // Borrows the owner's capability for the Vault and deposits the DUC tokens
            // mainnet F Address: 0x8a86f18e0e05bd9f
            // testnet S Address: 0x6f13cacd9e8bfdd1
            let dapperMarketVault = getAccount(0x8a86f18e0e05bd9f).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            let vaultRef = dapperMarketVault.borrow() ?? panic("Could not borrow reference to owner pack vault")
            vaultRef.deposit(from: <-buyTokens)


            // Resets the randomString so that the provided signature will become useless
            let packId: UInt64 = pack.id
            pack.setRandomString(randomString: unsafeRandom().toString())

            // Deposits the Pack to the recipient's collection
            recipient.deposit(token: <- pack)

            // Emits an even to notify about the purchase
            emit Purchased(id: packId)
        }

        // This function provides the ability for anyone to claim a Pack for free
        // It receives as parameters the Pack ID, the Pack Collection Public capability to receive the pack and
        // a signature to validate the process.
        // The signature is generated off-chain by the smart contract's owner account using the Crypto library
        // to generate a hash from the original random String contained in each Pack.
        // This will guarantee that the contract owner will be able to decide which user can buy a pack, by
        // providing them the correct signature.
        //
        //
        pub fun claimForFree(tokenId: UInt64, recipientCap: Capability<&{SportvatarPack.CollectionPublic}>, signature: String) {

            // Checks that the pack is still available and that the FLOW tokens are sufficient
            pre {
                self.ownedPacks.containsKey(tokenId) == true : "Pack not found!"
                self.getPrice(id: tokenId) == UFix64(0.0) : "Price not set as expected!"
            }

            // Gets the Crypto.KeyList and the public key of the collection's owner
            let keyList = Crypto.KeyList()
            let accountKey = self.owner!.keys.get(keyIndex: 0)!.publicKey

            // Adds the public key to the keyList
            keyList.add(
                PublicKey(
                    publicKey: accountKey.publicKey,
                    signatureAlgorithm: accountKey.signatureAlgorithm
                ),
                hashAlgorithm: HashAlgorithm.SHA3_256,
                weight: 1.0
            )

            // Creates a Crypto.KeyListSignature from the signature provided in the parameters
            let signatureSet: [Crypto.KeyListSignature] = []
            signatureSet.append(
                Crypto.KeyListSignature(
                    keyIndex: 0,
                    signature: signature.decodeHex()
                )
            )

            // Verifies that the signature is valid and that it was generated from the
            // owner of the collection
            if(!keyList.verify(signatureSet: signatureSet, signedData: self.getRandomString(id: tokenId).utf8)){
                panic("Unable to validate the signature for the pack!")
            }


            // Borrows the recipient's capability and withdraws the Pack from the collection.
            // If this fails the transaction will revert but the signature will be exposed.
            // For this reason in case it happens, the randomString will be reset when the purchase
            // reservation timeout expires by the web server back-end.
            let recipient = recipientCap.borrow()!
            let pack <- self.withdraw(withdrawID: tokenId)

            // Resets the randomString so that the provided signature will become useless
            let packId: UInt64 = pack.id
            pack.setRandomString(randomString: unsafeRandom().toString())

            // Deposits the Pack to the recipient's collection
            recipient.deposit(token: <- pack)

            // Emits an even to notify about the purchase
            emit Claimed(id: packId)
        }

        destroy() {
            destroy self.ownedPacks
        }
    }



    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @SportvatarPack.Collection {
        let ownerVault: Capability<&{FungibleToken.Receiver}> =  self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        return <- create Collection(ownerVault: ownerVault)
    }

    // Get all the packs from a specific account
    pub fun getPacks(address: Address) : [UInt64]? {

        let account = getAccount(address)

        if let packCollection = account.getCapability(self.CollectionPublicPath).borrow<&{SportvatarPack.CollectionPublic}>()  {
            return packCollection.getIDs();
        }
        return nil
    }

    pub fun checkPackAvailable(id: UInt64): Bool {
        if let packCollection = self.account.getCapability(self.CollectionPublicPath).borrow<&{SportvatarPack.CollectionPublic}>()  {
            let packIds: [UInt64] = packCollection.getIDs();
            return packIds.contains(id)
        }
        return false
    }



    // This method can only be called from another contract in the same account (The Sportvatar Admin resource)
    // It creates a new pack from a list of Components, the random String and the price.
    // Some Components are required and others are optional
    access(account) fun createPack(
            components: @[Sportbit.NFT],
            randomString: String,
            price: UFix64,
            flameCount: UInt32,
            series: UInt32,
            name: String
        ) : @SportvatarPack.Pack {

        var newPack <- create Pack(
            components: <-components,
            randomString: randomString,
            price: price,
            flameCount: flameCount,
            series: series,
            name: name
        )

        // Emits an event to notify that a Pack was created.
        // Sends the first 4 digits of the randomString to be able to sync the ID with the off-chain DB
        // that will store also the signatures once they are generated
        emit Created(id: newPack.id, prefix: randomString.slice(from: 0, upTo: 5))

        return <- newPack
    }

	init() {
        let wallet =  getAccount(0x8a86f18e0e05bd9f).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)

        self.CollectionPublicPath=/public/SportvatarPackCollection
        self.CollectionStoragePath=/storage/SportvatarPackCollection

        // Initialize the total supply
        self.totalSupply = 0

        self.account.save<@SportvatarPack.Collection>(<- SportvatarPack.createEmptyCollection(), to: SportvatarPack.CollectionStoragePath)
        self.account.link<&SportvatarPack.Collection{SportvatarPack.CollectionPublic}>(SportvatarPack.CollectionPublicPath, target: SportvatarPack.CollectionStoragePath)

        emit ContractInitialized()
	}
}

