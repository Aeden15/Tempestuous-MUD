-- name: Last Rites
-- regex: ^rites(?: (\w+))?$
local tgt = matches[2]
if not tgt or tgt == "" then
  tgt = Tempest.require_target()
  if not tgt then return end
end
send("use lastrites " .. tgt)
