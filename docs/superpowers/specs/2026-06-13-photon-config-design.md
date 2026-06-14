# Photon Keyboard Config — Design

**Date:** 2026-06-13
**Status:** Approved (pending spec review)

## Goal

Add the CannonKeys **Photon** (a wireless ZMK *board*) to this existing ZMK/Nix
config repo, alongside the existing VOID40 shield. The Photon should run the
stock CannonKeys keymap with one customization: on **both base layers**
(`windows_base_layer` and `mac_base_layer`), the rightmost column becomes
**Delete, Home, PgUp, PgDn, Right arrow**. All other layers (function layers,
control layer) remain stock.

## Background / Key Facts

- This repo is a **ZMK** config built via Nix using `zmk-nix`. It currently
  builds one keyboard: the VOID40 (a ZMK *shield* on a `nice_nano_v2`
  controller).
- The Photon is a self-contained ZMK **board** (`board: photon`), not a shield.
  Its board definition + default keymap live in the CannonKeys ZMK module:
  `github.com/cannonkeys/zmk-cannonkeys-keyboards`, under
  `boards/arm/photon/`.
- The Photon module does **not** run on upstream ZMK. Its `config/west.yml`
  points `zmk` at a fork (`awkannan/zmk@develop`) plus two extra modules:
  `awkannan/zmk-gpio-behavior` and `awkannan/zmk-smart-rgbled-widget`. The
  stock Photon control layer uses `&gpc GP_ON 0` / `&gpc GP_OFF 0`, which come
  from `zmk-gpio-behavior`.

## Integration Approach (Option A)

Switch the whole repo to the CannonKeys ZMK fork. Both keyboards build against
`awkannan/zmk@develop` + the CannonKeys modules. This is what CannonKeys ships,
and the fork is ZMK `develop` plus additions, so the VOID40 (which uses only
standard ZMK behaviors and features — verified) continues to build unchanged.

We use the **module + config override** pattern for the keymap: the Photon
board definition stays upstream in the module; our customized `photon.keymap`
lives in this repo's `config/` directory, which ZMK's config dir prioritizes
over the board's bundled default keymap.

## Stock Rightmost Column → Customized

The Photon base layers have a 5-row rightmost column. Stock vs. desired:

| Row | Stock  | Customized |
|-----|--------|------------|
| 1   | `DEL`  | `DEL`      |
| 2   | `PGUP` | `HOME`     |
| 3   | `PGDN` | `PGUP`     |
| 4   | `END`  | `PGDN`     |
| 5   | `RIGHT`| `RIGHT`    |

Net effect: rows 2–4 change from `PGUP, PGDN, END` to `HOME, PGUP, PGDN`.
Applied identically to `windows_base_layer` and `mac_base_layer`. Function and
control layers untouched.

## Files Changed / Added

### `config/west.yml` (modified)
Replace upstream-ZMK manifest with the CannonKeys fork manifest, merged with
this repo's existing `self: path: config`. Pin revisions to specific commits
for reproducibility, **each annotated with a trailing `# <ref>` comment** so the
existing `deps.yml` auto-updater can advance them weekly (see "Auto-Update"
below):

- `zmk` → remote `awkannan`,
  `revision: 312e4b0a056bcea9615d1355e84a5d1b2927f6ba # develop`,
  `import: app/west.yml`
- `zmk-gpio-behavior` → remote `awkannan`,
  `revision: 174a055e3c991b28942be71706265bfab4672dd6 # main`
- `zmk-smart-rgbled-widget` → remote `awkannan`,
  `revision: 8569005c9444eaf32423546504b77fc6b7fa3d20 # main`
- `zmk-cannonkeys-keyboards` → remote `cannonkeys`,
  `revision: 0b6f02193686573e78a7cb1d6fd768bcf53241d0 # main` — provides the
  `photon` board
- `self: path: config` (unchanged)

Remotes block adds `awkannan` (`https://github.com/awkannan`) and `cannonkeys`
(`https://github.com/cannonkeys`). The `zmkfirmware`/`zephyr` projects are
replaced by the fork's `import: app/west.yml`, which brings in Zephyr etc.

