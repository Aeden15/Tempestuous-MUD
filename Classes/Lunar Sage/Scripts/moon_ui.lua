Tempest = Tempest or {}

Tempest.lunar_ui = Tempest.lunar_ui or {
  enabled = false,
  amor_label = nil,
  honestus_label = nil,
}

local MOON = 58
local MOON_GAP = 10
local MOON_MARGIN = 14

local AMOR_MOON_CSS = [[
QLabel {
  background: qradialgradient(cx:0.32, cy:0.28, radius:0.95, fx:0.28, fy:0.24,
    stop:0 #ffffff, stop:0.35 #e6e6e6, stop:0.7 #a8a8a8, stop:1 #5c5c5c);
  border: 2px solid #b8b8b8;
  border-radius: 29px;
  color: #1a1a1a;
  font-size: 10px;
  font-weight: bold;
  padding: 2px;
  min-width: 58px;
  max-width: 58px;
  min-height: 58px;
  max-height: 58px;
}
]]

local HONESTUS_MOON_CSS = [[
QLabel {
  background: qradialgradient(cx:0.38, cy:0.30, radius:0.95, fx:0.32, fy:0.26,
    stop:0 #c9a8ff, stop:0.4 #7b4ec9, stop:0.75 #3d1f6e, stop:1 #1a0d33);
  border: 2px solid #9b6ee5;
  border-radius: 29px;
  color: #f0e8ff;
  font-size: 10px;
  font-weight: bold;
  padding: 2px;
  min-width: 58px;
  max-width: 58px;
  min-height: 58px;
  max-height: 58px;
}
]]

local function have_labels()
  return Tempest.lunar_ui.amor_label and Tempest.lunar_ui.honestus_label
end

local function safe_hide(label_name)
  if label_name then
    hideWindow(label_name)
  end
end

local function parse_prompt_values(line)
  local amor = tonumber((line or ""):match("Amor:%s*(-?%d+)"))
  local honestus = tonumber((line or ""):match("Honestus:%s*(-?%d+)"))
  return amor, honestus
end

function Tempest.lunar_ui_reposition()
  if not have_labels() or not getMainWindowSize then
    return
  end
  local w, h = getMainWindowSize()
  if not w or not h then
    return
  end
  local hx = w - MOON_MARGIN - MOON
  local hy = h - MOON_MARGIN - MOON
  local ax = hx - MOON_GAP - MOON
  moveWindow(Tempest.lunar_ui.amor_label, ax, hy)
  moveWindow(Tempest.lunar_ui.honestus_label, hx, hy)
end

function Tempest.lunar_ui_init()
  if have_labels() then
    Tempest.lunar_ui_reposition()
    return true
  end

  Tempest.lunar_ui.amor_label = Tempest.lunar_ui.amor_label or "tempest_lunar_ui_amor"
  Tempest.lunar_ui.honestus_label = Tempest.lunar_ui.honestus_label or "tempest_lunar_ui_honestus"

  createLabel(Tempest.lunar_ui.amor_label, 0, 0, MOON, MOON, 1)
  createLabel(Tempest.lunar_ui.honestus_label, 0, 0, MOON, MOON, 1)

  setLabelStyleSheet(Tempest.lunar_ui.amor_label, AMOR_MOON_CSS)
  setLabelStyleSheet(Tempest.lunar_ui.honestus_label, HONESTUS_MOON_CSS)

  echo(Tempest.lunar_ui.amor_label, "Amor\n—")
  echo(Tempest.lunar_ui.honestus_label, "Honestus\n—")
  Tempest.lunar_ui_reposition()
  safe_hide(Tempest.lunar_ui.amor_label)
  safe_hide(Tempest.lunar_ui.honestus_label)

  if not Tempest._lunar_ui_resize_hooked and registerAnonymousEventHandler then
    Tempest._lunar_ui_resize_hooked = true
    registerAnonymousEventHandler("sysWindowResize", "Tempest.lunar_ui_reposition")
  end

  return true
end

function Tempest.lunar_ui_show()
  Tempest.lunar_ui_init()
  Tempest.lunar_ui.enabled = true
  Tempest.lunar_ui_reposition()
  showWindow(Tempest.lunar_ui.amor_label)
  showWindow(Tempest.lunar_ui.honestus_label)
end

function Tempest.lunar_ui_hide()
  Tempest.lunar_ui.enabled = false
  safe_hide(Tempest.lunar_ui.amor_label)
  safe_hide(Tempest.lunar_ui.honestus_label)
end

function Tempest.lunar_ui_toggle()
  if Tempest.lunar_ui.enabled then
    Tempest.lunar_ui_hide()
  else
    Tempest.lunar_ui_show()
  end
end

function Tempest.lunar_ui_set_amor(n)
  if not Tempest.lunar_ui.enabled or not have_labels() then
    return
  end
  local v = tonumber(n)
  if not v then
    return
  end
  clearWindow(Tempest.lunar_ui.amor_label)
  echo(Tempest.lunar_ui.amor_label, string.format("Amor\n%d", v))
end

function Tempest.lunar_ui_set_honestus(n)
  if not Tempest.lunar_ui.enabled or not have_labels() then
    return
  end
  local v = tonumber(n)
  if not v then
    return
  end
  clearWindow(Tempest.lunar_ui.honestus_label)
  echo(Tempest.lunar_ui.honestus_label, string.format("Honestus\n%d", v))
end

function Tempest.lunar_ui_update_from_line(line)
  if not Tempest.lunar_ui.enabled or not have_labels() then
    return
  end

  local amor, honestus = parse_prompt_values(line or "")
  if amor then
    Tempest.lunar_ui_set_amor(amor)
  end
  if honestus then
    Tempest.lunar_ui_set_honestus(honestus)
  end
end
