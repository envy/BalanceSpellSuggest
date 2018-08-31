if select(2, UnitClass("player")) ~= "DRUID" then
    -- no druid, no addon
    return
end

BalanceSpellSuggest = LibStub("AceAddon-3.0"):NewAddon("BalanceSpellSuggest", "AceTimer-3.0", "AceEvent-3.0", "AceConsole-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("BalanceSpellSuggest", true)
local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
local LBG = LibStub:GetLibrary("LibButtonGlow-1.0")

BalanceSpellSuggest.suggestFrame = nil
BalanceSpellSuggest.curSpellFrame = nil
BalanceSpellSuggest.moonfireFrame = nil
BalanceSpellSuggest.sunfireFrame = nil
BalanceSpellSuggest.updateTimer = nil

BalanceSpellSuggest.masque = {}

local asin = math.asin
local pi = math.pi
local abs = math.abs
local sin = math.sin
local max = math.max
local min = math.min
local floor = math.floor

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

-- tries to show a frame
local function tryShow(frame)
    if frame:CanChangeProtectedState() then
        frame:Show()
    end
end

-- tries to hide a frame
local function tryHide(frame)
    if frame:CanChangeProtectedState() then
        frame:Hide()
    end
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
                ssPowerThreshold = {
                    name = L["SS power threshold"],
                    desc = L["SS power threshold Desc"],
                    type = "range",
                    order = 1,
                    min = 40,
                    max = 90,
                    softMin = 40,
                    softMax = 60,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.startsurgePower = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.startsurgePower end
                },
                ca = {
                    name = L["CA behavior"],
                    desc = L["CABehaviorDesc"],
                    type = "select",
                    order = 2,
                    values = { always = L["CABehaviorAlways"], boss = L["CABehaviorBoss"], never = L["CABehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.CA = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.CA end
                },
                foe = {
                    name = L["FoE behavior"],
                    desc = L["FoEBehaviorDesc"],
                    type = "select",
                    order = 3,
                    values = { always = L["FoEBehaviorAlways"], boss = L["FoEBehaviorBoss"], never = L["FoEBehaviorNever"] },
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.FoE = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.FoE end
                },
                foePowerThreshold = {
                    name = L["FoE power threshold"],
                    desc = L["FoE power threshold Desc"],
                    type = "range",
                    order = 4,
                    min = 0,
                    max = 80,
                    softMin = 0,
                    softMax = 60,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.FoEPower = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.FoEPower end
                },
                foePowerMax = {
                    name = L["FoE power max"],
                    desc = L["FoE power max Desc"],
                    type = "range",
                    order = 5,
                    min = 0,
                    max = 100,
                    softMin = 0,
                    softMax = 100,
                    step = 1,
                    set = function(_, val) BalanceSpellSuggest.db.profile.behavior.FoEPowerMax = val end,
                    get = function(_) return BalanceSpellSuggest.db.profile.behavior.FoEPowerMax end
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
                            name = L["Glow on OF style"],
                            desc = L["Glow on OF style Desc"],
                            type = "select",
                            order = 1,
                            values = { none = L["GlowNone"], normal = L["GlowNormal"], spellalert = L["GlowSpellAlert"] },
                            set = function(_, val)
                                BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlow = val
                                BalanceSpellSuggest:UpdateFramePosition()
                            end,
                            get = function(_) return BalanceSpellSuggest.db.profile.display.spellIcon.empMoonkinGlow end
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
                                textColor = {
                                    name = L["predictedEnergyTextColor"],
                                    type = "color",
                                    order = 4,
                                    get = function(_)
                                        return unpack(BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.textColor)
                                    end,
                                    set = function(_, r, g, b, a)
                                        BalanceSpellSuggest.db.profile.display.spellIcon.predictedEnergy.textColor = {r, g, b, a }
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
            startsurgePower = 50,
            CA = "boss",
            FoE = "boss",
            FoEPower = 20,
            FoEPowerMax = 80,
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
                showGCD = true,
                predictedEnergy = {
                    show = true,
                    fontSize = 13,
                    edgeOffset = 3,
                    textColor = {0, 206/255, 1, 1},
                },
            },
            dotTimer = {
                enable = true,
                normalfontsize = 15,
                highlightfontsize = 17,
                spacing = 0,
            },
        },
    }
}


-- spells and stuff
local moonfirename,_,moonfire = GetSpellInfo(8921)
local sunfirename,_,sunfire = GetSpellInfo(93402)
local starsurgename,_,starsurge = GetSpellInfo(78674)
local lunarstrikename,_,lunarstrike = GetSpellInfo(194153)
local solarwrathname,_,solarwrath = GetSpellInfo(190984)
local stellarflarename,_,stellarflare = GetSpellInfo(202347)
local starfallname,_,starfall = GetSpellInfo(191034)
local celestialalignmentname,_,celestialalignment = GetSpellInfo(194223)
local incarnationname,_,incarnation = GetSpellInfo(102560)
local moonkinformname,_,moonkinform = GetSpellInfo(24858)
local furyofelunename,_,furyofelune = GetSpellInfo(202770)

local lunarempowermentname = GetSpellInfo(164547)
local solarempowermentname = GetSpellInfo(164545)

local owlkinFrenzyname,_,owlkinFrenzy = GetSpellInfo(157228)

local lunarStrikeBase = 12
local solarWrathBase = 8
local sunfireBase = 3
local moonfireBase = 3
local stellarflasebase = 8
local starsurgebase = -40
local starfallbase = -50
local fureyofelunebase = 0
local fureyofelunebasegain = 5

local glowTexturePath = "Interface\\SpellActivationOverlay\\IconAlert"


local function spellToArray(i)
    if i == lunarstrike or i == lunarstrikename then
        return "lunarstrike"
    elseif i == solarwrath or i == solarwrathname then
        return "solarwrath"
    elseif i == stellarflare or i == stellarflarename then
        return "stellarflare"
    elseif i == celestialalignment or i == celestialalignmentname then
        return "celestialalignment"
    elseif i == furyofelune or i == furyofelunename then
        return "furyofelune"
    elseif i == starsurge or i == starsurgename then
        return "starsurge"
    end
    return "gcd"
end

local function texToName(t)
    if t == lunarstrike then
        return lunarstrikename
    elseif t == solarwrath then
        return solarwrathname
    elseif t == stellarflare then
        return stellarflarename
    elseif t == moonfire then
        return moonfirename
    elseif t == solarwrath then
        return solarwrath
    elseif t == starsurge then
        return starsurgename
    elseif t == starfall then
        return starfallname
    elseif t == moonkinform then
        return moonkinformname
    elseif t == incarnation then
        return incarnationname
    end
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
            celestialAlignment = 0,
            starfall = 0,
            starsurgeLunarBonus = 0,
            starsurgeSolarBonus = 0,
            warriorofelune = 0,
            incarnation = 0,
            owlkinFrenzy = 0,
        },
        talents = {
            souloftheforest = false,
            stellarflare = false,
            incarnation = false,
            furyofelune = false,
        },
        castTimes = {
            gcd = 1.5,
            lunarstrike = 0,
            solarwrath = 0,
            stellarflare = 0,
            --newmoon = 0,
            --halfmoon = 0,
            --fullmoon = 0,
            starsurge = 1.5, -- GCD
            starfall = 1.5, -- GCD
            moonfire = 1.5, -- GCD
            sunfire = 1.5, -- GCD
            moonkinform = 1.5, -- GCD
            celestialalignment = 1.5, -- GCD
            furyofelune = 1.5, -- GCD
            solarbeam = 0, -- no GCD
        },
        astralpower = {
            gcd = 0,
            lunarstrike = lunarStrikeBase,
            solarwrath = solarWrathBase,
            stellarflare = stellarflasebase,
            --newmoon = newmoonbase,
            --halfmoon = halfmoonbase,
            --fullmoon = fullmoonbase,
            starsurge = starsurgebase,
            starfall = starfallbase,
            moonfire = moonfireBase,
            sunfire = sunfireBase,
            moonkinform = 0,
            celestialalignment = 0,
            furyofelune = fureyofelunebase,
            solarbeam = 0,
        },
        inCombat = false,
        power = 0,
        currentCast = {
            spell = nil,
            icon = nil,
            startPower = nil,
            startTime = nil,
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
        celestialAlignmentCD = 0,
        --newMoonReady = false,
        --halfMoonReady = false,
        --fullMoonReady = false,
        furyOfEluneCD = 0,
        furyOfEluneTime = 0,
        incarnationReady = false,
        --moonCharges = 0,
        --moonChargeCDStart = 0,
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

    tryHide(self.suggestFrame)
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
        tryShow(self.moonfireFrame)
        tryShow(self.sunfireFrame)
    else
        self.suggestFrame:SetWidth(self.db.profile.display.general.size)
        tryHide(self.moonfireFrame)
        tryHide(self.sunfireFrame)
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
        tryShow(self.suggestFrame)
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
    frame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))
    frame.textAC:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAC:SetPoint("LEFT", self.db.profile.display.spellIcon.predictedEnergy.edgeOffset, 0)
    frame.textAC:SetShown(true)
    frame.textAN = frame:CreateFontString(nil, "LOW")
    frame.textAN:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))
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
    frame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))
    frame.textAC:SetPoint("BOTTOM", 0, self.db.profile.display.spellIcon.predictedEnergy.edgeOffset)
    frame.textAC:SetPoint("LEFT", self.db.profile.display.spellIcon.predictedEnergy.edgeOffset, 0)
    frame.textAC:SetShown(self.db.profile.display.spellIcon.predictedEnergy.show)
    oldtext:SetShown(false)
    oldtext = frame.textAN
    frame.textAN = frame:CreateFontString(nil, "LOW")
    frame.textAN:SetFont(LSM:Fetch(LSM.MediaType.FONT, self.db.profile.display.general.font), self.db.profile.display.spellIcon.predictedEnergy.fontSize, self.db.profile.display.general.fontoptions)
    frame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))
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
        tryShow(self.suggestFrame)
        return
    end

    self:UpdatePlayerState()

    -- we need a target
    if not UnitExists("target") then
        tryHide(self.suggestFrame)
        return
    end

    -- which is attackable
    if not UnitCanAttack("player", "target") then
        tryHide(self.suggestFrame)
        return
    end

    -- and alive
    if UnitIsDead("target") then
        tryHide(self.suggestFrame)
        return
    end

    tryShow(self.suggestFrame)

    self:UpdateTargetState()

    if self.db.profile.display.dotTimer.enable then
        self:TimerFrameUpdate(self.moonfireFrame, self.player.target.debuffs.moonfire)
        self:TimerFrameUpdate(self.sunfireFrame, self.player.target.debuffs.sunfire)
    end

    local curTexturePath, afterCurEnergy = self:curSpell()
    local nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, texToName(curTexturePath))

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
            afterCurEnergy = self.player.power
            nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, nil)
        end
        self.player.currentCast.isCorrect = false

    else
        -- not casting correct spell, show next spell based on current spell
        afterCurEnergy = self.player.power + self.player.astralpower[spellToArray(self.player.currentCast.spell)]
        afterCurEnergy = self.player.power + self.player.astralpower[spellToArray(self.player.currentCast.spell)]
        nextTexturePath, afterNextEnergy = self:nextSpell(afterCurEnergy, self.player.currentCast.spell)
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

    self.curSpellFrame.textAC:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))
    self.curSpellFrame.textAN:SetTextColor(unpack(self.db.profile.display.spellIcon.predictedEnergy.textColor))

    if afterCurEnergy >= 100 then
        self.curSpellFrame.textAC:SetText("*")
    else
        self.curSpellFrame.textAC:SetText(string.format("%.0f", afterCurEnergy))
    end
    if afterNextEnergy >= 100 then
        self.curSpellFrame.textAN:SetText("*")
    else
        self.curSpellFrame.textAN:SetText(string.format("%.0f", afterNextEnergy))
    end

    if self.player.buffs.owlkinFrenzy > 0 then
        if self.db.profile.display.spellIcon.empMoonkinGlow == "normal" then
            self.curSpellFrame.glowTexture:SetShown(true)
        elseif self.db.profile.display.spellIcon.empMoonkinGlow == "spellalert" then
            LBG.ShowOverlayGlow(self.curSpellFrame)
        end
    else
        self.curSpellFrame.glowTexture:SetShown(false)
        LBG.HideOverlayGlow(self.curSpellFrame)
    end
