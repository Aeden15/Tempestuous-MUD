/**
 * Generates TempestCombat.xml from combat_auto.lua + target.lua + trigger/alias tables.
 * Run: node Combat/build-combat-xml.cjs
 *
 * IMPORTANT (Mudlet 4.x): Trigger patterns MUST use <regexCodeList>/<regexCodePropertyList>.
 * The legacy <regex> element inside <Trigger> is NOT read by XMLimport::readTrigger — only
 * Aliases use <regex>. Using <regex> on triggers yields empty pattern rows in the editor.
 *
 * Pattern kinds: REGEX_SUBSTRING=0, REGEX_PERL=1 (see Mudlet src/TTrigger.h).
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");

const REGEX_PERL = 1;

function xmlText(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Mudlet accepts CDATA in <script>; avoids truncation when Lua comments contain <...> or many quotes. */
function luaScriptCdata(lua) {
  if (lua.includes("]]>")) {
    throw new Error("Lua source must not contain the CDATA terminator ]]>");
  }
  return `<![CDATA[\n${lua}\n]]>`;
}

/** Mudlet XMLexport::writeTrigger-compatible fields for a trigger or trigger folder. */
function emitRegexLists(patterns, kinds) {
  let body = "        <regexCodeList>\n";
  for (let i = 0; i < patterns.length; i++) {
    body += `          <string>${xmlText(patterns[i])}</string>\n`;
  }
  body += `        </regexCodeList>
        <regexCodePropertyList>\n`;
  for (let i = 0; i < kinds.length; i++) {
    body += `          <integer>${kinds[i]}</integer>\n`;
  }
  body += `        </regexCodePropertyList>\n`;
  return body;
}

function emitTriggerOpen(isFolder) {
  const ty = isFolder ? "TriggerGroup" : "Trigger";
  const folder = isFolder ? "yes" : "no";
  return `      <${ty} isActive="yes" isFolder="${folder}" isTempTrigger="no" isMultiline="no" isPerlSlashGOption="no" isColorizerTrigger="no" isFilterTrigger="no" isSoundTrigger="no" isColorTrigger="no" isColorTriggerFg="no" isColorTriggerBg="no">
`;
}

function emitTriggerCore(name, scriptText) {
  return `        <name>${xmlText(name)}</name>
        <script>${xmlText(scriptText)}</script>
        <triggerType>0</triggerType>
        <conditonLineDelta>0</conditonLineDelta>
        <mStayOpen>0</mStayOpen>
        <mCommand></mCommand>
        <packageName></packageName>
        <mFgColor>transparent</mFgColor>
        <mBgColor>transparent</mBgColor>
        <mSoundFile></mSoundFile>
        <colorTriggerFgColor>#ff0000</colorTriggerFgColor>
        <colorTriggerBgColor>#ffff00</colorTriggerBgColor>
`;
}

const targetLua = fs.readFileSync(path.join(root, "Classes", "core", "target.lua"), "utf8");
const combatLua = fs.readFileSync(path.join(__dirname, "combat_auto.lua"), "utf8");

const aliases = [
  { name: "Auto melee off", regex: "^acoff$", script: "Tempest.auto_melee_stop()" },
  { name: "Auto melee on", regex: "^acon$", script: "Tempest.auto_melee_start()" },
  { name: "Weapon sharp", regex: "^wsharp$", script: 'Tempest.set_weapon_line("sharp")' },
  { name: "Weapon blunt", regex: "^wblunt$", script: 'Tempest.set_weapon_line("blunt")' },
  { name: "Weapon styles reset", regex: "^wreset$", script: "Tempest.reset_weapon_capabilities()" },
  {
    name: "Set character name",
    regex: "^setname (\\w+)$",
    script: "Tempest.set_character_name(matches[2])",
  },
  { name: "Fire rapid", regex: "^frap (.+)$", script: 'Tempest.send_ranged("safe", matches[2])' },
  { name: "Fire deftly", regex: "^fdeft (.+)$", script: 'Tempest.send_ranged("mid", matches[2])' },
  { name: "Fire precisely", regex: "^fprec (.+)$", script: 'Tempest.send_ranged("heavy", matches[2])' },
  { name: "Fire auto risk", regex: "^fauto (.+)$", script: 'Tempest.send_ranged("auto", matches[2])' },
  { name: "Move by units", regex: "^mv ([+-]?\\d+)$", script: "Tempest.move_by_units(tonumber(matches[2]))" },
  { name: "Move toward target", regex: "^mvt (.+)$", script: "Tempest.move_towards(matches[2])" },
];

