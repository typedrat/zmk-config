# Photon Keyboard Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the CannonKeys Photon (a wireless ZMK board) to this ZMK/Nix config repo with a customized base-layer rightmost column, alongside the existing VOID40.

**Architecture:** Switch the repo's `config/west.yml` to the CannonKeys ZMK fork (`awkannan/zmk@develop`) plus the `zmk-gpio-behavior`, `zmk-smart-rgbled-widget`, and `zmk-cannonkeys-keyboards` modules. The Photon board definition stays upstream in the module; a customized `config/photon.keymap` overrides the board's default keymap. The Nix flake gains a `photon` package mirroring `void40`. Existing weekly auto-update workflows advance the new commit pins.

**Tech Stack:** ZMK (Zephyr/devicetree), west manifest, Nix flakes (`zmk-nix`), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-06-13-photon-config-design.md`

---

## Important context

- **This is a firmware repo with no unit-test framework.** "Tests" here are build-based verification (`nix build`) and file-content assertions (`grep`/`diff`). Steps are still small and verifiable.
- **First builds intentionally fail** with `zephyrDepsHash` mismatches and print the correct `sha256-...`. This is the normal Nix fixed-output-derivation flow and is handled explicitly in Task 5.
- Run all commands from the repo root: `/home/awilliams/Development/zmk-config`.
- Nix must be available with flakes enabled. If a `nix` command complains about experimental features, prefix with `NIX_CONFIG='extra-experimental-features = nix-command flakes'`.

---

## File Structure

- `config/west.yml` — **modify**: replace upstream-ZMK manifest with the CannonKeys fork + modules manifest, keeping `self: path: config`. Each project revision carries a `# <ref>` comment for the auto-updater.
- `config/photon.keymap` — **create**: stock Photon keymap with the rightmost column on both base layers changed to `DEL / HOME / PGUP / PGDN / RIGHT`.
- `flake.nix` — **modify**: add `photon` keyboard entry; make `buildKeyboard` tolerate `shield = null`.
- `flake.lock` — **modify**: bump `zmk-nix` and `nixpkgs` via `nix flake update`.
- `.github/workflows/ci.yml` — **modify**: build both `.#void40` and `.#photon`; upload both artifacts.

---

## Task 1: Switch west.yml to the CannonKeys fork manifest

**Files:**
- Modify: `config/west.yml` (replace entire contents)

- [ ] **Step 1: Replace `config/west.yml` with the fork manifest**

Overwrite the entire file with exactly this content:

```yaml
manifest:
  remotes:
    - name: awkannan
      url-base: https://github.com/awkannan
    - name: cannonkeys
      url-base: https://github.com/cannonkeys
  projects:
    - name: zmk
      remote: awkannan
      revision: 312e4b0a056bcea9615d1355e84a5d1b2927f6ba # develop
      import: app/west.yml
    - name: zmk-gpio-behavior
      remote: awkannan
      revision: 174a055e3c991b28942be71706265bfab4672dd6 # main
    - name: zmk-smart-rgbled-widget
      remote: awkannan
      revision: 8569005c9444eaf32423546504b77fc6b7fa3d20 # main
    - name: zmk-cannonkeys-keyboards
      remote: cannonkeys
      revision: 0b6f02193686573e78a7cb1d6fd768bcf53241d0 # main
  self:
    path: config
```

- [ ] **Step 2: Verify YAML is well-formed and pins are present**

Run:
```bash
grep -nE '# (develop|main)$' config/west.yml
```
Expected: 4 lines, one per project revision (the `# develop` line for `zmk` and three `# main` lines). Each project line ending in a `# <ref>` comment is what lets the auto-updater advance it.

- [ ] **Step 3: Commit**

```bash
git add config/west.yml
git commit -m "config: switch west.yml to CannonKeys ZMK fork + modules"
```

---

## Task 2: Add the customized Photon keymap

**Files:**
- Create: `config/photon.keymap`

This is the stock `boards/arm/photon/photon.keymap` from the CannonKeys module, with:
- The copyright header updated to repo style (matching `config/void40.keymap`).
- The rightmost column of **both base layers** changed: row 2 `PGUP`→`HOME`, row 3 `PGDN`→`PGUP`, row 4 `END`→`PGDN`. Rows 1 (`DEL`) and 5 (`RIGHT`) unchanged. Function and control layers are byte-identical to stock.

- [ ] **Step 1: Create `config/photon.keymap` with this exact content**

