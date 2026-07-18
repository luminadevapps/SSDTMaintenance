//
//  SSDTGeneratorView.swift
//  SSDTMaintenance
//
//  FINAL – Generate button always visible (bottom bar)
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SSDTGeneratorView: View {

    // MARK: - Bindings
    @Binding var outputFolder: URL?
    @Binding var statusMessage: String

    // MARK: - ACPI Paths
    @State private var hdefPath = "_SB.PC00.HDEF"
    @State private var igpuPath = "_SB.PC00.IGPU"
    @State private var gpuPath  = "_SB.PC00.PEG0.PEGP"
    @State private var hdauPath = "_SB.PC00.PEG0.PEGP.HDAU"
    @State private var lanPath  = "_SB.PC00.RP01.PXSX"
    @State private var wifiPath = "_SB.PC00.RP02.PXSX"
    @State private var sataPath = "_SB.PC00.SATA"
    @State private var nvmePath = "_SB.PC00.RP04.PXSX"
    @State private var tbPath   = "_SB.PC00.RP05.PXSX"
    @State private var xhciPath = "_SB.PC00.XHCI"

    // MARK: - Audio
    @State private var layoutID: Int = 7
    @State private var alcLayoutID: Int = 12
    @State private var codecName: String = "Realtek Audio"

    // MARK: - Presets
    @State private var igpuPreset: IGPUPreset = .raptorlake
    @State private var gpuPreset: GPUPreset = .rdna2
    @State private var lanPreset: LANPreset = .aquantiaAQC107
    @State private var wifiPreset: WIFIPreset = .intel
    @State private var tbPreset: TBPreset = .titanRidge
    @State private var usbPreset: USBPreset = .ports15
    @State private var sataPreset: SATAPreset = .intelAHCI
    @State private var nvmePreset: NVMePreset = .generic

    // MARK: - Maintenance (macOS Support) toggles
    // Universal / safe → ON by default.
    @State private var mAWAC = true      // clock fix (needs STAS in DSDT)
    @State private var mPMC  = true      // native NVRAM
    @State private var mUSBX = true      // USB power properties
    @State private var mEC   = true      // fake EC (may need EC->EC0 rename)
    @State private var mSBUS = true      // SMBus + MCHC
    // Situational / board-specific → OFF by default.
    @State private var mPNLF = false     // backlight (iGPU display)
    @State private var mGPRW = false     // instant-wake fix (needs _GPRW->XGPW rename)
    @State private var mRHUB = false     // USB root-hub reset
    @State private var mALS0 = false     // fake ambient light sensor
    @State private var mBRG0 = false     // PCI bridge _ADR template (advanced)

    // MARK: - Output / Log
    @State private var compileLog: String = ""
    @State private var showLog: Bool = false
    @State private var showFolderPicker: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // ✅ Main content scroll
            ScrollView {
                Form {
                    Section("ACPI Paths") {
                        pathField("HDEF", $hdefPath)
                        pathField("IGPU", $igpuPath)
                        pathField("GPU", $gpuPath)
                        pathField("HDAU", $hdauPath)
                        pathField("LAN", $lanPath)
                        pathField("Wi-Fi", $wifiPath)
                        pathField("SATA", $sataPath)
                        pathField("NVMe", $nvmePath)
                        pathField("Thunderbolt", $tbPath)
                        pathField("XHCI", $xhciPath)
                    }

                    Section("Audio") {
                        Stepper("Layout ID: \(layoutID)", value: $layoutID, in: 1...99)
                        Stepper("ALC Layout ID: \(alcLayoutID)", value: $alcLayoutID, in: 1...99)
                        TextField("Codec Name", text: $codecName)
                    }

                    Section("Graphics") {
                        modelPicker(
                            title: "Integrated GPU",
                            selection: $igpuPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                        modelPicker(
                            title: "Discrete GPU",
                            selection: $gpuPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                    }

                    Section("Connectivity") {
                        modelPicker(
                            title: "LAN",
                            selection: $lanPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                        modelPicker(
                            title: "Wi-Fi",
                            selection: $wifiPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                        modelPicker(
                            title: "Thunderbolt",
                            selection: $tbPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                    }

                    Section("USB & Storage") {
                        modelPicker(
                            title: "USB",
                            selection: $usbPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                        modelPicker(
                            title: "SATA",
                            selection: $sataPreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                        modelPicker(
                            title: "NVMe",
                            selection: $nvmePreset,
                            name: { $0.name },
                            description: { $0.description }
                        )
                    }

                    Section("Maintenance (macOS Support)") {
                        maintenanceToggle("SSDT-AWAC", $mAWAC,
                            "System clock fix (RTC/AWAC) — required on Z690/Z790")
                        maintenanceToggle("SSDT-PMC", $mPMC,
                            "Native NVRAM for 300-series and newer")
                        maintenanceToggle("SSDT-USBX", $mUSBX,
                            "USB sleep/wake power properties")
                        maintenanceToggle("SSDT-EC", $mEC,
                            "Fake Embedded Controller — may need EC→EC0 rename")
                        maintenanceToggle("SSDT-SBUS-MCHC", $mSBUS,
                            "SMBus + Memory Controller Hub")
                        maintenanceToggle("SSDT-PNLF", $mPNLF,
                            "Backlight control (iGPU display)")
                        maintenanceToggle("SSDT-GPRW", $mGPRW,
                            "Instant-wake fix — REQUIRES _GPRW→XGPW ACPI rename")
                        maintenanceToggle("SSDT-RHUB", $mRHUB,
                            "USB root-hub reset (port re-enumeration)")
                        maintenanceToggle("SSDT-ALS0", $mALS0,
                            "Fake ambient light sensor stub")
                        maintenanceToggle("SSDT-BRG0", $mBRG0,
                            "PCI bridge _ADR template (advanced — edit path first)")
                    }

                    // Add bottom padding so form content doesn't sit under the button bar
                    Section {
                        EmptyView()
                    }
                    .frame(height: 20)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }

            // ✅ Log panel (optional)
            if showLog {
                Divider()
                ScrollView {
                    Text(compileLog.isEmpty ? "No log yet." : compileLog)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(minHeight: 220, maxHeight: 260)
                .background(Color(NSColor.textBackgroundColor))
            }

            Divider()

            // ✅ Fixed bottom action bar (ALWAYS VISIBLE)
            HStack(spacing: 12) {
                Button {
                    generateAll()
                } label: {
                    Label("Generate ALL SSDTs", systemImage: "bolt.fill")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showFolderPicker = true
                } label: {
                    Label("Output Folder", systemImage: "folder.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(showLog ? "Hide Log" : "Show Log") {
                    withAnimation { showLog.toggle() }
                }
                .buttonStyle(.bordered)

                Button("Copy Log") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(compileLog, forType: .string)
                }
                .buttonStyle(.bordered)
                .disabled(compileLog.isEmpty)

                Spacer()

                // Current folder status
                if let folder = outputFolder {
                    Text(folder.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("No folder selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                _ = url.startAccessingSecurityScopedResource()
                do {
                    if !FileManager.default.fileExists(atPath: url.path) {
                        try FileManager.default.createDirectory(
                            at: url, withIntermediateDirectories: true
                        )
                    }
                    outputFolder = url
                    statusMessage = "Output: \(url.path)"
                } catch {
                    statusMessage = "❌ Cannot use folder"
                }
            case .failure(let error):
                statusMessage = error.localizedDescription
            }
        }
    }

    // MARK: - UI Helpers

    private func pathField(_ title: String, _ binding: Binding<String>) -> some View {
        TextField(title, text: binding)
            .font(.system(.body, design: .monospaced))
    }

    private func maintenanceToggle(
        _ title: String,
        _ binding: Binding<Bool>,
        _ subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(title, isOn: binding)
                .font(.system(.body, design: .monospaced))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func modelPicker<T>(
        title: String,
        selection: Binding<T>,
        name: @escaping (T) -> String,
        description: @escaping (T) -> String
    ) -> some View
    where T: CaseIterable & Identifiable & Hashable {

        VStack(alignment: .leading, spacing: 6) {
            Picker(title, selection: selection) {
                ForEach(Array(T.allCases), id: \.self) { item in
                    Text(name(item)).tag(item)
                }
            }

            Text(description(selection.wrappedValue))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Generation (REAL PIPELINE)

    private func generateAll() {
        guard let folder = outputFolder else {
            statusMessage = "❌ Please select an output folder"
            return
        }

        do {
            if !FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }
        } catch {
            statusMessage = "❌ Cannot create output folder: \(error.localizedDescription)"
            return
        }

        statusMessage = "⚙️ Generating SSDTs…"
        compileLog = ""
        showLog = true

        let ssdtList: [(name: String, dsl: String)] = [
            ("SSDT-PLUG", SSDTBuilder.cpuPlug()),
            ("SSDT-DTPG", SSDTBuilder.dtpg()),
            ("SSDT-EC-USBX", SSDTBuilder.ecUSBX()),

            ("SSDT-HDEF", SSDTBuilder.hdef(
                path: hdefPath,
                layoutID: layoutID,
                alcLayoutID: alcLayoutID,
                codecName: codecName
            )),

            ("SSDT-IGPU", SSDTBuilder.igpuWithPreset(path: igpuPath, preset: igpuPreset)),

            ("SSDT-GPU", SSDTBuilder.gpuWithHDAU(
                gpuPath: gpuPath,
                hdauPath: hdauPath,
                preset: gpuPreset,
                slotName: "PCIe Slot 1"
            )),

            ("SSDT-LAN", SSDTBuilder.lanWithPreset(
                path: lanPath,
                preset: lanPreset,
                slotName: "PCIe Slot 4"
            )),

            ("SSDT-WIFI", SSDTBuilder.wifiWithPreset(
                path: wifiPath,
                preset: wifiPreset,
                slotName: "PCIe Slot 3"
            )),

            ("SSDT-TB3", SSDTBuilder.tb3WithPreset(
                path: tbPath,
                preset: tbPreset,
                slotName: "PCIe Slot 5"
            )),

            ("SSDT-XHCI", SSDTBuilder.xhciWithPreset(path: xhciPath, preset: usbPreset)),
            ("SSDT-SATA", SSDTBuilder.sataWithPreset(path: sataPath, preset: sataPreset)),
            ("SSDT-NVME", SSDTBuilder.nvmeWithPreset(path: nvmePath, preset: nvmePreset))
        ]

        // Maintenance (macOS Support) SSDTs — only the enabled toggles.
        // Derive helper paths from the LPC bridge / XHCI already entered above.
        let lpcPath = "_SB.PC00.LPCB"
        var maintenanceList: [(name: String, dsl: String)] = []
        if mAWAC { maintenanceList.append(("SSDT-AWAC", SSDTBuilder.awac())) }
        if mPMC  { maintenanceList.append(("SSDT-PMC",  SSDTBuilder.pmc(lpcPath: lpcPath))) }
        if mUSBX { maintenanceList.append(("SSDT-USBX", SSDTBuilder.usbx())) }
        if mEC   { maintenanceList.append(("SSDT-EC",   SSDTBuilder.fakeEC(lpcPath: lpcPath))) }
        if mSBUS { maintenanceList.append(("SSDT-SBUS-MCHC", SSDTBuilder.sbusMCHC())) }
        if mPNLF { maintenanceList.append(("SSDT-PNLF", SSDTBuilder.pnlf(gfxPath: igpuPath))) }
        if mGPRW { maintenanceList.append(("SSDT-GPRW", SSDTBuilder.gprw())) }
        if mRHUB { maintenanceList.append(("SSDT-RHUB", SSDTBuilder.rhub(xhciPath: xhciPath))) }
        if mALS0 { maintenanceList.append(("SSDT-ALS0", SSDTBuilder.als0())) }
        if mBRG0 { maintenanceList.append(("SSDT-BRG0", SSDTBuilder.brg0(parentPort: tbPath))) }

        // The maintenance SSDT-EC / SSDT-USBX are the properly-scoped
        // replacements for the legacy combined SSDT-EC-USBX. Drop the legacy
        // one when either replacement is active to avoid duplicate EC/USBX.
        let baseFiltered = (mEC || mUSBX)
            ? ssdtList.filter { $0.name != "SSDT-EC-USBX" }
            : ssdtList

        let allSSDTs = baseFiltered + maintenanceList

        var wroteAny = false

        do {
            for item in allSSDTs {
                let trimmed = item.dsl.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    compileLog += "▶ \(item.name)\n(SKIPPED – empty SSDT)\n\n"
                    continue
                }

                wroteAny = true

                let dslURL = try SSDTFileManager.writeDSL(
                    name: item.name,
                    content: item.dsl,
                    to: folder
                )

                let result = SSDTCompiler.compile(dslURL: dslURL)

                compileLog += "▶ \(item.name)\n"
                compileLog += result.stdout
                if !result.stderr.isEmpty {
                    compileLog += "\n--- STDERR ---\n"
                    compileLog += result.stderr
                }
                compileLog += "\n\n"
            }

            statusMessage = wroteAny ? "✅ SSDTs generated successfully" : "⚠️ Nothing generated"

        } catch {
            statusMessage = "❌ Generation failed: \(error.localizedDescription)"
            compileLog += "❌ Fatal error: \(error.localizedDescription)\n"
        }
    }
}
