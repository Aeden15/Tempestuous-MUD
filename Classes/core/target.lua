Tempest = Tempest or {}

Tempest.target = Tempest.target or ""
Tempest.risk_band = Tempest.risk_band or "neutral"
-- Preference when the wielded weapon supports both slashing and blunt (see weapon_can_*).
Tempest.weapon_line = Tempest.weapon_line or "blunt"
-- weapon_can_slash / weapon_can_blunt: nil until triggers fire or you wreset (see TempestCombat.xml).
Tempest.character_name = Tempest.character_name or ""
-- From "You can move Nft(Uunits)!"; optional cap for move_by_units (e.g. 1 when server allows one unit per command).
Tempest.move_feet_per_step = Tempest.move_feet_per_step or nil
Tempest.move_units_available = Tempest.move_units_available or nil
Tempest.move_max_units_per_move = Tempest.move_max_units_per_move or nil

function Tempest.set_character_name(name)
  Tempest.character_name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
  if Tempest.character_name ~= "" then
    cecho("<cyan>[Tempest] Character name set for self-checks: <white>" .. Tempest.character_name .. "\n")
  end
end

function Tempest.get_self_name()
  local n = Tempest.character_name or ""
  if n ~= "" then
    return n
  end
  if type(gmcp) == "table" and gmcp.Char and gmcp.Char.Name then
    return tostring(gmcp.Char.Name)
  end
  return ""
end

local function norm_lower(s)
  return tostring(s or ""):match("^%s*(.-)%s*$"):lower()
end

local function is_target_self(name)
  local self_name = Tempest.get_self_name()
  if self_name == "" or name == "" then
    return false
  end
  return norm_lower(name) == norm_lower(self_name)
end

function Tempest.set_weapon_line(line)
  local key = norm_lower(line)
  if key ~= "sharp" and key ~= "blunt" then
    cecho("<red>[Tempest] weapon_line must be sharp or blunt.\n")
    return false
  end
  Tempest.weapon_line = key
  return true
end

function Tempest.reset_weapon_capabilities()
  Tempest.weapon_can_slash = nil
  Tempest.weapon_can_blunt = nil
end

function Tempest.note_slashing_weapon(line)
  Tempest.weapon_can_slash = true
end

function Tempest.note_blunt_weapon(line)
  Tempest.weapon_can_blunt = true
end

--- Effective line for verb choice: single-style from probes, or weapon_line when both apply.
function Tempest.resolve_effective_weapon_line()
  local s = Tempest.weapon_can_slash
  local b = Tempest.weapon_can_blunt
  if s == true and b ~= true then
    return "sharp"
  end
  if b == true and s ~= true then
    return "blunt"
  end
  if s == true and b == true then
    return Tempest.weapon_line or "blunt"
  end
  return Tempest.weapon_line or "blunt"
end

function Tempest.melee_verb_for_tier(tier)
  local t = tostring(tier or ""):lower()
  local wl = Tempest.resolve_effective_weapon_line()
  if t == "safe" then
    return wl == "sharp" and "slash" or "pound"
  end
  if t == "mid" then
    return wl == "sharp" and "slice" or "crush"
  end
  if t == "heavy" then
    return wl == "sharp" and "cleave" or "smash"
  end
  return nil
end

--- Ranged attack style for fire: safe -> rapid, mid -> deftly, heavy -> precisely (see attackinfo / help fire).
function Tempest.ranged_verb_for_tier(tier)
  local t = tostring(tier or ""):lower()
  if t == "safe" then
    return "rapid"
  end
  if t == "mid" then
    return "deftly"
  end
  if t == "heavy" then
    return "precisely"
  end
  return nil
end

function Tempest.set_target(name)
  name = tostring(name or ""):match("^%s*(.-)%s*$")

  if name == "" then
    cecho("<red>[Tempest] No target supplied.\n")
    return false
  end

  Tempest.target = name

  -- Compatibility with older/simple aliases that may expect a global target.
  target = name

  cecho("<cyan>[Tempest] Target set: <white>" .. name .. "\n")
  return true
end

function Tempest.get_target()
  if Tempest.target and Tempest.target ~= "" then
    return Tempest.target
  end

  if target and target ~= "" then
    return target
  end

  return nil
end

function Tempest.require_target()
  local tgt = Tempest.get_target()

  if not tgt or tgt == "" then
    cecho("<red>[Tempest] No target set. Use: tt <name>\n")
    return nil
  end

  if is_target_self(tgt) then
    cecho("<red>[Tempest] Target is your character name; clear or change target with tt.\n")
    return nil
  end

  return tgt
end

function Tempest.normalize_favors(value, silent)
  local text = tostring(value or ""):match("^%s*(.-)%s*$"):lower()
  if text == "" then
    return nil
  end

  if text == "min" or text == "max" or text:match("^%d+$") then
    return text
  end

  if not silent then
    cecho("<red>[Tempest] Invalid favors value. Use: min, max, or a number.\n")
  end
  return nil
end

function Tempest.send_pray(gift, target_name, favors)
  local cmd = "pray " .. gift
  local target_text = tostring(target_name or ""):match("^%s*(.-)%s*$")
  if target_text ~= "" then
    cmd = cmd .. " " .. target_text
  end

  local favors_text = Tempest.normalize_favors(favors)
  if favors_text then
    cmd = cmd .. " " .. favors_text
  end

  send(cmd)
