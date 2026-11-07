-- Target-specific engine adapters. No NPC status effects are applied to vehicles/devices.
local Targets = {}
local scanPermissions={}
function Targets.resetScanPermissions() scanPermissions={} end
function Targets.releaseScanPermission(id) scanPermissions[tostring(id.hash)]=nil end
function Targets.installScanHooks()
    -- Vanilla explicitly excludes civilians/crowds/friendlies from CanBeTagged.
    -- Permit only NPCs in this mod's current scan set; preserve the vanilla result elsewhere.
    Override("ScriptedPuppet","CanBeTagged",function(npc,wrapped)
        if scanPermissions[tostring(npc:GetEntityID().hash)] and ScriptedPuppet.IsActive(npc) then return true end
        return wrapped()
    end)
end
local function optional(fn, fallback)
    local ok,value=pcall(fn); if ok then return value end; return fallback
end
function Targets.kind(target)
    if not target or not IsDefined(target) then return "none" end
    if target:IsA("NPCPuppet") then return "npc" end
    if target:IsA("VehicleObject") or optional(function() return GameObject.IsVehicle(target) end,false) then return "vehicle" end
    local ps=optional(function() return target:GetDevicePS() end,nil)
    if ps then
        if optional(function() return ps:IsA("AccessPointControllerPS") end,false) then return "access_point" end
        return "device"
    end
    return "unsupported"
end
function Targets.label(target)
    return optional(function() return target:GetDisplayName() end,"scanner target")
