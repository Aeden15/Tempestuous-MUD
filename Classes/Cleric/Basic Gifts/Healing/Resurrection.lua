-- name: Resurrection
-- regex: ^rezz(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("restoration", tgt, matches[2])
