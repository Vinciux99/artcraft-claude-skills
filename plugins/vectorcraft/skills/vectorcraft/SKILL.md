---
name: vectorcraft
description: Create and edit vector graphics with VectorCraft (Illustrator-style, ArtCraft suite) through MCP, the CLI or the control channel, and set up, connect or troubleshoot its MCP server on Windows and macOS.
---

# VectorCraft for Claude

VectorCraft (ArtCraft suite, storytold/vectorcraft; formerly DrawCraft) is an Illustrator-style vector editor: paths, shapes, text, multi-fill/stroke appearance, live effects, symbols, swatches, artboards, Image Trace, graphs, perspective, export to SVG/PDF/AI/EPS/PNG and more. Everything is a command with an id and JSON parameters, reachable from the UI, CLI, control channel and MCP.

## Quick check: is the MCP server connected?

1. Look at the tools you have. If tools from the MCP server `vectorcraft` are available (for example `list_commands`, `execute` or `inspect_*` tools) the server is connected: skip to "Operating knowledge" below and use them directly.
2. If they are missing, check whether the user installed it under the name `vectorcraft` or `vectorcraft-headless`. In Claude Desktop the server may show as **disconnected**.
3. **Most common cause of "disconnected":** the live server (`mcp --connect 127.0.0.1:{port}`) exits when VectorCraft is not running at the moment Claude starts. Fix: open VectorCraft with the **"VectorCraft (Claude)" launcher** (it starts the app with its control channel on), then re-enable the server in Claude's settings or fully quit and reopen Claude.
4. If the user does not need to watch the app live, **headless mode** always starts (no window, works on files). See "Live, headless or both".
5. If nothing is configured yet, follow "Set up the MCP server" below. Ask the user which OS they use if you do not know.

## Set up the MCP server (guide the user)

Walk the user through this step by step. Ask for the OS (Windows or macOS) first. If you have a shell on the user's machine you may run the steps yourself, but **ask before editing any config file and always back it up first**. Never print tokens or keys in chat.

### 1. Prerequisites
- Install VectorCraft from its upstream releases page: https://github.com/storytold/vectorcraft/releases (Windows: the `.msi` installer; macOS: the `.dmg`, then drag the app to `/Applications`).
- Install Claude Desktop and/or Claude Code. For Claude Desktop, fully quit and reopen it after any config change.
- The MCP server is the **CLI** that ships with the app: `vectorcraft-cli`. Windows installs it next to the app (`C:\Program Files\VectorCraft\vectorcraft-cli.exe`, not on `PATH`). On macOS the CLI is a separate release download (asset `vectorcraft-cli-<version>-macos-universal.zip`) unless it is bundled in the app (unverified): the setup script below fetches it into `~/.artcraft/bin/` and clears the macOS quarantine flag.
- This kit uses port **7979** (the upstream default), which does not clash with the other apps of the kit.

### 2. Option A: automatic setup (recommended)
The setup script finds the app and CLI, creates the launcher, backs up and updates Claude Desktop's config, registers the server in Claude Code (if the `claude` command exists) and installs this skill. Preview first with a dry run: nothing is changed.

