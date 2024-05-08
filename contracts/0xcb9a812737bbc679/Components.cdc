pub contract Components {

    pub let AdminPath: StoragePath

    pub struct Colors {
        pub let accessories: String
        pub let clothing: String
        pub let hair: String
        pub let hat: String
        pub let facialHair: String
        pub let background: String
        pub let skin: String

        init(_ accessories: String, _ clothing: String, _ hair: String, _ hat: String, _ facialHair: String, _ bg: String, _ skin: String) {
            self.accessories = accessories
            self.clothing = clothing
            self.hair = hair
            self.hat = hat
            self.facialHair = facialHair
            self.background = bg
            self.skin = skin
        }
    }

    pub struct interface Component {
        pub let name: String
        pub fun build(components: {String: {Component}}, colors: Colors): String
    }

    pub struct Accessories: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "accessories_".concat(self.name))!)
                ?? panic("accessory not found")
            switch self.name {
                case "eyepatch":
                    return content[0]
                default:
                    return content[0].concat(colors.accessories).concat(content[1])
            }
        }

        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Clothing: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "clothing_".concat(self.name))!)
                ?? panic("clothing not found")
            switch self.name {
                case "graphicShirt":
                    if let graphic = components["clothingGraphic"] {
                        return content[0].concat(colors.clothing).concat(content[1]).concat(graphic.build(components: components, colors: colors)).concat(content[2])
                    }

                    return content[0].concat(colors.clothing).concat(content[1])
                default:
                    return content[0].concat(colors.clothing).concat(content[1])
            }
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct ClothingGraphic: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "clothingGraphic_".concat(self.name))!)
                ?? panic("clothing not found")
            return content[0]
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Eyebrows: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "eyebrows_".concat(self.name))!)
                ?? panic("eyebrows not found")
            return content[0]
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Eyes: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "eyes_".concat(self.name))!)
                ?? panic("eyes not found")
            return content[0]
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct FacialHair: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "facialHair_".concat(self.name))!)
                ?? panic("facialHair not found")
            return content[0].concat(colors.facialHair).concat(content[1])
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Mouth: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "mouth_".concat(self.name))!)
                ?? panic("mouth not found")
            return content[0]
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Nose: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "nose_".concat(self.name))!)
                ?? panic("nose not found")
            return content[0]
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Style: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "style_".concat(self.name))!)
                ?? panic("style not found")
            let base = components["base"]!.build(components: components, colors: colors)
            switch self.name {
                case "circle":
                    return content[0].concat(colors.background).concat(content[1]).concat(base).concat(content[2])
                case "default":
                    return base
            }

            return ""
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Top: Component {
        pub let name: String

        pub fun build(components: {String: {Component}}, colors: Colors): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "top_".concat(self.name))!)
                ?? panic("top not found")
            
            switch self.name {
                case "hat":
                    return content[0].concat(colors.hat).concat(content[1])
                case "hijab":
                    return content[0].concat(colors.hat).concat(content[1])
                case "turban":
                    return content[0].concat(colors.hat).concat(content[1])
                case "winterHat1":
                    return content[0].concat(colors.hat).concat(content[1])
                case "winterHat2":
                    return content[0].concat(colors.hat).concat(content[1])
                case "winterHat3":
                    return content[0].concat(colors.hat).concat(content[1])
                case "winterHat4":
                    return content[0].concat(colors.hat).concat(content[1])
                default:
                    return content[0].concat(colors.hair).concat(content[1])
            }
        }
        
        init(_ n: String) {
            self.name = n
        }
    }

    pub struct Renderer {
        pub let components: {String: {Component}}
        pub let colors: Colors
        pub let flattened: {String: String}

        pub fun build(): String {
            let content = Components.account.borrow<&[String]>(from: StoragePath(identifier: "base_".concat("default"))!)
                ?? panic("base not found")
            
            let document = Components.account.borrow<&[String]>(from: StoragePath(identifier: "document_default")!)
                ?? panic("document not found")

            let tmp = content[0]
                .concat(self.colors.skin)
                .concat(content[1])
                .concat(self.components["clothing"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[2])
                .concat(self.components["mouth"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[3])
                .concat(self.components["nose"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[4])
                .concat(self.components["eyes"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[5])
                .concat(self.components["eyebrows"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[6])
                .concat(self.components["top"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[7])
                .concat(self.components["facialHair"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[8])
                .concat(self.components["accessories"]?.build(components: self.components, colors: self.colors) ?? "")
                .concat(content[9])
            return document[0].concat(tmp).concat(document[1])
        }

        init(components: {String: {Component}}, colors: Colors) {
            self.components = components
            self.colors = colors
            
            self.flattened = {}
            for k in self.components.keys {
                self.flattened[k] = self.components[k]!.name
            }
            self.flattened["accessoriesColor"] = self.colors.accessories
            self.flattened["clothingColor"] = self.colors.clothing
            self.flattened["hairColor"] = self.colors.hair
            self.flattened["hatColor"] = self.colors.hat
            self.flattened["facialColor"] = self.colors.facialHair
            self.flattened["backgroundColor"] = self.colors.background
            self.flattened["skinColor"] = self.colors.skin
        }
    }

    pub resource Admin {
        pub let options: {String: {String: Bool}}
        pub let colors: {String: Bool}

        pub fun createRandom(): Renderer {
            let c: [String] = []
            var count = 0
            while count < 7 {
                count = count + 1

                c.append(self.colors.keys[unsafeRandom() % UInt64(self.colors.keys.length)])
            }

            let colors = Colors(c[0], c[1], c[2], c[3], c[4], c[5], c[6])
            let components: {String: {Component}} = {}

            let clothing = Clothing(self.rollOption(segment: "clothing"))
            components["clothing"] = clothing
            if clothing.name == "graphicShirt" {
                components["clothingGraphic"] = ClothingGraphic(self.rollOption(segment: "clothingGraphic"))
            }
            components["mouth"] = Mouth(self.rollOption(segment: "mouth"))
            components["nose"] = Nose(self.rollOption(segment: "nose"))
            components["eyes"] = Eyes(self.rollOption(segment: "eyes"))
            components["eyebrows"] = Eyebrows(self.rollOption(segment: "eyebrows"))
            components["top"] = Top(self.rollOption(segment: "top"))
            components["facialHair"] = FacialHair(self.rollOption(segment: "facialHair"))
            components["accessories"] = Accessories(self.rollOption(segment: "accessories"))

            return Renderer(components: components, colors: colors)
        }

        pub fun rollOption(segment: String): String {
            let keys = self.options[segment]!.keys
            return keys[unsafeRandom() % UInt64(keys.length)]
        }

        pub fun registerContent(component: String, name: String, content: [String]) {
            let storagePath = StoragePath(identifier: component.concat("_").concat(name))!
            Components.account.save(content, to: storagePath)

            if self.options[component] == nil {
                self.options[component] = {
                    name: true
                }
            } else {
                let tmp = self.options[component]!
                tmp[name] = true
                self.options[component] = tmp
            }
        }

        pub fun addColor(_ c: String) {
            self.colors.insert(key: c, true)
        }

        pub fun removeColor(_ c: String) {
            self.colors.remove(key: c)
        }

        init() {
            self.colors = {}
            self.options = {}
        }
    }

    init() {
        self.AdminPath = /storage/ComponentsAdmin

        let admin <- create Admin()
        let colors =  [
                "Red",
                "Blue",
                "Green",
                "Yellow",
                "Orange",
                "Purple",
                "Pink",
                "Brown",
                "Black",
                "White",
                "Gray",
                "Cyan",
                "Magenta",
                "Teal",
                "Maroon",
                "Navy",
                "Olive",
                "Turquoise",
                "Gold",
                "Silver",
                "Indigo",
                "Lavender",
                "Coral",
                "Salmon",
                "Plum"
            ]
            for c in colors {
                admin.addColor(c)
            }

        
        self.account.save(<- admin, to: self.AdminPath)
    }
}