```dts
/*
 * Copyright (c) 2024 CannonKeys LLC
 * Copyright (c) 2025 Alexis Williams
 *
 * SPDX-License-Identifier: MIT
 */

#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>
#include <dt-bindings/zmk/rgb.h>
#include <dt-bindings/zmk/bt.h>

/ {
    keymap {
        compatible = "zmk,keymap";

        windows_base_layer {
            display-name = "Base Win";
            bindings = <
    &kp ESC   &kp N1    &kp N2    &kp N3    &kp N4    &kp N5    &kp N6    &kp N7    &kp N8    &kp N9    &kp N0    &kp MINUS &kp EQUAL  &kp BSPC  &kp DEL
    &kp TAB   &kp Q     &kp W     &kp E     &kp R     &kp T     &kp Y     &kp U     &kp I     &kp O     &kp P     &kp LBKT  &kp RBKT   &kp BSLH  &kp HOME
    &kp CLCK  &kp A     &kp S     &kp D     &kp F     &kp G     &kp H     &kp J     &kp K     &kp L     &kp SEMI  &kp SQT              &kp RET   &kp PGUP
    &kp LSHFT           &kp Z     &kp X     &kp C     &kp V     &kp B     &kp N     &kp M     &kp COMMA &kp DOT   &kp FSLH  &kp RSHFT  &kp UP    &kp PGDN
    &kp LCTRL &kp LGUI  &kp LALT                                &kp SPACE                               &kp RALT  &mo 1     &kp LEFT   &kp DOWN  &kp RIGHT
                >;
            sensor-bindings = <&inc_dec_kp C_VOL_DN C_VOL_UP>;
        };

        windows_function_layer {
            display-name = "Function Win";
            bindings = <
    &kp GRAVE &kp F1    &kp F2    &kp F3    &kp F4    &kp F5    &kp F6    &kp F7    &kp F8    &kp F9    &kp F10   &kp F11   &kp F12   &kp DEL   &kp INS  
    &rgb_ug RGB_TOG     &trans    &kp PGUP  &trans  &trans    &trans    &trans    &trans    &kp PGUP  &trans    &trans    &trans    &trans    &trans  &kp C_BRI_UP   
    &trans    &kp HOME  &kp PGDN  &kp END  &trans &trans    &trans    &kp HOME  &kp PGDN  &kp END   &trans    &trans              &trans      &kp C_BRI_DN 
    &trans              &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &kp C_VOL_UP    &kp C_MUTE   
    &trans    &trans    &trans                                  &kp C_PP                             &mo 4     &trans    &kp C_PREV    &kp C_VOL_DN    &kp C_NEXT
            >;
        };

        mac_base_layer {
            display-name = "Base Mac";
            bindings = <
    &kp ESC   &kp N1    &kp N2    &kp N3    &kp N4    &kp N5    &kp N6    &kp N7    &kp N8    &kp N9    &kp N0    &kp MINUS &kp EQUAL  &kp BSPC  &kp DEL
    &kp TAB   &kp Q     &kp W     &kp E     &kp R     &kp T     &kp Y     &kp U     &kp I     &kp O     &kp P     &kp LBKT  &kp RBKT   &kp BSLH  &kp HOME
    &kp CLCK  &kp A     &kp S     &kp D     &kp F     &kp G     &kp H     &kp J     &kp K     &kp L     &kp SEMI  &kp SQT              &kp RET   &kp PGUP
    &kp LSHFT           &kp Z     &kp X     &kp C     &kp V     &kp B     &kp N     &kp M     &kp COMMA &kp DOT   &kp FSLH  &kp RSHFT  &kp UP    &kp PGDN
    &kp LCTRL &kp LALT  &kp LCMD                                &kp SPACE                               &kp RCMD  &mo 3     &kp LEFT   &kp DOWN  &kp RIGHT
                >;
            sensor-bindings = <&inc_dec_kp C_VOL_DN C_VOL_UP>;

        };

        mac_function_layer {
            display-name = "Function Mac";
            bindings = <
    &kp GRAVE   &kp C_BRI_UP   &kp C_BRI_DN   &kp C_AC_DESKTOP_SHOW_ALL_WINDOWS   &kp C_AC_DESKTOP_SHOW_ALL_APPLICATIONS    &kp C_AC_SEARCH    &kp C_PWR    &kp C_PREV    &kp C_PP    &kp C_NEXT    &kp C_MUTE    &kp C_VOL_DN    &kp C_VOL_UP    &kp DEL    &kp INS 
    &rgb_ug RGB_TOG   &trans   &kp PGUP   &trans &trans   &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans   
    &trans   &kp HOME   &kp PGDN   &kp END   &trans &trans    &trans    &trans    &trans    &trans    &trans    &trans              &trans    &trans  
    &trans            &trans   &trans   &trans   &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans  
    &trans   &trans   &trans                               &trans                                  &mo 4     &trans    &trans    &trans    &trans
            >;
        };


        control_layer {
            display-name = "Keyboard Control";
            bindings = <
    &bt BT_CLR_ALL &kp F1    &kp F2    &kp F3    &kp F4    &kp F5    &kp F6    &kp F7    &kp F8    &kp F9    &kp F10   &kp F11   &kp F12   &kp DEL   &bt BT_CLR  
    &rgb_ug RGB_TOG &rgb_ug RGB_EFF &rgb_ug RGB_HUI &rgb_ug RGB_SAI  &rgb_ug RGB_BRI &rgb_ug RGB_SPI &trans    &trans    &trans    &trans    &trans    &trans    &trans    &trans    &bt BT_SEL 0   
    &trans          &rgb_ug RGB_EFR &rgb_ug RGB_HUD &rgb_ug RGB_SAD  &rgb_ug RGB_BRD &rgb_ug RGB_SPD &trans    &trans    &trans    &trans    &trans    &trans    &studio_unlock      &bt BT_SEL 1   
    &trans                          &trans          &trans           &trans          &trans          &trans    &trans    &trans    &trans    &trans    &trans    &trans    &gpc GP_ON 0    &bt BT_SEL 2 
    &bootloader     &trans          &trans                                                           &rgb_ug RGB_TOG                         &trans    &trans    &trans    &gpc GP_OFF 0   &bt BT_SEL 3
            >;
        };

    };
};
```