Windows (PowerShell):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.ps1))) -Apps vectorcraft"
```
macOS (Terminal):
```sh
curl -fsSL https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.sh | bash -s -- --apps vectorcraft
```
Or clone/download this repository and double-click `setup-windows.cmd` (Windows) or `setup-macos.command` (macOS; first time: right-click, Open). Useful options: `-Mode live|headless|both` / `--mode ...` (default `live`; `both` registers `vectorcraft` live and `vectorcraft-headless`), `-DryRun` / `--dry-run`, `-NoLauncher`, `-NoClaudeDesktop`, `-NoClaudeCode`, `-NoSkill` (macOS: `--no-launcher`, `--no-claude-desktop`, `--no-claude-code`, `--no-skill`).

What it changes: Claude Desktop config (`%APPDATA%\Claude\claude_desktop_config.json` plus the Microsoft Store/MSIX copy under `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\`; macOS `~/Library/Application Support/Claude/claude_desktop_config.json`; backup saved next to it as `<file>.backup-<timestamp>`), the launcher "VectorCraft (Claude)" (Windows: Desktop shortcut; macOS: `~/Applications/VectorCraft (Claude).app` plus a Desktop alias), Claude Code's user-scope MCP list, and `~/.claude/skills/vectorcraft/`.

### 3. Option B: manual setup
**Windows** - edit `%APPDATA%\Claude\claude_desktop_config.json` (if Claude was installed from the Microsoft Store, also the copy under `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\`). Keep other servers; add this inside `mcpServers`. Backslashes must be doubled in JSON.
```json
{
  "mcpServers": {
    "vectorcraft": {
      "command": "C:\\Program Files\\VectorCraft\\vectorcraft-cli.exe",
      "args": [
        "mcp",
        "--connect",
        "127.0.0.1:7979"
      ]
    },
    "vectorcraft-headless": {
      "command": "C:\\Program Files\\VectorCraft\\vectorcraft-cli.exe",
      "args": [
        "mcp",
        "--headless"
      ]
    }
  }
}
```
**macOS** - edit `~/Library/Application Support/Claude/claude_desktop_config.json`. Use the absolute CLI path (replace `YOUR_NAME`; JSON does not expand `~`). The CLI path is unverified if your install differs: check with `ls ~/.artcraft/bin /Applications/VectorCraft.app/Contents/MacOS`.
```json
{
  "mcpServers": {
    "vectorcraft": {
      "command": "/Users/YOUR_NAME/.artcraft/bin/vectorcraft-cli",
      "args": [
        "mcp",
        "--connect",
        "127.0.0.1:7979"
      ]
    },
    "vectorcraft-headless": {
      "command": "/Users/YOUR_NAME/.artcraft/bin/vectorcraft-cli",
      "args": [
        "mcp",
        "--headless"
      ]
    }
  }
}
```
**Launcher** (starts the app with the control channel; needed before the live server can connect):
- Windows: create a Desktop shortcut named "VectorCraft (Claude)" with target `"C:\Program Files\VectorCraft\vectorcraft.exe" --control 7979`
- macOS: run `open -n -a "/Applications/VectorCraft.app" --args --control 7979`, or save it as an app with Script Editor/`osacompile` (the setup script does this for you).

**Claude Code** (any OS; run once):
Windows (PowerShell):
```powershell
claude mcp add --scope user vectorcraft -- "C:\Program Files\VectorCraft\vectorcraft-cli.exe" mcp --connect 127.0.0.1:7979
claude mcp add --scope user vectorcraft-headless -- "C:\Program Files\VectorCraft\vectorcraft-cli.exe" mcp --headless
```
macOS (Terminal):
```sh
claude mcp add --scope user vectorcraft -- "$HOME/.artcraft/bin/vectorcraft-cli" mcp --connect 127.0.0.1:7979
claude mcp add --scope user vectorcraft-headless -- "$HOME/.artcraft/bin/vectorcraft-cli" mcp --headless
```
Check with `claude mcp list`.

### 4. Authentication
VectorCraft needs no token: the control channel listens on loopback (`127.0.0.1`) only and has no authentication. Anyone on the machine can drive the app while it is open, so close it when you are done.

### 5. Finish and verify
1. **Fully quit and reopen Claude** (Desktop: quit from the tray/menu bar, not just close the window).
2. Open VectorCraft with the **"VectorCraft (Claude)" launcher** before asking Claude to use it.
3. In Claude, confirm the server `vectorcraft` is connected and call its `list_commands` tool (or equivalent). A non-empty command list means it works.

### Live, headless or both
- **Live** (`vectorcraft`): drives the open app; the user sees every change and screenshots/UI tools work. Needs the launcher first.
- **Headless** (`vectorcraft-headless`): in-process engine, no window; always starts; works on files; UI/screenshot tools are not available.
- **Both**: register both and pick per task. Switch with `-Mode` / `--mode`, or by editing the config entries above.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Server shows "disconnected" right after Claude starts | Live server exits when VectorCraft is not running | Open VectorCraft with the "VectorCraft (Claude)" launcher, then re-enable the server or restart Claude; or use headless mode |
| "Port already in use" / app opens but Claude cannot connect | Another app or an old VectorCraft instance holds port 7979 | Quit all VectorCraft windows, check the launcher uses the kit port, make sure no other ArtCraft app uses the same port |
| `command not found` / spawn error | CLI path wrong or the CLI is not installed (Windows: not on `PATH`; macOS: separate download) | Use the full absolute path in the config; macOS: run the setup script (it downloads the CLI to `~/.artcraft/bin/`) |
| macOS: "cannot be opened because the developer cannot be verified" | Gatekeeper/quarantine on the app or CLI | Right-click the app, Open; for the CLI: `xattr -dr com.apple.quarantine ~/.artcraft/bin/vectorcraft-cli` |
| Anyone else can drive the app | The control channel has no authentication (loopback only) | Start the app with the control channel only when needed and quit it when done |
| Config edited but nothing changed (Windows) | Claude installed from the Microsoft Store reads the MSIX copy of the config | Edit/update `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\claude_desktop_config.json` too |
| JSON config error / server not listed | Unescaped backslashes or trailing comma | Double the backslashes on Windows; validate the JSON; restore the `.backup-*` file if needed |
| App crashes on start or window is blank | Graphics backend problem | Windows: set `WGPU_BACKEND=vulkan` (or `dx12`) for one launch; avoid `gl` on some AMD drivers |
| Changes do not appear in the window | You are on the headless server | Use the live server (launcher first) |
| Quotes disappear in PowerShell JSON arguments | Windows PowerShell 5.1 quoting for `.exe` | Use `--script`/files where the CLI supports them, or single-quote the whole JSON |

## Operating knowledge

## Connecting

| Mode | Command | What works |
|---|---|---|
| **Remote (live)** | `vectorcraft-cli mcp --connect 127.0.0.1:7979` with the app started as `vectorcraft --control 7979` | Everything; you watch the app change live |
| **Headless** | `vectorcraft-cli mcp --headless` | Everything except UI-only tools (`inspect_ui`, `type_text`, `open_panel`, `screenshot {window:true}`) |
| **Automatic** | `vectorcraft-cli mcp` | Tries `127.0.0.1:7979`, falls back to headless if nothing answers |

Differences from the sister apps: port **7979**; the channel has **no authentication** (enable it only when needed); the flag is `--connect` (not `--bridge`).

**Allowed folders** (same flags as PhotoCraft): `--automation-read-root <dir>` and `--automation-write-root <dir>`. Every file read (open, place, relink, libraries, plug-ins, checked scripts) must be inside the read root; every file written (save, export, package, screenshot with a path...) inside the write root. Roots must exist; a path outside gives a readable error (`automation path rejected: outside the write root ...`). With only the read root, `export` and path-less saves still return the bytes (`dataBase64`).
- On the CLI these flags imply `--headless`; `--connect` together with them is an error.
- To confine the live app, start it with the flags: `vectorcraft --control 7979 --automation-read-root <dir> --automation-write-root <dir>` (or `VECTORCRAFT_AUTOMATION_READ_ROOT` / `..._WRITE_ROOT`), then connect normally.
- Isolated profile for tests: `VECTORCRAFT_CONFIG_DIR`; `VECTORCRAFT_NO_PREFS` disables preferences.

Choosing the channel: MCP server available → use it. Shell on the user's machine → CLI. A cloud-sandbox shell is a different machine: it cannot run the user's app or reach its localhost port (it can only prepare SVG/JSON files). Last resort: computer use (mind `[` `]` shortcuts on non-US keyboards).

## Ground rules
- **Coordinates are points** in document space: y points down, origin at the top-left of the first artboard. A new document is 612 × 792 (US Letter).
- New objects become the selection; most commands act on the selection or on explicit `ids`.
- **Colors** (`fill`, `stroke`): `"#rrggbb"`, `"none"`, `[r,g,b]` 0..1, `{"c","m","y","k"}`, `{"gray"}`, or a `paint.setFill` object (`{"gradient": ...}`, `{"swatch": "name"}`). For a filled shape with no outline pass `fill` and `stroke: "none"` (otherwise it inherits the "new art" appearance); lines start with no fill.
- **Parameter keys are checked:** an unknown key is rejected with a hint (`unknown parameter 'widht'; did you mean 'width'?`). Applies to `command_run`, `command_batch`, `run --params`, `engine.execute` and effect parameters.
- **References between steps** (`command_batch` and `run`): a string exactly `"$N"` or `"$N.path"` takes the result of step N **counting from 0**; `"$last.ids[0]"` the previous step; `"$$"` = a literal `$`.
- Calls that change nothing create no undo step (then `undo` undoes the one before).
- On big documents do not dump everything: `inspect_document {depth: 0}` (skeleton), `document.find {name?, kind?, text?, limit?}` to search, `document.node {id, summary: true, depth?, childLimit?}` to read a part. `document.json` / `vectorcraft://document/json` only when you need the full model.
- Exports are synchronous (no background jobs over MCP). In the desktop app saves may run in the background (`{background: true}`, see `ui.inspect` → `background`).