end


function BalanceSpellSuggest:UpdatePlayerState()
    self.player.time = GetTime()

    local _, _, mfC = AuraUtil.FindAuraByName(moonkinformname, "player")
    self.player.moonkinForm = mfC ~= nil

    local _, _, _, t1, t2  = GetTalentInfo(6, 3, GetActiveSpecGroup())
    self.player.talents.stellarflare = t1 and t2

    local _, _, _, t1, t2  = GetTalentInfo(5, 3, GetActiveSpecGroup())
    self.player.talents.incarnation = t1 and t2

    local _, _, _, t1, t2  = GetTalentInfo(7, 2, GetActiveSpecGroup())
    self.player.talents.furyofelune = t1 and t2

    local _, _, _, t1, t2  = GetTalentInfo(5, 1, GetActiveSpecGroup())
    self.player.talents.souloftheforest = t1 and t2

    local _, _, _, _, _, caET = AuraUtil.FindAuraByName(celestialalignmentname, "player")
    self.player.buffs.celestialAlignment = (caET ~= nil and caET - self.player.time) or 0

    self.player.power = UnitPower("player", SPELL_POWER_ECLIPSE)

    --self.player.moonCharges = select(1, GetSpellCharges(202767)) or 0
    --self.player.moonChargeCDStart = select(3, GetSpellCharges(202767))
    --if self.player.moonCharges == nil then
    --    self.player.moonCharges = select(1, GetSpellCharges(202768))
    --    if self.player.moonCharges == nil then
    --        self.player.moonCharges = select(1, GetSpellCharges(202771))
    --    end
    --end
    --print(self.player.moonCharges)
    --print(self.player.moonChargeCDStart)

    local _,_,leC,_,_,leET = AuraUtil.FindAuraByName(lunarempowermentname, "player")
    local _,_,seC,_,_,seET = AuraUtil.FindAuraByName(solarempowermentname, "player")
    self.player.buffs.starsurgeLunarBonus = (leET ~= nil and tonumber(leC)) or 0
    self.player.buffs.starsurgeSolarBonus = (seC ~= nil and tonumber(seC)) or 0

    local spell, _, icon, startTime, endTime, _, id, interrupt = UnitCastingInfo("player")
    if startTime ~= nil and self.player.currentCast.startTime ~= startTime then
        self.player.currentCast.startPower = self.player.power
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

    local start, dur, _, _ = GetSpellCooldown(194223)
    if dur > 0 then
        self.player.celestialAlignmentCD = dur - (self.player.time - start)
    else
        self.player.celestialAlignmentCD = 0
    end

    if select(2, GetSpellCooldown(102560)) == 0 then
        self.player.incarnationReady = true
    else
        self.player.incarnationReady = false
    end

    local start, dur, _, _ = GetSpellCooldown(202770)
    if dur > 0 then
        self.player.furyOfEluneCD = dur - (self.player.time - start)
        -- FoE has a CD of 60s and is active for 8.
        self.player.fureOfEluneTime = max(8 - (60 - self.player.furyOfEluneCD), 0)
    else
        self.player.furyOfEluneCD = 0
        self.player.furyOfEluneTime = 0
    end



    -- self.player.furyOfEluneCD = min(self.player.time - select(1, GetSpellCooldown(202770)), 0)
    --print("t: "..tostring(self.player.time).." cd: "..tostring(select(1, GetSpellCooldown(202770))))

    --local _,_,moonIcon = GetSpellInfo(202767)
    --if select(2, GetSpellCooldown(202767)) == 0 and nmoC ~= nil and hmoC ~= nil then
    --if moonIcon == newMoonIcon and self.player.moonCharges > 0 then
    --    self.player.newMoonReady = true
    --else
    --    self.player.newMoonReady = false
    --end

    --if select(2, GetSpellCooldown(202768)) == 0 and nmoC == nil and hmoC ~= nil then
    --if moonIcon == halfMoonIcon and self.player.moonCharges > 0 then
    --    self.player.halfMoonReady = true
    --else
    --    self.player.halfMoonReady = false
    --end

    --if select(2, GetSpellCooldown(202771)) == 0 and nmoC == nil and hmoC == nil then
    --if moonIcon == fullMoonIcon and self.player.moonCharges > 0 then
    --    self.player.fullMoonReady = true
    --else
    --    self.player.fullMoonReady = false
    --end
    --print("nmoC: "..tostring(nmoC~=nil).." hmoC: "..tostring(hmoC~=nil))
    --print("foe: "..tostring(self.player.furyOfEluneCD).." nm: "..tostring(self.player.newMoonReady).." hm: "..tostring(self.player.halfMoonReady).." fm: "..tostring(self.player.fullMoonReady))

    local _,_,_,_,_,sfET = AuraUtil.FindAuraByName(starfallname, "player")
    if sfET then
        self.player.buffs.starfall = sfET - self.player.time
    else
        self.player.buffs.starfall = 0
    end

    local _,_,_,_,_,ofET = AuraUtil.FindAuraByName(owlkinFrenzyname, "player")
    if ofET then
        self.player.buffs.owlkinFrenzy = 1
    else
        self.player.buffs.owlkinFrenzy = 0
    end

    self:UpdatePlayerCostAndGains()
