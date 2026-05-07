-- name: Rebuke
-- regex: ^reb(?: (\w+))?(?: (\w+))?$
Tempest.send_pray_require_or_manual_target("rebuke", matches[2], matches[3])