## MCP tools

**Dedicated tools**

| Tool | Arguments | Notes |
|---|---|---|
| `inspect_document` / `doc_inspect` | `{depth?, childLimit?}` | Artboards, layer tree (id, type, bounds, colors), selection, history, tool |
| `draw_shape` | `{shape, ...geometry, fill?, stroke?, strokeWidth?}` | `rectangle`/`ellipse`: `x,y,width,height` (+`radius` corners); `polygon`: `cx,cy,radius,sides`; `star`: `cx,cy,radius1,radius2,points`; `line`: `x1,y1,x2,y2` |
| `draw_path` | `{points \| d, closed?, fill?, stroke?, strokeWidth?}` | `points` `[[x,y],...]` or `[{x,y,in?,out?,smooth?},...]`; `d` = SVG path |
| `add_text` | `{text, x?, y?, width?, height?, fit?, path?, mode?, pathEffect?, size?, font?, color?, justify?}` | Point, area (`width`/`height`, `fit: none\|autoHeight\|shrinkText`) or on-path text (`path` + `mode: area\|onPath`); returns `{id, overflow?}` |
| `set_paint` | `{fill?, stroke?, strokeWidth?, ids?}` | On selection/ids; becomes the default for new art |
| `transform` | `{ids?, dx?, dy?, rotate?, scale?, scaleX?, scaleY?, reflect?, shear?, origin?, copy?}` | Order: move, rotate, scale, reflect, shear |
| `pathfinder` | `{operation, ids?}` | `unite`, `minusFront`, `intersect`, `exclude`, `divide`, `trim`, `merge`, `crop`, `outline`, `minusBack` |
| `apply_effect` | `{effect?, params?, ids?}` | Live effect; without `effect` returns the catalog with parameters and defaults |
| `create_graph` | `{type?, x, y, width, height, csv? \| series?, categories?, rows?}` | Nine types (column, bar, line, area, scatter, pie, radar...) |
| `text_wrap` | `{ids?, offset?, invert?, release?}` | Area text wrapping around objects |
| `select_tool` / `pointer_gesture` | `{tool}` / `{events:[{kind: down\|drag\|up\|move\|doubleclick, x, y, mods?}], tool?, mods?}` | Use tools like the mouse |
| `press_key` / `type_text` | `{key, mods?}` / `{text}` | `type_text` remote only |
| `invoke_menu` / `open_panel` | `{command, params?}` / `{panel}` | `open_panel` remote only |
| `screenshot` / `render_preview` | `{path?, scale?, artboard?, window?}` / `{max_side?, artboard?}` | PNG of the artboard (or the window with `window:true`, remote) |
| `open_file` | `{path}` | .vectorcraft/.drawcraft, .vctemplate, SVG/SVGZ, PDF/AI/AIT, EPS, DXF, EMF/WMF, PNG/JPEG/GIF/WebP/TIFF/BMP, PSD/PSB |
| `save_file` | `{path?}` | Format from file/extension (`.vectorcraft`, `.vctemplate`, `.pdf`, `.svg`, `.svgz`, `.ai`) |
| `export` | `{path?, format?, scale?, artboard?, range?, selection?, outlineText?, options?}` | svg, svgz, pdf, eps, dxf, emf, wmf, png, jpg, webp, gif, png8, tiff, bmp, tga, psd, txt, vectorcraft, template. Without path → `dataBase64` |
| `undo` / `redo` | `{}` | |
| `inspect_ui`, `ui_inspect`, `ui_screenshot` | | Remote only |

