if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0", "AceEvent-3.0", "AceConsole-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("BalanceSpellSuggest", true)
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")

BalanceSpellSuggest.suggestFrame = nil
BalanceSpellSuggest.curSpellFrame = nil
BalanceSpellSuggest.moonfireFrame = nil
BalanceSpellSuggest.sunfireFrame = nil
BalanceSpellSuggest.updateTimer = nil

BalanceSpellSuggest.predictor = {}
BalanceSpellSuggest.masque = {}

do
    -- Adapted from BlanacePowerTracker
    local a, ai, b, bi
    local euphoriaValues = {104.5, 1/3.2 }
    local normalValues = {104.5, math.pi/20 }
    local syncTime, inPeak, syncCycleTime = 0, false, 0

    local energyToTime = function(energy, direction)
        if direction == "sun" then
            return ((math.asin(energy * ai) + math.pi) * bi)
        else -- lunar and none
            return (math.asin(energy * ai) * bi * -1)
        end
    end

    local sync = function()
        local power = UnitPower("player", 8)
        if not inPeak and math.abs(power) == 100 then
            syncTime = GetTime()
            syncCycleTime = energyToTime(power, GetEclipseDirection())
            inPeak = true
        elseif inPeak and math.abs(power) < 100 then
            inPeak = false
        end
    end

    BalanceSpellSuggest.predictor.updateValues = function(euphoria)
        a, b = unpack((euphoria and euphoriaValues) or normalValues)
        ai = 1/a
        bi = 1/b
    end

    BalanceSpellSuggest.predictor.getEnergy = function(casttime, player)
        local startEnergy, startTime
        if player.currentCast.startPower ~= nil then
            startTime = player.currentCast.startTime / 1000
            startEnergy = player.currentCast.startPower
            casttime = player.currentCast.castTime
        else
            startTime = player.time
            startEnergy = player.rawPower
        end
        sync()
        local timenow
        if (not inPeak) or (inPeak and startTime < syncTime) then
            timenow = energyToTime(startEnergy, player.direction)
        else
            local caDiff = 0
            if player.buffs.celestialAlignment > 0 then
                caDiff = 15 - player.buffs.celestialAlignment
            end
            timenow = syncCycleTime + (startTime - syncTime) - caDiff
        end
        local temp = math.sin((timenow + casttime) * b) * a
        return math.min(math.max(math.floor(temp), -100), 100) * -1
    end
end

do
    local groups = {}
    BalanceSpellSuggest.masque.reskin = function()
        for k, v in pairs(groups) do
            v:ReSkin()
        end
    end

    BalanceSpellSuggest.masque.addGroup = function(_, name, group)
        groups[name] = group
    end
end

