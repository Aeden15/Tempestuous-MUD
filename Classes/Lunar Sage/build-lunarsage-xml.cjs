/**
 * Generates LunarSage.xml from alias source files + helper scripts.
 * Run: node "Classes/Lunar Sage/build-lunarsage-xml.cjs"
 */
const fs = require("fs");
const path = require("path");

const REGEX_PERL = 1;
const classRoot = __dirname;
const aliasRoot = path.join(classRoot);
const scriptRoot = path.join(classRoot, "Scripts");
const outPath = path.join(classRoot, "LunarSage.xml");

function xmlText(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function luaScriptCdata(lua) {
  if (lua.includes("]]>")) {
    throw new Error("Lua source must not contain CDATA terminator ]]>");
  }
  return `<![CDATA[\n${lua}\n]]>`;
}

function emitRegexLists(patterns, kinds) {
  let body = "        <regexCodeList>\n";
  for (const pattern of patterns) {
    body += `          <string>${xmlText(pattern)}</string>\n`;
  }
  body += `        </regexCodeList>
        <regexCodePropertyList>\n`;
  for (const kind of kinds) {
    body += `          <integer>${kind}</integer>\n`;
  }
  body += "        </regexCodePropertyList>\n";
  return body;
}

function emitTriggerOpen(isFolder) {
  const type = isFolder ? "TriggerGroup" : "Trigger";
  const folder = isFolder ? "yes" : "no";
  return `      <${type} isActive="yes" isFolder="${folder}" isTempTrigger="no" isMultiline="no" isPerlSlashGOption="no" isColorizerTrigger="no" isFilterTrigger="no" isSoundTrigger="no" isColorTrigger="no" isColorTriggerFg="no" isColorTriggerBg="no">
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

function walkLuaFiles(dir, files = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name === "Scripts") continue;
    if (entry.name === "LunarSage.xml") continue;
    if (entry.name === "build-lunarsage-xml.cjs") continue;
    if (entry.name.startsWith(".")) continue;

    const abs = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walkLuaFiles(abs, files);
      continue;
    }

    if (entry.isFile() && abs.toLowerCase().endsWith(".lua")) {
      files.push(abs);
    }
  }
  return files;
}

function parseAliasFile(absPath) {
  const text = fs.readFileSync(absPath, "utf8");
  const nameMatch = text.match(/^\s*--\s*name:\s*(.+)\s*$/m);
  const regexMatch = text.match(/^\s*--\s*regex:\s*(.+)\s*$/m);
  if (!nameMatch || !regexMatch) {
    throw new Error(`Missing -- name / -- regex header in ${absPath}`);
  }

  const script = text
    .split(/\r?\n/)
    .filter((line) => !line.match(/^\s*--\s*name:/) && !line.match(/^\s*--\s*regex:/))
    .join("\n")
    .trimEnd();

  const relDir = path.relative(aliasRoot, path.dirname(absPath));
  const groups = relDir === "" ? [] : relDir.split(path.sep);
  return {
    name: nameMatch[1].trim(),
    regex: regexMatch[1].trim(),
    script,
    groups,
  };
}

function makeNode(name) {
  return { name, groups: new Map(), aliases: [] };
}

function buildTree(items) {
  const root = makeNode("Lunar Sage");
  for (const item of items) {
    let node = root;
    for (const groupName of item.groups) {
      if (!node.groups.has(groupName)) {
        node.groups.set(groupName, makeNode(groupName));
      }
      node = node.groups.get(groupName);
    }
    node.aliases.push(item);
  }
  return root;
}

function emitAliasGroup(node, indent) {
  const pad = " ".repeat(indent);
  let xml = `${pad}<AliasGroup isActive="yes" isFolder="yes">
${pad}  <name>${xmlText(node.name)}</name>
${pad}  <script></script>
${pad}  <command></command>
${pad}  <packageName></packageName>
${pad}  <regex></regex>
`;

  const sortedGroups = [...node.groups.values()].sort((a, b) => a.name.localeCompare(b.name));
  for (const child of sortedGroups) {
    xml += emitAliasGroup(child, indent + 2);
  }

  const sortedAliases = [...node.aliases].sort((a, b) => a.name.localeCompare(b.name));
  for (const alias of sortedAliases) {
    xml += `${pad}  <Alias isActive="yes" isFolder="no">
${pad}    <name>${xmlText(alias.name)}</name>
${pad}    <script>${xmlText(alias.script)}</script>
${pad}    <command></command>
${pad}    <packageName></packageName>
${pad}    <regex>${xmlText(alias.regex)}</regex>
${pad}  </Alias>
`;
  }

  xml += `${pad}</AliasGroup>
`;
  return xml;
}

const triggers = [
  {
    name: "Lunar cores melee invalid",
    regex: "^You cannot use this type of weapon to perform a melee attack!$",
    script: "Tempest.on_lunar_melee_invalid()",
  },
  {
    name: "Lunar cores inspect line",
    regex: "(?i)^\\s*This\\s+is\\s+a\\s+lunar\\s+cores?.*$",
    script: "Tempest.on_lunar_cores_detected()",
  },
  {
    name: "Lunar cores can fire line",
    regex: "(?i)^\\s*This\\s+can\\s+fire\\s+\\d+\\s+times\\s+per\\s+round\\.?\\s*$",
    script: "Tempest.on_lunar_cores_detected()",
  },
  {
    name: "Lunar prompt Amor value",
    regex: "Amor:\\s*(-?\\d+)",
    script: "Tempest.lunar_ui_set_amor(tonumber(matches[2]))",
  },
  {
    name: "Lunar prompt Honestus value",
    regex: "Honestus:\\s*(-?\\d+)",
    script: "Tempest.lunar_ui_set_honestus(tonumber(matches[2]))",
  },
];

const aliasFiles = walkLuaFiles(aliasRoot);
const aliasItems = aliasFiles.map(parseAliasFile);
const aliasTree = buildTree(aliasItems);

const helperLua = fs.readFileSync(path.join(scriptRoot, "lunar_helpers.lua"), "utf8");
const moonUiLua = fs.readFileSync(path.join(scriptRoot, "moon_ui.lua"), "utf8");

let xml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE MudletPackage>
<MudletPackage version="1.001">
  <TriggerPackage>
`;

xml += emitTriggerOpen(true);
xml += emitTriggerCore("Lunar Sage", "");
xml += emitRegexLists([], []);

for (const trigger of triggers) {
  xml += emitTriggerOpen(false);
  xml += emitTriggerCore(trigger.name, trigger.script);
  xml += emitRegexLists([trigger.regex], [REGEX_PERL]);
  xml += "      </Trigger>\n";
}

xml += `    </TriggerGroup>
  </TriggerPackage>
  <TimerPackage />
  <AliasPackage>
`;
xml += emitAliasGroup(aliasTree, 4);
xml += `  </AliasPackage>
  <ActionPackage />
  <ScriptPackage>
    <ScriptGroup isActive="yes" isFolder="yes">
      <name>Lunar Sage Core</name>
      <script></script>
      <command></command>
      <packageName></packageName>
      <regex></regex>
      <Script isActive="yes" isFolder="no">
        <name>Lunar helper functions</name>
        <packageName></packageName>
        <script>${luaScriptCdata(helperLua)}</script>
        <eventHandlerList />
      </Script>
      <Script isActive="yes" isFolder="no">
        <name>Moon UI helpers</name>
        <packageName></packageName>
        <script>${luaScriptCdata(moonUiLua)}</script>
        <eventHandlerList />
      </Script>
    </ScriptGroup>
  </ScriptPackage>
  <KeyPackage />
</MudletPackage>
`;

fs.writeFileSync(outPath, xml, "utf8");
console.log("Wrote", outPath);