**Generic tools:** `list_commands {filter?, enabledOnly?}` / `command_list`; `run_command {command, params?}` / `command_run {id, params?}`; `command_batch {steps:[{id, params?}], stop_on_error?, atomic?, label?}` (max 256 steps; `atomic: true` = one undo).

**Resources:** `vectorcraft://document`, `vectorcraft://document/json`, `vectorcraft://commands`, `vectorcraft://object/{id}`, `vectorcraft://command/{id}`, `vectorcraft://effect/{id}`, `vectorcraft://swatch/{name}`.
**Ready-made prompts:** `poster {brief, palette, text}`, `icon-set {subject, count, detail}`, `recolor {palette, method}`, `trace-and-style {path, preset, effect}`, `export-set {formats, directory, scale}`.

## Examples
```json
{"name":"draw_shape","arguments":{"shape":"rectangle","x":72,"y":72,"width":200,"height":120,"radius":12,"fill":"#1e88e5","stroke":"none"}}
{"name":"draw_shape","arguments":{"shape":"star","cx":400,"cy":300,"radius1":90,"radius2":40,"points":5,"fill":"#ffc107","stroke":"#000000","strokeWidth":2}}
{"name":"draw_path","arguments":{"d":"M72 400 C 150 300 250 500 330 400","stroke":"#e53935","strokeWidth":4,"fill":"none"}}
{"name":"screenshot","arguments":{"scale":0.5}}
{"name":"export","arguments":{"path":"/Users/me/Pictures/art.svg"}}
{"name":"export","arguments":{"path":"/Users/me/Pictures/art.png","options":{"ppi":144,"background":"white","antiAlias":"type"}}}
{"name":"run_command","arguments":{"command":"select.all"}}
{"name":"run_command","arguments":{"command":"object.align","params":{"horizontal":"left"}}}
{"name":"run_command","arguments":{"command":"document.exportPdf","params":{"path":"out.pdf","range":"1, 3","compatibility":"1.5"}}}
{"name":"run_command","arguments":{"command":"colorTheme.save","params":{"color":"#2266aa","rule":"splitComplementary","name":"Harbor"}}}
```
- Raster export: `options` `ppi` (72 = 1 px per point), `background` (`transparent|white|black|#rrggbb`), `antiAlias` (`none|art|type`), `interlaced` (PNG), `quality` (JPEG). `useArtboards: true` = one file per artboard (`<name>-<n>.<ext>`).
- SVG: `options.svg` with `styling`, `outlineText`, `images: embed|link`, `objectIds`, `decimals`, `minify`, `responsive`, `preserveEditing` (reopens as a document), `embedFonts`, `profile: tiny12`. Full list: `run_command document.formats`.
- PDF: options of the Save PDF dialog (`preset`, `standard` PDF/A-PDF/X, `compatibility`, `compression`, `marks`, `bleed`, `output`, `advanced`, `security`); `document.pdfSettings` validates them without writing. `.ai` = a PDF carrying the native document (reopens editable).
- Gradient: `paint.setFill {gradient:{start:[x,y], end:[x,y]}}`, `paint.setGradientGeom {aspect, focal}`, freeform via `paint.editGradient {kind:"freeform"}` + `paint.freeform.addPoint {at, color, spread}`.
- Multiple appearance: `appearance.addFill`, `appearance.addStroke`; `item` (index) on `paint.setFill`, `stroke.set`, `effect.apply`...; `appearance.setActiveItem {index}`.
- CMYK document: `file.new {colorMode:"cmyk"}`; convert with `file.documentColorMode {mode}`.

