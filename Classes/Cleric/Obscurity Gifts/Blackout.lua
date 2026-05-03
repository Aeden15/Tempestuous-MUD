-- name: Blackout
-- regex: ^black(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("blackout", tgt, matches[2])
