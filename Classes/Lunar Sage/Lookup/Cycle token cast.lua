-- name: Cycle token cast
-- regex: ^cy (\S+)(?: (.+))?$
Tempest.send_lunar_cycle(matches[2], matches[3])
