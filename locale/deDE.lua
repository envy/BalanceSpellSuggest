local L = LibStub("AceLocale-3.0"):NewLocale("BalanceSpellSuggest", "deDE")

if L then
    L["Behavior"] = "Verhalten"
    L["DoT refresh power"] = "DoT Erneuerungsenergie"
    --L["dotRefreshPowerDesc"] = "Check and remind me if a DoT needs to be refreshed if my eclipse power is below this value when goind Lunar -> Solar or Solar -> Lunar."
    L["DoT refresh time"] = "DoT Erneuerungszeit"
    L["dotRefreshTimeDesc"] = "Die maximal verbleibene Zeit der DoTs bevor an das Erneuern erinnert werden soll."
    L["Leave one SS charge"] = "Eine Aufladung SS lassen"
    L["leaveOneSSChargeDesc"] = "Immer mindestens eine Aufladung von Sternensog zum Wirken von Sternenregen übrig lassen."

    L["Peak behavior"] = "Zenit Verhalten"
    L["PeakBehaviorDesc"] = "Steuert das Verhalten wann/ob DoTs am Mond-/Sonnenzenit vorgeschlagen werden sollen."
    L["PeakBehaviorAlways"] = "Immer"
    L["PeakBehaviorTime"] = "Nur wenn die DoTs auslaufen"
    L["PeakBehaviorNever"] = "Nie"

    L["CA behavior"] = true
    L["CABehaviorDesc"] = "Steuer das Verhalten wann/ob Himmlische Ausrichtung vorgeschlagen werden soll."
    L["CABehaviorAlways"] = "Immer (während Mond)"
    L["CABehaviorBoss"] = "Nur gegen Bosse"
    L["CABehaviorNever"] = "Nie"

    L["Display"] = "Anzeige"
    L["Locked"] = "Verriegelt"
    L["Locks the suggestion frame in place."] = "Verhindert verschieben der Anzeige mit der Maus"
    L["X position"] = "X Position"
    L["X position from the center."] = "X Position von der Bildschirmmitte aus"
    L["Y position"] = "Y Position"
    L["Y position from the center."] = "Y Position von der Bildschirmmitte aus"
    L["Size"] = "Größe"
    L["sizeDesc"] = "Größe der Icons"
    L["DoT Timer"] = "DoT Timer"
    L["Enable timers"] = "Timer aktivieren"
    L["Font size"] = "Schriftgröße"
    L["Highlight font size"] = "Warn Schtiftgröße"
    L["Font"] = "Schriftart"
    L["PeakGlow"] = "Aufleuchten bei Mond-/Sonnenzenit"
    L["PeakGlowDesc"] = "Ob und welches Aufleuchten bei Mond-/Sonnenzenit auftreten soll"
    L["PeakGlowNone"] = "Nie"
    L["PeakGlowNormal"] = "Normal"
    --L["PeakGlowSpellAlert"] = "Spell Alert"
end