-- https://gist.github.com/MihailJP/3931841
local function clone(t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

local function lunarBonus(e)
    return (-e/2)+50
end

local function solarBonus(e)
    return (e/2)+50
end


local options = {
    name = "Balance Spell Suggest",
    handler = BalanceSpellSuggest,
    type = 'group',
    childGroups = "tab",
    args = {
        open = {
            name = L["Open"],
            desc = L["OpenDesc"],
            type = "execute",
            order = 0,
            guiHidden = true,
            func = function()
                LibStub("AceConfigDialog-3.0"):Open("BalanceSpellSuggest")
            end
        },
        info = {
            name = L["Info"],
            type = "group",
            order = 1,
            cmdHidden = true,
            args = {
                text = {
                    type = "description",
                    name = L["Infotext"],
                    fontSize = "small",
                }
            },
        },
        behavior = {
            name = L["Behavior"],
            type = "group",
            order = 2,
            args = {
                dotRefreshPower = {
                    name = L["DoT refresh power"],
                    desc = L["dotRefreshPowerDesc"],
                    type = "range",
                    order = 0,
                    min = 0,
                    max = 100,
                    softMin = 10,
                    softMax = 50,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.dotRefreshPower = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.dotRefreshPower end
                },
                dotRefreshTime = {
                    name = L["DoT refresh time"],
                    desc = L["dotRefreshTimeDesc"],
                    type = "range",
                    order = 1,
                    min = 0,
                    max = 40,
                    softMin = 1,
                    softMax = 20,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.dotRefreshTime = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.dotRefreshTime end
                },
                stellarFlarePowerWindow = {
                    name = L["Stellar Flare power window"],
                    desc = L["sfPowerWindowDesc"],
                    type = "range",
                    order = 1,
                    min = 1,
                    max = 90,
                    softMin = 5,
                    softMax = 30,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.stellarFlarePowerWindow = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.stellarFlarePowerWindow end
                },
                leaveOneSSCharge = {
                    name = L["Leave one SS charge"],
                    desc = L["leaveOneSSChargeDesc"],
                    type = "toggle",
                    order = 5,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.leaveOneSSCharge = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.leaveOneSSCharge end
                },
                starfallOn3StarsurgeCharges = {
                    name = L["starfallOn3StarsurgeCharges"],
                    desc = L["starfallOn3StarsurgeChargesDesc"],
                    type = "toggle",
                    order = 5,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.starfallOn3StarsurgeCharges = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.starfallOn3StarsurgeCharges end
                },
                caBehavior = {
                    name = L["CA behavior"],
                    desc = L["CABehaviorDesc"],
                    type = "select",
                    order = 6,
                    values = { always = L["CABehaviorAlways"], boss = L["CABehaviorBoss"], never = L["CABehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.caBehavior = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.caBehavior end
                },
                peakBehavior = {
                    name = L["Peak behavior"],
                    desc = L["PeakBehaviorDesc"],
                    type = "select",
                    order = 6,
                    values = { always = L["PeakBehaviorAlways"], time = L["PeakBehaviorTime"], never = L["PeakBehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.peakBehavior = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.peakBehavior end
                },
            }
        },
        display = {
            name = L["Display"],
            type = "group",
            order = 3,
            args = {
                general = {
                    name = L["General"],
                    type = "group",
                    order = 0,
                    args = {
                        locked = {
                            name = L["Locked"],
                            desc = L["Locks the suggestion frame in place."],
                            type = "toggle",
                            order = 1,
                            set = function(info, val) BalanceSpellSuggest:ToggleFrameLock(info, val) end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.locked end
                        },
                        xPosition = {
                            name = L["X position"],
                            desc = L["X position from the center."],
                            type = "range",
                            order = 2,
                            min = -2000.0,
                            max = 2000.0,
                            softMin = -2000.0,
                            softMax = 2000.0,
                            step = 0.1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.general.xPosition = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.xPosition end
                        },
                        yPosition = {
                            name = L["Y position"],
                            desc = L["Y position from the center."],
                            type = "range",
                            order = 3,
                            min = -2000.0,
                            max = 2000.0,
                            softMin = -2000.0,
                            softMax = 2000.0,
                            step = 0.1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.general.yPosition = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.yPosition end
                        },
                        size = {
                            name = L["Size"],
                            desc = L["sizeDesc"],
                            type = "range",
                            order = 4,
                            min = 10,
                            max = 256,
                            softMin = 10,
                            softMax = 128,
                            step = 1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.general.size = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.size end
                        },
                        opacity = {
                            name = L["Opacity"],
                            type = "range",
                            order = 5,
                            min = 0,
                            max = 1,
                            softMin = 0.1,
                            softMax = 1,
                            step = 0.01,
                            isPercent = true,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.general.opacity = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.opacity end
                        },
                        font = {
                            name = L["Font"],
                            type = "select",
                            order = 6,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.general.font = val
                                BalanceSpellSuggest:RecreateAllFonts()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.general.font  end
                        },
                    },
                },
                spellicon = {
                    name = L["SpellIcon"],
                    type = "group",
                    order = 1,
                    args = {
                        empMoonkinGlow = {
                            name = L["empMoonkinGlow"],
                            desc = L["empMoonkinGlowDesc"],
                            type = "select",
                            order = 1,
                            values = { none = L["GlowNone"], normal = L["GlowNormal"], spellalert = L["GlowSpellAlert"] },
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlow = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlow end
                        },
                        empMoonkinGlowWhen = {
                            name = L["empMoonkinGlowWhen"],
                            desc = L["empMoonkinGlowWhenDesc"],
                            type = "select",
                            order = 2,
                            values = { all = L["GlowWhenAll"], onlyCasts = L["GlowWhenOnlyCasts"] },
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlowWhen = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlowWhen end
                        },
                        showGCD = {
                            name = L["showGCD"],
                            desc = L["showGCDDesc"],
                            type = "toggle",
                            order = 3,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.spellIcon.showGCD = val
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.showGCD end
                        },
                        predictedEnergy = {
                            name = L["predictedEnergyDisplay"],
                            type = "group",
                            order = 4,
                            inline = true,
                            args = {
                                show = {
                                    name = L["predictedEnergyShow"],
                                    desc = L["predictedEnergyShowDesc"],
                                    type = "toggle",
                                    order = 1,
                                    set = function(_, val)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.show = val
                                        BalanceSpellSuggest:UpdateFramePosition()
                                    end,
                                    get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.show end
                                },
                                fontSize = {
                                    name = L["predictedEnergyFontSize"],
                                    type = "range",
                                    order = 2,
                                    min = 1,
                                    max = 100,
                                    softMin = 10,
                                    softMax = 100,
                                    step = 1,
                                    set = function(_, val)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.fontSize = val
                                        BalanceSpellSuggest:RecreateAllFonts()
                                    end,
                                    get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.fontSize end
                                },
                                energyEdgeOffset = {
                                    name = L["predictedEnergyEdgeOffset"],
                                    type = "range",
                                    order = 3,
                                    min = 0,
                                    max = 20,
                                    softMin = 0,
                                    softMax = 10,
                                    step = 1,
                                    set = function(_, val)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.edgeOffset = val
                                        BalanceSpellSuggest:RecreateAllFonts()
                                    end,
                                    get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.edgeOffset end
                                },
                                lunarColor = {
                                    name = L["predictedEnergyLunarColor"],
                                    type = "color",
                                    order = 4,
                                    get = function(_)
                                        return unpack(BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.lunarColor)
                                    end,
                                    set = function(_, r, g, b, a)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.lunarColor = {r, g, b, a }
                                        BalanceSpellSuggest:RecreateSpellFonts(BalanceSpellSuggest.curSpellFrame)
                                    end
                                },
                                solarColor = {
                                    name = L["predictedEnergySolarColor"],
                                    type = "color",
                                    order = 5,
                                    get = function(_)
                                        return unpack(BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.solarColor)
                                    end,
                                    set = function(_, r, g, b, a)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.solarColor = {r, g, b, a }
                                        BalanceSpellSuggest:RecreateSpellFonts(BalanceSpellSuggest.curSpellFrame)
                                    end
                                },
                            },
                        },
                    },
                },
                timers = {
                    name = L["DoT Timer"],
                    type = "group",
                    order = 2,
                    args = {
                        timersToggle = {
                            name = L["Enable timers"],
                            type = "toggle",
                            order = 1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.dotTimer.enable = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.dotTimer.enable end
                        },
                        peakGlow = {
                            name = L["PeakGlow"],
                            desc = L["PeakGlowDesc"],
                            type = "select",
                            order = 2,
                            values = { none = L["GlowNone"], normal = L["GlowNormal"], spellalert = L["GlowSpellAlert"] },
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.dotTimer.peakGlow = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.dotTimer.peakGlow end
                        },
                        normalFontSize = {
                            name = L["Font size"],
                            type = "range",
                            order = 3,
                            min = 1,
                            max = 100,
                            softMin = 10,
                            softMax = 100,
                            step = 1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.dotTimer.normalfontsize = val
                                BalanceSpellSuggest:RecreateAllFonts()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.dotTimer.normalfontsize end
                        },
                        highlightFontSize = {
                            name = L["Highlight font size"],
                            type = "range",
                            order = 4,
                            min = 1,
                            max = 100,
                            softMin = 10,
                            softMax = 100,
                            step = 1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.dotTimer.highlightfontsize = val
                                BalanceSpellSuggest:RecreateAllFonts()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.dotTimer.highlightfontsize end
                        },
                        spacing = {
                            name = L["Spacing"],
                            desc = L["spacingDesc"],
                            type = "range",
                            order = 6,
                            min = 0,
                            max = 1000,
                            softMin = 0,
                            softMax = 100,
                            step = 1,
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.dotTimer.spacing = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.dotTimer.spacing end
                        },
                    },
                },
            }
        }
    }
}

local defaults = {
    profile = {
        behavior = {
            dotRefreshPower = 40,
            dotRefreshTime = 7,
            stellarFlarePowerWindow = 20,
            leaveOneSSCharge = true,
            starfallOn3StarsurgeCharges = true,
            peakBehavior = "time",
            caBehavior = "boss",
        },
        display = {
            general = {
                locked = true,
                xPosition = 0,
                yPosition = 0,
                size = 64,
                font = "Friz Quadrata TT",
                fontoptions = "OUTLINE",
                opacity = 1.0,
            },
            spellIcon = {
                empMoonkinGlow = "spellalert",
                empMoonkinGlowWhen = "all",
                showGCD = true,
                predictedEnergy = {
                    show = true,
                    fontSize = 13,
                    edgeOffset = 3,
                    lunarColor = {0, 206/255, 1, 1},
                    solarColor = {1, 166/255, 0, 1},
                },
            },
            dotTimer = {
                enable = true,
                normalfontsize = 15,
                highlightfontsize = 17,
                peakGlow = "normal",
                spacing = 0,
            },
        },
    }
}


-- spells and stuff
local moonfirename,_,moonfire = GetSpellInfo(164812)
local sunfirename,_,sunfire = GetSpellInfo(164815)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local starfirename,_,starfire =  GetSpellInfo(2912)
local wrathname,_,wrath = GetSpellInfo(5176)
local stellarflarename,_,stellarflare = GetSpellInfo(152221)
local starfallname,_,starfall = GetSpellInfo(48505)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(112071)
local incarnationname,_,incarnation = GetSpellInfo(102560)
local moonkinformname,_,moonkinform = GetSpellInfo(24858)

local lunarempowermentname = GetSpellInfo(164547)
local solarempowermentname = GetSpellInfo(164545)
local lunarpeakname = GetSpellInfo(171743)
local solarpeakname = GetSpellInfo(171744)

local empoweredMoonkin = GetSpellInfo(157228)

local glowTexturePath = "Interface\\SpellActivationOverlay\\IconAlert"


local function iconToCastTimeName(i)
    if i == starfire then
        return "starfire"
    elseif i == wrath then
        return "wrath"
    elseif i == stellarflare then
        return "stellarflare"
    elseif i == celestialalignment then
        return "celestialalignment"
    else
        return "gcd"
    end
end

local function isNotInstant(n)
    return n == starfire or n == wrath or n == stellarflare
end

-- Always called
function BalanceSpellSuggest:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BalanceSpellSuggestDB", defaults, true)
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BalanceSpellSuggest", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BalanceSpellSuggest", "Balance Spell Suggest")
    self:RegisterChatCommand("bss", "Options")
    self:RegisterChatCommand("balancespellsuggest", "Options")
    BalanceSpellSuggest:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    BalanceSpellSuggest:RegisterEvent("CHARACTER_POINTS_CHANGED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_REGEN_DISABLED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_REGEN_ENABLED")
    BalanceSpellSuggest:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    BalanceSpellSuggest:RegisterEvent("PLAYER_ENTERING_WORLD")

    self:SetUpFrames()

    self.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileChanged")

    self.baseGCD = 1.5

    self.player = {
        moonkinForm = false,
        buffs = {
            lunarPeak = false,
            solarPeak = false,
            empoweredMoonkin = false,
            celestialAlignment = 0,
            starfall = 0,
            starsurgeLunarBonus = 0,
            starsurgeSolarBonus = 0,
        },
        talents = {
            euphoria = false,
            stellarflare = false,
            balanceofpower = false,
            incarnation = false,
        },
        castTimes = {
            starfire = 0,
            wrath = 0,
            stellarflare = 0,
            gcd = 1.5,
            starsurge = 1.5, -- GCD
            starfall = 1.5, -- GCD
            moonfire = 1.5, -- GCD
            sunfire = 1.5, -- GCD
            moonkinform = 1.5, -- GCD
            celestialalignment = 0, -- no GCD
            solarbeam = 0, -- no GCD
            naturesvigil = 0, -- no GCD
        },
        inCombat = false,
        time = 0,
        power = 0,
        rawPower = 0,
        atPeak = false,
        direction = "none",
        inLunar = false,
        inSolar = false,
        currentCast = {
            spell = nil,
            icon = nil,
            startTime = nil,
            startPower = nil,
            endTime = nil,
            castTime = nil,
            id = nil,
            interruptable = nil,
            isCorrect = false,
        },
        gcd = {
            start = 0,
            duration = 0,
        },
        target = {
            debuffs = {
                moonfire = 0,
                sunfire = 0,
                stellarflare = 0,
            }
        },
        celestialAlignmentReady = false,
        starsurgeCharges = 0,
    }

    self:UpdateFramePosition()

    self.masque:reskin()
end


function BalanceSpellSuggest:Options(input)
    LibStub("AceConfigCmd-3.0").HandleCommand(BalanceSpellSuggest, "bss", "BalanceSpellSuggest", input)
end


-- Enable or disable update timer based on current specialization
function BalanceSpellSuggest:ACTIVE_TALENT_GROUP_CHANGED()
    local currentSpec = GetSpecialization()
    if tonumber(currentSpec) == 1 then
        self:EnableTimer()
    else
        self:DisableTimer()
    end
end


function BalanceSpellSuggest:CHARACTER_POINTS_CHANGED()
    self:UpdatePlayerState()
    self.predictor.updateValues(self.player.talents.euphoria)
end


function BalanceSpellSuggest:PLAYER_REGEN_DISABLED()
    self.player.inCombat = true
end


function BalanceSpellSuggest:PLAYER_REGEN_ENABLED()
    self.player.inCombat = false
end


function BalanceSpellSuggest:PLAYER_ENTERING_WORLD()
    self.masque:reskin()
end


function BalanceSpellSuggest:UNIT_SPELLCAST_SUCCEEDED(_, unit, name, rank, counter, id)
    if unit ~= "player" then
        return
    end
    if self.db.profile.display.spellIcon.showGCD and self.player.castTimes[string.lower(name)] ~= nil then
        self.player.gcd.start = GetTime()
        self.player.gcd.duration = self.player.castTimes.gcd
        self.curSpellFrame.cooldown:SetCooldown(self.player.gcd.start, self.player.gcd.duration)
    end
end


-- Called on login
function BalanceSpellSuggest:OnEnable()
    -- enable or diable based on current spec
    self:ACTIVE_TALENT_GROUP_CHANGED()
    self:CHARACTER_POINTS_CHANGED()
end


-- Called after a spec change to non-balance
function BalanceSpellSuggest:OnDisable()
    self:DisableTimer()
end


-- Enables the update timer
function BalanceSpellSuggest:EnableTimer()
    if self.updateTimer == nil then
        self.updateTimer = self:ScheduleRepeatingTimer("UpdateFrames", 0.1)
    end
end


-- Disables the update timer
function BalanceSpellSuggest:DisableTimer()
    if self.updateTimer ~= nil then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end

    self.suggestFrame:Hide()
end


function BalanceSpellSuggest:ProfileChanged()
    self:UpdateFramePosition()
    self:RecreateAllFonts()
end


function BalanceSpellSuggest:RecreateAllFonts()
    BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.moonfireFrame)
    BalanceSpellSuggest:RecreateFonts(BalanceSpellSuggest.sunfireFrame)
    self:RecreateSpellFonts(self.curSpellFrame)
end


-- Updates the position and the size of the frames
function BalanceSpellSuggest:UpdateFramePosition()
    self.suggestFrame:SetPoint("CENTER", self.db.profile.display.general.xPosition, self.db.profile.display.general.yPosition)

    if self.db.profile.display.dotTimer.enable then
        self.suggestFrame:SetWidth(self.db.profile.display.general.size * 3 + self.db.profile.display.dotTimer.spacing * 2)
        self.moonfireFrame:Show()
        self.sunfireFrame:Show()
    else
        self.suggestFrame:SetWidth(self.db.profile.display.general.size)
        self.moonfireFrame:Hide()
        self.sunfireFrame:Hide()
    end

    self.moonfireFrame:SetHeight(self.db.profile.display.general.size)
    self.moonfireFrame:SetWidth(self.db.profile.display.general.size)
    self.moonfireFrame:SetPoint("CENTER", -self.db.profile.display.general.size - self.db.profile.display.dotTimer.spacing, 0)

    self.sunfireFrame:SetHeight(self.db.profile.display.general.size)
    self.sunfireFrame:SetWidth(self.db.profile.display.general.size)
    self.sunfireFrame:SetPoint("CENTER", self.db.profile.display.general.size + self.db.profile.display.dotTimer.spacing, 0)


    self.suggestFrame:SetHeight(self.db.profile.display.general.size)

    self.curSpellFrame:SetHeight(self.db.profile.display.general.size)
    self.curSpellFrame:SetWidth(self.db.profile.display.general.size)


    if self.db.profile.display.spellIcon.predictedEnergy.show then
        self.curSpellFrame.textAC:Show()
        self.curSpellFrame.textAN:Show()
    else
        self.curSpellFrame.textAC:Hide()
        self.curSpellFrame.textAN:Hide()
    end

    local frames = { self.suggestFrame:GetChildren() }
    for _, frame in ipairs(frames) do
        if self.db.profile.display.general.locked then
            frame:SetAlpha(self.db.profile.display.general.opacity)
        else
            frame:SetAlpha(0.5)
        end
    end

    self.masque:reskin()
end


-- Toggles the frame lock of the suggestFrame
function BalanceSpellSuggest:ToggleFrameLock(_, val)
    self.db.profile.display.general.locked = val
    if self.db.profile.display.general.locked then
        self.suggestFrame:SetFrameStrata("BACKGROUND")
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
        self.suggestFrame:SetScript("OnDragStart", function() end)
        self.suggestFrame:SetScript("OnDragStop", function() end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame:SetAlpha(self.db.profile.display.general.opacity)
        end
    else
        self.suggestFrame:SetFrameStrata("MEDIUM")
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:SetScript("OnDragStart", self.suggestFrame.StartMoving)
        self.suggestFrame:SetScript("OnDragStop", function(self, button) BalanceSpellSuggest:StopMoving(self, button) end)
        local frames = { self.suggestFrame:GetChildren() }
        for _, frame in ipairs(frames) do
            frame:SetAlpha(0.5)
        end
    end
end


-- Set up all needed frames
function BalanceSpellSuggest:SetUpFrames()
    -- the main frame hosting all other frames
    self.suggestFrame = CreateFrame("Frame", "BSS_Main", UIParent)
    self.suggestFrame:SetFrameStrata("BACKGROUND")
    if self.db.profile.display.dotTimer.enable then
        self.suggestFrame:SetWidth(self.db.profile.display.general.size * 3)
    else
        self.suggestFrame:SetWidth(self.db.profile.display.general.size * 2)
    end
    self.suggestFrame:SetHeight(self.db.profile.display.general.size)
    self.suggestFrame:SetPoint("CENTER", self.db.profile.display.general.xPosition, self.db.profile.display.general.yPosition)
    self.suggestFrame:RegisterForDrag("LeftButton")

    if self.db.profile.display.general.locked then
        self.suggestFrame:SetMovable(false)
        self.suggestFrame:EnableMouse(false)
    else
        self.suggestFrame:SetMovable(true)
        self.suggestFrame:EnableMouse(true)
        self.suggestFrame:Show()
    end

    self.curSpellFrame = self:CreateSpellFrame("BSS_Cur", starfire, 0, 0)
    
    -- the frame for the moonfire timer
    self.moonfireFrame = self:CreateTimerFrame("BSS_Moonfire", moonfire, -self.db.profile.display.general.size - self.db.profile.display.dotTimer.spacing, 0)

    -- the frame for the sunfire timer
    self.sunfireFrame = self:CreateTimerFrame("BSS_Sunfire", sunfire, self.db.profile.display.general.size + self.db.profile.display.dotTimer.spacing, 0)

    -- Setup Masque
    local masque = LibStub("Masque", true)
    if masque then
        local spellGroup = masque:Group("Balance Spell Suggest", "Suggestion Icons")
        spellGroup:AddButton(self.curSpellFrame, {Icon = self.curSpellFrame.bssTexture, Cooldown = self.curSpellFrame.cooldown, })
        self.masque:addGroup("spell", spellGroup)
        local timerGroup = masque:Group("Balance Spell Suggest", "DoT Timers")
        timerGroup:AddButton(self.moonfireFrame, {Icon = self.moonfireFrame.bssTexture, })
        timerGroup:AddButton(self.sunfireFrame, {Icon = self.sunfireFrame.bssTexture, })
        self.masque:addGroup("timer", timerGroup)
        self.masque:reskin()
    end
end


-- Creates a spell frame
function BalanceSpellSuggest:CreateSpellFrame(name, texturePath, xOfs, yOfs)
    local frame = CreateFrame("Button", name, self.suggestFrame)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetWidth(self.db.profile.display.general.size)
    frame:SetHeight(self.db.profile.display.general.size)
    frame:SetPoint("CENTER", 0, 0)
    frame:EnableMouse(false)
    frame.bssTexture = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.bssTexture:SetTexture(starfire)
    frame.bssTexture:SetAllPoints()
    frame.glowTexture = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.glowTexture:SetTexture(glowTexturePath)
    frame.glowTexture:SetTexCoord(0.082, 0.44, 0.315, 0.49)
    frame.glowTexture:SetAllPoints()
    frame.glowTexture:SetShown(false)
    frame.cooldown = CreateFrame("Cooldown", name .. "_CD", frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetReverse(true)
    frame.cooldown:SetDrawBling(false)
    frame.cooldown:Show()
    frame.textAC = frame:CreateFontString(nil, "LOW")
    frame.textAC:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.lunarColor))
    frame.textAC:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAC:SetPoint("LEFT", self.db.profile.display.spellIcon.predictedEnergy.edgeOffset, 0)
    frame.textAC:SetShown(true)
    frame.textAN = frame:CreateFontString(nil, "LOW")
    frame.textAN:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.lunarColor))
    frame.textAN:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAN:SetPoint("RIGHT", -self.db.profile.display.spellIcon.predictedEnergy.edgeOffset+2, 0)
    frame.textAN:SetShown(true)
    return frame
end


-- Creates a timer frame
function BalanceSpellSuggest:CreateTimerFrame(name, texturePath, xOfs, yOfs)
    local frame  = CreateFrame("Button", name, self.suggestFrame)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetWidth(self.db.profile.display.general.size)
    frame:SetHeight(self.db.profile.display.general.size)
    frame:SetPoint("CENTER", xOfs, yOfs)
    frame:EnableMouse(false)
    frame.bssTexture = frame:CreateTexture(nil, "ARTWORK", nil ,0)
    frame.bssTexture:SetTexture(texturePath)
    frame.bssTexture:SetAllPoints()
    frame.glowTexture = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    frame.glowTexture:SetTexture(glowTexturePath)
    frame.glowTexture:SetTexCoord(0.082, 0.44, 0.315, 0.49)
    frame.glowTexture:SetAllPoints()
    frame.glowTexture:SetShown(false)
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.dotTimer.normalfontsize, self.db.profile.display.general.fontoptions)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    frame.text:SetShown(false)
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.dotTimer.highlightfontsize, self.db.profile.display.general.fontoptions)
    frame.highlightText:SetTextColor(1, 0, 0, 1)
    frame.highlightText:SetAllPoints()
    frame.highlightText:SetShown(false)
    return frame
