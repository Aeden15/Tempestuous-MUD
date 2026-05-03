-- name: Curative Efflux
-- regex: ^eff(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("curativeefflux", tgt, matches[2])
