//
//  ContentView.swift
//  SSDTMaintenance
//
//  Root View — full width, output folder lives in the bottom bar
//

import SwiftUI

struct ContentView: View {

    @State private var outputFolder: URL?
    @State private var statusMessage = "No output folder selected"

    var body: some View {
        ZStack {
            // Modern window background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            TabView {

                SSDTGeneratorView(
                    outputFolder: $outputFolder,
                    statusMessage: $statusMessage
                )
                .tabItem {
                    Label("Generator", systemImage: "gearshape.fill")
                }

                DeveloperInfoView()
                    .tabItem {
                        Label("About", systemImage: "info.circle.fill")
                    }
            }
            .padding()
        }
        .frame(minWidth: 900, minHeight: 680)
        .toolbar {
            ToolbarItem(placement: .status) {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    ContentView()
}
