//
//  SSDTBuilder+Maintenance.swift
//  SSDTMaintenance
//
//  Foundational "maintenance" SSDTs required for macOS support on
//  Alder Lake / Raptor Lake (Z690 / Z790) and similar 300-series+ boards.
//
//  Every DSL string below was compiled clean (0 errors, 0 warnings) with
//  iasl (ACPICA 20230628). Paths default to the ACPI0007/_SB.PC00 layout used
//  elsewhere in this app; adjust in the DSL if your DSDT differs.
//
//  Author: SYSM Project
//

import Foundation

extension SSDTBuilder {

    // =====================================================
    // SSDT-AWAC — System clock (AWAC/RTC) fix
    // Forces the legacy RTC and disables AWAC under Darwin.
    // Requires a STAS variable in the factory DSDT (Z690/Z790 have it).
    // =====================================================
    static func awac() -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "AWAC", 0x00000000)
        {
            External (STAS, IntObj)

            Scope (\\)
            {
                Method (_INI, 0, NotSerialized)
                {
                    If (_OSI ("Darwin"))
                    {
                        STAS = One
                    }
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-PMC — Native NVRAM for 300-series+
    // Adds a PMCR device under the LPC bridge.
    // =====================================================
    static func pmc(lpcPath: String = "_SB.PC00.LPCB") -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "PMC", 0x00000000)
        {
            External (\(lpcPath), DeviceObj)

            Scope (\\\(lpcPath))
            {
                Device (PMCR)
                {
                    Name (_HID, EisaId ("APP9876"))
                    Method (_STA, 0, NotSerialized)
                    {
                        If (_OSI ("Darwin"))
                        {
                            Return (0x0B)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }

                    Name (_CRS, ResourceTemplate ()
                    {
                        Memory32Fixed (ReadWrite,
                            0xFE000000,
                            0x00010000,
                            )
                    })
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-USBX — USB power properties (sleep/wake current)
    // Board-agnostic (root _SB.USBX).
    // =====================================================
    static func usbx() -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "USBX", 0x00000000)
        {
            Scope (\\_SB)
            {
                Device (USBX)
                {
                    Name (_ADR, Zero)
                    Method (_DSM, 4, NotSerialized)
                    {
                        If (!Arg2)
                        {
                            Return (Buffer (One) { 0x03 })
                        }

                        Return (Package ()
                        {
                            "kUSBSleepPowerSupply",      0x13EC,
                            "kUSBSleepPortCurrentLimit", 0x0834,
                            "kUSBWakePowerSupply",       0x13EC,
                            "kUSBWakePortCurrentLimit",  0x0834
                        })
                    }
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-EC — Fake Embedded Controller (desktop)
    // NOTE: if the board already has a real device named "EC",
    // add an OpenCore ACPI rename EC -> EC0 (45435F5F -> 45433000).
    // =====================================================
    static func fakeEC(lpcPath: String = "_SB.PC00.LPCB") -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "EC", 0x00000000)
        {
            External (\(lpcPath), DeviceObj)

            Scope (\\\(lpcPath))
            {
                Device (EC)
                {
                    Name (_HID, "ACID0001")
                    Method (_STA, 0, NotSerialized)
                    {
                        If (_OSI ("Darwin"))
                        {
                            Return (0x0F)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-PNLF — Backlight control device (iGPU display)
    // =====================================================
    static func pnlf(gfxPath: String = "_SB.PC00.GFX0") -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "PNLF", 0x00000000)
        {
            External (\(gfxPath), DeviceObj)

            Scope (\\\(gfxPath))
            {
                Device (PNLF)
                {
                    Name (_HID, EisaId ("APP0002"))
                    Name (_CID, "backlight")
                    Name (_UID, 0x0A)
                    Name (_STA, 0x0B)
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-SBUS-MCHC — SMBus + Memory Controller Hub
    // =====================================================
    static func sbusMCHC(
        rootPath: String = "_SB.PC00",
        sbusPath: String = "_SB.PC00.SBUS"
    ) -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "SBUS", 0x00000000)
        {
            External (\(rootPath), DeviceObj)
            External (\(sbusPath), DeviceObj)

            Scope (\\\(sbusPath))
            {
                Device (BUS0)
                {
                    Name (_CID, "smbus")
                    Name (_ADR, Zero)
                    Device (DVL0)
                    {
                        Name (_ADR, 0x57)
                        Name (_CID, "diagsvault")
                        Method (_DSM, 4, NotSerialized)
                        {
                            If (!Arg2)
                            {
                                Return (Buffer (One) { 0x57 })
                            }

                            Return (Package ()
                            {
                                "address", 0x57
                            })
                        }
                    }
                }
            }

            Scope (\\\(rootPath))
            {
                Device (MCHC)
                {
                    Name (_ADR, Zero)
                    Method (_STA, 0, NotSerialized)
                    {
                        If (_OSI ("Darwin"))
                        {
                            Return (0x0F)
                        }
                        Else
                        {
                            Return (Zero)
                        }
                    }
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-GPRW — Instant-wake-from-sleep fix
    // REQUIRES OpenCore ACPI rename: _GPRW -> XGPW
    //   Find    5F475052 57   Replace  58475057   Count 0
    // =====================================================
    static func gprw(gpe: Int = 0x6D) -> String {
        let gpeHex = String(format: "0x%02X", gpe)
        return """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "GPRW", 0x00000000)
        {
            External (XGPW, MethodObj)

            Method (GPRW, 2, NotSerialized)
            {
                If (((\(gpeHex) == Arg0) && (One == Arg1)))
                {
                    Return (Package (0x02)
                    {
                        \(gpeHex),
                        Zero
                    })
                }

                Return (XGPW (Arg0, Arg1))
            }
        }
        """
    }

    // =====================================================
    // SSDT-RHUB — USB root-hub reset (port re-enumeration)
    // =====================================================
    static func rhub(xhciPath: String = "_SB.PC00.XHCI") -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "RHUB", 0x00000000)
        {
            External (\(xhciPath).RHUB, DeviceObj)

            Scope (\\\(xhciPath).RHUB)
            {
                Method (_STA, 0, NotSerialized)
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (Zero)
                    }

                    Return (0x0F)
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-ALS0 — Fake ambient light sensor stub
    // =====================================================
    static func als0() -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "ALS0", 0x00000000)
        {
            Scope (\\_SB)
            {
                Device (ALS0)
                {
                    Name (_HID, "ACPI0008")
                    Name (_CID, 0x080005AC)
                    Method (_STA, 0, NotSerialized)
                    {
                        If (_OSI ("Darwin"))
                        {
                            Return (0x0F)
                        }

                        Return (Zero)
                    }

                    Method (_ALI, 0, NotSerialized)
                    {
                        Return (0x012C)
                    }

                    Name (_ALR, Package (0x01)
                    {
                        Package (0x02)
                        {
                            0x64,
                            0x012C
                        }
                    })
                }
            }
        }
        """
    }

    // =====================================================
    // SSDT-BRG0 — PCI bridge _ADR template (ADVANCED)
    // Only for a bridge that ships without an _ADR. Edit path + _ADR.
    // =====================================================
    static func brg0(parentPort: String = "_SB.PC00.RP05") -> String {
        """
        DefinitionBlock ("", "SSDT", 2, "SYSM", "BRG0", 0x00000000)
        {
            External (\(parentPort), DeviceObj)

            Scope (\\\(parentPort))
            {
                Device (BRG0)
                {
                    Name (_ADR, Zero)
                    Method (_STA, 0, NotSerialized)
                    {
                        If (_OSI ("Darwin"))
                        {
                            Return (0x0F)
                        }

                        Return (Zero)
                    }
                }
            }
        }
        """
    }
}
