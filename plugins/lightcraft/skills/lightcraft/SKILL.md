---
name: lightcraft
description: Manage photo libraries and develop RAW photos with LightCraft (Lightroom-style, ArtCraft suite) through MCP, the CLI or the control channel, and set up, connect or troubleshoot its MCP server on Windows and macOS.
---

# LightCraft for Claude

LightCraft (ArtCraft suite, storytold/lightcraft) is a clean-room, open-source, pure-Rust reimplementation of Lightroom: library (albums, folders, ratings, flags, labels, keywords, search), non-destructive RAW/JPEG development (Light, Color, Effects, curves, color grading, masks, crop, spot removal), HDR/panorama merge and export. Status: **alpha**.

Everything is a **command** with a stable id (`photo.rate`, `develop.set`, `mask.add`, `app.export`, ...) and JSON parameters. UI, keyboard, CLI, control channel and MCP server all go through the same dispatcher: if you find the right id you can run it from any channel. If a parameter is not documented here, discover it with `list_commands` / `--help` instead of inventing it.

## Quick check: is the MCP server connected?

1. Look at the tools you have. If tools from the MCP server `lightcraft` are available (for example `list_commands`, `execute` or `inspect_*` tools) the server is connected: skip to "Operating knowledge" below and use them directly.
2. If they are missing, check whether the user installed it under the name `lightcraft` or `lightcraft-headless`. In Claude Desktop the server may show as **disconnected**.
3. **Most common cause of "disconnected":** the live server (`mcp --connect 127.0.0.1:{port}`) exits when LightCraft is not running at the moment Claude starts. Fix: open LightCraft with the **"LightCraft (Claude)" launcher** (it starts the app with its control channel on), then re-enable the server in Claude's settings or fully quit and reopen Claude.
4. If the user does not need to watch the app live, **headless mode** always starts (no window, works on files). See "Live, headless or both".
5. If nothing is configured yet, follow "Set up the MCP server" below. Ask the user which OS they use if you do not know.

## Set up the MCP server (guide the user)

Walk the user through this step by step. Ask for the OS (Windows or macOS) first. If you have a shell on the user's machine you may run the steps yourself, but **ask before editing any config file and always back it up first**. Never print tokens or keys in chat.

### 1. Prerequisites
- Install LightCraft from its upstream releases page: https://github.com/storytold/lightcraft/releases (Windows: the `.msi` installer; macOS: the `.dmg`, then drag the app to `/Applications`).
- Install Claude Desktop and/or Claude Code. For Claude Desktop, fully quit and reopen it after any config change.
- The MCP server is the **CLI** that ships with the app: `lightcraft-cli`. Windows installs it next to the app (`C:\Program Files\LightCraft\lightcraft-cli.exe`, not on `PATH`). On macOS the CLI is a separate release download (asset `lightcraft-cli-<version>-macos-universal.zip`) unless it is bundled in the app (unverified): the setup script below fetches it into `~/.artcraft/bin/` and clears the macOS quarantine flag.
- This kit uses port **7980** (the upstream default), which does not clash with the other apps of the kit.

### 2. Option A: automatic setup (recommended)
The setup script finds the app and CLI, creates the launcher, backs up and updates Claude Desktop's config, registers the server in Claude Code (if the `claude` command exists) and installs this skill. Preview first with a dry run: nothing is changed.

