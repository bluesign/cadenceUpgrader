/**
> Reference: https://github.com/onflow/flow-cadence-eth-utils

# ETHUtils

*/

access(all) contract ETHUtils {
    /// Verify a EVM signature from a message using a public key
    ///
    access(all) fun verifySignature(hexPublicKey: String, hexSignature: String, message: String) : Bool {
        let decodedHexPublicKey = hexPublicKey.decodeHex()
        let decodedHexSignature = hexSignature.decodeHex()

        let ethereumMessagePrefix: String = "\u{0019}Ethereum Signed Message:\n".concat(message.length.toString())
        let fullMessage: String = ethereumMessagePrefix.concat(message)

        let publicKey = PublicKey(
            publicKey: decodedHexPublicKey,
            signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1
        )

        let isValid = publicKey.verify(
            signature: decodedHexSignature,
            signedData: fullMessage.utf8,
            domainSeparationTag: "",
            hashAlgorithm: HashAlgorithm.KECCAK_256
        )

        return isValid
    }

    /// Get the EVM address from a public key
    ///
    access(all) fun getETHAddressFromPublicKey(hexPublicKey: String) : String {
        let decodedHexPublicKey = hexPublicKey.decodeHex()
        let digest = HashAlgorithm.KECCAK_256.hash(decodedHexPublicKey)
        let hexDigest = String.encodeHex(digest)
        let ethAddress = "0x".concat(hexDigest.slice(from: hexDigest.length-40, upTo: hexDigest.length))
        return ethAddress.toLower()
    }
}
