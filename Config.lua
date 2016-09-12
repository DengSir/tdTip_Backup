
local Addon = LibStub('AceAddon-3.0'):GetAddon('tdTip')
local L = LibStub('AceLocale-3.0'):GetLocale('tdTip')

function Addon:LoadOptionFrame()
    local order = 0
    local function makeorder()
        order = order + 1
        return order
    end

    local function createColorGroup(name, ...)
        local info = {
            type = 'group',
            inline = true,
            name = name,
            order = makeorder(),
            get = function(item)
                local color = Addon.db.profile.colors[item[#item]]
                return color.r, color.g, color.b
            end,
            set = function(item, r, g, b)
                local color = Addon.db.profile.colors[item[#item]]
                color.r, color.g, color.b = r, g, b
            end,
            args = {}
        }

        for i = 1, select('#', ...), 2 do
            local key, name = select(i, ...)
            info.args[key] = {
                type = 'color',
                name = name,
                order = makeorder(),
                width = 'full',
            }
        end
        return info
    end

    local options = {
        type = 'group',
        name = L['tdTip Options'],
        childGroups = 'tab',
        args = {
            enable = {
                type = 'toggle',
                name = ENABLE,
                order = makeorder(),
                get = function() return Addon:IsEnabled() end,
                set = function(_, value)
                    if value then
                        Addon:Enable()
                    else
                        Addon:Disable()
                    end
                end,
            },

            general = {
                type = 'group',
                name = GENERAL,
                order = makeorder(),
                -- inline = true,
                disabled = function() return not Addon:IsEnabled() end,
                get = function(item)
                    return self.db.profile[item[#item]]
                end,
                set = function(item, value)
                    self.db.profile[item[#item]] = value
                end,
                args = {
                    showPVPName = {
                        type = 'toggle',
                        name = L['Show PVP Name'],
                        width = 'full',
                        order = makeorder(),
                    },
                    showGuildRank = {
                        type = 'toggle',
                        name = L['Show Guild Rank'],
                        width = 'full',
                        order = makeorder(),
                    },
                    showTarget = {
                        type = 'toggle',
                        name = L['Show Target'],
                        width = 'full',
                        order = makeorder(),
                    },
                    showClassIcon = {
                        type = 'toggle',
                        name = L['Show Class Icon'],
                        width = 'full',
                        order = makeorder(),
                    },
                    classIconSize = {
                        type = 'range',
                        min = 10,
                        max = 64,
                        step = 1,
                        name = L['Class Icon Size'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function() return not self.db.profile.showClassIcon end,
                    },
                }
            },
            extraIcon = {
                type = 'group',
                name = L['Extra Icon'],
                order = makeorder(),
                disabled = function() return not Addon:IsEnabled() end,
                get = function(item)
                    return self.db.profile[item[#item]]
                end,
                set = function(item, value)
                    self.db.profile[item[#item]] = value
                end,
                args = {
                    showExtraIcon = {
                        type = 'toggle',
                        name = ENABLE,
                        width = 'full',
                        order = makeorder(),
                    },
                    showRaidIcon = {
                        type = 'toggle',
                        name = L['Show Raid Icon'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function()
                            return not self.db.profile.showExtraIcon
                        end,
                    },
                    showPetIcon = {
                        type = 'toggle',
                        name = L['Show BattlePet Icon'],
                        width = 'full',
                        order = makeorder(),
                        hidden = true,
                        disabled = function()
                            return not self.db.profile.showExtraIcon
                        end,
                    },
                    showFacIcon = {
                        type = 'toggle',
                        name = L['Show Faction Icon'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function()
                            return not self.db.profile.showExtraIcon
                        end,
                    },
                    showNpcFacIcon = {
                        type = 'toggle',
                        name = L['Show NPC Faction Icon'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function()
                            return not self.db.profile.showExtraIcon or not self.db.profile.showFacIcon
                        end,
                    },
                    extraIconSize = {
                        type = 'range',
                        min = 24,
                        max = 64,
                        step = 1,
                        name = L['Icon Size'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function() return not self.db.profile.showExtraIcon end,
                    },
                    extraIconOffsetX = {
                        type = 'range',
                        min = -100,
                        max = 100,
                        step = 1,
                        name = L['X Offset'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function() return not self.db.profile.showExtraIcon end,
                    },
                    extraIconOffsetY = {
                        type = 'range',
                        min = -100,
                        max = 100,
                        step = 1,
                        name = L['Y Offset'],
                        width = 'full',
                        order = makeorder(),
                        disabled = function() return not self.db.profile.showExtraIcon end,
                    },
                },
            },
            textColor = {
                type = 'group',
                name = L['Text Color'],
                order = makeorder(),
                disabled = function() return not Addon:IsEnabled() end,
                args = {
                    guildColor = createColorGroup(L['Guild Text Color'],
                        'guild', L['Guild'],
                        'sameGuild', L['Same Guild']
                    ),
                    serverColor = createColorGroup(L['Server Text Color'],
                        'server', L['Server'],
                        'sameServer', L['Same Virtual Server']
                    ),
                    raceColor = createColorGroup(L['Race Text Color'],
                        'friend', L['Friend'],
                        'enemy', L['Enemy']
                    )
                }
            },
        }
    }

    local profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(self.db)

    local registry = LibStub('AceConfigRegistry-3.0')
    registry:RegisterOptionsTable('tdTip Options', options)
    registry:RegisterOptionsTable('tdTip Profiles', profiles)

    local dialog = LibStub('AceConfigDialog-3.0')
    dialog:AddToBlizOptions('tdTip Options', 'tdTip')
    dialog:AddToBlizOptions('tdTip Profiles', L['Profiles'], 'tdTip')
end
