-- Capri Night City 1.9.3. CET integration; scoped, chained hooks for counterhacks and scan tagging.
local Core = require("core")
local Targets = require("targets")
local Counter = require("counter")
local Programs = require("programs")
local mod = {}
local runtime, playerKey, attached = nil, nil, false
local elapsed, poll, autoClock, serial, generation = 0, 0, 0, 0, 0
local overlay = false
local lastHealth, lastCombat, lastWanted, lastVehicle, lastQuest = nil, nil, nil, nil, nil
local seenKills, trackedEffects = {}, {}
local seenKillOrder={}
local seenKillSlot=1
local revealed,lastScan,scanReported={},-100,false
local lastProtectHealth,protectAt=nil,-100
local protectedTargets={}
local scanReportAt=0
local emergencyAt=-1000
local counter
local cleanup
local leaseReadAt,leaseFields=-1,nil
local function clearScan()
    for _,entry in pairs(revealed) do
        local npc=Game.FindEntityByID(entry.id)
        if npc then pcall(Targets.clearHighlight,npc,entry.highlight) end
    end
    revealed={}; Targets.resetScanPermissions()
end
local status = "Waiting for a save."
local config = {autoAssist=true, blackwallChance=0.03, autoInterval=18, range=35}
config.emergencyEnabled=true
config.chaosInterval=10
config.protectInterval=1.5
config.counterNetrunners=true
local function startScan(player)
    clearScan(); lastScan=-100; scanReported=false; scanReportAt=elapsed+1.5
    -- A scanner pulse is optional; native tagging is the same authoritative path in both modes.
    if player then
        local ok,err=pcall(Targets.scanPulse,player,config.range)
        if not ok then print("[Capri Night City] Optional scanner pulse unavailable; native tagging continues: "..tostring(err)) end
    end
end
local function clean(value) return tostring(value or ""):gsub("[\r\n|]", " ") end
local function read(path)
    local f = io.open(path, "r"); if not f then return nil end
    local text = f:read(32769); f:close(); return text
end
local function write(path, text)
    local f = io.open(path .. ".tmp", "w"); if not f then error("Cannot write " .. path) end
    f:write(text); f:close()
    os.remove(path)
    local ok, err = os.rename(path .. ".tmp", path)
    if not ok then error("Bridge publish failed: " .. tostring(err)) end
end
local function log(message)
    status = clean(message); print("[Capri Night City] " .. status)
end
local function event(kind, message)
    if runtime then runtime:event(kind, clean(message)) end
end
local function key(object) return tostring(object:GetEntityID().hash) end
local function newSession(player)
    if cleanup then cleanup(nil,true) end
    clearScan()
    if counter then counter:reset() end
    generation = generation + 1
    runtime = Core.new(tostring(os.time()) .. "-" .. generation .. "-" .. math.random(100000,999999))
    runtime.assist = config.autoAssist
    runtime.emergency=config.emergencyEnabled
    runtime.protectInterval=config.protectInterval
    runtime.counter=config.counterNetrunners
    playerKey = player and key(player) or nil
    lastHealth, lastCombat, lastWanted, lastVehicle, lastQuest = nil,nil,nil,nil,nil
    seenKills, trackedEffects, seenKillOrder = {}, {}, {}
    seenKillSlot=1
    leaseReadAt=-1; leaseFields=nil
    lastProtectHealth=nil; protectAt=-100; protectedTargets={}
end
local function playerContext()
    local p = Game.GetPlayer()
    if not p or not p:IsAttached() or GetSingleton("inkMenuScenario"):GetSystemRequestsHandler():IsPreGame() then return nil, true end
    local defs = GetAllBlackboardDefs()
    local ui = Game.GetBlackboardSystem():Get(defs.UI_System)
    return p, ui:GetBool(defs.UI_System.IsInMenu)
end
local function clientAlive()
    if leaseReadAt~=elapsed then leaseFields=Core.parse(read("client.txt")); leaseReadAt=elapsed end
    local fields = leaseFields
    local time = fields and tonumber(fields.issued)
    return time and time == time and os.time() - time <= 3 and time <= os.time() + 2 and fields.session == runtime.session