Windows (PowerShell):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.ps1))) -Apps lightcraft"
```
macOS (Terminal):
```sh
curl -fsSL https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.sh | bash -s -- --apps lightcraft
```
Or clone/download this repository and double-click `setup-windows.cmd` (Windows) or `setup-macos.command` (macOS; first time: right-click, Open). Useful options: `-Mode live|headless|both` / `--mode ...` (default `live`; `both` registers `lightcraft` live and `lightcraft-headless`), `-DryRun` / `--dry-run`, `-NoLauncher`, `-NoClaudeDesktop`, `-NoClaudeCode`, `-NoSkill` (macOS: `--no-launcher`, `--no-claude-desktop`, `--no-claude-code`, `--no-skill`).

What it changes: Claude Desktop config (`%APPDATA%\Claude\claude_desktop_config.json` plus the Microsoft Store/MSIX copy under `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\`; macOS `~/Library/Application Support/Claude/claude_desktop_config.json`; backup saved next to it as `<file>.backup-<timestamp>`), the launcher "LightCraft (Claude)" (Windows: Desktop shortcut; macOS: `~/Applications/LightCraft (Claude).app` plus a Desktop alias), Claude Code's user-scope MCP list, and `~/.claude/skills/lightcraft/`.

### 3. Option B: manual setup
**Windows** - edit `%APPDATA%\Claude\claude_desktop_config.json` (if Claude was installed from the Microsoft Store, also the copy under `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\`). Keep other servers; add this inside `mcpServers`. Backslashes must be doubled in JSON.
```json
{
  "mcpServers": {
    "lightcraft": {
      "command": "C:\\Program Files\\LightCraft\\lightcraft-cli.exe",
      "args": [
        "mcp",
        "--connect",
        "127.0.0.1:7980"
      ]
    },
    "lightcraft-headless": {
      "command": "C:\\Program Files\\LightCraft\\lightcraft-cli.exe",
      "args": [
        "mcp"
      ]
    }
  }
}
```
**macOS** - edit `~/Library/Application Support/Claude/claude_desktop_config.json`. Use the absolute CLI path (replace `YOUR_NAME`; JSON does not expand `~`). The CLI path is unverified if your install differs: check with `ls ~/.artcraft/bin /Applications/LightCraft.app/Contents/MacOS`.
```json
{
  "mcpServers": {
    "lightcraft": {
      "command": "/Users/YOUR_NAME/.artcraft/bin/lightcraft-cli",
      "args": [
        "mcp",
        "--connect",
        "127.0.0.1:7980"
      ]
    },
    "lightcraft-headless": {
      "command": "/Users/YOUR_NAME/.artcraft/bin/lightcraft-cli",
      "args": [
        "mcp"
      ]
    }
  }
}
```
**Launcher** (starts the app with the control channel; needed before the live server can connect):
- Windows: create a Desktop shortcut named "LightCraft (Claude)" with target `"C:\Program Files\LightCraft\lightcraft.exe" --control 7980`
- macOS: run `open -n -a "/Applications/LightCraft.app" --args --control 7980`, or save it as an app with Script Editor/`osacompile` (the setup script does this for you).

**Claude Code** (any OS; run once):
Windows (PowerShell):
```powershell
claude mcp add --scope user lightcraft -- "C:\Program Files\LightCraft\lightcraft-cli.exe" mcp --connect 127.0.0.1:7980
claude mcp add --scope user lightcraft-headless -- "C:\Program Files\LightCraft\lightcraft-cli.exe" mcp
```
macOS (Terminal):
```sh
claude mcp add --scope user lightcraft -- "$HOME/.artcraft/bin/lightcraft-cli" mcp --connect 127.0.0.1:7980
claude mcp add --scope user lightcraft-headless -- "$HOME/.artcraft/bin/lightcraft-cli" mcp
```
Check with `claude mcp list`.

### 4. Authentication
LightCraft needs no token: the control channel listens on loopback (`127.0.0.1`) only and has no authentication. Anyone on the machine can drive the app while it is open, so close it when you are done.

### 5. Finish and verify
1. **Fully quit and reopen Claude** (Desktop: quit from the tray/menu bar, not just close the window).
2. Open LightCraft with the **"LightCraft (Claude)" launcher** before asking Claude to use it.
3. In Claude, confirm the server `lightcraft` is connected and call its `list_commands` tool (or equivalent). A non-empty command list means it works.

### Live, headless or both
- **Live** (`lightcraft`): drives the open app; the user sees every change and screenshots/UI tools work. Needs the launcher first.
- **Headless** (`lightcraft-headless`): in-process engine, no window; always starts; works on files; UI/screenshot tools are not available.
- **Both**: register both and pick per task. Switch with `-Mode` / `--mode`, or by editing the config entries above.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Server shows "disconnected" right after Claude starts | Live server exits when LightCraft is not running | Open LightCraft with the "LightCraft (Claude)" launcher, then re-enable the server or restart Claude; or use headless mode |
| "Port already in use" / app opens but Claude cannot connect | Another app or an old LightCraft instance holds port 7980 | Quit all LightCraft windows, check the launcher uses the kit port, make sure no other ArtCraft app uses the same port |
| `command not found` / spawn error | CLI path wrong or the CLI is not installed (Windows: not on `PATH`; macOS: separate download) | Use the full absolute path in the config; macOS: run the setup script (it downloads the CLI to `~/.artcraft/bin/`) |
| macOS: "cannot be opened because the developer cannot be verified" | Gatekeeper/quarantine on the app or CLI | Right-click the app, Open; for the CLI: `xattr -dr com.apple.quarantine ~/.artcraft/bin/lightcraft-cli` |
| Anyone else can drive the app | The control channel has no authentication (loopback only) | Start the app with the control channel only when needed and quit it when done |
| Config edited but nothing changed (Windows) | Claude installed from the Microsoft Store reads the MSIX copy of the config | Edit/update `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Roaming\Claude\claude_desktop_config.json` too |
| JSON config error / server not listed | Unescaped backslashes or trailing comma | Double the backslashes on Windows; validate the JSON; restore the `.backup-*` file if needed |
| App crashes on start or window is blank | Graphics backend problem | Windows: set `WGPU_BACKEND=vulkan` (or `dx12`) for one launch; avoid `gl` on some AMD drivers |
| Changes do not appear in the window | You are on the headless server | Use the live server (launcher first) |
| Quotes disappear in PowerShell JSON arguments | Windows PowerShell 5.1 quoting for `.exe` | Use `--script`/files where the CLI supports them, or single-quote the whole JSON |

## Operating knowledge

## Settings, paths, environment
- **Settings folder:** Windows `%APPDATA%\LightCraft\`; macOS `~/Library/Application Support/LightCraft/` (unverified). Logs in `logs/lightcraft.log` (rotates to `lightcraft.1.log` / `.2.log`; Help ▸ Open Log Folder). Optional models (SAM 3 in `models/sam3/`) live there. Portable mode: a `portable.txt` (or `LightCraft.portable`) next to the executable moves everything into `LightCraftData`.
- **Default library:** `~/Pictures/LightCraft Library` (confirm with `library.info` → `path`). A new library starts with demo photos.
- **App flags:** `--control PORT`, `--library DIR`, `--memory` (throw-away demo session, writes nothing), positional paths (folders/files to import, duplicates skipped), `--version`, `--help`.

| Variable | Effect |
|---|---|
| `LIGHTCRAFT_CONTROL_PORT=7980` | Same as `--control 7980` (opens the control channel) |
| `LIGHTCRAFT_CONFIG_DIR=<dir>` | Isolated settings folder (preferences, logs, default models); for tests also use a separate `--library` |
| `LIGHTCRAFT_NO_PREFS` | No preferences/log files (stderr only). Do not use when testing persistence |
| `LIGHTCRAFT_LOG=info\|debug` / `RUST_LOG` | Log level |
| `LIGHTCRAFT_GPU=0` / `LIGHTCRAFT_GPU_BACKEND=dx12\|vulkan\|gl\|metal\|off` | GPU off / forced backend (Windows default is DX12; if it crashes at startup try `dx12` or `off`) |
| `LIGHTCRAFT_MEMORY_MB` | Cache memory budget (default min(25% RAM, 1.5 GiB)) |
| `LIGHTCRAFT_SAM3_DIR`, `LIGHTCRAFT_SAM3_MIRRORS`, `LIGHTCRAFT_SAM3_REMOTE` | AI mask model (folder, mirrors, remote inference) |
| `LIGHTCRAFT_DENOISE_MODELS`, `LIGHTCRAFT_DENOISE_URL`, `LIGHTCRAFT_DENOISE_TOKEN` | AI Denoise models and remote denoise server |
| `LIGHTCRAFT_FACE_MODELS`, `LIGHTCRAFT_LENSFUN_DIR` | Face models, Lensfun lens profiles |

Examples of starting the app with the control channel: `lightcraft --control 7980`, `lightcraft --library "D:/Photos/LC Library" --control 7980` (specific library), `lightcraft --memory --control 7980` (throw-away demo).

## Connecting

| Mode | Command | What it drives | Notes |
|---|---|---|---|
| **MCP headless** (default) | `lightcraft-cli mcp [--demo] [--library DIR] [--compact] [FILE/FOLDER...]` | In-process engine session, no window | Develop, render, export; no UI tools |
| **MCP connect** (live app) | `lightcraft-cli mcp --connect [127.0.0.1:7980]` | The desktop app started with `--control 7980` | Adds screenshot, click, keys, gestures; connects on first call and reconnects if the app restarts |
| **CLI one-shot** | `lightcraft-cli run [--import ...] [--library DIR] [--connect [ADDR]] [--demo] [--script f.jsonl] [--keep-going] cmd k=v ...` | Headless, saved library or live app | One JSON line per command; exit ≠ 0 on failure |
| **Control channel** | TCP JSON lines on `127.0.0.1:7980` | The live app | `engine.*` and `ui.*` methods; basis of connect mode |
| **Headless UI snapshot** | `lightcraft-cli snapshot [--demo\|--library DIR] --script tour.jsonl -o out.png --size 1600x1000 [--scale 2]` | A whole UI session on CPU, no window | Same methods as the channel |

- **Port:** loopback only; 7980 is the example port (choose another if busy).
- **Authentication: none.** Anyone on the machine who can open a local socket can control the app. Enable only when needed and close the app (or restart without `--control`) when done. Max 16 connections, lines ≤ 4 MiB; a line that is not a JSON object with `method` closes the connection (protection against cross-origin HTTP requests).
- **Library lock:** a library is opened by a single process (`catalog.lock`). If the app has the library open, `mcp --library` on the same folder fails ("This library is already open in LightCraft...") — use `--connect`. For a headless MCP server alongside the app, give it a *different* library folder.
- **No read/write roots:** the docs define no automation roots; the user's filesystem applies. The only documented protection: a cataloged original (or its sidecar) is never overwritten by export/render, whatever the policy or `path`.
- To check you are on the expected library, call `doc_inspect` or `query_photos` before editing. For clients that struggle with many tools add `--compact` to the args.

### Choosing the channel
1. **MCP server available** (`lightcraft*` / `command_list` tools visible) → use it. Connect if the user wants to see the result in the app; headless for batches without a window.
2. **A shell on the user's machine** → `lightcraft-cli run ...` / `render ...` with the full path.
3. **A cloud sandbox** cannot run the user's app or reach its ports; it can only prepare files (`.jsonl` scripts, `.lcpreset` presets, lists).
4. **Last resort: computer use.** Non-US keyboards: shortcuts with `[` `]` (brush size) and `\` (original) may fail; prefer menus/sliders or, better, a command channel.

## Ground rules
- **Photo ids:** integers local to the library/session (`1`, `21`, ...). After reconnecting or switching library re-read state (`library.state`, `query_photos`); equal ids do not identify the same library.
- **Active photo vs selection:** most commands act on the **active** photo (or the selection for batch). `get_develop {id}` and `render_photo {id}` do not change the selection; `set_develop`, `crop`, `export` with an `id` **replace** the selection with that photo. Without an active photo `develop.controls` returns defaults and `photo.inspect` / `develop.get` without id error out.
- **Develop controls:** ids `section.name` (`light.exposure`, `light.contrast`, `light.highlights`, `light.shadows`, `light.whites`, `light.blacks`, `wb.temp`, `wb.tint`, `color.vibrance`, `color.saturation`, `effects.texture`, `effects.clarity`, `effects.dehaze`, `vignette.amount`, `grain.amount`, `grading.highlights.hue`, `grading.shadows.sat`, `detail.sharpenAmount`, `detail.nrLuminance`, `enhance.denoise`, `optics.distortion`, `crop.angle`, `profile.amount`, ...). `light.exposure` is −5..5 (step 0.01); Contrast … Blacks −100..100. **Always read range/default/value** with `list_controls` / `develop.controls {section}`.
- **White balance:** `wb.temp` is in **Kelvin** on RAWs with color matrices (DNG and known cameras), **relative** elsewhere (6500 = as shot, the UI shows −100..+100). In a partial `settings` JSON (`develop.merge`, presets) `temp`/`tint` without `"scale": "kelvin"` are always relative: for Kelvin use `values` in `set_develop` or `develop.wb`.
- **Non-destructive:** originals are never touched; edits live in the catalog (append-only log). XMP sidecars: `photo.saveMetadataToFile {ids?}` writes `<stem>.xmp` (merge, never replace; other apps' `crs:` preserved), `library.xmpPreferences {autoWrite: true}` writes them after each edit, `photo.readMetadataFromFile {ids?}` reads them back (one undo step). Full settings are in `lc:settings`.
- **Undo/history:** everything is undoable (`edit.undo` / `edit.redo`, `history.list` / `history.restore`). A drag or a burst of `develop.set` is one step; in `command_batch` each edit is its own step; group with `develop.beginInteraction {label}` … `develop.endInteraction {}`.
- **Parameters:** MCP helpers are **strict** (unknown key → JSON-RPC `-32602` listing accepted keys); `cmd_*` tools and `run_command` `params` are free-form (prose docs), but export options are validated strictly. Command errors → result with `isError: true`: read the message and fix.
- **Render process:** `get_develop` reports `process`; old photos may be on V1; `develop.updateProcess` moves them to the latest (changes the look: ask first). Copy/paste/sync/presets do not change it.
- **Auto Sync:** when on, `develop.set` / `develop.adjust` propagate to the other selected photos. `develop.autoSync {}` is a **toggle**, not a read — do not call it to "check".
- **Background tasks:** import, background export, previews, downloads, face scans appear in `activity.list` (`{tasks:[{id, kind, label, done, total, ...}]}`); stop with `activity.cancel {id}` or `{all: true}`.
- **Failed save:** with a persistent library, "saved in memory but not written to disk: ...; LightCraft will retry" means the edit is applied but not yet on disk (disk full?): tell the user.
- **Connection lost mid-call:** "the outcome is unknown" → nothing is re-sent; check state before repeating (an `edit.undo` must not run twice).
- **AI models:** Object/Describe masks (SAM 3) and AI Denoise need optional models the user installs. Call `segment.model.download {acknowledged: true}` and `faces.models.download/install {acknowledged: true}` only **after** the user has seen and accepted the license/terms. AI Denoise: Bayer RAW only (no X-Trans, no JPEG); no weights included. The "AI" Sky/Subject/Background masks are currently classical heuristics.

## MCP tools

Core tools (always listed, even with `--compact`):

| Tool | Arguments | Notes |
|---|---|---|
| `command_list` | `filter?`, `enabled_only?` | Command catalog |
| `command_run` | `id`, `params?` | Run a command |
| `command_batch` | `steps: [{id, params?}]`, `stop_on_error?` | Stops at the first error by default; export here is synchronous, no progress |
| `doc_inspect` | — | Library state and catalog counts |
| `render_preview` | `id?`, `max_side?`, `format?` | Image; does not change selection or save files |

Helpers:

| Tool | Arguments | Notes |
|---|---|---|
| `list_commands` | `filter?` | id, label, menu, shortcut, param doc, enabled now |
| `run_command` | `command`, `params?` | Any command by id |
| `import` | `paths`, `album?`, `mode?`, `destination?`, `organize?`, `rename?` | Recursive folders; the first new photo becomes active. `mode`: add (in place), `copy`, `move` (source removed only after a verified copy); `organize`: `date`, `month`, `flat` or template `{date:%Y}/{date:%Y%m%d}`; `rename`: template (tags from `photo.renameTokens`) |
| `query_photos` | `filter?`, `sort?`, `offset?`, `limit?` | Photos of the current view or a catalog `Filter` |
| `select_photos` | `ids`, `active?`, `mode?` | Unknown id → error, selection unchanged |
| `list_controls` | `section?` | id, range, default, current value |
| `get_develop` | `id?` | Full JSON + `process` |
| `set_develop` | `id?`, `values?`, `settings?`, `label?` | `values: {controlId: number}`; `settings`: partial JSON deep-merged; undoable |
| `apply_preset` | `preset`, `amount?`, `ids?` | amount 0–200; list ids with `list_commands {filter: "preset"}`. Built-ins seen: `lc.golden-hour`, `lc.bw-high-contrast` |
| `crop` | `id?`, `rect?`, `angle?`, `reset?` | `rect` normalized `[x0,y0,x1,y1]`; at least one of the three; the crop always stays inside the photo |
| `render_photo` | `id?`, `size?`, `format?`, `path?` | **Image** PNG (or JPEG with `format: "jpeg"`), long edge `size` (default 1024) |
| `export` | `path` \| `dir`, `id?` \| `ids?`, `format?`, `longEdge?` \| `shortEdge?` \| `width?`/`height?` \| `megapixels?` \| `percent?`, `dontEnlarge?`, `ppi?`, `quality?`, `colorSpace?`, `bitDepth?`, ... | See recipes. Not idempotent: by default an existing name becomes `-2`, `-3`, ... |

Connect mode only (errors with instructions in headless):

| Tool | Arguments | Notes |
|---|---|---|
| `ui_inspect` / `inspect_ui` | — | View, panels, rects, selection, state |
| `ui_screenshot` / `screenshot` | `screenshot {maxSize?, format?, path?}` (`ui_screenshot` without path) | Window as image, after pending renders |
| `set_ui` | `state` | Merge UI state, e.g. `{"view": "detail"}` |
| `list_widgets` / `click` | `filter?` / `widget` \| `x,y`, `count?`, `button?` | Real egui clicks by automation id |
| `press_key` / `type_text` | `key`, `cmd?`, `shift?`, `alt?` / `text` | Keyboard |
| `clipboard` | `action`, `text?` | Cut/copy/paste in the focused text field |
| `pointer_gesture` | `events` | Gestures in normalized image coordinates (brush, gradients, crop handles) |

**One tool per command:** `tools/list` also contains `cmd_<id with _>` for every command (`photo.rate` → `cmd_photo_rate`, `develop.set` → `cmd_develop_set`); with `--compact` they disappear but `run_command` still reaches them. Count: 17 named tools in headless, 28 in connect, plus the `cmd_*`.

**Resources** (JSON snapshots, no subscribe — re-read to poll): `lightcraft://library`, `lightcraft://photos`, `lightcraft://photo/active`, `lightcraft://develop/active`, `lightcraft://controls`, `lightcraft://document` (= `doc_inspect`), `lightcraft://commands` (= `command_list`). No MCP prompts documented.

