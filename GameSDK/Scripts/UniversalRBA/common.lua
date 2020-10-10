--- @script Common
--- @author Theros   ~ Discord: Theros#7648, Site: https://svaltek.xyz.
-- Various Common Methods used throughout SvalTek Mods.
DIR_SEPERATOR = _G['package'].config:sub(1, 1)

--- Function Wrapper Explicitly ensures the Provided Function Only Runs on Server.
---@param f function    function to run
--- all Further parameters are passed to the Provided Function call.
function ServerOnly(f, ...) if System.IsEditor() or CryAction.IsDedicatedServer() then return f(...) end end

function ScriptDir() return debug.getinfo(2).source:match('@?(.*/)') end

function assert_arg(idx, val, tp)
    if type(val) ~= tp then
        local fn = debug.getinfo(2, 'n')
        local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
                        string.format('Argument:%s Type: %q Expected: %q', tostring(idx), type(val), tp)
        local test = function() error(msg, 4) end
        local rStat, cResult = pcall(test)
        if rStat then
            return false
        else
            LogError(cResult)
            return true, cResult
        end
    end
end

-- @function compose
---* Create a function composition from given functions.
-- any further functions as arguments get added to composition in order
--- @param f1 function
-- the outermost function of the composition
--- @param f2 function
-- second outermost function of the composition
--- @return function the composite function
function compose(f1, f2, ...)
    if select('#', ...) > 0 then
        local part = compose(f2, ...)
        return compose(f1, part)
    else
        return function(...) return f1(f2(...)) end
    end
end

-- @function bind
---* Create a function with bound arguments ,
-- The bound function returned will call func() ,
-- with the arguments passed on to its creation .
-- If more arguments are given during its call, they are ,
-- appended to the original ones .
-- `...` the arguments to bind to the function.
--- @param func function
-- the function to create a binding of
--- @return function
-- the bound function
function bind(func, ...)
    local saved_args = {...}
    return function(...)
        local args = {table.unpack(saved_args)}
        for _, arg in ipairs({...}) do table.insert(args, arg) end
        return func(table.unpack(args))
    end
end

-- @function bind_self
---* Create f bound function whose first argument is t ,
--  Particularly useful to pass a method as a function ,
-- Equivalent to bind(t[k], t, ...) ,
-- `...` further arguments to bind to the function.
--- @param t table Binding
-- The table to be accessed
--- @param k any Key
-- The key to be accessed
--- @return function BoundFunc
-- The binding for t[k]
function bind_self(t, k, ...) return bind(t[k], t, ...) end

--- @section Getters and Setters

---* Create a function that returns the value of t[k] ,
-- The returned function is Bound to the Provided Table,Key.
--- @param t table
-- table to access
--- @param k any
-- key to return
--- @return function
-- returned getter function
function bind_getter(t, k)
    return function()
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            return t[k], 'Fetched Bound Key'
        end
    end
end

---* Create a function that sets the value of t[k] ,
--- The returned function is Bound to the Provided Table,Key ,
--- The argument passed to the returned function is used as the value to set.
--- @param t table       table to access
--- @param k table       key to set
--- @return function     returned setter function
function bind_setter(t, k)
    return function(v)
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            t[k] = v
            return true, 'Set Bound Key'
        end
    end
end

---* Create a function that returns the value of t[k] ,
--- The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned getter function
function getter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k) return t[k] end
    end
end

---* Create a function that sets the value of t[k] ,
--- The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned setter function
function setter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k, v)
            t[k] = v
            return true
        end
    end
end
--- @section ChatCommand Utils

---* Cleans Eccess quotes from input string
function clean_quotes(inputString)
    local result = ''
    result = inputString:gsub('^"', ''):gsub('"$', '')
    result = result:gsub('^\'', ''):gsub('\'$', '')
    return result
end

function cmdSplit(pString, pPattern)
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

function parseArgs(command)
    local cmdLine = cmdSplit(command, ' ')
    local cmdChunks = {}
    local ix = 0
    for iChunk, cmdChunk in pairs(cmdLine) do
        if ix ~= 1 then
            cmdChunks['0'] = cmdChunk
            ix = 1
        else
            local aKey, aValue = cmdChunk:match('([^,]+)=([^,]+)')
            if aValue ~= nil then cmdChunks[aKey] = aValue end
        end
    end
    return cmdChunks
end

-- @section Table Functions

