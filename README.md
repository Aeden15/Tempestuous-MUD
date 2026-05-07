# Tempest Mudlet packages

This repo holds Mudlet packages for **Tempest Season** ([tempestseason.com](https://www.tempestseason.com)).

### Scope (do not mix codebases)

- **This repository targets only Tempest Season.** Lua, XML, triggers, and aliases assume Tempest’s commands, manual, and combat model.
- **Other Mudlet projects** (for example separate curing or offense frameworks built for a different MUD) live in **other repositories** and are **not** dependencies of Tempest. Do not copy Tempest packages into those repos as “the same system,” and do not assume shared globals or load order between them.
- **Mudlet profiles:** For different games, use **separate profiles** (or clearly separate package sets) so triggers and `Tempest.*` APIs are not loaded alongside unrelated packages unless you intend to debug conflicts.

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

**Maintainers:** Class packages (for example Cleric) call `Tempest.*` defined in `target.lua`. If you add or change functions there, run the command above and **commit the updated `TempestCombat.xml`** before publishing; otherwise imports that load Combat first will miss the new API and aliases can error at runtime.

Import **`Combat/TempestCombat.xml`** via Mudlet Package Manager (or zip as `.mpackage` if you use that workflow).

### 2. Cleric (class-specific aliases only)

- **Alias source of truth:** `Classes/Cleric/**/*.lua`
- **Generated package XML:** [`Classes/Cleric/Cleric.xml`](Classes/Cleric/Cleric.xml)
- **Uploadable archive:** `Classes/Cleric/Cleric.mpackage` (when built)

All Cleric aliases are embedded in `Cleric.xml` under `AliasPackage` → `Cleric`. **Combat triggers and the shared `Tempest` API live only in Tempest Combat** — not in Cleric.

**Buff-style prayers** (Alacrity, Aura, Protection, Rejuvenation, Vitality, Self rez, Intercession, Alleviation, Obcursion) resolve the pray target in two ways: with no manual name they use **`tt`** / `Tempest.get_target()` if set, otherwise **`self`**; add a first word that is not `min`, `max`, or digits to cast on that **denizen name** for one line only (`tt` unchanged). Optional second word is favors (`min` / `max` / number). If `tt` points at a mob but you want **yourself**, use an explicit name: e.g. **`alac self`** or **`alac self max`**. Words `min`, `max`, or all-digit names cannot be used as the first-token manual target (they are read as favors when alone).

**Celestial grasp** (`recall`) is **self-only** in these aliases: optional word is favors only.

### 3. Lunar Sage (class package: cycle/incantations + ranged safeguards)

- **Alias source of truth:** `Classes/Lunar Sage/**/*.lua` (one alias file per command).
- **Generated package XML:** [`Classes/Lunar Sage/LunarSage.xml`](Classes/Lunar%20Sage/LunarSage.xml)
- **XML build script:** [`Classes/Lunar Sage/build-lunarsage-xml.cjs`](Classes/Lunar%20Sage/build-lunarsage-xml.cjs)
- **Support scripts embedded in XML:** [`Classes/Lunar Sage/Scripts/lunar_helpers.lua`](Classes/Lunar%20Sage/Scripts/lunar_helpers.lua), [`Classes/Lunar Sage/Scripts/moon_ui.lua`](Classes/Lunar%20Sage/Scripts/moon_ui.lua)

Lunar Sage uses `syzygies` (lookup/list) and `cycle` (cast), plus `use lunarincantations ...` for harmonics/lord/energy/view. The class package also ships auto-melee safety triggers for ranged-only lunar cores.

### Install order

1. Import **Tempest Combat** first (defines `Tempest.*`, triggers, `tt`, melee/ranged/move helpers, auto-melee).
2. Import **Cleric** and/or **Lunar Sage** class packages (they call `Tempest.*` from Tempest Combat).

Class packages assume **Tempest Combat** is already installed; they do not embed `target helper`.

## Lunar Sage quick notes

- **Manual URL:** [tempestseason.com/manual/classes/lunar-sages/](https://tempestseason.com/manual/classes/lunar-sages/) (Cloudflare-protected; use a normal browser or Cursor browser MCP).
- **`syzygies [name]`:** lists cycle-cast spells.
- **`cycle <token> [optional target/args]`:** casts a syzygy token (`cycle novara` is verified for Nova Ray).
- **Incantations:** use `use lunarincantations ...` (`harmonics`, `lord`, `empower`, `flow`, `siphon`, `view`).
- **Lunar cores combat path:** use Tempest Combat ranged aliases (`frap`, `fdeft`, `fprec`, `fauto`) and movement (`mv`, `mvt`).
- **Lunar cores + auto-combat:** triggers set ranged-only mode when your weapon is lunar cores (inspect lines) or when melee is rejected (`You cannot use this type of weapon to perform a melee attack!`). With **Tempest Combat** `acon` on, auto-combat continues using **`fire`** (same tier logic as melee), not melee verbs.
- **Optional moon UI:** `lmoonon` / `lmoonoff` / `lmoon` for a decorative two-moon HUD (Amor white, Honestus violet), with prompt-driven updates from `Amor:` / `Honestus:` lines.

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
| `acoff`  | Stop auto combat loop (melee or ranged)     |
| `acon`   | Start auto combat (melee or ranged)        |
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

The combat package also reacts to retreat stumble knockdown, `You can't use this command while laying.`, and `You stand up.` (clears prone state for auto-melee). If you still see `[ … Second Delay ]` or “Placing the command in the queue…”, those strings are **not** emitted by this repo’s Lua; search other Mudlet aliases, keys, or **packages from other games/toolchains** in your profile.

## Canonical paths

| Role              | Path                          |
|-------------------|-------------------------------|
| Target + melee API | `Classes/core/target.lua`    |
| Combat automation | `Combat/combat_auto.lua`      |
| Cleric aliases    | `Classes/Cleric/**/*.lua`     |
| Lunar Sage aliases | `Classes/Lunar Sage/**/*.lua` |

## Quick validation

1. Parse `Combat/TempestCombat.xml`, `Classes/Cleric/Cleric.xml`, and `Classes/Lunar Sage/LunarSage.xml` as XML.
2. Import packages in Mudlet.
3. Verify `tt`, `wsharp` / `wblunt` / `wreset`, `setname`, `acoff` / `acon`, and that examining a weapon fires the slashing/blunt triggers.
4. On Lunar Sage: verify `szy`, `nr`, `liha`, `liv`, `lmoon`, and that lunar cores / melee-invalid lines switch auto-combat to **ranged** when `acon` is on.

## References

- Mudlet scripting: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Scripting)
- Mudlet package format: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Technical_Manual)
- Lua: [Lua PIL](https://www.lua.org/pil/contents.html)
- Combat / risk: [tempestseason.com/manual/combat/](https://tempestseason.com/manual/combat/)
