//
//  CommandOutputView.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import SwiftUI

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
}

struct CommandOutputView: View {
    @Binding var isPresented: Bool
    let source: String
    let target: String
    var isDMGSource: Bool = false
    var dmgPath: String? = nil
    @State private var outputText = ""
    @State private var isRunning = false
    
    private var command: String {
        "sudo asr --source \(source) --target \(target) --erase --noprompt --verbose"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "terminal")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Command Execution")
                    .font(.headline)
                
                Spacer()
                
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Command being executed
            VStack(alignment: .leading, spacing: 8) {
                Text("Executing Command:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Output area
            VStack(alignment: .leading, spacing: 8) {
                Text("Output:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    ScrollViewReader { proxy in
                        Text(outputText.isEmpty ? "Waiting for command execution..." : outputText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(outputText.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(8)
                            .id("bottom")
                            .onChange(of: outputText) { _ in
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                    }
                }
                .frame(height: 200)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            
            // Buttons
            HStack {
                if !isRunning {
                    Button("Close") {
                        isPresented = false
                    }
                    .keyboardShortcut(.escape)
                }
                
                Spacer()
                
                if !isRunning {
                    Button("Execute") {
                        executeCommand()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                }
            }
        }
        .padding()
        .frame(width: 700, height: 450)
        .onAppear {
            appendOutput("Ready to execute command...")
            appendOutput("Click 'Execute' to start or press Enter")
        }
    }
    
    private func appendOutput(_ text: String) {
        DispatchQueue.main.async {
            if !outputText.isEmpty {
                outputText += "\n"
            }
            outputText += "[\(DateFormatter.timeFormatter.string(from: Date()))] \(text)"
        }
    }
    
    private func executeCommand() {
        isRunning = true
        outputText = ""
        Task {
            do {
                try await ASRUtility.cloneDiskWithOutput(source: source, target: target) { output in
                    appendOutput(output)
                }
                await MainActor.run {
                    appendOutput("✅ Command completed successfully!")
                    isRunning = false
                }
            } catch {
                await MainActor.run {
                    appendOutput("❌ Error: \(error.localizedDescription)")
                    isRunning = false
                }
            }
        }
    }
}

#Preview {
    CommandOutputView(
        isPresented: .constant(true),
        source: "/dev/disk2",
        target: "/dev/disk3"
    )
}
