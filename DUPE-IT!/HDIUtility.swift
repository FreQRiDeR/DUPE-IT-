//
//  HDIUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct HDIUtility {
    static func createDMGWithOutput(source: String, outputURL: URL, useUDZO: Bool, outputHandler: @escaping (String) -> Void) async throws {
        outputHandler("Starting DMG creation...")
        outputHandler("Source: \(source)")
        outputHandler("Output File: \(outputURL.path)")
        outputHandler("Format: \(useUDZO ? "UDZO (compressed)" : "UDRW (read/write)")")
        
        let format = useUDZO ? "UDZO" : "UDRW"
        let fullPath = outputURL.path
        
        // Use osascript to prompt for password and run sudo
        let script = """
        do shell script "/usr/bin/hdiutil create -srcdevice '\(source)' -format \(format) '\(fullPath)'" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        outputHandler("Executing: sudo hdiutil create -srcdevice \(source) -format \(format) \(fullPath)")
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
            outputHandler("hdiutil process started successfully")
            
            // Wait for completion
            process.waitUntilExit()
            
            // Stop reading output
            outputHandle.readabilityHandler = nil
            
            guard process.terminationStatus == 0 else {
                throw HDIError.creationFailed("hdiutil command failed with exit code \(process.terminationStatus)")
            }
            
            outputHandler("✅ DMG creation completed successfully!")
            outputHandler("Output file: \(fullPath)")
            
        } catch {
            outputHandle.readabilityHandler = nil
            throw HDIError.creationFailed("Failed to execute hdiutil command: \(error.localizedDescription)")
        }
    }
}

enum HDIError: LocalizedError {
    case creationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let message):
            return "DMG creation failed: \(message)"
        }
    }
}
