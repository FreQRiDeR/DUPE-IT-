//
//  DiskUtility.swift
//  DUPE-IT!
//
//  Created by FreQRiDeR on 9/9/25.
//

import Foundation

struct DiskUtility {
    static func listDisks() async throws -> [DiskInfo] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        process.arguments = ["list", "-plist"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw DiskUtilityError.commandFailed("diskutil failed with status \(process.terminationStatus)")
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let allDisksAndPartitions = plist["AllDisksAndPartitions"] as? [[String: Any]] else {
            throw DiskUtilityError.parsingFailed("Failed to parse diskutil output")
        }
        
        var disks: [DiskInfo] = []
        
        for diskDict in allDisksAndPartitions {
            if let deviceIdentifier = diskDict["DeviceIdentifier"] as? String,
               let size = diskDict["Size"] as? Int64 {
                
                let name = diskDict["VolumeName"] as? String ?? diskDict["MediaName"] as? String ?? "Unknown"
                let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                let type = diskDict["Content"] as? String ?? "Unknown"
                
                disks.append(DiskInfo(
                    deviceIdentifier: "/dev/\(deviceIdentifier)",
                    name: name,
                    size: sizeString,
                    type: type
                ))
            }
            
            // Also check partitions
            if let partitions = diskDict["Partitions"] as? [[String: Any]] {
                for partition in partitions {
                    if let deviceIdentifier = partition["DeviceIdentifier"] as? String,
                       let size = partition["Size"] as? Int64 {
                        
                        let name = partition["VolumeName"] as? String ?? partition["MediaName"] as? String ?? "Partition"
                        let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                        let type = partition["Content"] as? String ?? "Partition"
                        
                        disks.append(DiskInfo(
                            deviceIdentifier: "/dev/\(deviceIdentifier)",
                            name: name,
                            size: sizeString,
                            type: type
                        ))
                    }
                }
            }
        }
        
        return disks.sorted { $0.deviceIdentifier < $1.deviceIdentifier }
    }
}

enum DiskUtilityError: LocalizedError {
    case commandFailed(String)
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .parsingFailed(let message):
            return message
        }
    }
}
