//
//  DMGCommandOutputView.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import SwiftUI

struct DMGCommandOutputView: View {
    @Binding var isPresented: Bool
    let source: String
    let outputURL: URL?
    let useUDZO: Bool
    
    @State private var output: [String] = []
    @State private var isRunning = true
    @State private var hasError = false
    @State private var progress: Double = 0.0
    @State private var currentPhase: String = "Creating DMG"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: isRunning ? "gear.circle.fill" : (hasError ? "xmark.circle.fill" : "checkmark.circle.fill"))
                    .foregroundColor(isRunning ? .blue : (hasError ? .red : .green))
                    .font(.title2)
                
                Text("DMG Creation")
                    .font(.headline)
                
                Spacer()
                
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Button("Close") {
                    isPresented = false
                }
                .disabled(isRunning)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Progress Bar
            if isRunning || progress > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
            
            Divider()
            
            // Output Log
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(output.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(lineColor(for: line))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: output.count) { _ in
                    if let lastIndex = output.indices.last {
                        withAnimation {
                            proxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                if !isRunning {
                    if hasError {
                        Label("Operation failed", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    } else {
                        Label("DMG created successfully", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    Label("Creating DMG...", systemImage: "gear")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            startCreatingDMG()
        }
    }
    
    private func lineColor(for line: String) -> Color {
        if line.contains("❌") || line.contains("error") || line.contains("failed") || line.contains("Error") {
            return .red
        } else if line.contains("✅") || line.contains("success") || line.contains("completed") {
            return .green
        } else if line.contains("⚠️") || line.contains("warning") || line.contains("Warning") {
            return .orange
        }
        return .primary
    }
    
    private func startCreatingDMG() {
        guard let outputURL = outputURL else {
            output.append("❌ Error: No output URL specified")
            isRunning = false
            hasError = true
            return
        }
        
        Task {
            do {
                try await DMGUtility.createDMG(
                    source: source,
                    output: outputURL,
                    useUDZO: useUDZO,
                    outputHandler: { line in
                        output.append(line)
                    },
                    progressHandler: { prog in
                        progress = prog
                    }
                )
                
                await MainActor.run {
                    isRunning = false
                    hasError = false
                }
            } catch {
                await MainActor.run {
                    output.append("❌ Error: \(error.localizedDescription)")
                    isRunning = false
                    hasError = true
                }
            }
        }
    }
}

#Preview {
    DMGCommandOutputView(
        isPresented: .constant(true),
        source: "/dev/disk2",
        outputURL: URL(fileURLWithPath: "/Users/test/backup.dmg"),
        useUDZO: true
    )
}