---* Pretty Print (Dumps) Tables/Objects/Strings with formatting
--- @param value any
-- value to Pretty Print
function pretty(value, level)
    local level = level or 0
    local output = {}
    local insert, concat, format = table.insert, table.concat, string.format

    local function add(line, indent) insert(output, format('%s%s', string.rep('  ', indent or 0), line)) end
    local function isarray(t)
        if type(t) ~= 'table' then return false end
        for k, _ in pairs(t) do if type(k) ~= 'number' then return false end end
        return true
    end
    local function pretty_array(t)
        local strings = {}
        for _, v in ipairs(t) do insert(strings, pretty(v, level + 1)) end
        return concat(strings, ', ')
    end

    if type(value) == 'table' then
        if isarray(value) then
            return format('[ %s ]', pretty_array(value))
        else
            local keys = {}
            for k, _ in pairs(value) do if type(k) ~= 'number' then insert(keys, k) end end
            table.sort(keys)
            add('{')
            for _, k in ipairs(keys) do add(format('%s = %s', k, pretty(value[k], level + 1)), level + 1) end
            for _, v in ipairs(value) do add(pretty(v, level + 1), level + 1) end
            add('}', level)
        end
    elseif type(value) == 'string' then
        add(format('\'%s\'', value))
    else
        add(format('%s', tostring(value)))
    end
    return concat(output, '\n')
end

---* Return the Size of a Table.
-- Works with non Indexed Tables
--- @param table table  any table to get the size of
--- @return number      size of the table
function table_size(table)
    local n = 0
    for k, v in pairs(table) do n = n + 1 end
    return n
end

---* Copies all the fields from the source into t and return .
-- If a key exists in multiple tables the right-most table value is used.
--- @param t table      table to update
function table_update(t, ...)
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if x then for k, v in pairs(x) do t[k] = v end end
    end
    return t
end

function mRequireFile(filename)
    local oldPackagePath = package.path
    package.path = './' .. filename .. ';' .. package.path
    local obj = require(filename)
    package.path = oldPackagePath
    if obj then
        return obj, 'success loading file from ' .. filename
    else
        return nil, 'Failed to Require file from path ' .. filename
    end
end

---* Evaluate a Lua String
-- evaluates in Protected mode, Does nothing if the provided string ,
-- contains errors or is not a valid lua chunk
--- @param eval_string string
-- Lua Code to Evaluate
--- @return any
-- Result of lua evaluation
function mF_eval(eval_string)
    if not type(eval_string) == 'string' then
        return
    else
        local eString = eval_string:gsub('%^%*', ','):gsub('%*%^', ',')
        local eval_func = function(s) return loadstring(s)() end
        return pcall(eval_func, eString)
    end
end

local WaitTimer = 5
_WaitFor_Timer = WaitTimer * 1000
_SvWaitFor_Timer = function(...) _WaitFor(...) end

---* Wait for something to return true
-- Provided a valid `conf` definition will wait for the provided function or lua chunck to return true
--- @param conf table
-- WaitFor Definition
--- @usage
-- the provided table `conf` should contain:
-- {
--     tag = "Give your _waitFor a name/description",
--     check = function()
--         --[[ valid lua code or function call that must return true or nil ]]
--     end,
--     func = function()
--         --[[ a function to run when compleated and true ]]
--     end
-- }

function _WaitFor(conf)
    local thisClass, _eMsg = loadstring('if (not ' .. tostring(conf.check) .. ') then return nil else return true end')
    if (not thisClass) or (not thisClass()) then
        Log(
            tostring(conf.tag) .. ' > Waiting for: ' .. tostring(conf.check) .. ' timer: ' ..
                tostring(_WaitFor_Timer / 1000) .. 's'
        )
        Log(tostring(conf.check) .. ' = ' .. tostring(thisClass() or 'Not Loaded'))
        Log(tostring(_eMsg or 'No Error'))
        return Script.SetTimerForFunction(_WaitFor_Timer, '_SvWaitFor_Timer', conf)
    else
        Log(' - ' .. tostring(conf.tag) .. ' >  No longer waiting for: ' .. tostring(conf.check))
        local _status, _return = pcall(conf.func)
        if (not _status) then
            Log(' - ' .. tostring(conf.tag) .. ' > Call Failed result: ' .. tostring(_return or 'No Return'))
        else
            Log(' - ' .. tostring(conf.tag) .. ' > Call Success result: ' .. tostring(_return or 'No Return'))
            return _return
        end
    end
