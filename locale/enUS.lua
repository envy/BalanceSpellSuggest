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
L["DoT refresh time"] = true
L["dotRefreshTimeDesc"] = "The maximum remaining time on the DoT effects before reminding to refresh them."

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
L["empMoonkinGlow"] = "Glow on OF style"
L["empMoonkinGlowDesc"] = "Whether and what glow to show if your next spell is instant because of Owlkin Frenzy"
L["empMoonkinGlowWhen"] = "Glow on OF behavior"
L["empMoonkinGlowWhenDesc"] = "Whether to show the glow for every suggested spell or only for spells with cast times"
L["GlowWhenAll"] = "All spells"
L["GlowWhenOnlyCasts"] = "Only for spells with cast times"
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