end


-- Recreates the normal and highlight fonts for a frame
function BalanceSpellSuggest:RecreateFonts(frame)
    local oldtext = frame.text
    frame.text = frame:CreateFontString(nil, "LOW")
    frame.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.dotTimer.normalfontsize, self.db.profile.display.general.fontoptions)
    frame.text:SetTextColor(1, 1, 1, 1)
    frame.text:SetAllPoints()
    oldtext:SetShown(false)
    oldtext = frame.highlightText
    frame.highlightText = frame:CreateFontString(nil, "LOW")
    frame.highlightText:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.dotTimer.highlightfontsize, self.db.profile.display.general.fontoptions)
    frame.highlightText:SetTextColor(1, 0, 0, 1)
    frame.highlightText:SetAllPoints()
    oldtext:SetShown(false)
end


function BalanceSpellSuggest:RecreateSpellFonts(frame)
    local oldtext = frame.textAC
    frame.textAC = frame:CreateFontString(nil, "LOW")
    frame.textAC:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAC:SetTextColor(1, 1, 1, 1)
    frame.textAC:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAC:SetPoint("LEFT", self.db.profile.display.spellIcon.predictedEnergy.edgeOffset, 0)
    frame.textAC:SetShown(self.db.profile.display.spellIcon.predictedEnergy.show)
    oldtext:SetShown(false)
    oldtext = frame.textAN
    frame.textAN = frame:CreateFontString(nil, "LOW")
    frame.textAN:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAN:SetTextColor(1, 1, 1, 1)
    frame.textAN:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAN:SetPoint("RIGHT", -self.db.profile.display.spellIcon.predictedEnergy.edgeOffset+2, 0)
    frame.textAN:SetShown(self.db.profile.display.spellIcon.predictedEnergy.show)
    oldtext:SetShown(false)