**Long exports (headless, direct call only):** with `params._meta.progressToken` you get progress notifications; `notifications/cancelled` with `requestId` stops the export before the next photo (already-written photos remain, no partial file).

## Recipes

Import a folder and look at it (MCP):
```json
{"name": "import", "arguments": {"paths": ["/Users/me/Pictures/Shoot"], "album": "Shoot"}}
{"name": "query_photos", "arguments": {"limit": 50}}
```
(Windows paths: `C:\\Users\\me\\Pictures\\Shoot`.)

Rating, flags, metadata (commands via `run_command` or the channel):
```json
{"command": "photo.rate", "params": {"ids": [1, 2, 3], "rating": 5}}
{"command": "photo.flag", "params": {"ids": [1, 3], "flag": "pick"}}
{"command": "photo.setMeta", "params": {"ids": [1], "title": "Sunset", "creator": "Jane Doe", "keywords": ["sea", "coast"]}}
{"command": "library.filter", "params": {"text": "rating:>3 flag:pick iso:>800"}}
```

Develop + preset + visual check:
```json
{"name": "select_photos", "arguments": {"ids": [21]}}
{"name": "set_develop", "arguments": {"values": {"light.highlights": -45, "light.shadows": 38, "effects.clarity": 28, "effects.dehaze": 18}}}
{"name": "apply_preset", "arguments": {"preset": "lc.golden-hour", "amount": 60}}
{"name": "render_photo", "arguments": {"size": 1024}}
```
Other useful commands: `develop.auto` (Auto), `develop.adjust {control, delta}` (relative, clamped), `develop.reset` / `develop.resetSection` / `develop.resetControl`, `develop.wb`, `develop.profile`.