end
local function eligible(target, player)
    return Targets.check(target,player,config.range,false)
end
local function targetAtCrosshair(player)
    return Game.GetTargetingSystem():GetLookAtObject(player,false,false)
end
local effects = {
    spike = {record="BaseStatusEffect.Electrocuted", damage=40, seconds=3, name="Ghost Spike"},
    burn = {record="BaseStatusEffect.OverheatLevel4", damage=25, seconds=6, name="Neural Burn"},
    lock = {record="BaseStatusEffect.Stun", damage=0, seconds=4, name="Puppet Lock"},
    blind = {record="BaseStatusEffect.Blind", seconds=6, name="Optics Blackout"},
    jam = {record="BaseStatusEffect.WeaponMalfunctionSmartLock", seconds=6, name="Weapon Jam"},
    collapse = {record="BaseStatusEffect.SystemCollapse", seconds=8, name="System Collapse"},
    wipe = {record="BaseStatusEffect.MemoryWipeLevel2", seconds=8, name="Memory Wipe"},
    erase = {record="BaseStatusEffect.Electrocuted", lethal=true, seconds=2, name="Signal Erase"},
    thermal_erase = {record="BaseStatusEffect.OverheatLevel4", lethal=true, seconds=2, name="Thermal Shutdown"},
    neural_erase = {record="BaseStatusEffect.Overload", lethal=true, seconds=2, name="Neural Execution"},
    blackwall = {record="BaseStatusEffect.SoMi_Q306_BlackwallHackUpload", seconds=5, name="Blackwall Breach"}
}
for action,definition in pairs(Programs.definitions) do effects[action]=definition end
local function cast(intent, target, player, hostileOnly,batchPermit,channel)
    local allowed, why, kind = Targets.check(target,player,config.range,hostileOnly); if not allowed then return false,why end
    if runtime.stealth then
        if intent=="smart" or intent=="control" or intent=="assist" then intent=kind=="npc" and "wipe" or "device_distract" end
        local quiet={wipe=true,blind=true,jam=true,lock=true,brake=true,device_off=true,device_distract=true,open=true,breach=true}
        if Programs.definitions[intent] and Programs.definitions[intent].quiet then quiet[intent]=true end
        if not quiet[intent] then return false,"Stealth mode blocks damaging/lethal hacks. Turn stealth off first." end
    end
    local ready, reason = runtime:ready(intent,elapsed,channel); if not ready and not (batchPermit and intent~="blackwall") then return false,reason end
    if kind~="npc" then
        if Programs.definitions[intent] then return false,"This custom program requires an NPC. Use a vehicle or device hack for that target." end
        local ok,success,message=pcall(function()
            if kind=="vehicle" then return Targets.vehicle(intent,target,player,trackedEffects,elapsed) end
            if kind=="access_point" and (intent=="breach" or intent=="smart" or intent=="chaos") then return Targets.breach(target,player) end
            return Targets.device(intent,target,player)
        end)
        if not ok then return false,"Target API could not execute that action: " .. clean(success) end
        if success then runtime:used(intent,elapsed,channel); event("hack",message) end
        return success,message
    end
    if intent=="explode" then intent="kill" end
    local system = Game.GetStatusEffectSystem()
    local available = function(action)
        local effect = effects[action]
        return effect and (runtime:ready(action,elapsed,channel) or batchPermit and action~="blackwall")
            and Programs.available(effect,system,target)
    end
    local machine = false
    pcall(function()
        local kind = target:GetNPCType()
        machine = kind == gamedataNPCType.Android or kind == gamedataNPCType.Drone or kind == gamedataNPCType.Mech or kind == gamedataNPCType.Spiderbot
    end)
    local health = Game.GetStatPoolsSystem():GetStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,true)
    local action = runtime:choose(intent,{machine=machine,danger=health<35,blackwallChance=config.blackwallChance},available)
    if not action then return false,"No suitable hack is available for that request (effect missing, active or cooling down)." end
    local effect = effects[action]
    if not effect then return false,"Unknown hack." end
    local records,problem=Programs.apply(effect,system,target,player)
    if not records then return false,problem end
    runtime:used(action,elapsed,channel)
    -- Retain only weak game references and remove our own transient effects later.
    for _,record in ipairs(records) do
        trackedEffects[#trackedEffects+1] = {id=target:GetEntityID(),record=record,at=elapsed+effect.seconds,
            action=action,session=runtime.session,hostileOnly=hostileOnly}
    end
    if effect.damage then
        Game.GetStatPoolsSystem():RequestChangingStatPoolValue(target:GetEntityID(),gamedataStatPoolType.Health,-effect.damage,player,true,true)
    elseif effect.lethal then
        target:Kill(player,false,false)
    end
    if effect.heal then
        Game.GetStatPoolsSystem():RequestChangingStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,effect.heal,player,true,false)
    end
    if effect.pulses then for pulse=1,effect.pulses do
        trackedEffects[#trackedEffects+1]={id=target:GetEntityID(),pulseDamage=effect.damage,at=elapsed+pulse*effect.pulseInterval,
            session=runtime.session,hostileOnly=hostileOnly}
    end end
    if effect.executeAfter then
        trackedEffects[#trackedEffects+1]={id=target:GetEntityID(),execute=true,at=elapsed+effect.executeAfter,
            session=runtime.session,hostileOnly=hostileOnly}
    end
    event(action == "blackwall" and "blackwall" or "hack", effect.name .. " uploaded to " .. clean(target:GetDisplayName()) .. ".")
    return true,(intent ~= action and "I've chosen " .. effect.name .. ". " or "") .. effect.name .. " uploaded."
