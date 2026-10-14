# ArtCraft skills for Claude

Skills for the 13 apps of the [ArtCraft suite](https://github.com/storytold) (open-source, Rust, clean-room alternatives to Excel, Word, PowerPoint, Photoshop, Illustrator, Lightroom, InDesign, Acrobat, AutoCAD, Figma, Premiere Pro, After Effects and Pro Tools).

Each skill does two things:
1. **Teaches Claude to drive the app** through MCP, the app's CLI or its control channel: every action is a command id plus JSON parameters.
2. **Knows how to create the MCP server and guides you through it**, on **Windows and macOS**: check, install, launcher, config, authentication, verification, troubleshooting.

Unofficial community packaging, not affiliated with storytold. English, generic, MIT licensed.

## Pick your skills

| App | What it is | Repo | Skill zip | id |
|---|---|---|---|---|
| [EffectCraft](https://github.com/Vinciux99/effectcraft-claude-skill) | After Effects-style motion graphics and compositing (.ecproj) | [repo](https://github.com/Vinciux99/effectcraft-claude-skill) | [zip](dist/effectcraft-skill.zip) | `effectcraft` |
| [FilmCraft](https://github.com/Vinciux99/filmcraft-claude-skill) | Premiere Pro-style video editor | [repo](https://github.com/Vinciux99/filmcraft-claude-skill) | [zip](dist/filmcraft-skill.zip) | `filmcraft` |
| [PhotoCraft](https://github.com/Vinciux99/photocraft-claude-skill) | Photoshop-style raster image editor | [repo](https://github.com/Vinciux99/photocraft-claude-skill) | [zip](dist/photocraft-skill.zip) | `photocraft` |
| [VectorCraft](https://github.com/Vinciux99/vectorcraft-claude-skill) | Illustrator-style vector graphics editor | [repo](https://github.com/Vinciux99/vectorcraft-claude-skill) | [zip](dist/vectorcraft-skill.zip) | `vectorcraft` |
| [LightCraft](https://github.com/Vinciux99/lightcraft-claude-skill) | Lightroom-style photo library and RAW developer | [repo](https://github.com/Vinciux99/lightcraft-claude-skill) | [zip](dist/lightcraft-skill.zip) | `lightcraft` |
| [DesignCraft](https://github.com/Vinciux99/designcraft-claude-skill) | InDesign-style page layout and publishing | [repo](https://github.com/Vinciux99/designcraft-claude-skill) | [zip](dist/designcraft-skill.zip) | `designcraft` |
| [PdfCraft](https://github.com/Vinciux99/pdfcraft-claude-skill) | Acrobat-style PDF viewer and editor | [repo](https://github.com/Vinciux99/pdfcraft-claude-skill) | [zip](dist/pdfcraft-skill.zip) | `pdfcraft` |
| [CADCraft](https://github.com/Vinciux99/cadcraft-claude-skill) | AutoCAD-style 2D/3D CAD (DXF/DWG) | [repo](https://github.com/Vinciux99/cadcraft-claude-skill) | [zip](dist/cadcraft-skill.zip) | `cadcraft` |
| [DeckCraft](https://github.com/Vinciux99/deckcraft-claude-skill) | PowerPoint-style presentations (.pptx) | [repo](https://github.com/Vinciux99/deckcraft-claude-skill) | [zip](dist/deckcraft-skill.zip) | `deckcraft` |
| [FigCraft](https://github.com/Vinciux99/figcraft-claude-skill) | Figma-style interface and prototype design | [repo](https://github.com/Vinciux99/figcraft-claude-skill) | [zip](dist/figcraft-skill.zip) | `figcraft` |
| [GridCraft](https://github.com/Vinciux99/gridcraft-claude-skill) | Excel-style spreadsheets (.xlsx) | [repo](https://github.com/Vinciux99/gridcraft-claude-skill) | [zip](dist/gridcraft-skill.zip) | `gridcraft` |
| [SoundCraft](https://github.com/Vinciux99/soundcraft-claude-skill) | Pro Tools-style digital audio workstation | [repo](https://github.com/Vinciux99/soundcraft-claude-skill) | [zip](dist/soundcraft-skill.zip) | `soundcraft` |
| [WordCraft](https://github.com/Vinciux99/wordcraft-claude-skill) | Word-style document editor (.docx) | [repo](https://github.com/Vinciux99/wordcraft-claude-skill) | [zip](dist/wordcraft-skill.zip) | `wordcraft` |

- **Everything at once:** [`dist/all-artcraft-skills.zip`](dist/all-artcraft-skills.zip) (13 folders, each with a `SKILL.md`).
- **Choose with checkboxes:** open [`index.html`](index.html) (enable GitHub Pages for this repo to use it online, or open the file locally), tick the apps, download one bundle, or jump to each repo.

## Install

Prerequisite: install the app(s) you want from their upstream releases (Windows `.msi`, macOS `.dmg`) and Claude Desktop and/or Claude Code.

### A. One command: skill + MCP server + launcher

Windows (PowerShell), one or more ids, comma-separated, or `all`:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.ps1))) -Apps gridcraft,wordcraft"
```
macOS (Terminal):
```sh
curl -fsSL https://raw.githubusercontent.com/Vinciux99/artcraft-claude-skills/main/install.sh | bash -s -- --apps gridcraft,wordcraft
```
Options: `-Mode live|headless|both` / `--mode ...`, `-DryRun` / `--dry-run` (preview, changes nothing), `-NoLauncher`, `-NoClaudeDesktop`, `-NoClaudeCode`, `-NoSkill` (macOS: `--no-launcher`, `--no-claude-desktop`, `--no-claude-code`, `--no-skill`).

For each app it: finds the app and its CLI (macOS: downloads the CLI from the app's latest release if needed), creates the **"<App> (Claude)"** launcher, backs up and updates Claude Desktop's config, registers the server in Claude Code, and installs the skill into `~/.claude/skills/`. Then **fully quit and reopen Claude** and start the app with its launcher.

### B. Claude Code plugins
```
/plugin marketplace add Vinciux99/artcraft-claude-skills
/plugin install gridcraft@artcraft
```

### C. Claude app (claude.ai / Desktop)
Download the skill zip, then Customize > Skills > "+" > Create skill > Upload a skill (needs Settings > Capabilities > "Code execution and file creation" on).

### D. Just ask Claude
With a skill installed say "set up the GridCraft MCP server": the skill walks you through it step by step.

## Ports (so all 13 can run at once)
effectcraft 9877, filmcraft 9876, photocraft 7878, vectorcraft 7979, lightcraft 7980, designcraft 7981, cadcraft 7982, figcraft 7984, gridcraft 7985, wordcraft 7987, deckcraft 7990, soundcraft 7801; pdfcraft uses a control file instead of a port.

## Repository layout
```
install.ps1 / install.sh     one-command installers (-Apps / --apps)
index.html                   skill picker
dist/                        per-app skill zips and all-artcraft-skills.zip
plugins/<id>/                Claude Code plugin per skill (marketplace source)
apps/<id>/app.json           per-app settings read by the setup scripts
scripts/                     shared setup scripts
.claude-plugin/marketplace.json
```
Each app also has its own repository with the same skill, README, scripts and CI release.

## CI
Validates every skill and `app.json`, checks the installers' syntax and rebuilds the zips on each push; each push to `main` publishes or updates a release with all zips.

## Caveats
Windows arguments come from a working install; macOS paths follow upstream packaging but are **unverified** on a real Mac. The ArtCraft apps are young projects; `list_commands` is the source of truth.
