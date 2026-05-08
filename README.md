# Tempest (Mudlet package)

This repo holds a **single** Mudlet package for **Tempest Season** ([tempestseason.com](https://www.tempestseason.com)): one source file, one import.

## Source of truth

| File | Role |
|------|------|
| [`Tempest.xml`](Tempest.xml) | Triggers, aliases, and all Lua (combat, target helper, Cleric, Lunar Sage). **Edit this file** (or export from Mudlet and replace this file). |
| [`config.lua`](config.lua) | Mudlet package metadata (`mpackage`, description, version). Keep alongside `Tempest.xml` when building an `.mpackage`. |

## Install (Mudlet 4.20)

1. **Quick:** Drag [`Tempest.xml`](Tempest.xml) onto Mudlet, or run `installPackage([[full/path/to/Tempest.xml]])`.
2. **Shareable archive:** Zip **`Tempest.xml` + `config.lua`** together and rename the zip to **`Tempest.mpackage`** (Mudlet expects `config.lua` at the zip root). The built **`Tempest.mpackage`** is gitignored so accidental binary churn stays out of git.

### Scope (do not mix codebases)

- **Tempest Season only.** Lua assumes Tempest commands and mechanics.
- Use **separate Mudlet profiles** (or package sets) if you use automation for other games so globals like `Tem.*` do not collide.

## Lua namespace (`Tem`)

Aliases and triggers call functions on the **`Tem`** table (short names). User-visible `cecho` lines still say **`[Tempest]`** / **`[Tempest Combat]`** for branding.

| Lua | Purpose |
|-----|---------|
| `Tem.settgt(name)` | Set alias target (`tt` → also sets legacy global `target`). |
| `Tem.gettgt()` / `Tem.reqtgt()` | Read target; `reqtgt` errors if unset or self-name. |
| `Tem.setname(name)` | Character name for self-target guards (`setname`). |
| `Tem.pray(gift, target, favors)` | Raw `pray …` with optional favors (`min` / `max` / number). |
| `Tem.praybuff(gift, opt1, opt2)` | Buff-style: uses `tt` or `self`; optional manual denizen / favors (see below). |
| `Tem.prayoff(gift, opt1, opt2)` | Offense-style: requires target unless you pass a manual name. |
| `Tem.melee(mode, target)` / `Tem.ranged(mode, target)` | `safe` \| `mid` \| `heavy` \| `auto` (risk band). |
| `Tem.atk(verb, target)` | Basic melee verbs (`slash`, `pound`, …). |
| `Tem.mv(n)` / `Tem.mvt(name)` | `move ±units` / `move name`. |
| `Tem.setrisk(band)` | `good` \| `neutral` \| `bad` \| `critical`. |
| `Tem.setwln("sharp"\|"blunt")` / `Tem.resetw()` | Weapon style preference after probe lines (`wsharp`, `wblunt`, `wreset`). |
| `Tem.acon()` / `Tem.acoff()` | Auto combat on/off (`acon`, `acoff`). |
| `Tem.updposture(line)` etc. | Used by combat triggers (posture, knockdown, weapon probes). |
| `Tem.cycle` / `Tem.syz` / `Tem.incant` | Lunar Sage cycle / `syzygies` / `use lunarincantations …`. |
| `Tem.uishow` / `Tem.uihide` / `Tem.uitog` | Moon UI (`lmoonon`, `lmoonoff`, `lmoon`). |

## Cleric gift aliases (reference)

**Buff-style prayers** (`praybuff`): optional first token is either favors (`min` / `max` / digits) or a one-shot denizen name; optional second is favors. If `tt` points at a mob but you want yourself, use an explicit name (e.g. `alac self`). **`recall`** (`celestialgrasp`) is self-only: optional word is favors only.

**Offense prayers** (`prayoff`): require `tt` unless you supply a manual target name first.

### Basic Gifts — Buffs

| Alias | Gift token |
|-------|------------|
| `alac`, `aura`, `prot`, `rejuv` | `alacrity`, `righteousaura`, `sacredprotection`, `rejuvenation` |

### Basic Gifts — Healing

| Alias | Command |
|-------|---------|
| `lrevive` | `liturgy:ghostwaverevive` (long revive) |
| `rezz` | `restoration` |
| `srezz` | `awakening` (self rez) |
| `vit` | `vitality` |

### Basic Gifts — Melee / risk

`bp` / `bc` / `bs` (pound / crush / smash), `sl` / `si` / `clv`, `mma` (smart), `rgb` / `rgn` / `rbd` / `rcr` (risk bands).

### Basic Gifts — Miscellaneous

| Alias | Notes |
|-------|--------|
| `hbr` | **Holy Burning Recant** — self + favors (`pray holyburningrecant self …`). |
| `recall` | **Celestial grasp** — self-only favors. |

### Basic Gifts — Offense

`dword`, `hymn`, `reb`.

### Empathy Gifts — Buffs

| Alias | Gift token |
|-------|------------|
| `eff`, `inter`, `allev`, `desur`, `bsf`, `brf` | Curative Efflux, Intercession, Alleviation, Desurmras Blessing, **Blazing Soulfire**, **Bestow Refulgent Flame** |

`brf` sends `pray bestowrefulgentflame self [favors]`.

### Empathy Gifts — Offense

`objm` → `objurgation:malice`.

### Cleric Skills

`rites`, `preach …`, `wlist`.

### Obscurity Gifts

`black`, `obc`.

Spells shown **in red** in your `gifts` list (e.g. Exodus, Exalted Spirit, Empathic Fire, Beacon Of Green Flames) are **not** aliased here—no access per your filter.

## Lunar Sage (in same package)

- Lookup: `cy`, `szy` / `syz`, `lrange` (reminder).
- Incantations: `liea`, `lieh`, `lifa`, `lifh`, `lisa`, `lish`, `liha`, `lihc`, `lihh`, `lila`, `lilc`, `lilh`, `liv`.
- Syzygies: `arem`, `eam`, `gms`, `lsh`, `lcr`, `nr`, `oam`, `pmb`, `pbur`, `zam`, `aar`, `bz`, `eh`, `fwa`, `hwr`, `oho`, `pbeam`, `rfl`, `uff`, `zd`, `mwk`.
- UI: `lmoon`, `lmoonon`, `lmoonoff`.

Lunar cores / melee-invalid lines switch auto-combat to **ranged** when appropriate (`Tem.lcranged`).

## Combat quick reference

| Player | Action |
|--------|--------|
| `tt <name>` | Set target |
| `acoff` / `acon` | Auto combat |
| `wsharp` / `wblunt` / `wreset` | Weapon style / reset after swap |
| `setname <name>` | Self-name for guards |
| `frap` / `fdeft` / `fprec` / `fauto <target>` | Ranged |
| `mv <n>` / `mvt <name>` | Move |

Optional: `Tem.aadelay = 2.1` (seconds) for auto-attack spacing.

## Self-target guard

Set once: `setname Yourname` or rely on **GMCP** `Char.Name` if the game fills it.

## Quick validation

1. Load [`Tempest.xml`](Tempest.xml) in Mudlet.
2. Optional: parse as XML in an editor or `Select-Xml` in PowerShell to catch typos.
3. In-game: `tt`, `wreset` + weapon probe, `acon` / `acoff`, Cleric `alac`, new gifts `hbr` / `bsf` / `brf` if you have them.

## References

- Mudlet scripting: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Scripting)
- Package format: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Technical_Manual)
- Lua PIL: [Lua PIL](https://www.lua.org/pil/contents.html)
- Combat manual: [tempestseason.com/manual/combat/](https://tempestseason.com/manual/combat/)
