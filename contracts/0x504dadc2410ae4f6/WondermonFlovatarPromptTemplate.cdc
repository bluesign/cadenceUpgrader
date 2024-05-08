pub contract WondermonFlovatarPromptTemplate {

    pub event ContractInitialized()

    pub event PromptTemplateSet(flovatarId: UInt64)
    pub event PromptTemplateRemoved(flovatarId: UInt64)
    pub event DefaultPromptTemplateSet()

    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath
    pub let AdminPrivatePath: PrivatePath

    pub let promptTemplates: {UInt64: String}
    pub var defaultPrompt: String

    pub resource Admin {

        pub fun setTemplate(flovatarId: UInt64, template: String) {
            WondermonFlovatarPromptTemplate.promptTemplates.insert(key: flovatarId, template)
            emit PromptTemplateSet(flovatarId: flovatarId)
        }

        pub fun removeTemplate(flovatarId: UInt64) {
            WondermonFlovatarPromptTemplate.promptTemplates.remove(key: flovatarId)
            emit PromptTemplateRemoved(flovatarId: flovatarId)
        }

        pub fun setDefaultTemplate(_ template: String) {
            WondermonFlovatarPromptTemplate.defaultPrompt = template
            emit DefaultPromptTemplateSet()
        }
    }

    pub fun getPromptTemplate(flovatarId: UInt64): String {
        return self.promptTemplates[flovatarId] ?? self.defaultPrompt
    }

    init() {
        self.promptTemplates = {}
        self.defaultPrompt = ""

        self.AdminStoragePath = /storage/WondermonFlovatarPromptTemplateAdmin
        self.AdminPublicPath = /public/WondermonFlovatarPromptTemplateAdmin
        self.AdminPrivatePath = /private/WondermonFlovatarPromptTemplateAdmin

        self.account.save(<- create Admin(), to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}