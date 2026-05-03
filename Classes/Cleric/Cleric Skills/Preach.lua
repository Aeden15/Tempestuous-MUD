-- name: Preach
-- regex: ^preach (\w+)(?: (.+))?$
local npc = matches[2]
local message = matches[3]
local cmd = "use preach " .. npc
if message and message ~= "" then
  cmd = cmd .. " " .. message
end
send(cmd)
