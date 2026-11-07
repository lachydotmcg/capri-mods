-- Capri-designed programs composed from native effects and bridge-controlled mechanics.
local Programs={}
Programs.definitions={
    ghost_veil={name="Ghost Veil",records={"BaseStatusEffect.MemoryWipeLevel2","BaseStatusEffect.Blind"},seconds=8,quiet=true},
    marionette={name="Marionette Lock",records={"BaseStatusEffect.Stun","BaseStatusEffect.Blind","BaseStatusEffect.WeaponMalfunctionSmartLock"},seconds=6,quiet=true},
    dead_channel={name="Dead Channel",records={"BaseStatusEffect.MemoryWipeLevel2","BaseStatusEffect.WeaponMalfunctionSmartLock"},seconds=8,quiet=true},
    siphon={name="Neural Siphon",record="BaseStatusEffect.Electrocuted",seconds=3,damage=20,heal=25},
    furnace={name="Furnace Lock",records={"BaseStatusEffect.OverheatLevel4","BaseStatusEffect.Stun"},seconds=6,damage=30},
    circuit_breaker={name="Circuit Breaker",records={"BaseStatusEffect.Electrocuted","BaseStatusEffect.WeaponMalfunctionSmartLock"},seconds=6,damage=35},
    crash_loop={name="Crash Loop",records={"BaseStatusEffect.Electrocuted","BaseStatusEffect.WeaponMalfunctionSmartLock"},seconds=6,damage=12,pulses=2,pulseInterval=2},
    reaper_thread={name="Reaper Thread",record="BaseStatusEffect.Stun",seconds=3,executeAfter=3}
}
function Programs.records(effect) return effect.records or {effect.record} end
function Programs.available(effect,system,target)
    for _,name in ipairs(Programs.records(effect)) do
        if not TweakDB:GetRecord(name) or system:HasStatusEffect(target:GetEntityID(),TweakDBID.new(name)) then return false end
    end
    return true
end
function Programs.apply(effect,system,target,player)
    -- Preflight the whole program. Never overwrite/remove another hack's existing effects.
    if not Programs.available(effect,system,target) then return nil,"A required effect is missing or already active; no program uploaded." end
    local applied={}
    for _,name in ipairs(Programs.records(effect)) do
        local record=TweakDBID.new(name)
        local ok,result=pcall(function() return system:ApplyStatusEffect(target:GetEntityID(),record,TweakDBID.new(),player:GetEntityID()) end)
        if not ok or not result then
            for _,owned in ipairs(applied) do pcall(function() system:RemoveStatusEffect(target:GetEntityID(),owned) end) end
            return nil,"The game rejected part of the program; newly applied effects were rolled back."
        end
        applied[#applied+1]=record
    end
    return applied
end
return Programs
