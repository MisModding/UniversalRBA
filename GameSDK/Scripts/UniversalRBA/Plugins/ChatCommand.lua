--
-- ────────────────────────────────────────────────────────────────────────────────────────────────── I ──────────
--      :::::: m Framwork   C H A T C O M M A N D   H A N D L E R : :  :   :    :     :        :          :
-- ────────────────────────────────────────────────────────────────────────────────────────────────────────────
local function cmdSplit(pString, pPattern)
    local Table = {}
    local fpat = '(.-)' .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= '' then table.insert(Table, cap) end
        last_end = e + 1
        s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
        cap = pString:sub(last_end)
        table.insert(Table, cap)
    end
    return Table
end

local mChatCommand = {
    Name = '',
    Usage = '',
    command = nil,
    AuthorisedRanks = nil,
    Properties = {
        RespondPlayer = true,
        LogAuthFail = true,
        AuthFailMsg = {
            Server = 'Authorisation Success for $playername[$steamId] Command:$command',
            Player = ' > $playername - You are Not Authorised to use command: $command',
        },
        LogAuthSucces = false,
        AuthSuccessMsg = {
            Server = 'Authorisation Success for $playername[$steamId] Command:$command',
            Player = ' > $playername - You Are Authorised to use command: $command',
        },
    },
    AuthFail = function(self, player, action)
        --[[Debug]]
        if (not Log) then
            print('AuthFail')
            return
        end
        if (self.Properties.LogAuthFail) then
            local LogLine = tostring(self.Properties.AuthFailMsg.Server):gsub('$playername', player:GetName())
            local LogMsg = tostring(LogLine):gsub('$steamId', player.player:GetSteam64Id()):gsub('$command', self.Name)
            Log(LogMsg)
        end
        if (self.Properties.RespondPlayer) then
            local mResponse = tostring(self.Properties.AuthFailMsg.Player):gsub('$playername', player:GetName())
            local msg = tostring(mResponse):gsub('$steamId', player.player:GetSteam64Id()):gsub('$command', self.Name)
            g_gameRules.game:SendTextMessage(4, player.id, msg)
        end
    end,
    AuthSuccess = function(self, player, action)
        --[[Debug]]
        if (not Log) then
            print('AuthSuccess')
            return
        end
        if (self.Properties.LogAuthSuccess) then
            local LogLine = tostring(self.Properties.AuthSuccessMsg.Server):gsub('$playername', player:GetName())
            local LogMsg = tostring(LogLine):gsub('$steamId', player.player:GetSteam64Id()):gsub('$command', self.Name)
            Log(LogMsg)
        end
        if (self.Properties.RespondPlayer) then
            local mResponse = tostring(self.Properties.AuthSuccessMsg.Player):gsub('$playername', player:GetName())
            local msg = tostring(mResponse):gsub('$steamId', player.player:GetSteam64Id()):gsub('$command', self.Name)
            g_gameRules.game:SendTextMessage(4, player.id, msg)
        end
    end,
}
function mChatCommand.getActionParams(command)
    if (command) then
        local args = cmdSplit(command, ' ')
        local action = tostring(args[1])
        local cleancommand = tostring(command):gsub(action, '')
        local cleanparams = cmdSplit(cleancommand, ' ')
        cleanparams[0] = command -- add the full command back to index [0] for actions to fetch the original message
        return action, cleanparams
    end
    return nil
end

function mChatCommand:AllowCommand(player)
    local isAuthorised = function(AllowedRanks)
        if (not player) or (not player.player) then
            if self.Properties.LogAuthFail then self:AuthFail() end
            return nil
        end
        local steamId = player.player:GetSteam64Id()
        local URBA_Player = URBA:Player(player)
        --->[[ We match for both RankID and RankName as some might use both]]
        local authorised = false
        for i, rank in pairs(self.AuthorisedRanks) do
            if URBA_Player:Role(rank) then
                authorised = true
                break
            end
        end

        if authorised then
            if self.Properties.LogAuthSuccess then self:AuthSuccess() end
            return true
        else
            if self.Properties.LogAuthFail then self:AuthFail() end
            return nil
        end
    end
    return isAuthorised(self.AuthorisedRanks)
end

function mChatCommand:ShowUsage(player)
    if (self.Usage) then
        if (g_gameRules) then
            g_gameRules.game:SendTextMessage(4, player.id, 'Usage for Command: ' .. self.Name .. ' \n ' .. self.Usage)
        else
            -- DEBUG
            print('  - Showing Command Usage >')
            print('  - ' .. self.Usage)
        end
    end
end

function mChatCommand:Continue(player, action, params)
    --[[ passing an action is optional as we can just assign self.command as a function for command without params]]
    if (type(self.command) == 'table') then
        if action then
            -- > if a table then we have a command with params
            if (type(self.command[action]) == 'function') then
                -- > Call this Action if it exists
                return self.command[action](self, player, params)
            else
                --[[
                > allow for fallback to a "default" action to be when no params are provided
                ! if no "fallback" exists then we show usage or do nothing
            ]]
                if (type(self.command['default']) == 'function') then
                    return self.command['default'](self, player, params)
                else
                    return self:ShowUsage(player)
                end
            end
        end
    elseif (type(self.command) == 'function') then
        -- >its a function so we probably have a command without params
        -- > Call it
        return self.command(self, player, action)
    end
    return nil, 'self.command is invalid or conatins invalid actions'
end
--
-- ─── CONSTRUCTOR ────────────────────────────────────────────────────────────────
--
local function CreateChatCommand()
    local self = {}
    for k, v in pairs(mChatCommand) do self[k] = v end
    return self
end

--
-- ───────────────────────────────────────────────────────────── EXPORT CLASS ─────
--
URBA_ChatCommand = CreateChatCommand

if (not CC) then CC = function(name, command) return ChatCommands['!' .. name](g_localActorId, (command or '')) end end