end

local function resolve_attack_target(explicit_target)
  local text = tostring(explicit_target or ""):match("^%s*(.-)%s*$")
  if text ~= "" then
    return text
  end
  return Tempest.get_target()
end

function Tempest.send_basic_attack(attack, explicit_target)
  local target_name = resolve_attack_target(explicit_target)
  if target_name and target_name ~= "" then
    if is_target_self(target_name) then
      cecho("<red>[Tempest] Refusing to attack yourself; fix target (tt) or character name (Tempest.set_character_name).\n")
      return false
    end
    send(attack .. " " .. target_name)
  else
    send(attack)
  end
  return true
end

--- Syntax: fire <rapid|deftly|precisely> <target> (game allows abbreviations; we send full words).
function Tempest.send_basic_ranged(verb, explicit_target)
  local v = tostring(verb or ""):match("^%s*(.-)%s*$")
  if v == "" then
    return false
  end
  local target_name = resolve_attack_target(explicit_target)
  if not target_name or target_name == "" then
    cecho("<red>[Tempest] Ranged fire needs a target (tt or second argument).\n")
    return false
  end
  if is_target_self(target_name) then
    cecho("<red>[Tempest] Refusing to fire on yourself; fix target (tt) or character name (Tempest.set_character_name).\n")
    return false
  end
  send("fire " .. v .. " " .. target_name)
  return true
end

function Tempest.set_risk_band(value)
  local band = tostring(value or ""):lower():match("^%s*(.-)%s*$")
  local valid = {
    good = true,
    neutral = true,
    bad = true,
    critical = true,
  }

  if not valid[band] then
    cecho("<red>[Tempest] Invalid risk band. Use: good, neutral, bad, critical.\n")
    return false
  end

  Tempest.risk_band = band
  cecho("<cyan>[Tempest] Risk band set: <white>" .. band .. "\n")
  return true
end

function Tempest.send_melee(kind, explicit_target)
  local key = tostring(kind or ""):lower()
  local tier = nil

  if key == "safe" then
    tier = "safe"
  elseif key == "mid" then
    tier = "mid"
  elseif key == "heavy" then
    tier = "heavy"
  elseif key == "auto" then
    if Tempest.risk_band == "good" then
      tier = "heavy"
    elseif Tempest.risk_band == "bad" or Tempest.risk_band == "critical" then
      tier = "safe"
    else
      tier = "mid"
    end
  else
    cecho("<red>[Tempest] Unknown melee mode. Use: safe, mid, heavy, auto.\n")
    return false
  end

  local attack = Tempest.melee_verb_for_tier(tier)
  if not attack then
    return false
  end

  Tempest.send_basic_attack(attack, explicit_target)
  return true
end

--- Same modes as send_melee: safe/mid/heavy/auto from Risk (parallel to melee tier mapping).
function Tempest.send_ranged(kind, explicit_target)
  local key = tostring(kind or ""):lower()
  local tier = nil

  if key == "safe" then
    tier = "safe"
  elseif key == "mid" then
    tier = "mid"
  elseif key == "heavy" then
    tier = "heavy"
  elseif key == "auto" then
    if Tempest.risk_band == "good" then
      tier = "heavy"
    elseif Tempest.risk_band == "bad" or Tempest.risk_band == "critical" then
      tier = "safe"
    else
      tier = "mid"
    end
  else
    cecho("<red>[Tempest] Unknown ranged mode. Use: safe, mid, heavy, auto.\n")
    return false
  end

  local verb = Tempest.ranged_verb_for_tier(tier)
  if not verb then
    return false
  end

  return Tempest.send_basic_ranged(verb, explicit_target)
end

--- Room positioning: move +/-<units> (1 unit = 5ft per help move). Honors Tempest.move_max_units_per_move when set.
function Tempest.move_by_units(delta)
  local n = tonumber(delta)
  if not n or n == 0 then
    cecho("<red>[Tempest] move_by_units needs a non-zero number (e.g. +1 or -2).\n")
    return false
  end
  local cap = tonumber(Tempest.move_max_units_per_move)
  if cap and cap > 0 and math.abs(n) > cap then
    n = n > 0 and cap or -cap
  end
  if n > 0 then
    send("move +" .. tostring(n))
  else
    send("move " .. tostring(n))
  end
  return true
end

--- move <target> — advance toward a denizen or player name.
function Tempest.move_towards(name)
  name = tostring(name or ""):match("^%s*(.-)%s*$") or ""
  if name == "" then
    cecho("<red>[Tempest] move_towards needs a target name.\n")
    return false
  end
  send("move " .. name)
  return true
end

--- Trigger helper: game line "You can move 5ft(1units)!". Pass feet and units from capture groups, or one full line string.
function Tempest.note_move_capability(a, b)
  local feet, units = a, b
  if b == nil and type(a) == "string" then
    feet, units = tostring(a):match("You can move (%d+)ft%((%d+)units%)")
  end
  feet = tonumber(feet)
  units = tonumber(units)
  if feet then
    Tempest.move_feet_per_step = feet
  end
  if units then
    Tempest.move_units_available = units
  end
end
