// Welcome to the EmeraldIdentity contract!
//
// This contract is a service that maps a user's on-chain 
// SHADOW address to their DiscordID. 
//
// A user cannot configure their own EmeraldID. It must be done 
// by someone who has access to the Administrator resource.
//
// A user can only ever have 1 address mapped to 1 DiscordID, and
// 1 DiscordID mapped to 1 address. This means you cannot configure
// multiple addresses to your DiscordID, and you cannot configure
// multiple DiscordIDs to your address. 1-1.

pub contract EmeraldIdentityShadow {

    //
    // Paths
    //
    pub let AdministratorStoragePath: StoragePath
    pub let AdministratorPrivatePath: PrivatePath

    //
    // Events
    //
    pub event EmeraldIDCreated(account: Address, discordID: String)
    pub event EmeraldIDRemoved(account: Address, discordID: String)
    
    //
    // Administrator
    //
    pub resource Administrator {
        // 1-to-1
        access(account) var accountToDiscord: {Address: String}
        // 1-to-1
        access(account) var discordToAccount: {String: Address}

        pub fun createEmeraldID(account: Address, discordID: String) {
            pre {
                EmeraldIdentityShadow.getAccountFromDiscord(discordID: discordID) == nil:
                    "The old discordID must remove their EmeraldID first."
                EmeraldIdentityShadow.getDiscordFromAccount(account: account) == nil: 
                    "The old account must remove their EmeraldID first."
            }

            self.accountToDiscord[account] = discordID
            self.discordToAccount[discordID] = account

            emit EmeraldIDCreated(account: account, discordID: discordID)
        }

        pub fun removeByAccount(account: Address) {
            let discordID = EmeraldIdentityShadow.getDiscordFromAccount(account: account) ?? panic("This EmeraldID does not exist!")
            self.remove(account: account, discordID: discordID)
        }

        pub fun removeByDiscord(discordID: String) {
            let account = EmeraldIdentityShadow.getAccountFromDiscord(discordID: discordID) ?? panic("This EmeraldID does not exist!")
            self.remove(account: account, discordID: discordID)
        }

        access(self) fun remove(account: Address, discordID: String) {
            self.discordToAccount.remove(key: discordID)
            self.accountToDiscord.remove(key: account)

            emit EmeraldIDRemoved(account: account, discordID: discordID)
        }

        pub fun createAdministrator(): Capability<&Administrator> {
            return EmeraldIdentityShadow.account.getCapability<&Administrator>(EmeraldIdentityShadow.AdministratorPrivatePath)
        }

        init() {
            self.accountToDiscord = {}
            self.discordToAccount = {}
        }
    }

    /*** USE THE BELOW FUNCTIONS FOR SECURE VERIFICATION OF ID ***/ 

    pub fun getDiscordFromAccount(account: Address): String?  {
        let admin = EmeraldIdentityShadow.account.borrow<&Administrator>(from: EmeraldIdentityShadow.AdministratorStoragePath)!
        return admin.accountToDiscord[account]
    }

    pub fun getAccountFromDiscord(discordID: String): Address? {
        let admin = EmeraldIdentityShadow.account.borrow<&Administrator>(from: EmeraldIdentityShadow.AdministratorStoragePath)!
        return admin.discordToAccount[discordID]
    }

    init() {
        self.AdministratorStoragePath = /storage/EmeraldIDShadowAdministrator
        self.AdministratorPrivatePath = /private/EmeraldIDShadowAdministrator

        self.account.save(<- create Administrator(), to: EmeraldIdentityShadow.AdministratorStoragePath)
        self.account.link<&Administrator>(EmeraldIdentityShadow.AdministratorPrivatePath, target: EmeraldIdentityShadow.AdministratorStoragePath)
    }
}