- [ ] **Step 2: Verify the base-layer rightmost column was edited correctly**

Run:
```bash
grep -nE 'kp (HOME|PGUP|PGDN)$' config/photon.keymap
```
Expected: exactly 6 matches — for each base layer (windows + mac), the three lines ending in `&kp HOME`, `&kp PGUP`, `&kp PGDN` (rows 2/3/4). The function/control layers do not end their lines in those tokens, so they won't match.

- [ ] **Step 3: Verify no stray `&kp END` remains as a base-layer rightmost key**

Run:
```bash
grep -nE 'RSHFT  &kp UP    &kp PGDN$' config/photon.keymap
```
Expected: 2 matches (row 4 of each base layer now ends in `&kp PGDN`, not `&kp END`).

- [ ] **Step 4: Commit**

```bash
git add config/photon.keymap
git commit -m "config: add Photon keymap with customized base-layer right column"
```

---

## Task 3: Add the Photon to the Nix flake

**Files:**
- Modify: `flake.nix` (add `photon` to `keyboards`; make `buildKeyboard` handle `shield = null`)

The current `buildKeyboard` always passes `shield = config.shield;` to the build function. The Photon is a board with no shield, so we must only pass `shield` when it is non-null. We do this by building the build arguments conditionally.

- [ ] **Step 1: Add the `photon` entry to the `keyboards` attrset**

In `flake.nix`, find the `keyboards = { ... };` block (currently containing only `void40`). Add a `photon` entry and add `shield` to `void40` explicitly so both entries have the same shape. Replace:

```nix
    keyboards = {
      void40 = {
        board = "nice_nano_v2";
        shield = "void40";
        zephyrDepsHash = "sha256-79/rYCtUDlC0K4ARO9MSEaCcI1RQSsv7MCeayVZSwtQ=";
        description = "VOID40 custom hand-wired keyboard";
        split = false;
        enableZmkStudio = true;
      };
    };
```

with:

```nix
    keyboards = {
      void40 = {
        board = "nice_nano_v2";
        shield = "void40";
        zephyrDepsHash = "sha256-79/rYCtUDlC0K4ARO9MSEaCcI1RQSsv7MCeayVZSwtQ=";
        description = "VOID40 custom hand-wired keyboard";
        split = false;
        enableZmkStudio = true;
      };
      photon = {
        board = "photon";
        shield = null;
        zephyrDepsHash = "";
        description = "CannonKeys Photon wireless keyboard";
        split = false;
        enableZmkStudio = true;
      };
    };
```

- [ ] **Step 2: Make `buildKeyboard` pass `shield` only when set**

In `flake.nix`, find the `firmware = (buildFunction { ... })` block. It currently hardcodes `shield = config.shield;`. Replace the whole `firmware` binding:

