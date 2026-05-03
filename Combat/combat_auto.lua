-- Shared Tempest combat automation (all classes). Depends on Tempest.* from target.lua.



Tempest.auto_melee_active = Tempest.auto_melee_active or false

Tempest.posture_tier = Tempest.posture_tier or "mid"

Tempest.auto_attack_delay = Tempest.auto_attack_delay or 2.1

Tempest._auto_attack_timer_id = Tempest._auto_attack_timer_id or nil

-- True while server reports Knocked Down (posture line or knockdown message).

Tempest.knocked_down = Tempest.knocked_down or false

-- Set true when Posture trigger has fired at least once (see update_posture_from_line).

Tempest._posture_line_seen = Tempest._posture_line_seen or false

-- After queue clear + stand, cleared when posture line shows upright (no Knocked Down).
Tempest._kd_recovery_sent = Tempest._kd_recovery_sent or false


local function cancel_attack_timer()

  if Tempest._auto_attack_timer_id and killTimer then

    killTimer(Tempest._auto_attack_timer_id)

    Tempest._auto_attack_timer_id = nil

  end

end



--- Rank for merging: lower = safer (pound/slash), higher = heavier (smash/cleave).

local function _tier_to_rank(t)

  local x = tostring(t or ""):lower()

  if x == "safe" then

    return 1

  end

  if x == "mid" then

    return 2

  end

  if x == "heavy" then

    return 3

  end

  return 2

end



local function _rank_to_tier(r)

  if r <= 1 then

    return "safe"

  end

  if r <= 2 then

    return "mid"

  end

  return "heavy"

end



--- Same tier mapping as Tempest.send_melee("auto", ...): good→heavy, bad/critical→safe, else mid.

local function _risk_tier_from_band()

  local rb = tostring(Tempest.risk_band or "neutral"):lower()

  if rb == "good" then

    return "heavy"

  end

  if rb == "bad" or rb == "critical" then

    return "safe"

  end

  return "mid"

end



--- Merge posture tier with Risk band: use the safer (lower rank) of the two.

--- Until any posture line is seen, Risk alone drives tier (default posture is not real data).

function Tempest.auto_melee_merged_tier()

  local posture = Tempest.posture_tier or "mid"

  local risk = _risk_tier_from_band()

  if not Tempest._posture_line_seen then

    return risk, posture, risk

  end

  local m = math.min(_tier_to_rank(posture), _tier_to_rank(risk))

  return _rank_to_tier(m), posture, risk

end



--- Queue clear + stand once per knockdown; shared by message triggers and posture line.
local function knockdown_apply_recovery()

  Tempest.knocked_down = true

  Tempest.posture_tier = "safe"

  cancel_attack_timer()

  if not Tempest._kd_recovery_sent then

    Tempest._kd_recovery_sent = true

    send("queue clear")

    send("stand")

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

  -- Do not queue attacks from the client while prone; server queue + delays block stand.

  if Tempest.knocked_down then

    return

  end

  local tier = select(1, Tempest.auto_melee_merged_tier())

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

  Tempest._posture_line_seen = true

  local lower = line:lower()

  if lower:find("knocked down", 1, true) then

    knockdown_apply_recovery()

    return

  end

  Tempest.knocked_down = false

  Tempest._kd_recovery_sent = false

  if line:find("Feeble") or line:find("Very Weak") or line:find("Very Unsteady") then

    Tempest.posture_tier = "safe"

    if Tempest.auto_melee_active then

      Tempest.schedule_auto_attack()

    end

    return

  end

  if line:find("Unsteady") then

    Tempest.posture_tier = "safe"

    if Tempest.auto_melee_active then

      Tempest.schedule_auto_attack()

    end

    return

  end

  if line:find("Weak") and not line:find("Very Weak") then

    Tempest.posture_tier = "mid"

    if Tempest.auto_melee_active then

      Tempest.schedule_auto_attack()

    end

    return

  end

  if line:find("Neutral") then

    Tempest.posture_tier = "mid"

    if Tempest.auto_melee_active then

      Tempest.schedule_auto_attack()

    end

    return

  end

  if line:find("Good") or line:find("Strong") then

    Tempest.posture_tier = "heavy"

    if Tempest.auto_melee_active then

      Tempest.schedule_auto_attack()

    end

    return

  end

  if Tempest.auto_melee_active then

    Tempest.schedule_auto_attack()

  end

end



function Tempest.on_combat_line()

  if Tempest.auto_melee_active then

    return

  end

  Tempest.auto_melee_start(false)

end



function Tempest.on_knockdown()

  knockdown_apply_recovery()

end



--- Stops auto melee when the game says the current target is invalid (e.g. mob dead, wrong name).

function Tempest.on_invalid_target()

  if not Tempest.auto_melee_active then

    return

  end

  send("queue clear")

  Tempest.auto_melee_stop(false)

  cecho("<yellow>[Tempest Combat] Auto melee off: invalid target. Set target with tt.\n")

end



--- Call from a trigger on your game's stand-success line if posture updates lag behind.

function Tempest.note_stood_up()

  Tempest.knocked_down = false

  Tempest._kd_recovery_sent = false

  if Tempest.auto_melee_active then

    Tempest.schedule_auto_attack()

  end

end