end


function BalanceSpellSuggest:UpdatePlayerCostAndGains()
    local curHaste = UnitSpellHaste("player")

    self.player.castTimes.gcd = max(self.baseGCD * (1 - (curHaste/100)), 1)

    local _,_,_,lunarstrikect =  GetSpellInfo(194153)
    local _,_,_,solarwrathct = GetSpellInfo(190984)
    local _,_,_,stellarflarect = GetSpellInfo(202347)
    --local _,_,_,newmoonct = GetSpellInfo(202767)
    --local _,_,_,halfmoonct = GetSpellInfo(202768)
    --local _,_,_,fullmoonct = GetSpellInfo(202771)

    if self.player.buffs.owlkinFrenzy > 0 then
        self.player.castTimes.lunarstrike = self.player.castTimes.gcd
    else
        self.player.castTimes.lunarstrike = max(lunarstrikect / 1000, 1)
        self.player.castTimes.solarwrath = max(solarwrathct / 1000, 1)
        self.player.castTimes.stellarflare = max(stellarflarect / 1000, 1)
        --self.player.castTimes.newmoon = max(newmoonct / 1000, 1)
        --self.player.castTimes.halfmoon = max(halfmoonct / 1000, 1)
        --self.player.castTimes.fullmoon = max(fullmoonct / 1000, 1)
    end

    self.player.astralpower.solarwrath = solarWrathBase
    self.player.astralpower.lunarstrike = lunarStrikeBase
    self.player.astralpower.moonfire = moonfireBase
    self.player.astralpower.sunfire = sunfireBase
    self.player.astralpower.starfall = starfallbase

    if self.player.talents.souloftheforest then
        self.player.astralpower.starfall = min(self.player.astralpower.starfall + 10, 0)
    end

