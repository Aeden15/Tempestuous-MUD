-- name: Intercession
-- regex: ^inter(?: (\w+))?(?: (\w+))?$
Tempest.send_pray_self_optional_target("intercession", matches[2], matches[3])
