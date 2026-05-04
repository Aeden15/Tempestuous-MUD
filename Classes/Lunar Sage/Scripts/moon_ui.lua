Tempest = Tempest or {}

Tempest.lunar_ui = Tempest.lunar_ui or {
  enabled = false,
  amor_label = nil,
  honestus_label = nil,
}

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

function Tempest.lunar_ui_init()
  if have_labels() then
    return true
  end

  Tempest.lunar_ui.amor_label = Tempest.lunar_ui.amor_label or "tempest_lunar_ui_amor"
  Tempest.lunar_ui.honestus_label = Tempest.lunar_ui.honestus_label or "tempest_lunar_ui_honestus"

  createLabel(Tempest.lunar_ui.amor_label, 10, 10, 92, 32, 1)
  createLabel(Tempest.lunar_ui.honestus_label, 108, 10, 110, 32, 1)

  setLabelStyleSheet(
    Tempest.lunar_ui.amor_label,
    "background-color: rgba(245,245,245,0.25); border: 1px solid #d9d9d9; border-radius: 16px; color: #f4f4f4; padding-left: 8px;"
  )
  setLabelStyleSheet(
    Tempest.lunar_ui.honestus_label,
    "background-color: rgba(121,72,208,0.35); border: 1px solid #8f63dd; border-radius: 16px; color: #d6c2ff; padding-left: 8px;"
  )

  echo(Tempest.lunar_ui.amor_label, "Amor ●")
  echo(Tempest.lunar_ui.honestus_label, "Honestus ●")
  safe_hide(Tempest.lunar_ui.amor_label)
  safe_hide(Tempest.lunar_ui.honestus_label)
  return true
end

function Tempest.lunar_ui_show()
  Tempest.lunar_ui_init()
  Tempest.lunar_ui.enabled = true
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

function Tempest.lunar_ui_update_from_line(line)
  if not Tempest.lunar_ui.enabled or not have_labels() then
    return
  end

  local amor, honestus = parse_prompt_values(line or "")
  if amor then
    clearWindow(Tempest.lunar_ui.amor_label)
    echo(Tempest.lunar_ui.amor_label, string.format("Amor ● %d", amor))
  end
  if honestus then
    clearWindow(Tempest.lunar_ui.honestus_label)
    echo(Tempest.lunar_ui.honestus_label, string.format("Honestus ● %d", honestus))
  end
end