end


function BalanceSpellSuggest:UpdateTargetState()
    local time = GetTime()

    local _,_,_,_,_,mET,mC = AuraUtil.FindAuraByName(moonfirename, "target", "PLAYER|HARMFUL") -- Moonfire
    if mET and mC == "player" then
        self.player.target.debuffs.moonfire = mET - time
    else
        self.player.target.debuffs.moonfire = 0
    end
    local _,_,_,_,_,sET,sC = AuraUtil.FindAuraByName(sunfirename, "target", "PLAYER|HARMFUL") -- Sunfire
    if sET and sC == "player" then
        self.player.target.debuffs.sunfire = sET - time
    else
        self.player.target.debuffs.sunfire = 0
    end
    local _,_,_,_,_,sET,sC = AuraUtil.FindAuraByName(stellarflarename, "target", "PLAYER|HARMFUL") -- Stellar Flare
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


function BalanceSpellSuggest:nextPower(player, cast)
    local foebonus = 0
    if player.furyOfEluneTime > 0 then
        if player.castTimes[cast] <= player.furyOfEluneTime then
            foebonus = player.castTimes[cast] * fureyofelunebasegain
        else
            foebonus = player.furyOfEluneTime * fureyofelunebasegain
        end
    end
    return player.power + foebonus + player.astralpower[cast]
