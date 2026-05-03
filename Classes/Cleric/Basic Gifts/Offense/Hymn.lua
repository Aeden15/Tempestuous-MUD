-- name: Hymn
-- regex: ^hymn(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("hymnoftheinferno", tgt, matches[2])
