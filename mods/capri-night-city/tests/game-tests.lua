local source=assert(arg[1],"source folder")
for _,file in ipairs({"command.txt","result.txt","snapshot.txt","client.txt","peer-stop.txt","emergency-cooldown.txt"}) do os.remove(file) end
do local f=assert(io.open("settings.json","w")); f:write("{}"); f:close() end
package.path=source .. "/?.lua;" .. package.path
local Core=require("core")
local Targets=require("targets")
math.randomseed(1200)
local checks=0
local function check(value,name) assert(value,"FAIL " .. name); checks=checks+1; print("PASS " .. name) end
local c=Core.new("session")
local function cmd(id,action,time,session) return {id=id,action=action,issued=tostring(time),session=session or "session"} end
check(Core.parse("protocol=1\nid=x\ncommit=x\n").id=="x","complete wire message")
check(Core.parse("protocol=1\nid=x\ncommit=y\n")==nil,"partial wire message rejected")
check(Core.parse(string.rep("x",32769))==nil,"oversized wire message rejected")
check(c:validate(cmd("a","spike",100),100),"valid command")
check(not c:validate(cmd("a","erase",100),100),"replayed ID rejected")
check(not c:validate(cmd("old","spike",90),100),"expired command rejected")
check(not c:validate(cmd("future","spike",110),100),"future command rejected")
check(not c:validate(cmd("session","spike",100,"other"),100),"wrong session rejected")
check(not c:validate(cmd("code","loadstring",100),100),"arbitrary code action rejected")
c:used("spike",100)
check(not c:ready("burn",101),"global normal hack cooldown")
check(c:ready("burn",108),"normal cooldown expires")
c:used("blackwall",110)
check(not c:ready("blackwall",289),"Blackwall cooldown enforced")
check(c:ready("blackwall",290),"Blackwall cooldown expires")
local defense=Core.new("defense")
defense:used("spike",100)
check(defense:ready("control",100,"protect"),"ordinary manual cooldown does not delay protection")
defense:used("blind",100,"protect")
check(not defense:ready("jam",101,"protect") and defense:ready("jam",101.5,"protect"),"protection has its own 1.5-second cooldown")
check(not defense:ready("burn",101) and defense:ready("burn",108),"defensive use preserves the ordinary eight-second cooldown")
defense:used("blackwall",110)
check(not defense:ready("blackwall",111,"protect"),"defensive channel cannot bypass Blackwall cooldown")
for i=1,40 do c:event("kill","event " .. i) end
check(#c.events==24 and c.events[1].seq==17,"bounded event ring")
local picker=Core.new("selection")
local all=function() return true end
local noBlackwall=function(action) return action~="blackwall" end
local zero=function() return 0 end
local context={machine=false,danger=false,blackwallChance=.03}
check(picker:choose("blind",context,all,zero)=="blind","blind intent cannot select a lethal hack")
check(picker:choose("kill",context,all,zero)=="blackwall","rare Blackwall roll for lethal intent")
check(picker:choose("kill",context,noBlackwall,zero)=="erase","ordinary kill chooses lethal alternative")
picker.lastChoice="erase"
check(picker:choose("kill",context,noBlackwall,zero)=="thermal_erase","lethal choices avoid immediate repetition")
context.machine=true
check(picker:choose("kill",context,noBlackwall,zero)=="neural_erase","machine executions avoid thermal variant")
context.danger=true; picker.lastChoice=nil
check(picker:choose("smart",context,all,zero)=="jam","machine emergency chooses weapon control")
context.machine=false
check(picker:choose("smart",context,all,zero)=="blind","human emergency chooses control")
context.danger=false
check(picker:choose("smart",context,all,zero)=="spike","healthy open-ended intent can choose damage")
check(picker:choose("control",context,all,zero)=="blind","disable intent stays in control pool")
check(picker:choose("smart",context,function(a) return a=="jam" end,zero)=="jam","missing or active effects skipped")
check(picker:choose("blind",context,function() return false end,zero)==nil,"explicit blind request does not silently substitute another hack")
check(picker:choose("control",context,function(a) return a=="ghost_veil" end,zero)=="ghost_veil","adaptive defense can select a new custom quiet program")
check(picker:choose("smart",context,function(a) return a=="siphon" end,zero)=="siphon","open-ended hacks can select Neural Siphon")
check(picker:choose("kill",context,function(a) return a=="reaper_thread" end,zero)==nil,"generic kill cannot quietly become a delayed Reaper execution")

local events,observers,overrides={},{},{}
registerForEvent=function(name,callback) events[name]=callback end
registerInput=function() end
Observe=function(class,method,callback) observers[class .. "." .. method]=callback end
ObserveAfter=Observe
Override=function(class,method,callback) overrides[class .. "." .. method]=callback end
IsDefined=function(obj) return obj~=nil end
EAIAttitude={AIA_Hostile="hostile"}
gameGodModeType={Invulnerable="invulnerable",Immortal="immortal"}
gamedataStatPoolType={Health="Health"}
gamedataNPCType={Human="Human",Android="Android",Drone="Drone",Mech="Mech",Spiderbot="Spiderbot"}
TweakDBID={new=function(value) return value or "" end}
CName={new=function(value) return value end}
TargetingSet={Complete="Complete"}
FocusForcedHighlightData={new=function() return {} end}
HighlightInstance={new=function() return {} end}
EPriority={Absolute="Absolute"}
EFocusOutlineType={ENEMY_NETRUNNER="ENEMY_NETRUNNER"}
EFocusForcedHighlightType={ENEMY_NETRUNNER="ENEMY_NETRUNNER"}
VisionModePatternType={Netrunner="Netrunner"}
json={decode=function() return {emergencyEnabled=false} end}
local sim={time=1000,menu=false,pregame=false,combat=false,health=100,wanted=0,vehicle=false,target=nil,applied=0,killed=0,damage=0,record=true}
local actualTime=os.time
os.time=function() return math.floor(sim.time) end
local objects={}
local function entity(id)
    local e={id=id,active=true,health=100,effects={}}
    function e:GetEntityID() return {hash=self.id} end
    function e:IsA(name) return name==(self.tag or "NPCPuppet") and self.id~="V" end
    function e:GetDevicePS() return self.ps end
    function e:QueueEvent(evt) self.queued=self.queued or {}; self.queued[#self.queued+1]=evt end
    function e:ForceVisionAppearanceNetrunner(target,source,name,on) self.revealed=on end
    function e:IsAttached() return true end
    function e:IsDead() return self.dead or false end
    function e:IsDestroyed() return self.destroyed or false end
    function e:ForceVisionAppearance(data) self.revealed=true; self.highlight=data end
    function e:CancelForcedVisionAppearance(data) if self.highlight==data then self.revealed=false end end
    function e:GetTaggingSystem() return {CanTag=function() return not sim.scanningBlocked end} end
    function e:CanBeTagged()
        local original=function() return not (self.untaggable or self.crowd or self.friendly or self.civilian) end
        local override=overrides["ScriptedPuppet.CanBeTagged"]
        return override and override(self,original) or original()
    end
    function e:GetGame() return "game" end
    function e:GetStimReactionComponent() return {SetDownedBodyVisibleComponent=function(_,visible) self.bodyVisible=visible end} end
    function e:IsCrowd() return self.crowd or false end
    function e:IsQuest() return self.quest or false end
    function e:IsBoss() return self.boss or false end
    function e:GetWorldPosition() return {x=self.distance or 0,y=0,z=0} end
    function e:GetWorldForward() return {x=1,y=0,z=0} end
    function e:GetDisplayName() return self.id end
    function e:GetNPCType() return self.kind or "Human" end
    function e:Kill(instigator,skipDeath,disableRagdoll)
        self.killInstigator=instigator; self.skipDeath=skipDeath; self.disableRagdoll=disableRagdoll
        self.dead=true; self.active=false; sim.killed=sim.killed+1
        if observers["NPCPuppet.OnDeath"] then observers["NPCPuppet.OnDeath"](self,{instigator=instigator}) end
    end
    objects[id]=e; return e
end
local player=entity("V")
function player:IsInCombat() return sim.combat end
function player:SetIsBeingRevealed(value) sim.beingRevealed=value end
function player:GetMountedVehicle() return sim.mounted end
function player:GetPlayerStateMachineBlackboard() return {GetBool=function() return sim.vehicle end} end
function player:GetTargetTrackerComponent() return {GetHostileThreats=function() return {} end} end
local enemy=entity("enemy"); sim.target=enemy
ScriptedPuppet={IsActive=function(e) return e.active end}
PlayerPuppet={IsTargetFriendlyNPC=function(p,t) return t.friendly end,IsTargetChildNPC=function(p,t) return t.child end}
GameObject={GetAttitudeBetween=function(t,p) return t.neutral and "neutral" or "hostile" end}
GameObject.TagObject=function(npc) if npc:CanBeTagged() then npc.tagged=true; npc.revealed=true end end
GameObject.UntagObject=function(npc) npc.tagged=false; npc.revealed=false end
GetSingleton=function() return {GetSystemRequestsHandler=function() return {IsPreGame=function() return sim.pregame end} end} end
GetAllBlackboardDefs=function() return {UI_System={IsInMenu="menu"},PlayerStateMachine={MountedToVehicle="vehicle"},UI_HUDProgressBar={FailedText="failed",Active="active"}} end
gamedataStatPoolType.QuickHackUpload="upload"
EUploadProgramState={COMPLETED="completed"}
SaveLocksManager={RequestSaveLockRemove=function() sim.saveLockRemoved=true end}
PreventionSystemHackerLoop={UpdateOtherProgressBarReference=function() sim.preventionBarCleared=true end}
local ses={
    HasStatusEffect=function(self,id,record) return objects[id.hash].effects[record]~=nil end,
    ApplyStatusEffect=function(self,id,record,dbid,instigator)
        if sim.rejectEffect or sim.rejectRecord==record then return false end
        objects[id.hash].effects[record]=true; sim.applied=sim.applied+1; return true
    end,
    RemoveStatusEffect=function(self,id,record)
        if sim.failCleanupId==id.hash then sim.cleanupFailures=(sim.cleanupFailures or 0)+1; error("fixture cleanup failure") end
        objects[id.hash].effects[record]=nil
    end
}
Game={
    GetVisionModeSystem=function() return {GetScanningController=function() return {
        IsTagged=function(self,npc) return npc.tagged or false end,
        PulseScan=function(self,p,range,position) sim.scanPulses=(sim.scanPulses or 0)+1; sim.scanRange=range end
    } end} end,
    GetPlayer=function() return sim.pregame and nil or player end,
    GetBlackboardSystem=function() return {Get=function() return {GetBool=function() return sim.menu end} end} end,
    GetGodModeSystem=function() return {HasGodMode=function(self,id,mode) return objects[id.hash][mode] or false end} end,
    GetTargetingSystem=function() return {GetLookAtObject=function() return sim.target end,IsVisibleTarget=function(self,p,t) return not t.hidden end,
        GetTargetParts=function(self,p,query) local parts={}; for _,entity in ipairs(sim.nearby or {}) do
            if not entity.hidden or query.testedSet==TargetingSet.Complete then
                parts[#parts+1]={GetComponent=function() return {GetEntity=function() return entity end} end}
            end
        end; return true,parts end} end,
    GetStatusEffectSystem=function() return ses end,
    GetStatPoolsSystem=function() return {
        RequestRemovingStatPool=function(self,id,pool) sim.uploadRemoved=(sim.uploadRemoved or 0)+1; sim.uploadPool=pool end,
        RequestUnregisteringListener=function(self,id,pool,listener) sim.uploadUnregistered=(sim.uploadUnregistered or 0)+1 end,
        GetStatPoolValue=function(self,id,pool,percentage) return percentage==false and (sim.rawHealth or sim.health) or sim.health end,
        RequestChangingStatPoolValue=function(self,id,pool,diff,p,chunk,percentage)
            if id.hash=="V" and diff>0 then
                check(percentage==false and (diff==100 or diff==25),"healing uses the intended raw HP amount, not a percentage")
                sim.rawHealth=math.min(sim.maxHealth or 200,(sim.rawHealth or sim.health)+diff)
                sim.health=sim.rawHealth/(sim.maxHealth or 200)*100
                if diff==25 then sim.siphonHeals=(sim.siphonHeals or 0)+1 else sim.heals=(sim.heals or 0)+1 end
            else check(percentage==true,"damage uses percentage API"); sim.damage=sim.damage-diff end
        end
    } end,
    GetScriptableSystemsContainer=function() return {Get=function() return {GetHeatStageAsInt=function() return sim.wanted end} end} end,
    GetJournalManager=function() return {GetTrackedEntry=function() return sim.quest end,GetEntryHash=function(self,q) return q end} end,
    FindEntityByID=function(id) return objects[id.hash] end
}
Game["TSQ_ALL;"]=function() return {} end
NewObject=function(name)
    if name:match("^Vehicle") or (name=="vehicleExplodeEvent" and sim.missingNative) then return nil end
    return {type=name}
end
NameToString=function(value) return value end
gamedeviceRequestType={Remote="Remote"}
Device={GetInteractionClearance=function() return "clearance" end}
HackingMinigameState={Succeeded="Succeeded"}
TweakDB={GetRecord=function(self,record) return sim.record and not (sim.missingRecords and sim.missingRecords[record]) end}
local function write(path,text) local f=assert(io.open(path,"w")); f:write(text); f:close() end
local function read(path) local f=assert(io.open(path,"r")); local text=f:read("*a"); f:close(); return Core.parse(text) end
local function snapshot() return read("snapshot.txt") end
local counter=0
local function lease()
    local s=snapshot(); write("client.txt",Core.pack({protocol="1",id="lease",issued=os.time(),session=s.session},{"protocol","id","issued","session"}))
end
local function tick(n,connected)
    for i=1,(n or 1) do sim.time=sim.time+.25; if connected then lease() end; events.onUpdate(.25) end
end
local function command(action,target,selection,expected,count)
    counter=counter+1; local s=snapshot(); lease()
    write("command.txt",Core.pack({protocol="1",id="test"..counter,session=s.session,issued=os.time(),action=action,target=target or (sim.target and sim.target.id or ""),selection=selection or "aim",expected=expected or "",count=count or 1},
        {"protocol","id","session","issued","action","target","selection","expected","count"}))
    tick(); return read("result.txt")
end
local function action(name,inactive)
    return {GetActionName=function() return name end,IsInactive=function() return inactive or false end,
        SetExecutor=function(self,p) self.executor=p end,RegisterAsRequester=function(self,id) self.requester=id end}
end
local function device(id,access)
    local object=entity(id); object.tag="Device"; object.ps={breached=false,actions={action("QuickHackDistraction"),action("ToggleON"),action("OverloadDevice"),action("QuestDestroy",false),action("DisabledAction",true)}}
    function object.ps:IsA(name) return access and name=="AccessPointControllerPS" end
    function object.ps:GenerateContext() return {} end
    function object.ps:GetRemoteActions(context) check(context.ignoresRPG,"companion device context ignores player RAM/perk gate"); return self.actions end
    function object.ps:ExecutePSAction(value) self.executed=value end
    function object.ps:IsBreached() return self.breached end
    function object.ps:OnNPCBreachEvent(evt) self.breached=evt.state=="Succeeded" end
    function object.ps:IsOFF() return false end
    return object
end
local peer=arg[2] and arg[2]:match("^peer")
if arg[2]=="peer_vehicle" then sim.target=entity("peer-car"); sim.target.tag="VehicleObject" end
if arg[2]=="peer_device" then sim.target=device("peer-camera",false) end
if arg[2]=="peer_access_point" then sim.target=device("peer-access",true) end
local mod=dofile(source .. "/init.lua")
events.onInit(); tick()
if peer then
    -- A real C# process drives this fixture through the exact production wire files.
    -- Busy loop is bounded to five seconds; it does not start the game or touch live files.
    local untilTime=actualTime()+8
    local nextFrame=os.clock()
    while actualTime()<untilTime do
        if os.clock()>=nextFrame then
            nextFrame=os.clock()+.05
            local stop=io.open("peer-stop.txt","r"); if stop then stop:close(); break end
            sim.time=actualTime(); events.onUpdate(.05)
        end
    end
    events.onShutdown(); os.time=actualTime; return
end
check(snapshot().ready=="1","loaded-save snapshot")
check(snapshot().counter=="1","netrunner retaliation defaults to armed in a new session")
check(snapshot().target=="enemy" and snapshot().eligible=="1","eligible target snapshot")
local result=command("spike")
check(result.ok=="1" and sim.damage==40,"spike acknowledged with damage")
tick(1); check(sim.damage==40,"duplicate command file cannot apply damage twice")
check(command("burn").ok=="0","normal cooldown blocks second hack")
tick(36,true)
enemy.quest=true; check(command("erase").ok=="0" and sim.killed==0,"quest target protected"); enemy.quest=false
enemy.boss=true; check(command("erase").ok=="0","boss protected"); enemy.boss=false
enemy.friendly=true; check(not Targets.check(enemy,player,35,true) and Targets.check(enemy,player,35,false),"friendly NPC allowed manually, excluded from combat assistance"); enemy.friendly=false
enemy.neutral=true; check(not Targets.check(enemy,player,35,true) and Targets.check(enemy,player,35,false),"neutral NPC allowed manually, excluded from combat assistance"); enemy.neutral=false
enemy.crowd=true; check(not Targets.check(enemy,player,35,true) and Targets.check(enemy,player,35,false),"adult crowd NPC allowed manually, excluded from combat assistance"); enemy.crowd=false
enemy.child=true; check(command("erase").ok=="0","child NPC protected"); enemy.child=false
enemy.immortal=true; check(command("erase").ok=="0","immortal protected"); enemy.immortal=false
enemy.invulnerable=true; check(command("erase").ok=="0","invulnerable protected"); enemy.invulnerable=false
enemy.hidden=true; check(Targets.check(enemy,player,35,false),"occlusion no longer blocks target eligibility"); enemy.hidden=false
enemy.distance=100; check(command("erase").ok=="0","range enforced"); enemy.distance=0
check(command("erase","other").ok=="0","changed crosshair target rejected")
sim.menu=true; check(command("erase").ok=="0","menu command rejected"); sim.menu=false
sim.record=false; check(command("erase").ok=="0","missing native effect rejected"); sim.record=true
sim.rejectEffect=true; check(command("erase").ok=="0" and sim.killed==0,"rejected status effect cannot trigger kill"); sim.rejectEffect=false
check(command("lock").ok=="1","puppet lock accepted")
tick(20,true); check(next(enemy.effects)==nil,"transient effects cleaned up")
tick(16,true)
enemy.hidden=true
check(command("erase").ok=="1" and sim.killed==1,"signal erase executes through walls at final cast check")
enemy.hidden=false
check(snapshot().kills=="1","kill observer reports player-attributed death")
local enemy2=entity("enemy2"); sim.target=enemy2; tick(36,true)
check(command("blackwall").ok=="1","Blackwall upload acknowledged")
tick(24,true)
check(enemy2.dead and sim.killed==2,"delayed Blackwall completion")
local enemy3=entity("enemy3"); sim.target=enemy3; tick()
check(command("blackwall").ok=="0","Blackwall long cooldown applies across targets")
tick(36,true)
local killedBefore=sim.killed
check(command("blind").ok=="1" and enemy3.effects["BaseStatusEffect.Blind"] and sim.killed==killedBefore,"actual blind action applies optics effect without kill request")
tick(36,true)
check(command("jam").ok=="1" and enemy3.effects["BaseStatusEffect.WeaponMalfunctionSmartLock"],"weapon jam effect applied")
tick(36,true)
check(command("collapse").ok=="1" and enemy3.effects["BaseStatusEffect.SystemCollapse"],"system collapse effect applied")
tick(36,true)
check(command("control").ok=="1" and sim.killed==killedBefore,"adaptive disable does not call native Kill")
tick(36,true)
local chosen=command("kill")
check(chosen.ok=="1" and chosen.message:find("chosen",1,true) and sim.killed==killedBefore+1,"natural kill intent chooses a lethal hack and executes it")
local enemy4=entity("enemy4"); sim.target=enemy4; tick(36,true)
sim.health=20
check(command("smart").ok=="1" and sim.killed==killedBefore+1,"low-health adaptive hack protects V without execution")
sim.health=100; tick(36,true)
sim.health=20; sim.combat=true; sim.wanted=2; sim.vehicle=true; sim.quest=7; tick()
local s=snapshot(); local all=""; for i=1,24 do all=all .. (s["event_"..i] or "") end
check(all:find("low_health",1,true) and all:find("combat_start",1,true) and all:find("wanted",1,true),"health/combat/police events")
sim.health=0; tick(); local deathEvents=snapshot(); local deaths=""; for i=1,24 do deaths=deaths .. (deathEvents["event_"..i] or "") end
check(deaths:find("player_down",1,true),"player death state reaction"); sim.health=100
check(command("assist_off").ok=="1" and snapshot().assist=="0","stand down command")
local car=entity("car"); car.tag="VehicleObject"; sim.target=car; tick(36,true)
check(snapshot().target_kind=="vehicle" and snapshot().eligible=="1","vehicle scanner target is exposed to Capri")
sim.mounted=car; check(command("explode").ok=="0","V's occupied vehicle is skipped"); sim.mounted=nil
car.hidden=true
check(command("brake").ok=="1" and car.queued[1].type=="vehicleForceBrakesQuickhackEvent" and car.queued[1].active,"native vehicle braking event executes through walls")
car.hidden=false
tick(20,true); check(car.queued[#car.queued].active==false,"vehicle brake effect is released")
tick(16,true); check(command("accelerate").ok=="1" and car.queued[#car.queued].type=="vehicleAccelerateQuickhackEvent","native vehicle acceleration event")
tick(36,true); check(command("explode").ok=="1" and car.queued[#car.queued].type=="vehicleExplodeEvent","native vehicle explosion event")
car.destroyed=true; tick(2,true)
local confirmation=snapshot(); local confirmationText=""; for i=1,24 do confirmationText=confirmationText..(confirmation["event_"..i] or "") end
check(confirmationText:find("destruction confirmed",1,true),"vehicle success requires observed destroyed state")
car.destroyed=false; tick(36,true); sim.missingNative=true
check(command("explode").ok=="0","missing native constructor cannot produce success acknowledgement")
sim.missingNative=false
local camera=device("camera",false); sim.target=camera; tick(36,true)
check(snapshot().target_kind=="device" and snapshot().eligible=="1","device scanner target is exposed to Capri")
camera.hidden=true
check(command("device_distract").ok=="1" and camera.ps.executed:GetActionName()=="QuickHackDistraction","device distraction executes through walls using PS")
camera.hidden=false
tick(36,true); check(command("device_off").ok=="1" and camera.ps.executed:GetActionName()=="ToggleON","advertised device toggle action")
tick(36,true); check(command("explode").ok=="1" and camera.ps.executed:GetActionName()=="OverloadDevice","device overload uses an advertised native action")
local _,remote=Targets.remoteActions(camera,player)
check(#remote==3,"inactive and quest actions excluded from device selection")
camera.ps.actions={action("DisabledAction",true)}; tick(36,true)
check(command("smart").ok=="0","device without an active action reports refusal")
local ap=device("access",true); ap.hidden=true; sim.target=ap; tick(36,true)
check(snapshot().target_kind=="access_point","access-point class detected")
check(command("breach").ok=="1" and ap.ps.breached,"native access-point network breach")
tick(36,true); check(command("breach").ok=="0","already breached access point not repeatedly claimed")
local scenery=entity("scenery"); scenery.tag="StaticMesh"; sim.target=scenery; tick()
check(snapshot().eligible=="0" and command("smart").ok=="0","scanner-only props without a hack interface are refused")
sim.target=nil; tick(); check(command("chaos_on").ok=="1" and snapshot().chaos=="1","chaos can be enabled without a crosshair target")
sim.nearby={car}; sim.combat=false; local queueCount=#car.queued
tick(48,true); check(#car.queued>queueCount,"chaos discovers a nearby vehicle outside combat and outside crosshair")
local function starts()
    local n=0; for _,evt in ipairs(car.queued) do if evt.active or evt.type=="vehicleExplodeEvent" then n=n+1 end end; return n
end
local startsBefore=starts(); tick(48,false); check(starts()==startsBefore,"chaos stops initiating attacks after the Capri lease expires")
check(command("chaos_off").ok=="1" and snapshot().chaos=="0","chaos off command")
queueCount=#car.queued; tick(48,true); check(#car.queued==queueCount,"chaos off stops ambient vehicle attacks")
check(command("chaos_on").ok=="1","chaos reenabled")
check(command("assist_off").ok=="1" and snapshot().chaos=="0" and snapshot().assist=="0","stand down stops chaos and assistance together")
sim.target=enemy4; sim.nearby={}; tick(36,true)
local close=entity("closest-enemy"); close.distance=4; close.neutral=true
local far=entity("far-enemy"); far.distance=15
local hidden=entity("hidden-enemy"); hidden.distance=8; hidden.hidden=true
sim.target=car; sim.nearby={far,close,hidden}; tick(36,true)
check(command("kill",nil,"aim","npc").ok=="0","person-in-front request cannot attack the aimed vehicle")
local carQueue=#car.queued
check(command("kill",nil,"nearest_enemy","npc").ok=="1" and close.dead and not far.dead and #car.queued==carQueue,"generic kill chooses closest enemy even while aiming at vehicle")
check(command("scan").ok=="1","enemy scan command accepted")
check(sim.scanPulses and sim.scanPulses>0 and sim.scanRange==35,"scan uses the native network/scanner pulse")
tick(5,true); check(hidden.revealed and far.revealed,"scan outlines nearby enemies through walls without aiming")
local neutralScan=entity("scan-neutral"); neutralScan.neutral=true; neutralScan.crowd=true; neutralScan.civilian=true; neutralScan.hidden=true; neutralScan.distance=3
check(not neutralScan:CanBeTagged(),"vanilla civilian tagging remains blocked outside this mod's scan set")
sim.nearby[#sim.nearby+1]=neutralScan
local friendlyScan=entity("scan-friendly"); friendlyScan.friendly=true; friendlyScan.neutral=true; friendlyScan.distance=6
sim.nearby[#sim.nearby+1]=friendlyScan
tick(132,true)
local arriving=entity("arriving-hidden"); arriving.hidden=true; arriving.distance=9; sim.nearby[#sim.nearby+1]=arriving
tick(5,true)
check(snapshot().scan=="1" and arriving.revealed and hidden.revealed and neutralScan.revealed,"continuous scan includes hidden neutral civilians despite vanilla tagging exclusion")
check(friendlyScan.revealed,"scanner includes friendly neutral adults using scoped native tagging permission")
sim.menu=true; tick(1,true); check(not hidden.revealed and snapshot().scan=="1","menus clear owned scan tags without forgetting scan mode")
sim.menu=false; tick(5,true); check(hidden.revealed,"continuous scanning resumes after menus")
arriving.distance=100; tick(5,true); check(not arriving.revealed,"continuous scan clears owned tags after target leaves range")
check(command("scan_off").ok=="1" and not hidden.revealed and not far.revealed,"scan off releases owned outlines")
check(not neutralScan.revealed and not neutralScan:CanBeTagged(),"scan off restores civilian tagging policy and removes owned civilian tags")
check(not friendlyScan.revealed and not friendlyScan:CanBeTagged(),"scan off restores friendly tagging policy too")
local originalPulse=Targets.scanPulse; Targets.scanPulse=function() error("PulseScan unavailable") end
check(command("scan").ok=="1","optional scanner pulse failure does not disable protection-mode tagging")
tick(5,true); check(hidden.revealed,"native tags still work when scanner pulse is unavailable")
Targets.scanPulse=originalPulse; command("scan_off")
far.tagged=true; far.revealed=true; command("scan"); tick(8,true); command("scan_off")
check(far.tagged,"scan cleanup preserves player-preexisting scanner tags")
far.tagged=false; far.revealed=false; sim.scanningBlocked=true
local tagOk=pcall(Targets.highlight,far,player:GetEntityID())
check(not tagOk,"scanner restrictions are reported rather than claiming a tag")
sim.scanningBlocked=false
check(not NewObject("VehicleExplodeEvent") and NewObject("vehicleExplodeEvent"),"regression: REDscript alias absent while native RTTI constructor exists")
sim.nearby={}; sim.target=enemy4; tick(36,true)
local attacker=entity("attacker"); attacker.distance=5; attacker.hidden=true
local attacker2=entity("attacker-2"); attacker2.distance=8; attacker2.hidden=true
local bystander=entity("bystander"); bystander.distance=1; bystander.neutral=true
sim.nearby={attacker,attacker2,bystander}; sim.target=nil; sim.health=100; sim.combat=false
check(command("protect_on").ok=="1" and snapshot().protect=="1" and snapshot().chaos=="0","protect me is a target-free mode that disables chaos")
local protectApplied=sim.applied; tick(12,true)
check(sim.applied==protectApplied,"protect mode waits while V is unthreatened")
sim.health=30; tick(1,true)
check(sim.applied>protectApplied and next(attacker.effects)~=nil and next(bystander.effects)==nil,"protect mode uses control on hostile rather than nearer neutral NPC")
local protectedAt=sim.applied; tick(4,true)
check(sim.applied==protectedAt,"protection cannot spam between 1.5-second defensive opportunities")
tick(2,true)
check(sim.applied>protectedAt and next(attacker2.effects)~=nil,"protection hacks again after 1.5 seconds and spreads control to another hostile through walls")
check(attacker.revealed and attacker2.revealed and bystander.revealed,"protect scan includes neutral contacts while defense attacks only hostiles")
command("scan_off"); tick(5,true); check(not attacker.revealed and snapshot().scan=="0" and snapshot().protect=="1","stop scanning disables protection tags without stopping defense")
command("scan"); tick(5,true); check(attacker.revealed,"scan command resumes the same tagging while protection is running")
check(command("protect_off").ok=="1" and snapshot().protect=="0","protection off command")
tick(5,true); check(snapshot().scan=="1" and attacker.revealed,"explicit continuous scan remains independent when protection is turned off")
command("assist_off"); check(snapshot().scan=="0" and not attacker.revealed,"stand down stops both manual and protection scanning")
sim.nearby={}; sim.health=100; sim.combat=false
local before=sim.applied; tick(100,true); check(sim.applied==before,"stand down stops autonomous hacks")
check(command("assist_on").ok=="1","cover me command")
tick(100,false); local after=sim.applied; tick(100,false); check(sim.applied==after,"offline Capri cannot keep attacking")
command("chaos_on"); observers["PlayerPuppet.OnDetach"](); tick()
check(snapshot().chaos=="0","chaos is cleared by a session reset")
command("assist_off"); sim.nearby={}; sim.target=nil; sim.health=100
for i=1,7 do local npc=entity("batch"..i); npc.distance=i+2; sim.nearby[#sim.nearby+1]=npc end
sim.nearby[2].hidden=true; sim.nearby[3].hidden=true
tick(36,true)
local batchBefore=sim.applied
check(command("blind",nil,"nearby_group","npc",3).ok=="1" and sim.applied-batchBefore==3,"one command blinds three NPCs under a single cooldown")
local behind=entity("behind-player"); behind.distance=-4; sim.nearby[#sim.nearby+1]=behind
local front=Targets.group(player,35,"npc",true); local behindSeen=false
for _,contact in ipairs(front) do if contact.target==behind then behindSeen=true end end
check(not behindSeen and #front>0,"front group selection excludes an NPC behind V")
check(command("kill",nil,"nearby_group","npc",5).ok=="0","next batch obeys the shared cooldown")
tick(36,true)
check(command("stealth_on").ok=="1" and snapshot().stealth=="1","stealth mode enabled")
local killsBeforeStealth=sim.killed
check(command("kill",nil,"nearest_enemy","npc").ok=="0" and sim.killed==killsBeforeStealth,"stealth blocks explicit lethal requests")
check(command("emergency_on").ok=="1","emergency rescue armed")
sim.health=20; sim.rawHealth=40; sim.maxHealth=200; tick(4,true)
check(not sim.heals and sim.killed==killsBeforeStealth,"stealth suppresses lethal emergency and healing")
sim.health=40; sim.rawHealth=80
check(command("stealth_off").ok=="1","stealth off restores armed rescue")
tick(2,true)
check(not sim.heals and sim.killed==killsBeforeStealth,"80 raw HP at 40 percent does not trigger the 50-HP rescue")
sim.health=25; sim.rawHealth=50; tick(2,true)
check(not sim.heals,"exactly 50 raw HP does not trigger a strictly-below-50 rescue")
sim.health=24.5; sim.rawHealth=49; tick(2,true)
check(sim.killed-killsBeforeStealth==5 and sim.heals==1 and sim.rawHealth==149,"49 raw HP triggers up to five eliminations and a 100-HP heal")
sim.health=24.5; sim.rawHealth=49; tick(100,true)
check(sim.heals==1,"rescue cannot repeat during its 120-second cooldown")
observers["PlayerPuppet.OnDetach"](); tick(); command("emergency_on")
check(sim.heals==1,"save/session reset does not reset the rescue cooldown")
sim.time=sim.time+121; sim.maxHealth=80; sim.rawHealth=49; sim.health=61.25; tick(2,true)
check(sim.heals==2 and sim.rawHealth==80,"49 raw HP above 50 percent still triggers after cooldown and healing stays capped")
do local f=assert(io.open("emergency-cooldown.txt","r")); local saved=tonumber(f:read("*a")); f:close(); check(saved and math.abs(saved-os.time())<2,"rescue cooldown timestamp persisted for game restart") end
command("assist_off"); check(snapshot().emergency=="0","stand down disarms emergency rescue")
-- Custom programs: real protocol, composition, delayed work, healing and lifecycle.
local function freshProgram(id)
    command("assist_off"); sim.menu=false; sim.health=100; sim.rawHealth=nil; sim.combat=false
    local npc=entity("program-"..id); npc.hidden=true; sim.target=npc; sim.nearby={npc}; tick(36,true)
    return npc
end
local ghost=freshProgram("ghost")
check(command("ghost_veil").ok=="1" and ghost.effects["BaseStatusEffect.MemoryWipeLevel2"] and ghost.effects["BaseStatusEffect.Blind"],"Ghost Veil combines memory wipe and blindness through walls")
tick(33,true); check(next(ghost.effects)==nil,"all Ghost Veil components clean up after their duration")
local puppet=freshProgram("puppet")
check(command("marionette").ok=="1" and puppet.effects["BaseStatusEffect.Stun"] and puppet.effects["BaseStatusEffect.Blind"] and puppet.effects["BaseStatusEffect.WeaponMalfunctionSmartLock"],"Marionette Lock applies three distinct control effects")
local channel=freshProgram("channel")
check(command("dead_channel").ok=="1" and channel.effects["BaseStatusEffect.MemoryWipeLevel2"] and channel.effects["BaseStatusEffect.WeaponMalfunctionSmartLock"],"Dead Channel combines memory wipe and weapon lockout")
local drain=freshProgram("siphon"); sim.rawHealth=190; sim.maxHealth=200
local damageAt=sim.damage
check(command("siphon").ok=="1" and sim.damage-damageAt==20 and sim.siphonHeals==1 and sim.rawHealth==200,"Neural Siphon requests 20 percent target damage and 25 raw player HP capped by maximum")
local furnace=freshProgram("furnace"); damageAt=sim.damage
check(command("furnace").ok=="1" and furnace.effects["BaseStatusEffect.OverheatLevel4"] and furnace.effects["BaseStatusEffect.Stun"] and sim.damage-damageAt==30,"Furnace Lock burns and immobilizes with its own damage profile")
local breaker=freshProgram("breaker"); damageAt=sim.damage
check(command("circuit_breaker").ok=="1" and breaker.effects["BaseStatusEffect.WeaponMalfunctionSmartLock"] and sim.damage-damageAt==35,"Circuit Breaker shocks and jams")
local loop=freshProgram("loop"); damageAt=sim.damage
check(command("crash_loop").ok=="1" and sim.damage-damageAt==12,"Crash Loop begins with one electrical pulse")
tick(4,true); check(sim.damage-damageAt==12,"Crash Loop does not pulse every polling frame")
tick(4,true); check(sim.damage-damageAt==24,"Crash Loop sends its second pulse at two seconds")
tick(8,true); check(sim.damage-damageAt==36,"Crash Loop sends only three twelve-percent pulses total")
local cancelled=freshProgram("cancel-loop"); command("crash_loop"); command("assist_off"); damageAt=sim.damage; tick(24,true)
check(sim.damage==damageAt and next(cancelled.effects)==nil,"stand down cancels all future Crash Loop pulses and owned effects")
freshProgram("menu-loop"); command("crash_loop"); sim.menu=true; tick(1,true); damageAt=sim.damage; sim.menu=false; tick(24,true)
check(sim.damage==damageAt,"menus cancel future pulses rather than replaying them on return")
freshProgram("offline-loop"); command("crash_loop"); local currentSnapshot=snapshot()
write("client.txt",Core.pack({protocol="1",id="stale-custom",issued=os.time()-10,session=currentSnapshot.session},{"protocol","id","issued","session"}))
damageAt=sim.damage; tick(24,false); check(sim.damage==damageAt,"offline connection cancels pending pulses")
local reaper=freshProgram("reaper"); local deathAt=sim.killed
check(command("reaper_thread").ok=="1" and sim.killed==deathAt and reaper.effects["BaseStatusEffect.Stun"],"Reaper Thread starts with a stun, without claiming an immediate death")
tick(8,true); check(not reaper.dead,"Reaper Thread waits for its three-second execution delay")
tick(4,true); check(reaper.dead and sim.killed==deathAt+1,"Reaper Thread executes once at three seconds")
local escaped=freshProgram("escaped-reaper"); command("reaper_thread"); escaped.distance=100; tick(16,true)
check(not escaped.dead,"delayed execution rechecks range and eligibility")
local menuReaper=freshProgram("menu-reaper"); command("reaper_thread"); sim.menu=true; tick(16,true); sim.menu=false
check(not menuReaper.dead,"menus cancel Reaper execution")
local rejected=freshProgram("rollback"); sim.rejectRecord="BaseStatusEffect.Blind"; damageAt=sim.damage
check(command("ghost_veil").ok=="0" and next(rejected.effects)==nil and sim.damage==damageAt,"partially rejected combo rolls back only newly applied components")
sim.rejectRecord=nil
check(command("dead_channel").ok=="1","failed combo does not consume a successful-cast cooldown")
local foreign=freshProgram("foreign"); foreign.effects["BaseStatusEffect.Blind"]=true
check(command("ghost_veil").ok=="0" and foreign.effects["BaseStatusEffect.Blind"] and not foreign.effects["BaseStatusEffect.MemoryWipeLevel2"],"preexisting foreign effects prevent composition without being removed")
local absent=freshProgram("missing"); sim.missingRecords={["BaseStatusEffect.Blind"]=true}; local requestsAt=sim.applied
check(command("ghost_veil").ok=="0" and sim.applied==requestsAt and next(absent.effects)==nil,"missing component fails before any effect is applied")
sim.missingRecords=nil
freshProgram("stealth"); command("stealth_on")
check(command("reaper_thread").ok=="0" and command("siphon").ok=="0" and command("furnace").ok=="0","stealth refuses delayed lethal and damaging custom programs")
check(command("ghost_veil").ok=="1","stealth permits the quiet custom control program")
freshProgram("group"); sim.target=nil; sim.nearby={entity("custom-group1"),entity("custom-group2"),entity("custom-group3")}
local groupAt=sim.applied
check(command("marionette",nil,"nearby_group","npc",3).ok=="1" and sim.applied-groupAt==9,"one command applies a three-effect program to three NPCs under one cooldown")
check(command("ghost_veil",nil,"nearby_group","npc",3).ok=="0","next custom group obeys the ordinary shared cooldown")
freshProgram("wrong-kind"); sim.target=car
check(command("furnace").ok=="0","NPC program cannot accidentally explode or damage an aimed vehicle")

-- Actual-source counterhack routing and silent death hooks, driven through installed handlers.
command("assist_off"); sim.health=100; sim.combat=false; sim.menu=false
check(command("counter_on").ok=="1" and snapshot().counter=="1","target-free netrunner defense can be armed")
local runner=entity("counter-runner"); runner.hidden=true; runner.distance=150
local spare=entity("nearby-spare"); spare.distance=1
sim.nearby={spare}; sim.target=spare
local incoming=overrides["PlayerPuppet.OnHackTargetEvent"]
local vanillaHacks=0
local function pass() vanillaHacks=vanillaHacks+1; return true end
local attack={targetID=player:GetEntityID(),netrunnerID=runner:GetEntityID()}
local counterApplied=sim.applied
check(incoming(player,attack,pass)==false and runner.dead and not spare.dead and vanillaHacks==0,"incoming hack kills its exact source instantly through walls, without range or nearest-target substitution")
check(runner.killInstigator==nil and runner.skipDeath==true and runner.disableRagdoll==false and sim.applied==counterApplied,"retaliation is an unattributed body drop without damaging status effects or death animation")
local killsBefore=sim.killed
incoming(player,attack,pass); check(sim.killed==killsBefore,"duplicate hack callbacks do not kill twice")
local otherTarget=entity("other-hack-target"); local otherSource=entity("other-source")
incoming(player,{targetID=otherTarget:GetEntityID(),netrunnerID=otherSource:GetEntityID()},pass)
check(not otherSource.dead and vanillaHacks==1,"hacks against somebody other than V pass through unchanged")
local protected=entity("protected-runner"); protected.quest=true
incoming(player,{targetID=player:GetEntityID(),netrunnerID=protected:GetEntityID()},pass)
check(not protected.dead and vanillaHacks==2,"protected quest netrunner is not force-killed")
local broken=entity("broken-counter"); broken.Kill=function() error("fixture kill unavailable") end
local beforeBroken=vanillaHacks
incoming(player,{targetID=player:GetEntityID(),netrunnerID=broken:GetEntityID()},pass)
check(not broken.dead and vanillaHacks==beforeBroken+1,"failed native kill does not silently swallow unrelated original hack handler")
sim.menu=true; local menuRunner=entity("menu-runner")
incoming(player,{targetID=player:GetEntityID(),netrunnerID=menuRunner:GetEntityID()},pass)
check(not menuRunner.dead and vanillaHacks==beforeBroken+2,"menu state suspends retaliation")
sim.menu=false
local fear,squad,bodyRegistered=0,0,0
local incapacitate=overrides["NPCPuppet.OnIncapacitated"]
local fearHook=overrides["ReactionSystem.AddFearSource"]
local squadHook=overrides["AISquadHelper.NotifySquadOnIncapacitated;ScriptedPuppet"]
local function deathWork(npc)
    fearHook({}, {},25,nil,function() fear=fear+1 end)
    bodyRegistered=bodyRegistered+1
    squadHook(npc,function() squad=squad+1 end)
end
incapacitate(runner,function() deathWork(runner) end)
check(fear==0 and squad==0 and bodyRegistered==1 and runner.bodyVisible,"silent victim suppresses fear and remote squad alerts while retaining normal death work and discoverable corpse")
incapacitate(spare,function() deathWork(spare) end)
check(fear==1 and squad==1 and bodyRegistered==2,"unrelated deaths retain vanilla fear and squad notifications")
local bodyBroadcasts=0
local reactionHook=overrides["ReactionManagerComponent.OnIncapacitatedEvent"]
reactionHook({GetOwner=function() return runner end},{},function() bodyBroadcasts=bodyBroadcasts+1 end)
reactionHook({GetOwner=function() return spare end},{},function() bodyBroadcasts=bodyBroadcasts+1 end)
check(bodyBroadcasts==1,"only retaliated netrunner skips remote dying/illegal-action broadcasts")
pcall(incapacitate,runner,function() error("fixture death handler error") end)
fearHook({}, {},25,nil,function() fear=fear+1 end)
check(fear==2,"silent death scope unwinds after an error rather than disabling global fear")
local function uploadListener(npc,record,target)
    return {m_npcPuppet=npc,m_playerPuppet=target or player,
        m_action={GetObjectActionID=function() return record end},
        m_hudBlackboard={SetString=function() end,SetBool=function(self,name,value) self.active=value end},
        RemoveLink=function(self) self.linkRemoved=true end,
        RemoveLinkedStatusEffects=function(self,source,trace) self.linkedRemoved=true; self.trace=trace end}
end
local traceRunner=entity("tracing-runner"); traceRunner.neutral=true; traceRunner.hidden=true
local trace=uploadListener(traceRunner,"AIQuickHack.HackRevealPosition")
observers["UploadFromNPCToPlayerListener.Initialize"](trace)
check(traceRunner.dead,"trace initialization retaliates against its identified source even before its attitude turns hostile")
local completions=0; local complete=function() completions=completions+1 end
overrides["UploadFromNPCToPlayerListener.OnStatPoolValueChanged"](trace,10,20,1,complete)
check(completions==0 and trace.linkRemoved and trace.linkedRemoved and trace.trace and trace.m_hudBlackboard.active==false,"trace is interrupted and cleaned up without running the original progress/completion or starting combat")
check(sim.uploadRemoved and sim.uploadUnregistered and sim.uploadPool=="upload" and sim.saveLockRemoved and sim.preventionBarCleared and sim.beingRevealed==false,"trace cancellation releases upload pool listener HUD reveal state and save lock")
local removed=sim.uploadRemoved
overrides["UploadFromNPCToPlayerListener.OnStatPoolMaxValueReached"](trace,100,complete)
check(completions==0 and sim.uploadRemoved==removed,"late maximum-value callback cannot complete a cancelled trace or repeat cleanup")
local lateRunner=entity("late-tracer"); local lateTrace=uploadListener(lateRunner,"AIQuickHack.PreventionHackRevealPosition")
overrides["UploadFromNPCToPlayerListener.OnStatPoolMaxValueReached"](lateTrace,100,complete)
check(lateRunner.dead and completions==0 and lateTrace.trace,"already-running police trace is intercepted before its completion callback")
local uploadRunner=entity("damage-upload-runner"); local damageUpload=uploadListener(uploadRunner,"AIQuickHack.HackOverheat")
overrides["UploadFromNPCToPlayerListener.OnStatPoolValueChanged"](damageUpload,1,2,1,complete)
check(uploadRunner.dead and damageUpload.linkRemoved and damageUpload.trace==false and completions==0,"direct damaging uploads are cancelled too without treating them as position traces")
command("stealth_on"); local stealthRunner=entity("stealth-counter")
incoming(player,{targetID=player:GetEntityID(),netrunnerID=stealthRunner:GetEntityID()},pass)
check(stealthRunner.dead and snapshot().stealth=="1","explicit silent counter-retaliation remains armed during stealth without enabling other lethal hacks")
local npcListener=uploadListener(otherSource,"AIQuickHack.HackRevealPosition",otherTarget)
overrides["UploadFromNPCToPlayerListener.OnStatPoolValueChanged"](npcListener,1,2,1,complete)
check(not otherSource.dead and completions==1,"non-player listener passes to other mods and vanilla")
command("counter_off"); local disabled=entity("disabled-counter")
incoming(player,{targetID=player:GetEntityID(),netrunnerID=disabled:GetEntityID()},pass)
check(not disabled.dead and snapshot().counter=="0","explicit counterhack off disables retaliation")
command("counter_on"); command("assist_off")
check(snapshot().counter=="0","stand down disarms netrunner retaliation with other autonomous modes")
command("counter_on"); tick(16,false); local offline=entity("offline-counter")
incoming(player,{targetID=player:GetEntityID(),netrunnerID=offline:GetEntityID()},pass)
check(not offline.dead,"stale Capri connection cannot retaliate")
-- Long-session and cleanup regression checks.
command("assist_off"); sim.menu=false; sim.health=100; sim.target=nil
local cleanA,cleanB=entity("cleanup-A"),entity("cleanup-B"); sim.nearby={cleanA,cleanB}
tick(36,true); command("blind",nil,"nearby_group","npc",2)
sim.failCleanupId="cleanup-B"; sim.cleanupFailures=0; tick(30,true)
check(next(cleanA.effects)==nil,"one failing cleanup entry does not pin every later effect")
check(sim.cleanupFailures==3,"permanently failing cleanup gets a bounded retry budget")
tick(20,true); check(sim.cleanupFailures==3,"failed entry cannot grow work or retry forever")
sim.failCleanupId=nil; ses:RemoveStatusEffect(cleanB:GetEntityID(),"BaseStatusEffect.Blind")
command("assist_off"); sim.target=entity("session-cleanup"); sim.nearby={sim.target}; tick(36,true); command("blind")
local priorTarget=sim.target; player.id="V-replacement"; tick(1,true)
check(next(priorTarget.effects)==nil,"missed detach still cleans previous session's owned effects on player-ID change")
player.id="V"; sim.target=nil; sim.nearby={}; tick(1,true); command("assist_off"); command("scan")
local actualOpen=io.open; local leaseReads=0
io.open=function(path,mode) if path=="client.txt" and mode=="r" then leaseReads=leaseReads+1 end; return actualOpen(path,mode) end
tick(1,true); io.open=actualOpen
check(leaseReads==1,"one update shares one client-heartbeat read across all consumers")
command("assist_off")
for i=1,1100 do local npc=entity("long-session-"..i); observers["NPCPuppet.OnDeath"](npc,{instigator=player}) end
local function capture(fn,wanted)
    for i=1,100 do local name,value=debug.getupvalue(fn,i); if not name then break end; if name==wanted then return value end end
end
local dedup=capture(observers["NPCPuppet.OnDeath"],"seenKills"); local dedupCount=0
for _ in pairs(dedup) do dedupCount=dedupCount+1 end
check(dedupCount==1024,"long-session kill deduplication stays bounded after 1100 deaths")
local aggregate=snapshot().kills; tick(1,true); local beforeDuplicate=tonumber(snapshot().kills)
observers["NPCPuppet.OnDeath"](objects["long-session-1100"],{instigator=player}); tick(1,true)
check(tonumber(snapshot().kills)==beforeDuplicate,"bounded kill cache still rejects recent duplicate death callbacks")
events.onShutdown(); check(snapshot().ready=="0","shutdown marks bridge unavailable")
os.time=actualTime
print("PASS " .. checks .. " game-side mocked checks; no gameplay tested.")
