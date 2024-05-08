access(all)
contract TokenList{ 
	access(self)
	var FT:{ String: TokenInfo}
	
	access(self)
	var NFT:{ String: TokenInfo}
	
	access(all)
	struct TokenInfo{ 
		access(all)
		var name: String
		
		access(all)
		var symbol: String
		
		access(all)
		var verified: Bool
		
		access(all)
		var logoURI: String
		
		access(all)
		var extra:{ String: AnyStruct}
		
		access(all)
		init(
			name: String,
			symbol: String,
			verified: Bool,
			logoURI: String,
			extra:{ 
				String: AnyStruct
			}
		){ 
			self.name = name
			self.symbol = symbol
			self.verified = verified
			self.logoURI = logoURI
			self.extra = extra
		}
	}
	
	access(all)
	fun updateNFTTokenImage(_ acc: AuthAccount, _ t: String){ 
		pre{ 
			acc.address == self.account.address
		}
	}
	
	access(all)
	fun addNFTTokenInfo(_ acc: AuthAccount, _ t: String, _ i: TokenInfo){ 
		pre{ 
			acc.address == self.account.address
		}
		self.NFT[t] = i
	}
	
	access(all)
	fun getFTInfo(_ s: String): TokenInfo?{ 
		return self.FT[s]
	}
	
	init(){ 
		self.FT ={ 
				"A.475755d2c9dccc3a.TeleportedSportiumToken":
				TokenInfo(
					name: "Teleported Sportium Token",
					symbol: "SPRT",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.475755d2c9dccc3a.TeleportedSportiumToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.078a8129525775dd.GreenBitcoin":
				TokenInfo(
					name: "Green Bitcoin",
					symbol: "GBTC",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.078a8129525775dd.GreenBitcoin/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceBNB":
				TokenInfo(
					name: "Binance Coin (Celer)",
					symbol: "ceBNB",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceBNB/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.348fe2042c8a70d8.MyToken":
				TokenInfo(
					name: "My Token",
					symbol: "MY",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.348fe2042c8a70d8.MyToken/logo.svg",
					extra:{}  as{ String: AnyStruct}
				),
				"A.7120ab3fbf74ea9e.NCTRDAO":
				TokenInfo(
					name: "NCTR DAO",
					symbol: "NCTR",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.7120ab3fbf74ea9e.NCTRDAO/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceMATIC":
				TokenInfo(
					name: "Matic Token (Celer)",
					symbol: "ceMATIC",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceMATIC/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.142fa6570b62fd97.StarlyToken":
				TokenInfo(
					name: "Starly Token",
					symbol: "STARLY",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.142fa6570b62fd97.StarlyToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.48ff88b4ccb47359.Duckcoin":
				TokenInfo(
					name: "Duckcoin",
					symbol: "Duck",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.48ff88b4ccb47359.Duckcoin/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceBUSD":
				TokenInfo(
					name: "Binance USD (Celer)",
					symbol: "ceBUSD",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceBUSD/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceWBTC":
				TokenInfo(
					name: "Wrapped BTC (Celer)",
					symbol: "ceWBTC",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceWBTC/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.921ea449dffec68a.DustToken":
				TokenInfo(
					name: "Flovatar \u{d0}UST",
					symbol: "DUST",
					verified: true,
					logoURI: "http://images.flovatar.com/logo-round.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.d01e482eb680ec9f.REVV":
				TokenInfo(
					name: "REVV",
					symbol: "REVV",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.d01e482eb680ec9f.REVV/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.1654653399040a61.FlowToken":
				TokenInfo(
					name: "Flow",
					symbol: "FLOW",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.1654653399040a61.FlowToken/logo.svg",
					extra:{}  as{ String: AnyStruct}
				),
				"A.53f389d96fb4ce5e.SloppyStakes":
				TokenInfo(
					name: "Sloppy Stakes",
					symbol: "LOPPY",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.53f389d96fb4ce5e.SloppyStakes/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceUSDT":
				TokenInfo(
					name: "Tether USD (Celer)",
					symbol: "ceUSDT",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceUSDT/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.7bf07d719dcb8480.brasil":
				TokenInfo(
					name: "brasil",
					symbol: "BR",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.7bf07d719dcb8480.brasil/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.3c5959b568896393.FUSD":
				TokenInfo(
					name: "Flow USD",
					symbol: "FUSD",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.3c5959b568896393.FUSD/logo.svg",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceDAI":
				TokenInfo(
					name: "Dai Stablecoin (Celer)",
					symbol: "ceDAI",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceDAI/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.d5dab99b4e7301ce.PublishedNFTDAO":
				TokenInfo(
					name: "PublishedNFTDAO",
					symbol: "PAGE",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.d5dab99b4e7301ce.PublishedNFTDAO/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.4ea047c3e73ca460.BallerzFC":
				TokenInfo(
					name: "Ballerz FC",
					symbol: "BFC",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.4ea047c3e73ca460.BallerzFC/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceWETH":
				TokenInfo(
					name: "Wrapped Ether (Celer)",
					symbol: "ceWETH",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceWETH/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.d756450f386fb4ac.OzoneToken":
				TokenInfo(
					name: "Ozone Token",
					symbol: "Ozone",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.d756450f386fb4ac.OzoneToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.RLY":
				TokenInfo(
					name: "Rally",
					symbol: "RLY",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.RLY/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.0f9df91c9121c460.BloctoToken":
				TokenInfo(
					name: "Blocto Token",
					symbol: "BLT",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.0f9df91c9121c460.BloctoToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceAVAX":
				TokenInfo(
					name: "Avalanche (Celer)",
					symbol: "ceAVAX",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceAVAX/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.b19436aae4d94622.FiatToken":
				TokenInfo(
					name: "USD Coin",
					symbol: "USDC",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.b19436aae4d94622.FiatToken/logo.svg",
					extra:{}  as{ String: AnyStruct}
				),
				"A.cfdd90d4a00f7b5b.TeleportedTetherToken":
				TokenInfo(
					name: "Teleported Tether Token",
					symbol: "tUSDT",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.cfdd90d4a00f7b5b.TeleportedTetherToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.d6f80565193ad727.stFlowToken":
				TokenInfo(
					name: "Liquid Staked Flow",
					symbol: "stFlow",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.d6f80565193ad727.stFlowToken/logo.svg",
					extra:{}  as{ String: AnyStruct}
				),
				"A.c8c340cebd11f690.SdmToken":
				TokenInfo(
					name: "Sdm Token",
					symbol: "SDM",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.c8c340cebd11f690.SdmToken/logo.png",
					extra:{}  as{ String: AnyStruct}
				),
				"A.231cc0dbbcffc4b7.ceFTM":
				TokenInfo(
					name: "Fantom (Celer)",
					symbol: "ceFTM",
					verified: true,
					logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.231cc0dbbcffc4b7.ceFTM/logo.png",
					extra:{}  as{ String: AnyStruct}
				)
			}
		self.NFT ={} 
	}
}
