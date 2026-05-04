Tempest = Tempest or {}

Tempest.lunar_cores_ranged_only = Tempest.lunar_cores_ranged_only or false

local function trim(text)
  return tostring(text or ""):match("^%s*(.-)%s*$")
end

function Tempest.send_lunar_cycle(token, extra)
  local spell = trim(token)
  if spell == "" then
    cecho("<red>[Tempest] Missing cycle token.\n")
    return false
  end

  local cmd = "cycle " .. spell
  local suffix = trim(extra)
  if suffix ~= "" then
    cmd = cmd .. " " .. suffix
  end

  send(cmd)
  return true
end

function Tempest.send_syzygies_lookup(filter_text)
  local cmd = "syzygies"
  local filter = trim(filter_text)
  if filter ~= "" then
    cmd = cmd .. " " .. filter
  end

  send(cmd)
  return true
end

function Tempest.send_lunar_incantation(path, args)
  local incant = trim(path)
  if incant == "" then
    cecho("<red>[Tempest] Missing lunar incantation path.\n")
    return false
  end

  local cmd = "use lunarincantations " .. incant
  local suffix = trim(args)
  if suffix ~= "" then
    cmd = cmd .. " " .. suffix
  end

  send(cmd)
  return true
end

function Tempest.on_lunar_cores_detected()
  Tempest.lunar_cores_ranged_only = true
  if Tempest.auto_melee_stop and Tempest.auto_melee_active then
    Tempest.auto_melee_stop()
  end
end

function Tempest.on_lunar_melee_invalid()
  Tempest.lunar_cores_ranged_only = true
  if Tempest.auto_melee_stop then
    Tempest.auto_melee_stop()
  end
end
