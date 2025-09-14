//
//  DiskClonerView.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation
import SwiftUI


struct DiskClonerView: View {
    // Verifies DMG using hdiutil scan
    @State private var availableDisks: [DiskInfo] = []
    @State private var selectedSource: DiskInfo?
    @State private var selectedDMGPath: String? = nil
    @State private var showingDMGOpenPanel = false
    // Removed scan state for DMG, as scan is deprecated
    @State private var selectedTarget: DiskInfo?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCloning = false
    @State private var showingCommandOutput = false
    
    // DMG Creator states
    @State private var selectedDMGSource: DiskInfo?
    @State private var isCreatingDMG = false
    @State private var showingDMGCommandOutput = false
    @State private var useUDZO = false
    @State private var outputURL: URL?
    @State private var outputDisplayPath = "No file selected"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "externaldrive.fill.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("DUPE-IT! Disk Cloner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Clone drives and partitions using Apple Software Restore")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                Divider()
                
                // ASR Disk Cloning Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Disk Cloning (ASR)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: refreshDisks) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Disks")
                            }
                        }
                        .disabled(isLoading || isCloning || isCreatingDMG)
                        
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
                            Divider()
                            Text("Choose DMG...")
                                .tag(DiskInfo(deviceIdentifier: "DMG_CHOOSE", name: "Choose DMG", size: "", type: "dmg") as DiskInfo?)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(isCloning || isCreatingDMG)
                        .onChange(of: selectedSource) { newValue in
                            if let src = newValue, src.deviceIdentifier == "DMG_CHOOSE" {
                                selectedSource = nil
                                showingDMGOpenPanel = true
                            }
                        }
                        if let dmgPath = selectedDMGPath {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.badge.ellipsis")
                                Text(dmgPath)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Button("Clear") { selectedDMGPath = nil }
                            }
                        }
                    }
                    
                    // Target Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Target Disk", systemImage: "externaldrive.badge.plus")
                            .font(.headline)
                        
                        Picker("Target Disk", selection: $selectedTarget) {
                            Text("Select target disk...")
                                .tag(nil as DiskInfo?)
                            
                            ForEach(availableDisks.filter { $0.id != selectedSource?.id }) { disk in
                                Text(disk.displayName)
                                    .tag(disk as DiskInfo?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(isCloning || isCreatingDMG)
                    }
                    
                    // Warning
                    if selectedSource != nil && selectedTarget != nil {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Warning: All data on the target disk will be erased!")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Clone Button
                    Button(action: startCloning) {
                        HStack {
                            if isCloning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.fill")
                            }
                            
                            Text(isCloning ? "Cloning..." : "Start Cloning")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStartCloning ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canStartCloning || isCloning || isCreatingDMG)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Divider()
                
                // DMG Creator Section
                VStack(spacing: 16) {
                    HStack {
                        Text("DMG Creator (hdiutil)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    
                    // DMG Source Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Source Disk", systemImage: "externaldrive")
                            .font(.headline)
                        
                        Picker("DMG Source Disk", selection: $selectedDMGSource) {
                            Text("Select source disk...")
                                .tag(nil as DiskInfo?)
                            
                            ForEach(availableDisks) { disk in
                                Text(disk.displayName)
                                    .tag(disk as DiskInfo?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(isCloning || isCreatingDMG)
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
                            .disabled(isCloning || isCreatingDMG)
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
                            .disabled(isCloning || isCreatingDMG)
                    }
                    
                    // Create DMG Button
                    Button(action: startCreatingDMG) {
                        HStack {
                            if isCreatingDMG {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            
                            Text(isCreatingDMG ? "Creating DMG..." : "Create DMG")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStartCreatingDMG ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canStartCreatingDMG || isCloning || isCreatingDMG)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 700)
        .onAppear {
            refreshDisks()
        }
        .alert("Disk Cloner", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingCommandOutput) {
            CommandOutputView(
                isPresented: $showingCommandOutput,
                source: selectedDMGPath ?? selectedSource?.deviceIdentifier ?? "",
                target: selectedTarget?.deviceIdentifier ?? "",
                isDMGSource: selectedDMGPath != nil,
                dmgPath: selectedDMGPath
            )
        }
        .sheet(isPresented: $showingDMGCommandOutput) {
            DMGCommandOutputView(
                isPresented: $showingDMGCommandOutput,
                source: selectedDMGSource?.deviceIdentifier ?? "",
                outputURL: outputURL,
                useUDZO: useUDZO
            )
        }
        .fileImporter(isPresented: $showingDMGOpenPanel, allowedContentTypes: [.data], allowsMultipleSelection: false, onCompletion: { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, url.pathExtension.lowercased() == "dmg" {
                    selectedDMGPath = url.path
                } else {
                    alertMessage = "Please select a valid DMG file."
                    showingAlert = true
                }
            case .failure:
                break
            }
        })
    }
    
    private var canStartCloning: Bool {
        // Allow if either a disk is selected, or a DMG is selected
        ((selectedSource != nil && selectedTarget != nil) || (selectedDMGPath != nil && selectedTarget != nil)) && !isLoading
    }
    
    private var canStartCreatingDMG: Bool {
        selectedDMGSource != nil && outputURL != nil && !isLoading
    }
    
    private func showSavePanel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save DMG File"
        savePanel.message = "Choose location and name for the DMG file"
        savePanel.allowedContentTypes = [.init(filenameExtension: "dmg")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        // Set default filename based on selected source
        if let source = selectedDMGSource {
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
    
    private func startCloning() {
        // If using DMG as source
        if let dmgPath = selectedDMGPath, !dmgPath.isEmpty, selectedSource == nil {
            if selectedTarget != nil {
                showingCommandOutput = true
            }
            return
        }
    guard selectedSource != nil, selectedTarget != nil else { return }
    showingCommandOutput = true
    }
    
    private func startCreatingDMG() {
    guard selectedDMGSource != nil, outputURL != nil else { return }
    showingDMGCommandOutput = true
    }


}

#Preview {
    DiskClonerView()
}
