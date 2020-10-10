URBA_VERSION = '0.1a'
URBA_CONFIG_PATH = getPath('.', 'UniversalRBA', 'Settings.cfg')
local UniversalRBA = require('URBA')
local configReader = require('URBA.configReader')

LogWarning('  >>> Universal RBA       version: %s', URBA_VERSION)
Log('   |')
Log('   |')
local config = configReader.read(URBA_CONFIG_PATH)
if not config then
    LogWarning('    >>>     Error: Failed to Find URBA Configuration file @ %s', URBA_CONFIG_PATH)
    return
else
    -- ! check we have a valid config file
    if not type(config['Owners']) == 'table' then
        LogWarning('    >>>     Error: Failed to Start, Settings.cfg missing Owners Key')
        return
    end
    -- ! make sure we have at least 1 owner
    local OwnerCount = (#config.Owners or 0)
    if (OwnerCount < 1) then
        LogWarning('    >>>     Error: Failed to Start, Owners Key Must have at least one entry in Settings.cfg')
    end

    --
    -- ! ───────────────────── INITIALISE UNIVERSALRBA WITH OWNERS FROM CONFIG FILE ─────
    --
    --- UniversalRBA
    ---@type URBA
    URBA = UniversalRBA({owners = table_update({}, config.Owners)})

    --- URBA BUILTIN Permission mapping
    local URBA_PERM = {
        --- Manage all URBA Roles (but not Owner/Admin)
        MANAGE_ROLES = 'URBA.MANAGE_ROLES',
        --- Manage all URBA Permissions (but not Owner/Admin)
        MANAGE_PERMISSIONS = 'URBA.MANAGE_PERMISSIONS',
        --- Manage all URBA Users (but not Owner/Admin)
        MANAGE_USERS = 'URBA.MANAGE_USERS',
    }

    --- URBA Server Owner (can do everything and bypasses permission checks)
    local URBA_OWNER = 'URBA.OWNER'

    --- URBA Server Admin (can do everything)
    local URBA_ADMIN = 'URBA.ADMIN'

    --- URBA Server Developer (has acces to debug commands and bypasses permission checks other than owner/admin)
    local URBA_DEVELOPER = 'URBA.DEVELOPER'

    --- URBA Player (standard access)
    local URBA_PLAYER = 'URBA.PLAYER'

    -- ! ───────────────────────────────────── UNSURE OUR DEFAULT ROLES ARE CREATED ─────
    --
    -- ! ─── SERVER OWNER ROLE ──────────────────────────────────────────────────────────
    --
    local ServerOwner = URBA:createRole('Owner', 'A Server Owner.')
    -- ? Owners Can Manage Everything
    ServerOwner:createPermission(URBA_DEVELOPER, true)
    ServerOwner:createPermission(URBA_OWNER, true)
    ServerOwner:createPermission(URBA_ADMIN, true)

    --
    ---! ─── ADMIN ROLE ─────────────────────────────────────────────────────────────────
    --
    local AdminRole = URBA:createRole('Admin', 'A Server Admin.')
    -- ? Admin Can Manage Everything
    ServerOwner:createPermission(URBA_DEVELOPER, true)
    ServerOwner:createPermission(URBA_ADMIN, true)

    --
    -- ! ─── PLAYER ROLE ────────────────────────────────────────────────────────────────
    --
    local PlayerRole = URBA:createRole('Player', 'A Player.')
    PlayerRole:createPermission(URBA_PLAYER, true)

    local URBA_NEW_PLAYER = require('URBA_Player')
    function URBA:Player(player) return URBA_NEW_PLAYER(player) end
end