Masks (linear sky gradient + radial, then local adjustments on the selected mask):
```json
{"command": "mask.add", "params": {"kind": "linear", "start": [0.5, 0.0], "end": [0.5, 0.45], "name": "Sky"}}
{"command": "mask.adjust", "params": {"values": {"exposure": -0.6, "temp": 25, "saturation": 20, "dehaze": 20}}}
{"command": "mask.add", "params": {"kind": "radial", "center": [0.62, 0.4], "rx": 0.2, "ry": 0.14, "feather": 70, "name": "Sun glow"}}
{"command": "mask.adjust", "params": {"values": {"exposure": 0.5, "temp": 40}}}
```

AI masks (needs the SAM 3 model; the default CLI is built without AI masks):
```json
{"command": "segment.model.status"}
{"command": "mask.add", "params": {"kind": "prompt", "text": "sky"}}
{"command": "mask.add", "params": {"kind": "object", "points": [[0.4, 0.6]]}}
{"command": "mask.objectPoint", "params": {"x": 0.45, "y": 0.62, "exclude": true}}
```
Coordinates are normalized to the uncropped photo. In the desktop app they answer `{pending: true}` and the mask arrives later: re-read `photo.inspect` → `develop.masks`. Other kinds mentioned: `colorRange`, `luminanceRange` (parameters: check `list_commands {filter: "mask"}`).

