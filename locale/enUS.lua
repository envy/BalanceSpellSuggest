local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "enUS", true)

if L then
    L["Behavior"] = true
    L["DoT refresh power"] = true
    L["dotRefreshPowerDesc"] = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when going Lunar -> Solar or Solar -> Lunar."
    L["Starfire -> Wrath tipping point"] = true
    L["starfireWrathTippingPointDesc"] = "When going from lunar to solar, at which power start to suggest Wrath instead of Starfire while still in lunar."
    L["Wrath -> Starfire tipping point"] = true
    L["wrathStarfireTippingPointDesc"] = "When going from solar to lunar, at which power start to suggest Starfire instead of Wrath while still in solar."
    L["Talents"] = true
    L["Euphoria"] = true
    L["Is Euphoria skilled?"] = true

    L["Display"] = true
    L["Locked"] = true
    L["Locks the suggestion frame in place."] = true
    L["X position"] = true
    L["X position from the center."] = true
    L["Y position"] = true
    L["Y position from the center."] = true
    L["DoT Timer"] = true
    L["Enable timers"] = true
    L["Font size"] = true
    L["Highlight font size"] = true
end