## CLI (headless)
```sh
vectorcraft-cli commands                                   # command catalog (JSON)
vectorcraft-cli run --in in.svg --cmd select.all --cmd paint.setFill --params '{"color":"#ff0000"}' --export out.svg --export out.png --scale 2
vectorcraft-cli run --cmd file.new --params '{"width":800,"height":600}' --cmd shape.star --params '{"cx":400,"cy":300,"radius1":200,"radius2":90}' --export star.vectorcraft
vectorcraft-cli run --cmd file.new --params '{"width":600,"height":200}' --cmd text.create --params '{"x":10,"y":60,"text":"plain and bold words","size":30}' --cmd text.setRangeStyle --params '{"id":"$1.id","start":10,"end":14,"style":"Bold"}'
vectorcraft-cli run --cmd script.check --params '{"path":"Tidy Layers.jsx"}'
vectorcraft-cli --help        # formats and options (also convert, info)
```
`run` prints one JSON line per step (`open`, `cmd`, `export`) and exits non-zero at the first error; `--params` applies to the `--cmd` just before it. It also accepts `file.open`, `file.save`, `file.export`, `file.exportForScreens`, `tool.select`. In PowerShell call the exe with `&` and quote its path.

`script.check {path|data, includes?}` analyses an Illustrator-style `.jsx` script without running it (what DOM, files, menus it uses, syntax problems).

