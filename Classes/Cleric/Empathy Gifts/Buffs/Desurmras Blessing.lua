-- name: Desurmras Blessing
-- regex: ^desur(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("desurmrasblessing", tgt, matches[2])