end


-- Called on drag stop from the suggestFrame
function BalanceSpellSuggest:StopMoving(frame, _)
    frame:StopMovingOrSizing()

    -- get the coordinates for the offset from center
    for pointnum = 1, frame:GetNumPoints() do
        --local point, relTo, relPoint, x, y = frame:GetPoint(pointnum)
        local xc, yc = frame:GetCenter()
        local w, h = GetScreenWidth(), GetScreenHeight()
        local wh, hh = w/2, h/2
        self.db.profile.display.general.xPosition = -(wh - xc)
        self.db.profile.display.general.yPosition = -(hh - yc)
    end

end


-- Updates the suggestFrame visibility and the inner frames textures/strings
function BalanceSpellSuggest:UpdateFrames()
    -- drag/drop  mode
    if not self.db.profile.display.general.locked then
        self.suggestFrame:Show()
        return
    end

    self:UpdatePlayerState()

    -- we need a target
    if not UnitExists("target") then
        self.suggestFrame:Hide()
        return
    end

    -- which is attackable
    if not UnitCanAttack("player", "target") then
        self.suggestFrame:Hide()
        return
    end

    -- and alive
    if UnitIsDead("target") then
        self.suggestFrame:Hide()
        return
    end

    self.suggestFrame:Show()

    self:UpdateTargetState()

    if self.player.buffs.lunarPeak then
        if self.db.profile.display.dotTimer.peakGlow == "normal" then
            self.moonfireFrame.glowTexture:SetShown(true)
        elseif self.db.profile.display.dotTimer.peakGlow == "spellalert" then
            ActionButton_ShowOverlayGlow(self.moonfireFrame)
        end
    else
        self.moonfireFrame.glowTexture:SetShown(false)
        ActionButton_HideOverlayGlow(self.moonfireFrame)
    end

    if self.player.buffs.solarPeak then
        if self.db.profile.display.dotTimer.peakGlow == "normal" then
            self.sunfireFrame.glowTexture:SetShown(true)
        elseif self.db.profile.display.dotTimer.peakGlow == "spellalert" then
            ActionButton_ShowOverlayGlow(self.sunfireFrame)
        end
    else
        self.sunfireFrame.glowTexture:SetShown(false)
        ActionButton_HideOverlayGlow(self.sunfireFrame)
    end

    if self.db.profile.display.dotTimer.enable then
        self:TimerFrameUpdate(self.moonfireFrame, self.player.target.debuffs.moonfire)
        self:TimerFrameUpdate(self.sunfireFrame, self.player.target.debuffs.sunfire)
    end

    local curTexturePath, afterCurEnergy = self:curSpell()
    local nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, curTexturePath)

    if not curTexturePath or not nextTexturePath then
        -- no suggestions, something went wrong
        return
    end

    local gcd = -1
    if curTexturePath == self.player.currentCast.icon then
        -- is casting the correct spell, show next spell
        self.player.currentCast.isCorrect = true
    elseif self.player.currentCast.icon == nil then
        -- not casting anything, calc next spell based on energy after gcd end
        gcd = self.player.gcd.start + self.player.gcd.duration - self.player.time
        if gcd > 0 then
            afterCurEnergy = self.predictor.getEnergy(gcd, self.player)
            nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, nil)
        end
        self.player.currentCast.isCorrect = false

    else
        -- not casting correct spell, show next spell based on current spell
        afterCurEnergy = self.predictor.getEnergy(self.player.currentCast.castTime, self.player)
        nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, self.player.currentCast.icon)
        self.player.currentCast.isCorrect = false
    end

    if self.player.currentCast.isCorrect then
        -- is casting the correct spell, show next spell
        self.curSpellFrame.bssTexture:SetTexture(nextTexturePath)
    else
        if self.player.currentCast.icon == nil then
            -- not casting anything
            if gcd > 0 then
                self.curSpellFrame.bssTexture:SetTexture(nextTexturePath)
            else
                self.curSpellFrame.bssTexture:SetTexture(curTexturePath)
            end
        else
            -- not casting correct spell, show next spell based on current spell
            self.curSpellFrame.bssTexture:SetTexture(nextTexturePath)
        end
    end

    if afterCurEnergy > 0 then
        self.curSpellFrame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.solarColor))
    else
        afterCurEnergy = math.abs(afterCurEnergy)
        self.curSpellFrame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.lunarColor))
    end
    if afterNextEnergy > 0 then
        self.curSpellFrame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.solarColor))
    else
        afterNextEnergy = math.abs(afterNextEnergy)
        self.curSpellFrame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.lunarColor))
    end
    if afterCurEnergy == 100 then
        self.curSpellFrame.textAC:SetText("*")
    else
        self.curSpellFrame.textAC:SetText(string.format("%.0f", afterCurEnergy))
    end
    if afterNextEnergy == 100 then
        self.curSpellFrame.textAN:SetText("*")
    else
        self.curSpellFrame.textAN:SetText(string.format("%.0f", afterNextEnergy))
    end

    if self.player.buffs.empoweredMoonkin then
        if self.db.profile.display.spellIcon.empMoonkinGlow == "normal" then
            if self.db.profile.display.spellIcon.empMoonkinGlowWhen == "onlyCasts" then
                if isNotInstant(curTexturePath) then
                    self.curSpellFrame.glowTexture:SetShown(true)
                else
                    self.curSpellFrame.glowTexture:SetShown(false)
                end
            else
                self.curSpellFrame.glowTexture:SetShown(true)
            end
        elseif self.db.profile.display.spellIcon.empMoonkinGlow == "spellalert" then
            if self.db.profile.display.spellIcon.empMoonkinGlowWhen == "onlyCasts" then
                if isNotInstant(curTexturePath) then
                    ActionButton_ShowOverlayGlow(self.curSpellFrame)
                else
                    ActionButton_HideOverlayGlow(self.curSpellFrame)
                end
            else
                ActionButton_ShowOverlayGlow(self.curSpellFrame)
            end
        end
    else
        self.curSpellFrame.glowTexture:SetShown(false)
        ActionButton_HideOverlayGlow(self.curSpellFrame)
    end