end
cleanup=function(player, cancel)
    for i = #trackedEffects,1,-1 do
        local work = trackedEffects[i]
        if cancel or elapsed >= work.at then
            local keep=false
            local ok,err=pcall(function()
            -- Resolve by EntityID rather than retaining strong NPC handles across frames.
            local target = Game.FindEntityByID(work.id)
            if target and IsDefined(target) then
                if work.confirmDestruction then
                    if target:IsDestroyed() then event("hack","Vehicle destruction confirmed by the game.")
                    elseif not cancel and elapsed<work.deadline then work.at=elapsed+.25; keep=true
                    elseif not cancel then event("hack","Vehicle did not confirm destruction. Check bridge diagnostics; no success assumed.") end
                elseif work.vehicleEvent then
                    local evt=NewObject(work.vehicleEvent)
                    if evt then evt.active=false
                        if work.vehicleEvent=="vehicleForceBrakesQuickhackEvent" then evt.alarmDuration=0 end
                        target:QueueEvent(evt)
                    end
                elseif not cancel and (work.pulseDamage or work.execute) and work.session==runtime.session and player then
                    if not work.actionIssued and not runtime.stealth and Targets.check(target,player,config.range,work.hostileOnly) then
                        work.actionIssued=true
                        if work.execute then target:Kill(player,false,false)
                        else Game.GetStatPoolsSystem():RequestChangingStatPoolValue(target:GetEntityID(),gamedataStatPoolType.Health,-work.pulseDamage,player,true,true) end
                    end
                elseif not cancel and work.action == "blackwall" and work.session == runtime.session and player then
                    local ok = not work.actionIssued and Targets.check(target,player,config.range,work.hostileOnly)
                    if ok then work.actionIssued=true end
                    if ok then target:Kill(player,false,false); event("blackwall_kill","Blackwall target eliminated.") end
                end
                if work.record then Game.GetStatusEffectSystem():RemoveStatusEffect(work.id,work.record) end
            end
            end)
            -- Drop failed delayed actions without retrying damage/kills. A bad game API
            -- must not pin one entry forever and prevent every subsequent cleanup.
            if not ok then
                work.failures=(work.failures or 0)+1
                keep=(work.record~=nil or work.vehicleEvent~=nil) and work.failures<3
                if keep then work.at=elapsed+.25 end
                if work.failures==1 or not keep then log((keep and "Effect cleanup retry scheduled: " or "Effect cleanup entry discarded after bounded retries: ")..clean(err)) end
            end
            if not keep then table.remove(trackedEffects,i) end
        end
    end
