-- name: Rebuke
-- regex: ^reb(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("rebuke", tgt, matches[2])
