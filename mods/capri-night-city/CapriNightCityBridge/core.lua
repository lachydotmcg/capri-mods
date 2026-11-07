-- Engine-independent protocol, replay and cooldown policy. No game objects retained here.
local Core = {}
Core.__index = Core
function Core.parse(text)
    if type(text) ~= "string" or #text > 32768 then return nil end
    local fields = {}
    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key then fields[key] = value end
    end
    if fields.protocol ~= "1" or not fields.commit or fields.commit ~= fields.id then return nil end
    return fields
end
function Core.pack(fields, order)
    local lines = {}
    for _, key in ipairs(order) do
        lines[#lines + 1] = key .. "=" .. tostring(fields[key] or ""):gsub("[\r\n]", " ")
    end
    return table.concat(lines, "\n") .. "\ncommit=" .. fields.id .. "\n"
end
function Core.new(session)
    return setmetatable({session = session, seen = {}, seenOrder = {}, normalAt = -1000,
        blackwallAt = -1000, defenseAt = -1000, protectInterval = 1.5, scan = false,
        autoAt = 0, events = {}, sequence = 0, assist = true, chaos = false, protect = false}, Core)
end
function Core:event(kind, message)
    self.sequence = self.sequence + 1
    self.events[#self.events + 1] = {seq = self.sequence, kind = kind, message = message}
    if #self.events > 24 then table.remove(self.events, 1) end
end
function Core:validate(command, now)
    if not command then return false, "Incomplete command." end
    if self.seen[command.id] then return false, "duplicate" end
    -- Remember even rejected commands, preventing delayed execution after a condition changes.
    self.seen[command.id] = true
    self.seenOrder[#self.seenOrder + 1] = command.id
    if #self.seenOrder > 256 then self.seen[table.remove(self.seenOrder, 1)] = nil end
    local issued = tonumber(command.issued)
    if not issued or issued ~= issued or now - issued > 6 or issued > now + 2 then return false, "Command expired. Try again." end
    if command.session ~= self.session then return false, "Game session changed. Try again." end
    local allowed = {spike=true, burn=true, lock=true, blind=true, jam=true, collapse=true,
        erase=true, thermal_erase=true, neural_erase=true, blackwall=true,
        kill=true, smart=true, control=true, assist_on=true, assist_off=true, chaos_on=true, chaos_off=true,
        brake=true, accelerate=true, explode=true, breach=true, device_off=true, device_distract=true, open=true,
        scan=true, scan_off=true,protect_on=true,protect_off=true,stealth_on=true,stealth_off=true,emergency_on=true,emergency_off=true,wipe=true,counter_on=true,counter_off=true,
        ghost_veil=true,marionette=true,dead_channel=true,siphon=true,furnace=true,circuit_breaker=true,crash_loop=true,reaper_thread=true}
    if not allowed[command.action] then return false, "Unknown hack keyword." end
    return true
end
function Core:ready(action, now, channel)
    if action == "blackwall" then
        if now - self.blackwallAt < 180 then return false, "Blackwall is cooling down: " .. math.ceil(180 - (now-self.blackwallAt)) .. " seconds." end
    elseif channel == "protect" then
        if now - self.defenseAt < self.protectInterval then return false, "Defensive link cooling down." end
    elseif now - self.normalAt < 8 then return false, "Hack link cooling down." end
    return true
end
function Core:used(action, now, channel)
    if channel == "protect" then self.defenseAt = now else self.normalAt = now end
    self.lastChoice = action
    if action == "blackwall" then self.blackwallAt = now end
end
-- Intent selection stays in the game process, using current target/health/effect availability.
-- A blind request always selects blindness; only open-ended intents choose from a pool.
function Core:choose(intent, context, available, random)
    local roll = random or math.random
    local pool
    if intent == "kill" then
        if available("blackwall") and roll() < context.blackwallChance then return "blackwall" end
        -- Generic kill stays immediate. Reaper's delayed execution is explicitly named or chosen in chaos.
        pool = context.machine and {"erase","neural_erase"} or {"erase","thermal_erase","neural_erase"}
    elseif intent == "chaos" then
        if available("blackwall") and roll() < context.blackwallChance then return "blackwall" end
        pool = context.machine and {"spike","jam","lock","collapse","erase","neural_erase","circuit_breaker","crash_loop","marionette"}
            or {"spike","burn","blind","jam","lock","collapse","erase","thermal_erase","neural_erase","furnace","siphon","crash_loop","reaper_thread"}
    elseif intent == "smart" or intent == "control" or intent == "assist" then
        if intent == "assist" and available("blackwall") and roll() < context.blackwallChance then return "blackwall" end
        if context.machine then
            pool = (context.danger or intent == "control") and {"jam","lock","dead_channel","marionette"} or {"spike","jam","lock","circuit_breaker","crash_loop"}
        elseif context.danger or intent == "control" then
            pool = {"blind","jam","lock","ghost_veil","dead_channel","marionette"}
        else
            pool = {"spike","burn","blind","jam","lock","siphon","furnace","circuit_breaker","crash_loop","ghost_veil","dead_channel","marionette"}
        end
    else
        return available(intent) and intent or nil
    end
    local options = {}
    for _,action in ipairs(pool) do if available(action) then options[#options+1] = action end end
    if #options > 1 then
        for i = #options,1,-1 do if options[i] == self.lastChoice then table.remove(options,i) end end
    end
    if #options == 0 then return nil end
    return options[math.min(#options,math.floor(roll() * #options)+1)]
end
return Core
