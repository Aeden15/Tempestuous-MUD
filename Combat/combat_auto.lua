-- Shared Tempest combat automation (all classes). Depends on Tempest.* from target.lua.

Tempest.auto_melee_active = Tempest.auto_melee_active or false
Tempest.posture_tier = Tempest.posture_tier or "mid"
Tempest.auto_attack_delay = Tempest.auto_attack_delay or 2.1
Tempest._auto_attack_timer_id = Tempest._auto_attack_timer_id or nil

local function cancel_attack_timer()
  if Tempest._auto_attack_timer_id and killTimer then
    killTimer(Tempest._auto_attack_timer_id)
    Tempest._auto_attack_timer_id = nil
  end
end

function Tempest.auto_melee_stop(message)
  Tempest.auto_melee_active = false
  cancel_attack_timer()
  if message ~= false then
    cecho("<yellow>[Tempest Combat] Auto melee off.\n")
  end
end

function Tempest.auto_melee_start(message)
  Tempest.auto_melee_active = true
  if message ~= false then
    cecho("<green>[Tempest Combat] Auto melee on.\n")
  end
  Tempest.auto_attack_once()
end

function Tempest.schedule_auto_attack()
  cancel_attack_timer()
  if not Tempest.auto_melee_active then
    return
  end
  local delay = tonumber(Tempest.auto_attack_delay) or 2.1
  if tempTimer then
    Tempest._auto_attack_timer_id = tempTimer(delay, function()
      Tempest.auto_attack_once()
    end)
  end
end

function Tempest.auto_attack_once()
  if not Tempest.auto_melee_active then
    return
  end
  local tier = Tempest.posture_tier or "mid"
  local attack = Tempest.melee_verb_for_tier(tier)
  if not attack then
    Tempest.schedule_auto_attack()
    return
  end
  Tempest.send_basic_attack(attack, nil)
  Tempest.schedule_auto_attack()
end

--- Map posture text from game output to melee tier: safe | mid | heavy
function Tempest.update_posture_from_line(line)
  line = tostring(line or "")
  if line:find("Knocked Down") then
    Tempest.posture_tier = "safe"
    return
  end
  if line:find("Very Weak") or line:find("Very Unsteady") then
    Tempest.posture_tier = "safe"
    return
  end
  if line:find("Unsteady") then
    Tempest.posture_tier = "safe"
    return
  end
  if line:find("Weak") and not line:find("Very Weak") then
    Tempest.posture_tier = "mid"
    return
  end
  if line:find("Neutral") then
    Tempest.posture_tier = "mid"
    return
  end
  if line:find("Good") or line:find("Strong") then
    Tempest.posture_tier = "heavy"
    return
  end
end

function Tempest.on_combat_line()
  if Tempest.auto_melee_active then
    return
  end
  Tempest.auto_melee_start(false)
end

function Tempest.on_knockdown()
  send("stand")
end