AI Denoise (Bayer RAW, user-installed model): `denoise.status`, `denoise.toggle`, then slider `enhance.denoise` (0–100). Commands: `denoise.settings`, `denoise.queue`, `denoise.models.list|install|select...`.

Syncing settings: select the photos with the source active, then `develop.sync`; or `develop.copy` (with `groups`) + `develop.paste`; `develop.pastePrevious` pastes from the previous active photo. Group names are not documented: read them with `list_commands {filter: "develop.copy"}`. Spots, red-eye and process stay per photo.

Export JPEG 2048 px quality 85 (MCP):
```json
{"name": "export", "arguments": {"ids": [1, 3], "dir": "/Users/me/Pictures/Export", "longEdge": 2048, "quality": 85, "colorSpace": "displayP3"}}
```
- With no size parameters: 3000 px long edge; `longEdge: 0` = full resolution (cropped); `dontEnlarge` defaults to true; `width`+`height` fit both orientations.
- Formats: extension `.jpg` / `.png` / `.tif` / `.webp` / `.avif` / `.jxl`; `format: "original"` (copy + XMP), `"dng"` (RAW with embedded edits), `"rendereddng"`. The exact `format` value for JPEG etc. is not in the docs: use the `path` extension or verify.
- Other documented `app.export` parameters: `limitKb`, `bitDepth`, `tiffCompression` (none/lzw/zip), `dngCompression`, `sharpen`, `sharpenAmount`, `metadata`, `removeLocation`, `watermark` (text or object), `naming` (`{name}`, `{seq:N}`, `{date:%Y-%m-%d}`, `{camera}`, ...), `startNumber`, `subfolder`, `conflict: unique|overwrite|skip` (default unique), `preset`, `background: true` (then poll `ui.inspect` → `export`), `hdr`. `addToPhotos` is macOS only.
- Contact sheet PDF: `export.contactSheet path=Contact.pdf paper=a4 columns=3 rows=4 captions=true` (max 1000 photos).

