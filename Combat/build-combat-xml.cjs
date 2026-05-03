/**
 * Generates TempestCombat.xml and syncs target.lua into Classes/Cleric/Cleric.xml
 * Run from repo root: node Combat/build-combat-xml.cjs
 */
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");

function xmlText(s) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
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
];

const triggers = [
  { name: "Combat engaged", regex: "attacks you!", script: "Tempest.on_combat_line()" },
  {
    name: "Posture line",
    regex: "^(.*Position.*)$",
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
    name: "Weapon allows slashing",
    regex: "^This is a slashing weapon\\.?$",
    script: "Tempest.note_slashing_weapon()",
  },
  {
    name: "Weapon allows blunt",
    regex: "^This is a blunt weapon\\.?$",
    script: "Tempest.note_blunt_weapon()",
  },
];

let xml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MudletPackage>
<MudletPackage version="1.001">
  <TriggerPackage>
    <TriggerGroup isActive="yes" isFolder="yes">
      <name>Tempest Combat</name>
      <script></script>
      <command></command>
      <packageName></packageName>
      <regex></regex>
`;

for (const t of triggers) {
  xml += `      <Trigger isActive="yes" isFolder="no">
        <name>${xmlText(t.name)}</name>
        <script>${xmlText(t.script)}</script>
        <command></command>
        <packageName></packageName>
        <regex>${xmlText(t.regex)}</regex>
      </Trigger>
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
        <script>${xmlText(targetLua)}</script>
        <eventHandlerList />
      </Script>
      <Script isActive="yes" isFolder="no">
        <name>combat automation</name>
        <packageName></packageName>
        <script>${xmlText(combatLua)}</script>
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

const clericPath = path.join(root, "Classes", "Cleric", "Cleric.xml");
let cleric = fs.readFileSync(clericPath, "utf8");
const embedded = xmlText(targetLua);
cleric = cleric.replace(
  /(<name>target helper<\/name>\s*<packageName><\/packageName>\s*<script>)[\s\S]*?(<\/script>\s*<eventHandlerList \/>)/,
  `$1${embedded}$2`
);
fs.writeFileSync(clericPath, cleric, "utf8");
console.log("Synced target helper into", clericPath);