VOID40 keymap/overlay/conf are unchanged and continue to build against the fork.

### `config/photon.keymap` (new)
Copy of the stock `boards/arm/photon/photon.keymap` from the module, with the
rightmost-column edit applied to both base layers. Lives in `config/` so it
overrides the board default. Updated copyright header to match repo style.

### `flake.nix` (modified)
Add a `photon` entry to the `keyboards` attrset, mirroring `void40`:

```nix
photon = {
  board = "photon";
  shield = null;            # board, not shield
  zephyrDepsHash = "";      # placeholder — Nix prints correct hash on first build
  description = "CannonKeys Photon wireless keyboard";
  split = false;
  enableZmkStudio = true;
};
```

`buildKeyboard` must tolerate `shield = null` (pass `shield` only when set).
The existing `void40` entry's `zephyrDepsHash` will also change because the
west manifest now fetches different/additional sources — both hashes get
refreshed on first build.

### `flake.lock` (modified — version bumps)
- `zmk-nix`: `35e44e3…` → `8caca9a74984b56c6c334c34563e86a978f69683`
- `nixpkgs`: `c6a788f…` → `5a722a7155bfc9fbe657f28d26b71860d95324bc`

(Done via `nix flake update`, which rewrites `flake.lock` to latest.)

### `.github/workflows/ci.yml` (modified)
The current build step runs a bare `nix build` (line 21), which resolves to the
default package — fine with one keyboard, but with two it builds only one and
won't exercise the Photon. Change it to build both keyboards explicitly so every
PR (including the weekly auto-update PRs from `deps.yml`/`flake.yml`) verifies
both:

```yaml
- run: nix -vL --show-trace build .#void40 .#photon
```

Adjust the `upload-artifact` step's `path` accordingly (both `result*` symlinks,
or drop artifact upload to the default). The `flake check` step is unchanged.

## Auto-Update

No new workflow is needed. The repo already has two weekly cron workflows that
together satisfy the auto-update requirement:

- **`.github/workflows/deps.yml`** runs `nix run .#update` (zmk-nix's updater),
  which rewrites `config/west.yml` revisions. The updater advances any project
  whose `revision` line carries a trailing `# <ref>` comment, by running
  `git ls-remote <url> <ref>` and pinning to that ref's current HEAD — then
  refreshes the `zephyrDepsHash`. Projects **without** a `# <ref>` comment are
  skipped. This is why every new west project above carries a `# develop` or
  `# main` annotation (matching the existing `void40` pattern).
- **`.github/workflows/flake.yml`** runs `update-flake-lock`, advancing
  `zmk-nix` and `nixpkgs` in `flake.lock`.

Both open reviewable PRs and trigger `ci.yml` to build before merge. Because
`ci.yml` is updated to build both keyboards explicitly (see above), these
auto-update PRs verify the Photon build too. Net result: reproducible commit
pins today, automatic weekly advancement under review.

## Build Behavior

- First `nix build .#photon` (and `.#void40`) will fail with a
  `zephyrDepsHash` mismatch and print the correct `sha256-…`. Paste those into
  `flake.nix` and rebuild. This is expected Nix fixed-output-derivation flow.
- Photon builds with `enableZmkStudio = true` and the `zmk-usb-logging`
  snippet, matching VOID40 conventions.

## Out of Scope (YAGNI)

- No per-keyboard west manifests / repo restructuring (rejected Option B).
- No changes to VOID40 keymap or hardware config.
- No edits to Photon function or control layers.
- No encoder/RGB/LED customization — stock behavior retained.

## Verification

- `nix build .#void40` succeeds (regression check against the fork).
- `nix build .#photon` succeeds and produces `photon-firmware`.
- Inspect built/!merged `photon.keymap`: both base layers show rightmost column
  `DEL / HOME / PGUP / PGDN / RIGHT`; function + control layers byte-identical
  to upstream stock.
