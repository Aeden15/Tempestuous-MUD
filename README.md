# Tempest (Mudlet package)

This repo holds a **single** Mudlet package for **Tempest Season** ([tempestseason.com](https://www.tempestseason.com)): one source file, one import.

## Source of truth

| File | Role |
|------|------|
| [`Tempest.xml`](Tempest.xml) | Triggers, aliases, and all Lua (combat, target helper, Cleric, Lunar Sage, Dragon). **Edit this file** (or export from Mudlet and replace this file). |
| [`config.lua`](config.lua) | Mudlet package metadata (`mpackage`, description, version) shown by Mudlet Package Manager. Keep alongside `Tempest.xml` when building an `.mpackage`. |

## Install (Mudlet 4.20)

1. **Quick:** Drag [`Tempest.xml`](Tempest.xml) onto Mudlet, or run `installPackage([[full/path/to/Tempest.xml]])`.
2. **Shareable archive:** Zip **`Tempest.xml` + `config.lua`** together and rename the zip to **`Tempest.mpackage`** (Mudlet expects `config.lua` at the zip root). The built **`Tempest.mpackage`** is gitignored so accidental binary churn stays out of git.

### Scope (do not mix codebases)

- **Tempest Season only.** Lua assumes Tempest commands and mechanics.
- Use **separate Mudlet profiles** (or package sets) if you use automation for other games so globals like `Tem.*` do not collide.
- Targeting is namespaced: `tt` updates `Tem.tgt` only (Tempest does not mirror Mudlet global `target`).

## Lua namespace (`Tem`)

Aliases and triggers call functions on the **`Tem`** table (short names). User-visible `cecho` lines still say **`[Tempest]`** / **`[Tempest Combat]`** for branding.

| Lua | Purpose |
|-----|---------|
| `Tem.settgt(name)` | Set alias target (`tt` updates `Tem.tgt`). |
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
| `Tem.acon()` / `Tem.acoff()` | Auto combat on/off (`acon`, `acoff`). When `Tem.is_dragon` is true (from `score`), `acon` sends `use tear` vs `tt` instead of weapon melee. |
| `Tem.is_dragon` | Set by trigger on the `score` line starting with `You go by the name of` (dragon growth stages). `nil` until first matching `score`. |
| `Tem.dragonclaw_ready()` | True unless a `Dragon Claw cannot be used for another …` line has fired since the last ready line. |
| `Tem.essenic_blast_ready()` | True unless `Essenic Blast cannot be used for another …` fired since `Essenic Blast is now ready to be used.` |
| `Tem.essenic_blast_after_volley()` | True from the cast hit line `The volley crashes into … exploding violently!` until the first DoT tick or DoT expiry. |
| `Tem.essenic_blast_dot_active()` | True from each `The essence burns …!` tick until `The burning essence on … finally dies down.` |
| `Tem.essenic_blast_dot_ticks()` / `Tem.essenic_blast_dot_last_ticks()` | Tick count in the current DoT window / tick count for the last completed window (0 if none). |
| `Tem.dragon_use_target` / `Tem.dragon_use_self` / `Tem.dragon_passive` | Helpers for Dragon racial `use` aliases. |
| `Tem.updposture(line)` etc. | Used by combat triggers (posture, knockdown, weapon probes). |
| `Tem.cycle` / `Tem.syz` / `Tem.incant` | Lunar Sage cycle / `syzygies` / `use lunarincantations …`. |
| `Tem.uishow` / `Tem.uihide` / `Tem.uitog` | Moon UI (`lmoonon`, `lmoonoff`, `lmoon`). |

### Risk band, posture, and auto combat

On a fresh profile, **`Tem.risk` defaults to `good`**. Auto combat (`acon`) picks a melee/ranged tier from **`Tem.autotier()`**, which uses the **safer** (lower) of: (1) your **combat posture** tier parsed from game output, and (2) the tier implied by your **risk band** (`good` → heavy, `neutral` → mid, `bad` / `critical` → safe). With morale and posture in play, leaving the band at **`neutral`** can **cap** automation at mid even when your posture would support heavier attacks; **`rgb`** sets **good** if you want that ceiling raised. Aliases **`rgb`** / **`rgn`** / **`rbd`** / **`rcr`** still override the band anytime.

If **`Tem.is_dragon`** is **true**, `acon` skips posture/melee/ranged auto-attack logic and repeatedly sends **`use tear`** with your **`tt`** target (no `reqtgt` spam: it silently waits if `tt` is unset). Run **`score`** once after login so the package can detect dragon growth stages on the `You go by the name of …` line.

Invalid-name rejections (e.g. **`There is no player with the name … present in the room.`**) turn **`acon`** off through the same **Invalid target stop auto** trigger as **`That target does not exist.`** — queue clear, `acoff`, and the usual `[Tempest Combat]` message.

`[Tempest Combat]` status lines from the package print on their **own** line (leading newline) so they do not run onto the same line as incoming game text.

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
| `recall` | **Celestial grasp** — self-only favors. |
| `exod` | **Exodus** (`praybuff`). |

### Basic Gifts — Offense

`dword`, `hymn`, `reb`, `hbr` (**Holy Burning Recant** — `pray holyburningrecant self [favors]`).

### Empathy Gifts — Buffs

| Alias | Gift token |
|-------|------------|
| `eff`, `inter`, `allev`, `desur`, `bsf`, `empf`, `brf` | Curative Efflux, Intercession, Alleviation, Desurmras Blessing, **Blazing Soulfire**, **Empathic Fire**, **Bestow Refulgent Flame** |

`brf` sends `pray bestowrefulgentflame self [favors]`.

### Empathy Gifts — Offense

`objm` → `objurgation:malice`; `bgf` → **Beacon Of Green Flames**; `exalt` → **Exalted Spirit**.

### Cleric Skills

`rites`, `preach …`, `wlist`.

### Obscurity Gifts

`black`, `obc`.

Gift rows in your latest Basic/Empathy/Obscurity screenshots are all represented in the current Cleric alias set.

## Lunar Sage (in same package)

- Lookup: `cy`, `szy` / `syz`, `lrange` (reminder).
- Incantations: `liea`, `lieh`, `lifa`, `lifh`, `lisa`, `lish`, `liha`, `lihc`, `lihh`, `lila`, `lilc`, `lilh`, `liv`.
- Syzygies: `arem`, `eam`, `gms`, `lsh`, `lcr`, `nr`, `oam`, `pmb`, `pbur`, `zam`, `aar`, `bz`, `eh`, `fwa`, `hwr`, `oho`, `pbeam`, `rfl`, `uff`, `zd`, `mwk`.
- UI: `lmoon`, `lmoonon`, `lmoonoff`.

Lunar cores / melee-invalid lines switch auto-combat to **ranged** when appropriate (`Tem.lcranged`).
Moon UI registers an anonymous `sysWindowResize` handler once; if labels behave oddly after reinstall/reload, restart the profile or toggle `lmoonoff`/`lmoonon`.

## Ethari Psionics (in same package)

- Alias folder path: `Classes > Psionics`.
- Trees included: `Astral Flame`, `Clairsentience`, `Clairvoyance`, `Delusions`, `General Psionics`, `Psychometabolism`, `Telekinesis`, `Telepathy`, `Thrall Drain`, `Vitakinesis`.
- Current scope is **trained/unlocked abilities only** from your latest psionics list.

### Shorthand aliases

- `ef [target]` → `manipulate eonicflare [target]`
- `sps [target]` → `manipulate scorchedpsyche [target]`
- `enth [target]` → `manipulate enthrall [target]`
- `pbl` → Psi Blade is automatic/passive; alias prints guidance and opens `help psiblade`.

Target behavior:
- If target is provided, alias uses that target.
- If target is omitted, alias falls back to `tt` target when available.
- If `tt` is unset, command is sent without a target (matches in-game `help manipulate` behavior where blank target auto-targets Ethari context).

## Dragon (race skills)

- Alias folder: **`Classes > Dragon (race skills)`** (disable the folder on non-dragon profiles).
- **Posture:** lines from the in-game skill list are **not** included here (shared across classes); use your class posture aliases or raw `use posture:…` as usual.
- **`score`:** Triggers under **`Tempest > Classes > Dragon`** watch for `You go by the name of` and set **`Tem.is_dragon`** when the line contains **Dragon Whelp**, **Young Dragon**, **Adolescent Dragon**, **Adult Dragon**, or **Elder Dragon**; otherwise clears the flag on that same line shape.
- **Dragon Claw cooldown:** Triggers on `Dragon Claw cannot be used for another …` and `Dragon Claw is now ready to be used.` — query with `lua display(Tem.dragonclaw_ready())` or branch in your own scripts.
- **Essenic Blast:** Same cooldown pattern (`… cannot be used for another …` / `… is now ready to be used.`). **On cast:** `The volley crashes into <target>, exploding violently!` (optional `[damage]`). DoT is tracked on `The essence burns <target>!` and cleared on `The burning essence on <target> finally dies down.` — use `Tem.essenic_blast_after_volley()`, `Tem.essenic_blast_dot_active()`, `Tem.essenic_blast_dot_ticks()`, and `Tem.essenic_blast_dot_last_ticks()` alongside `Tem.essenic_blast_ready()`.
- **Charge** is a HUD resource in Tempest Season; this package does not parse it yet.

### Shorthand table (`use` form; optional bare verb still works in-game)

| Alias | Sends (canonical) |
|-------|---------------------|
| `ddc [tgt]` | `use dragonclaw <target>` |
| `dte [tgt]` | `use tear <target>` |
| `dgo [tgt]` | `use gore <target>` |
| `deb [tgt]` | `use essenicblast <target>` |
| `dbe [tgt]` | `use baneofessenic <target>` |
| `dvu [tgt]` | `use violentuproar <target>` |
| `dfe [tgt]` | `use feed <target>` |
| `dic [tgt]` | `use infusedclaws <target>` |
| `dfof` | `use dragonformforceoffire` |
| `dgsl` | `use dragonformspeedoflightning` |
| `dfow` | `use dragonformfinesseofwater` |
| `dkod` | `use dragonformknowledgeofdeath` |
| `dtop` | `use dragonformtouchofpoison` |
| `dhoi` | `use dragonformhardnessofice` |
| `dbw [tgt]` | `use bindwounds <target>` |
| `dfp` | `use feralpresence` |
| `dwr` | `use wrath` |
| `dss` | `use scaleshield` |
| `dbm` | `use boostmorale` |
| `dch` | `use chameleoncloak` |
| `dfs` | `use frenziedswipe` |
| `ddm` | passive — opens `help defensivemaneuvers` |
| `dama` | passive — opens `help amaranefortitude` |
| `ddr` | auto — opens `help dragonrage` |
| `des` | passive — opens `help enchantedscales` |

Confirm any token with **`help <skill name>`** if the MUD rejects a line; training and growth can rename rare edge cases.

## Combat quick reference

| Player | Action |
|--------|--------|
| `tt <name>` | Set target |
| `acoff` / `acon` | Auto combat (dragon + `score`: `use tear` vs `tt`) |
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
3. In-game: `tt`, `wreset` + weapon probe, `acon` / `acoff`, Cleric `alac`, new gifts `bsf` / `brf` if you have them.

## Posture/morale validation

- Toggle controls: `apon`, `apoff`, `apstat`, `apstats` (same as `apstat`), `apclear`, `apprune` (remove bogus keys like `you` / `stop` from old saves), `apdump`.
- Confirm posture parser lines:
  - `You enter the <Posture> posture!`
  - `You stop using Posture: <Posture>!`
  - `Posture: <Posture> cannot be used for another <N>s.`
  - `Posture: <Posture> is now ready to be used.`
- Weakness apply (learn NPC posture): `You apply the weakness Form Weakness: ...` (and other posture names) uses current `tt` target.
- Mind / combat activity (from live logs):
  - `You have gained a new mind state: …!` → tracked as `mindState` in `apstat` / `apstats`.
  - `Clearing command queue on kill.` → refreshes last-combat time (morale idle model).
- Confirm morale parser lines:
  - `Your morale has grown! You are now EAGER/STEADY/DETERMINED!`
  - `You lose all of your morale buffs from switching out of this Risk Stance!`
  - `Your morale state has decayed to ...`
  - `The iron-will ends and your morale can now be lost!`
- Verify policy behavior:
  - With active morale and unknown NPC posture, auto posture does not churn.
  - With known NPC posture, auto posture can switch to match the known target.
  - No posture selected is detected and auto posture re-establishes a stance.
- Verify idle decay model:
  - Stop combat and observe morale-state tracking downgrade on ~60s intervals out of combat.
  - Re-engage combat and ensure activity refreshes timing.
- Regression: confirm existing melee/ranged aliases and knockdown stand recovery still behave as before.

### Live regression (posture cooldown / false `you` learn)

1. Reload the package in Mudlet, then in a safe room: `apoff`, `apstats` — confirm status prints (no unknown command).
2. `apclear` — empty learned DB.
3. `tt <mob>`, `apon`, `acon` — fight until one kill. Expect no spam of `Auto posture: toggling off …` while `Posture: … cannot be used for another Ns` is showing.
4. `apoff`, `apstats`, `apdump` — `apdump` must **not** list a target key `you`. Entries should be real mob names (normalized) when posture was learned from lines.
5. Turn `apon` again only if you want auto posture; verify morale lines still update state after kills.

## References

- Mudlet scripting: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Scripting)
- Package format: [wiki.mudlet.org](https://wiki.mudlet.org/w/Manual:Technical_Manual)
- Lua PIL: [Lua PIL](https://www.lua.org/pil/contents.html)
- Combat manual: [tempestseason.com/manual/combat/](https://tempestseason.com/manual/combat/)
