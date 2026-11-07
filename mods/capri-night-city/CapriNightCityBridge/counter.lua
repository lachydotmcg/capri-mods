-- Retaliation uses the actual incoming hack source, never a nearest-NPC guess.
local Targets=require("targets")
local Counter={}; Counter.__index=Counter
local function key(object) return object and tostring(object:GetEntityID().hash) end
function Counter.new(context)
    return setmetatable({context=context,silent={},cancelled=setmetatable({},{__mode="k"}),depth=0},Counter)
end
function Counter:reset()
    self.silent={}; self.cancelled=setmetatable({},{__mode="k"}); self.depth=0
end
function Counter:isSilent(npc)
    local untilTime=npc and self.silent[key(npc)]
    return untilTime and self.context.now()<untilTime or false
end
function Counter:prune()
    for id,untilTime in pairs(self.silent) do if self.context.now()>=untilTime then self.silent[id]=nil end end
end
function Counter:enabled(player)
    local current,menu=self.context.player()
    return self.context.enabled() and current and player and key(current)==key(player) and not menu
        and ScriptedPuppet.IsActive(current) and self.context.alive()
end
function Counter:block(npc,player)
    if not self:enabled(player) or not npc or not IsDefined(npc) then return false end
    if self:isSilent(npc) then return true end
    if Targets.kind(npc)~="npc" or not Targets.check(npc,player,math.huge,false) then return false end
    -- The incoming event proves this NPC is attacking/tracing V, even if its attitude is
    -- still neutral before a trace completes. No general neutral-NPC auto-attack is enabled.
    self:prune()
    local count=0; local oldest,oldestAt
    for id,at in pairs(self.silent) do count=count+1; if not oldestAt or at<oldestAt then oldest,oldestAt=id,at end end
    if count>=128 and oldest then self.silent[oldest]=nil end
    local id=key(npc); self.silent[id]=self.context.now()+15
    -- Unattributed environmental-style death: no player damage/hit event, no death
    -- animation, ragdoll remains enabled. The body is not removed or hidden.
    local ok,err=pcall(function() npc:Kill(nil,true,false) end)
    if not ok then self.silent[id]=nil; self.context.log("Silent retaliation failed: "..tostring(err)); return false end
    self.context.log("Silent retaliation requested against identified incoming netrunner "..id..".")
    return true
end
function Counter:attempt(npc,player)
    local ok,blocked=pcall(self.block,self,npc,player)
    if not ok then self.context.log("Counterhack source check failed: "..tostring(blocked)); return false end
    return blocked
end
function Counter:listenerBlocked(listener)
    if not listener then return false end
    return self:attempt(listener.m_npcPuppet,listener.m_playerPuppet)
