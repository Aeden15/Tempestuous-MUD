# Tempest Mudlet packages

This repo holds Mudlet packages for **Tempest Season** ([tempestseason.com](https://www.tempestseason.com)).

## Packages

### 1. Tempest Combat (shared — all classes)

- **Source:** [`Combat/combat_auto.lua`](Combat/combat_auto.lua), [`Classes/core/target.lua`](Classes/core/target.lua)
- **Generated Mudlet XML:** [`Combat/TempestCombat.xml`](Combat/TempestCombat.xml)
- **Contains:** Target helper (`tt`, self-target guard, melee and ranged `fire` mapping, move helpers), optional GMCP character name, denizen combat automation, triggers for weapon probes, knockdown/posture/move lines, aliases `acoff` / `acon`, `wsharp` / `wblunt`, `wreset`, `setname <name>`, `frap` / `fdeft` / `fprec` / `fauto`, `mv`, `mvt`.

Regenerate XML after editing Lua:

```bash
node Combat/build-combat-xml.cjs
```

That script embeds `target.lua` and `combat_auto.lua` inside **CDATA** in `TempestCombat.xml` (so Lua comments with `<…>` cannot break XML).

Import **`Combat/TempestCombat.xml`** via Mudlet Package Manager (or zip as `.mpackage` if you use that workflow).

### 2. Cleric (class-specific aliases only)

- **Alias source of truth:** `Classes/Cleric/**/*.lua`
- **Generated package XML:** [`Classes/Cleric/Cleric.xml`](Classes/Cleric/Cleric.xml)
- **Uploadable archive:** `Classes/Cleric/Cleric.mpackage` (when built)

All Cleric aliases are embedded in `Cleric.xml` under `AliasPackage` → `Cleric`. **Combat triggers and the shared `Tempest` API live only in Tempest Combat** — not in Cleric.

### Install order

1. Import **Tempest Combat** first (defines `Tempest.*`, triggers, `tt`, melee/ranged/move helpers, auto-melee).
2. Import **Cleric** (or any other class package that calls `Tempest.*`).

Class packages assume **Tempest Combat** is already installed; they do not embed `target helper`.

## Target helper and `tt`

- Target alias: **`tt <name>`** → `Tempest.set_target`.
- On Tempest, avoid using the stock **`t`** prefix for targeting if your game binds `t` to another command (e.g. item tagging); use **`tt`** for this package.

## Self-target guard

Set your character name once per profile (helps block `slash Yourname` mistakes):

- **`setname Darale`** (example), or rely on **GMCP** `Char.Name` if your game fills it.

## Weapon styles (`wsharp` / `wblunt`)

Tempest item text often includes lines such as **This is a slashing weapon.** and **This is a blunt weapon.** (a morning star can show both). The combat package **sets flags from those lines** so `send_melee` and auto-combat use the right attack family.

- **Only one line appears** (e.g. pure slashing): that style is used automatically; `wsharp` / `wblunt` are ignored.
- **Both lines appear:** use **`wsharp`** to prefer slash / slice / cleave, or **`wblunt`** to prefer pound / crush / smash (default is blunt if you never set a preference).
- After **changing weapons**, run **`wreset`** then **probe / examine** the new weapon so the old style flags are cleared and the new lines can register.

## Combat automation quick reference

| Alias    | Action                                      |
|----------|---------------------------------------------|
| `acoff`  | Stop auto melee loop                        |
| `acon`   | Start auto melee                            |
| `wsharp` | Prefer sharp verbs when weapon allows both  |
| `wblunt` | Prefer blunt verbs when weapon allows both  |
| `wreset` | Clear slashing/blunt flags (e.g. after swap) |

Adjust delay (seconds): `Tempest.auto_attack_delay = 2.1` in a script after load.

## Ranged `fire` (same risk tiers as melee)

- **Lua:** `Tempest.send_ranged("safe"|"mid"|"heavy"|"auto", target)` → sends `fire rapid|deftly|precisely <target>` (auto uses `Tempest.risk_band` like `send_melee`).
- **Lower level:** `Tempest.send_basic_ranged("rapid"|"deftly"|"precisely", target)` or abbreviations the game accepts (e.g. `r`).
- **Aliases:** `frap <target>`, `fdeft <target>`, `fprec <target>`, `fauto <target>`.

## Move (help move)

- **Lua:** `Tempest.move_by_units(n)` → `move +n` / `move -n` (optional `Tempest.move_max_units_per_move` to clamp before send, e.g. `1` when the game only allows one unit per command).
- **Lua:** `Tempest.move_towards("denizen")` → `move <name>`.
- **Aliases:** `mv +1`, `mv -2`, `mvt <name>`.
- **Trigger:** Lines like `You can move 5ft(1units)!` call `Tempest.note_move_capability` (sets `Tempest.move_feet_per_step` and `Tempest.move_units_available`).

## Knockdown / prone lines (combat package triggers)

The combat package also reacts to retreat stumble knockdown, `You can't use this command while laying.`, and `You stand up.` (clears prone state for auto-melee). If you still see `[ … Second Delay ]` or “Placing the command in the queue…”, those strings are **not** emitted by this repo’s Lua; search other Mudlet aliases, keys, or packages in your profile.

## Canonical paths

| Role              | Path                          |
|-------------------|-------------------------------|
| Target + melee API | `Classes/core/target.lua`    |
| Combat automation | `Combat/combat_auto.lua`      |
| Cleric aliases    | `Classes/Cleric/**/*.lua`     |

## Quick validation

1. Parse `Combat/TempestCombat.xml` and `Classes/Cleric/Cleric.xml` as XML.
2. Import packages in Mudlet.
3. Verify `tt`, `wsharp` / `wblunt` / `wreset`, `setname`, `acoff` / `acon`, and that examining a weapon fires the slashing/blunt triggers.

## References

- Mudlet scripting: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Scripting)
- Mudlet package format: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Technical_Manual)
- Lua: [Lua PIL](https://www.lua.org/pil/contents.html)
- Combat / risk: [tempestseason.com/manual/combat/](https://tempestseason.com/manual/combat/)