Merge: `merge.hdr {ids?, align, deghost: none|low|medium|high, ...}`, `merge.panorama {ids?, projection, boundaryWarp, autoCrop, ...}`, `merge.hdrPanorama`; the result `<name>-HDR.dng` / `-Pano.dng` is written next to the first photo.

Lightroom Classic catalog (source read-only): `library.inspectLightroom path=...lrcat`, then `library.importLightroom path=...lrcat` (`updateExisting=true` replaces existing edits: ask first).

## CLI
```sh
# headless: import, develop, export
lightcraft-cli run --import ~/Pictures/a.dng develop.set control=light.exposure value=0.7 develop.auto app.export path=~/Pictures/a.jpg shortEdge=1080
# persistent library: edits persist across invocations
lightcraft-cli run --library ~/lc-lib --import ~/Pictures/Shoot library.info
lightcraft-cli run --library ~/lc-lib library.select 'ids=[3]' develop.get
# live app (same commands + ui.* methods)
lightcraft-cli run --connect 127.0.0.1:7980 library.state photo.inspect develop.controls section=light
lightcraft-cli run --connect ui.set view=detail ui.screenshot path=~/Desktop/ui.png
# JSON-lines script: {"command": id, "params": {...}} or {"method": "ui.inspect"}
lightcraft-cli run --demo --script steps.jsonl --keep-going
```
(On Windows call the exe with its full path, e.g. `& "C:\Program Files\LightCraft\lightcraft-cli.exe" run ...`.)

`run` syntax: a word without `=` starts the next command; `key=value` is JSON if parseable, else a string; an argument `'{...}'` merges a JSON object into the params. Quote values with brackets or spaces. Output: one JSON line per command `{"command", "ok", "result"|"error", "ms"}`. In PowerShell JSON quoting is awkward: prefer `--script`.

Other subcommands:
```sh
lightcraft-cli render in.dng -o out.jpg --set light.exposure=0.5 --set light.contrast=20 --size 2048
lightcraft-cli render in.dng -o out.tif --opt colorSpace=displayP3 --opt bitDepth=16 --opt percent=50
lightcraft-cli render in.jpg -o out.png --settings look.json --preset <presetId>
lightcraft-cli commands --json      # command registry
lightcraft-cli controls --json      # develop control ids and ranges
lightcraft-cli snapshot --demo -o grid.png --size 1600x1000
lightcraft-cli merge hdr|panorama|hdr-panorama [options] FILE...
lightcraft-cli calibrate --max 300 <folder>                    # camera color profiles
lightcraft-cli denoise-serve --listen <ip:port>                 # remote denoise server (token in LIGHTCRAFT_DENOISE_TOKEN)
```
`denoise-serve` is not encrypted: LAN/VPN only, never exposed to the internet.

## Control channel
- **Transport:** TCP `127.0.0.1:<port>` (app started with `--control PORT` or `LIGHTCRAFT_CONTROL_PORT`); one JSON request per line, one response per line, in order. No authentication.
- **Request:** `{"id": 1, "method": "engine.execute", "params": {"command": "photo.rate", "params": {"rating": 4}}}`
- **Response:** `{"id": 1, "ok": true, "result": ...}` or `{"id": 2, "ok": false, "error": "unknown command `nope`"}`.
- **Limits:** runs on the UI thread between frames, timeout 60 s; if the app draws no frame for 5 s an unstarted request is dropped (window minimized/hidden: keep it visible or use headless). Max 16 connections, lines ≤ 4 MiB; invalid input → error and connection closed (reconnect). No spontaneous events: poll.