```nix
      firmware =
        (buildFunction {
          name = "${name}-firmware";

          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".board"
            ".cmake"
            ".conf"
            ".defconfig"
            ".dts"
            ".dtsi"
            ".json"
            ".keymap"
            ".overlay"
            ".shield"
            ".yml"
            "_defconfig"
          ];

          board = config.board;
          shield = config.shield;
          zephyrDepsHash = config.zephyrDepsHash;
          enableZmkStudio = config.enableZmkStudio;
          snippets = ["zmk-usb-logging"];

          meta = {
            description = config.description;
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        }).overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [nixpkgs.legacyPackages.${system}.dtc];
        });
```

with this version, which builds the argument set conditionally so `shield` is omitted when `null`:

```nix
      baseArgs = {
        name = "${name}-firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [
          ".board"
          ".cmake"
          ".conf"
          ".defconfig"
          ".dts"
          ".dtsi"
          ".json"
          ".keymap"
          ".overlay"
          ".shield"
          ".yml"
          "_defconfig"
        ];

        board = config.board;
        zephyrDepsHash = config.zephyrDepsHash;
        enableZmkStudio = config.enableZmkStudio;
        snippets = ["zmk-usb-logging"];

        meta = {
          description = config.description;
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      firmware =
        (buildFunction (
          baseArgs
          // nixpkgs.lib.optionalAttrs (config.shield != null) {
            shield = config.shield;
          }
        )).overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [nixpkgs.legacyPackages.${system}.dtc];
        });
```

- [ ] **Step 3: Verify the flake evaluates (structure check, before dep updates)**

Run:
```bash
nix flake show 2>&1 | grep -E 'void40|photon' || true
```
Expected: both `void40` and `photon` appear as packages. If you instead see an evaluation error mentioning the `zephyrDepsHash` being empty, that is acceptable at this stage — the empty hash only matters at build time (Task 5), not for `flake show`. If `nix flake show` errors for another reason (syntax), fix the edit before continuing.

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "nix: add photon keyboard package, support shieldless boards"
```

---

## Task 4: Bump flake inputs (zmk-nix, nixpkgs)

**Files:**
- Modify: `flake.lock`

- [ ] **Step 1: Update flake inputs to latest**

Run:
```bash
nix flake update
```
This rewrites `flake.lock`, advancing `zmk-nix` and `nixpkgs` to their latest locked revisions.

- [ ] **Step 2: Verify the lock advanced**

Run:
```bash
grep -E '"rev"' flake.lock
```
Expected: the `zmk-nix` rev is no longer `35e44e305606c4304e0d6dd8286380f674bfdb22` and `nixpkgs` rev is no longer `c6a788f552b7b7af703b1a29802a7233c0067908` (they should be newer commits). If a network/eval error occurs, resolve connectivity and retry.

- [ ] **Step 3: Commit**

```bash
git add flake.lock
git commit -m "flake: update inputs (zmk-nix, nixpkgs)"
```

---

## Task 5: Build both keyboards and pin the dep hashes

**Files:**
- Modify: `flake.nix` (fill in both `zephyrDepsHash` values from build output)

Switching to the fork changes the west-fetched sources, so **both** keyboards' `zephyrDepsHash` values are now wrong. Nix will print the correct hash on first build. Do the Photon first (its hash is an empty placeholder), then re-check void40.

- [ ] **Step 1: Attempt the Photon build to learn its correct hash**

Run:
```bash
nix build -L .#photon 2>&1 | tee /tmp/photon-build.log | tail -30
```
Expected: the build fails with a fixed-output-derivation hash mismatch, printing lines like:
```
        specified: sha256-AAAA...
           got:    sha256-<REAL_HASH>
```
Copy the `got:` value.

- [ ] **Step 2: Set the Photon `zephyrDepsHash`**

In `flake.nix`, replace the photon entry's `zephyrDepsHash = "";` with the real hash from Step 1:

```nix
        zephyrDepsHash = "sha256-<REAL_HASH_FROM_STEP_1>";
