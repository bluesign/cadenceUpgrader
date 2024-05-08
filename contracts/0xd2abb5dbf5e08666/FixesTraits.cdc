/**
> Author: FIXeS World <https://fixes.world/>

# FixesTraits

TODO: Add description

*/

// Thirdparty Imports
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/// The `FixesTraits` contract
///
access(all) contract FixesTraits {

    /// =============  Trait: Season 0 - Secret Garden =============

    /// The Definition of the Marketplace Season 0
    access(all) enum Season0SecretPlaces: UInt8 {
        access(all) case HeartOfTheAzureOcean // 蔚蓝海洋之心
        access(all) case HeartOfTheDarkForest // 黑暗森林之心
        access(all) case GardenofVenus // 维纳斯的花园
        access(all) case CityOfTheDead // 亡者之城
        access(all) case DragonboneWasteland // 龙骨荒原
        access(all) case MysticForest // 神秘森林
        access(all) case SoulWaterfall // 灵魂瀑布
        access(all) case AbyssalHollow // 深渊之穴
        access(all) case SilentGlacier // 静寂冰川
        access(all) case FrostWasteland // 霜冻荒原
        access(all) case DesolateGround // 荒芜之地
        access(all) case MirageCity // 海市蜃楼
        access(all) case ScorpionGorge // 蛇蝎峡谷
        access(all) case MysteriousIceLake // 神秘冰湖
        access(all) case NightShadowForest // 夜影密林
        access(all) case SpiritualValley // 灵犀山谷
        access(all) case RavensPerch // 乌鸦栖息地
        access(all) case RainbowFalls // 彩虹瀑布
        access(all) case TwilightValley // 暮色谷地
        access(all) case RuggedHill // 乱石山岗
    }

    access(all) view
    fun getSeason0SecretPlacesDefs(): [Definition] {
        return [
            Definition(5, 100), // 1% chance, rarity 2
            Definition(12, 1900), // 19% chance, rarity 1
            Definition(20, 8000) // 80% chance, rarity 0
        ]
    }

    /// =============  Trait: Season 0 - Ability =============

    /// The Definition of the Marketplace Season 0
    ///
    access(all) enum Season0Ability: UInt8 {
        access(all) case Omniscience // 全知全能
        access(all) case ElementalMastery // 全元素掌控
        access(all) case TimeStand // 时间静止
        access(all) case MillenniumFreeze // 千年冰封
        access(all) case FossilResurgence // 化石重生
        access(all) case MysticVision // 神秘视界
        access(all) case PhoenixRebirth // 凤凰复生
        access(all) case SoulBind // 灵魂束缚
        access(all) case PrayerOfLight // 光明祈祷
        access(all) case Starfall // 星辰坠落
        access(all) case DragonsBreath // 龙焰吐息
        access(all) case PsychicSense // 心灵感应
        access(all) case MindControl // 心灵控制
        access(all) case EndlessTorment // 无尽痛苦
        access(all) case MeditationInDespair // 绝境冥思
        access(all) case SilenceFear // 沉默恐惧
        access(all) case GloryChallenge // 荣耀挑战
        access(all) case ShieldWall // 防御罩墙
        access(all) case TidalCall // 海潮呼唤
        access(all) case FountainOfLife // 生命之泉
        access(all) case PsychicInteraction // 精神互动
        access(all) case PlagueTransmission // 疫病传染
        access(all) case NinjaStealth // 忍者潜行
        access(all) case BattleRoar // 战斗吼叫
        access(all) case CongestiveStrike // 充血打击
        access(all) case HolyGuidance // 圣光指引
        access(all) case EmpoweredBarrier // 强化结界
        access(all) case PerpetualLife // 生生不息
        access(all) case CombatEvade // 战斗闪避
        access(all) case AbyssArrow // 深渊之箭
        access(all) case SoulEcho // 灵魂回响
        access(all) case ArcaneBlink // 魔力闪现
        access(all) case ArcaneExplosion // 魔力爆炸
        access(all) case ShadowStep // 暗黑影步
        access(all) case JadeStoneSpell // 玉石咒语
        access(all) case PhantomDodge // 鬼魅闪避
        access(all) case KissOfDeath // 死亡之吻
        access(all) case PhantomSummoning // 幻影召唤
        access(all) case EyeOfTheRaven // 乌鸦之眼
        access(all) case RatSwarmSurge // 鼠群涌动
        access(all) case FlameShock // 烈焰冲击
        access(all) case GaleSpeedBlade // 疾风快剑
        access(all) case InterstellarFlight // 星界飞行
        access(all) case WraithSeal // 怨灵封印
        access(all) case DivineRestoration // 神力恢复
        access(all) case LifePull // 生命拉扯
        access(all) case RapidFire // 快速射击
        access(all) case MightyBlow // 强力打击
        access(all) case PhysicalTraining // 锻炼体魄
    }

    access(all) view
    fun getSeason0AbilityDefs(): [Definition] {
        return [
            Definition(5, 20), // 0.2% chance, rarity 3
            Definition(12, 100), // 1% chance, rarity 2
            Definition(25, 1880), // 18.8% chance, rarity 1
            Definition(49, 8000) // 80% chance, rarity 0
        ]
    }

    /// =============  Trait: Season 0 - Weapons =============

    access(all) enum Season0Weapons: UInt8 {
        access(all) case Starstaff // 星辰法杖
        access(all) case BowOfTheMysteriousBird // 九天玄鸟之弓
        access(all) case VoidSpiritWand // 虚空灵杖
        access(all) case GodlyWand // 神祇法杖
        access(all) case SunriseHolySword // 旭日圣剑
        access(all) case DeepSeaTrident // 深海三叉戟
        access(all) case DragonboneBow // 龙骨弓
        access(all) case RainbowHolySword // 虹光圣剑
        access(all) case MysticalGrimoire // 神秘法书
        access(all) case SaintsStaff // 圣者圣杖
        access(all) case FirePhoenixWhip // 火凤长鞭
        access(all) case SoulOrb // 灵魂法球
        access(all) case LightningSpear // 闪电长矛
        access(all) case DarkScepter // 黑暗权杖
        access(all) case DawnLance // 破晓长枪
        access(all) case RedLotusRocket // 红莲火箭
        access(all) case DemonBoneSpike // 恶魔骨刺
        access(all) case EvilStarCatapult // 魔星投石器
        access(all) case SwordOfTenderness // 温柔之剑
        access(all) case WindWarriorLongbow // 风战者长弓
        access(all) case NightDagger // 黑夜匕首
        access(all) case GalaxyHalberd // 银河双戟
        access(all) case MoonshadowScimitar // 影月弯刀
        access(all) case IceCrownDagger // 冰冠短剑
        access(all) case StormBattleAxe // 风暴战斧
        access(all) case ArcaneStaff // 奥术长杖
        access(all) case AxeOfInferno // 烈火之斧
        access(all) case SkybreakerDualBlade // 破空双刃
        access(all) case IceGiantSword // 寒冰巨剑
        access(all) case TrollsHammer // 巨魔之锤
    }

    access(all) view
    fun getSeason0WeaponsDefs(): [Definition] {
        return [
            Definition(5, 20), // 0.2% chance, rarity 3
            Definition(12, 100), // 1% chance, rarity 2
            Definition(20, 1880), // 18.8% chance, rarity 1
            Definition(30, 8000) // 80% chance, rarity 0
        ]
    }

    access(account)
    fun attemptToGenerateRandomEntryForSeason0(): @Entry? {
        let randForType = revertibleRandom()
        // 5% for secret places, 10% for ability, 15% for weapons, 70% for nothing
        let randForTypePercent = UInt8(randForType % 100)
        if randForTypePercent >= 30 {
            return nil
        }
        var type: Type? = nil
        if randForTypePercent < 5 {
            type = Type<Season0SecretPlaces>()
        } else if randForTypePercent < 15 {
            type = Type<Season0Ability>()
        } else {
            type = Type<Season0Weapons>()
        }
        return <- self.generateRandomEntry(type!)
    }

    /**
        ------------------------ Public Methods ------------------------
    */

    /// Get the rarity definition array for a given series
    /// The higher the rarity in front.
    ///
    access(all)
    fun getRarityDefinition(_ series: Type): [Definition]? {
        switch series {
        case Type<Season0SecretPlaces>():
            return self.getSeason0SecretPlacesDefs()
        case Type<Season0Ability>():
            return self.getSeason0AbilityDefs()
        case Type<Season0Weapons>():
            return self.getSeason0WeaponsDefs()
        }
        return nil
    }

    /// Get the maximum rarity for a given series
    ///
    access(all)
    fun getMaxRarity(_ series: Type): UInt8 {
        if let arr = self.getRarityDefinition(series) {
            return UInt8(arr.length - 1)
        }
        return UInt8.max
    }

    /**
        ------------------------ Genreal Interfaces & Resources ------------------------
    */

    /// The Entry Definition
    ///
    access(all) struct Definition {
        access(all)
        let threshold: UInt8 // max value for this rarity, not included
        access(all)
        let weight: UInt64 // weight of this rarity

        init (
            _ threshold: UInt8,
            _ weight: UInt64
        ) {
            self.threshold = threshold
            self.weight = weight
        }
    }

    /// The TraitWithOffset Definition
    ///
    access(all) struct TraitWithOffset {
        // Series is the identifier of the series enum
        access(all)
        let series: Type
        // Value is the value of the trait, as the rawValue of the enum
        access(all)
        let value: UInt8
        // Rarity is the rarity of the trait, from 0 to maxRarity
        access(all)
        let rarity: UInt8
        // Offset is random between -20 and 20, to be used for rarity extension
        access(all)
        let offset: Int8

        init(
            series: Type,
            value: UInt8,
            rarity: UInt8
        ) {
            self.series = series
            self.value = value
            self.rarity = rarity
            // Offset is random between -20 and 20
            let rand = revertibleRandom()
            self.offset = Int8(rand % 40) - 20
        }
    }

    /// The `Entry` resource
    ///
    access(all) resource Entry: MetadataViews.Resolver {
        access(self)
        let trait: TraitWithOffset

        init (
            series: Type,
            value: UInt8,
            rarity: UInt8
        ) {
            self.trait = TraitWithOffset(
                series: series,
                value: value,
                rarity: rarity
            )
        }

        /// Get the trait
        ///
        access(all)
        fun getTrait(): TraitWithOffset {
            return self.trait
        }

        // ---- implement Resolver ----

        /// Function that returns all the Metadata Views available for this profile
        ///
        access(all)
        fun getViews(): [Type] {
            return [
                Type<TraitWithOffset>(),
                Type<MetadataViews.Trait>()
            ]
        }

        /// Function that resolves a metadata view for this profile
        ///
        access(all)
        fun resolveView(_ view: Type): AnyStruct? {
            switch view {
            case Type<TraitWithOffset>():
                return self.trait
            case Type<MetadataViews.Trait>():
                return MetadataViews.Trait(
                    name: self.trait.series.identifier,
                    value: self.trait.value,
                    displayType: "number",
                    rarity: MetadataViews.Rarity(
                        score: UFix64(self.trait.rarity),
                        max: UFix64(FixesTraits.getMaxRarity(self.trait.series)),
                        description: nil
                    )
                )
            }
            return nil
        }
    }

    /// Create a new entry
    ///
    access(account)
    fun createEntry(_ series: Type, _ value: UInt8, _ rarity: UInt8): @Entry {
        return <- create Entry(
            series: series,
            value: value,
            rarity: rarity
        )
    }

    /// Generate a random entry
    ///
    access(account)
    fun generateRandomEntry(_ series: Type): @Entry? {
        let defs = self.getRarityDefinition(series)
        if defs == nil {
            return nil // DO NOT PANIC
        }

        // generate a random number for the entry
        let randForEntry = revertibleRandom() % 10000
        // calculate the rarity
        var totalWeight: UInt64 = 0
        var lastThreshold: UInt8 = 0
        var currentThreshold: UInt8 = 0
        let maxRarity = UInt8(defs!.length - 1)
        var currentRarity: UInt8 = 0
        // find the right rarity
        for i, def in defs! {
            totalWeight = totalWeight + def.weight
            if randForEntry < totalWeight {
                currentThreshold = def.threshold
                currentRarity = maxRarity - UInt8(i)
                break
            }
            lastThreshold = def.threshold
        }
        // create the entry
        return <- self.createEntry(
            series,
            // calculate the value
            lastThreshold + (UInt8(randForEntry % 255) % (currentThreshold - lastThreshold)),
            currentRarity
        )
    }
}
