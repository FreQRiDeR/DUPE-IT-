//
//  ASRUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct ASRUtility {
    static func cloneDisk(source: String, target: String) async throws {
        try await cloneDiskWithOutput(source: source, target: target) { _ in }
    }
    
    static func cloneDiskWithOutput(source: String, target: String, outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("Starting ASR clone operation...")
        outputHandler("Source: \(source)")
        outputHandler("Target: \(target)")
        outputHandler("⚠️  All data on target will be erased!")
        
        // Use osascript to prompt for password and run sudo
        let script = """
        do shell script "/usr/sbin/asr --source '\(source)' --target '\(target)' --erase --noprompt --verbose" with administrator privileges
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
        outputHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        outputHandler(output.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
        }
        
        do {
            try process.run()
            outputHandler("ASR process started successfully")
            
            // Wait for completion
            process.waitUntilExit()
            
            // Stop reading output
            outputHandle.readabilityHandler = nil
            
            guard process.terminationStatus == 0 else {
                throw ASRError.cloneFailed("ASR command failed with exit code \(process.terminationStatus)")
            }
            
            outputHandler("✅ Clone operation completed successfully!")
            
        } catch {
            outputHandle.readabilityHandler = nil
            throw ASRError.cloneFailed("Failed to execute ASR command: \(error.localizedDescription)")
        }
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