```

- [ ] **Step 3: Rebuild the Photon to confirm it now fetches deps**

Run:
```bash
nix build -L .#photon 2>&1 | tee /tmp/photon-build2.log | tail -30
```
Expected: the dep-fetch step now succeeds (no hash mismatch). The build proceeds to compile firmware. If the full build succeeds, you'll get a `result` symlink. If it fails *later* for a non-hash reason, capture the error for investigation (do not proceed to commit).

- [ ] **Step 4: Attempt the void40 build to learn its (now-changed) hash**

Run:
```bash
nix build -L .#void40 2>&1 | tee /tmp/void40-build.log | tail -30
```
Expected: a hash mismatch (the void40 hash changed because the west manifest changed). Copy the new `got:` value. If, instead, void40 builds successfully with the existing hash, skip Step 5.

- [ ] **Step 5: Update the void40 `zephyrDepsHash`**

In `flake.nix`, replace the void40 entry's `zephyrDepsHash = "sha256-79/rYCtUDlC0K4ARO9MSEaCcI1RQSsv7MCeayVZSwtQ=";` with the new hash from Step 4:

```nix
        zephyrDepsHash = "sha256-<NEW_VOID40_HASH_FROM_STEP_4>";
```

- [ ] **Step 6: Build both keyboards to confirm green**

Run:
```bash
nix build -L .#void40 && nix build -L .#photon && echo "BOTH OK"
```
Expected: `BOTH OK` printed, no hash mismatches, both produce firmware.

- [ ] **Step 7: Commit**

```bash
git add flake.nix
git commit -m "nix: pin zephyrDepsHash for photon and void40 against fork"
```

---

## Task 6: Build both keyboards in CI

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.gitignore` (ignore the named out-links)

The current build step runs a bare `nix build`, which resolves to a single default package. With two keyboards we must build both explicitly so PRs (including the weekly auto-update PRs) verify the Photon too. We name the out-links `result-void40`/`result-photon`; add them to `.gitignore` so they never get committed.

- [ ] **Step 1: Update the build + artifact steps**

In `.github/workflows/ci.yml`, replace this block:

```yaml
      - run: nix -vL --show-trace flake check

      - run: nix -vL --show-trace build

      - uses: actions/upload-artifact@v4
        with:
          name: zmk_firmware
          path: result
```

with:

```yaml
      - run: nix -vL --show-trace flake check

      - run: nix -vL --show-trace build .#void40 --out-link result-void40

      - run: nix -vL --show-trace build .#photon --out-link result-photon

      - uses: actions/upload-artifact@v4
        with:
          name: zmk_firmware
          path: |
            result-void40
            result-photon
```

- [ ] **Step 2: Add the named out-links to `.gitignore`**

The current `.gitignore` ignores `result` but not `result-void40`/`result-photon`. Append two lines so they read:

```gitignore
/.west
/modules
/zephyr
/zmk
/build
result
result-void40
result-photon
```

- [ ] **Step 3: Verify the workflow references both keyboards**

Run:
```bash
grep -nE '\.#(void40|photon)' .github/workflows/ci.yml
```
Expected: two matches — one `.#void40` build line and one `.#photon` build line.

- [ ] **Step 4: Confirm both out-links build locally (mirrors CI)**

Run:
```bash
nix -vL build .#void40 --out-link result-void40 && \
nix -vL build .#photon --out-link result-photon && \
ls -l result-void40 result-photon
```
Expected: both symlinks exist and point into the Nix store. They are now covered by `.gitignore`.

- [ ] **Step 5: Clean up local out-links and commit**

```bash
rm -f result-void40 result-photon
git add .github/workflows/ci.yml .gitignore
git commit -m "ci: build both void40 and photon firmware"
```

---

## Task 7: Final verification

- [ ] **Step 1: Confirm the working tree is clean and all tasks committed**

Run:
```bash
git status --short
```
Expected: empty output (no uncommitted changes, no stray `result-*` links).

- [ ] **Step 2: Full build of both keyboards from clean**

Run:
```bash
nix build -L .#void40 && nix build -L .#photon && echo "ALL GREEN"
```
Expected: `ALL GREEN`.

- [ ] **Step 3: Confirm the Photon keymap customization is present in the built config**

Run:
```bash
grep -cE 'kp (HOME|PGUP|PGDN)$' config/photon.keymap
```
Expected: `6` (three customized base-layer rows × two base layers).

- [ ] **Step 4: Review the full diff against the starting point**

Run:
```bash
git log --oneline -7
git diff HEAD~6 --stat
```
Expected: commits for west.yml, photon.keymap, flake.nix (photon entry), flake.lock, flake.nix (hashes), and ci.yml. The stat should show only the six intended files touched (`config/west.yml`, `config/photon.keymap`, `flake.nix`, `flake.lock`, `.github/workflows/ci.yml`, `.gitignore`), plus the plan/spec docs.