end


function BalanceSpellSuggest:UpdatePlayerState()
    self.player.time = GetTime()

    local _,_,_,mfC = UnitBuff("player", moonkinformname)
    self.player.moonkinForm = mfC ~= nil

    local _, _, _, t1, t2  = GetTalentInfo(7, 1, GetActiveSpecGroup())
    self.player.talents.euphoria = t1 and t2

    local _, _, _, t1, t2  = GetTalentInfo(7, 2, GetActiveSpecGroup())
    self.player.talents.stellarflare = t1 and t2

    local _, _, _, t1, t2  = GetTalentInfo(7, 3, GetActiveSpecGroup())
    self.player.talents.balanceofpower = t1 and t2

    local _,_,_,_,_,_,emET = UnitBuff("player", empoweredMoonkin)
    self.player.buffs.empoweredMoonkin = emET ~= nil

    local _,_,_,_,_,_,caET = UnitBuff("player", celestialalignmentname)
    self.player.buffs.celestialAlignment = (caET ~= nil and caET - self.player.time) or 0

    self.player.power = UnitPower("player", 8)
    self.player.rawPower = self.player.power
    self.player.direction = GetEclipseDirection()
    self.player.inLunar = false
    self.player.inSolar = false
    if self.player.power < 0 then
        self.player.power = self.player.power * -1
        self.player.inLunar = true
    elseif self.player.power > 0 then
        self.player.inSolar = true
    else
        self.player.power = 0
    end

    self.player.starsurgeCharges = select(1, GetSpellCharges(78674))
    local _,_,_,leC,_,_,leET = UnitBuff("player", lunarempowermentname)
    local _,_,_,seC,_,_,seET = UnitBuff("player", solarempowermentname)
    self.player.buffs.starsurgeLunarBonus = (leET ~= nil and tonumber(leC)) or 0
    self.player.buffs.starsurgeSolarBonus = (seC ~= nil and tonumber(seC)) or 0

    local spell, _, _, icon, startTime, endTime, _, id, interrupt = UnitCastingInfo("player")
    if startTime ~= nil and self.player.currentCast.startTime ~= startTime then
        self.player.currentCast.startPower = self.player.rawPower
    elseif spell == nil then
        self.player.currentCast.startPower = nil
    end

    self.player.currentCast.spell = spell
    self.player.currentCast.icon = icon
    self.player.currentCast.startTime = startTime
    self.player.currentCast.endTime = endTime
    if self.player.currentCast.endTime ~= nil then
        self.player.currentCast.castTime = (endTime - startTime)/1000
    else
        self.player.currentCast.castTime = nil
    end
    self.player.currentCast.id = id
    self.player.currentCast.interruptable = interrupt

    if select(2, GetSpellCooldown(112071)) == 0 then
        self.player.celestialAlignmentReady = true
    else
        self.player.celestialAlignmentReady = false
    end

    local _,_,_,_,_,_,lpET = UnitBuff("player", lunarpeakname)
    local _,_,_,_,_,_,spET = UnitBuff("player", solarpeakname)
    self.player.buffs.lunarPeak = lpET ~= nil
    self.player.buffs.solarPeak = spET ~= nil

    local _,_,_,_,_,_,sfET = UnitBuff("player", starfallname)
    if sfET then
        self.player.buffs.starfall = sfET - self.player.time
    else
        self.player.buffs.starfall = 0
    end

    self:UpdatePlayerCastTimes()
