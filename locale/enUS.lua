local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "enUS", true)

if L then
    L["Behavior"] = true
    L["DoT refresh power"] = true
    L["dotRefreshPowerDesc"] = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when going Lunar -> Solar or Solar -> Lunar."
    L["DoT refresh time"] = true
    L["dotRefreshTimeDesc"] = "The maximum remaining time on the DoT effects before reminding to refresh them."
    L["Starfire -> Wrath tipping point"] = true
    L["starfireWrathTippingPointDesc"] = "When going from lunar to solar, at which power start to suggest Wrath instead of Starfire while still in lunar."
    L["Wrath -> Starfire tipping point"] = true
    L["wrathStarfireTippingPointDesc"] = "When going from solar to lunar, at which power start to suggest Starfire instead of Wrath while still in solar."
    L["CA on boss only"] = true
    L["CAOnlyOnBossDesc"] = "Only recommend Celestial Alignment if the target is classified as a boss. Detection might not work in some cases."
    L["Leave one SS charge"] = true
    L["leaveOneSSChargeDesc"] = "Leave at least one charge of Starsurge for manual casting of Starfall."

    L["Peak behavior"] = true
    L["PeakBehaviorDesc"] = "Controls the behavior for Lunar/Solar Peak and if/when to suggest DoTs."
    L["PeakBehaviorAlways"] = "Alayws"
    L["PeakBehaviorTime"] = "Only if DoTs run out"
    L["PeakBehaviorNever"] = "Never"

    L["Display"] = true
    L["Locked"] = true
    L["Locks the suggestion frame in place."] = true
    L["X position"] = true
    L["X position from the center."] = true
    L["Y position"] = true
    L["Y position from the center."] = true
    L["Size"] = true
    L["sizeDesc"] = "Size of the icons"
    L["DoT Timer"] = true
    L["Enable timers"] = true
    L["Font size"] = true
    L["Highlight font size"] = true
    L["Font"] = true
    L["peakGlow"] = "Glow on Lunar/Solar Peak"
end