end


function BalanceSpellSuggest:curSpell(player)
    local player = player or self.player

    -- we need moonkinform
    if not player.moonkinForm then
        return moonkinform, self:nextPower(player, "moonkinform")
    end

    -- opener
    if not player.inCombat and player.power == 0 then
        return solarwrath, self:nextPower(player, "solarwrath")
    end

    -- we check if the dots are on the target for longer then SW cast time
    -- this seems weirds, because then the first condition will also be true
    -- however, if for some reason cast time of SW is longer, we ensure that dots do not fall off
    if player.target.debuffs.moonfire < 6.6 or player.target.debuffs.moonfire <= player.castTimes.solarwrath then
        return moonfire, self:nextPower(player, "moonfire")
    end

    if player.target.debuffs.sunfire < 5.4 or player.target.debuffs.sunfire <= player.castTimes.solarwrath then
        return sunfire, self:nextPower(player, "sunfire")
    end

    -- if stellar flare is skilled, also check this
    if player.talents.stellarflare and (player.target.debuffs.stellarflare < 7.2 or player.target.debuffs.stellarflare <= player.castTimes.solarwrath) then
        return stellarflare, self:nextPower(player, "stellarflare")
    end

    -- if OF is active and we don't have 3 SW emps, cast LS
    -- why check SW emps? because LS ca proc a SW emp through Eclipse
    if player.buffs.owlkinFrenzy > 0 and
       player.buffs.starsurgeSolarBonus < 3 then
        return lunarstrike, self:nextPower(player, "lunarstrike")
    end

    -- get rid of empowerments
    if player.buffs.starsurgeSolarBonus == 3 and player.buffs.starsurgeLunarBonus < 3 then
        return solarwrath, self:nextPower(player, "solarwrath")
    elseif player.buffs.starsurgeSolarBonus < 3 and player.buffs.starsurgeLunarBonus == 3 then
        return lunarstrike, self:nextPower(player, "lunarstrike")
    elseif player.buffs.starsurgeSolarBonus == 3 and player.buffs.starsurgeLunarBonus == 3 then
        -- both at 3, does not matter which, use solar because faster cast
        return solarwrath, self:nextPower(player, "solarwrath")
    end

    -- FoE checks
    if player.talents.furyofelune and
       (self.db.profile.behavior.FoE == 'always' or (self.db.profile.behavior.FoE == 'boss' and player.target.isBoss)) and
       player.power >= self.db.profile.behavior.FoEPower and
       player.power <= self.db.profile.behavior.FoEPowerMax and
       player.furyOfEluneCD == 0
    then
       return furyofelune, self:nextPower(player, "furyofelune")
    end

    if (self.db.profile.behavior.CA == 'always' or (self.db.profile.behavior.CA == 'boss' and player.target.isBoss)) then
        -- if FoE is skilled and should be displayed
        if player.celestialAlignmentCD == 0 then
            -- and its off cooldown
            return celestialalignment, self:nextPower(player, "celestialalignment")
        end
    end

    if player.power >= self.db.profile.behavior.startsurgePower then
        -- if we are above X AP and are not capped with empowerments, cast starsurge
        if player.buffs.starsurgeSolarBonus < 2 and player.buffs.starsurgeLunarBonus < 2 then
            return starsurge, self:nextPower(player, "starsurge")
        end
    end

    -- in all other cases
    if player.buffs.starsurgeLunarBonus > player.buffs.starsurgeSolarBonus then
        -- if we have more lunar emps than solar, cast lunar otherwise cast solar
        return lunarstrike, self:nextPower(player, "lunarstrike")
    end

    -- otherwise, cast SW
    return solarwrath, self:nextPower(player, "solarwrath")
