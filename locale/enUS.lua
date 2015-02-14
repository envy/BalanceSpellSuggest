local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "enUS", true)

if L then
    L["Behavior"] = true
    L["DoT refresh power"] = true
    L["dotRefreshPowerDesc"] = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when going Lunar -> Solar or Solar -> Lunar."
    L["DoT refresh time"] = true
    L["dotRefreshTimeDesc"] = "The maximum remaining time on the DoT effects before reminding to refresh them."
    L["Stellar Flare power window"] = true
    L["sfPowerWindowDesc"] = "Energy window in which Stellar Flare should be suggested to finish casting"
    L["Leave one SS charge"] = true
    L["leaveOneSSChargeDesc"] = "Leave at least one charge of Starsurge for manual casting of Starfall."

    L["Peak behavior"] = true
    L["PeakBehaviorDesc"] = "Controls the behavior for Lunar/Solar Peak and if/when to suggest DoTs."
    L["PeakBehaviorAlways"] = "Always"
    L["PeakBehaviorTime"] = "Only if DoTs run out"
    L["PeakBehaviorNever"] = "Never"

    L["CA behavior"] = true
    L["CABehaviorDesc"] = "Controls the behavior for Celestial Alignment"
    L["CABehaviorAlways"] = "Always (during lunar)"
    L["CABehaviorBoss"] = "Only against bosses"
    L["CABehaviorNever"] = "Never"

    L["Display"] = true
    L["Locked"] = true
    L["Locks the suggestion frame in place."] = true
    L["X position"] = true
    L["X position from the center."] = true
    L["Y position"] = true
    L["Y position from the center."] = true
    L["Size"] = true
    L["sizeDesc"] = "Size of the icons"
    L["Spacing"] = true
    L["spacingDesc"] = "Add extra space between the current and next spell icons"
    L["DoT Timer"] = true
    L["Enable timers"] = true
    L["Font size"] = true
    L["Highlight font size"] = true
    L["Font"] = true
    L["PeakGlow"] = "Glow on Lunar/Solar Peak"
    L["PeakGlowDesc"] = "Whether and what glow to show on Lunar/Solar Peak"
    L["PeakGlowNone"] = "Never"
    L["PeakGlowNormal"] = "Normal"
    L["PeakGlowSpellAlert"] = "Spell Alert"
end