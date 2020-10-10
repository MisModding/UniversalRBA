--
-- ─── COMMON ─────────────────────────────────────────────────────────────────────
--
---@class vector
---@field x number x-axis
---@field y number y-axis
---@field z number z-axis



--- Vector { x-axis, y-axis, z-axis }
local vector = {x = 0, y = 0, z = 0}
--
-- ─── CRYACTION ──────────────────────────────────────────────────────────────────
--

---* Are we Running onClient
---@return boolean
function CryAction.IsClient() end

---* Are we Running onServer
---@return boolean
function CryAction.IsDedicatedServer() end

--
-- ─── SYSTEM ─────────────────────────────────────────────────────────────────────
--

---* Fetch an Entity using its entityId
---@param entityId entityId
---@return entity
function System.GetEntity(entityId) end

---* Fetch an Entity using its Name
---@param name string
---@return entity
function System.GetEntityByName(name) end

---* Returns the Class of an Entity by its entityId
---@param entityId entityId
---@return string
function System.GetEntityClass(entityId) end

---* Fetch All Entities
---@return table
function System.GetEntities() end

---* Fetch All Entities of a Specified Class
---@param class string
---@return table
function System.GetEntitiesByClass(class) end