end


function BalanceSpellSuggest:nextSpell(newEnergy, curCastName)
    local player = clone(self.player)
    if newEnergy == nil then
        newEnergy = 0
        print("newEnergy was nil!")
    end

    if not player.inCombat then
        player.inCombat = true
    end

    if curCastName == starsurgename then
        player.buffs.starsurgeSolarBonus = max(player.buffs.starsurgeSolarBonus + 1, 3)
        player.buffs.starsurgeLunarBonus = max(player.buffs.starsurgeLunarBonus + 1, 3)
    elseif curCastName == starfallname then
        player.buffs.starfall = 8
    elseif curCastName == moonfirename then
        player.target.debuffs.moonfire = 22
    elseif curCastName == sunfirename then
        player.target.debuffs.sunfire = 18
    elseif curCastName == stellarflarename then
        player.target.debuffs.stellarflare = 24
    elseif curCastName == lunarstrikename then
        if player.buffs.starsurgeLunarBonus > 0 then
            player.buffs.starsurgeLunarBonus = max(player.buffs.starsurgeLunarBonus - 1, 0)
        end
        if player.buffs.owlkinFrenzy > 0 then
            player.buffs.owlkinFrenzy = 0
        end
    elseif curCastName == solarwrathname then
        if player.buffs.starsurgeSolarBonus > 0 then
            player.buffs.starsurgeSolarBonus = max(player.buffs.starsurgeSolarBonus - 1, 0)
        end
    elseif curCastName == celestialalignmentname then
        player.buffs.celestialAlignment = 20
        player.celestialAlignmentReady = false
    elseif curCastName == moonkinformname then
        player.moonkinForm = true
    end

    local oldTime = player.time

    local castTime
    if player.currentCast.icon == nil then
        castTime = player.castTimes[spellToArray(curCastName)]
        player.time = player.time + castTime
    else
        castTime = player.currentCast.castTime
        player.time = (player.currentCast.startTime / 1000) + castTime
    end

    local timeDiff = player.time - oldTime

    player.target.debuffs.moonfire = max(player.target.debuffs.moonfire - castTime, 0)
    player.target.debuffs.sunfire = max(player.target.debuffs.sunfire - castTime, 0)
    player.target.debuffs.stellarflare = max(player.target.debuffs.stellarflare - castTime, 0)
    player.buffs.celestialAlignment = max(player.buffs.celestialAlignment - castTime, 0)

    --if player.time - player.moonChargeCDStart >= 15 then
    --    player.moonCharges = min(3, player.moonCharges + 1)
    --end

    player.furyOfEluneCD = max(player.furyOfEluneCD - timeDiff, 0)
    player.furyOfEluneTime = max(player.furyOfEluneTime - timeDiff, 0)

    player.currentCast.startPower = nil
    player.currentCast.spell = nil
    player.currentCast.icon = nil
    player.currentCast.startTime = nil
    player.currentCast.endTime = nil
    player.currentCast.castTime = nil
    player.currentCast.id = nil
    player.currentCast.interruptable = nil

    local oldEnergy = player.power

    player.power = newEnergy

    return self:curSpell(player)
end
