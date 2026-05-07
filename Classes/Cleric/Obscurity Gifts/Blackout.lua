-- name: Blackout
-- regex: ^black(?: (\w+))?(?: (\w+))?$
Tempest.send_pray_require_or_manual_target("blackout", matches[2], matches[3])
