-- name: Self rez
-- regex: ^srezz(?: (\w+))?(?: (\w+))?$
Tempest.send_pray_self_optional_target("awakening", matches[2], matches[3])