end


function BalanceSpellSuggest:UpdatePlayerCastTimes()
    local curHaste = UnitSpellHaste("player")

    self.player.castTimes.gcd = math.max(self.baseGCD * (1 - (curHaste/100)), 1)
    self.player.castTimes.moonfire = self.player.castTimes.gcd
    self.player.castTimes.sunfire = self.player.castTimes.gcd
    self.player.castTimes.starsurge = self.player.castTimes.gcd
    self.player.castTimes.starfall = self.player.castTimes.gcd
    self.player.castTimes.moonkinform = self.player.castTimes.gcd

    local _,_,_,starfirect =  GetSpellInfo(2912)
    local _,_,_,wrathct = GetSpellInfo(5176)
    local _,_,_,stellarflarect = GetSpellInfo(152221)
    if self.player.buffs.empMoonkin then
        self.player.castTimes.starfire = self.player.castTimes.gcd
        self.player.castTimes.wrath = self.player.castTimes.gcd
        self.player.castTimes.stellarflare = self.player.castTimes.gcd
    else
        self.player.castTimes.starfire = math.max(starfirect / 1000, 1)
        self.player.castTimes.wrath = math.max(wrathct / 1000, 1)
        self.player.castTimes.stellarflare = math.max(stellarflarect / 1000, 1)
    end
