//
//  DMGUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct DMGUtility {
    static func createDMG(
        source: String,
        output: URL,
        useUDZO: Bool,
        outputHandler: @escaping (String) -> Void,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        outputHandler("Starting DMG creation...")
        outputHandler("Source: \(source)")
        outputHandler("Output: \(output.path)")
        outputHandler("Format: \(useUDZO ? "UDZO (compressed)" : "UDRW (read-write)")")
        
        // Escape single quotes to prevent command injection
        let escapedSource = source.replacingOccurrences(of: "'", with: "'\\''")
        let escapedOutput = output.path.replacingOccurrences(of: "'", with: "'\\''")
        
        // Use UDRW (read-write) instead of UDRO for proper restore compatibility
        // Use UDZO for compressed, but note it's read-only and may need conversion
        let format = useUDZO ? "UDZO" : "UDRW"
        
        let script = """
        do shell script "/usr/bin/hdiutil create -srcdevice '\(escapedSource)' '\(escapedOutput)' -format \(format) -verbose && /bin/chmod 644 '\(escapedOutput)'" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        outputHandler("Executing: sudo hdiutil create -srcdevice \(source) \(output.path) -format \(format)")
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
                            
                            // Parse progress from hdiutil output
                            if let progress = parseDMGProgress(from: trimmed) {
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
            outputHandler("DMG creation process started successfully")
            progressHandler(0.0)
            
            // Wait for completion
            process.waitUntilExit()
            
            // Small delay to ensure all output is captured
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Stop reading output
            outputHandle.readabilityHandler = nil
            
            guard process.terminationStatus == 0 else {
                throw DMGError.creationFailed("hdiutil command failed with exit code \(process.terminationStatus)")
            }
            
            progressHandler(1.0)
            
            // Set proper permissions on the DMG file
            outputHandler("Setting file permissions...")
            setDMGPermissions(at: output)
            
            outputHandler("✅ DMG creation completed successfully!")
            outputHandler("ℹ️ DMG is ready for restore operations")
            
            if useUDZO {
                outputHandler("⚠️ Note: UDZO format is compressed and read-only")
                outputHandler("   For ASR restore, Disk Utility will handle it automatically")
            }
            
            // Scan the DMG for restore
            outputHandler("")
            outputHandler("Starting DMG scan for restore...")
            try await DMGUtility.scanDMGForRestore(dmgPath: output.path, outputHandler: outputHandler, progressHandler: progressHandler)
            
        } catch {
            outputHandle.readabilityHandler = nil
            throw DMGError.creationFailed("Failed to execute hdiutil command: \(error.localizedDescription)")
        }
    }
    
    private static func parseDMGProgress(from line: String) -> Double? {
        // hdiutil outputs progress like:
        // "Creating ... XX.XX%..."
        // ".................................................XX%"
        let patterns = [
            #"(\d+\.\d+)%"#,  // Match decimal percentages
            #"(\d+)%"#  // Match integer percentages
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
    
    private static func setDMGPermissions(at url: URL) {
        // Set permissions to 644 (rw-r--r--) so all users can read
        do {
            let attributes = [FileAttributeKey.posixPermissions: 0o644]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
        } catch {
            // Permission setting failed, but DMG was created
            // The chmod in the shell script should have handled it
        }
    }
    
    static func scanDMGForRestore(
        dmgPath: String,
        outputHandler: @escaping (String) -> Void,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        outputHandler("Scanning DMG: \(dmgPath)")
        outputHandler("This verifies the DMG can be used for restore operations...")
        
        // Escape single quotes to prevent command injection
        let escapedPath = dmgPath.replacingOccurrences(of: "'", with: "'\\''")
        
        let script = """
        do shell script "/usr/bin/hdiutil imageinfo '\(escapedPath)' && /usr/bin/hdiutil verify '\(escapedPath)'" with administrator privileges
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        outputHandler("Executing: hdiutil imageinfo && hdiutil verify")
        
        // Track progress manually for scan (hdiutil verify doesn't always report progress)
        var scanProgress: Double = 0.0
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if scanProgress < 0.9 {
                scanProgress += 0.05
                DispatchQueue.main.async {
                    progressHandler(scanProgress)
                }
            }
        }
        
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
                        }
                    }
                }
            }
        }
        
        do {
            try process.run()
            
            // Wait for completion
            process.waitUntilExit()
            
            // Stop progress timer
            progressTimer.invalidate()
            
            // Small delay to ensure all output is captured
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Stop reading output
            outputHandle.readabilityHandler = nil
            
            guard process.terminationStatus == 0 else {
                progressHandler(0.0)
                throw DMGError.scanFailed("DMG verification failed with exit code \(process.terminationStatus)")
            }
            
            progressHandler(1.0)
            outputHandler("✅ DMG scan completed - Image is valid for restore!")
            
        } catch {
            progressTimer.invalidate()
            outputHandle.readabilityHandler = nil
            progressHandler(0.0)
            throw DMGError.scanFailed("Failed to scan DMG: \(error.localizedDescription)")
        }
    }
}

enum DMGError: LocalizedError {
    case creationFailed(String)
    case scanFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let message):
            return "DMG creation failed: \(message)"
        case .scanFailed(let message):
            return "DMG scan failed: \(message)"
        }
    }
}