| Method | Params | Result |
|---|---|---|
| `engine.execute` (alias `ui.menu.invoke`) | `{command, params?}` | Runs any engine/UI command |
| `engine.commands` | — | id, label, menu, shortcut, param doc, enabled |
| `ui.menu.list` / `ui.menu.tree` | — | Flat menu entries / menu-bar tree |
| `ui.inspect` | — | UI state, `loupe` (`source`, `pending`, `failed`), selection, perf/GPU, `export`, `import`, `activity`, `notices`, `quitPrompt`, `unsaved`, `libraryProblem`, ... |
| `ui.widgets` | `{filter?}` | On-screen widgets `{id, rect}` |
| `ui.clickWidget` / `ui.dragWidget` / `ui.hoverWidget` | `{id, count?, button?, fx?, fy?}` / `{id, toX?, toY?, dx?, dy?, steps?}` / `{id, fx?, fy?}` | Real egui input on a widget |
| `ui.move` / `ui.click` / `ui.drag` | `{x, y, ...}` / `{x, y, toX, toY, steps?}` | Pointer in screen points |
| `ui.pointer` | `{events: [{kind: down\|drag\|up, x, y}], alt?, shift?, cmd?}` | Gesture in normalized image coordinates (Detail view) |
| `ui.key` / `ui.text` | `{key, cmd?, shift?, alt?, ctrl?}` / `{text}` | Keyboard |
| `ui.clipboard` | `{action: cut\|copy\|paste, text?}` | Clipboard in the focused field |
| `ui.scroll` / `ui.zoom` / `ui.zoomFactor` | `{dx, dy, ...}` / `{factor}` / `{factor}` (0.5–3) | Scroll, pinch, interface scale |
| `ui.set` | Partial UI state (`view`, `right`, `openSections`, `beforeAfter`, `leftPanel`, ...) | Resulting state |
| `ui.dialog.confirm` / `ui.dialog.cancel` | — | Closes the open dialog |
| `ui.resize` | `{width, height}` | Resize the window |
| `ui.screenshot` | `{path?, headless?}` | `{path, width, height}` once renders finish; with no frame for 2 s falls back to CPU |
| `ui.render` | `{id?, size?, path?}` | PNG render of a photo |
| `ui.settle` | `{timeoutMs?}` | (snapshot) waits for no renders in flight |
| `ui.dock` / `ui.dock.reset` | `{operation, panel, ...}` | Panels `library`, `tools`, `presets` (via `engine.execute`) |
| `app.quit` | — | Quit the app |

**Widget ids** (from `ui.widgets`): `slider:effects.clarity`, `button:upright-auto`, `button:noticeOk`, `button:quitAnyway` / `quitCancel` / `quitRetry`, `button:libraryRetry` / `libraryChoose` / `libraryTemporary` / `libraryQuit`, `button:dialogOk` / `dialogCancel`, `indicator:unsaved`, `indicator:temporarySession`, `activity:row:<id>`, `activity:cancel:<id>`, `loupe:rendering`, `loupe:renderFailed`, `icon:appearance`.

**Before a screenshot** of the Detail view, poll `ui.inspect` until `loupe.photo` is the right one, `loupe.source` is `render` or `cached`, and `loupe.pending` is false (or `loupe.failed` is set).

**External controllers / feedback:** `library.state` (selection), `photo.inspect {id?}` (id + develop + rating + flag + history together), `develop.controls {section?}`, `develop.set`, `develop.adjust`, `library.select` / `library.next` / `library.previous`, `edit.undo` / `edit.redo`.

## Commands by family
Partial list of documented ids; for the rest (and for parameters) use `list_commands` / `command_list` / `engine.commands` / `lightcraft-cli commands --json`.