end


function BalanceSpellSuggest:UpdateTargetState()
    local time = GetTime()

    local _,_,_,_,_,_,mET,mC = UnitAura("target", moonfirename, nil, "PLAYER|HARMFUL") -- Moonfire
    if mET and mC == "player" then
        self.player.target.debuffs.moonfire = mET - time
    else
        self.player.target.debuffs.moonfire = 0
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", sunfirename, nil, "PLAYER|HARMFUL") -- Sunfire
    if sET and sC == "player" then
        self.player.target.debuffs.sunfire = sET - time
    else
        self.player.target.debuffs.sunfire = 0
    end
    local _,_,_,_,_,_,sET,sC = UnitAura("target", stellarflarename, nil, "PLAYER|HARMFUL") -- Stellar Flare
    if sET and sC == "player" then
        self.player.target.debuffs.stellarflare = sET - time
    else
        self.player.target.debuffs.stellarflare = 0
    end

    local targetclassification = UnitClassification("target")
    local targetLevel = UnitLevel("target")
    if targetclassification == "worldboss" or ((targetLevel < 0 or targetLevel == UnitLevel("player") + 2) and targetclassification == "elite") then
        self.player.target.isBoss = true
    else
        self.player.target.isBoss = false
    end
end


function BalanceSpellSuggest:TimerFrameUpdate(frame, duration)
    if duration <= 0 then
        frame.bssTexture:SetVertexColor(1.0, 0, 0)
        frame.text:SetShown(false)
        frame.highlightText:SetShown(false)
    else
        frame.bssTexture:SetVertexColor(1.0, 1.0, 1.0)
        if duration <= self.db.profile.behavior.dotRefreshTime then
            frame.text:SetShown(false)
            frame.highlightText:SetShown(true)
            frame.highlightText:SetText(string.format("%.1f", duration))
        else
            frame.text:SetShown(true)
            frame.highlightText:SetShown(false)
            frame.text:SetText(string.format("%.0f", duration))
        end
    end
end


function BalanceSpellSuggest:curSpell(player)
    local player = player or self.player

    if not player.moonkinForm then
        return moonkinform, 0
    end

    local minStarsurgeCharges = 0
    if self.db.profile.behavior.leaveOneSSCharge then
        minStarsurgeCharges = 1
    end

    local halfCycle = 20
    if player.talents.euphoria then
        halfCycle = 10
    end

    -- TODO opening rotation
    if not player.inCombat and player.power == 0 then
        return starfire, 0
    end

    if player.buffs.celestialAlignment > 0 then
        -- always do the lunar cycle
        if player.target.debuffs.sunfire < self.db.profile.behavior.dotRefreshTime
                or (player.buffs.celestialAlignment < 4 and player.target.debuffs.sunfire < halfCycle) then
            return moonfire, self.predictor.getEnergy(player.castTimes.moonfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, 0)
        if ss then
            return ss, sse
        end
        if  player.inSolar and player.buffs.starsurgeSolarBonus > 0 then
            return wrath, self.predictor.getEnergy(player.castTimes.wrath, player)
        end
        return starfire, self.predictor.getEnergy(player.castTimes.starfire, player)
    end

    if player.inSolar then
        if player.target.debuffs.sunfire < self.db.profile.behavior.dotRefreshTime
                or (player.direction == "sun" and player.power > 0 and player.target.debuffs.sunfire < 10)
                or (player.direction == "moon" and player.power <= self.db.profile.behavior.dotRefreshPower and player.target.debuffs.sunfire <= halfCycle)
                or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "always")
                or (player.buffs.solarPeak and self.db.profile.behavior.peakBehavior == "time" and player.target.debuffs.sunfire < (halfCycle * 1.5)) then
            return sunfire, self.predictor.getEnergy(player.castTimes.sunfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, minStarsurgeCharges)
        if ss then
            return ss, sse
        end

        local sf, sfe = self:CalcStellarFlare(player)
        if sf then
            return sf, sfe
        end

        local afterWrath = self.predictor.getEnergy(player.castTimes.wrath, player)

        if player.direction == "sun" then
            return wrath, afterWrath
        end

        local afterStarfire = self.predictor.getEnergy(player.castTimes.starfire, player)

        if solarBonus(afterWrath) >= lunarBonus(afterStarfire) then
            return wrath, afterWrath
        else
            return starfire, afterStarfire
        end
    else
        if player.celestialAlignmentReady
            and ((self.db.profile.behavior.caBehavior == "boss" and player.target.isBoss) or self.db.profile.behavior.caBehavior == "always") then
            return celestialalignment, self.predictor.getEnergy(player.castTimes.celestialalignment, player)
        end

        if player.target.debuffs.moonfire < self.db.profile.behavior.dotRefreshTime
                or (player.direction == "sun" and player.power <= self.db.profile.behavior.dotRefreshPower and player.target.debuffs.moonfire <= halfCycle)
                or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "always")
                or (player.buffs.lunarPeak and self.db.profile.behavior.peakBehavior == "time" and player.target.debuffs.moonfire < (halfCycle * 1.5)) then
            return moonfire, self.predictor.getEnergy(player.castTimes.moonfire, player)
        end

        local ss, sse = self:CalcStarsurgeRota(player, minStarsurgeCharges)
        if ss then
            return ss, sse
        end

        local sf, sfe = self:CalcStellarFlare(player)
        if sf then
            return sf, sfe
        end

        local afterStarfire = self.predictor.getEnergy(player.castTimes.starfire, player)

        if player.direction == "moon" then
            return starfire, afterStarfire
        end

        local afterWrath = self.predictor.getEnergy(player.castTimes.wrath, player)

        if solarBonus(afterWrath) > lunarBonus(afterStarfire) then
            return wrath, afterWrath
        else
            return starfire, afterStarfire
        end
    end
    print("returned nil, should not happen!")
    return nil, 0