## Control channel (`vectorcraft --control 7979`)
TCP `127.0.0.1`, one JSON per line: `{"id":1,"method":"...","params":{}}` → `{"id":1,"ok":true,"result":...}`. No authentication; line max 4 MiB; 16 connections; idle 5 min; timeout 60 s (`will not run` = safe to retry; `still running` = check first). An invalid line closes the connection.

| Method | Use |
|---|---|
| `engine.execute {command, params}` / `engine.commands` | Any command / catalog |
| `document.inspect {depth?, childLimit?}` | Tree, selection, key object, history |
| `ui.inspect` | Tool, view, window, `fileDialog`, background saves, `ui.status` |
| `ui.menu.list` / `ui.menu.invoke {command, params}` / `ui.contextMenu.list` | Menus |
| `ui.tool.select {tool}` / `ui.tool.list` | Tools |
| `ui.pointer {events:[{kind, x, y, space?: doc\|screen, mods?}]}` | Use the tool like a mouse |
| `ui.key {key, shift?, alt?, cmd?}`, `ui.text {text}`, `ui.move`, `ui.click`, `ui.drag {x,y,toX,toY,steps?}`, `ui.wheel` | Synthetic input (max 1024 queued events) |
| `ui.set {brightness?, panel?, rulers?, outline?, grid?, smartGuides?, boundingBox?, controlBar?}` | UI state |
| `ui.dialog.set {field, value}` / `.confirm` / `.cancel` | Open dialogs (svgOptions, savePdf, pngOptions, exportForScreens, saveChanges...) |
| `ui.screenshot {path?, data?}` / `ui.render {path?, scale?, artboard?, data?}` | Window / rendered artboard |
| `app.open {path}`, `app.save {path?, svg?}`, `app.export {path?, format?, artboard?, range?, scale?, ...}`, `app.quit` | Files (quit/close open `saveChanges`: `ui.dialog.confirm` saves; `ui.dialog.set {field:"discard", value:true}` + confirm discards) |
| `ui.resize`, `ui.focus` | Window |

On Windows native file dialogs block the call until closed: always pass `path` to avoid them.