- **library.\*:** `import`, `importPreview`, `select`, `selectAll`, `selectNone`, `selectBy`, `selectOnlyActive`, `next`, `previous`, `filter`, `sort`, `shuffle`, `source`, `state`, `info`, `browse`, `folders`, `findMissing`, `findSimilar`, `buildPreviews`, `smartPreviews`, `xmpPreferences`, `preferences`, `inspectLightroom`, `importLightroom`, `autoImport`, `compact`, `emptyRecentlyDeleted`, `removeFolder`
- **photo.\*:** `rate`, `increaseRating`, `decreaseRating`, `flag`, `pick`, `reject`, `unflag`, `label`, `setMeta`, `inspect`, `rename`, `renameTokens`, `virtualCopy`, `duplicate`, `delete`, `restore`, `deletePermanently` (catalog only, not files), `rotateLeft`, `rotateRight`, `flipHorizontal`, `flipVertical`, `saveMetadataToFile`, `readMetadataFromFile`, `copyMetadata`, `pasteMetadata`, `setCaptureTime`, `moveToFolder`, `relink`, `locate`, `convertToDng`, `editExternal`, `editInPhotoCraft`, `smartPreview`
- **develop.\*:** `set`, `adjust`, `get`, `controls`, `merge`, `auto`, `reset`, `resetSection`, `resetControl`, `wb`, `wbPick`, `profile`, `treatment`, `curve`, `hdr`, `copy`, `paste`, `pastePrevious`, `sync`, `autoSync`, `matchExposure`, `autoBwMix`, `updateProcess`, `sectionEnabled`, `beginInteraction`, `endInteraction`
- **mask.\*:** `add`, `addComponent`, `adjust`, `update`, `select`, `delete`, `duplicate`, `invert`, `rename`, `move`, `visible`, `component`, `brushStroke`, `sampleColor`, `objectPoint`, `refine`, `refineDetail`, `list`; **tool.\*:** `brush`, `linear`, `radial`, `wbPicker`, `guidedUpright`, `done`; **brush.\*:** `larger`, `smaller`, `featherMore`, `featherLess`; **segment.\*:** `prepare`, `model.status`, `model.download`, `model.cancel`
- **crop.\*:** `set`, `aspect`, `straighten`, `autoStraighten`, `rotateAspect`, `reset`, `drag`; **geometry.\*:** `upright`, `guides`
- **spot.\*:** `add` (`mode: heal|clone|remove|fill`), `update`, `delete`, `select`, `findDust`, `findBlemishes`; **redeye.\*:** `add`, `catchlight`, `delete`; **pointColor.\*:** `pick`, `delete`; **curve.\*:** `presets`, `applyPreset`, `savePreset`, `reset`
- **preset.\*:** `apply`, `create`, `update`, `rename`, `delete`, `move`, `favorite`, `import`, `export`; **profile.\*:** `import`, `favorite`, `deleteImported`; **profiles.\*:** `list`, `menu`
- **history.\*:** `list`, `restore`, `next`, `previous`, `clear`; **version.\*:** `create`, `restore`, `update`, `rename`, `delete`; **edit.\*:** `undo`, `redo`; **beforeAfter.\*:** `setBefore`, `swap`, `copyAfterToBefore`, `copyBeforeToAfter`, `resetBefore`
- **album.\*:** `create`, `createSmart`, `addPhotos`, `removePhotos`, `rename`, `delete`, `move`, `sort`, `setRules`, `setCover`; **folder.\*:** `create`, `rename`, `move`, `synchronize`, `scanChanges`, `label`; **stack.\*:** `group`, `ungroup`, `auto`, `setTop`, `toggle`, `expandAll`, `collapseAll`; **keyword.\*:** `create`, `list`, `rename`, `merge`, `delete`, `suggest`, `import`, `export`; **label.\*:** `names`, `setNames`, `sets`, `applySet`; **metadata.\*:** `presets`, `applyPreset`, `reverseGeocode`; **filter.\*:** `presets`, `applyPreset`, `savePreset`
- **app.\*:** `export`, `exportPrevious`, `openLibrary`, `newLibrary`, `settings`, `gpu`, `systemInfo`, `memoryBudget`, `showInFinder`, `openLogFolder`, `quit`; **export.\*:** `contactSheet`, `presets`, `savePreset`, `deletePreset`, `checkTarget`; **file.\*:** `addPhotos`, `addFolder`, `importPresets`, `backupLibrary`, `restoreLibrary`, `findMissing`
- **merge.\*:** `hdr`, `panorama`, `hdrPanorama`, `hdrLast`, `panoramaLast`; **denoise.\*:** `toggle`, `settings`, `queue`, `cancel`, `status`, `pump`, `clear`, `models.*`; **faces.\*:** `detect`, `enable`, `index`, `suggest`, `person`, `unnamed`, `setName`, `nameFaces`, `models.*`; **activity.\*:** `list`, `cancel`
- **view.\*** (UI, connect): `detail`, `photoGrid`, `squareGrid`, `compare`, `survey`, `beforeAfter`, `beforeAfterSplit`, `showOriginal`, `navigate {zoom?: "fit"|"fill"|{percent}, pan?}`, `zoomFit`, `zoom100`, `clipping`, `histogram`, `filmstrip`, `leftPanel`, `filterBar`, `appearance {mode?}`, `theme {theme}`, `fullScreenPreview`, `slideshow`, `softProof`; **panel.\*:** `edit`, `crop`, `masking`, `presets`, `info`, `keywords`, `remove`, `redeye`, `versions`, `activity`; **section.\*:** `light`, `color`, `effects`, `detail`, `optics`; **dialog.\*:** `export`, `copySettings`, `pasteSettings`, `mergeHdr`, `mergePanorama`, `rename`, `contactSheet`, ...

## Recommended workflow
1. **Orient:** `doc_inspect` (or `library.info` / `library.state`) for library, `path`, selection and active photo; in connect mode also `ui_inspect`. Confirm with the user that it is the right library.
2. **Import or open:** `import` (in place by default; `copy`/`move` only if asked) or `query_photos` / `library.filter` to find photos; `select_photos` to fix selection and active photo.
3. **Find commands:** `list_commands {filter}` and `list_controls {section}` before using non-obvious ids or ranges; do not guess parameter names.
4. **Edit:** `set_develop` / `apply_preset` / `mask.*` / `crop` on one photo in small steps; use `develop.beginInteraction`/`endInteraction` for a single undo step; sync to others only after the user's OK.
5. **Verify:** `render_photo` (or `render_preview`) and look at it; in connect mode `ui_screenshot` after waiting for `loupe.pending == false`. Re-read `get_develop` to confirm saved values.
6. **Export only when the user agrees**, to a dedicated output folder, with `conflict: "unique"` (default); never `overwrite` without permission. Originals are never overwritten; do not use `move`, `deletePermanently`, `updateExisting`, `develop.updateProcess` or model downloads without explicit confirmation. When done, close the app started with `--control` (unauthenticated port).
