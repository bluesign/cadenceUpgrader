import NonFungibleToken from 0x1d7e57aa55817448 //Mainnet address: 0x1d7e57aa55817448
import FungibleToken from 0xf233dcee88fe0abe //Mainnet address: 0xf233dcee88fe0abe
import MetadataViews from 0x1d7e57aa55817448 //Mainnet address: 0x1d7e57aa55817448
// TODO: change to your account which deploy ChainIDEShildNFT
import ChainIDEShieldNFT from "./ChainIDEShieldNFT.cdc"

pub contract ChainIDEShieldNFTMintContract {

    pub let AdminStoragePath: StoragePath
    pub var sale: Sale
    pub struct Sale {
        pub var price: UFix64
        pub var receiver: Address
        init(price: UFix64, receiver: Address){
            self.price = price
            self.receiver = receiver
        }
    }


    pub fun paymentMint(
        payment: @FungibleToken.Vault,
        amount: Int,
        recipient: &{NonFungibleToken.CollectionPublic}
    ){
        pre {
            amount <= 10: "amount should less equal than 10 in per mint"
            payment.balance == self.sale.price! * UFix64(amount): "payment vault does not contain requested price"
        }

        let receiver = getAccount(self.sale.receiver).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow()?? panic("Could not get receiver reference to Flow Token")
        receiver.deposit(from: <- payment)
        let minter = self.account.borrow<&ChainIDEShieldNFT.NFTMinter>(from: ChainIDEShieldNFT.MinterStoragePath)!
        var index = 0
        let types = ["bronze", "silver", "gold", "platinum"];
        while index < amount {
            minter.mintNFT(recipient: recipient, type: types[unsafeRandom() % 4])
            index = index + 1
        }
    }

    pub resource Administrator {
        pub fun setSale(price: UFix64, receiver: Address){
            ChainIDEShieldNFTMintContract.sale = Sale(price: price, receiver: receiver)
        }
    }

    init(price: UFix64, receiver: Address) {
        self.sale = Sale(price: price, receiver: receiver)
        self.AdminStoragePath = /storage/ChainIDEShieldNFTMintAdmin
        self.account.save(<- create Administrator(), to: self.AdminStoragePath)
    }
}