end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do table.insert(charset, string.char(c)) end
    for c = 65, 90 do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function strRandom(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock() ^ 5)
    return strRandom(length - 1) .. charset[math.random(1, #charset)]
end

local function Invoker(links, index)
    return function(...)
        local link = links[index]
        if not link then return end
        local continue = Invoker(links, index + 1)
        local returned = link(continue, ...)
        if returned then returned(function(_, ...) continue(...) end) end
    end
end

---* Chain()
-- used to chain multiple functions/callbacks
--- @usage Example
-- local function TimedText (seconds, text)
--     return function (go)
--         print(text)
--         millseconds = (seconds or 1) * 1000
--         Script.SetTimerForFunction(millseconds, go)
--     end
-- end
--
-- Chain(
--     TimedText(1, 'fading in'),
--     TimedText(1, 'showing splash screen'),
--     TimedText(1, 'showing title screen'),
--     TimedText(1, 'showing demo')
-- )()
--- @return function chain
-- the cretedfunction chain
function Chain(...)
    local links = {...}

    local function chain(...)
        if not (...) then return Invoker(links, 1)(select(2, ...)) end
        local offset = #links
        for index = 1, select('#', ...) do links[offset + index] = select(index, ...) end
        return chain
    end

    return chain
end

--[[
    Creates a uuid using an improved randomseed function accouning for lua 5.1 vm limitations
        >> Lua 5.1 has a limitation on the bitsize meaning that when using randomseed
        >> nubers over the limit get truncated or set to 1 , destroying all randomness for the run
]] -- Assumed Lua 5.1 maximim bitsize of 32
local bitsize = 32
local initTime = os.time()
local function better_randomseed(seed)
    seed = math.floor(math.abs(seed))
    if seed >= (2 ^ bitsize) then
        -- integer overflow, reduce  it to prevent a bad seed.
        seed = seed - math.floor(seed / 2 ^ bitsize) * (2 ^ bitsize)
    end
    math.randomseed(seed - 2 ^ (bitsize - 1))
    return seed
end

uuidSeed = better_randomseed(initTime)

function new_uuid()
    local template = 'xyxxxxxx-xxyx-xxxy-yxxx-xyxxxxxxxxxx'
    return string.gsub(
               template, '[xy]', function(c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end
           )
end

function Dec2Hex(nValue)
    if type(nValue) == 'string' then nValue = tonumber(nValue) end
    local nHexVal = string.format('%X', nValue) -- %X returns uppercase hex, %x gives lowercase letters
    local sHexVal = nHexVal .. ''
    return sHexVal
end

function Hex2Dec(someHexString) return tonumber(someHexString, 16) end

--- pack an argument list into a table.
-- @param ... any arguments
-- @return a table with field n set to the length
-- @return the length
-- @function table.pack
if not table.pack then function table.pack(...) return {n = select('#', ...), ...} end end

------
-- return the full path where a Lua module name would be matched.
-- @param mod module name, possibly dotted
-- @param path a path in the same form as package.path or package.cpath
-- @see path.package_path
-- @function package.searchpath
if not package.searchpath then
    local sep = package.config:sub(1, 1)
    function package.searchpath(mod, path)
        mod = mod:gsub('%.', sep)
        for m in path:gmatch('[^;]+') do
            local nm = m:gsub('?', mod)
            local f = io.open(nm, 'r')
            if f then
                f:close();
                return nm
            end
        end
    end
end

function __FILE__(offset) return debug.getinfo(1 + (offset or 1), 'S').source end
function __LINE__(offset) return debug.getinfo(1 + (offset or 1), 'l').currentline end
function __FUNC__(offset) return debug.getinfo(1 + (offset or 1), 'n').name end

function try(t)
    local ok, value = pcall(t['try'])
    local final_value
    if ok then
        if t.finally then final_value = t.finally(value) end
        return (final_value or value)
    else
        local handled, backup_value = pcall(function() return t.catch(value) end)
        if t.finally then final_value = t.finally(backup_value) end
        if handled then
            return (final_value or backup_value)
        else
            return error(backup_value, 2)
        end
    end
end

--- * Class Builder used in all my Scripts.
function Class(base, new)
    local class = {__type = 'Class', __tostring = function(self) return tostring(self.__type) end} -- a new class instance
    if not new and type(base) == 'function' then
        new = base
        base = nil
    elseif type(base) == 'table' then
        -- our new class is a shallow copy of the base class!
        for i, v in pairs(base) do class[i] = v end
        class._base = base
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    class.__index = class

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, class_tbl)
        if class_tbl.new then
            class_tbl.new(obj, ...)
        else
            -- make sure that any stuff from the base class is initialized!
            if base and base.new then base.new(obj, ...) end
        end
        return obj
    end
    class.new = new
    class.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    class.implement = function(self, ...)
        for _, cls in pairs({...}) do
            for k, v in pairs(cls) do if self[k] == nil and type(v) == 'function' then self[k] = v end end
        end
    end
    class.extend = function(self, name)
        local obj = {}
        for k, v in pairs(self) do if k:find('__') == 1 then obj[k] = v end end
        obj.__index = obj
        obj.super = self
        setmetatable(obj, self)
        return obj
    end
    setmetatable(class, mt)
    return class
end
