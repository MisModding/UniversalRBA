if not MisDB then require('MisDB') end
local Database = MisDB:Create('UniversalRBA/', 'UniversalRBA')

local RolesCollection = Database:Collection('URBA_Roles')

math.randomseed(os.time())
math.random();
math.random();
math.random()
rba_seed = math.random(88888)

local roleDescriptions = {'some awesome %s', '%s player', '%s'}

--- helper for creating new Roles
local rba = {
    Role = function(rba, obj)

        ---@class role
        ---@field Permissions table Stores this roles permissions
        local role = Class(obj)
        role.__type = 'UniversalRBA Role'

        ---* Create a new Permission for this Role
        ---| name must be a string, optional default value can be `string`,`number`,`boolean`
        ---@param name string `required: permission name`
        ---@param value string|number|boolean `required: permissions default value`
        function role:createPermission(name, value)
            if assert_arg(1, 'name', 'string') then return nil, 'invalid name' end
            if not FindInTable(self.Permissions, 'name', name) then
                InsertIntoTable(self.Permissions, {name = name, value = value or 'false'})
                rba:saveData()
                return true, 'Permission Created'
            end
            return false, 'permission exists'
        end
        ---* Set a Permissions value for this Role
        ---| name must be a string, values can be `string`,`number`,`boolean`
        ---@param name string `required: permission name`
        ---@param value string|number|boolean `required: permission value`
        function role:setPermission(name, value)
            if assert_arg(1, 'name', 'string') then return nil, 'invalid name' end
            if (value == nil) or type(value) == ('function' or 'userdata') then
                return nil, 'invalid value (not be nil,function,userdata)'
            end
            permission = FindInTable(self.Permissions, 'name', name)
            if permission then permission.value = value end
            rba:saveData()
            return true, 'permission set'
        end
        ---* Fetch a Permission for this Role
        ---@param name string `required: name of permission to get`
        ---@return table|nil,string `returns the found role or nil,message`
        function role:getPermission(name)
            local permission = FindInTable(self.Permissions, 'name', name)
            if permission then return permission, 'found permission' end
            return nil, 'invalid permission'
        end
        return role()
    end,
}

---@class URBA
---@field new fun(self:URBA,options:table<string,boolean|number|string>):URBA
---@field Options table<string,boolean|number|string>
---@field Roles table<table>
---* UniversalRBA Main Class
local RBA = Class {
    __type = 'UniversalRBA Main Class',
    __collection = RolesCollection,
    ---@type table<table> URBA Roles
    Roles = {},
    Options = {
        ---@type table<string> URBA ServerOwners
        owners = {'0'},
    },
}

---* Create a New UniversalRBA Instance
---@param options table<string,boolean|string|number> `optional: table key=value URBA Config options`
---@return URBA `new URBA instance`
function RBA:new(options)
    if type(options) == 'table' then for name, value in pairs(options) do self.Options[name] = value end end
    self.Roles = self.__collection:GetPage('Roles') or {}
    return self
end

---* Saves all URBA Data to PersistantStorage
function RBA:saveData() self.__collection:SetPage('Roles', self.Roles) end

---* Creates a New Role
---@param name string `required: role name`
---@param description string `optional: role description`
function RBA:createRole(name, description)
    if not name then return false, 'Invalid or Missing name' end
    if (not FindInTable(self.Roles, 'Name', name)) then
        local role_id = (#self.Roles or 0) + 1
        local randDesc = math.random(1, #roleDescriptions)
        local new_role = {
            id = role_id,
            Name = name,
            Description = description or string.format(roleDescriptions[randDesc], name),
            Permissions = {},
        }
        InsertIntoTable(self.Roles, new_role)
        self:saveData()
        return rba.Role(self, new_role), 'Role Created'
    end
    return false, 'role exists'
end

---* Fetches a Role by Name
---| returns the role if found or false plus message if not
---@param name string `required: name of role to find`
---@return role|boolean,string
function RBA:getRoleByName(name)
    local role = FindInTable(self.Roles, 'Name', name)
    if (role) then return rba.Role(self, role), 'found role' end
    return false, 'invalid role'
end

---* Fetches a Role by roleId
---| returns the role if found or false plus message if not
---@param id number `required: roleId to find`
---@return role|boolean,string
function RBA:getRoleById(id)
    local role = FindInTable(self.Roles, 'id', id)
    if (role) then return rba.Role(self, role), 'found role' end
    return false, 'invalid role'
end

RegisterModule('URBA', RBA)
return RBA