end
local function acknowledge(command, ok, message)
    local fields={protocol="1",id=command.id,session=runtime.session,ok=ok and "1" or "0",message=clean(message)}
    write("result.txt",Core.pack(fields,{"protocol","id","session","ok","message"}))
end
local function processCommand(player, menu)
    local command = Core.parse(read("command.txt")); if not command then return end
    local ok, reason = runtime:validate(command,os.time())
    if not ok then if reason ~= "duplicate" then acknowledge(command,false,reason) end; return end
    if not clientAlive() then acknowledge(command,false,"Capri connection is not current."); return end
    if command.action == "assist_off" then runtime.assist=false; runtime.chaos=false; runtime.protect=false; runtime.scan=false; runtime.protectScan=false; runtime.stealth=false; runtime.emergency=false; runtime.counter=false; clearScan(); cleanup(player,true); acknowledge(command,true,"All autonomous attacks standing down. All modes, counterhacks and emergency rescue are off."); return end
    if command.action=="counter_on" or command.action=="counter_off" then
        runtime.counter=command.action=="counter_on"
        acknowledge(command,true,runtime.counter and "Netrunner defense on. Actual incoming hackers and tracers receive silent lethal retaliation." or "Netrunner defense off."); return
    end
    if command.action=="emergency_on" or command.action=="emergency_off" then
        runtime.emergency=command.action=="emergency_on"
        acknowledge(command,true,runtime.emergency and "Emergency rescue armed: below 50 HP, up to five hostiles and 100 HP, cooldown 120 seconds." or "Emergency rescue off."); return
    end
    if command.action=="stealth_on" then runtime.stealth=true; runtime.chaos=false; runtime.protect=false; runtime.assist=false; cleanup(player,true); acknowledge(command,true,"Stealth mode on. Automatic lethal rescue is suspended; I'll use control and memory wipe."); return end
    if command.action=="stealth_off" then runtime.stealth=false; acknowledge(command,true,"Stealth mode off. Emergency rescue resumes if armed."); return end
    if command.action == "assist_on" then runtime.assist=true; acknowledge(command,true,"Combat assistance enabled while Capri is connected."); return end
    if command.action == "chaos_on" then runtime.protect=false; clearScan(); runtime.chaos=true; autoClock=0; acknowledge(command,true,"Chaos mode on. Nearby NPCs, vehicles and devices are fair game."); return end
    if command.action == "chaos_off" then runtime.chaos=false; cleanup(player,true); acknowledge(command,true,"Chaos mode off. Combat assistance keeps its current setting."); return end
    if command.action=="protect_on" then
        runtime.protect=true; runtime.protectScan=true; runtime.chaos=false; runtime.assist=false
        startScan(player)
        acknowledge(command,true,"Protection on. Continuous NPC tagging and defensive hacks every "..config.protectInterval.." seconds against threats, including through walls. Chaos is off."); return
    end
    if command.action=="protect_off" then runtime.protect=false; clearScan(); cleanup(player,true); acknowledge(command,true,runtime.scan and "Protection off. Your separate continuous scan remains on." or "Protection off. My scanner tags are being cleared."); return end
    if command.action=="scan_off" then runtime.scan=false; runtime.protectScan=false; clearScan(); acknowledge(command,true,"Enemy scan off."); return end
    if not player or menu or not ScriptedPuppet.IsActive(player) then acknowledge(command,false,"Load a save and close menus first."); return end
    if command.action=="scan" then
        runtime.scan=true; runtime.protectScan=true; startScan(player)
        acknowledge(command,true,"Continuous NPC scan on, including neutral NPCs and civilians through walls. Say stop scanning to clear it."); return
    end
    local count=math.max(1,math.min(5,math.floor(tonumber(command.count) or 1)))
    if count>1 then
        if runtime.stealth and (command.action=="kill" or command.action=="erase" or command.action=="explode" or command.action=="blackwall") then acknowledge(command,false,"Stealth mode blocks lethal batches. Turn stealth off first."); return end
        local ready,why=runtime:ready(command.action,elapsed); if not ready then acknowledge(command,false,why); return end
        local kind=command.expected=="vehicle" and "vehicle" or "npc"
        local candidates=Targets.group(player,config.range,kind,command.selection=="front_group")
        local sent,attempted=0,0
        for _,contact in ipairs(candidates) do
            if attempted>=count then break end; attempted=attempted+1
            local ok=cast(command.action,contact.target,player,false,true); if ok then sent=sent+1 end
        end
        acknowledge(command,sent>0,"Multi-target action accepted for "..sent.." of "..attempted.." targets. Death/destruction is confirmed separately by game events."); return
    end
    local target
    if command.selection=="nearest_enemy" then
        target=Targets.closestEnemy(player,config.range)
        if not target then acknowledge(command,false,"No eligible NPC found within hack range, including behind walls."); return end
    else
        target=targetAtCrosshair(player)
        if not target or command.target ~= key(target) then acknowledge(command,false,"Crosshair target changed. Aim and retry."); return end
        if command.expected=="npc" and Targets.kind(target)~="npc" then acknowledge(command,false,"You're aiming at a vehicle or device, not a person. No attack sent."); return end
    end
    local success,message=cast(command.action,target,player)
    acknowledge(command,success,message)
