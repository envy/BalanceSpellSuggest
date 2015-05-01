local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "enUS", true)

if not L then return end

L["Open"] = true
L["OpenDesc"] = "Opens the options window"

L["Info"] = true
L["Infotext"] = "If you are casting nothing, your spell icon will show you your next cast.\
If you are casting something, your next spell will be shown so you can queue it up when your current spell is finishing it's cast.\
\
If you have enabled the predicted energy display, the left number will show you your energy after your current cast. The right number will show you your energy after your next cast.\
They are colored for lunar and solar phases. If you are at peak, they will show an asterisk (*)."

L["Behavior"] = true
L["DoT refresh power"] = true
L["dotRefreshPowerDesc"] = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when going Lunar -> Solar or Solar -> Lunar."
L["DoT refresh time"] = true
L["dotRefreshTimeDesc"] = "The maximum remaining time on the DoT effects before reminding to refresh them."
L["Stellar Flare power window"] = true
L["sfPowerWindowDesc"] = "Energy window in which Stellar Flare should be suggested to finish casting"
L["Leave one SS charge"] = true
L["leaveOneSSChargeDesc"] = "Leave at least one charge of Starsurge for manual casting of Starfall."
L["starfallOn3StarsurgeCharges"] = "SF at 3 SS charges"
L["starfallOn3StarsurgeChargesDesc"] = "Suggest Starfall if you have three Starsurge charges and the current Starsurge buff is still up."

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
L["empMoonkinGlow"] = "Glow on EM style"
L["empMoonkinGlowDesc"] = "Whether and what glow to show if your next spell is instant because of Empowered Moonkin"
L["empMoonkinGlowWhen"] = "Glow on EM behavior"
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
L["predictedEnergyLunarColor"] = "Color in lunar phase"
L["predictedEnergySolarColor"] = "Color in solar phase"

L["DoT Timer"] = true
L["Enable timers"] = true
L["Font size"] = true
L["Highlight font size"] = true
L["Font"] = true
L["wrongCastColor"] = "Wrong cast color"
L["wrongCastColorDesc"] = "What color to tint the spell icon with, if your current cast does not match the suggested one. If you want to disable this, set it to white."
L["PeakGlow"] = "Glow on Lunar/Solar Peak"
L["PeakGlowDesc"] = "Whether and what glow to show on Lunar/Solar Peak"
L["GlowNone"] = "Never"
L["GlowNormal"] = "Normal"
L["GlowSpellAlert"] = "Spell Alert"
L["Spacing"] = true
L["spacingDesc"] = "Add extra space between the timers and the spell icon"