## Commands by family (from the docs; parameters via `list_commands {filter}`)
- **file:** `file.new {width, height, colorMode?}`, `file.newFromTemplate`, `file.open`, `file.save`, `file.saveAs`, `file.saveCopy`, `file.saveAsTemplate`, `file.revert`, `file.place {path, link?}`, `file.package`, `file.exportAs`, `file.exportForScreens`, `file.exportSelection`, `file.saveForWeb`, `file.print`, `file.documentColorMode`, `file.documentSetup`, `file.formatOptions`, `file.info`, `file.list {path}`, `file.recovery.list|restore|discard`, `file.close`, `file.closeAll`.
- **document:** `document.inspect`, `document.node`, `document.find`, `document.info`, `document.formats`, `document.open {path, pages?, cropTo?, password?, textAs?, layers?, colorMode?, editingData?}`, `document.save {path?, compress?, svg?}`, `document.export`, `document.serialize`, `document.exportPdf`, `document.pdfSettings`, `document.pdfInfo`, `document.exportEps`, `document.exportDxf`, `document.exportForScreens`, `document.exportForWeb`, `document.exportForOffice`, `document.exportSelection`, `document.setup`, `document.setUnits`, `document.rasterEffectsSettings`.
- **select:** `select.all`, `select.none`, `select.inverse`, `select.set`, `select.add`, `select.toggle {ids}`, `select.allOnArtboard`, `select.same.fillColor` (and other `select.same.*`), `select.object.*`, `select.anchors`, `select.anchorsMany`, `select.nextAbove|nextBelow`, `select.key`, `select.save`, `select.recall`.
- **object:** `object.move`, `object.rotate`, `object.scale`, `object.reflect`, `object.shear`, `object.setBounds`, `object.align {horizontal?, vertical?}`, `object.distribute`, `object.distributeSpacing`, `object.group`, `object.setProps {name?, opacity?, blend?, data?}`, `object.expand`, `object.rasterize`, `object.isolate`, `object.exitIsolation`, `object.clippingMask.make|release`, `object.blend.make|release|expand|options`, `object.envelope.makeWithWarp|makeWithMesh|makeWithTopObject|release|expand`, `object.mesh.create`, `object.path.offsetPath`, `object.path.simplify`, `object.path.splitIntoGrid`, `object.flattenTransparency`, `object.createTrimMarks`, `object.puppetWarp`, `object.liquify`, `object.slice.*`, `object.setLiveShape`, `object.showAll`.
- **path:** `path.join`, `path.split`, `path.reverse`, `path.removeAnchors`, `path.convertAnchors`, `path.cutAtAnchors`, `path.moveAnchors`, `path.reshapeSegment`, `path.curvatureEdit`, `path.setFillRule`, `path.lineCut`, `path.rectCut`.
- **paint / stroke / appearance:** `paint.setFill`, `paint.setStroke`, `paint.editGradient`, `paint.setGradientGeom`, `paint.freeform.*`, `paint.proxies`, `paint.recent`, `paint.invert`, `paint.complement`, `paint.default`, `stroke.set`, `stroke.setAdvanced`, `stroke.widthProfile.*`, `stroke.widthPoint.*`, `appearance.addFill`, `appearance.addStroke`, `appearance.setActiveItem`, `appearance.clear`, `appearance.removeItem`, `appearance.moveItem`, `transparency.set`, `gradient.selectStop`.
- **effect:** `effect.list`, `effect.apply {effect, params, item?}`, `effect.setParams`, `effect.remove`, `effect.duplicate`, `effect.expandAppearance`; 3D `threeD.extrude`, `threeD.inflate`.
- **text:** `text.create {x, y, text, size}`, `text.createInPath`, `text.setText`, `text.setStyle`, `text.setRangeStyle {id, start, end, style}`, `text.setFormat`, `text.areaOptions`, `text.getRange`, `text.fonts`, `text.fontList`, `text.missingFonts`, `text.rescanFonts`, `type.convertToAreaType`, `type.convertToPointType`, `paraStyle.new|apply|list`, `charStyle.new`.
- **layer / artboard:** `layer.new`, `layer.newSublayer`, `layer.setProps`, `layer.setCurrent`, `layer.move`, `layer.merge`, `layer.flatten`, `layer.duplicate`, `layer.delete`, `layer.releaseToLayers`, `layer.lockOthers`, `layer.hideOthers`, `artboard.setProps`, `artboard.fitToArt`, `artboard.duplicate`, `artboard.delete`, `artboard.rearrange`, `guide.add|move|remove|list`.
- **colors / styles:** `swatch.list`, `swatch.new`, `swatch.edit`, `swatch.delete`, `swatch.newGroup`, `swatch.move`, `swatch.library.*`, `color.harmony {color, rule}`, `colorTheme.save|list|delete|addToSwatches`, `recolor.apply`, `edit.colors.toCMYK|toRGB|toGrayscale|invert|saturate`, `graphicStyle.new|apply|list|library`.
- **other:** `symbol.new|place|edit|replace|list`, `brush.new|apply|list`, `imageTrace.make|makeAndExpand|expand|presets`, `graph.setData`, `graph.setType`, `perspective.*`, `variable.*`, `dataset.*`, `links.list|relink|embed|update`, `library.*`, `assets.*`, `css.copy|export`, `print.*`, `prefs.get|set|list`, `plugin.list|install|run`, `script.check`, `edit.undo`, `edit.copy`, `edit.paste`, `edit.pasteInFront|InBack|InPlace`, `view.fitArtboard`, `view.actualSize`, `window.panel.*`, `tool.select`, `tool.setOption`.

## Recommended workflow
1. Orient: `inspect_document {depth: 0}` (and `inspect_ui` when remote).
2. Create or open: `run_command file.new {width, height}` or `open_file {path}` (inside the read root).
3. Draw with the dedicated tools; for everything else `list_commands {filter}` → `run_command`. Multi-step: `command_batch {atomic: true, label}`.
4. Verify with `screenshot` / `render_preview` and `document.node`.
5. Save/export (`save_file`, `export`) inside the write root when the user agrees; never overwrite originals without asking.
