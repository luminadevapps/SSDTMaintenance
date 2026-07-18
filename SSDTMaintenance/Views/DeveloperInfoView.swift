//
//  DeveloperInfoView.swift
//  SSDTMaintenance
//
//  About — Lumina Dev Apps
//

import SwiftUI
import AppKit

struct DeveloperInfoView: View {

    // MARK: - Company Details
    private let companyName   = "Lumina Dev Apps"
    private let parentCompany = "A division of Direct Parcel Distributors Inc."
    private let address       = "1335 Apollo St, Oshawa, Ontario L1K 3E6"
    private let websiteText   = "luminadevapps.com"
    private let websiteURL    = URL(string: "https://luminadevapps.com")!
    private let email         = "support@luminadevapps.com"
    private let copyright     = "© 2026 Lumina Dev Apps"

    private let donateURL = URL(
        string: "https://www.paypal.com/donate/?business=H3PV9HX92AVMJ&no_recurring=0&item_name=Support+development+of+all+my+apps+and+tools.+Donations+fund+testing+hardware%2C+servers%2C+and+continued+open-source+development.&currency_code=CAD"
    )!

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 22) {

                // MARK: - Logo
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(radius: 4, y: 2)

                // MARK: - Title / Company
                VStack(spacing: 6) {
                    Text("SSDT Maintenance Utility")
                        .font(.largeTitle.bold())

                    Text(companyName)
                        .font(.title3.weight(.semibold))

                    Text(parentCompany)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)

                Divider()

                // MARK: - Company Details
                VStack(alignment: .leading, spacing: 14) {

                    infoRow(
                        icon: "globe",
                        title: "Website",
                        value: websiteText,
                        action: { NSWorkspace.shared.open(websiteURL) }
                    )

                    infoRow(
                        icon: "envelope.fill",
                        title: "Email",
                        value: email,
                        action: {
                            NSWorkspace.shared.open(URL(string: "mailto:\(email)")!)
                        }
                    )

                    infoRow(
                        icon: "mappin.and.ellipse",
                        title: "Address",
                        value: address
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // MARK: - Description
                Text("""
This utility generates clean, OpenCore-ready SSDTs — including the \
essential macOS-support maintenance tables — for modern Hackintosh systems.

If this tool helps your build, consider supporting continued development.
""")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

                // MARK: - Donate Button
                Button {
                    NSWorkspace.shared.open(donateURL)
                } label: {
                    Label("Support Development", systemImage: "heart.fill")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.0, green: 0.45, blue: 0.25))
                .controlSize(.large)

                // MARK: - Copyright
                Text(copyright)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer()
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .padding()
        }
    }

    // MARK: - Info Row Helper

    private func infoRow(
        icon: String,
        title: String,
        value: String,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(title)
                .fontWeight(.semibold)

            Spacer()

            if let action = action {
                Button(value) {
                    action()
                }
                .buttonStyle(.link)
            } else {
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DeveloperInfoView()
}
