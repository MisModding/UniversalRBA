if not MisDB then require('MisDB') end
local Database = MisDB:Create('UniversalRBA/', 'UniversalRBA')

local PlayersCollection = Database:Collection('URBA_Players')

local URBA_PLAYER = Class {
    __type = 'UniversalRBA Player',
    __collection = PlayersCollection,
    PlayerData = {
        Permissions = {},
        Roles = {3}, -- players are allways in Player Role
    },
}

function URBA_PLAYER:new(player)
    if not player or not player.player then return false, 'invalid player' end
    local steamId = player.player:GetSteam64Id()
    self.PlayerData = self.__collection:GetPage(steamId) or {}
    self.PlayerData['Name'] = player:GetName()
    self.PlayerData['SteamId'] = steamId
    self:saveData()
end
function URBA_PLAYER:saveData() self.__collection:SetPage(self.PlayerData['SteamId'], self.PlayerData) end

function URBA_PLAYER:setName(name) self.PlayerData['Name'] = name end

function URBA_PLAYER:getName() return self.PlayerData['Name'] end

---* Add this Player to a Role
---@param roleId number
function URBA_PLAYER:AddRole(roleId)
    if assert_arg(1, roleId, 'number') then return false, 'invalid roleId (must ba number)' end
    local new_role = URBA:getRoleById(roleId)
    if new_role then
        if FindInTable(self.PlayerData['Roles'], 'roleId', new_role.id) then
            return true, 'player allready in specified role'
        end
        InsertIntoTable(self.PlayerData['Roles'], {roleId = new_role.id, name = new_role.Name})
        self:saveData()
        return true, 'added player to specified role'
    end
    return false, 'unknown role'
end

function URBA_PLAYER:ClearRole(roleId)
    if assert_arg(1, roleId, 'number') then return false, 'invalid roleId (must ba number)' end
    local clear_role = URBA:getRoleById(roleId)
    if clear_role then
        RemoveFromTable(self.PlayerData['Roles'], {roleId = clear_role.id, name = clear_role.Name})
        self:saveData()
        return true, 'removed player from specified role'
    end
    return true, 'player not in specified role'
end

---* Fetch all Roles this Player is a member of
function URBA_PLAYER:Roles()
    local player_roles = {}
    for i, role in pairs(self.PlayerData['Roles']) do player_roles[role.name] = URBA:getRoleById(role.roleId) end
    return player_roles
end

---* Checks if a member of and Fetches a specific named role
function URBA_PLAYER:GetRoleByName(name)
    local found_role = FindInTable(self.PlayerData['Roles'], 'name', name)
    if found_role then return URBA:getRoleById(found_role.roleId), 'player in found role' end
    return false, 'player not in specified role'
end

---* Check if a member of and Fetches a specific role by Id
function URBA_PLAYER:GetRoleById(roleId)
    local found_role = FindInTable(self.PlayerData['Roles'], 'roleId', roleId)
    if found_role then return URBA:getRoleById(found_role.roleId), 'player in found role' end
    return false, 'player not in specified role'
end

---* Set a Permission for this Player
---| name must be a string, values can be `string`,`number`,`boolean`
---@param name string `required: permission name`
---@param value string|number|boolean `required: permission value`
function URBA_PLAYER:setPermission(name, value)
    if assert_arg(1, 'name', 'string') then return nil, 'invalid name' end
    if (value == nil) or type(value) == ('function' or 'userdata') then
        return nil, 'invalid value (must not be nil,function,userdata)'
    end
    permission = FindInTable(self.PlayerData['Permissions'], 'name', name)
    if permission then
        permission.value = value
    else
        InsertIntoTable(self.PlayerData['Permissions'], {name = name, value = value})
    end
    self:saveData()
    return true, 'permission set'
end

---* Fetch a Permission for this Player
---@param name string `required: name of permission to get`
---@return table|nil,string `returns the found permission or nil,message`
function URBA_PLAYER:getPermission(name)
    local permission = FindInTable(self.PlayerData['Permissions'], 'name', name)
    if permission then return permission, 'found permission' end
    return nil, 'Unknown permission'
end

RegisterModule('URBA_Player', URBA_PLAYER)
return URBA_PLAYER