end
function Counter:cancel(listener)
    if self.cancelled[listener] then return end
    self.cancelled[listener]=true
    local player,npc=listener.m_playerPuppet,listener.m_npcPuppet
    local failures={}
    local function try(label,fn)
        local ok=pcall(fn); if not ok then failures[#failures+1]=label end
    end
    -- Mirror vanilla's interrupted-upload cleanup, never ForceClose/CompleteAction:
    -- ForceClose actually completes the quickhack and can start combat for a trace.
    try("upload pool",function() Game.GetStatPoolsSystem():RequestRemovingStatPool(player:GetEntityID(),gamedataStatPoolType.QuickHackUpload) end)
    try("upload listener",function() Game.GetStatPoolsSystem():RequestUnregisteringListener(player:GetEntityID(),gamedataStatPoolType.QuickHackUpload,listener) end)
    try("network link",function() listener:RemoveLink(npc) end)
    try("linked effects",function()
        local action=listener.m_action:GetObjectActionID()
        local trace=action==TweakDBID.new("AIQuickHack.HackRevealPosition") or action==TweakDBID.new("AIQuickHack.PreventionHackRevealPosition")
        listener:RemoveLinkedStatusEffects(npc,trace)
    end)
    try("reveal state",function() player:SetIsBeingRevealed(false) end)
    for _,record in ipairs({"AIQuickHackStatusEffect.BeingHacked","BaseStatusEffect.ForcedQHUploadAwarenessBumps"}) do
        try(record,function() Game.GetStatusEffectSystem():RemoveStatusEffect(player:GetEntityID(),TweakDBID.new(record)) end)
    end
    try("save lock",function() SaveLocksManager.RequestSaveLockRemove(player:GetGame(),CName.new("PlayerBeingHacked")) end)
    try("HUD",function()
        if listener.m_hudBlackboard then
            local defs=GetAllBlackboardDefs().UI_HUDProgressBar
            listener.m_hudBlackboard:SetString(defs.FailedText,"LocKey#15353")
            listener.m_hudBlackboard:SetBool(defs.Active,false)
        end
    end)
    try("prevention bar reference",function() PreventionSystemHackerLoop.UpdateOtherProgressBarReference(player:GetGame(),nil) end)
    try("progress event",function()
        local evt=NewObject("UploadProgramProgressEvent")
        evt.state=EUploadProgramState.COMPLETED
        player:QueueEvent(evt)
    end)
    if #failures>0 then self.context.log("Counterhack completion suppressed; cleanup interfaces unavailable: "..table.concat(failures,", ")) end
end
function Counter:install()
    local guard=self
    Override("PlayerPuppet","OnHackTargetEvent",function(player,evt,wrapped)
        local ok,blocked=pcall(function()
            if not evt or key(player)~=tostring(evt.targetID.hash) then return false end
            return guard:attempt(Game.FindEntityByID(evt.netrunnerID),player)
        end)
        if ok and blocked then return false end
        return wrapped(evt)
    end)
    -- Sources started directly by other game systems or already tracing when enabled.
    ObserveAfter("UploadFromNPCToPlayerListener","Initialize",function(listener)
        local ok,err=pcall(guard.listenerBlocked,guard,listener)
        if not ok then guard.context.log("Counterhack initialize unavailable: "..tostring(err)) end
    end)
    Override("UploadFromNPCToPlayerListener","OnStatPoolValueChanged",function(listener,old,new,scale,wrapped)
        if guard:listenerBlocked(listener) then guard:cancel(listener); return end
        return wrapped(old,new,scale)
    end)
    Override("UploadFromNPCToPlayerListener","OnStatPoolMaxValueReached",function(listener,value,wrapped)
        if guard:listenerBlocked(listener) then guard:cancel(listener); return false end
        return wrapped(value)
    end)
    -- Vanilla death still processes loot, ragdoll and MarkDeadBody. Suppress only the
    -- remote squad/fear broadcasts caused by this mod's identified counter victims.
    Override("AISquadHelper","NotifySquadOnIncapacitated;ScriptedPuppet",function(puppet,wrapped)
        if guard:isSilent(puppet) then return end
        return wrapped(puppet)
    end)
    Override("NPCPuppet","OnIncapacitated",function(npc,wrapped)
        if not guard:isSilent(npc) then return wrapped() end
        guard.depth=guard.depth+1
        local ok,result=pcall(wrapped)
        guard.depth=math.max(0,guard.depth-1)
        if not ok then error(result) end
        local marked,err=pcall(function() npc:GetStimReactionComponent():SetDownedBodyVisibleComponent(true,CName.new("Dead_Body")) end)
        if not marked then guard.context.log("Counterhack body visibility could not be confirmed: "..tostring(err)) end
        return result
    end)
    Override("ReactionSystem","AddFearSource",function(system,position,radius,debugInfo,wrapped)
        if guard.depth>0 then return end
        return wrapped(position,radius,debugInfo)
    end)
    Override("ReactionManagerComponent","OnIncapacitatedEvent",function(component,evt,wrapped)
        local ok,npc=pcall(function() return component:GetOwner() end)
        if ok and guard:isSilent(npc) then return false end
        return wrapped(evt)
    end)
end
return Counter
