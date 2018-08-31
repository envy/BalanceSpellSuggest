local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "enUS", true)

if not L then return end

L["Open"] = true
L["OpenDesc"] = "Opens the options window"

L["Info"] = true
L["Infotext"] = "If you are casting nothing, your spell icon will show you your next cast.\
If you are casting something, your next spell will be shown so you can queue it up when your current spell is finishing its cast.\
\
If you have enabled the predicted energy display, the left number will show you your astral power after your current cast. The right number will show you your astral power after your next cast.\
If you are at 100 astral power, they will show an asterisk (*)."

L["Behavior"] = true
L["SS power threshold"] = true
L["SS power threshold Desc"] = "The amount of Astral Power that you need to start suggesting Starsurge."

L["CA behavior"] = true
L["CABehaviorDesc"] = "Controls the behavior for Celestial Alignment"
L["CABehaviorAlways"] = "Always"
L["CABehaviorBoss"] = "Only against bosses"
L["CABehaviorNever"] = "Never"

L["FoE behavior"] = true
L["FoEBehaviorDesc"] = "Controls the behavior for Fury of Elune"
L["FoEBehaviorAlways"] = "Always"
L["FoEBehaviorBoss"] = "Only against bosses"
L["FoEBehaviorNever"] = "Never"

L["FoE power threshold"]  = true
L["FoE power threshold Desc"] = "The amount of Astral Power that you need to have to start suggesting Fury of Elune."

L["FoE power max"] = true
L["FoE power max Desc"] = "The amount of Astral Power that you need to have to stop suggesting Fury of Elune."

L["General"] = true

L["Display"] = true
L["Locked"] = true
L["Locks the suggestion frame in place."] = true
L["X position"] = true
L["X position from the center."] = true
L["Y position"] = true
L["Y position from the center."] = true
L["Size"] = true
L["Opacity"] = true
L["sizeDesc"] = "Size of the icons"

L["SpellIcon"] = "Spell icon"
L["Glow on OF style"] = true
L["Glow on OF style Desc"] = "Whether and what glow to show if your next Lunar Strike is instant because of Owlkin Frenzy"
L["showGCD"] = "Show GCD"
L["showGCDDesc"] = "Show a cooldown spiral for the global cooldown"

L["predictedEnergyDisplay"] = "Predicted Energy Display"
L["predictedEnergyShow"] = "Show predicted energy texts"
L["predictedEnergyShowDesc"] = "Show the predicted energy inside the spell suggestions"
L["predictedEnergyFontSize"] = "Font size"
L["predictedEnergyEdgeOffset"] = "Offset from the corner"
L["predictedEnergyTextColor"] = "Text color"

L["DoT Timer"] = true
L["Enable timers"] = true
L["Font size"] = true
L["Highlight font size"] = true
L["Font"] = true
L["GlowNone"] = "Never"
L["GlowNormal"] = "Normal"
L["GlowSpellAlert"] = "Spell Alert"
L["Spacing"] = true
L["spacingDesc"] = "Add extra space between the timers and the spell icon"