end
local function emergency(player)
    if not runtime.emergency or runtime.stealth or os.time()-emergencyAt<120 then return false end
    local pools=Game.GetStatPoolsSystem()
    if pools:GetStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,false)>=50 then return false end
    emergencyAt=os.time() -- reserve and persist before engine calls; no replay after a partial burst
    local saved,err=pcall(write,"emergency-cooldown.txt",tostring(emergencyAt))
    if not saved then log("Emergency rescue cancelled: cooldown could not be saved: "..clean(err)); return false end
    local targets=Targets.enemies(player,config.range,false,true)
    local requested=0
    for _,contact in ipairs(targets) do
        if requested>=5 then break end
        local ok=pcall(function() contact.target:Kill(player,false,false) end)
        if ok then requested=requested+1 end
    end
    local before=pools:GetStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,false)
    pools:RequestChangingStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,100,player,true,false)
    event("protect","Emergency rescue: requested "..requested.." hostile eliminations and +100 HP (capped by maximum health). Cooldown 120 seconds.")
    log("Emergency rescue fired. Health before="..tostring(before)..", requested kills="..requested)
    return true
end
local function automatic(player,menu)
    if menu or not clientAlive() or not ScriptedPuppet.IsActive(player) then return end
    if emergency(player) then return end
    if runtime.stealth then
        if autoClock<12 or not runtime:ready("lock",elapsed) then return end
        autoClock=0
        if player:IsInCombat() then
            for _,contact in ipairs(Targets.enemies(player,config.range,false,true)) do
                local ok=cast("wipe",contact.target,player,true); if ok then return end
            end
        end
        return
    end
    if runtime.protect then
        local health=Game.GetStatPoolsSystem():GetStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,true)
        local threatened=player:IsInCombat() or health<45 or lastProtectHealth and health<lastProtectHealth-1
        lastProtectHealth=health
        if threatened and elapsed-protectAt>=config.protectInterval and runtime:ready("control",elapsed,"protect") then
            protectAt=elapsed -- also throttle failed attempts when every available effect is already active
            for id,at in pairs(protectedTargets) do if elapsed-at>60 then protectedTargets[id]=nil end end
            local contacts=Targets.enemies(player,config.range,true,true)
            table.sort(contacts,function(a,b)
                local left,right=protectedTargets[key(a.target)] or -1000,protectedTargets[key(b.target)] or -1000
                if left~=right then return left<right end
                return a.distance<b.distance
            end)
            for _,contact in ipairs(contacts) do
                local success=cast("control",contact.target,player,true,false,"protect")
                if success then protectedTargets[key(contact.target)]=elapsed; event("protect","Defensive control hack applied to a nearby hostile."); break end
            end
        end
        return
    end
    if runtime.chaos then
        if autoClock<config.chaosInterval then return end
        autoClock=0
        local ok,candidates=pcall(Targets.nearby,player,config.range,64)
        if not ok then log("Chaos target scan unavailable: " .. clean(candidates)); return end
        -- Shuffle candidates so the crosshair is not always chosen before nearby entities.
        for i=#candidates,2,-1 do local j=math.random(i); candidates[i],candidates[j]=candidates[j],candidates[i] end
        for _,target in ipairs(candidates) do
            if eligible(target,player) then
                local success=cast("chaos",target,player,false)
                if success then return end
            end
        end
        return
    end
    if not runtime.assist or not player:IsInCombat() then return end
    if autoClock < config.autoInterval then return end
    autoClock=0
    local choices={}
    for _,contact in ipairs(Targets.enemies(player,config.range,false)) do choices[#choices+1]=contact.target end
    local look=targetAtCrosshair(player); if look then choices[#choices+1]=look end
    local tracker=player:GetTargetTrackerComponent()
    if tracker then for _,location in ipairs(tracker:GetHostileThreats(false)) do if location.entity then choices[#choices+1]=location.entity end end end
    for _,target in ipairs(choices) do
        if Targets.kind(target)=="npc" and Targets.check(target,player,config.range,true) then
            cast("assist",target,player,true); return
        end
    end
end
local function snapshot(player,menu)
    serial=serial+1
    local fields={protocol="1",id=tostring(serial),session=runtime.session,issued=tostring(os.time()),
        ready=player and "1" or "0",menu=menu and "1" or "0",assist=runtime.assist and "1" or "0",chaos=runtime.chaos and "1" or "0",protect=runtime.protect and "1" or "0",status=status,
        health="0",combat="0",wanted="0",vehicle="0",target="",target_name="",eligible="0",quest="",kills=tostring(runtime.kills or 0),event_seq=tostring(runtime.sequence)}
    fields.target_kind="none"
    fields.scan=(runtime.scan or runtime.protect and runtime.protectScan) and "1" or "0"
    fields.counter=runtime.counter and "1" or "0"
    fields.protect_interval=tostring(config.protectInterval)
    fields.stealth=runtime.stealth and "1" or "0"; fields.emergency=runtime.emergency and "1" or "0"
    fields.rescue_remaining=tostring(math.max(0,120-(os.time()-emergencyAt)))
    local order={"protocol","id","session","issued","ready","menu","assist","chaos","protect","status","health","combat","wanted","vehicle","target","target_name","target_kind","eligible","quest","kills","event_seq"}
    order[#order+1]="stealth"; order[#order+1]="emergency"; order[#order+1]="rescue_remaining"
    order[#order+1]="scan"; order[#order+1]="protect_interval"
    order[#order+1]="counter"
    if player then
        local health=Game.GetStatPoolsSystem():GetStatPoolValue(player:GetEntityID(),gamedataStatPoolType.Health,true)
        local combat=player:IsInCombat()
        local wanted=Game.GetScriptableSystemsContainer():Get("PreventionSystem"):GetHeatStageAsInt()
        local vehicle=player:GetPlayerStateMachineBlackboard():GetBool(GetAllBlackboardDefs().PlayerStateMachine.MountedToVehicle)
        fields.health=tostring(math.floor(health)); fields.combat=combat and "1" or "0"; fields.wanted=tostring(wanted); fields.vehicle=vehicle and "1" or "0"
        local target=targetAtCrosshair(player)
        if target then fields.target=key(target); fields.target_name=clean(Targets.label(target)); fields.target_kind=Targets.kind(target); fields.eligible=eligible(target,player) and "1" or "0" end
        local journal=Game.GetJournalManager(); local quest=journal:GetTrackedEntry()
        fields.quest=quest and tostring(journal:GetEntryHash(quest)) or ""
        if not menu then
            if lastCombat ~= nil and combat ~= lastCombat then event(combat and "combat_start" or "combat_end",combat and "Enemies engaged V." or "V is out of combat.") end
            if lastHealth and health < 30 and lastHealth >= 30 then event("low_health","V's health is critical.") end
            if lastHealth and health <= 0 and lastHealth > 0 then event("player_down","V is down.") end
            if lastWanted and wanted > lastWanted then event("wanted","Police heat increased to " .. wanted .. ".") end
            if lastVehicle ~= nil and vehicle ~= lastVehicle then event(vehicle and "vehicle_enter" or "vehicle_exit",vehicle and "V entered a vehicle." or "V left the vehicle.") end
            if lastQuest and fields.quest ~= lastQuest and fields.quest ~= "" then event("objective","Tracked objective changed.") end
            lastCombat,lastHealth,lastWanted,lastVehicle,lastQuest=combat,health,wanted,vehicle,fields.quest
        end
    end
    fields.event_seq=tostring(runtime.sequence)
    for i,e in ipairs(runtime.events) do
        local field="event_" .. i; order[#order+1]=field
        fields[field]=e.seq .. "|" .. e.kind .. "|" .. e.message
    end
    write("snapshot.txt",Core.pack(fields,order))
end
local function update(delta)
    elapsed=elapsed+math.max(0,math.min(delta,0.5)); poll=poll+delta; autoClock=autoClock+math.max(0,math.min(delta,0.5))
    if poll < .25 then return end; poll=0
    local p,menu=playerContext()
    if p and (not attached or key(p) ~= playerKey) then newSession(p); attached=true end
    if not p and attached then cleanup(nil,true); newSession(nil); attached=false end
    if not runtime then newSession(p) end
    cleanup(p,menu or not p or not clientAlive())
    if not (runtime.scan or runtime.protect and runtime.protectScan) or not p or menu or not clientAlive() or not ScriptedPuppet.IsActive(p) then if next(revealed) then clearScan() end
    elseif elapsed-lastScan>=1 then
        lastScan=elapsed
        local contacts=Targets.enemies(p,config.range,true,false)
        local active={}
        for _,contact in ipairs(contacts) do
            local npc=contact.target; local id=key(npc)
            active[id]=true
            if not revealed[id] then
                local ok,highlight=pcall(Targets.highlight,npc,p:GetEntityID())
                if ok then revealed[id]={id=npc:GetEntityID(),highlight=highlight}
                else log("Scan highlight failed: "..clean(highlight)) end
            end
        end
        for id,entry in pairs(revealed) do
            if not active[id] then
                local npc=Game.FindEntityByID(entry.id)
                if npc then pcall(Targets.clearHighlight,npc,entry.highlight) end
                Targets.releaseScanPermission(entry.id)
                revealed[id]=nil
            end
        end
        if not scanReported and elapsed>=scanReportAt then
            local count,requests=0,0
            for _,entry in pairs(revealed) do
                requests=requests+1; local npc=Game.FindEntityByID(entry.id)
                if npc and Targets.isHighlighted(npc) then count=count+1 end
            end
            event("scan","Scanner found "..#contacts.." eligible NPCs. Game confirms "..count.." tagged; "..requests.." tagging requests sent.")
            scanReported=true
        end
    end
    processCommand(p,menu)
    if p then automatic(p,menu) end
    snapshot(p,menu)
end
registerForEvent("onInit",function()
    local raw=read("settings.json")
    if raw then
        local ok,s=pcall(json.decode,raw)
        if ok and type(s)=="table" then
            if type(s.autoAssist)=="boolean" then config.autoAssist=s.autoAssist end
            if type(s.blackwallChance)=="number" then config.blackwallChance=math.max(0,math.min(.1,s.blackwallChance)) end
            if type(s.autoInterval)=="number" then config.autoInterval=math.max(10,math.min(120,s.autoInterval)) end
            if type(s.range)=="number" then config.range=math.max(5,math.min(60,s.range)) end
            if type(s.chaosInterval)=="number" then config.chaosInterval=math.max(8,math.min(120,s.chaosInterval)) end
            if type(s.emergencyEnabled)=="boolean" then config.emergencyEnabled=s.emergencyEnabled end
            if type(s.protectInterval)=="number" then config.protectInterval=math.max(.5,math.min(10,s.protectInterval)) end
            if type(s.counterNetrunners)=="boolean" then config.counterNetrunners=s.counterNetrunners end
        end
    end
    emergencyAt=tonumber(read("emergency-cooldown.txt")) or -1000
    newSession(nil)
    Targets.installScanHooks()
    counter=Counter.new({now=function() return elapsed end,player=playerContext,alive=clientAlive,
        enabled=function() return runtime and runtime.counter end,
        log=function(message) print("[Capri Night City] "..clean(message)) end})
    counter:install()
    Observe("NPCPuppet","OnDeath",function(npc,evt)
        pcall(function()
            local p=Game.GetPlayer()
            if not runtime or not p or not evt or not evt.instigator or key(evt.instigator) ~= key(p) then return end
            local id=key(npc); if seenKills[id] then return end
            local expired=seenKillOrder[seenKillSlot]; if expired then seenKills[expired]=nil end
            seenKills[id]=true; seenKillOrder[seenKillSlot]=id; seenKillSlot=seenKillSlot%1024+1
            runtime.kills=(runtime.kills or 0)+1
            event("kill","V eliminated " .. clean(npc:GetDisplayName()) .. ".")
        end)
    end)
    Observe("PlayerPuppet","OnDetach",function()
        pcall(function() cleanup(nil,true); newSession(nil); attached=false end)
    end)
    log("Bridge ready. Load a save, then enable the Capri code mod.")
end)
registerForEvent("onUpdate",function(delta)
    local ok,err=pcall(update,delta)
    if not ok then
        local message="Bridge error: " .. clean(err)
        if status ~= message then log(message) end
        -- Publish an explicit not-ready snapshot instead of leaving apparently live state.
        pcall(function() if not runtime then newSession(nil) end; snapshot(nil,true) end)
    end
end)
registerForEvent("onOverlayOpen",function() overlay=true end)
registerForEvent("onOverlayClose",function() overlay=false end)
registerForEvent("onDraw",function()
    if not overlay then return end
    ImGui.Begin("Capri Night City")
    ImGui.TextWrapped(status)
    if runtime then
        ImGui.Text("Assistance: " .. (runtime.assist and "ON" or "OFF"))
        ImGui.Text("Chaos: " .. (runtime.chaos and "ON" or "OFF"))
        ImGui.Text("Capri heartbeat: " .. (clientAlive() and "connected" or "offline"))
        ImGui.Text("Rare Blackwall: " .. math.floor(config.blackwallChance*100) .. "% per assist opportunity")
        if ImGui.Button("Toggle assistance") then runtime.assist=not runtime.assist end
        if ImGui.Button("Toggle chaos mode") then runtime.chaos=not runtime.chaos; autoClock=0 end
        ImGui.TextWrapped("NPCs / cars / devices / access points. In Capri: hack that car, blow it up, hack the access point, chaos mode on, stand down.")
    end
    ImGui.End()
end)
registerInput("capri_ghost_spike","Capri Night City: Ghost Spike",function(pressed)
    if not pressed then return end
    local ok,err=pcall(function()
        local p,menu=playerContext(); if not p or menu or not clientAlive() then log("Load a save, close menus and connect Capri first."); return end
        local success,message=cast("spike",targetAtCrosshair(p),p); log(message)
    end)
    if not ok then log(err) end
end)
registerForEvent("onShutdown",function()
    clearScan()
    pcall(function() cleanup(nil,true); if runtime then runtime.assist=false; runtime.chaos=false; runtime.counter=false; snapshot(nil,true) end end)
end)
return mod