end
function Targets.check(target,player,range,hostileOnly)
    local kind=Targets.kind(target)
    if kind=="none" or target==player then return false,"Select a scanner target.",kind end
    if kind=="unsupported" then return false,"Scanner highlight found, but this entity exposes no supported hack interface.",kind end
    if optional(function() return target:IsQuest() end,false) or optional(function() return target:IsBoss() end,false) then
        return false,"The game marks this target as quest/boss protected.",kind
    end
    local god=Game.GetGodModeSystem()
    if god:HasGodMode(target:GetEntityID(),gameGodModeType.Invulnerable) or god:HasGodMode(target:GetEntityID(),gameGodModeType.Immortal) then
        return false,"Target is protected by the game.",kind
    end
    local a,b=player:GetWorldPosition(),target:GetWorldPosition()
    if (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2>range^2 then return false,"Target is out of hack range.",kind end
    -- Companion hacks are network abilities: occlusion is not an eligibility condition.
    -- Range, supported interface and protected-target checks still apply through walls.
    if kind=="npc" then
        if not ScriptedPuppet.IsActive(target) or target:IsDead() then return false,"That target is already down.",kind end
        if PlayerPuppet.IsTargetChildNPC(player,target) then return false,"This NPC is protected.",kind end
        if hostileOnly and (target:IsCrowd() or PlayerPuppet.IsTargetFriendlyNPC(player,target) or GameObject.GetAttitudeBetween(target,player)~=EAIAttitude.AIA_Hostile) then
            return false,"Combat assistance targets hostile NPCs only.",kind
        end
    elseif kind=="vehicle" then
        local mounted=player:GetMountedVehicle()
        if mounted and tostring(mounted:GetEntityID().hash)==tostring(target:GetEntityID().hash) then return false,"Skipping the vehicle V is currently in.",kind end
        if optional(function() return target:IsDestroyed() end,false) then return false,"Vehicle is destroyed.",kind end
    end
    return true,nil,kind
end
local function name(action)
    return tostring(NameToString(action:GetActionName()))
end
function Targets.remoteActions(target,player)
    local ps=target:GetDevicePS()
    local context=ps:GenerateContext(gamedeviceRequestType.Remote,Device.GetInteractionClearance(),player,target:GetEntityID())
    -- These are companion abilities: no player cyberdeck/RAM gate. Device-specific locks remain.
    context.ignoresRPG=true
    local actions=ps:GetRemoteActions(context) or {}
    local result={}
    for _,action in ipairs(actions) do
        if action and not optional(function() return action:IsInactive() end,true) then
            local label=name(action); local lower=label:lower()
            if not lower:find("quest",1,true) and not lower:find("takecontrol",1,true) and not lower:find("netrunnerdive",1,true) then
                result[#result+1]={action=action,name=label,lower=lower}
            end
        end
    end
    return ps,result
end
local function matches(intent,label)
    if intent=="device_distract" or intent=="blind" then return label:find("distract",1,true) or label:find("malfunction",1,true) end
    if intent=="device_off" or intent=="control" or intent=="collapse" or intent=="jam" then return label:find("toggle",1,true) or label:find("disable",1,true) or label:find("shutdown",1,true) end
    if intent=="explode" or intent=="kill" or intent=="burn" or intent=="spike" then return label:find("overload",1,true) or label:find("explod",1,true) end
    if intent=="open" then return label:find("open",1,true) or label:find("toggle",1,true) end
    return intent=="smart" or intent=="chaos" or intent=="assist"
end
function Targets.device(intent,target,player)
    local ps,actions=Targets.remoteActions(target,player)
    if intent=="device_off" and optional(function() return ps:IsOFF() end,false) then return false,"Device is already off." end
    local candidates={}
    for _,entry in ipairs(actions) do if matches(intent,entry.lower) then candidates[#candidates+1]=entry end end
    if #candidates==0 then return false,"This device has no currently available remote action for that request." end
    local chosen=candidates[math.random(#candidates)]
    chosen.action:SetExecutor(player)
    chosen.action:RegisterAsRequester(target:GetEntityID())
    ps:ExecutePSAction(chosen.action)
    return true,"Device action queued: " .. chosen.name .. "."
end
function Targets.breach(target,player)
    local ps=target:GetDevicePS()
    if ps:IsBreached() then return false,"Access point is already breached." end
    -- Native companion/NPC breach path exposes the connected network without fabricating loot.
    local event=NewObject("NPCBreachEvent")
    event.state=HackingMinigameState.Succeeded
    ps:OnNPCBreachEvent(event)
    if not ps:IsBreached() then return false,"Access point refused the breach." end
    return true,"Access point network breached. Minigame loot has not been awarded."
end
function Targets.vehicle(intent,target,player,schedule,now)
    local action=intent
    if intent=="smart" or intent=="assist" then action="brake" end
    if intent=="control" or intent=="lock" or intent=="jam" or intent=="collapse" then action="brake" end
    if intent=="kill" or intent=="burn" or intent=="spike" then action="explode" end
    if intent=="chaos" then local options={"brake","accelerate","explode"}; action=options[math.random(#options)] end
    if action=="explode" then
        -- REDscript's import alias is VehicleExplodeEvent; CET needs the actual native RTTI name.
        local evt=NewObject("vehicleExplodeEvent")
        if not evt or not IsDefined(evt) then return false,"Native vehicleExplodeEvent could not be constructed; no explosion was sent." end
        target:QueueEvent(evt)
        schedule[#schedule+1]={id=target:GetEntityID(),confirmDestruction=true,at=now+.25,deadline=now+5}
        return true,"Native vehicle explosion sent. Waiting for the game to confirm destruction."
    end
    local eventType=action=="brake" and "vehicleForceBrakesQuickhackEvent" or action=="accelerate" and "vehicleAccelerateQuickhackEvent" or nil
    if not eventType then return false,"Use stop the car, accelerate the car, blow up the car, or hack the car." end
    local evt=NewObject(eventType)
    if not evt or not IsDefined(evt) then return false,"Native vehicle event could not be constructed: "..eventType end
    evt.active=true
    if action=="brake" then evt.alarmDuration=4 end
    target:QueueEvent(evt)
    schedule[#schedule+1]={id=target:GetEntityID(),vehicleEvent=eventType,at=now+4}
    return true,action=="brake" and "Vehicle brake hack engaged." or "Vehicle acceleration hack engaged."
end
function Targets.nearby(player,range,limit)
    local list,seen={},{}
    local function add(entity)
        if not entity or not IsDefined(entity) or entity==player then return end
        local key=tostring(entity:GetEntityID().hash)
        if not seen[key] and #list<limit then seen[key]=true; list[#list+1]=entity end
    end
    add(Game.GetTargetingSystem():GetLookAtObject(player,false,false))
    local query=Game["TSQ_ALL;"](); query.maxDistance=range; query.filterObjectByDistance=true; query.ignoreInstigator=true
    query.testedSet=TargetingSet.Complete
    local success,parts=Game.GetTargetingSystem():GetTargetParts(player,query)
    if success and parts then for _,part in ipairs(parts) do
        pcall(function() add(part:GetComponent():GetEntity()) end)
    end end
    return list
end
function Targets.enemies(player,range,throughWalls,hostileOnly)
    -- Keep the legacy throughWalls argument for compatibility; all discovery now ignores occlusion.
    local candidates=Targets.nearby(player,range,96)
    local tracker=player:GetTargetTrackerComponent()
    if tracker then for _,location in ipairs(tracker:GetHostileThreats(false)) do
        if location.entity then candidates[#candidates+1]=location.entity end
    end end
    local enemies,seen={},{}
    local origin=player:GetWorldPosition()
    for _,target in ipairs(candidates) do
        local id=tostring(target:GetEntityID().hash)
        if not seen[id] and Targets.kind(target)=="npc" and Targets.check(target,player,range,hostileOnly or false) then
            seen[id]=true; local p=target:GetWorldPosition()
            enemies[#enemies+1]={target=target,distance=(p.x-origin.x)^2+(p.y-origin.y)^2+(p.z-origin.z)^2}
        end
    end
    table.sort(enemies,function(a,b) return a.distance<b.distance end)
    return enemies
end
function Targets.highlight(npc,source)
    local scanner=Game.GetVisionModeSystem():GetScanningController()
    local existed=scanner:IsTagged(npc)
    if not existed then
        -- Same pipeline used by scanner tagging/cameras: native tag, reveal, HUD and blackboard.
        local tagging=npc:GetTaggingSystem()
        if not tagging:CanTag() then error("Game scanner tagging is blocked: cybereye or NoScanning restriction.") end
        scanPermissions[tostring(npc:GetEntityID().hash)]=true
        local queried,allowed=pcall(function() return npc:CanBeTagged() end)
        if not queried or not allowed then Targets.releaseScanPermission(npc:GetEntityID()); error("This NPC cannot be tagged by the scanner.") end
        local ok,err=pcall(GameObject.TagObject,npc)
        if not ok then Targets.releaseScanPermission(npc:GetEntityID()); error(err) end
    end
    return {scannerTag=true,existed=existed}
end
function Targets.scanPulse(player,range)
    Game.GetVisionModeSystem():GetScanningController():PulseScan(player,range,player:GetWorldPosition())
end
function Targets.isHighlighted(npc) return Game.GetVisionModeSystem():GetScanningController():IsTagged(npc) end
function Targets.clearHighlight(npc,owned)
    Targets.releaseScanPermission(npc:GetEntityID())
    if owned and owned.scannerTag and not owned.existed then GameObject.UntagObject(npc) end
end
function Targets.closestEnemy(player,range)
    local enemies=Targets.enemies(player,range,false)
    return enemies[1] and enemies[1].target or nil
end
function Targets.group(player,range,kind,front)
    if kind=="npc" and not front then return Targets.enemies(player,range,false,false) end
    local list={}; local origin=player:GetWorldPosition(); local direction=front and player:GetWorldForward() or nil
    for _,target in ipairs(Targets.nearby(player,range,96)) do
        if Targets.kind(target)==kind and Targets.check(target,player,range,false,false) then
            local p=target:GetWorldPosition(); local x,y,z=p.x-origin.x,p.y-origin.y,p.z-origin.z
            local distance=x*x+y*y+z*z
            if not front or distance>0 and (x*direction.x+y*direction.y+z*direction.z)/math.sqrt(distance)>=.5 then
                list[#list+1]={target=target,distance=distance}
            end
        end
    end
    table.sort(list,function(a,b) return a.distance<b.distance end); return list
end
return Targets