end


function BalanceSpellSuggest:nextSpell(newEnergy, curCast)
    local player = clone(self.player)
    if newEnergy == nil then
        newEnergy = 0
        print("newEnergy was nil!")
    end

    if not player.inCombat then
        player.inCombat = true
    end

    if curCast == starsurge then
        player.starsurgeCharges = math.max(player.starsurgeCharges - 1, 0)
        if player.inSolar then
            player.buffs.starsurgeSolarBonus = 3
        else
            player.buffs.starsurgeLunarBonus = 2
        end
    elseif curCast == starfall then
        player.starsurgeCharges = math.max(player.starsurgeCharges - 1, 0)
        player.buffs.starfall = 10
    elseif curCast == moonfire then
        player.target.debuffs.moonfire = 40
        if player.buffs.celestialAlignment > 0 then
            player.target.debuffs.sunfire = 24
        end
        player.buffs.lunarPeak = false
        if player.talents.balanceofpower then
            player.target.debuffs.moonfire = player.target.debuffs.moonfire + 6
        end
    elseif curCast == sunfire then
        player.target.debuffs.sunfire = 24
        if player.buffs.celestialAlignment > 0 then
            player.target.debuffs.moonfire = 40
        end
        player.buffs.solarPeak = false
        if player.talents.balanceofpower then
            player.target.debuffs.sunfire = player.target.debuffs.sunfire + 4
        end
    elseif curCast == stellarflare then
        player.target.debuffs.stellarflare = 20
    elseif curCast == starfire then
        if player.buffs.starsurgeLunarBonus > 0 then
            player.buffs.starsurgeLunarBonus = math.max(player.buffs.starsurgeLunarBonus - 1, 0)
        end
    elseif curCast == wrath then
        if player.buffs.starsurgeSolarBonus > 0 then
            player.buffs.starsurgeSolarBonus = math.max(player.buffs.starsurgeSolarBonus - 1, 0)
        end
    elseif curCast == celestialalignment then
        player.buffs.celestialAlignment = 15
        player.celestialAlignmentReady = false
    elseif curCast == moonkinform then
        player.moonkinForm = true
    end

    if player.currentCast.icon == nil then
        local castTime = player.castTimes[iconToCastTimeName(curCast)]
        player.time = player.time + castTime

        player.target.debuffs.moonfire = math.max(player.target.debuffs.moonfire - castTime, 0)
        player.target.debuffs.sunfire = math.max(player.target.debuffs.sunfire - castTime, 0)
        player.target.debuffs.stellarflare = math.max(player.target.debuffs.stellarflare - castTime, 0)
        player.buffs.celestialAlignment = math.max(player.buffs.celestialAlignment - castTime, 0)
    else
        local castTime = player.currentCast.castTime
        player.time = (player.currentCast.startTime / 1000) + castTime

        player.target.debuffs.moonfire = math.max(player.target.debuffs.moonfire - castTime, 0)
        player.target.debuffs.sunfire = math.max(player.target.debuffs.sunfire - castTime, 0)
        player.target.debuffs.stellarflare = math.max(player.target.debuffs.stellarflare - castTime, 0)
        player.buffs.celestialAlignment = math.max(player.buffs.celestialAlignment - castTime, 0)
    end

    player.currentCast.startPower = nil
    player.currentCast.spell = nil
    player.currentCast.icon = nil
    player.currentCast.startTime = nil
    player.currentCast.endTime = nil
    player.currentCast.castTime = nil
    player.currentCast.id = nil
    player.currentCast.interruptable = nil

    local oldEnergy = player.rawPower

    if player.direction == "moon" then
        if newEnergy >= oldEnergy then
            player.direction = "sun"
        end
    elseif player.direction == "sun" then
        if newEnergy <= oldEnergy then
            player.direction = "moon"
        end
    end

    player.power = newEnergy
    player.rawPower = newEnergy
    player.inSolar = false
    player.inLunar = false
    if player.power < 0 then
        player.power = player.power * -1
        player.inLunar = true
    elseif player.power > 0 then
        player.inSolar = true
    else
        player.power = 0
    end

    return self:curSpell(player)
end

-- handle starsurge
function BalanceSpellSuggest:CalcStarsurgeRota(player, minCharges)
    if player.inSolar then
        if player.starsurgeCharges > minCharges then
            if (player.starsurgeCharges == 3 and player.buffs.starsurgeSolarBonus > 0) then
                if player.buffs.starfall == 0 and self.db.profile.behavior.starfallOn3StarsurgeCharges then
                    return starfall, self.predictor.getEnergy(player.castTimes.starfall, player)
                else
                    return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
                end
            end
            if (player.starsurgeCharges == 3 or player.buffs.starsurgeSolarBonus == 0) then
                return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
            end
        end
    else -- lunar and none
        if player.starsurgeCharges > minCharges then
            if (player.starsurgeCharges == 3 and player.buffs.starsurgeLunarBonus > 0) then
                if player.buffs.starfall == 0 and self.db.profile.behavior.starfallOn3StarsurgeCharges then
                    return starfall, self.predictor.getEnergy(player.castTimes.starfall, player)
                else
                    return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
                end
            end
            if (player.starsurgeCharges == 3 or player.buffs.starsurgeLunarBonus == 0) then
                return starsurge, self.predictor.getEnergy(player.castTimes.starsurge, player)
            end
        end
    end
    return nil
end


function BalanceSpellSuggest:CalcStellarFlare(player)
    if player.talents.stellarflare then
        local afterStellarFlare = self.predictor.getEnergy(player.castTimes.stellarflare, player)
        if player.target.debuffs.stellarflare <= 5 and afterStellarFlare >= -self.db.profile.behavior.stellarFlarePowerWindow and afterStellarFlare <= self.db.profile.behavior.stellarFlarePowerWindow then
            return stellarflare, afterStellarFlare
        end
    end
    return nil
end