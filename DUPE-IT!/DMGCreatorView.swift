//
//  DMGCreatorView.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import SwiftUI

struct DMGCreatorView: View {
    @State private var availableDisks: [DiskInfo] = []
    @State private var selectedSource: DiskInfo?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCreating = false
    @State private var showingCommandOutput = false
    @State private var useUDZO = false
    @State private var outputURL: URL?
    @State private var outputDisplayPath = "No file selected"

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("DMG Creator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Create disk images using hdiutil")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            Divider()
            
            // Disk Selection
            VStack(spacing: 16) {
                HStack {
                    Button(action: refreshDisks) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Disks")
                        }
                    }
                    .disabled(isLoading || isCreating)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Source Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Source Disk", systemImage: "externaldrive")
                        .font(.headline)
                    
                    Picker("Source Disk", selection: $selectedSource) {
                        Text("Select source disk...")
                            .tag(nil as DiskInfo?)
                        
                        ForEach(availableDisks) { disk in
                            Text(disk.displayName)
                                .tag(disk as DiskInfo?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(isCreating)
                }
                
                // Output File Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Output File", systemImage: "folder")
                        .font(.headline)
                    
                    HStack {
                        Text(outputDisplayPath)
                            .foregroundColor(outputURL == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button("Choose...") {
                            showSavePanel()
                        }
                        .disabled(isCreating)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                
                // Format Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("Format Options", systemImage: "gearshape")
                        .font(.headline)
                    
                    Toggle("Use UDZO compression (smaller file)", isOn: $useUDZO)
                        .disabled(isCreating)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
            
            // Create Button
            Button(action: startCreating) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(isCreating ? "Creating DMG..." : "Create DMG")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canStartCreating ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canStartCreating || isCreating)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            refreshDisks()
        }
        .alert("DMG Creator", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingCommandOutput) {
            DMGCommandOutputView(
                isPresented: $showingCommandOutput,
                source: selectedSource?.deviceIdentifier ?? "",
                outputURL: outputURL,
                useUDZO: useUDZO
            )
        }
    }
    
    private var canStartCreating: Bool {
        selectedSource != nil && outputURL != nil && !isLoading
    }
    
    private func showSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save DMG File"
        savePanel.message = "Choose location and name for the DMG file"
        savePanel.allowedContentTypes = [.init(filenameExtension: "dmg")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        // Set default filename based on selected source
        if let source = selectedSource {
            let diskName = source.deviceIdentifier.replacingOccurrences(of: "/dev/", with: "")
            savePanel.nameFieldStringValue = "\(diskName)_Backup.dmg"
        } else {
            savePanel.nameFieldStringValue = "Backup.dmg"
        }
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                outputURL = url
                outputDisplayPath = url.path
            }
        }
    }
    
    private func refreshDisks() {
        isLoading = true
        
        Task {
            do {
                let disks = try await DiskUtility.listDisks()
                await MainActor.run {
                    self.availableDisks = disks
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.alertMessage = "Failed to load disks: \(error.localizedDescription)"
                    self.showingAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func startCreating() {
        guard let source = selectedSource, let outputURL = outputURL else { return }
        
        showingCommandOutput = true
    }
}

#Preview {
    DMGCreatorView()
}