/** Each entry: script + either `regex` (single pattern) or `patterns` (array, OR-match). */
const triggers = [
  { name: "Combat engaged", regex: "attacks you!", script: "Tempest.on_combat_line()" },
  {
    name: "Posture line",
    regex: "^\\s*(.*Position.*)\\s*$",
    script: 'Tempest.update_posture_from_line(matches[1] or "")',
  },
  {
    name: "Knockdown stand",
    regex: "^You are knocked down from the force of the blow!$",
    script: "Tempest.on_knockdown()",
  },
  {
    name: "Knockdown stand alt",
    regex: "^You have been knocked down!$",
    script: "Tempest.on_knockdown()",
  },
  {
    name: "Knockdown message loose",
    regex: "(?i).*knocked down.*",
    script: "Tempest.on_knockdown()",
  },
  {
    name: "Knockdown retreat stumble",
    patterns: [
      "^As you retreat backwards, you loose your footing and stumble to the ground!$",
      "^As you retreat backwards, you lose your footing and stumble to the ground!$",
    ],
    script: "Tempest.on_knockdown()",
  },
  {
    name: "Cannot command while laying",
    regex: "^You can't use this command while laying\\.$",
    script: "Tempest.on_knockdown()",
  },
  {
    name: "Stood up",
    regex: "^You stand up\\.$",
    script: "Tempest.note_stood_up()",
  },
  {
    name: "Move capability ft units",
    patterns: ["^\\s*You can move (\\d+)ft\\((\\d+)units\\)!\\s*$"],
    script: "Tempest.note_move_capability(matches[2], matches[3])",
  },
  {
    name: "Invalid target stop auto",
    regex: "^That target does not exist\\.$",
    script: "Tempest.on_invalid_target()",
  },
  {
    name: "Weapon allows slashing",
    // Match game probe lines like "This is a slashing weapon." (indent/color-safe).
    patterns: [
      "^\\s*This\\s+is\\s+a\\s+slashing\\s+weapon\\s*\\.?\\s*$",
      "^\\s*This-is-a-slashing-weapon\\s*\\.?\\s*$",
    ],
    script: "Tempest.note_slashing_weapon(matches[1])",
  },
  {
    name: "Weapon allows blunt",
    patterns: [
      "^\\s*This\\s+is\\s+a\\s+blunt\\s+weapon\\s*\\.?\\s*$",
      "^\\s*This-is-a-blunt-weapon\\s*\\.?\\s*$",
    ],
    script: "Tempest.note_blunt_weapon(matches[1])",
  },
];

let xml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MudletPackage>
<MudletPackage version="1.001">
  <TriggerPackage>
`;

xml += emitTriggerOpen(true);
xml += emitTriggerCore("Tempest Combat", "");
xml += emitRegexLists([], []);

for (const t of triggers) {
  const patterns = t.patterns ?? [t.regex];
  const kinds = patterns.map(() => REGEX_PERL);
  xml += emitTriggerOpen(false);
  xml += emitTriggerCore(t.name, t.script);
  xml += emitRegexLists(patterns, kinds);
  xml += `      </Trigger>
`;
}

xml += `    </TriggerGroup>
  </TriggerPackage>
  <TimerPackage />
  <AliasPackage>
    <AliasGroup isActive="yes" isFolder="yes">
      <name>Tempest Combat</name>
      <script></script>
      <command></command>
      <packageName></packageName>
      <regex></regex>
`;

for (const a of aliases) {
  xml += `      <Alias isActive="yes" isFolder="no">
        <name>${xmlText(a.name)}</name>
        <script>${xmlText(a.script)}</script>
        <command></command>
        <packageName></packageName>
        <regex>${xmlText(a.regex)}</regex>
      </Alias>
`;
}

xml += `    </AliasGroup>
  </AliasPackage>
  <ActionPackage />
  <ScriptPackage>
    <ScriptGroup isActive="yes" isFolder="yes">
      <name>Tempest Core</name>
      <script></script>
      <command></command>
      <packageName></packageName>
      <regex></regex>
      <Script isActive="yes" isFolder="no">
        <name>target helper</name>
        <packageName></packageName>
        <script>${luaScriptCdata(targetLua)}</script>
        <eventHandlerList />
      </Script>
      <Script isActive="yes" isFolder="no">
        <name>combat automation</name>
        <packageName></packageName>
        <script>${luaScriptCdata(combatLua)}</script>
        <eventHandlerList />
      </Script>
    </ScriptGroup>
  </ScriptPackage>
  <KeyPackage />
</MudletPackage>
`;

const combatXmlPath = path.join(__dirname, "TempestCombat.xml");
fs.writeFileSync(combatXmlPath, xml, "utf8");
console.log("Wrote", combatXmlPath);
