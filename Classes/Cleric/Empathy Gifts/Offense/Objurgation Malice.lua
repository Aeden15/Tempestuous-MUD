-- name: Objurgation Malice
-- regex: ^objm(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("objurgation:malice", tgt, matches[2])
