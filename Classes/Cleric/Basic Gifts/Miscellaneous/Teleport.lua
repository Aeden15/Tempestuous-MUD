-- name: Teleport
-- regex: ^recall(?: (\w+))?(?: (\w+))?$
local first = matches[2]
local second = matches[3]
local target_name = "self"
local favors = nil

if first and first ~= "" then
  local maybe_favors = Tempest.normalize_favors(first, true)
  if maybe_favors then
    favors = maybe_favors
  else
    target_name = first
    favors = second
  end
end

Tempest.send_pray("celestialgrasp", target_name, favors)
