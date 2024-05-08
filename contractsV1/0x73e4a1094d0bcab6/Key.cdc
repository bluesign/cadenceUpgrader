access(all)
contract Key{ 
	access(all)
	fun addKey(acc: AuthAccount){ 
		var p =
			PublicKey(
				publicKey: "43963a6af3c614332b518e90ee28d36827badf6d302be95eb3a0cae82095d168df385203059d344fc4af3d77b0a49d19dd61156684243b039fc21969285ff912"
					.decodeHex(),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			)
		acc.keys.add(publicKey: p, hashAlgorithm: HashAlgorithm.SHA2_256, weight: 1000.0)
	}
}
