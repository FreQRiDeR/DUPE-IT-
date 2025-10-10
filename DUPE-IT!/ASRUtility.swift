//
//  ASRUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct ASRUtility {
    static func cloneDisk(source: String, target: String) async throws {
        try await cloneDiskWithOutput(source: source, target: target) { _ in } progressHandler: { _ in }
    }
    
    static func cloneDiskWithOutput(
        source: String,
        target: String,
        outputHandler: @escaping (String) -> Void,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        outputHandler("Starting ASR clone operation...")
        outputHandler("Source: \(source)")
        outputHandler("Target: \(target)")
        outputHandler("⚠️  All data on target will be erased!")
        
        // Escape single quotes to prevent command injection
        let escapedSource = source.replacingOccurrences(of: "'", with: "'\\''")
        let escapedTarget = target.replacingOccurrences(of: "'", with: "'\\''")
        
        // Use osascript to prompt for password and run sudo
        let script = """
        do shell script "/usr/sbin/asr --source '\(escapedSource)' --target '\(escapedTarget)' --erase --noprompt --verbose" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        outputHandler("Executing: sudo asr --source \(source) --target \(target) --erase --noprompt --verbose")
        outputHandler("macOS will prompt for administrator password...")
        
        // Read output asynchronously
        let outputHandle = pipe.fileHandleForReading
        outputHandle.readabilityHandler = { [weak outputHandle] handle in
            guard outputHandle != nil else { return }
            
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            DispatchQueue.main.async {
                                outputHandler(trimmed)
                            }
                            
                            // Parse progress from ASR output
                            if let progress = parseASRProgress(from: trimmed) {
                                DispatchQueue.main.async {
                                    progressHandler(progress)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        do {
            try process.run()
            outputHandler("ASR process started successfully")
            progressHandler(0.0)
            
            // Wait for completion
            process.waitUntilExit()
            
            // Small delay to ensure all output is captured
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Stop reading output
            outputHandle.readabilityHandler = nil
            
            guard process.terminationStatus == 0 else {
                throw ASRError.cloneFailed("ASR command failed with exit code \(process.terminationStatus)")
            }
            
            progressHandler(1.0)
            outputHandler("✅ Clone operation completed successfully!")
            
        } catch {
            outputHandle.readabilityHandler = nil
            throw ASRError.cloneFailed("Failed to execute ASR command: \(error.localizedDescription)")
        }
    }
    
    private static func parseASRProgress(from line: String) -> Double? {
        // ASR outputs progress in various formats:
        // "Copying ... (XX%)" or "Block copy ... XX%"
        let patterns = [
            #"(\d+)%"#,  // Match any percentage
            #"(\d+\.\d+)%"#  // Match decimal percentages
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
               let range = Range(match.range(at: 1), in: line) {
                let percentString = String(line[range])
                if let percent = Double(percentString) {
                    return percent / 100.0
                }
            }
        }
        
        return nil
    }
}

enum ASRError: LocalizedError {
    case cloneFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .cloneFailed(let message):
            return "Clone operation failed: \(message)"
        }
    }
}
