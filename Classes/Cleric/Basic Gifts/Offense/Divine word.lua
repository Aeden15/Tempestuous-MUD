-- name: Divine word
-- regex: ^dword(?: (\w+))?$
local tgt = Tempest.require_target()
if not tgt then return end
Tempest.send_pray("divineword", tgt, matches[2])
