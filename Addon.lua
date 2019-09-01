-- Addon.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/30/2019, 11:22:04 PM

local ns = select(2, ...)
local Addon = LibStub('AceAddon-3.0'):NewAddon('tdTip')

ns.Addon = Addon

function Addon:OnInitialize()
    local defaults = {
        profile = {
            showPVPName = false,
            showGuildRank = false,
            showTarget = true,
            showClassIcon = true,
            classIconSize = 22,
            showExtraIcon = true,
            showRaidIcon = true,
            showPetIcon = false,
            showFacIcon = true,
            showNpcFacIcon = false,
            extraIconSize = 48,
            extraIconOffsetX = 0,
            extraIconOffsetY = -5,
            colors = {
                guild = {r = 1.00, g = 0.00, b = 1.00},
                sameGuild = {r = 1.00, g = 0.31, b = 0.38},
                server = {r = 0.67, g = 1.00, b = 1.00},
                sameServer = {r = 0.34, g = 0.35, b = 1.00},
                friend = {r = 0.00, g = 1.00, b = 0.20},
                enemy = {r = 1.00, g = 0.20, b = 0.00},
            },
        },
    }

    self.db = LibStub('AceDB-3.0'):New('TDDB_TIP', defaults, true)

    if self.LoadOptionFrame then
        self:LoadOptionFrame()
    end
end
