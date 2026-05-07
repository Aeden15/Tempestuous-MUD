-- name: Divine word
-- regex: ^dword(?: (\w+))?(?: (\w+))?$
Tempest.send_pray_require_or_manual_target("divineword", matches[2], matches[3])
