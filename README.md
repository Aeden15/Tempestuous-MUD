# Tempest Mudlet packages

This repo holds Mudlet packages for **Tempest Season** ([tempestseason.com](https://www.tempestseason.com)).

## Packages

### 1. Tempest Combat (shared — all classes)

- **Source:** [`Combat/combat_auto.lua`](Combat/combat_auto.lua), [`Classes/core/target.lua`](Classes/core/target.lua)
- **Generated Mudlet XML:** [`Combat/TempestCombat.xml`](Combat/TempestCombat.xml)
- **Contains:** Target helper (`tt`, self-target guard, melee mapping), optional GMCP character name, denizen combat automation, triggers for `This is a slashing weapon.` / `This is a blunt weapon.`, aliases `acoff` / `acon`, `wsharp` / `wblunt`, `wreset`, `setname <name>`.

Regenerate XML after editing Lua:

```bash
node Combat/build-combat-xml.cjs
```

That script also syncs [`Classes/core/target.lua`](Classes/core/target.lua) into the Cleric package’s embedded `target helper` script.

Import **`Combat/TempestCombat.xml`** via Mudlet Package Manager (or zip as `.mpackage` if you use that workflow).

### 2. Cleric (class-specific aliases only)

- **Alias source of truth:** `Classes/Cleric/**/*.lua`
- **Generated package XML:** [`Classes/Cleric/Cleric.xml`](Classes/Cleric/Cleric.xml)
- **Uploadable archive:** `Classes/Cleric/Cleric.mpackage` (when built)

All Cleric aliases are embedded in `Cleric.xml` under `AliasPackage` → `Cleric`. **Combat triggers do not live here** — use Tempest Combat.

### Install order

1. Import **Tempest Combat** (or ensure [`Classes/core/target.lua`](Classes/core/target.lua) is loaded once).
2. Import **Cleric** (or your future class package).

If both embed `target helper`, Mudlet runs both scripts; definitions should match if you keep running `node Combat/build-combat-xml.cjs` after editing `target.lua`.

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
