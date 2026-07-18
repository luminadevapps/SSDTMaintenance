# SSDT Maintenance

**SSDT generator & maintenance suite for macOS (OpenCore Hackintosh).**

SSDT Maintenance is a native macOS app that generates clean, OpenCore-ready
SSDTs — including the essential **macOS-support maintenance tables** — and
compiles them to `.aml` locally with `iasl`. Built for modern Intel desktops
(Alder Lake / Raptor Lake, Z690 / Z790 and similar 300-series-and-newer boards).

Developed by **[Lumina Dev Apps](https://luminadevapps.com)** — a division of
Direct Parcel Distributors Inc.

---

## Features

- **One-click generation** — configure your paths and hardware, hit *Generate
  ALL SSDTs*, and every enabled table is written as `.dsl` and compiled to
  `.aml` automatically.
- **Live compile log** with a **Copy Log** button and selectable text.
- **Output folder picker** in the bottom bar; full-width single-window layout.
- **Editable ACPI paths** and hardware presets (iGPU, dGPU, LAN, Wi-Fi,
  Thunderbolt, USB, SATA, NVMe, audio layout IDs).

### Device SSDTs

| SSDT | Purpose |
|------|---------|
| `SSDT-PLUG` | CPU power management (`plugin-type`) — auto-sized to your core count |
| `SSDT-DTPG` | `DTGP` helper method used by other tables |
| `SSDT-HDEF` | Onboard audio (layout-id / alc-layout-id injection) |
| `SSDT-IGPU` | Intel integrated graphics (Alder/Raptor Lake, headless) |
| `SSDT-GPU`  | Discrete GPU + HDAU audio (AMD RDNA2 / Vega) |
| `SSDT-LAN`  | Ethernet (Aquantia AQC107, Realtek, Intel I225/I226) |
| `SSDT-WIFI` | Wi-Fi (Intel itlwm / Broadcom) |
| `SSDT-TB3`  | Thunderbolt (Titan Ridge / Maple Ridge) |
| `SSDT-XHCI` | USB port map (15 / 20 / 25 / 30 / Type-C layouts) |
| `SSDT-SATA` | SATA / AHCI controller |
| `SSDT-NVME` | NVMe SSD properties |

### Maintenance SSDTs (macOS support) — new in v1.1.0

Toggleable in the **Maintenance (macOS Support)** section. The first five are
on by default; the rest are situational.

| SSDT | Purpose | Default | ACPI rename |
|------|---------|:------:|-------------|
| `SSDT-AWAC` | System clock fix (RTC/AWAC) — required on Z690/Z790 | ✅ | — |
| `SSDT-PMC` | Native NVRAM for 300-series+ | ✅ | — |
| `SSDT-USBX` | USB sleep/wake power properties | ✅ | — |
| `SSDT-EC` | Fake Embedded Controller | ✅ | `EC → EC0` (if board's EC is named `EC`) |
| `SSDT-SBUS-MCHC` | SMBus + Memory Controller Hub | ✅ | — |
| `SSDT-PNLF` | Backlight control (iGPU display) | — | — |
| `SSDT-GPRW` | Instant-wake-from-sleep fix | — | `_GPRW → XGPW` (required) |
| `SSDT-RHUB` | USB root-hub reset (port re-enumeration) | — | — |
| `SSDT-ALS0` | Fake ambient light sensor stub | — | — |
| `SSDT-BRG0` | PCI bridge `_ADR` template (advanced) | — | — |

---

## Requirements

- **macOS 13.0+**
- **`iasl`** (the ACPI compiler), for the compile step:

  ```bash
  brew install acpica
  ```

  The app looks for `iasl` at `/usr/bin`, `/usr/local/bin`, or
  `/opt/homebrew/bin`.

---

## Building from source

1. Open `SSDTMaintenance.xcodeproj` in **Xcode 16** (the project uses
   file-system-synchronized groups — new files in `Core/` and `Views/` are
   picked up automatically).
2. Select the **SSDTMaintenance** scheme, target **My Mac**, and set your
   signing **Team** under *Signing & Capabilities*.
3. **Remove the App Sandbox capability** (*Signing & Capabilities → ✕ App
   Sandbox*). A sandboxed app cannot launch `iasl`, so *Generate* would report
   "iasl not found." (Alternatively, bundle `iasl` inside the app's Resources.)
4. Build & run (**⌘R**).

---

## Usage

1. Fill in the **ACPI paths** for your board (defaults target the `_SB.PC00`
   layout). Confirm them against your own disassembled DSDT.
2. Choose your **hardware presets** and audio **layout IDs**.
3. In **Maintenance (macOS Support)**, enable the tables you need.
4. Click **Output Folder** (bottom bar) and pick a destination.
5. Click **Generate ALL SSDTs**. Use **Show Log** / **Copy Log** to review
   the `iasl` output.

Your `.aml` files (and `.dsl` source) land in the chosen folder, ready for
`EFI/OC/ACPI/`. Add each to `config.plist → ACPI → Add` (ProperTree's snapshot
does this for you).

### Required ACPI renames

Add these under `config.plist → ACPI → Patch` (Base empty, Count 0):

**`SSDT-EC`** — only if your board's real EC is named `EC`:

| Find | Replace | Comment |
|------|---------|---------|
| `45435F5F` | `45433000` | Rename EC to EC0 |

**`SSDT-GPRW`** — required for the instant-wake fix:

| Find | Replace | Comment |
|------|---------|---------|
| `5F475052 57` | `58475057` | Rename _GPRW to XGPW |

### Recommended deployment set

For most Z790 builds, install **AWAC + PMC + USBX + EC + SBUS-MCHC** (plus
`PNLF` / `ALS0` if wanted). Add `GPRW` / `RHUB` only with their renames/edits,
and treat `BRG0` as a template — edit its path and `_ADR` before use. Generating
all ten is fine; deploy only the ones your build actually needs.

> ⚠️ Injected SSDTs change how macOS sees your PCI tree. Always verify device
> paths against your own DSDT and test before relying on them.

---

## Changelog

### v1.1.0
- Added the **Maintenance (macOS Support)** SSDT suite: AWAC, PMC, USBX, EC,
  SBUS-MCHC, PNLF, GPRW, RHUB, ALS0, BRG0.
- The new EC + USBX replace the legacy combined `SSDT-EC-USBX`.
- Full-width single-window layout; **Output Folder** moved to the footer.
- **Copy Log** button and selectable compile log.
- Rebranded to **Lumina Dev Apps** (name, copyright, bundle identifier).

### v1.0
- Initial release: device SSDT generator with local `iasl` compilation.

---

## License

Released under the [MIT License](LICENSE).

© 2026 Lumina Dev Apps — a division of Direct Parcel Distributors Inc.
[luminadevapps.com](https://luminadevapps.com) · support@luminadevapps.com
