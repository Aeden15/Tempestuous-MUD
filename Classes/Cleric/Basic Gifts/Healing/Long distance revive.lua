-- name: Long distance revive
-- regex: ^lrevive(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("liturgy:ghostwaverevive", tgt, matches[2])
